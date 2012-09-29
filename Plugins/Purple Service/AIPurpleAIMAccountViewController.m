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

#import "AIPurpleAIMAccountViewController.h"
#import "CBPurpleAccount.h"
#import "CBPurpleOscarAccount.h"
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AITextViewWithPlaceholder.h>
#import <Adium/AIAccount.h>
#import <Adium/AIMessageEntryTextView.h>

@implementation AIPurpleAIMAccountViewController

/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"ESPurpleAIMAccountView";
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	NSScrollView	*scrollView = [textView_textProfile enclosingScrollView];
	if (scrollView && [scrollView isKindOfClass:[AIAutoScrollView class]]) {
		[(AIAutoScrollView *)scrollView setAlwaysDrawFocusRingIfFocused:YES];
	}
	
	if ([textView_textProfile isKindOfClass:[AIMessageEntryTextView class]]) {
		/* We use the AIMessageEntryTextView to get nifty features for our text view, but we don't want to attempt
		 * to 'send' to a target on Enter or Return.
		 */
		[(AIMessageEntryTextView *)textView_textProfile setSendingEnabled:NO];
	}
}

/*!
 * @brief Configure controls
 */
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	[[NSFontPanel sharedFontPanel] setDelegate: textView_textProfile];
    
    //Profile
    NSData				*profileData = [account preferenceForKey:@"textProfile" group:GROUP_ACCOUNT_STATUS];
	NSAttributedString	*profile = (profileData ? [NSAttributedString stringWithData:profileData] : nil);
	
	if (profile && [profile length]) {
		[[textView_textProfile textStorage] setAttributedString:profile];
	} else {
		[textView_textProfile setString:@""];
	}

	if ([textView_textProfile isKindOfClass:[AITextViewWithPlaceholder class]]) {
		NSData				*globalProfileData = [adium.preferenceController preferenceForKey:@"textProfile" group:GROUP_ACCOUNT_STATUS];
		NSAttributedString	*globalProfile = (globalProfileData ? [NSAttributedString stringWithData:globalProfileData] : nil);
		
		if (globalProfile && [globalProfile length]) {
			[(AITextViewWithPlaceholder *)textView_textProfile setPlaceholder:globalProfile];
		} else {
			[(AITextViewWithPlaceholder *)textView_textProfile setPlaceholder:nil];
		}
	}
}

/*!
 * @brief Save controls
 */
- (void)saveConfiguration
{
    [super saveConfiguration];
	
	[account setPreference:([[textView_textProfile textStorage] length] ?
							[[textView_textProfile textStorage] dataRepresentation] :
							nil)
					forKey:@"textProfile"
					 group:GROUP_ACCOUNT_STATUS];
}

@end
