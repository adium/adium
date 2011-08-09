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

#import "AITooltipUtilities.h"

#define TOOLTIP_MAX_WIDTH			300
#define TOOLTIP_INSET				4.0f
#define TOOLTIP_TITLE_BODY_MARGIN	10.0f
#define MAX_IMAGE_DIMENSION			96.0f

#define TOOLTIP_OPACITY				1.0f
#define TOOLTIP_FADEOUT_INTERVAL	0.025f
#define TOOLTIP_FADOUT_STEP			0.1f

@interface AITooltipUtilities ()
+ (void)_createTooltip;
+ (void)_closeTooltip;
+ (void)_sizeTooltip;
+ (NSPoint)_tooltipFrameOriginForSize:(NSSize)tooltipSize;
+ (void)_reallyCloseTooltip;
@end

@implementation AITooltipUtilities

static	NSPanel                 *tooltipWindow = nil;
static	NSTextView				*textView_tooltipTitle = nil;
static	NSTextView				*textView_tooltipBody = nil;
static  NSTextStorage   		*textStorage_tooltipTitle = nil;
static  NSTextStorage   		*textStorage_tooltipBody = nil;
static  NSImageView				*view_tooltipImage = nil;
static  NSWindow				*onWindow = nil;
static	NSAttributedString      *tooltipBody;
static	NSAttributedString      *tooltipTitle;
static  NSImage                 *tooltipImage;
static	NSViewAnimation			*fadeOutAnimation;
static  NSSize                  imageSize;
static  BOOL                    imageOnRight;
static	NSPoint					tooltipPoint;
static	AITooltipOrientation	tooltipOrientation;

//Tooltips
+ (void)showTooltipWithString:(NSString *)inString onWindow:(NSWindow *)inWindow atPoint:(NSPoint)inPoint orientation:(AITooltipOrientation)inOrientation
{
    [self showTooltipWithAttributedString:[[[NSAttributedString alloc] initWithString:inString] autorelease] 
								 onWindow:inWindow 
								  atPoint:inPoint 
							  orientation:inOrientation];
}

+ (void)showTooltipWithAttributedString:(NSAttributedString *)inString onWindow:(NSWindow *)inWindow atPoint:(NSPoint)inPoint orientation:(AITooltipOrientation)inOrientation
{
    [self showTooltipWithTitle:nil 
						  body:inString
						 image:nil
				  imageOnRight:YES
					  onWindow:inWindow
					   atPoint:inPoint 
				   orientation:inOrientation];
}

+ (void)showTooltipWithTitle:(NSAttributedString *)inTitle body:(NSAttributedString *)inBody image:(NSImage *)inImage onWindow:(NSWindow *)inWindow atPoint:(NSPoint)inPoint orientation:(AITooltipOrientation)inOrientation
{
    [self showTooltipWithTitle:inTitle 
						  body:inBody 
						 image:inImage
				  imageOnRight:YES
					  onWindow:inWindow
					   atPoint:inPoint 
				   orientation:inOrientation];    
}

