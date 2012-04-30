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

#import <Adium/AIWindowController.h>

@class AITextColorPreviewView;

@interface AIListThemeWindowController : AIWindowController {
	IBOutlet	NSTextField				*textField_themeName;
	
    IBOutlet	NSButton				*checkBox_signedOff;
    IBOutlet	NSColorWell				*colorWell_signedOff;
    IBOutlet	NSColorWell				*colorWell_signedOffLabel;
	IBOutlet	AITextColorPreviewView	*preview_signedOff;
	
    IBOutlet	NSButton				*checkBox_signedOn;
    IBOutlet	NSColorWell				*colorWell_signedOn;
    IBOutlet	NSColorWell				*colorWell_signedOnLabel;
	IBOutlet	AITextColorPreviewView	*preview_signedOn;
	
    IBOutlet	NSButton				*checkBox_away;
    IBOutlet	NSColorWell				*colorWell_away;
    IBOutlet	NSColorWell				*colorWell_awayLabel;
	IBOutlet	AITextColorPreviewView	*preview_away;
	
    IBOutlet	NSButton				*checkBox_idle;
    IBOutlet	NSColorWell				*colorWell_idle;
    IBOutlet	NSColorWell				*colorWell_idleLabel;
	IBOutlet	AITextColorPreviewView	*preview_idle;
	
    IBOutlet	NSButton				*checkBox_typing;
    IBOutlet	NSColorWell				*colorWell_typing;
    IBOutlet	NSColorWell				*colorWell_typingLabel;
	IBOutlet	AITextColorPreviewView	*preview_typing;
	
    IBOutlet	NSButton				*checkBox_unviewedContent;
    IBOutlet	NSColorWell				*colorWell_unviewedContent;
    IBOutlet	NSColorWell				*colorWell_unviewedContentLabel;
	IBOutlet	AITextColorPreviewView	*preview_unviewedContent;
	
    IBOutlet	NSButton				*checkBox_online;
    IBOutlet	NSColorWell				*colorWell_online;
    IBOutlet	NSColorWell				*colorWell_onlineLabel;
	IBOutlet	AITextColorPreviewView	*preview_online;
	
    IBOutlet	NSButton				*checkBox_idleAndAway;
    IBOutlet	NSColorWell				*colorWell_idleAndAway;
    IBOutlet	NSColorWell				*colorWell_idleAndAwayLabel;
	IBOutlet	AITextColorPreviewView	*preview_idleAndAway;
	
    IBOutlet	NSButton				*checkBox_offline;
    IBOutlet	NSColorWell				*colorWell_offline;
    IBOutlet	NSColorWell				*colorWell_offlineLabel;
	IBOutlet	AITextColorPreviewView	*preview_offline;
	
	IBOutlet	NSButton				*checkBox_useBackgroundImage;
	IBOutlet	NSButton				*button_setBackgroundImage;
	IBOutlet	NSTextField				*textField_backgroundImagePath;
	IBOutlet	NSSlider				*slider_backgroundFade;
	IBOutlet	NSTextField				*textField_backgroundFade;
	IBOutlet	NSPopUpButton			*popUp_displayImageStyle;
	
	IBOutlet	NSColorWell				*colorWell_background;
	IBOutlet	AITextColorPreviewView	*preview_background;
	IBOutlet	NSColorWell				*colorWell_customHighlight;
	IBOutlet	AITextColorPreviewView	*preview_customHighlight;
	IBOutlet	NSButton				*checkBox_drawCustomHighlight;
	IBOutlet	NSColorWell				*colorWell_grid;
	IBOutlet	AITextColorPreviewView	*preview_grid;
	IBOutlet	NSButton				*checkBox_drawGrid;
	IBOutlet	NSButton				*checkBox_backgroundAsStatus;
	IBOutlet	NSButton				*checkBox_backgroundAsEvents;
	IBOutlet	NSColorWell				*colorWell_statusText;
	IBOutlet	NSButton				*checkBox_fadeOfflineImages;

	IBOutlet	NSButton				*checkBox_groupGradient;
	IBOutlet	NSButton				*checkBox_groupShadow;
	IBOutlet	NSColorWell				*colorWell_groupText;
	IBOutlet	NSColorWell				*colorWell_groupShadow;
	IBOutlet	NSColorWell				*colorWell_groupBackground;
	IBOutlet	NSColorWell				*colorWell_groupBackgroundGradient;
	IBOutlet	AITextColorPreviewView	*preview_group;
	
	id				target;
	NSString		*themeName;
}

- (void)showOnWindow:(id)parentWindow __attribute__((ns_consumes_self));
- (id)initWithName:(NSString *)inName notifyingTarget:(id)inTarget;
- (IBAction)cancel:(id)sender;
- (IBAction)okay:(id)sender;
- (void)preferenceChanged:(id)sender;
- (IBAction)selectBackgroundImage:(id)sender;

@end

@interface NSObject (AIListThemeWindowTarget)

- (void)listThemeEditorWillCloseWithChanges:(BOOL)changes forThemeNamed:(NSString *)name;

@end
