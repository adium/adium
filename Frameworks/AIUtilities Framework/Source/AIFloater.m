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

#import "AIFloater.h"
#import "AIEventAdditions.h"

#define WINDOW_FADE_FPS			24.0f
#define WINDOW_FADE_STEP		0.3f
#define WINDOW_FADE_SLOW_STEP	0.1f
#define WINDOW_FADE_MAX			1.0f
#define WINDOW_FADE_MIN			0.0f
#define WINDOW_FADE_SNAP		0.05f // How close to min/max we must get before fade is finished

@interface AIFloater ()

- (id)initWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask;
- (void)AI_setWindowOpacity:(CGFloat)opacity;

@end

@implementation AIFloater

// Because the floater can control its own display, it retains itself and releases when it closes.
+ (id)newFloaterWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask
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

		// Set up the panel
		frame = NSMakeRect(0, 0, [inImage size].width, [inImage size].height);
		
		panel = [[NSPanel alloc] initWithContentRect:frame
										   styleMask:styleMask
											 backing:NSBackingStoreBuffered
											   defer:NO];
		[panel setHidesOnDeactivate:NO];
		[panel setIgnoresMouseEvents:YES];
		[panel setLevel:NSStatusWindowLevel];
		[panel setHasShadow:YES];
		[panel setOpaque:NO];
		[panel setBackgroundColor:[NSColor clearColor]];
		[self AI_setWindowOpacity:WINDOW_FADE_MIN];
			
		// Setup the static view
		staticView = [[NSImageView alloc] initWithFrame:frame];
		[staticView setImage:inImage];
		[staticView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		[[panel contentView] addSubview:staticView];
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
    [fadeAnimation stopAnimation]; fadeAnimation = nil;
    [panel orderOut:nil];
	panel = nil;
}

- (void)setMaxOpacity:(CGFloat)inMaxOpacity
{
    maxOpacity = inMaxOpacity;
    if (windowIsVisible) [self AI_setWindowOpacity:maxOpacity];
}

#pragma mark Window Visibility

// Update the visibility of this window (Window is visible if there are any tabs present)
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

				// 1.0f / FPS = duration per step
				// 1.0f / step = number of steps (e.g.: If step = 0.1f, 1.0f / step = 10 steps)
				// duration per step * number of steps = total duration
				NSTimeInterval step = [[NSApp currentEvent] shiftKey] ? WINDOW_FADE_SLOW_STEP : WINDOW_FADE_STEP;
				fadeAnimation.duration = (1.0f / step) * (1.0f / WINDOW_FADE_FPS);

				[fadeAnimation startAnimation];
            }
        } else {
            [self AI_setWindowOpacity:(windowIsVisible ? maxOpacity : WINDOW_FADE_MIN)];
        }
    }
}

- (void)AI_setWindowOpacity:(CGFloat)opacity
{
    [panel setAlphaValue:opacity];
}

@end