+ (void)showTooltipWithTitle:(NSAttributedString *)inTitle
						body:(NSAttributedString *)inBody
					   image:(NSImage *)inImage
				imageOnRight:(BOOL)inImageOnRight
					onWindow:(NSWindow *)inWindow
					 atPoint:(NSPoint)inPoint
				 orientation:(AITooltipOrientation)inOrientation
{    
   if ((inTitle && [inTitle length]) || (inBody && [inBody length]) || inImage) { //If passed something to display
       BOOL		newLocation = (!NSEqualPoints(inPoint,tooltipPoint) || (tooltipOrientation != inOrientation));
	   
	   BOOL fadingOut = (fadeOutAnimation != nil && [fadeOutAnimation isAnimating]);
	   if (fadingOut) [fadeOutAnimation stopAnimation];
	   
	   //Update point and orientation
        tooltipPoint = inPoint;
        tooltipOrientation = inOrientation;
        onWindow = inWindow;

        if ((!tooltipTitle && !tooltipBody && !tooltipImage)) {
            [self _createTooltip]; //make the window
        }

        if (!(inBody == tooltipBody)   ||
		   !(inTitle == tooltipTitle) || 
		   !(inImage == tooltipImage)) { //we don't exist or something changed

			[tooltipTitle release]; tooltipTitle = [inTitle retain];

			if (inTitle) {
                [[textView_tooltipTitle textStorage] replaceCharactersInRange:NSMakeRange(0,[[textView_tooltipTitle textStorage] length])
														 withAttributedString:tooltipTitle];
            } else {
                [[textView_tooltipTitle textStorage] deleteCharactersInRange:NSMakeRange(0,[[textView_tooltipTitle textStorage] length])];            
            }

            [tooltipBody release]; tooltipBody = [inBody retain];
            if (inBody) {
                [[textView_tooltipBody textStorage] replaceCharactersInRange:NSMakeRange(0,[[textView_tooltipBody textStorage] length])
														withAttributedString:tooltipBody];
            } else {
                [[textView_tooltipBody textStorage] deleteCharactersInRange:NSMakeRange(0,[[textView_tooltipBody textStorage] length])];
            }
            
            [tooltipImage release]; tooltipImage = [inImage retain];

			imageOnRight = inImageOnRight;
			[view_tooltipImage setImage:tooltipImage];

			if (tooltipImage) {
				imageSize = [tooltipImage size];
				
				//Constrain our image proportionally
				if (imageSize.height > MAX_IMAGE_DIMENSION) {
					imageSize.width = AIround(imageSize.width * (MAX_IMAGE_DIMENSION / imageSize.height));
					imageSize.height = MAX_IMAGE_DIMENSION;
				}
				
				if (imageSize.width > MAX_IMAGE_DIMENSION) {
					imageSize.height = AIround(imageSize.height * (MAX_IMAGE_DIMENSION / imageSize.width));
					imageSize.width = MAX_IMAGE_DIMENSION;
				}
				
			} else {
				imageSize = NSZeroSize;	
			}
			
			//If we're fading out, hide the window before moving and then show it at normal opacity
			if (fadingOut) [tooltipWindow setAlphaValue:0.0f];
            [self _sizeTooltip];
			if (fadingOut) [tooltipWindow setAlphaValue:TOOLTIP_OPACITY];
				
        } else if (newLocation) { //Everything is the same but the location is different
				//If we're fading out, hide the window before moving and then show it at normal opacity
				if (fadingOut) [tooltipWindow setAlphaValue:0.0f];
                [tooltipWindow setFrameOrigin:[self _tooltipFrameOriginForSize:[[tooltipWindow contentView] frame].size]];
				if (fadingOut) [tooltipWindow setAlphaValue:TOOLTIP_OPACITY];
        }

    } else { //If passed a nil string, hide any existing tooltip
        if (tooltipBody) {
            [self _closeTooltip];
        }

    }
}

