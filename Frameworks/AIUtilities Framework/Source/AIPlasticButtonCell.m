//
//  AIPlasticButtonCell.m
//  AIUtilities
//
//  Created by Mac-arena the Bored Zo on 2005-11-26.
//  Drawing code, -copyWithZone: code, -commonInit code, and -isOpaque ganked from previous implementation of AIPlasticButton by Adam Iser.
//

#import "AIPlasticButtonCell.h"
#import "AIImageAdditions.h"

#import <Carbon/Carbon.h>

#define LABEL_OFFSET_X	1
#define LABEL_OFFSET_Y	-1

#define IMAGE_OFFSET_X	0
#define IMAGE_OFFSET_Y	0

#define PLASTIC_ARROW_WIDTH		8
#define PLASTIC_ARROW_HEIGHT	(PLASTIC_ARROW_WIDTH/2.0f)
#define PLASTIC_ARROW_XOFFSET	12
#define PLASTIC_ARROW_YOFFSET	12
#define PLASTIC_ARROW_PADDING	8

@implementation AIPlasticButtonCell

#pragma mark Birth and Death

- (id)copyWithZone:(NSZone *)zone
{
	AIPlasticButtonCell	*newCell = [[self class] allocWithZone:zone];

	switch ([self type]) {
		case NSImageCellType:
			newCell = [newCell initImageCell:[self image]];
			break;
		case NSTextCellType:
			newCell = [newCell initTextCell:[self stringValue]];
			break;
		default:
			newCell = [newCell init]; //and hope for the best
			break;
	}
	
	[newCell setMenu:[[[self menu] copy] autorelease]];
	[newCell->plasticCaps retain];
	[newCell->plasticMiddle retain];
	[newCell->plasticPressedCaps retain];
	[newCell->plasticPressedMiddle retain];
	[newCell->plasticDefaultCaps retain];
	[newCell->plasticDefaultMiddle retain];

	return newCell;
}

- (void)commonInit
{
	//Default title and image
	[self setTitle:@""];
	[self setImage:nil];
	[self setImagePosition:NSImageOnly];

	Class myClass = [self class];

	//Load images
	plasticCaps          = [[NSImage imageNamed:@"PlasticButtonNormal_Caps"    forClass:myClass] retain];
	plasticMiddle        = [[NSImage imageNamed:@"PlasticButtonNormal_Middle"  forClass:myClass] retain];
	plasticPressedCaps   = [[NSImage imageNamed:@"PlasticButtonPressed_Caps"   forClass:myClass] retain];
	plasticPressedMiddle = [[NSImage imageNamed:@"PlasticButtonPressed_Middle" forClass:myClass] retain];
	plasticDefaultCaps   = [[NSImage imageNamed:@"PlasticButtonDefault_Caps"   forClass:myClass] retain];
	plasticDefaultMiddle = [[NSImage imageNamed:@"PlasticButtonDefault_Middle" forClass:myClass] retain];
	
	[plasticCaps          setFlipped:YES];
	[plasticMiddle        setFlipped:YES];
	[plasticPressedCaps   setFlipped:YES];
	[plasticPressedMiddle setFlipped:YES];
	[plasticDefaultCaps   setFlipped:YES];
	[plasticDefaultMiddle setFlipped:YES];
}

- (id)initTextCell:(NSString *)str
{
	if ((self = [super initTextCell:str])) {
		[self commonInit];
	}

	return self;    
}
- (id)initImageCell:(NSImage *)image
{
	if ((self = [super initImageCell:image])) {
		[self commonInit];
	}
	
	return self;    
}

- (void)dealloc
{
    [plasticCaps release];
    [plasticMiddle release];
    [plasticPressedCaps release];
    [plasticPressedMiddle release];
    [plasticDefaultCaps release];
    [plasticDefaultMiddle release];    
	
    [super dealloc];
}

#pragma mark Spiffy drawing magic

