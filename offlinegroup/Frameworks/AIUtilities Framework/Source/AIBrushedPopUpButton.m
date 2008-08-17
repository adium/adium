//
//  AIBrushedPopUpButton.m
//  Adium
//
//  Created by Adam Iser on Fri Jul 11 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIBrushedPopUpButton.h"
#import "AIImageAdditions.h"
#import "AIWindowAdditions.h"

#define TRIANGLE_PADDING_X 	2
#define TRIANGLE_OFFSET_Y 	4
#define LABEL_INSET_SMALL	3

@interface AIBrushedPopUpButton (PRIVATE)
- (void)stopTrackingCursor;
- (void)startTrackingCursor;
- (void)sizeToFitBrushed;
@end

@implementation AIBrushedPopUpButton

//
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
		Class myClass = [self class];

		if ([[self cell] controlSize] != NSMiniControlSize) {
			//Preload normal-size images
			popUpRolloverCaps   = [[NSImage imageNamed:@"PopUpRollover_Caps"   forClass:myClass] retain];
			popUpRolloverMiddle = [[NSImage imageNamed:@"PopUpRollover_Middle" forClass:myClass] retain];
			popUpPressedCaps    = [[NSImage imageNamed:@"PopUpPressed_Caps"    forClass:myClass] retain];
			popUpPressedMiddle  = [[NSImage imageNamed:@"PopUpPressed_Middle"  forClass:myClass] retain];
			popUpTriangle       = [[NSImage imageNamed:@"PopUpArrow"           forClass:myClass] retain];
			popUpTriangleWhite  = [[NSImage imageNamed:@"PopUpArrowWhite"      forClass:myClass] retain];
		} else {
			//Preload small images
			popUpRolloverCaps   = [[NSImage imageNamed:@"SmallPopUpRollover_Caps"   forClass:myClass] retain];
			popUpRolloverMiddle = [[NSImage imageNamed:@"SmallPopUpRollover_Middle" forClass:myClass] retain];
			popUpPressedCaps    = [[NSImage imageNamed:@"SmallPopUpPressed_Caps"    forClass:myClass] retain];
			popUpPressedMiddle  = [[NSImage imageNamed:@"SmallPopUpPressed_Middle"  forClass:myClass] retain];
			popUpTriangle       = [[NSImage imageNamed:@"SmallPopUpArrow"           forClass:myClass] retain];
			popUpTriangleWhite  = [[NSImage imageNamed:@"SmallPopUpArrowWhite"      forClass:myClass] retain];
		}

		mouseIn = NO;
		trackingTag = 0;
		popUpTitle = nil;
	}

    return self;    
}

//
- (void)dealloc
{
    //
    [popUpRolloverCaps   release];
    [popUpRolloverMiddle release];
    [popUpPressedCaps    release];
    [popUpPressedMiddle  release];
    [popUpTriangle       release];
    [popUpTriangleWhite  release];

    [popUpTitle release];
    
    [super dealloc];
}

//Handle title setting on our own, since NSPopUpButton doesn't seem to do it reliably.
- (void)setTitle:(NSString *)aString
{
    if (popUpTitle != aString) {
        [popUpTitle release];
        popUpTitle = [aString retain];

	if ([[self window] isTextured]) [self sizeToFitBrushed];
        [self setNeedsDisplay:YES];
    }
}
- (void)selectItem:(NSMenuItem *)item
{
    if (popUpTitle) {
        [popUpTitle release]; popUpTitle = nil;
    }
    if ([[self window] isTextured]) [self sizeToFitBrushed];
    [super selectItem:item];
}

//
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    //If we're being removed from the window, we need to remove our tracking rects
    if (newWindow == nil) {
        [self stopTrackingCursor];
	
    } else {
	//If we're being added to a brushed window, size ourself appropriately
	if ([newWindow isTextured]) {
	    [self sizeToFitBrushed];
	}
	
    }
}

//Size ourself as small as possible (for brushed only)
- (void)sizeToFitBrushed
{
    NSDictionary    *textAttributes;
    NSString	    *title;
    NSFont	    *font;
    NSRect	    frame;
    float	    fontSize;
    
    fontSize = [[self font] pointSize];
    font = ([[self window] isTextured] ? [NSFont boldSystemFontOfSize:fontSize] : [NSFont systemFontOfSize:fontSize]);
    if (popUpTitle) {
	title = popUpTitle;
    } else {
	title = [self titleOfSelectedItem];
    }
    
    textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    
    frame = [self frame];
    [[self superview] setNeedsDisplayInRect:frame];
    frame.size.width = [title sizeWithAttributes:textAttributes].width - (LABEL_INSET_SMALL * 2) + TRIANGLE_PADDING_X + [popUpTriangle size].width + [popUpRolloverCaps size].width;
    
    [self setFrame:frame];
}

