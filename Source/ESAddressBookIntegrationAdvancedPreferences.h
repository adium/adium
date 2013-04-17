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

#import <Adium/AIPreferencePane.h>

@class AILocalizationTextField;

@interface ESAddressBookIntegrationAdvancedPreferences : AIPreferencePane <NSTokenFieldDelegate> {
    IBOutlet    NSButton                *checkBox_syncAutomatic;
    IBOutlet	NSButton                *checkBox_useABImages;
    IBOutlet	NSButton				*checkBox_preferABImages;

    IBOutlet	NSButton                *checkBox_enableImport;
	IBOutlet	NSButton				*checkBox_useFirstName;
	IBOutlet    NSButton                *checkBox_useNickName;
		
    IBOutlet    NSButton                *checkBox_enableNoteSync;
	
	IBOutlet	NSButton				*checkBox_metaContacts;
	
	IBOutlet	AILocalizationTextField	*label_instructions;
	IBOutlet	AILocalizationTextField	*label_names;
	IBOutlet	AILocalizationTextField	*label_images;
	IBOutlet	AILocalizationTextField	*label_contacts;
	
	IBOutlet	NSBox					*box_nameElements;

	IBOutlet	AILocalizationTextField *label_firstToken;
	IBOutlet	AILocalizationTextField *label_middleToken;
	IBOutlet	AILocalizationTextField *label_lastToken;
	IBOutlet	AILocalizationTextField *label_nickToken;
	
	IBOutlet	NSTokenField			*tokenField_format;
	IBOutlet	NSTokenField			*tokenField_firstToken;
	IBOutlet	NSTokenField			*tokenField_middleToken;
	IBOutlet	NSTokenField			*tokenField_lastToken;
	IBOutlet	NSTokenField			*tokenField_nickToken;
}

- (IBAction)changePreference:(id)sender;

@end
