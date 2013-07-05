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

#import "AIIRCConsoleController.h"
#import <libpurple/irc.h>
#import <AIUtilities/AIAutoScrollView.h>

@interface AIIRCConsoleController ()
- (PurpleConnection *)gc;
@end;

static void
text_received_cb(PurpleConnection *gc, char **text, gpointer this)
{
    AIIRCConsoleController *self = (AIIRCConsoleController *)this;
	char *salvagedString = purple_utf8_salvage(*text);
    
    if (!this || [self gc] != gc)
        return;
	
    NSString *sstr = [[NSString stringWithUTF8String:salvagedString] stringByAppendingString:@"\n"];
	
	g_free(salvagedString);
    
	if (!sstr) {
		AILogWithSignature(@"Received a not valid utf8 string?");
		return;
	}
	
    NSAttributedString *astr = [[NSAttributedString alloc] initWithString:sstr
                                                               attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Courier" size:12], NSFontAttributeName, nil]];
    [self appendToLog:astr];
    [astr release];
}

static void
text_sent_cb(PurpleConnection *gc, char **text, gpointer this)
{
    AIIRCConsoleController *self = (AIIRCConsoleController *)this;
	char *salvagedString = purple_utf8_salvage(*text);

    if (!this || [self gc] != gc)
        return;
	
    NSString *sstr = [NSString stringWithUTF8String:salvagedString];
	
	g_free(salvagedString);
	
	if (!sstr) {
		AILogWithSignature(@"Sent a not valid utf8 string?");
		return;
	}

    NSAttributedString *astr = [[NSAttributedString alloc] initWithString:sstr
                                                               attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName,
																		   [NSFont fontWithName:@"Courier" size:12], NSFontAttributeName, nil]];
    [self appendToLog:astr];
    [astr release];
}

@implementation AIIRCConsoleController

- (void)dealloc {
    purple_signals_disconnect_by_handle(self);
    
    [super dealloc];
}

- (IBAction)send:(id)sender {
    NSString *rawData = [injectView string];
    NSAssert( INT_MAX >= [rawData length],
						 @"Sending more irc data value than libpurple can handle.  Abort." );
	
	const char *quote = [rawData UTF8String];
	irc_cmd_quote([self gc]->proto_data, NULL, NULL, &quote);
	
    // remove from text field
    [super send:sender];
}

- (IBAction)showWindow:(id)sender {
	if (!consoleWindow) {
		[super showWindow:sender];
		
		//Connect to the signals for updating the window
		PurplePlugin *irc = purple_find_prpl("prpl-irc");
		if (!irc) AILog(@"Unable to locate irc prpl");
		
		purple_signal_connect(irc, "irc-receiving-text", self,
							  PURPLE_CALLBACK(text_received_cb), self);
		purple_signal_connect(irc, "irc-sending-text", self,
							  PURPLE_CALLBACK(text_sent_cb), self);
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	//We don't need to watch the signals with the window closed
	purple_signals_disconnect_by_handle(self);
	
	[super windowWillClose:notification];
}

- (PurpleConnection*)gc {
    return gc;
}

- (void)setPurpleConnection:(PurpleConnection *)inGc
{
	gc = inGc;
}

@end
