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

#import "AIOTRTopBarLoggingWarningController.h"
#import "AIMessageViewController.h"
#import <Adium/AIPreferenceControllerProtocol.h>

#import "AILoggerPlugin.h"

@implementation AIOTRTopBarLoggingWarningController

- (id)init
{
    self = [super initWithNibName:@"AIOTRTopBarLoggingWarningController"
						   bundle:[NSBundle bundleForClass:[AIOTRTopBarLoggingWarningController class]]];
    if (self) {
        [self loadView];
		
		view_backgroundView.startColor = [NSColor colorWithCalibratedRed:1.0
																   green:.95
																	blue:.3
																   alpha:1.0];
		
		view_backgroundView.endColor = [NSColor colorWithCalibratedRed:1.0
																 green:.95
																  blue:.5
																 alpha:1.0];
		
		[adium.preferenceController registerPreferenceObserver:self
													  forGroup:PREF_GROUP_LOGGING];
    }
    
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	[super dealloc];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([key isEqualToString:KEY_LOGGER_SECURE_CHATS] || [key isEqualToString:KEY_LOGGER_CERTAIN_ACCOUNTS]
		|| [key isEqualToString:KEY_LOGGER_OBJECT_DISABLE]) {
		if (chat.shouldLog) {
			[owner unhideTopBarController:self];
		} else {
			[owner hideTopBarController:self];
		}
	}
}

- (IBAction)configureLogging:(id)sender
{
	[adium.preferenceController openPreferencesToCategoryWithIdentifier:@"Messages"];
}

- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*modifiedKeys = [[notification userInfo] objectForKey:@"Keys"];
	
    if ([modifiedKeys containsObject:@"securityDetails"]) {
		if ([[[chat securityDetails] objectForKey:@"EncryptionStatus"] integerValue] == EncryptionStatus_None
			|| !chat.shouldLog) {
			[owner removeTopBarController:self];
		}
    }
}

- (void)setChat:(AIChat *)inChat
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[chat release];
	chat = [inChat retain];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatStatusChanged:)
                                                 name:Chat_StatusChanged
                                               object:chat];
}

@end
