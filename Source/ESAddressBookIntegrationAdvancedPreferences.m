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

#import "ESAddressBookIntegrationAdvancedPreferences.h"
#import <Adium/AIAddressBookController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AILocalizationTextField.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

@interface NSTokenField (NSTokenFieldAdditions)
- (void)updateDisplay;
@end

@implementation NSTokenField (NSTokenFieldAdditions)
- (void)updateDisplay
{
	NSRange selectionRange = [[[self window] fieldEditor:YES forObject:self] selectedRange];
	
	// XXX - Reassign objectValue to let NSTokenField know it has changed.
	id objectValue = [self objectValue];
	[self setObjectValue:nil];
	[self setObjectValue:objectValue];
	
	[[[self window] fieldEditor:YES forObject:self] setSelectedRange:selectionRange];
}
@end

@interface ESAddressBookIntegrationAdvancedPreferences ()
- (IBAction)changeFormat:(id)sender;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (NSArray *)separateStringIntoTokens:(NSString *)string;
- (void)changeFormatToFullName:(id)representedObject;
- (void)changeFormatToInitialCharacter:(id)representedObject;
@end

/*!
 * @class ESAddressBookIntegrationAdvancedPreferences
 * @brief Provide advanced preferences for the address book integration
 */
@implementation ESAddressBookIntegrationAdvancedPreferences
- (AIPreferenceCategory)category{
	return AIPref_Advanced;
}
- (NSString *)paneIdentifier{
	return @"AddressBookAdvanced";
}
- (NSString *)paneName{
    return AILocalizedString(@"Address Book",nil);
}
- (NSString *)nibName{
    return @"Preferences-AddressBookIntegration";
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"pref-address-book" forClass:[self class]];
}

/*!
 * @brief Configure the preference view
 */
