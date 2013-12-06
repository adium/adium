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
#import "AMPurpleJabberAdHocServer.h"
#import "AMPurpleJabberAdHocCommand.h"
#import <libpurple/jabber.h>

@interface AMPurpleJabberAdHocServer ()
- (BOOL)receivedCommand:(xmlnode*)command from:(NSString*)jid iqid:(NSString*)iqid;
- (void)addCommandsToXML:(xmlnode*)xml;
@end

@implementation AMPurpleJabberAdHocServer

static void AMPurpleJabberAdHocServer_received_data_cb(PurpleConnection *gc, xmlnode **packet, gpointer this) {
	@autoreleasepool {
		AMPurpleJabberAdHocServer *self = (__bridge AMPurpleJabberAdHocServer *)this;
		PurpleAccount *account = [self.account purpleAccount];
		if(purple_account_get_connection(account) == gc) {
			if(strcmp((*packet)->name,"iq")) {
				return;
			}
			const char *type = xmlnode_get_attrib(*packet,"type");
			if(!type || strcmp(type,"set")) {
				return; // doesn't talk to us, probably the user interacting with some other adhoc node
			}
			const char *from = xmlnode_get_attrib(*packet,"from");
			const char *iqid = xmlnode_get_attrib(*packet,"id");
			xmlnode *command = xmlnode_get_child_with_namespace(*packet,"command","http://jabber.org/protocol/commands");
			if(command) {
				BOOL handled = [self receivedCommand:command
												from:from?[NSString stringWithUTF8String:from]:nil
												iqid:iqid?[NSString stringWithUTF8String:iqid]:nil];
				if(handled) {
					xmlnode_free(*packet);
					*packet = NULL;
				}
			}
		}
		
	}
}

/* we have to catch the reply to a disco#info for http://jabber.org/protocol/commands and insert our nodes */
static void xmlnode_sent_cb(PurpleConnection *gc, xmlnode **packet, gpointer this) {
	@autoreleasepool {
		xmlnode *xml = *packet;
		AMPurpleJabberAdHocServer *self = (__bridge AMPurpleJabberAdHocServer *)this;
		PurpleAccount *account = [self.account purpleAccount];
		if(xml && purple_account_get_connection(account) == gc) {
			if(!strcmp(xml->name,"iq")) {
				const char *tostr = xmlnode_get_attrib(xml,"to");
				if(tostr) {
					NSString *to = [NSString stringWithUTF8String:tostr];
					NSRange slash = [to rangeOfString:@"/"];
					if(slash.location != NSNotFound) {
						NSString *barejid = [to substringToIndex:slash.location];
						if([barejid isEqualToString:self.account.UID]) {
							const char *type = xmlnode_get_attrib(xml,"type");
							if(type && !strcmp(type,"result")) {
								xmlnode *query = xmlnode_get_child_with_namespace(xml,"query","http://jabber.org/protocol/disco#items");
								if(query) {
									const char *node = xmlnode_get_attrib(query,"node");
									if(node && !strcmp(node,"http://jabber.org/protocol/commands"))
										[self addCommandsToXML:query];
								}
							}
						}
					}
				}
			}
		}
	}
}

+ (void)initialize {
	if (self == [AMPurpleJabberAdHocServer class])
		jabber_add_feature("http://jabber.org/protocol/commands", NULL);
}

- (id)initWithAccount:(ESPurpleJabberAccount*)_account {
	if((self = [super init])) {
		account = _account;
		commands = [[NSMutableDictionary alloc] init];
		
		PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
        if (!jabber) {
            AILog(@"Unable to locate jabber prpl");
            return nil;
        }

		purple_signal_connect(jabber, "jabber-receiving-xmlnode", (__bridge void *)(self),
                              PURPLE_CALLBACK(AMPurpleJabberAdHocServer_received_data_cb), (__bridge void *)(self));
        purple_signal_connect(jabber, "jabber-sending-xmlnode", (__bridge void *)(self),
                              PURPLE_CALLBACK(xmlnode_sent_cb), (__bridge void *)(self));
	}
	return self;
}

- (void)dealloc {
	purple_signals_disconnect_by_handle((__bridge void *)(self));
}

- (void)addCommand:(NSString*)node delegate:(id<AMPurpleJabberAdHocServerDelegate>)delegate name:(NSString*)name {
	[commands setObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithNonretainedObject:delegate],@"delegate",
				name, @"name",
				nil] forKey:node];
}

- (void)removeCommand:(NSString*)node {
	[commands removeObjectForKey:node];
}

- (ESPurpleJabberAccount*)account {
	return account;
}

- (void)addCommandsToXML:(xmlnode*)xml {
	JabberStream *js = purple_account_get_connection([self.account purpleAccount])->proto_data;
	char *jid = g_strdup_printf("%s@%s/%s", js->user->node, js->user->domain, js->user->resource);
	
	for (NSString *node in commands) {
		xmlnode *item = xmlnode_new_child(xml, "item");
		xmlnode_set_attrib(item,"jid",jid);
		xmlnode_set_attrib(item,"name",[[[commands objectForKey:node] objectForKey:@"name"] UTF8String]);
		xmlnode_set_attrib(item,"node",[node UTF8String]);
	}
	g_free(jid);
}

- (BOOL)receivedCommand:(xmlnode*)command from:(NSString*)jid iqid:(NSString*)iqid {
	// verify that it's the same bare jid this command was received from
	if(!jid)
		return NO;
	NSRange slash = [jid rangeOfString:@"/"];
	if(slash.location == NSNotFound || ![[jid substringToIndex:slash.location] isEqualToString:account.UID])
		return NO;
	
	const char *node = xmlnode_get_attrib(command,"node");
	
	if(node) {
		id delegate = [[commands objectForKey:[NSString stringWithUTF8String:node]] objectForKey:@"delegate"];
		if(delegate && [[delegate nonretainedObjectValue] respondsToSelector:@selector(adHocServer:executeCommand:)]) {
			AMPurpleJabberAdHocCommand *cmd = [[AMPurpleJabberAdHocCommand alloc] initWithServer:self command:command jid:jid iqid:iqid];
			[[delegate nonretainedObjectValue] adHocServer:self executeCommand:cmd];
			return YES;
		}
	}
	return NO;
}

@end
