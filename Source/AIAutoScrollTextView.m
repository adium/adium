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

#import "AIAutoScrollTextView.h"

#define ABOUT_SCROLL_FPS	30.0f
#define ABOUT_SCROLL_RATE	1.0f

@interface AIAutoScrollTextView ()
- (void)startScrolling;
- (void)stopScrolling;
- (void)scrollTimer:(NSTimer *)scrollTimer;
@end

@implementation AIAutoScrollTextView


- (void)loadText:(NSAttributedString *)textToLoad
{
    [self addTrackingArea:[[[NSTrackingArea alloc] initWithRect:[self bounds]
														options:(NSTrackingMouseEnteredAndExited |
																 NSTrackingActiveAlways |
																 NSTrackingInVisibleRect)
														  owner:self
													   userInfo:nil] autorelease]];

	[[self textStorage] setAttributedString:textToLoad];
    [self startScrolling];
}

- (void)dealloc
{
	[scrollTimer invalidate]; [scrollTimer release]; scrollTimer = nil;

	[super dealloc];
}

// When the user scrolls stop the automatic scrolling
- (void)scrollWheel:(NSEvent *)theEvent
{
   	if (scrollTimer) {
		[self stopScrolling];
    }

	[super scrollWheel:theEvent];
}

- (void)toggleScrolling
{
	if (scrollTimer) {
		[self stopScrolling];
	} else{
		[self startScrolling];
    }
}

// Resume scrolling after leaving the bounds
- (void)mouseExited:(NSEvent *)theEvent
{
    if (!scrollTimer) {
		[self startScrolling];
    }
    
    [super mouseExited:theEvent];
}

- (void)startScrolling
{
    [[self enclosingScrollView] setHasVerticalScroller:NO];
	[[self enclosingScrollView] setLineScroll:0.0f];
	[[self enclosingScrollView] setPageScroll:0.0f];

	/*
	 * Xxx Somehow there are 7 pixels missing after re-starting to scroll - add
	 * them by hand until we find the cause.
	 */
	scrollLocation = [[[self enclosingScrollView] contentView] bounds].origin.y + 7;
	maxScroll = [[self textStorage] size].height;
    
	scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0f / ABOUT_SCROLL_FPS)
													target:self
												  selector:@selector(scrollTimer:)
												  userInfo:nil
												   repeats:YES] retain];
}

- (void)stopScrolling
{
	[scrollTimer invalidate]; [scrollTimer release]; scrollTimer = nil;

	// Enable scrolling
    [[self enclosingScrollView] setHasVerticalScroller:YES];
    [[self enclosingScrollView] setLineScroll:10.0f];
	[[self enclosingScrollView] setPageScroll:10.0f];
    
    /* 
     * Scroll to correct location, otherwise scrolling will start
     * at the end of the last manual scroll
     */
    [[[self enclosingScrollView] contentView] scrollPoint:NSMakePoint(0, scrollLocation)];
}

// Scroll the credits
- (void)scrollTimer:(NSTimer *)scrollTimer
{
	scrollLocation += ABOUT_SCROLL_RATE;

	if (scrollLocation > maxScroll || scrollLocation < 0) {
		scrollLocation = 0;
    }

	[self scrollPoint:NSMakePoint(0, scrollLocation)];
}

@end
