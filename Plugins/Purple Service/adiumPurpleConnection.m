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

#import "adiumPurpleConnection.h"
#import <AIUtilities/AIObjectAdditions.h>

static void adiumPurpleConnConnectProgress(PurpleConnection *gc, const char *text, size_t step, size_t step_count)
{
	if (!PURPLE_CONNECTION_IS_VALID(gc)) return;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    AILog(@"Connecting: gc=%p (%s) %zi / %zi", gc, text, step, step_count);

	NSNumber	*connectionProgressPrecent = [NSNumber numberWithDouble:((CGFloat)step / (CGFloat)(step_count-1))];
	[accountLookup(purple_connection_get_account(gc)) mainPerformSelector:@selector(accountConnectionProgressStep:percentDone:)
										 withObject:[NSNumber numberWithInteger:step]
										 withObject:connectionProgressPrecent];
    [pool drain];
}

static void adiumPurpleConnConnected(PurpleConnection *gc)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    AILog(@"Connected: gc=%p", gc);
	
	[accountLookup(purple_connection_get_account(gc)) accountConnectionConnected];
    [pool drain];
}

static void adiumPurpleConnDisconnected(PurpleConnection *gc)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    AILog(@"Disconnected: gc=%p", gc);
	//    if (_accountDict == nil) // if this has been destroyed, unloadPlugin has already been called
	//        return;
    [accountLookup(purple_connection_get_account(gc)) accountConnectionDisconnected];
    [pool drain];
}

static void adiumPurpleConnNotice(PurpleConnection *gc, const char *text)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    AILog(@"Connection Notice: gc=%p (%s)", gc, text);
	
	NSString *connectionNotice = [NSString stringWithUTF8String:text];
	[accountLookup(purple_connection_get_account(gc)) accountConnectionNotice:connectionNotice];
    [pool drain];
}

/** Called when an error causes a connection to be disconnected.
 *  Called before 'disconnected'.  This op is intended to replace
 *  'report_disconnect'.  If both are implemented, this will be called
 *  first; however, there's no real reason to implement both.
 *  @param gc		The PurpleConnection
 *  @param reason  why the connection ended, if known, or
 *                 'PURPLE_CONNECTION_ERROR_OTHER_ERROR', if not.
 *  @param text  a localized message describing the disconnection
 *               in more detail to the user.
 */
static void adiumPurpleConnReportDisconnectReason(PurpleConnection *gc,
										   PurpleConnectionError reason,
										   const char *text)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	AILog(@"Connection Disconnected: gc=%p (%s)", gc, text);
	
	NSString	*disconnectError = (text ? [NSString stringWithUTF8String:text] : @"");
    [accountLookup(purple_connection_get_account(gc)) accountConnectionReportDisconnect:disconnectError withReason:reason];
    [pool drain];
}

static PurpleConnectionUiOps adiumPurpleConnectionOps = {
    adiumPurpleConnConnectProgress,
    adiumPurpleConnConnected,
    adiumPurpleConnDisconnected,
    adiumPurpleConnNotice,
    /* report_disconnect */ NULL,
	/* network_connected */ NULL,
	/* network_disconnected */ NULL,
	adiumPurpleConnReportDisconnectReason,
	/* _purple_reserved 1-3 */
	NULL, NULL, NULL
};

PurpleConnectionUiOps *adium_purple_connection_get_ui_ops(void)
{
	return &adiumPurpleConnectionOps;
}
