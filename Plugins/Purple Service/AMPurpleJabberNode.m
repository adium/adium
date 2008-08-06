//
//  AMPurpleJabberNode.m
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import "AMPurpleJabberNode.h"

static unsigned iqCounter = 0;

@implementation AMPurpleJabberNode

static void AMPurpleJabberNode_received_data_cb(PurpleConnection *gc, xmlnode **packet, gpointer this) {
	AMPurpleJabberNode *self = (AMPurpleJabberNode*)this;
	
	// we're receiving *all* packets, so let's filter out those that don't concern us
	const char *from = xmlnode_get_attrib(*packet, "from");
	if (!from)
		return;
	if (!(*packet)->name)
		return;
	const char *type = xmlnode_get_attrib(*packet, "type");
	if (!type || (strcmp(type, "result") && strcmp(type, "error")))
		return;
	if (strcmp((*packet)->name, "iq"))
		return;
	if (![[NSString stringWithUTF8String:from] isEqualToString:self->jid])
		return;
	xmlnode *query = xmlnode_get_child_with_namespace(*packet,"query","http://jabber.org/protocol/disco#info");
	if (query) {
		if (self->features || self->identities)
			return; // we already have that information
		
		const char *node = xmlnode_get_attrib(query,"node");
		if ((self->node && !node) || (!self->node && node))
			return;
		if (node && ![[NSString stringWithUTF8String:node] isEqualToString:self->node])
			return;
		
		// it's us, fill in features and identities
		NSMutableArray *identities = [[NSMutableArray alloc] init];
		NSMutableSet *features = [[NSMutableSet alloc] init];
		
		xmlnode *item;
		for(item = query->child; item; item = item->next) {
			if (item->type == XMLNODE_TYPE_TAG) {
				if (!strcmp(item->name, "identity")) {
					const char *category = xmlnode_get_attrib(item,"category");
					const char *type = xmlnode_get_attrib(item, "type");
					const char *name = xmlnode_get_attrib(item, "name");
					[identities addObject:[NSDictionary dictionaryWithObjectsAndKeys:
										   category?[NSString stringWithUTF8String:category]:[NSNull null], @"category",
										   type?[NSString stringWithUTF8String:type]:[NSNull null], @"type",
										   name?[NSString stringWithUTF8String:name]:[NSNull null], @"name",
										   nil]];
				} else if (!strcmp(item->name, "feature")) {
					const char *var = xmlnode_get_attrib(item, "var");
					if (var)
						[features addObject:[NSString stringWithUTF8String:var]];
				}
			}
		}
		
		self->identities = identities;
		self->features = features;
		
		NSEnumerator *e = [self->delegates objectEnumerator];
		id delegate;
		while ((delegate = [e nextObject]))
			if ([delegate respondsToSelector:@selector(jabberNodeGotInfo:)])
				[delegate jabberNodeGotInfo:self];
		if ([features containsObject:@"http://jabber.org/protocol/commands"]) {
			// in order to avoid endless loops, check if the current node isn't a command by itself (which can't contain other commands)
			BOOL isCommand = NO;
			e = [identities objectEnumerator];
			NSDictionary *identity;
			while ((identity = [e nextObject])) {
				if ([[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
					isCommand = YES;
					break;
				}
			}
			
			if (!isCommand) {
				// commands have to be prefetched to be available when the user tries to access the context menu
				if (self->commands)
					[self->commands release];
				self->commands = [[AMPurpleJabberNode alloc] initWithJID:self->jid
																	node:@"http://jabber.org/protocol/commands"
																	name:nil
															  connection:self->gc];
				[self->commands fetchItems];
			}
		}
		return;
	}
	
	query = xmlnode_get_child_with_namespace(*packet,"query","http://jabber.org/protocol/disco#items");
	if (query) {
		if (self->items)
			return; // we already have that info
		
		const char *node = xmlnode_get_attrib(query,"node");
		if ((self->node && !node) || (!self->node && node))
			return;
		if (node && ![[NSString stringWithUTF8String:node] isEqualToString:self->node])
			return;
		
		// it's us, create the subnodes
		NSMutableArray *items = [[NSMutableArray alloc] init];
		xmlnode *item;
		for(item = query->child; item; item = item->next) {
			if (item->type == XMLNODE_TYPE_TAG) {
				if (!strcmp(item->name, "item")) {
					const char *jid = xmlnode_get_attrib(item,"jid");
					const char *node = xmlnode_get_attrib(item,"node");
					const char *name = xmlnode_get_attrib(item,"name");
					
					if (jid) {
						AMPurpleJabberNode *newnode = [[AMPurpleJabberNode alloc] initWithJID:[NSString stringWithUTF8String:jid]
																						 node:node?[NSString stringWithUTF8String:node]:nil
																						 name:name?[NSString stringWithUTF8String:name]:nil
																				   connection:self->gc];
						// propagate delegates
						[newnode->delegates release];
						newnode->delegates = [self->delegates retain];
						[items addObject:newnode];
						// check if we're a conference service
						if ([[self jid] rangeOfString:@"@"].location == NSNotFound) { // we can't be one when we have an @
							NSEnumerator *e = [[self identities] objectEnumerator];
							NSDictionary *identity;
							while ((identity = [e nextObject])) {
								if ([[identity objectForKey:@"category"] isEqualToString:@"conference"]) {
									// since we're a conference service, assume that our children are conferences
									newnode->identities = [[NSArray arrayWithObject:identity] retain];
									break;
								}
							}
							if (!identity)
								[newnode fetchInfo];
						} else
							[newnode fetchInfo];
						[newnode release];
					}
				}
			}
		}
		self->items = items;
		
		NSEnumerator *e = [self->delegates objectEnumerator];
		id delegate;
		while ((delegate = [e nextObject]))
			if ([delegate respondsToSelector:@selector(jabberNodeGotItems:)])
				[delegate jabberNodeGotItems:self];
	}
}

- (id)initWithJID:(NSString*)_jid node:(NSString*)_node name:(NSString*)_name connection:(PurpleConnection*)_gc {
	if ((self = [super init])) {
		PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
        if (!jabber) {
            AILog(@"Unable to locate jabber prpl");
            [self release];
            return nil;
        }
		jid = [_jid copy];
		node = [_node copy];
		name = [_name copy];
		gc = _gc;
		delegates = [[NSMutableArray alloc] init];
		
		purple_signal_connect(jabber, "jabber-receiving-xmlnode", self,
                              PURPLE_CALLBACK(AMPurpleJabberNode_received_data_cb), self);
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
	if (!jabber) {
		AILog(@"Unable to locate jabber prpl");
		[self release];
		return nil;
	}
	AMPurpleJabberNode *copy = [[AMPurpleJabberNode alloc] init];
	
	// share the items, identities and features between copies
	// copy the rest, keep delegates separate
	copy->jid = [jid copy];
	copy->node = [node copy];
	copy->name = [name copy];
	copy->gc = gc;
	copy->delegates = [[NSMutableArray alloc] init];
	copy->items = [items retain];
	copy->features = [features retain];
	copy->identities = [identities retain];
	
	purple_signal_connect(jabber, "jabber-receiving-xmlnode", copy,
						  PURPLE_CALLBACK(AMPurpleJabberNode_received_data_cb), copy);
	
	return copy;
}

- (void)dealloc {
	purple_signals_disconnect_by_handle(self);
	[jid release];
	[node release];
	[features release];
	[identities release];
	[items release];
	[name release];
	[commands release];
	[delegates release];
	[super dealloc];
}

- (void)fetchItems {
	if (items) {
		[items release];
		items = nil;
	}
	
	NSXMLElement *iq = [NSXMLNode elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	if (jid)
		[iq addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
	[iq addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%@%u,",[self className], iqCounter++]]];
	
	NSXMLElement *query = [NSXMLNode elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#items"]];
	if (node)
		[query addAttribute:[NSXMLNode attributeWithName:@"node" stringValue:node]];
	[iq addChild:query];
	
	NSData *xmlData = [[iq XMLString] dataUsingEncoding:NSUTF8StringEncoding];
	
	if (PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)
		(PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)(gc, [xmlData bytes], [xmlData length]);
}

- (void)fetchInfo {
	if (features) {
		[features release];
		features = nil;
	}
	if (identities) {
		[identities release];
		identities = nil;
	}
	
	NSXMLElement *iq = [NSXMLNode elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	if (jid)
		[iq addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
	[iq addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%@%u",[self className], iqCounter++]]];
	
	NSXMLElement *query = [NSXMLNode elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#info"]];
	if (node)
		[query addAttribute:[NSXMLNode attributeWithName:@"node" stringValue:node]];
	[iq addChild:query];
	
	NSData *xmlData = [[iq XMLString] dataUsingEncoding:NSUTF8StringEncoding];
	
	if (PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)
		(PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)(gc, [xmlData bytes], [xmlData length]);
}

- (NSString*)name {
	return name;
}
- (NSString*)jid {
	return jid;
}
- (NSString*)node {
	return node;
}
- (NSArray*)items {
	if (!items) {
		BOOL isCommand = NO;
		NSEnumerator *e = [identities objectEnumerator];
		NSDictionary *identity;
		while ((identity = [e nextObject])) {
			if ([[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
				isCommand = YES;
				break;
			}
		}
		// commands don't contain any other nodes
		if (isCommand) {
			items = [[NSArray alloc] init];
			return items;
		}
	}
	
	return items;
}
- (NSSet*)features {
	return features;
}
- (NSArray*)identities {
	return identities;
}
- (NSArray*)commands {
	return [commands items];
}

- (void)addDelegate:(id)delegate {
	[delegates addObject:delegate];
}

- (void)removeDelegate:(id)delegate {
	[delegate removeObjectIdenticalTo:delegate];
}

@end
