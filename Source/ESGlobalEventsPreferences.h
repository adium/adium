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

#define OTHER						AILocalizedString(@"Other",nil)
#define OTHER_ELLIPSIS				[OTHER stringByAppendingEllipsis]
#define SOUND_MENU_ICON_SIZE		16

@class ESContactAlertsViewController, AIVariableHeightOutlineView;

@interface ESGlobalEventsPreferences : AIPreferencePane {
	IBOutlet	ESContactAlertsViewController	*contactAlertsViewController;
	
	IBOutlet	NSPopUpButton	*popUp_eventPreset;
	IBOutlet	NSPopUpButton	*popUp_soundSet;
		
	IBOutlet	NSTextField		*label_eventPreset;
	IBOutlet	NSTextField		*label_soundSet;
	
	IBOutlet	NSSlider		*slider_volume;
	IBOutlet	NSButton		*button_minvolume;
	IBOutlet	NSButton		*button_maxvolume;	
}

- (IBAction)selectedNameForPresetCopy:(id)sender;
- (IBAction)selectVolume:(id)sender;


@end
