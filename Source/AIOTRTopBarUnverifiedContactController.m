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

#import "AIOTRTopBarUnverifiedContactController.h"
#import "AIMessageViewController.h"
#import <Adium/AIPreferenceControllerProtocol.h>
#import "AIStringAdditions.h"
#import <Adium/AIContentControllerProtocol.h>

@implementation AIOTRTopBarUnverifiedContactController

- (id)init
{
    self = [super initWithNibName:@"AIOTRTopBarUnverifiedContactController"
						   bundle:[NSBundle bundleForClass:[AIOTRTopBarUnverifiedContactController class]]];
    if (self) {
        [self loadView];
		
		view_backgroundView.startColor = [NSColor colorWithCalibratedWhite:0.79f alpha:1.0f];

		view_backgroundView.endColor = [NSColor colorWithCalibratedWhite:0.91f alpha:1.0f];
		
		[label_description setStringValue:AILocalizedString(@"Your conversation is encrypted, but the contact's identity is unverified.", nil)];
		[button_configure setStringValue:[AILocalizedString(@"Verify", nil) stringByAppendingEllipsis]];
    }
    
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

- (IBAction)verify:(id)sender
{
	
}

- (void)chatStatusChanged:(NSNotification *)notification
{
    NSArray	*modifiedKeys = [[notification userInfo] objectForKey:@"Keys"];
	
    if ([modifiedKeys containsObject:@"securityDetails"]) {
		if ([[[chat securityDetails] objectForKey:@"EncryptionStatus"] integerValue] != EncryptionStatus_Unverified) {
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
