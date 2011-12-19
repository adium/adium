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

#import "AIPreferencePane.h"

@interface AIWindowHandlingPreferences : AIPreferencePane {
	AILocalizationTextField *label_statusWindow;
	AILocalizationTextField *label_chatWindows;
	AILocalizationTextField *label_contactList;
	AILocalizationTextField *label_autoHide;
	AILocalizationTextField *label_show;
	AILocalizationTextField *label_order;
	
	NSPopUpButton *popUp_chatWindowPosition;
	NSPopUpButton *popUp_contactListWindowPosition;
	NSMatrix *matrix_hiding;
	
	AILocalizationButton *checkBox_hideOnScreenEdgesOnlyInBackground;
	AILocalizationButton *checkBox_showOnAllSpaces;
	AILocalizationButton *checkBox_hideInBackground;
	AILocalizationButton *checkBox_statusWindowHideInBackground;
	AILocalizationButton *checkBox_statusWindowAlwaysOnTop;
}

@property (assign) IBOutlet AILocalizationTextField *label_contactList;
@property (assign) IBOutlet AILocalizationTextField *label_autoHide;
@property (assign) IBOutlet AILocalizationTextField *label_statusWindow;
@property (assign) IBOutlet AILocalizationTextField *label_chatWindows;
@property (assign) IBOutlet AILocalizationTextField *label_show;
@property (assign) IBOutlet AILocalizationTextField *label_order;

@property (assign) IBOutlet NSPopUpButton *popUp_chatWindowPosition;
@property (assign) IBOutlet NSPopUpButton *popUp_contactListWindowPosition;
@property (assign) IBOutlet NSMatrix *matrix_hiding;

@property (assign) IBOutlet AILocalizationButton *checkBox_hideOnScreenEdgesOnlyInBackground;
@property (assign) IBOutlet AILocalizationButton *checkBox_showOnAllSpaces;
@property (assign) IBOutlet AILocalizationButton *checkBox_hideInBackground;
@property (assign) IBOutlet AILocalizationButton *checkBox_statusWindowHideInBackground;
@property (assign) IBOutlet AILocalizationButton *checkBox_statusWindowAlwaysOnTop;

@end
