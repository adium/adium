//
//  AMPurpleJabberNode.m
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import "AMPurpleJabberNode.h"

static unsigned iqCounter = 0;

@interface AMPurpleJabberNode()
@property (readwrite, copy, nonatomic) NSString *name;
@property (readwrite, copy, nonatomic) NSString *jid;
@property (readwrite, copy, nonatomic) NSString *node;
@property (readwrite, retain, nonatomic) NSSet *features;
@property (readwrite, retain, nonatomic) NSArray *identities;
@property (readwrite, retain, nonatomic) AMPurpleJabberNode *commandsNode;
@property (readwrite, assign, nonatomic) PurpleConnection *gc;
@property (readwrite, copy, nonatomic) NSMutableArray *delegates;
@property (readwrite, retain, nonatomic) NSArray *itemsArray;
@end

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
	if (![[NSString stringWithUTF8String:from] isEqualToString:self.jid])
		return;
	xmlnode *query = xmlnode_get_child_with_namespace(*packet,"query","http://jabber.org/protocol/disco#info");
	if (query) {
		if (self.features || self.identities)
			return; // we already have that information
		
		const char *node = xmlnode_get_attrib(query,"node");
		if ((self.node && !node) || (!self.node && node))
			return;
		if (node && ![[NSString stringWithUTF8String:node] isEqualToString:self.node])
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
		
		self.identities = identities;
		self.features = features;

		for (id delegate in self.delegates) {
			if ([delegate respondsToSelector:@selector(jabberNodeGotInfo:)])
				[delegate jabberNodeGotInfo:self];
		}
			
		if ([features containsObject:@"http://jabber.org/protocol/commands"]) {
			// in order to avoid endless loops, check if the current node isn't a command by itself (which can't contain other commands)
			BOOL isCommand = NO;
			NSDictionary *identity;
			for (identity in identities) {
				if ([[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
					isCommand = YES;
					break;
				}
			}
			
			if (!isCommand) {
				// commands have to be prefetched to be available when the user tries to access the context menu
				self.commandsNode = [[AMPurpleJabberNode alloc] initWithJID:self.jid
																	node:@"http://jabber.org/protocol/commands"
																	name:nil
															  connection:self.gc];
				[self.commandsNode fetchItems];
			}
		}
		return;
	}
	
	query = xmlnode_get_child_with_namespace(*packet,"query","http://jabber.org/protocol/disco#items");
	if (query) {
		if (self.itemsArray)
			return; // we already have that info
		
		const char *node = xmlnode_get_attrib(query,"node");
		if ((self.node && !node) || (!self.node && node))
			return;
		if (node && ![[NSString stringWithUTF8String:node] isEqualToString:self.node])
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
																				   connection:self.gc];
						// propagate delegates
						newnode.delegates = self.delegates;
						[items addObject:newnode];
						// check if we're a conference service
						if ([[self jid] rangeOfString:@"@"].location == NSNotFound) { // we can't be one when we have an @
							NSDictionary *identity = nil;
							for (identity in self.identities) {
								if ([[identity objectForKey:@"category"] isEqualToString:@"conference"]) {
									// since we're a conference service, assume that our children are conferences
									newnode.identities = [NSArray arrayWithObject:identity];
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
		self.itemsArray = items;
		
		for (id delegate in self.delegates) {
			if ([delegate respondsToSelector:@selector(jabberNodeGotItems:)])
				[delegate jabberNodeGotItems:self];
		}
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
		self.jid = _jid;
		self.node = _node;
		self.name = _name;
		self.gc = _gc;
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
	copy.jid = self.jid;
	copy.node = self.node;
	copy.name = self.name;
	copy.gc = self.gc;

	copy.delegates = [[[NSMutableArray alloc] init] autorelease];
	copy.features = self.features;
	copy.identities = self.identities;
	copy.itemsArray = self.itemsArray;
	
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
	self.itemsArray = nil;
	
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
	self.features = nil;
	self.identities = nil;
	
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

- (NSArray*)items {
	if (!items) {
		BOOL isCommand = NO;
		NSDictionary *identity;
		for (identity in identities) {
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

- (NSArray*)commands {
	return [commands items];
}

@synthesize commandsNode = commands, itemsArray = items, identities, features, node, jid, name, gc, delegates;

- (void)addDelegate:(id)delegate {
	[delegates addObject:delegate];
}

- (void)removeDelegate:(id)delegate {
	[delegate removeObjectIdenticalTo:delegate];
}

@end
