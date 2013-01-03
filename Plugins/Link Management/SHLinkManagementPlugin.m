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

#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import "SHLinkEditorWindowController.h"
#import "SHLinkManagementPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>

#define ADD_LINK_TITLE			[AILocalizedString(@"Add Link",nil) stringByAppendingEllipsis]
#define EDIT_LINK_TITLE			[AILocalizedString(@"Edit Link",nil) stringByAppendingEllipsis]
#define RM_LINK_TITLE           AILocalizedString(@"Remove Link",nil)

@interface SHLinkManagementPlugin ()
- (BOOL)textViewSelectionIsLink:(NSTextView *)textView;
- (void)registerToolbarItem;
- (IBAction)editFormattedLink:(id)sender;
- (IBAction)removeFormattedLink:(id)sender;
@end

@implementation SHLinkManagementPlugin

- (void)installPlugin
{
	NSMenuItem	*menuItem;
	
    //Add/Edit Link... menu item (edit menu)
    menuItem = [[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
																	 target:self
																	 action:@selector(editFormattedLink:)
															  keyEquivalent:@"k"];
    [adium.menuController addMenuItem:menuItem toLocation:LOC_Edit_Links];
    
    //Context menu
    menuItem = [[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
																	 target:self
																	 action:@selector(editFormattedLink:)
															  keyEquivalent:@""];
    [adium.menuController addContextualMenuItem:menuItem toLocation:Context_TextView_LinkEditing];
    [self registerToolbarItem];
}

- (void)uninstallPlugin
{
	
}

//Update our add/edit link menu item
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	if (responder && [responder isKindOfClass:[NSTextView class]]) {
		if ([[menuItem title] isEqualToString:RM_LINK_TITLE]) {
			// only make remove link menu item active if slection is a link.
			return [self textViewSelectionIsLink:(NSTextView *)responder];
		} else {
			//Update the menu item's title to reflect the current action
			[menuItem setTitle:([self textViewSelectionIsLink:(NSTextView *)responder] ? EDIT_LINK_TITLE : ADD_LINK_TITLE)];
			
			return ([(NSTextView *)responder isEditable] && [(NSTextView *)responder isRichText]);
		}
	} else {
		return NO; //Disable the menu item if a text field is not key
	}
	
}

//Add or edit a link
- (IBAction)editFormattedLink:(id)sender
{
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSTextView	*earliestTextView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];

    if (earliestTextView &&
		![[keyWin windowController] isKindOfClass:[SHLinkEditorWindowController class]]) {
		SHLinkEditorWindowController *linkEditorWindowController = [[SHLinkEditorWindowController alloc] initWithTextView:earliestTextView
																										  notifyingTarget:nil];
		[linkEditorWindowController showOnWindow:keyWin];
    }
}

- (IBAction)removeFormattedLink:(id)sender
{
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSTextView	*earliestTextView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];
    
	if (earliestTextView) {
		NSRange	selectedRange = [earliestTextView selectedRange];
		
		if ([[earliestTextView textStorage] length] &&
			selectedRange.location != NSNotFound &&
			selectedRange.location != [[earliestTextView textStorage] length]) {
			
			[[earliestTextView textStorage] attribute:NSLinkAttributeName
											  atIndex:selectedRange.location
									   effectiveRange:&selectedRange];
			[[earliestTextView textStorage] removeAttribute:NSLinkAttributeName range:selectedRange];			
		}
	}	
}

//Returns YES if a link is under the selection of the passed text view
- (BOOL)textViewSelectionIsLink:(NSTextView *)textView
{
	id		selectedLink = nil;
	
	if ([[textView textStorage] length] &&
	   [textView selectedRange].location != NSNotFound &&
	   [textView selectedRange].location != [[textView textStorage] length]) {
		NSRange selectionRange = [textView selectedRange];
		selectedLink = [[textView textStorage] attribute:NSLinkAttributeName
												 atIndex:selectionRange.location
										  effectiveRange:&selectionRange];
	}
	
	return selectedLink != nil;
}

#pragma mark Toolbar Item stuff

- (void)registerToolbarItem
{
    //Unregister the existing toolbar item first
    if (toolbarItem) {
        [adium.toolbarController unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		toolbarItem = nil;
    }
    
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"LinkEditor"
                                                           label:AILocalizedString(@"Link",nil)
                                                    paletteLabel:AILocalizedString(@"Insert Link",nil)
                                                         toolTip:AILocalizedString(@"Add/Edit Hyperlink",nil)
                                                          target:self
                                                 settingSelector:@selector(setImage:)
                                                     itemContent:[NSImage imageNamed:@"msg-insert-link" forClass:[self class] loadLazily:YES]
                                                          action:@selector(editFormattedLink:)
                                                            menu:nil];
    
    [adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}
@end
