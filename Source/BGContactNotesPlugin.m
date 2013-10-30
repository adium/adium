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

#import <Adium/AIContactControllerProtocol.h>
//#import "AIContactInfoWindowController.h"
//#import "AIContactListEditorPlugin.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import "BGContactNotesPlugin.h"
//#import <AddressBook/AddressBook.h>
#import <Adium/AIListObject.h>

#define KEY_AB_NOTE_SYNC			@"AB Note Sync"

/*!
 * @class BGContactNotesPlugin
 * @brief Component to show contact notes in tooltips
 */
@implementation BGContactNotesPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{    
    //Install our tooltip entry
    [adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:YES];
}

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
    return AILocalizedString(@"Notes", "Short identifier for the 'notes' which can be entered for contacts. This will be shown in the contact list tooltips.");
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSAttributedString  *entry = nil;
	NSString			*currentNotes;
    
	if ((currentNotes = [inObject preferenceForKey:@"Notes" group:PREF_GROUP_NOTES]) ||
	   (currentNotes = [inObject valueForProperty:@"Notes"])) {
        entry = [[NSAttributedString alloc] initWithString:currentNotes];
    }
    
    return entry;
}

- (BOOL)shouldDisplayInContactInspector
{
	return YES;
}

@end
