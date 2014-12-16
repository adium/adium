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

@interface ESContactListAdvancedPreferences : AIPreferencePane {
	//Display/Visibility
	IBOutlet NSPopUpButton *popUp_sortContacts;
	IBOutlet NSPopUpButton *popUp_contactNameFormat;
	
	IBOutlet AILocalizationButton *button_sortContacts;
	IBOutlet AILocalizationButton *button_hideAccounts;
	
	IBOutlet AILocalizationButton *checkBox_hideCertainContacts;
	IBOutlet AILocalizationButton *checkBox_hideOffline;
	IBOutlet AILocalizationButton *checkBox_hideIdle;
	IBOutlet AILocalizationButton *checkBox_hideAway;
	IBOutlet AILocalizationButton *checkBox_hideMobile;
	IBOutlet AILocalizationButton *checkBox_hideBlocked;
	IBOutlet AILocalizationButton *checkBox_showGroups;
	IBOutlet AILocalizationButton *checkBox_groupOfflineContacts;
	IBOutlet AILocalizationButton *checkBox_showGroupTotalCount;
	IBOutlet AILocalizationButton *checkBox_showGroupOnlineCount;
	
	IBOutlet AILocalizationTextField *label_sortContacts;
	IBOutlet AILocalizationTextField *label_contactNameFormat;
	IBOutlet AILocalizationTextField *label_contactHiding;
	IBOutlet AILocalizationTextField *label_contactGroups;
	
	NSArray *_hideAccounts;
	
	//Theming
	IBOutlet	NSPopUpButton	*popUp_listLayout;
	IBOutlet	NSPopUpButton	*popUp_colorTheme;
	IBOutlet	NSPopUpButton	*popUp_windowStyle;
	
	IBOutlet	NSButton		*button_colorTheme;
	IBOutlet	NSButton		*button_listLayout;
	IBOutlet	NSButton		*checkBox_verticalAutosizing;
	IBOutlet	NSButton		*checkBox_horizontalAutosizing;
	
	IBOutlet	NSButton		*checkBox_flash;
	IBOutlet	NSButton		*checkBox_animateChanges;
	IBOutlet	NSButton		*checkBox_showTooltips;
	IBOutlet	NSButton		*checkBox_showTooltipsInBackground;
	IBOutlet	NSButton		*checkBox_windowHasShadow;

	IBOutlet	AILocalizationTextField		*label_colorTheme;
	IBOutlet	AILocalizationTextField		*label_listLayout;
	IBOutlet	AILocalizationTextField		*label_windowStyle;
	IBOutlet	AILocalizationTextField		*label_opacity;
	IBOutlet	AILocalizationTextField		*label_automaticSizing;
	IBOutlet	AILocalizationTextField		*label_horizontalWidth;
	IBOutlet	AILocalizationTextField		*label_verticalHeight;
	IBOutlet	AILocalizationTextField		*label_animation;
	IBOutlet	AILocalizationTextField		*label_tooltips;
	
	IBOutlet	NSSlider		*slider_windowOpacity;
	IBOutlet	NSTextField		*textField_windowOpacity;
	
	IBOutlet	NSSlider		*slider_horizontalWidth;
	IBOutlet	NSTextField		*textField_horizontalWidth;
	IBOutlet	NSSlider		*slider_verticalHeight;
	IBOutlet	NSTextField		*textField_verticalHeight;
	
	//
	NSArray		*_listLayouts;	//Will NOT always be a valid reference.  Do not use as one!
	NSArray		*_listThemes;	//Will NOT always be a valid reference.  Do not use as one!
}

- (IBAction)customizeListLayout:(id)sender;
- (IBAction)customizeListTheme:(id)sender;
- (IBAction)customizeSort:(id)sender;
- (IBAction)customizeHiddenAccounts:(id)sender;

@end