- (void)viewDidLoad
{
	NSString *displayFormat = [adium.preferenceController preferenceForKey:KEY_AB_DISPLAYFORMAT group:PREF_GROUP_ADDRESSBOOK];
	[tokenField_format setDelegate:self];
	[tokenField_format setTokenizingCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
	[tokenField_format setObjectValue:[self separateStringIntoTokens:displayFormat]];

	[tokenField_firstToken setDelegate:self];
	[tokenField_firstToken setStringValue:FORMAT_FIRST_FULL];
	[tokenField_middleToken setDelegate:self];
	[tokenField_middleToken setStringValue:FORMAT_MIDDLE_FULL];
	[tokenField_lastToken setDelegate:self];
	[tokenField_lastToken setStringValue:FORMAT_LAST_FULL];
	[tokenField_nickToken setDelegate:self];
	[tokenField_nickToken setStringValue:FORMAT_NICK_FULL];

	[checkBox_enableImport setState:[[adium.preferenceController preferenceForKey:KEY_AB_ENABLE_IMPORT
																			  group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	[checkBox_useFirstName setState:[[adium.preferenceController preferenceForKey:KEY_AB_USE_FIRSTNAME
																			group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	[checkBox_useNickName setState:[[adium.preferenceController preferenceForKey:KEY_AB_USE_NICKNAME
																			 group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	[checkBox_syncAutomatic setState:[[adium.preferenceController preferenceForKey:KEY_AB_IMAGE_SYNC
																			   group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	[checkBox_useABImages setState:[[adium.preferenceController preferenceForKey:KEY_AB_USE_IMAGES
																			 group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	[checkBox_enableNoteSync setState:[[adium.preferenceController preferenceForKey:KEY_AB_NOTE_SYNC
																				group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	[checkBox_preferABImages setState:[[adium.preferenceController preferenceForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES
																				group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	[checkBox_metaContacts setState:[[adium.preferenceController preferenceForKey:KEY_AB_CREATE_METACONTACTS
																			  group:PREF_GROUP_ADDRESSBOOK] boolValue]];
	
	[self configureControlDimming];
}

- (void)localizePane
{
	[label_instructions setLocalizedString:AILocalizedString(@"Type text and drag name elements to create a custom name format.", nil)];
	[label_names setLocalizedString:AILocalizedString(@"Names:",nil)];
	[label_images setLocalizedString:AILocalizedString(@"Images:",nil)];
	[label_contacts setLocalizedString:AILocalizedString(@"Contacts:",nil)];
	
	[box_nameElements setTitle:AILocalizedString(@"Name elements", "Contains name format tokens")];
	
	[label_firstToken setLocalizedString:AILocalizedString(@"First", "First name token")];
	[label_middleToken setLocalizedString:AILocalizedString(@"Middle", "Middle name token")];
	[label_lastToken setLocalizedString:AILocalizedString(@"Last", "Last name token")];
	[label_nickToken setLocalizedString:AILocalizedString(@"Nick", "Nickname token")];
	
	[checkBox_enableImport setLocalizedString:AILocalizedString(@"Import my contacts' names from the Address Book",nil)];
	[checkBox_useFirstName setLocalizedString:AILocalizedString(@"Replace Nick with First if not available", nil)];
	[checkBox_useNickName setLocalizedString:AILocalizedString(@"Use Nick exclusively if available",nil)];
	[checkBox_useABImages setLocalizedString:AILocalizedString(@"Use Address Book images as contacts' icons",nil)];
	[checkBox_preferABImages setLocalizedString:AILocalizedString(@"Even if the contact already has a contact icon",nil)];
	[checkBox_syncAutomatic setLocalizedString:AILocalizedString(@"Overwrite Address Book images with contacts' icons",nil)];
	[checkBox_metaContacts setLocalizedString:AILocalizedString(@"Combine contacts listed on a single card",nil)];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[super dealloc];
}

/*!
 * @brief Configure control dimming
 */
- (void)configureControlDimming
{
	BOOL            enableImport = [[adium.preferenceController preferenceForKey:KEY_AB_ENABLE_IMPORT
																			 group:PREF_GROUP_ADDRESSBOOK] boolValue];
	BOOL            useImages = [[adium.preferenceController preferenceForKey:KEY_AB_USE_IMAGES
																		  group:PREF_GROUP_ADDRESSBOOK] boolValue];
	
	[label_instructions setTextColor:((enableImport) ? [NSColor controlTextColor] : [NSColor disabledControlTextColor])];
	
	//Use Nick Name and the format menu are irrelevent if importing of names is not enabled
	[checkBox_useFirstName setEnabled:enableImport];
	[checkBox_useNickName setEnabled:enableImport];
	
	[tokenField_format setEnabled:enableImport];
	[tokenField_firstToken setEnabled:enableImport];
	[tokenField_middleToken setEnabled:enableImport];
	[tokenField_lastToken setEnabled:enableImport];
	[tokenField_nickToken setEnabled:enableImport];

	//Disable the image priority checkbox if we aren't using images
	[checkBox_preferABImages setEnabled:useImages];
}

/*!
 * @brief Save changed name format preference
 */
- (IBAction)changeFormat:(id)sender
{
	[adium.preferenceController setPreference:[[sender objectValue] componentsJoinedByString:@""]
									   forKey:KEY_AB_DISPLAYFORMAT
                                        group:PREF_GROUP_ADDRESSBOOK];
}

/*!
 * @brief Save changed preference
 */
- (IBAction)changePreference:(id)sender
{
    if (sender == checkBox_syncAutomatic) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_IMAGE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_useABImages) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
                                             forKey:KEY_AB_USE_IMAGES
                                              group:PREF_GROUP_ADDRESSBOOK];
	} else if (sender == checkBox_useFirstName) {
		[adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
										   forKey:KEY_AB_USE_FIRSTNAME
											group:PREF_GROUP_ADDRESSBOOK];
    } else if (sender == checkBox_useNickName) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state]==NSOnState)]
										   forKey:KEY_AB_USE_NICKNAME
                                            group:PREF_GROUP_ADDRESSBOOK];
    } else if (sender == checkBox_enableImport) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_ENABLE_IMPORT
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_preferABImages) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_enableNoteSync) {
        [adium.preferenceController setPreference:[NSNumber numberWithBool:([sender state] == NSOnState)]
                                             forKey:KEY_AB_NOTE_SYNC
                                              group:PREF_GROUP_ADDRESSBOOK];
		
    } else if (sender == checkBox_metaContacts) {
		BOOL shouldCreateMetaContacts = ([sender state] == NSOnState);
		
		if (shouldCreateMetaContacts) {
			[adium.preferenceController setPreference:[NSNumber numberWithBool:YES]
												 forKey:KEY_AB_CREATE_METACONTACTS
												  group:PREF_GROUP_ADDRESSBOOK];		
			
		} else {
			NSBeginAlertSheet(nil,
							  AILocalizedString(@"Unconsolidate all metacontacts",nil),
							  AILocalizedString(@"Cancel",nil), nil,
							  [[self view] window], self,
							  @selector(sheetDidEnd:returnCode:contextInfo:), NULL,
							  NULL,
							  AILocalizedString(@"Disabling automatic contact consolidation will also unconsolidate all existing metacontacts, including any created manually.  You will need to recreate any manually-created metacontacts if you proceed.",nil));
		}
	}

    [self configureControlDimming];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		//If we now shouldn't create metaContacts, clear 'em all... not pretty, but effective.

		//Delay to the next run loop to give better UI responsiveness
		[adium.contactController performSelector:@selector(clearAllMetaContactData)
										withObject:nil
										afterDelay:0];
		
		
		[adium.preferenceController setPreference:[NSNumber numberWithBool:NO]
                                             forKey:KEY_AB_CREATE_METACONTACTS
                                              group:PREF_GROUP_ADDRESSBOOK];		
	} else {
		//Put the checkbox back
		[checkBox_metaContacts setState:![checkBox_metaContacts state]];
	}
}


#pragma mark Token Field Delegate

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	NSString *tokenStrings = [tokens componentsJoinedByString:@""];
	return [self separateStringIntoTokens:tokenStrings];
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard
{
	[pboard setString:[objects componentsJoinedByString:@""] forType:NSStringPboardType];
	return YES;
}

- (NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard
{
	return [self separateStringIntoTokens:[pboard stringForType:NSStringPboardType]];
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
	if ([representedObject hasPrefix:@"%["] && [representedObject hasSuffix:@"]"]) {
		return NSRoundedTokenStyle;
	} else {
		return NSPlainTextTokenStyle;
	}
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
	if ([representedObject isEqualToString:FORMAT_FIRST_FULL]) {
		return @"Evan";
	} else if ([representedObject isEqualToString:FORMAT_FIRST_INITIAL]) {
		return @"E";
	} else if ([representedObject isEqualToString:FORMAT_MIDDLE_FULL]) {
		return @"Dreskin";
	} else if ([representedObject isEqualToString:FORMAT_MIDDLE_INITIAL]) {
		return @"D";
	} else if ([representedObject isEqualToString:FORMAT_LAST_FULL]) {
		return @"Schoenberg";
	} else if ([representedObject isEqualToString:FORMAT_LAST_INITIAL]) {
		return @"S";
	} else if ([representedObject isEqualToString:FORMAT_NICK_FULL]) {
		return @"TekJew";
	} else if ([representedObject isEqualToString:FORMAT_NICK_INITIAL]) {
		return @"T";
	} else {
		return nil;
	}
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject
{
	if ([representedObject hasPrefix:@"%["] && [representedObject hasSuffix:@"]"]) {
		return nil;
	} else {
		return representedObject;
	}
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
	if ([editingString hasPrefix:@"%["] && [editingString hasSuffix:@"]"]) {
		// Return mutable string as formats should be modifiable
		return [NSMutableString stringWithString:editingString];
	} else {
		return editingString;
	}
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
	if (tokenField == tokenField_format) {
		// Only tokens in Format should have menus
		return YES;
	} else {
		return NO;
	}
}

- (NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject
{
	NSMenu *menu = [[[NSMenu alloc] init] autorelease];
	
	if (!representedObject)
		return nil;

	NSString *fullName = [self tokenField:tokenField 
		displayStringForRepresentedObject:[representedObject stringByReplacingOccurrencesOfString:@"INITIAL"
																					   withString:@"FULL"]];
	[menu addItemWithTitle:fullName
					target:self
					action:@selector(changeFormatToFullName:)
			 keyEquivalent:@"" 
		 representedObject:representedObject];
	
	NSString *initialCharacter = [self tokenField:tokenField
				displayStringForRepresentedObject:[representedObject stringByReplacingOccurrencesOfString:@"FULL"
																					   withString:@"INITIAL"]];
	[menu addItemWithTitle:initialCharacter
					target:self
					action:@selector(changeFormatToInitialCharacter:)
			 keyEquivalent:@""
		 representedObject:representedObject];
	
	return menu;
}

- (void)changeFormatToInitialCharacter:(id)sender
{
	[[sender representedObject] replaceOccurrencesOfString:FORMAT_FULL
												withString:FORMAT_INITIAL
												   options:NSLiteralSearch 
													 range:NSMakeRange(0, [[sender representedObject] length])];
	
	[tokenField_format updateDisplay];
	[self changeFormat:tokenField_format];
}

- (void)changeFormatToFullName:(id)sender
{
	[[sender representedObject] replaceOccurrencesOfString:FORMAT_INITIAL
												withString:FORMAT_FULL
												   options:NSLiteralSearch 
													 range:NSMakeRange(0, [[sender representedObject] length])];

	[tokenField_format updateDisplay];
	[self changeFormat:tokenField_format];
}

- (NSArray *)separateStringIntoTokens:(NSString *)string
{
	NSMutableArray *tokens = [NSMutableArray array];
	
	int i = 0;
	while (i < [string length]) {
		unsigned int start = i;
		
		// Search for end of current token
		if ([[string substringFromIndex:i] hasPrefix:@"%["]) {
			for (; i < [string length]; i++) {
				if ([[string substringFromIndex:i] hasPrefix:@"]"]) {
					i++;
					break;
				}
			}
			
		// Search for start of next token
		} else {
			for (; i < [string length]; i++) {
				if ([[string substringFromIndex:(i + 1)] hasPrefix:@"%["]) {
					i++;
					break;
				}
			}
		}
		
		[tokens addObject:[[[string substringWithRange:NSMakeRange(start, i - start)] mutableCopy] autorelease]];
	}
	
	return tokens;
}

@end
