//
//  AIStatusItemView.m
//  Adium
//
//  Created by Zachary West on 2008-05-22.
//

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
		mainMenu = nil;
		alternateMenu = nil;
		
		[cell setHighlightWhenNotKey:YES];
		[cell setImageTextPadding:0];
    }
    return self;
}

- (void)dealloc
{
	[statusItem release];
	[regularImage release];
	[alternateImage release];
	[mainMenu release];
	[alternateMenu release];
	
	[super dealloc];
}

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
- (void)displayMenu:(NSMenu *)menu
{
	mouseDown = YES;
	if (alternateImage) {
		[self setImage:alternateImage];
	}
	
	[cell setHighlighted:YES];
	
	[self display];
	
	[cell setHighlighted:NO];
	
	[statusItem popUpStatusItemMenu:menu];
	
	mouseDown = NO;
	if (alternateImage) {
		[self setImage:regularImage];
	}
	
	[self setNeedsDisplay:YES];	
}

/*!
 * @brief Primary menu on left mouse down
 */
- (void)mouseDown:(NSEvent *)event
{
	[self displayMenu:mainMenu];
}

/*!
 * @brief Secondary menu on right mouse down
 */
- (void)rightMouseDown:(NSEvent *)event
{
	[self displayMenu:(alternateMenu ? alternateMenu : mainMenu)];
}

/*!
 * @brief The width our cell would like to be.
 */
- (unsigned)desiredWidth
{
	return [cell cellSizeForBounds:NSMakeRect(0,0,1e6,1e6)].width;
}

/*!
 * @brief Sets the regular image
 *
 * This is the image that is normally displayed, when a menu is not popping up.
 */
- (void)setRegularImage:(NSImage *)image
{
	[regularImage release];
	regularImage = [image retain];
	
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
	[alternateImage release];
	alternateImage = [image retain];

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

/*!
 * @brief Set the menu displayed when left clicking
 *
 * This is also the menu used for right-clicking if no alternate menu is specified
 */
- (void)setMenu:(NSMenu *)menu
{
	[mainMenu release];
	mainMenu = [menu retain];
}

/*!
 * @brief The menu displayed when left clicking
 *
 * This is also the menu used for right-clicking if no alternate menu is specified
 */
- (NSMenu *)menu
{
	return mainMenu;
}

/*!
 * @brief Set the menu displayed when right clicking
 */
- (void)setAlternateMenu:(NSMenu *)menu
{
	[alternateMenu release];
	alternateMenu = [menu retain];
}

/*!
 * @brief The menu displayed when right clicking
 */
- (NSMenu *)alternateMenu
{
	return alternateMenu;
}

/*!
 * @brief Set this view's status item
 */
- (void)setStatusItem:(NSStatusItem *)inStatusItem
{
	[statusItem release];
	statusItem = [inStatusItem retain];
}

/*!
 * @brief This view's status item
 */
- (NSStatusItem *)statusItem
{
	return statusItem;
}

@end
