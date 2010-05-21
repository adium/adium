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
		menu = nil;
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
	[menu release];
	[alternateMenu release];
	
	[super dealloc];
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
	[regularImage release];
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
	[alternateImage release];
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
