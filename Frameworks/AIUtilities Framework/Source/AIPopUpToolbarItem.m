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

#import "AIPopUpToolbarItem.h"
#import "MVMenuButton.h"

@interface AIDelayedPopUpButton : MVMenuButton
@property BOOL mouseIsDown;
@property BOOL menuWasShownForLastMouseDown;
@property uint mouseDownUniquenessCounter;
@end

@implementation AIDelayedPopUpButton

// show the menu if the mouse is held down
- (void)mouseDown:(NSEvent *)theEvent
{
	self.mouseIsDown = YES;
	self.menuWasShownForLastMouseDown = NO;
	uint mouseDownUniquenessCounterCopy = ++(self.mouseDownUniquenessCounter);
	
	[self highlight:YES];
	
	float delayInSeconds = 0.2;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		if (self.mouseIsDown && mouseDownUniquenessCounterCopy == self.mouseDownUniquenessCounter) {
			self.menuWasShownForLastMouseDown = YES;
			[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
			[self highlight:NO];
		}
	});
}

// perform the button's action if the menu isn't showing
- (void)mouseUp:(NSEvent *)theEvent
{
	self.mouseIsDown = NO;
	
	if (!self.menuWasShownForLastMouseDown)
		[self sendAction:self.action to:self.target];
	
	[self highlight:NO];
}

@end


@implementation AIPopUpToolbarItem

- (id)initWithItemIdentifier:(NSString *)ident
{
	if (self = [super initWithItemIdentifier:ident])
	{
		button = [[AIDelayedPopUpButton alloc] initWithFrame:NSMakeRect(0,0,32,32)];
		[button setButtonType:NSMomentaryChangeButton];
		[button setBordered:NO];
		[self setView:button];
		[self setMinSize:NSMakeSize(32,32)];
		[self setMaxSize:NSMakeSize(32,32)];
	}
	return self;
}

- (void)dealloc
{
	[button release];
	[super dealloc];
}

- (NSMenu *)menu
{
	return [button menu];
}

- (void)setMenu:(NSMenu *)menu
{
	[button setMenu:menu];
	
	// Also set menu form representation - this is used in the toolbar overflow menu but also, more importantly, to display
	// a menu in text-only mode.
	NSMenuItem *menuFormRep = [[NSMenuItem alloc] initWithTitle:[self label] action:nil keyEquivalent:@""];
	[menuFormRep setSubmenu:menu];
	[self setMenuFormRepresentation:menuFormRep];
	[menuFormRep release];
}

- (id)target
{
	return [button target];
}

- (void)setTarget:(id)anObject
{
	[button setTarget:anObject];
}

- (SEL)action
{
	return [button action];
}

- (void)setAction:(SEL)aSelector
{
	[button setAction:aSelector];
}

- (NSImage *)image
{
	return [button image];
}

- (void)setImage:(NSImage *)anImage
{
	[button setImage:anImage];
}

@end