//Create the tooltip
+ (void)_createTooltip
{
	NSLayoutManager *layoutManager;
	NSTextContainer *container;

	if (!tooltipWindow) {
		//Create the window
		tooltipWindow = [[NSPanel alloc] initWithContentRect:NSZeroRect 
												   styleMask:NSBorderlessWindowMask
													 backing:NSBackingStoreBuffered
													   defer:NO];
		[tooltipWindow setHidesOnDeactivate:NO];
		[tooltipWindow setIgnoresMouseEvents:YES];
		[tooltipWindow setOpaque:NO]; 
		[tooltipWindow setBackgroundColor:[[NSColor controlBackgroundColor] colorWithAlphaComponent:0.97f]];
		[tooltipWindow setAlphaValue:TOOLTIP_OPACITY];
		[tooltipWindow setHasShadow:YES];

		//Just using the floating panel level is insufficient because the contact list can float, too
		[tooltipWindow setLevel:NSStatusWindowLevel];
	}

    if (!textView_tooltipTitle) {
		//create and add the title text view
		textStorage_tooltipTitle = [[NSTextStorage alloc] init];

		layoutManager = [[NSLayoutManager alloc] init];
		[textStorage_tooltipTitle addLayoutManager:layoutManager];
		[layoutManager release];

		container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(TOOLTIP_MAX_WIDTH,10000000.0f)];
		[container setLineFragmentPadding:1.0f]; //so widths will caclulate properly
		[layoutManager addTextContainer:container];
		[container release];

		textView_tooltipTitle = [[NSTextView alloc] initWithFrame:NSZeroRect textContainer:container];
		[textView_tooltipTitle setSelectable:NO];
		[textView_tooltipTitle setRichText:YES];
		[textView_tooltipTitle setDrawsBackground:NO];
		[[tooltipWindow contentView] addSubview:textView_tooltipTitle];
	}

	if (!textView_tooltipBody) {
		//create and add the body text view
		textStorage_tooltipBody = [[NSTextStorage alloc] init];
		
		layoutManager = [[NSLayoutManager alloc] init];
		[textStorage_tooltipBody addLayoutManager:layoutManager];
		[layoutManager release];
		
		container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(TOOLTIP_MAX_WIDTH,10000000.0f)];
		[container setLineFragmentPadding:0.0f]; //so widths will caclulate properly
		[layoutManager addTextContainer:container];
		[container release];

		textView_tooltipBody = [[NSTextView alloc] initWithFrame:NSZeroRect textContainer:container];
		[textView_tooltipBody setSelectable:NO];
		[textView_tooltipBody setRichText:YES];
		[textView_tooltipBody setDrawsBackground:NO];

		[[tooltipWindow contentView] addSubview:textView_tooltipBody];
	}

    if (!view_tooltipImage) {
		view_tooltipImage = [[NSImageView alloc] initWithFrame:NSZeroRect];
		[[tooltipWindow contentView] addSubview:view_tooltipImage];
	}
}

+ (void)_closeTooltip
{
	NSAssert2(!fadeOutAnimation, @"%s: Trying to close tooltip while a tooltip is already fading out! Animation is %@", __PRETTY_FUNCTION__, fadeOutAnimation);
	fadeOutAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
		tooltipWindow, NSViewAnimationTargetKey,
		NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
	nil]]];
	[fadeOutAnimation setDelegate:(id<NSAnimationDelegate>)self];
	[fadeOutAnimation setDuration:0.25f];
	[fadeOutAnimation setAnimationCurve:NSAnimationLinear];
	[fadeOutAnimation startAnimation];
}

//This is called when we send stopAnimation to the animation from the showTooltipWithTitle:body:image:imageOnRight:onWindow:atPoint:orientation: method.
+ (void)animationDidStop:(NSAnimation *)animation
{
	if (animation != nil && animation == fadeOutAnimation)
		[self _reallyCloseTooltip];
}
//This is called when the animation ends naturally.
+ (void)animationDidEnd:(NSAnimation *)animation
{
	if (animation != nil && animation == fadeOutAnimation)
		[self _reallyCloseTooltip];
}

+ (void)_reallyCloseTooltip
{
    [textView_tooltipBody release];  textView_tooltipBody = nil;
    [textView_tooltipTitle release]; textView_tooltipTitle = nil;
	[textStorage_tooltipBody release]; textStorage_tooltipBody = nil;
	[textStorage_tooltipTitle release]; textStorage_tooltipTitle = nil;
    [view_tooltipImage release];     view_tooltipImage = nil;
    [tooltipWindow release];         tooltipWindow = nil;
    [tooltipBody release];           tooltipBody = nil;
    [tooltipTitle release];          tooltipTitle = nil;
    [tooltipImage release];          tooltipImage = nil;
    tooltipPoint = NSZeroPoint;
	
	[fadeOutAnimation release]; fadeOutAnimation = nil;
}

