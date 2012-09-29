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

#import "AMPurpleJabberAdHocCommand.h"
#import "AMPurpleJabberFormGenerator.h"
#import "AMPurpleJabberAdHocServer.h"

@implementation AMPurpleJabberAdHocCommand

- (id)initWithServer:(AMPurpleJabberAdHocServer*)_server command:(xmlnode*)_command jid:(NSString*)_jid iqid:(NSString*)_iqid {
	if((self = [super init])) {
		server = _server;
		command = xmlnode_copy(_command);
		jid = [_jid copy];
		iqid = [_iqid copy];
	}
	return self;
}

- (void)dealloc {
	xmlnode_free(command);
	[jid release];
	[iqid release];
	[sessionid release];
	[super dealloc];
}

- (AMPurpleJabberFormGenerator*)form {
	xmlnode *jabberForm = xmlnode_get_child_with_namespace(command,"x","jabber:x:data");
	if(!jabberForm)
		return nil;
	return [[[AMPurpleJabberFormGenerator alloc] initWithXML:form] autorelease];
}

- (NSString*)jid {
	return jid;
}

- (NSString*)sessionid {
	if(sessionid)
		return sessionid;
	const char *sessionid_orig = xmlnode_get_attrib(command,"sessionid");
	if(!sessionid_orig)
		return nil;
	return [NSString stringWithUTF8String:sessionid_orig];
}

- (void)setSessionid:(NSString*)_sessionid {
	id old = sessionid;
	sessionid = [_sessionid copy];
	[old release];
}

- (AMPurpleJabberAdHocCommand*)generateReplyWithForm:(AMPurpleJabberFormGenerator*)jabberForm actions:(NSArray*)actions defaultAction:(NSUInteger)defaultAction status:(enum AMPurpleJabberAdHocCommandStatus)status {
	const char *nodeattr = xmlnode_get_attrib(command,"node");
	if(!nodeattr)
		return nil;
	xmlnode *newcmd = xmlnode_new("command");
	xmlnode_set_namespace(newcmd,"http://jabber.org/protocol/commands");
	xmlnode_set_attrib(newcmd,"node",nodeattr);
	switch(status) {
		case executing:
			xmlnode_set_attrib(newcmd,"status","executing");
			break;
		case canceled:
			xmlnode_set_attrib(newcmd,"status","canceled");
			break;
		case completed:
			xmlnode_set_attrib(newcmd,"status","completed");
			break;
	}
	NSString *sessionid_orig = [self sessionid];
	if(sessionid_orig)
		xmlnode_set_attrib(newcmd,"sessionid",[sessionid_orig UTF8String]);
	
	if(actions) {
		xmlnode *actionsnode = xmlnode_new_child(newcmd,"actions");
		xmlnode_set_attrib(actionsnode,"execute",[[actions objectAtIndex:defaultAction] UTF8String]);
		NSString *actionstr;
		for(actionstr in actions)
			xmlnode_new_child(actionsnode, [actionstr UTF8String]);
	}
	
	xmlnode_insert_child(newcmd,[jabberForm xml]);
	
	AMPurpleJabberAdHocCommand *cmd = [[AMPurpleJabberAdHocCommand alloc] initWithServer:server command:newcmd jid:jid iqid:iqid];
	xmlnode_free(newcmd);
	return [cmd autorelease];
}

- (AMPurpleJabberAdHocCommand*)generateReplyWithNote:(NSString*)text type:(enum AMPurpleJabberAdHocCommandNoteType)type status:(enum AMPurpleJabberAdHocCommandStatus)status {
	const char *nodeattr = xmlnode_get_attrib(command,"node");
	if(!nodeattr)
		return nil;
	xmlnode *newcmd = xmlnode_new("command");
	xmlnode_set_namespace(newcmd,"http://jabber.org/protocol/commands");
	xmlnode_set_attrib(newcmd,"node",nodeattr);
	switch(status) {
		case executing:
			xmlnode_set_attrib(newcmd,"status","executing");
			break;
		case canceled:
			xmlnode_set_attrib(newcmd,"status","canceled");
			break;
		case completed:
			xmlnode_set_attrib(newcmd,"status","completed");
			break;
	}
	NSString *sessionid_orig = [self sessionid];
	if(sessionid_orig)
		xmlnode_set_attrib(newcmd,"sessionid",[sessionid_orig UTF8String]);
	
	xmlnode *note = xmlnode_new_child(newcmd,"note");
	switch(type) {
		case error:
			xmlnode_set_attrib(note,"type","error");
			break;
		case info:
			xmlnode_set_attrib(note,"type","info");
			break;
		case warn:
			xmlnode_set_attrib(note,"type","warn");
			break;
	}
	
	xmlnode_insert_data(note,[text UTF8String],-1);
	
	AMPurpleJabberAdHocCommand *cmd = [[AMPurpleJabberAdHocCommand alloc] initWithServer:server command:newcmd jid:jid iqid:iqid];
	xmlnode_free(newcmd);
	return [cmd autorelease];
}

- (void)send {
	PurpleAccount *account = [server.account purpleAccount];
	xmlnode *iq = xmlnode_new("iq");
	
	xmlnode_set_attrib(iq, "id", [iqid UTF8String]);
	xmlnode_set_attrib(iq, "to", [jid UTF8String]);
	xmlnode_set_attrib(iq, "type", "result");
	xmlnode *cmdcopy = xmlnode_copy(command);
	if(sessionid)
		xmlnode_set_attrib(cmdcopy, "sessionid", [sessionid UTF8String]);
	xmlnode_insert_child(iq, cmdcopy);
	
	gint len = 0;
	char *text = xmlnode_to_str(iq, &len);
	PURPLE_PLUGIN_PROTOCOL_INFO(purple_account_get_connection(account)->prpl)->send_raw(purple_account_get_connection(account), text, len);
	g_free(text);
	xmlnode_free(iq);
}

@end
