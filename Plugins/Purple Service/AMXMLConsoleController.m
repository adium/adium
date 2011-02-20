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

#import "AMXMLConsoleController.h"
#import <libpurple/jabber.h>
#import <AIUtilities/AIAutoScrollView.h>

#define XML_PREFIX @"<?xml version='1.0' encoding='UTF-8' ?>\n"

@interface AMXMLConsoleController ()
- (void)appendToLog:(NSAttributedString *)astr;
- (PurpleConnection *)gc;
@end;

static void
xmlnode_received_cb(PurpleConnection *gc, xmlnode **packet, gpointer this)
{
    AMXMLConsoleController *self = (AMXMLConsoleController *)this;
    
    if (!this || [self gc] != gc)
        return;
    
	char *str = xmlnode_to_formatted_str(*packet, NULL);
    NSString *sstr = [NSString stringWithUTF8String:str];
    
    if ([sstr hasPrefix:XML_PREFIX])
        sstr = [sstr substringFromIndex:[XML_PREFIX length]];
    
    NSAttributedString *astr = [[NSAttributedString alloc] initWithString:sstr
                                                               attributes:nil];
    [self appendToLog:astr];
    [astr release];
    
	g_free(str);
}

static void
xmlnode_sent_cb(PurpleConnection *gc, char **packet, gpointer this)
{
    AMXMLConsoleController *self = (AMXMLConsoleController *)this;
	xmlnode *node;

    if (!this || [self gc] != gc)
        return;

	node = ((*packet && strlen(*packet) && ((*packet)[0] == '<')) ?
			xmlnode_from_str(*packet, -1) :
			NULL);

	if (!node)
		return;
	
	char *str = xmlnode_to_formatted_str(node, NULL);
    NSString *sstr = [NSString stringWithUTF8String:str];
    
    if ([sstr hasPrefix:XML_PREFIX])
        sstr = [sstr substringFromIndex:[XML_PREFIX length]];

    NSAttributedString *astr = [[NSAttributedString alloc] initWithString:sstr
                                                               attributes:[NSDictionary dictionaryWithObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName]];
    [self appendToLog:astr];
    [astr release];
    
	g_free(str);
	xmlnode_free(node);
}

@implementation AMXMLConsoleController

- (void)dealloc {
    purple_signals_disconnect_by_handle(self);
    
    [super dealloc];
}

- (IBAction)sendXML:(id)sender {
    NSData *rawXMLData = [[xmlInjectView string] dataUsingEncoding:NSUTF8StringEncoding];
    NSAssert( INT_MAX >= [rawXMLData length],
						 @"Sending more jabber data value than libpurple can handle.  Abort." );
    jabber_prpl_send_raw(gc, [rawXMLData bytes], (int)[rawXMLData length]);

    // remove from text field
    [xmlInjectView setString:@""];
}

- (IBAction)clearLog:(id)sender {
    [xmlLogView setString:@""];
}

- (IBAction)showWindow:(id)sender {
	if (!xmlConsoleWindow) {
		//Load the window if it's not already loaded
		[NSBundle loadNibNamed:@"AMPurpleJabberXMLConsole" owner:self];
		if (!xmlConsoleWindow) AILog(@"Unable to load AMPurpleJabberXMLConsole!");
		
		
		//Connect to the signals for updating the window
		PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
		if (!jabber) AILog(@"Unable to locate jabber prpl");
		
		purple_signal_connect(jabber, "jabber-receiving-xmlnode", self,
							  PURPLE_CALLBACK(xmlnode_received_cb), self);
		purple_signal_connect(jabber, "jabber-sending-text", self,
							  PURPLE_CALLBACK(xmlnode_sent_cb), self);
	}
	
    [xmlConsoleWindow makeKeyAndOrderFront:sender];
	[(AIAutoScrollView *)[xmlLogView enclosingScrollView] setAutoScrollToBottom:YES];
}

- (void)windowWillClose:(NSNotification *)notification
{
	xmlConsoleWindow = nil;

	//We don't need to watch the signals with the window closed
	purple_signals_disconnect_by_handle(self);
}

- (void)close
{
	[xmlConsoleWindow close];
}


- (void)appendToLog:(NSAttributedString*)astr {
	[[xmlLogView textStorage] appendAttributedString:astr];
}

- (PurpleConnection*)gc {
    return gc;
}

- (void)setPurpleConnection:(PurpleConnection *)inGc
{
	gc = inGc;
}

@end