+ (void)_sizeTooltip
{
    static  NSColor *titleAndBodyMarginLineColor = nil;
    NSRect  tooltipTitleRect;
    NSRect  tooltipBodyRect;
    NSRect  tooltipWindowRect;
    
    BOOL hasTitle = tooltipTitle && [tooltipTitle length];
    BOOL hasBody = tooltipBody && [tooltipBody length];
	
	static dispatch_once_t setTitleAndBodyMarginLineColor;
	dispatch_once(&setTitleAndBodyMarginLineColor, ^{
		titleAndBodyMarginLineColor = [[[NSColor grayColor] colorWithAlphaComponent:.7f] retain];
	});

    if (hasTitle) {
        //Make sure we're not wrapping by default
        //Set up the tooltip's bounds
        [[textView_tooltipTitle layoutManager] glyphRangeForTextContainer:[textView_tooltipTitle textContainer]]; //void - need to force it to lay out the glyphs for an accurate measurement
        tooltipTitleRect = [[textView_tooltipTitle layoutManager] usedRectForTextContainer:[textView_tooltipTitle textContainer]];
    } else {
        tooltipTitleRect = NSZeroRect;
    }
    
    if (hasBody) {
        //Make sure we're not wrapping by default
        //Set up the tooltip's bounds
        [[textView_tooltipBody layoutManager] glyphRangeForTextContainer:[textView_tooltipBody textContainer]]; //void - need to force it to lay out the glyphs for an accurate measurement
        tooltipBodyRect = [[textView_tooltipBody layoutManager] usedRectForTextContainer:[textView_tooltipBody textContainer]];
    } else {
        tooltipBodyRect = NSZeroRect;   
    }
    
    CGFloat titleAndBodyMargin = (hasTitle && hasBody) ? TOOLTIP_TITLE_BODY_MARGIN : 0;
    //width is the greater of the body and title widths
    CGFloat windowWidth = TOOLTIP_INSET*2 + ((tooltipBodyRect.size.width > tooltipTitleRect.size.width) ? tooltipBodyRect.size.width : tooltipTitleRect.size.width);
    CGFloat windowHeight = titleAndBodyMargin + TOOLTIP_INSET*2 + (tooltipTitleRect.size.height + tooltipBodyRect.size.height);
    
    //Set the textView's origin 
//  tooltipTitleRect.origin =  NSMakePoint(windowWidth/2 - tooltipTitleRect.size.width/2,TOOLTIP_INSET + tooltipBodyRect.size.height); //center the title
    tooltipTitleRect.origin =  NSMakePoint(TOOLTIP_INSET,titleAndBodyMargin + TOOLTIP_INSET + tooltipBodyRect.size.height); //left
    tooltipBodyRect.origin =  NSMakePoint(TOOLTIP_INSET, TOOLTIP_INSET);

    if (tooltipImage) {
		BOOL imageIsTallerThanTitle;
		
        //if the image isn't going to fit without overlapping the title, expand the window's width
        CGFloat neededWidth = imageSize.width + tooltipTitleRect.size.width + (TOOLTIP_INSET * 3);
        if (neededWidth > windowWidth) {
            windowWidth = neededWidth;   
        }
		
		imageIsTallerThanTitle = (imageSize.height > tooltipTitleRect.size.height);
        if (imageIsTallerThanTitle) {
			//The image should not overlap the body of the tooltip, so increase the window height (the body has an origin at the bottom-left so will move with the window)
			windowHeight = titleAndBodyMargin + imageSize.height + tooltipBodyRect.size.height + TOOLTIP_INSET * 2;
			
			//If the image is taller than the title, shift the title up 
			tooltipTitleRect.origin.y = (windowHeight - ((imageSize.height) * 0.5f) - (tooltipTitleRect.size.height * 0.5f));
        }

        if (imageOnRight) {
            //Recenter the title to be between the left of the window and the left of the image
			tooltipTitleRect.origin.x = TOOLTIP_INSET;

            [view_tooltipImage setFrameOrigin:NSMakePoint(windowWidth - imageSize.width - TOOLTIP_INSET,windowHeight - imageSize.height - TOOLTIP_INSET)];
        } else {
            //Recenter the title to be between the right of the image and the right of the window
			tooltipTitleRect.origin.x = (imageSize.width + TOOLTIP_INSET * 2);

            [view_tooltipImage setFrameOrigin:NSMakePoint(TOOLTIP_INSET, windowHeight - imageSize.height - TOOLTIP_INSET)];
        }
    }

    [view_tooltipImage setFrameSize:imageSize];
    
    //Apply the new frames for the text views
    [textView_tooltipTitle  setFrame:tooltipTitleRect];
    [textView_tooltipBody   setFrame:tooltipBodyRect];
    
    [textView_tooltipTitle  setNeedsDisplay:YES];
    [textView_tooltipBody   setNeedsDisplay:YES];
    [view_tooltipImage      setNeedsDisplay:YES];
    [[tooltipWindow contentView] setNeedsDisplay:YES];
    
    //Set the window origin and give it a border
    tooltipWindowRect.size = NSMakeSize(windowWidth,windowHeight);
    tooltipWindowRect.origin =  [self _tooltipFrameOriginForSize:tooltipWindowRect.size];
    
    //Apply the frame change
    [tooltipWindow setFrame:tooltipWindowRect display:YES];
    
    //Draw the dividing line
    if (titleAndBodyMargin) {
        [[tooltipWindow contentView] lockFocus];
        [titleAndBodyMarginLineColor set];
        [NSBezierPath setDefaultLineWidth:0.5f];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(TOOLTIP_INSET, (titleAndBodyMargin * 0.5f) + tooltipBodyRect.size.height + 4)
                                  toPoint:NSMakePoint(windowWidth - TOOLTIP_INSET, (titleAndBodyMargin * 0.5f) + tooltipBodyRect.size.height + 4)];
        [[tooltipWindow contentView] unlockFocus];
    }
    
    //Ensure the tip is visible
    if (![tooltipWindow isVisible]) {
        [tooltipWindow makeKeyAndOrderFront:nil];
    }
}

