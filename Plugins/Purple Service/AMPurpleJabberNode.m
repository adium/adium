/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AMPurpleJabberNode.h"

static NSUInteger iqCounter = 0;

@interface AMPurpleJabberNode()
@property (readwrite, copy, nonatomic) NSString *name;
@property (readwrite, copy, nonatomic) NSString *jid;
@property (readwrite, copy, nonatomic) NSString *node;
@property (weak, readwrite, nonatomic) NSSet *features;
@property (weak, readwrite, nonatomic) NSArray *identities;
@property (readwrite, nonatomic, strong) AMPurpleJabberNode *commandsNode;
@property (readwrite, assign, nonatomic) PurpleConnection *gc;
@property (readwrite, nonatomic, strong) NSMutableArray *delegates;
@property (weak, readwrite, nonatomic) NSArray *itemsArray;
@end

static CFArrayCallBacks nonretainingArrayCallbacks = {
	.version = 0,
	.copyDescription = (CFArrayCopyDescriptionCallBack)CFCopyDescription,
	.equal = (CFArrayEqualCallBack)CFEqual,
};

@implementation AMPurpleJabberNode

static void AMPurpleJabberNode_received_data_cb(PurpleConnection *gc, xmlnode **packet, gpointer this) {
	@autoreleasepool {
		AMPurpleJabberNode *self = (__bridge AMPurpleJabberNode*)this;
		
		// we're receiving *all* packets, so let's filter out those that don't concern us
		const char *from = xmlnode_get_attrib(*packet, "from");
		if (!from) {
			return;
		}
		if (!(*packet)->name){
			return;
		}
		const char *type = xmlnode_get_attrib(*packet, "type");
		if (!type || (strcmp(type, "result") && strcmp(type, "error"))){
			return;
		}
		if (strcmp((*packet)->name, "iq")){
			return;
		}
		if (![[NSString stringWithUTF8String:from] isEqualToString:self.jid]){
			return;
		}
		xmlnode *query = xmlnode_get_child_with_namespace(*packet,"query","http://jabber.org/protocol/disco#info");
		if (query) {
			if (self.features || self.identities) {
				return; // we already have that information
			}
			const char *queryNode = xmlnode_get_attrib(query,"node");
			if ((self.node && !queryNode) || (!self.node && queryNode)){
				return;
			}
			if (queryNode && ![[NSString stringWithUTF8String:queryNode] isEqualToString:self.node]){
				return;
			}
			
			// it's us, fill in features and identities
			NSMutableArray *identities = [NSMutableArray array];
			NSMutableSet *features = [NSMutableSet set];
			
			xmlnode *item;
			for(item = query->child; item; item = item->next) {
				if (item->type == XMLNODE_TYPE_TAG) {
					if (!strcmp(item->name, "identity")) {
						const char *category = xmlnode_get_attrib(item,"category");
						const char *ltype = xmlnode_get_attrib(item, "type");
						const char *queryName = xmlnode_get_attrib(item, "name");
						[identities addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											   category?[NSString stringWithUTF8String:category]:[NSNull null], @"category",
											   ltype?[NSString stringWithUTF8String:ltype]:[NSNull null], @"type",
											   queryName?[NSString stringWithUTF8String:queryName]:[NSNull null], @"name",
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
			if (self.itemsArray) {
				return; // we already have that info
			}
			
			const char *checkNode = xmlnode_get_attrib(query,"node");
			if ((self.node && !checkNode) || (!self.node && checkNode)) {
				return;
			}
			if (checkNode && ![[NSString stringWithUTF8String:checkNode] isEqualToString:self.node]){
				return;
			}
			
			// it's us, create the subnodes
			NSMutableArray *newItems = [NSMutableArray array];
			for(xmlnode *item = query->child; item; item = item->next) {
				if (item->type == XMLNODE_TYPE_TAG) {
					if (!strcmp(item->name, "item")) {
						const char *queryJID = xmlnode_get_attrib(item,"jid");
						const char *queryNode = xmlnode_get_attrib(item,"node");
						const char *queryName = xmlnode_get_attrib(item,"name");
						
						if (queryJID) {
							AMPurpleJabberNode *newnode = [[AMPurpleJabberNode alloc] initWithJID:[NSString stringWithUTF8String:queryJID]
																							 node:queryNode ? [NSString stringWithUTF8String:queryNode] : nil
																							 name:queryName ? [NSString stringWithUTF8String:queryName] : nil
																					   connection:self.gc];
							// propagate delegates
							newnode.delegates = CFBridgingRelease(CFArrayCreateMutableCopy(kCFAllocatorDefault, /*capacity*/ 0, (__bridge CFArrayRef)self.delegates));
							[newItems addObject:newnode];
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
						}
					}
				}
			}
			self.itemsArray = newItems;
			
			for (id delegate in self.delegates) {
				if ([delegate respondsToSelector:@selector(jabberNodeGotItems:)])
					[delegate jabberNodeGotItems:self];
			}
		}
	}
}

- (id)initWithJID:(NSString*)_jid node:(NSString*)_node name:(NSString*)_name connection:(PurpleConnection*)_gc {
	if ((self = [super init])) {
		PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
        if (!jabber) {
            AILog(@"Unable to locate jabber prpl");
            return nil;
        }
		self.jid = _jid;
		self.node = _node;
		self.name = _name;
		self.gc = _gc;
		self.delegates = CFBridgingRelease(CFArrayCreateMutable(kCFAllocatorDefault, /*capacity*/ 0, &nonretainingArrayCallbacks));
		
		purple_signal_connect(jabber, "jabber-receiving-xmlnode", (__bridge void *)(self),
                              PURPLE_CALLBACK(AMPurpleJabberNode_received_data_cb), (__bridge void *)(self));
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
	if (!jabber) {
		AILog(@"Unable to locate jabber prpl");
		return nil;
	}
	AMPurpleJabberNode *copy = [[AMPurpleJabberNode alloc] init];
	
	// share the items, identities and features between copies
	// copy the rest, keep delegates separate
	copy.jid = self.jid;
	copy.node = self.node;
	copy.name = self.name;
	copy.gc = self.gc;

	copy.delegates = CFBridgingRelease(CFArrayCreateMutable(kCFAllocatorDefault, /*capacity*/ 0, &nonretainingArrayCallbacks));
	copy.features = self.features;
	copy.identities = self.identities;
	copy.itemsArray = self.itemsArray;
	
	purple_signal_connect(jabber, "jabber-receiving-xmlnode", (__bridge void *)copy,
						  PURPLE_CALLBACK(AMPurpleJabberNode_received_data_cb), (__bridge void *)copy);
	
	return copy;
}

- (void)dealloc {
	purple_signals_disconnect_by_handle((__bridge void *)(self));
}

- (void)fetchItems {
	self.itemsArray = nil;
	
	NSXMLElement *iq = [NSXMLNode elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	if (jid)
		[iq addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
	[iq addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%@%lu,",[self className], iqCounter++]]];
	
	NSXMLElement *query = [NSXMLNode elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#items"]];
	if (node)
		[query addAttribute:[NSXMLNode attributeWithName:@"node" stringValue:node]];
	[iq addChild:query];
	
	NSData *xmlData = [[iq XMLString] dataUsingEncoding:NSUTF8StringEncoding];
	
	NSAssert( INT_MAX >= [xmlData length],
					 @"More XML data than libpurple can handle.  Abort." );
	
	if (PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)
		(PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)(gc, [xmlData bytes], (int)[xmlData length]);
}

- (void)fetchInfo {
	self.features = nil;
	self.identities = nil;
	
	NSXMLElement *iq = [NSXMLNode elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	if (jid)
		[iq addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
	[iq addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%@%lu",[self className], iqCounter++]]];
	
	NSXMLElement *query = [NSXMLNode elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#info"]];
	if (node)
		[query addAttribute:[NSXMLNode attributeWithName:@"node" stringValue:node]];
	[iq addChild:query];
	
	NSData *xmlData = [[iq XMLString] dataUsingEncoding:NSUTF8StringEncoding];
	
	NSAssert( INT_MAX >= [xmlData length],
					 @"More XML data than libpurple can handle.  Abort." );
	
	if (PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)
		(PURPLE_PLUGIN_PROTOCOL_INFO(gc->prpl)->send_raw)(gc, [xmlData bytes], (gint)[xmlData length]);
}

- (NSArray*)items {
	if (!items) {
		BOOL isCommand = NO;
		for (NSDictionary *identity in identities) {
			if ([[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
				isCommand = YES;
				break;
			}
		}
		// commands don't contain any other nodes
		if (isCommand) {
			self.itemsArray = [NSArray array];
			return items;
		}
	}
	
	return items;
}

- (NSArray*)commands {
	return [commands items];
}

@synthesize commandsNode = commands, itemsArray = items, identities, features, node, jid, name, gc, delegates;

- (void)addDelegate:(id<AMPurpleJabberNodeDelegate>)delegate {
	[delegates addObject:delegate];
}

- (void)removeDelegate:(id<AMPurpleJabberNodeDelegate>)delegate {
	[delegates removeObjectIdenticalTo:delegate];
}

@end
