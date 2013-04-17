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

#import "AIRejoinGroupChatViewController.h"
#import "AIBundleAdditions.h"
#import <Adium/AIGroupChat.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIAbstractAccount.h>
#import "AIMessageViewController.h"

@interface AIRejoinGroupChatViewController ()

@end

@implementation AIRejoinGroupChatViewController

- (id)init
{
    self = [super initWithNibName:@"AIRejoinGroupChatTopBar" bundle:[NSBundle bundleForClass:[AIRejoinGroupChatViewController class]]];
    if (self) {
		[label_description setStringValue:AILocalizedString(@"You have parted the channel", @"Description in bar at the top of parted channels")];
		[button_rejoin setStringValue:AILocalizedString(@"Rejoin", @"Button in the bar at the top of parted channels to rejoin")];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (IBAction)rejoin:(id)sender
{
    [chat.account setShouldBeOnline:YES];
    
    [chat.account rejoinChat:chat];
}

- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*keys = [[notification userInfo] objectForKey:@"Keys"];
    
    // Remove ourselves if the chat rejoined.
    if ([keys containsObject:@"accountJoined"] &&
        [chat boolValueForProperty:@"accountJoined"]) {
        [owner removeTopBarController:self];
	}
}

- (void)setChat:(AIChat *)inChat
{
    if (chat) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:Chat_StatusChanged
                                                      object:chat];
    }
    
    [chat release];
    
    chat = [inChat retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatStatusChanged:)
                                                 name:Chat_StatusChanged
                                               object:chat];
}

@end