+ (NSPoint)_tooltipFrameOriginForSize:(NSSize)tooltipSize;
{
	NSRect screenRect;
	if (onWindow) {
		screenRect = [[onWindow screen] visibleFrame];
	} else {
		screenRect = [[NSScreen mainScreen] visibleFrame];
	}
	
    NSPoint      tooltipOrigin;
    
    //Adjust the tooltip so it fits completely on the screen
    if (tooltipOrientation == TooltipAbove) {
        if (tooltipPoint.x > (screenRect.origin.x + screenRect.size.width - tooltipSize.width)) {
           tooltipOrigin.x = tooltipPoint.x - 2 - tooltipSize.width;
        } else {
          tooltipOrigin.x = tooltipPoint.x;
        }

        if (tooltipPoint.y > (screenRect.origin.y + screenRect.size.height - tooltipSize.height)) {
            tooltipOrigin.y = screenRect.origin.y + screenRect.size.height - tooltipSize.height;
        } else {
            tooltipOrigin.y = tooltipPoint.y + 2;
        }
        
        if (tooltipOrigin.y < 0)
            tooltipOrigin.y = 0;
        
    } else {
        if (tooltipPoint.x > (screenRect.origin.x + screenRect.size.width - tooltipSize.width)) {
            tooltipOrigin.x = tooltipPoint.x - 2 - tooltipSize.width;
        } else {
            tooltipOrigin.x = tooltipPoint.x + 10;
        }

        if (tooltipPoint.y < (screenRect.origin.y + tooltipSize.height)) {
            tooltipOrigin.y = tooltipPoint.y + 2;
        } else {
            tooltipOrigin.y = tooltipPoint.y - 2 - tooltipSize.height;
        }
        
        if (tooltipOrigin.y + tooltipSize.height > (screenRect.origin.y + screenRect.size.height))
            tooltipOrigin.y = (screenRect.origin.y + screenRect.size.height) - tooltipSize.height;
    }
    
    return tooltipOrigin;
}

@end
