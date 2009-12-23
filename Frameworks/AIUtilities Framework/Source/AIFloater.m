//
//  AIFloater.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.//

#import "AIFloater.h"
#import "AIEventAdditions.h"

#define WINDOW_FADE_FPS                         24.0
#define WINDOW_FADE_STEP                        0.3
#define WINDOW_FADE_SLOW_STEP                   0.1
#define WINDOW_FADE_MAX                         1.0
#define WINDOW_FADE_MIN                         0.0
#define WINDOW_FADE_SNAP                        0.05 //How close to min/max we must get before fade is finished

@interface AIFloater ()
- (id)initWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask;
- (void)_setWindowOpacity:(CGFloat)opacity;
@end

@implementation AIFloater

//Because the floater can control its own display, it retains itself and releases when it closes.
+ (id)floaterWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask
{
    return [[self alloc] initWithImage:inImage styleMask:styleMask];
}

- (id)initWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask
{
	if ((self = [super init])) {
		NSRect  frame;
		windowIsVisible = NO;
		fadeAnimation = nil;
		maxOpacity = WINDOW_FADE_MAX;

		//Set up the panel
		frame = NSMakeRect(0, 0, [inImage size].width, [inImage size].height);    
		panel = [[NSPanel alloc] initWithContentRect:frame
										   styleMask:styleMask
											 backing:NSBackingStoreBuffered
											   defer:NO];
		[panel setHidesOnDeactivate:NO];
		[panel setIgnoresMouseEvents:YES];
		[panel setLevel:NSStatusWindowLevel];
		[panel setHasShadow:YES];
		[self _setWindowOpacity:WINDOW_FADE_MIN];

		//Setup the static view
		staticView = [[NSImageView alloc] initWithFrame:frame];
		[staticView setImage:inImage];
		[staticView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		[[panel contentView] addSubview:[staticView autorelease]];
	}

	return self;
}

- (void)moveFloaterToPoint:(NSPoint)inPoint
{
    [panel setFrameOrigin:inPoint];
    [panel orderFront:nil];
}

- (void)setImage:(NSImage *)inImage
{
    NSRect frame = [panel frame];
    frame.size = [inImage size];
    [staticView setImage:inImage];
    [panel setFrame:frame display:YES animate:NO];
}

- (NSImage *)image
{
    return [staticView image];
}

- (void)endFloater
{
    [self close:nil];   
}

- (IBAction)close:(id)sender
{
    [fadeAnimation stopAnimation]; [fadeAnimation release]; fadeAnimation = nil;
    [panel orderOut:nil];
    [panel release]; panel = nil;

    [self release];
}

- (void)setMaxOpacity:(CGFloat)inMaxOpacity
{
    maxOpacity = inMaxOpacity;
    if (windowIsVisible) [self _setWindowOpacity:maxOpacity];
}

//Window Visibility --------------------------------------------------------------------------------------------------
//Update the visibility of this window (Window is visible if there are any tabs present)
- (void)setVisible:(BOOL)inVisible animate:(BOOL)animate
{    
    if (inVisible != windowIsVisible) {
        windowIsVisible = inVisible;
        
        if (animate) {
            if (!fadeAnimation) {
				NSDictionary *animDict = [NSDictionary dictionaryWithObjectsAndKeys:
					panel, NSViewAnimationTargetKey,
					inVisible ? NSViewAnimationFadeInEffect : NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
					nil];
                fadeAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animDict]];

				//1.0 / FPS = duration per step
				//1.0 / step = number of steps (e.g.: If step = 0.1, 1.0 / step = 10 steps)
				//duration per step * number of steps = total duration
				NSTimeInterval step = [[NSApp currentEvent] shiftKey] ? WINDOW_FADE_SLOW_STEP : WINDOW_FADE_STEP;
				fadeAnimation.duration = (1.0 / step) * (1.0 / WINDOW_FADE_FPS);

				[fadeAnimation startAnimation];
            }
        } else {
            [self _setWindowOpacity:(windowIsVisible ? maxOpacity : WINDOW_FADE_MIN)];
        }
    }
}

- (void)_setWindowOpacity:(CGFloat)opacity
{
    [panel setAlphaValue:opacity];
}


@end



