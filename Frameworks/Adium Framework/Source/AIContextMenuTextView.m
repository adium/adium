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

#import <Adium/AIContextMenuTextView.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <AIUtilities/AITextAttributes.h>

@implementation AIContextMenuTextView

- (void)_configureContextMenuTextView
{
	[self setDrawsBackground:YES];

	if ([self respondsToSelector:@selector(setAllowsUndo:)]) {
		[self setAllowsUndo:YES];
	}
	if ([self respondsToSelector:@selector(setAllowsDocumentBackgroundColorChange:)]) {
		[self setAllowsDocumentBackgroundColorChange:YES];
	}			
}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
	if ((self = [super initWithFrame:frameRect textContainer:aTextContainer])) {
		[self _configureContextMenuTextView];
	}

	return self;
}

- (void)awakeFromNib
{
	[self _configureContextMenuTextView];
}

+ (NSMenu *)defaultMenu
{
	NSMenu			*contextualMenu;
	
	NSArray			*itemsArray = nil;
	NSMenuItem		*menuItem;
	
	//Grab NSTextView's default menu, copying so we don't affect menus elsewhere
	contextualMenu = [[super defaultMenu] copy];
	
	//Retrieve the items which should be added to the bottom of the default menu
	NSMenu  *adiumMenu = [adium.menuController contextualMenuWithLocations:[NSArray arrayWithObjects:
		[NSNumber numberWithInt:Context_TextView_LinkEditing],
		[NSNumber numberWithInt:Context_TextView_Edit], nil]];

	itemsArray = [adiumMenu itemArray];
	
	if ([itemsArray count] > 0) {
		[contextualMenu addItem:[NSMenuItem separatorItem]];
		NSInteger i = [contextualMenu numberOfItems];
		for (menuItem in itemsArray) {
			//We're going to be copying; call menu needs update now since it won't be called later.
			NSMenu	*submenu = [menuItem submenu];
			if (submenu &&
			   [submenu respondsToSelector:@selector(delegate)] &&
			   [[submenu delegate] respondsToSelector:@selector(menuNeedsUpdate:)]) {
				[[submenu delegate] menuNeedsUpdate:submenu];
			}
			
			[contextualMenu insertItem:[menuItem copy] atIndex:i++];
		}
	}
	
	return contextualMenu;
}

//Set our string, preserving the selected range
- (void)setAttributedString:(NSAttributedString *)inAttributedString
{
    NSInteger			length = [inAttributedString length];
    NSRange 	oldRange = [self selectedRange];
	
    //Change our string
    [[self textStorage] setAttributedString:inAttributedString];
	
    //Restore the old selected range
    if (oldRange.location < length) {
        if (oldRange.location + oldRange.length <= length) {
            [self setSelectedRange:oldRange];
        } else {
            [self setSelectedRange:NSMakeRange(oldRange.location, length - oldRange.location)];       
        }
    }
	
    //Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
}

- (void)textDidChange:(NSNotification *)notification
{
    if (([self selectedRange].location == 0) && ([self selectedRange].length == 0)) { //remove attributes if we're changing text at (0,0)
		NSDictionary		*currentTextAttribs = [self typingAttributes];
		
        if ([currentTextAttribs objectForKey:NSLinkAttributeName]) { // but only if we currently have a link there.
			NSMutableDictionary *textAttribs;
			
			textAttribs = [[self typingAttributes] mutableCopy];

            [textAttribs removeObjectsForKeys:[NSArray arrayWithObjects:NSLinkAttributeName, //the link
                                                                        NSUnderlineStyleAttributeName, //the line
                                                                        NSForegroundColorAttributeName, //the blue
                                                                        nil]]; //the myth
            [self setTypingAttributes:textAttribs];
        }
    }
}

//Paste as rich text without altering our typing attributes
- (void)pasteAsRichText:(id)sender
{
	NSDictionary	*attributes = [[self typingAttributes] copy];
	
	[super pasteAsRichText:sender];
	
	if (attributes) {
		[self setTypingAttributes:attributes];
	}
}

- (void)deleteBackward:(id)sender
{
	//Perform the delete
	[super deleteBackward:sender];
	
	//If we are now an empty string, and we still have a link active, clear the link
	if ([[self textStorage] length] == 0) {
		NSDictionary *typingAttributes = [self typingAttributes];
		if ([typingAttributes objectForKey:NSLinkAttributeName]) {
			
			NSMutableDictionary *newTypingAttributes = [typingAttributes mutableCopy];
			
			[newTypingAttributes removeObjectForKey:NSLinkAttributeName];
			[self setTypingAttributes:newTypingAttributes];
		}
	}
}

//Set our typing format
- (void)setTypingAttributes:(NSDictionary *)attrs
{
	NSColor	*backgroundColor;
	[super setTypingAttributes:attrs];

	//Correctly set our background color
	if ((backgroundColor = [attrs objectForKey:AIBodyColorAttributeName])) {
		[self setBackgroundColor:backgroundColor];
	} else {
		static NSColor	*cachedWhiteColor = nil;

		//Create cachedWhiteColor first time we're called; we'll need it later, repeatedly
		if (!cachedWhiteColor) cachedWhiteColor = [NSColor whiteColor];

		[self setBackgroundColor:cachedWhiteColor];
	}
}
@end
