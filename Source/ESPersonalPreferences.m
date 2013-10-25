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

#import "ESPersonalPreferences.h"
#import <Adium/AIAccount.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIMessageEntryTextView.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIDelayedTextField.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>

@interface ESPersonalPreferences ()
- (void)fireProfileChangesImmediately;
- (void)configureProfile;
- (void)configureImageView;
- (void)configureTooltips;
@end

@implementation ESPersonalPreferences

/*!
 * @brief Preference pane properties
 */
- (NSString *)paneIdentifier
{
	return @"Personal";
}
- (NSString *)paneName{
    return AILocalizedString(@"Personal","Personal preferences label");
}
- (NSString *)nibName{
    return @"PersonalPreferences";
}
- (NSImage *)paneIcon
{
	return [NSImage imageNamed:@"Personal" forClass:[self class]];
}

/*!
 * @brief Configure the view initially
 */
- (void)viewDidLoad
{
	NSString *displayName = [[[adium.preferenceController preferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
																	   group:GROUP_ACCOUNT_STATUS] attributedString] string];
	[textField_displayName setStringValue:(displayName ? displayName : @"")];
	
	//Set the default local alias (address book name) as the placeholder for the local alias
	NSString *defaultAlias = [[[adium.preferenceController defaultPreferenceForKey:KEY_ACCOUNT_DISPLAY_NAME
																			   group:GROUP_ACCOUNT_STATUS
																			  object:nil] attributedString] string];
	[[textField_displayName cell] setPlaceholderString:(defaultAlias ? defaultAlias : @"")];

	[self configureProfile];
	[self configureTooltips];
	
	if ([[adium.preferenceController preferenceForKey:KEY_USE_USER_ICON
												  group:GROUP_ACCOUNT_STATUS] boolValue]) {
		[matrix_userIcon selectCellWithTag:1];
	} else {
		[matrix_userIcon selectCellWithTag:0];		
	}

	[self configureControlDimming];

	[adium.preferenceController registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];

	[imageView_userIcon setMaxSize:NSMakeSize(128.0f, 128.0f)];

	[super viewDidLoad];
}

- (void)viewWillClose
{
	[adium.preferenceController unregisterPreferenceObserver:self];

	[textField_alias fireImmediately];
	[textField_displayName fireImmediately];
	[self fireProfileChangesImmediately];

	[[NSFontPanel sharedFontPanel] setDelegate:nil];

	[super viewWillClose];
}

- (void)changePreference:(id)sender
{	
	if (sender == textField_displayName) {
		NSString *displayName = [textField_displayName stringValue];
		
		[adium.preferenceController setPreference:((displayName && [displayName length]) ?
													 [[NSAttributedString stringWithString:displayName] dataRepresentation] :
													 nil)
											 forKey:KEY_ACCOUNT_DISPLAY_NAME
											  group:GROUP_ACCOUNT_STATUS];

	} else if (sender == textView_profile) {
		[adium.preferenceController setPreference:[[textView_profile textStorage] dataRepresentation] 
											 forKey:@"textProfile"
											  group:GROUP_ACCOUNT_STATUS];

	} else if (sender == matrix_userIcon) {
		BOOL enableUserIcon = ([[matrix_userIcon selectedCell] tag] == 1);

		[adium.preferenceController setPreference:[NSNumber numberWithBool:enableUserIcon]
											 forKey:KEY_USE_USER_ICON
											  group:GROUP_ACCOUNT_STATUS];	
	}else if (sender == button_enableMusicProfile) {
		BOOL enableUserIcon = ([button_enableMusicProfile state] == NSOnState);
		
		[adium.preferenceController setPreference:[NSNumber numberWithBool:enableUserIcon]
											 forKey:KEY_USE_USER_ICON
											  group:GROUP_ACCOUNT_STATUS];	
	}
	
	
	[super changePreference:nil];
}

- (void)configureControlDimming
{
	BOOL enableUserIcon = ([[matrix_userIcon selectedCell] tag] == 1);

	[button_chooseIcon setEnabled:enableUserIcon];
	[imageView_userIcon setEnabled:enableUserIcon];	
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (object) return;

	if ([key isEqualToString:KEY_ACCOUNT_DISPLAY_NAME]) {
		NSString *displayName = [textField_displayName stringValue];
		NSString *newDisplayName = [[[prefDict objectForKey:KEY_ACCOUNT_DISPLAY_NAME] attributedString] string];
		if (newDisplayName && ![displayName isEqualToString:newDisplayName]) {
			[textField_displayName setStringValue:newDisplayName];
		}
	}

	if (firstTime || [key isEqualToString:KEY_USER_ICON] || [key isEqualToString:KEY_DEFAULT_USER_ICON]) {
		[self configureImageView];
	}
}

