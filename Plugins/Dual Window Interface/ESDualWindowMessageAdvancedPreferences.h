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

#import <Adium/AIAdvancedPreferencePane.h>
#import "AIWebKitMessageViewPlugin.h"

@interface ESDualWindowMessageAdvancedPreferences : AIAdvancedPreferencePane {
	IBOutlet	NSTabView		*tabView_messageType;
	IBOutlet	NSTabViewItem	*tabViewItem_regular;
	IBOutlet	NSTabViewItem	*tabViewItem_group;
	
	// Regular/Group Chat false tabs
	IBOutlet	NSButton		*checkBox_customNameFormatting;
	IBOutlet	NSPopUpButton   *popUp_nameFormat;
	
	IBOutlet	NSPopUpButton	*popUp_timeStampFormat;
	
	IBOutlet	NSPopUpButton	*popUp_minimumFontSize;	
	
	IBOutlet	NSButton		*checkBox_showTabCount;
	IBOutlet	NSButton		*checkBox_unreadMentionCount;
	
	// Tabs
	IBOutlet	NSButton		*autohide_tabBar;	
	
	// Window Handling
	IBOutlet	NSButton		*checkBox_hide;
	IBOutlet	NSButton		*checkBox_psychicOpen;
	IBOutlet	NSPopUpButton	*popUp_windowPosition;
}

@property (readonly, nonatomic) NSString *preferenceGroupForCurrentTab;
@property (readonly, nonatomic) AIWebkitStyleType currentTab;

@end
