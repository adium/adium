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

#define LINK_MANAGEMENT_DEFAULTS        @"LinkManagementDefaults"
#define PREF_GROUP_LINK_FAVORITES       @"URL Favorites"
#define KEY_LINK_FAVORITES				@"Favorite Links"
#define KEY_LINK_URL					@"URL"
#define KEY_LINK_TITLE					@"Title"

@class SHAutoValidatingTextView, AIAutoScrollView;

@interface SHLinkEditorWindowController : AIWindowController {
    
    IBOutlet NSButton                   *button_insert;
    IBOutlet NSButton                   *button_cancel;
	IBOutlet NSButton					*button_removeLink;
	
    IBOutlet NSTextField                *textField_linkText;
    IBOutlet AIAutoScrollView           *scrollView_URL;
    IBOutlet SHAutoValidatingTextView   *textView_URL;
    IBOutlet NSImageView                *imageView_invalidURLAlert;
    
	IBOutlet NSTextField				*label_linkText;
	IBOutlet NSTextField				*label_URL;
	
    NSTextView 							*textView;
    id 									target;
}

- (id)initWithTextView:(NSTextView *)inTextView notifyingTarget:(id)inTarget;
- (void)showOnWindow:(NSWindow *)parentWindow __attribute__((ns_consumes_self));

- (IBAction)cancel:(id)sender;
- (IBAction)acceptURL:(id)sender;
- (IBAction)removeURL:(id)sender;

@end