//Custom drawing for brushed windows
- (void)drawRect:(NSRect)rect
{
    if ([[self window] isTextured]) {
	NSDictionary	*textAttributes, *bezelAttributes;
	NSColor		*textColor, *bezelColor;
	NSString		*title;
	NSImage		*triangle;
	NSFont		*font;
	int			contentRight;
	NSSize		labelSize;
	NSImage		*caps, *middle;
	NSRect 		frame, sourceRect, destRect;
	int 		capWidth, capHeight;
	int			centeredLabelY;
	BOOL		highlighted = [[self cell] isHighlighted];
	
	//Disable sub-pixel rendering.  It looks horrible with embossed text
	CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], 0);
	
	//Get the font and displayed string
	font = [NSFont boldSystemFontOfSize:[[self font] pointSize]];
	if (popUpTitle) {
	    title = popUpTitle;
	} else {
	    title = [self titleOfSelectedItem];
	}
	
	//Get the colors
	if (mouseIn || highlighted) {
	    textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
	    bezelColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.4];
	} else {
	    textColor = [NSColor colorWithCalibratedWhite:0.16 alpha:1.0];
	    bezelColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.4];
	}
	
	//Create the attributes
	textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, textColor, NSForegroundColorAttributeName, nil];
	bezelAttributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, bezelColor, NSForegroundColorAttributeName, nil];
	
	//Get the correct triangle image
	if (highlighted || mouseIn) {
	    triangle = popUpTriangleWhite;
	} else {
	    triangle = popUpTriangle;
	}
	
	//Get the correct background images
	if (highlighted) {
	    caps = popUpPressedCaps;
	    middle = popUpPressedMiddle;
	} else {
	    caps = popUpRolloverCaps;
	    middle = popUpRolloverMiddle;
	}
	
	//Precalc dimensions
	frame = [self bounds];
	capWidth = [caps size].width / 2.0;
	capHeight = [caps size].height;
	labelSize = [title sizeWithAttributes:textAttributes];
	centeredLabelY = ((capHeight - labelSize.height) / 2.0);
	contentRight = capWidth + labelSize.width - (LABEL_INSET_SMALL * 2) + TRIANGLE_PADDING_X + [triangle size].width;
	
	//Center vertically
	frame.origin.y -= (frame.size.height - capHeight) / 2.0;

	//Draw the backgound
	if (mouseIn || highlighted) {
	    //Draw the left cap
	    [caps compositeToPoint:NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height)
		   fromRect:NSMakeRect(0, 0, capWidth, capHeight)
		  operation:NSCompositeSourceOver];
	    
	    //Draw the middle
	    sourceRect = NSMakeRect(0, 0, [middle size].width, [middle size].height);
	    destRect = NSMakeRect(frame.origin.x + capWidth, frame.origin.y + frame.size.height, sourceRect.size.width, sourceRect.size.height);
	    
	    while (destRect.origin.x < contentRight && sourceRect.size.width != 0) {
		if ((destRect.origin.x + destRect.size.width) > contentRight) { //Crop
		    sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - contentRight;
		}
		
		[middle compositeToPoint:destRect.origin
		  fromRect:sourceRect
		 operation:NSCompositeSourceOver];
		destRect.origin.x += destRect.size.width;
	    }
	    
	    //Draw right cap
	    [caps compositeToPoint:NSMakePoint(contentRight, frame.origin.y + frame.size.height)
		   fromRect:NSMakeRect(capWidth, 0, capWidth, capHeight)
		  operation:NSCompositeSourceOver];        
	}
	
	//Draw the embossed title
	[title drawAtPoint:NSMakePoint(frame.origin.x + capWidth - LABEL_INSET_SMALL, frame.origin.y + frame.size.height - labelSize.height - centeredLabelY) withAttributes:bezelAttributes];
	[title drawAtPoint:NSMakePoint(frame.origin.x + capWidth - LABEL_INSET_SMALL, frame.origin.y + frame.size.height - labelSize.height - centeredLabelY - 1) withAttributes:textAttributes];
	
	//Draw the triangle
	[triangle compositeToPoint:NSMakePoint(frame.origin.x + capWidth + labelSize.width - LABEL_INSET_SMALL + TRIANGLE_PADDING_X, frame.origin.y + frame.size.height - TRIANGLE_OFFSET_Y) operation:NSCompositeSourceOver];

    } else {
	[super drawRect:rect];
    }
}

//Reset our cursor tracking (Only for the brushed variant)
- (void)resetCursorRects
{
    if ([[self window] isTextured]) {
	[self stopTrackingCursor];
	[self startTrackingCursor];
    }
}

//Stop traking the cursor
- (void)stopTrackingCursor
{
    if (trackingTag) {
        [self removeTrackingRect:trackingTag];
        trackingTag = 0;
    }    
}

//Start tracking the cursor
- (void)startTrackingCursor
{
    if (trackingTag == 0) {
        NSRect 		trackRect;
        NSPoint		localPoint;

        //Tracking rect
        trackRect = NSMakeRect(0, 0, [self frame].size.width, [self frame].size.height);
        localPoint = [[self window] convertScreenToBase:[NSEvent mouseLocation]];
        localPoint = [self convertPoint:localPoint fromView:nil];
        mouseIn = NSPointInRect(localPoint, trackRect);

        //Track only if we're within a valid window
        if ([self window]) {
            trackingTag = [self addTrackingRect:trackRect owner:self userData:nil assumeInside:mouseIn];
        }
    }
}

//User is hovering our popup
- (void)mouseEntered:(NSEvent *)theEvent
{
    if ([self canDraw]) {
        mouseIn = YES;
        [self setNeedsDisplay:YES];
    }
}

//User has left our popup
- (void)mouseExited:(NSEvent *)theEvent
{
    if ([self canDraw]) {
        mouseIn = NO;
        [self setNeedsDisplay:YES];
    }
}

@end
