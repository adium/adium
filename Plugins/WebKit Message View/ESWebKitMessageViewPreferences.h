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
#import "AIWebKitMessageViewPlugin.h"

@class ESWebView, AIContentObject, AIAutoScrollView, AIWebKitPreviewMessageViewController;
@class JVFontPreviewField, AIImageViewWithImagePicker;

/*!
 *	@class ESWebKitMessageViewPreferences ESWebKitMessageViewPreferences.h
 *	@brief Handles the messages preference pane
 */
@interface ESWebKitMessageViewPreferences : AIPreferencePane {
	IBOutlet	NSTabView			*tabView_messageType;
	IBOutlet	NSTabViewItem		*tabViewItem_regularChat;
	IBOutlet	NSTabViewItem		*tabViewItem_groupChat;
	
	IBOutlet	NSButton			*checkBox_useRegularChatForGroup;
	
	IBOutlet	JVFontPreviewField  *fontPreviewField_currentFont;
	IBOutlet	NSButton			*button_setFont;
	IBOutlet	NSButton			*button_defaultFont;
	
	IBOutlet	NSPopUpButton   	*popUp_styles;
	IBOutlet	NSPopUpButton   	*popUp_variants;
	IBOutlet	NSPopUpButton   	*popUp_backgroundImageType;
	IBOutlet	NSColorWell			*colorWell_customBackgroundColor;
	IBOutlet	AIImageViewWithImagePicker	*imageView_backgroundImage;
	IBOutlet    NSButton        	*checkBox_showUserIcons;
	IBOutlet    NSButton        	*checkBox_showHeader;
	IBOutlet	NSButton			*checkBox_showMessageColors;
	IBOutlet	NSButton			*checkBox_showMessageFonts;
	IBOutlet	NSButton			*checkBox_useCustomBackground;
	
	//Message preview
	IBOutlet	NSView						*view_previewLocation;
	NSMutableDictionary						*previewListObjectsDict;
	AIWebKitPreviewMessageViewController	*previewController;
	ESWebView								*preview;
	
	BOOL							viewIsOpen;
}

/*!
 *	@brief Rebuild our styles menu when installed message styles change
 */
- (void)messageStyleXtrasDidChange;

/*!
 * @brief Reset display font to the default value
 */
- (IBAction)resetDisplayFontToDefault:(id)sender;

@property (readonly, nonatomic) NSString *preferenceGroupForCurrentTab;
@property (readonly, nonatomic) AIWebkitStyleType currentTab;

@end
