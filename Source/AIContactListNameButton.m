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

#import "AIContactListNameButton.h"
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>

@implementation AIContactListNameButton

- (void)drawRect:(NSRect)inRect
{
	if (!textField_editor) {
		[super drawRect:inRect];
	}
}

/*!
 * @brief Begin editing a specified name
 */
- (void)editName:(NSString *)startingString
{
	if (!textField_editor) {
		NSRect			editingFrame;
		
		editingFrame = [self frame];
		editingFrame.origin = NSMakePoint(3, 1);

		NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																				lineBreakMode:NSLineBreakByTruncatingMiddle];
		[paragraphStyle setMaximumLineHeight:editingFrame.size.height];
		NSAttributedString		*attributedString = [[NSAttributedString alloc] initWithString:(startingString ? startingString : @"")
																					 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																						 [[self cell] font], NSFontAttributeName,
																						 paragraphStyle, NSParagraphStyleAttributeName,
																						 nil]];
		textField_editor = [[NSTextField alloc] initWithFrame:editingFrame];
		[textField_editor setAttributedStringValue:attributedString];
		[attributedString release];
	
		[textField_editor setFocusRingType:NSFocusRingTypeNone];
		[textField_editor setDelegate:self];
		[textField_editor setEditable:YES];
		[textField_editor setFont:[[self cell] font]];
		[textField_editor setBordered:NO];
		[textField_editor setDrawsBackground:NO];
		[[textField_editor cell] setDrawsBackground:NO];
		[[textField_editor cell] setScrollable:YES];

		[self addSubview:textField_editor];
		[[self window] makeFirstResponder:textField_editor];
		[[self superview] display];		
	}	
}

/*!
 * @brief The text finished editing
 */
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[editTarget mainPerformSelector:editSelector
						 withObject:self
						 withObject:[textField_editor stringValue]
						 withObject:editUserInfo];

	[textField_editor removeFromSuperview];
	[textField_editor release]; textField_editor = nil;

	[self resetCursorRects];
}

/*!
 * @brief Edit the name
 *
 * @param startingString The name to initially show in the editor. We don't use our title because the title might have been filtered
 * @param inTarget The target to notify, which must implement inSelector
 * @param inSelector The selector, which should be of the form nameView:didChangeToString:userInfo:
 * @param inUserInfo Userinfo which will be passed back to inTarget via inSelector
 */
- (void)editNameStartingWithString:(NSString *)startingString notifyingTarget:(id)inTarget selector:(SEL)inSelector userInfo:(id)inUserInfo
{
	[self editName:startingString];
	
	if (editTarget != inTarget) {
		[editTarget release];
		editTarget = [inTarget retain];
	}
	
	editSelector = inSelector;
	
	if (inUserInfo != editUserInfo) {
		[editUserInfo release];
		editUserInfo = [inUserInfo retain];
	}
}

- (NSRect)trackingRect
{
	NSRect trackingRect = [super trackingRect];
	
	//Don't let the bottommost part of our view qualify for highlighting; this lets it get closer to views below without leaving whitespace.
	trackingRect.size.height -= 2;

	return trackingRect;
}

@end
