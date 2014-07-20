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
#import <Adium/AIListObject.h>

#import "AIOTRSMPSecretAnswerWindowController.h"

@implementation AIOTRTopBarUnverifiedContactController

- (id)init
{
    self = [super initWithNibName:@"AIOTRTopBarUnverifiedContactController"
						   bundle:[NSBundle bundleForClass:[AIOTRTopBarUnverifiedContactController class]]];
    if (self) {
        [self loadView];
		
		view_backgroundView.startColor = [NSColor colorWithCalibratedWhite:0.79f alpha:1.0f];

		view_backgroundView.endColor = [NSColor colorWithCalibratedWhite:0.91f alpha:1.0f];
		
		[button_configure setStringValue:[AILocalizedString(@"Verify", nil) stringByAppendingEllipsis]];
    }
    
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)verify:(id)sender
{
	NSString *UID = ((AIListObject *)chat.listObject).formattedUID;
	
	[verificationWindow makeKeyAndOrderFront:nil];
	
	[label_explanation setStringValue:[NSString
									   stringWithFormat:AILocalizedString(@"Your conversation with %@ is encrypted. However, you should make sure you really are talking to %@.\n\n"
																		  @"You can authenticate %@ in the following ways:", nil), UID, UID, UID]];
	
	NSButtonCell *questionCell = [matrix_verificationChoices cellWithTag:1];
	NSButtonCell *secretCell = [matrix_verificationChoices cellWithTag:2];
	NSButtonCell *manualCell = [matrix_verificationChoices cellWithTag:3];
	
	[questionCell setTitle:[NSString stringWithFormat:AILocalizedString(@"Secret question: Ask a question only %@ can answer.", "radio button when verifying OTR"), UID]];
	[secretCell setTitle:AILocalizedString(@"Shared secret: You have previously agreed on a secret.", "radio button when verifying OTR")];
	[manualCell setTitle:AILocalizedString(@"Manually verify their fingerprint.", "radio button when verifying OTR")];
	
	[matrix_verificationChoices selectCellAtRow:0 column:0];
}

- (IBAction)okay:(id)sender
{
	switch ([matrix_verificationChoices selectedTag]) {
		case 1:
			[adium.contentController questionVerifyEncryptionIdentityInChat:chat];
			break;
		case 2:
			[adium.contentController sharedVerifyEncryptionIdentityInChat:chat];
			break;
		case 3:
			[adium.contentController promptToVerifyEncryptionIdentityInChat:chat];
			break;
		default:
			AILogWithSignature(@"Shouldn't happen: %ld!", (long)[matrix_verificationChoices selectedTag]);
			break;
	}
	
	[verificationWindow orderOut:nil];
}

- (IBAction)cancel:(id)sender
{
	[verificationWindow orderOut:nil];
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
	
	chat = inChat;
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(chatStatusChanged:)
                                                 name:Chat_StatusChanged
                                               object:chat];
	
	NSMutableAttributedString *label = [[NSMutableAttributedString alloc]
										initWithString:AILocalizedString(@"Your conversation is encrypted, but ",
																		 "after this a contact's UID, followed by \"s identity is unverified.\"")];
	
	NSAttributedString *uid = [[NSAttributedString alloc]
							   initWithString:[[chat listObject] formattedUID]
							   attributes:@{ NSFontAttributeName : [NSFont boldSystemFontOfSize:[NSFont systemFontSize]] }];
	
	[label appendAttributedString:uid];
	
	NSAttributedString *label2 = [[NSMutableAttributedString alloc]
								  initWithString:AILocalizedString(@"’s identity is unverified.", "See \"Your conversation is encrypted, but\"")];
	
	[label appendAttributedString:label2];
	
	[label_description setAttributedStringValue:label];
}

@end