//for some unknown reason, NSButtonCell's -drawWithFrame:inView: draws a basic ridge border on the bottom-right if we do not override it.
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect	sourceRect, destRect, frame;
    CGFloat		capWidth;
    CGFloat		capHeight;
    CGFloat		middleRight;
    NSImage	*caps;
    NSImage	*middle;
	NSCellImagePosition imagePosition = [self imagePosition];
    
    //Get the correct images
    if (![self isHighlighted]) {
        if ([[self keyEquivalent] isEqualToString:@"\r"]) {
			//default button. draw appropriately.
            caps = plasticDefaultCaps;
            middle = plasticDefaultMiddle;
        } else {
            caps = plasticCaps;
            middle = plasticMiddle;
        }
    } else {
        caps = plasticPressedCaps;
        middle = plasticPressedMiddle;
    }

    //Precalc some sizes
    NSSize capsSize = [caps size];
    frame = cellFrame;//[controlView bounds];
    capWidth = capsSize.width / 2.0f;
    capHeight = capsSize.height;
    middleRight = ((frame.origin.x + frame.size.width) - capWidth);

    //Draw the left cap
	destRect = NSMakeRect(frame.origin.x/* + capWidth*/, frame.origin.y/* + frame.size.height*/, capWidth, frame.size.height);
    [caps drawInRect:destRect
			fromRect:NSMakeRect(0, 0, capWidth, capHeight)
		   operation:NSCompositeSourceOver
			fraction:1.0f];

    //Draw the middle, which tiles across the button (excepting the areas drawn by the left and right caps)
    NSSize middleSize = [middle size];
    sourceRect = NSMakeRect(0, 0, middleSize.width, middleSize.height);
    destRect = NSMakeRect(frame.origin.x + capWidth, frame.origin.y/* + frame.size.height*/, sourceRect.size.width,  frame.size.height);
	
    while (destRect.origin.x < middleRight && (int)destRect.size.width > 0) {
        //Crop
        if ((destRect.origin.x + destRect.size.width) > middleRight) {
            sourceRect.size.width -= (destRect.origin.x + destRect.size.width) - middleRight;
        }
		
        [middle drawInRect:destRect
				  fromRect:sourceRect
				 operation:NSCompositeSourceOver
				  fraction:1.0f];
        destRect.origin.x += destRect.size.width;
    }
	
    //Draw right mask
	destRect = NSMakeRect(middleRight, frame.origin.y/* + frame.size.height*/, capWidth, frame.size.height);
	[caps drawInRect:destRect
			fromRect:NSMakeRect(capWidth, 0, capWidth, capHeight)
		   operation:NSCompositeSourceOver
			fraction:1.0f];
	
    //Draw Label
	if(imagePosition != NSImageOnly) {
		NSString *title = [self title];
		if (title) {
			//Prep attributes
			NSColor *color = [self isEnabled] ? [NSColor blackColor] : [NSColor colorWithCalibratedWhite:0.0f alpha:0.5f];

			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[self font], NSFontAttributeName, color, NSForegroundColorAttributeName, nil];

			//Calculate center
			NSSize size = [title sizeWithAttributes:attributes];
			NSPoint centeredPoint = NSMakePoint(frame.origin.x + AIround((frame.size.width - size.width) / 2.0f) + LABEL_OFFSET_X,
										frame.origin.y + AIround((frame.size.height - size.height) / 2.0f) + LABEL_OFFSET_Y);

			//Draw
			[title drawAtPoint:centeredPoint withAttributes:attributes];
		}
    }

    //Draw image
	if(imagePosition != NSNoImage) {
		NSImage *image = [self image];
		if (image) {
			NSSize	size = [image size];
			NSRect	centeredRect;

			if ([self menu]) frame.size.width -= PLASTIC_ARROW_PADDING;

			centeredRect = NSMakeRect(frame.origin.x + (int)((frame.size.width - size.width) / 2.0f) + IMAGE_OFFSET_X,
									  frame.origin.y + (int)((frame.size.height - size.height) / 2.0f) + IMAGE_OFFSET_Y,
									  size.width,
									  size.height);

			[image setFlipped:YES];
			[image drawInRect:centeredRect
					 fromRect:NSMakeRect(0,0,size.width,size.height) 
					operation:NSCompositeSourceOver 
					 fraction:([self isEnabled] ? 1.0f : 0.5f)];
		}
    }
    
	//Draw the arrow, if needed
	if ([self menu]) {
		struct HIThemePopupArrowDrawInfo drawInfo = {
			.version = 0,
			.state = 0,
			.orientation = kThemeArrowDown,
			.size = kThemeArrow7pt,
		};
		if([self isEnabled]) {
			if([self state] != NSOffState) {
				drawInfo.state = kThemeStatePressed;
			} else {
				drawInfo.state = kThemeStateActive;
			}
		} else {
			drawInfo.state = kThemeStateInactive;
		}

		union {
			HIRect HIToolbox;
			NSRect AppKit;
		} rect;

		frame = [controlView frame];
		rect.AppKit.origin.x = NSWidth (frame) - PLASTIC_ARROW_XOFFSET;
		rect.AppKit.origin.y = NSHeight(frame) - PLASTIC_ARROW_YOFFSET;
		rect.AppKit.size.width  = PLASTIC_ARROW_WIDTH;
		rect.AppKit.size.height = PLASTIC_ARROW_HEIGHT;

		HIThemeDrawPopupArrow(&rect.HIToolbox,
							  &drawInfo,
							  [[NSApp context] graphicsPort],
							  kHIThemeOrientationNormal);
	}
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		return NSAccessibilityButtonRole;

    } else if([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
        return [self title];
		
    } else if([attribute isEqualToString:NSAccessibilityHelpAttribute]) {
        return [self title];
		
	} else {
        return [super accessibilityAttributeValue:attribute];
    }
}

#pragma mark Accessors (should that REALLY be plural?)

- (BOOL)isOpaque
{
    return NO;
}

@end
