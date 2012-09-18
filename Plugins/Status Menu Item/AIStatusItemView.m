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

#import <AIUtilities/AIImageTextCell.h>
#import "AIStatusItemView.h"
#import "AIImageTextCellView.h"

@implementation AIStatusItemView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		statusItem = nil;
		regularImage = nil;
		alternateImage = nil;
		menu = nil;
		alternateMenu = nil;
		
		[cell setHighlightWhenNotKey:YES];
		[cell setImageTextPadding:0];
    }
    return self;
}

#pragma mark Display

- (void)drawRect:(NSRect)rect
{
	// A known bug with screen flashing and updating: http://www.cocoabuilder.com/archive/message/cocoa/2008/4/22/204861
	NSDisableScreenUpdates();
		
	[statusItem drawStatusBarBackgroundInRect:[self frame] withHighlight:mouseDown];
	[super drawRect:rect];
	
	NSEnableScreenUpdates();
}

/*!
 * @brief Displays the desired menu, setting the highlight image as necessary.
 */
- (void)displayMenu:(NSMenu *)menuToDisplay
{
	mouseDown = YES;
	if (alternateImage) {
		[self setImage:alternateImage];
	}
	
	[cell setHighlighted:YES];
	
	[self display];
	
	[cell setHighlighted:NO];
	
	[statusItem popUpStatusItemMenu:menuToDisplay];
	
	mouseDown = NO;
	if (alternateImage) {
		[self setImage:regularImage];
	}
	
	[self setNeedsDisplay:YES];	
}

#pragma mark Events

/*!
 * @brief Primary menu on left mouse down
 */
- (void)mouseDown:(NSEvent *)event
{
	[self displayMenu:self.menu];
}

/*!
 * @brief Secondary menu on right mouse down
 */
- (void)rightMouseDown:(NSEvent *)event
{
	[self displayMenu:(self.alternateMenu ? self.alternateMenu : self.menu)];
}

#pragma mark AIImageTextCellView subclass responsibilities

/*!
 * @brief The width our cell would like to be.
 */
- (NSUInteger)desiredWidth
{
	return [cell cellSizeForBounds:NSMakeRect(0,0,1e6f,1e6f)].width;
}

#pragma mark Accessors

/*!
 * @brief Sets the regular image
 *
 * This is the image that is normally displayed, when a menu is not popping up.
 */
- (void)setRegularImage:(NSImage *)image
{
	regularImage = [image copy];
	
	if (!mouseDown) {
		[self setImage:regularImage];
		[self setNeedsDisplay:YES];
	}
}

/*! 
 * @brief The regular image
 *
 * This is the image that is normally displayed, when a menu is not popping up.
 */
- (NSImage *)regularImage
{
	return regularImage;
}

/*!
 * @brief Set the alternate image
 *
 * This is the image that is displayed when a menu is popping up.
 */
- (void)setAlternateImage:(NSImage *)image
{
	alternateImage = [image copy];

	if (mouseDown) {
		[self setImage:alternateImage];
		[self setNeedsDisplay:YES];
	}
}

/*!
 * @brief The alternate image
 *
 * This is the image that is displayed when a menu is popping up.
 */
- (NSImage *)alternateImage
{
	return alternateImage;
}

@synthesize menu;
@synthesize alternateMenu;

@synthesize statusItem;

@end