#pragma mark Profile
- (void)configureProfile
{
	NSScrollView	*scrollView = [textView_profile enclosingScrollView];
	if (scrollView && [scrollView isKindOfClass:[AIAutoScrollView class]]) {
		[(AIAutoScrollView *)scrollView setAlwaysDrawFocusRingIfFocused:YES];
	}
	
	if ([textView_profile isKindOfClass:[AIMessageEntryTextView class]]) {
		/* We use the AIMessageEntryTextView to get nifty features for our text view, but we don't want to attempt
		* to 'send' to a target on Enter or Return.
		*/
		[(AIMessageEntryTextView *)textView_profile setSendingEnabled:NO];
	}

	[[NSFontPanel sharedFontPanel] setDelegate:textView_profile];

	NSData				*profileData = [adium.preferenceController preferenceForKey:@"textProfile"
																				group:GROUP_ACCOUNT_STATUS];
	NSAttributedString	*profile = (profileData ? [NSAttributedString stringWithData:profileData] : nil);
	
	if (profile && [profile length]) {
		[[textView_profile textStorage] setAttributedString:profile];
	} else {
		[textView_profile setString:@""];
	}	
}

- (void)fireProfileChangesImmediately
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(changePreference:)
											   object:textView_profile];	
	[self changePreference:textView_profile];
}

- (void)textDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == textView_profile) {		
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(changePreference:)
												   object:textView_profile];
		[self performSelector:@selector(changePreference:)
				   withObject:textView_profile
				   afterDelay:1.0];
	}
}

// AIImageViewWithImagePicker Delegate ---------------------------------------------------------------------
#pragma mark AIImageViewWithImagePicker Delegate
- (void)imageViewWithImagePicker:(AIImageViewWithImagePicker *)sender didChangeToImageData:(NSData *)imageData
{
	[adium.preferenceController setPreference:imageData
										 forKey:KEY_USER_ICON
										  group:GROUP_ACCOUNT_STATUS];
}

- (void)deleteInImageViewWithImagePicker:(AIImageViewWithImagePicker *)sender
{
	[adium.preferenceController setPreference:nil
										 forKey:KEY_USER_ICON
										  group:GROUP_ACCOUNT_STATUS];

	//User icon - restore to the default icon
	[self configureImageView];
}

- (NSString *)fileNameForImageInImagePicker:(AIImageViewWithImagePicker *)picker
{
	return AILocalizedString(@"Adium Icon", nil);
}

- (void)configureImageView
{
	NSData *imageData = [adium.preferenceController preferenceForKey:KEY_USER_ICON
																 group:GROUP_ACCOUNT_STATUS];
	if (!imageData) {
		imageData = [adium.preferenceController preferenceForKey:KEY_DEFAULT_USER_ICON
															 group:GROUP_ACCOUNT_STATUS];
	}

	[imageView_userIcon setImage:(imageData ? [[[NSImage alloc] initWithData:imageData] autorelease] : nil)];
	[imageView_userIcon setMaxSize:NSMakeSize(128.0f, 128.0f)];
	[imageView_userIcon setShouldUpdateRecentRepository:YES];
}

- (void)configureTooltips
{
	[matrix_userIcon setToolTip:AILocalizedString(@"Do not use an icon to represent you.", nil)
						forCell:[matrix_userIcon cellWithTag:0]];
	[matrix_userIcon setToolTip:AILocalizedString(@"Use the icon below to represent you.", nil)
						forCell:[matrix_userIcon cellWithTag:1]];

#define DISPLAY_NAME_TOOLTIP AILocalizedString(@"Your name, which on supported services will be sent to remote contacts. Substitutions from the Edit->Scripts and Edit->iTunes menus may be used here.", nil)
	[label_remoteAlias  setToolTip:DISPLAY_NAME_TOOLTIP];
	[textField_displayName setToolTip:DISPLAY_NAME_TOOLTIP];

#define PROFILE_TOOLTIP AILocalizedString(@"Profile to display when contacts request information about you (not supported by all services). Text may be formatted using the Edit and Format menus.", nil)
	[label_profile setToolTip:PROFILE_TOOLTIP];
	[textView_profile setToolTip:PROFILE_TOOLTIP];
}

@end
