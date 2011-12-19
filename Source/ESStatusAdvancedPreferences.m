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

#import "CBStatusMenuItemPlugin.h"
#import "ESStatusAdvancedPreferences.h"
#import "AIStatusController.h"
#import "ESiTunesPlugin.h"
#import "AIPreferenceWindowController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESStatusAdvancedPreferences ()

- (IBAction)changeFormat:(id)sender;
- (NSArray *)separateStringIntoTokens:(NSString *)string;

@end

@implementation ESStatusAdvancedPreferences
//Preference pane properties
- (AIPreferenceCategory)category{
    return AIPref_Advanced;
}
- (NSString *)paneIdentifier{
	return @"StatusAdvanced";
}
- (NSString *)paneName{
    return AILocalizedString(@"Status",nil);
}
- (NSString *)nibName{
    return @"StatusPreferencesAdvanced";
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"pref-status" forClass:[AIPreferenceWindowController class]];
}

//Configure the preference view
- (void)viewDidLoad
{
	[label_statusWindow setLocalizedString:AILocalizedString(@"Away Status Window", nil)];
	[checkBox_statusWindowHideInBackground setLocalizedString:AILocalizedString(@"Hide the status window when Adium is not active", nil)];
	[checkBox_statusWindowAlwaysOnTop setLocalizedString:AILocalizedString(@"Show the status window above other windows", nil)];
	
	[box_itunesElements setTitle:AILocalizedString(@"iTunes Elements", nil)];
	
	[label_instructions setLocalizedString:AILocalizedString(@"Type text and drag iTunes elements to create a custom format.", nil)];
	[label_album setLocalizedString:AILocalizedString(@"Album", nil)];
	[label_artist setLocalizedString:AILocalizedString(@"Artist", nil)];
	[label_composer setLocalizedString:AILocalizedString(@"Composer", nil)];
	[label_genre setLocalizedString:AILocalizedString(@"Genre", nil)];
	[label_status setLocalizedString:AILocalizedString(@"Player State", nil)];
	[label_title setLocalizedString:AILocalizedString(@"Title", nil)];
	[label_year setLocalizedString:AILocalizedString(@"Year", nil)];

	NSString *displayFormat = [adium.preferenceController preferenceForKey:KEY_CURRENT_TRACK_FORMAT
																	 group:PREF_GROUP_STATUS_PREFERENCES];
	if (!displayFormat || ![displayFormat length]) {
		displayFormat  = [NSString stringWithFormat:@"%@ - %@", TRACK_TRIGGER, ARTIST_TRIGGER];
	}
	[tokenField_format setObjectValue:[self separateStringIntoTokens:displayFormat]];
	[tokenField_format setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[tokenField_format setDelegate:self];

	[tokenField_album setStringValue:ALBUM_TRIGGER];
	[tokenField_album setDelegate:self];
	[tokenField_artist setStringValue:ARTIST_TRIGGER];
	[tokenField_artist setDelegate:self];
	[tokenField_composer setStringValue:COMPOSER_TRIGGER];
	[tokenField_composer setDelegate:self];
	[tokenField_genre setStringValue:GENRE_TRIGGER];
	[tokenField_genre setDelegate:self];
	[tokenField_status setStringValue:STATUS_TRIGGER];
	[tokenField_status setDelegate:self];
	[tokenField_title setStringValue:TRACK_TRIGGER];
	[tokenField_title setDelegate:self];
	[tokenField_year setStringValue:YEAR_TRIGGER];
	[tokenField_year setDelegate:self];
	
	[super viewDidLoad];
}

- (IBAction)changeFormat:(id)sender
{
	[adium.preferenceController setPreference:[[sender objectValue] componentsJoinedByString:@""]
									   forKey:KEY_CURRENT_TRACK_FORMAT
										group:PREF_GROUP_STATUS_PREFERENCES];
	[[NSNotificationCenter defaultCenter] postNotificationName:Adium_CurrentTrackFormatChangedNotification 
														object:[[sender objectValue] componentsJoinedByString:@""]];
}

#pragma mark Token Field Delegate

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	NSString *tokenString = [tokens componentsJoinedByString:@""];
	return [self separateStringIntoTokens:tokenString];
}

- (NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard
{
	return [self separateStringIntoTokens:[pboard stringForType:NSStringPboardType]];
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard
{
	[pboard setString:[objects componentsJoinedByString:@""] forType:NSStringPboardType];
	return YES;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
	if ([representedObject hasPrefix:@"%_"]) {
		return NSRoundedTokenStyle;
	} else {
		return NSPlainTextTokenStyle;
	}
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
	if ([representedObject isEqualToString:ALBUM_TRIGGER]) {
		return @"Let It Be";
	} else if ([representedObject isEqualToString:ARTIST_TRIGGER]) {
		return @"The Beatles";
	} else if ([representedObject isEqualToString:COMPOSER_TRIGGER]) {
		return @"Harrison";
	} else if ([representedObject isEqualToString:GENRE_TRIGGER]) {
		return @"Rock";
	} else if ([representedObject isEqualToString:STATUS_TRIGGER]) {
		return AILocalizedString(@"Paused", nil);
	} else if ([representedObject isEqualToString:TRACK_TRIGGER]) {
		return @"I Me Mine";
	} else if ([representedObject isEqualToString:YEAR_TRIGGER]) {
		return @"1970";
	} else {
		return nil;
	}
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
	return editingString;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject
{
	// Tokens should not be editable
	return nil;
}

- (NSArray *)separateStringIntoTokens:(NSString *)string
{
	NSMutableArray *tokens = [NSMutableArray array];
	
	int i = 0;
	while (i < [string length]) {
		unsigned int start = i;
		
		// Evaluate if it known token
		if ([[string substringFromIndex:i] hasPrefix:@"%_"]) {
			NSString *substringFromIndex = [string substringFromIndex:i];
			if ([substringFromIndex hasPrefix:ALBUM_TRIGGER]) {
				i += [ALBUM_TRIGGER length];
			} else if ([substringFromIndex hasPrefix:ARTIST_TRIGGER]) {
				i += [ARTIST_TRIGGER length];
			} else if ([substringFromIndex hasPrefix:COMPOSER_TRIGGER]) {
				i += [COMPOSER_TRIGGER length];
			} else if ([substringFromIndex hasPrefix:GENRE_TRIGGER]) {
				i += [GENRE_TRIGGER length];
			} else if ([substringFromIndex hasPrefix:STATUS_TRIGGER]) {
				i += [STATUS_TRIGGER length];
			} else if ([substringFromIndex hasPrefix:TRACK_TRIGGER]) {
				i += [TRACK_TRIGGER length];			
			} else if ([substringFromIndex hasPrefix:YEAR_TRIGGER]) {
				i += [YEAR_TRIGGER length];
			} else {
				for (; i < [string length]; i++) {
					if ([[string substringFromIndex:(i + 1)] hasPrefix:@"%_"]) {
						i++;
						break;
					}
				}
			}
		// Search for start of next token
		} else {
			for (; i < [string length]; i++) {
				if ([[string substringFromIndex:(i + 1)] hasPrefix:@"%_"]) {
					i++;
					break;
				}
			}
		}
		
		[tokens addObject:[string substringWithRange:NSMakeRange(start, i - start)]];
	}
	
	return tokens;
}
 
@end
