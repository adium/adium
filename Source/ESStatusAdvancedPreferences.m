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
- (NSString *)label{
    return AILocalizedString(@"Status",nil);
}
- (NSString *)nibName{
    return @"StatusPreferencesAdvanced";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-status" forClass:[AIPreferenceWindowController class]];
}

//Configure the preference view
- (void)viewDidLoad
{
	[label_statusWindow setLocalizedString:AILocalizedString(@"Away Status Window", nil)];
	[checkBox_statusWindowHideInBackground setLocalizedString:AILocalizedString(@"Hide the status window when Adium is not active", nil)];
	[checkBox_statusWindowAlwaysOnTop setLocalizedString:AILocalizedString(@"Show the status window above other windows", nil)];

	[label_itunesStatusFormat setLocalizedString:AILocalizedString(@"iTunes Status Format", nil)];
	[box_itunesElements setTitle:AILocalizedString(@"iTunes Elements", nil)];

	[label_instructions setLocalizedString:AILocalizedString(@"Type text and drag iTunes elements to create a custom format.", nil)];
	[label_album setLocalizedString:AILocalizedString(@"Album", nil)];
	[label_artist setLocalizedString:AILocalizedString(@"Artist", nil)];
	[label_composer setLocalizedString:AILocalizedString(@"Composer", nil)];
	[label_genre setLocalizedString:AILocalizedString(@"Genre", nil)];
	[label_status setLocalizedString:AILocalizedString(@"Player State", nil)];
	[label_title setLocalizedString:AILocalizedString(@"Title", nil)];
	[label_year setLocalizedString:AILocalizedString(@"Year", nil)];

	NSString *displayFormat = [adium.preferenceController preferenceForKey:KEY_ITUNES_TRACK_FORMAT
																	 group:PREF_GROUP_STATUS_PREFERENCES];
	if (!displayFormat || ![displayFormat length]) {
		displayFormat  = [NSString stringWithFormat:@"%@ - %@", TRIGGER_TRACK, TRIGGER_ARTIST];
	}
	[tokenField_format setObjectValue:[self separateStringIntoTokens:displayFormat]];
	[tokenField_format setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[tokenField_format setDelegate:self];

	[tokenField_album setStringValue:TRIGGER_ALBUM];
	[tokenField_album setDelegate:self];
	[tokenField_artist setStringValue:TRIGGER_ARTIST];
	[tokenField_artist setDelegate:self];
	[tokenField_composer setStringValue:TRIGGER_COMPOSER];
	[tokenField_composer setDelegate:self];
	[tokenField_genre setStringValue:TRIGGER_GENRE];
	[tokenField_genre setDelegate:self];
	[tokenField_status setStringValue:TRIGGER_STATUS];
	[tokenField_status setDelegate:self];
	[tokenField_title setStringValue:TRIGGER_TRACK];
	[tokenField_title setDelegate:self];
	[tokenField_year setStringValue:TRIGGER_YEAR];
	[tokenField_year setDelegate:self];
	
	[super viewDidLoad];
}

- (IBAction)changeFormat:(id)sender
{
	[adium.preferenceController setPreference:[[sender objectValue] componentsJoinedByString:@""]
									   forKey:KEY_ITUNES_TRACK_FORMAT
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
	if ([representedObject isEqualToString:TRIGGER_ALBUM]) {
		return AILocalizedString(@"Let It Be", @"Example for album title");
	} else if ([representedObject isEqualToString:TRIGGER_ARTIST]) {
		return AILocalizedString(@"The Beatles", @"Example for song artist");
	} else if ([representedObject isEqualToString:TRIGGER_COMPOSER]) {
		return AILocalizedString(@"Harrison", @"Example for song composer");
	} else if ([representedObject isEqualToString:TRIGGER_GENRE]) {
		return AILocalizedString(@"Rock", @"Example for song genre");
	} else if ([representedObject isEqualToString:TRIGGER_STATUS]) {
		return AILocalizedString(@"Paused", @"Example for music players' status (e.g. playing, paused)");
	} else if ([representedObject isEqualToString:TRIGGER_TRACK]) {
		return AILocalizedString(@"I Me Mine", @"Example for song title");
	} else if ([representedObject isEqualToString:TRIGGER_YEAR]) {
		return AILocalizedString(@"1970", @"Example for a songs debut-year");
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
			if ([substringFromIndex hasPrefix:TRIGGER_ALBUM]) {
				i += [TRIGGER_ALBUM length];
			} else if ([substringFromIndex hasPrefix:TRIGGER_ARTIST]) {
				i += [TRIGGER_ARTIST length];
			} else if ([substringFromIndex hasPrefix:TRIGGER_COMPOSER]) {
				i += [TRIGGER_COMPOSER length];
			} else if ([substringFromIndex hasPrefix:TRIGGER_GENRE]) {
				i += [TRIGGER_GENRE length];
			} else if ([substringFromIndex hasPrefix:TRIGGER_STATUS]) {
				i += [TRIGGER_STATUS length];
			} else if ([substringFromIndex hasPrefix:TRIGGER_TRACK]) {
				i += [TRIGGER_TRACK length];			
			} else if ([substringFromIndex hasPrefix:TRIGGER_YEAR]) {
				i += [TRIGGER_YEAR length];
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
