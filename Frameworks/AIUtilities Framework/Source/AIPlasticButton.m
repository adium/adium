//
//  AIPlasticButton.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 26 2003.
//

#import "AIPlasticButton.h"
#import "AIPlasticButtonCell.h"

#define LABEL_OFFSET_X	1
#define LABEL_OFFSET_Y	-1

@implementation AIPlasticButton

+ (void)initialize {
	if (self == [AIPlasticButton class])
		[self setCellClass:[AIPlasticButtonCell class]];
}

- (id)copyWithZone:(NSZone *)zone
{
	AIPlasticButton	*newButton = [[[self class] allocWithZone:zone] initWithFrame:[self frame]];
	
	[newButton setMenu:[[[self menu] copy] autorelease]];

	return newButton;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		//Default title and image
		[self setTitle:@""];
		[self setImage:nil];
		[self setImagePosition:NSImageOnly];
	}

	return self;    
}

- (void)sizeToFit
{		
	[super sizeToFit];
	
	NSRect frame = [self frame];
	frame.size.width += LABEL_OFFSET_X * 2;
	
	[self setFrame:frame];
}

//silly NSControl...
- (void)setMenu:(NSMenu *)menu {
	[super setMenu:menu];
	[[self cell] setMenu:menu];
}

//Mouse Tracking -------------------------------------------------------------------------------------------------------
#pragma mark Mouse Tracking
//Custom mouse down tracking to display our menu and highlight
- (void)mouseDown:(NSEvent *)theEvent
{
	if (![self menu]) {
		[super mouseDown:theEvent];
	} else {
		if ([self isEnabled] &&
			NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], [self bounds])) {
			[self highlight:YES];

			//2 pt down, 1 pt to the left.
			NSPoint point = [self convertPoint:[self bounds].origin toView:nil];
			point.y -= NSHeight([self frame]) + 2;
			point.x -= 1;
			
			NSEvent *event = [NSEvent mouseEventWithType:[theEvent type]
												location:point
										   modifierFlags:[theEvent modifierFlags]
											   timestamp:[theEvent timestamp]
											windowNumber:[[theEvent window] windowNumber]
												 context:[theEvent context]
											 eventNumber:[theEvent eventNumber]
											  clickCount:[theEvent clickCount]
												pressure:[theEvent pressure]];
			[NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
			
			//In the case of the Add Account pop-up button (which is an instance of this class), if the user cancels the Account Editor immediately after it appears for the new account, we stay highlighted, which is a bug (#7955). Sending ourselves mouseUp fixes that.
			[self mouseUp:[[NSApplication sharedApplication] currentEvent]];
		}
	}
}

//Remove highlight on mouse up
- (void)mouseUp:(NSEvent *)theEvent
{
	[self highlight:NO];
	[super mouseUp:theEvent];
}

//Ignore dragging
- (void)mouseDragged:(NSEvent *)theEvent
{
	//Empty
}

@end
