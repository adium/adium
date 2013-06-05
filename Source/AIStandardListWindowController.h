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

#import <AIUtilities/AIRolloverButton.h>
#import "AIListWindowController.h"
#import <Adium/AIStatusMenu.h>

#define ALL_OTHER_ACCOUNTS AILocalizedString(@"All Other Accounts", nil)

@protocol StateMenuPlugin;
@class AIAccount, AIHoveringPopUpButton, AIContactListNameButton, AIContactListImagePicker;

typedef enum {
	ContactListImagePickerOnLeft = 0,
	ContactListImagePickerOnRight,
	ContactListImagePickerHiddenOnLeft,
	ContactListImagePickerHiddenOnRight,
} ContactListImagePickerPosition;

@interface AIStandardListWindowController : AIListWindowController <AIStatusMenuDelegate, NSToolbarDelegate> {
	IBOutlet	NSView						*view_statusAndImage;
	
	IBOutlet	NSView						*view_nameAndStatusMenu;
	IBOutlet	AIHoveringPopUpButton		*statusMenuView;
	IBOutlet	AIContactListNameButton		*nameView;
	IBOutlet	NSImageView					*imageView_status;
	
	IBOutlet	AIContactListImagePicker	*imagePicker;

	ContactListImagePickerPosition			imagePickerPosition;
	
	AIStatusMenu				*statusMenu;
}


- (void)updateImagePicker;

+ (AIAccount *)activeAccountForIconsGettingOnlineAccounts:(NSMutableSet *)onlineAccounts
										  ownIconAccounts:(NSMutableSet *)ownIconAccounts;
+ (AIAccount *)activeAccountForDisplayNameGettingOnlineAccounts:(NSMutableSet *)onlineAccounts
										 ownDisplayNameAccounts:(NSMutableSet *)ownDisplayNameAccounts;
@end
