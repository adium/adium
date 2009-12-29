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

@interface AIAutoScrollTextView (Private)
- (void)startScrolling;
- (void)stopScrolling;
@end

@implementation AIAutoScrollTextView

- (void)loadText:(NSAttributedString *)textToLoad
{
	[[self textStorage] setAttributedString:textToLoad];
	[self startScrolling];
}

- (void)dealloc
{
	[scrollTimer invalidate]; [scrollTimer release]; scrollTimer = nil;
	[eventLoopScrollTimer invalidate]; [eventLoopScrollTimer release]; eventLoopScrollTimer = nil;
	[super dealloc];
}

//When the user scrolls stop the automatic scrolling
- (void)scrollWheel:(NSEvent *)theEvent
{
	if (scrollTimer)
		[self stopScrolling];

	[super scrollWheel:theEvent];
}

- (void)toggleScrolling
{
	if (scrollTimer)
		[self stopScrolling];
	else
		[self startScrolling];
}

- (void)startScrolling
{
	[[self enclosingScrollView] setLineScroll:0.0f];
	[[self enclosingScrollView] setPageScroll:0.0f];
	[[self enclosingScrollView] setVerticalScroller:nil];
	[[self enclosingScrollView] setHasVerticalScroller:NO];
	
	//Start scrolling
	scrollLocation = [[[self enclosingScrollView] contentView] bounds].origin.y;
	maxScroll = [[self textStorage] size].height - [[self enclosingScrollView] documentVisibleRect].size.height;
	scrollTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0/ABOUT_SCROLL_FPS)
													target:self
												  selector:@selector(scrollTimer:)
												  userInfo:nil
												   repeats:YES] retain];
	eventLoopScrollTimer = [[NSTimer timerWithTimeInterval:(1.0/ABOUT_SCROLL_FPS)
													target:self
												  selector:@selector(scrollTimer:)
												  userInfo:nil
												   repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:eventLoopScrollTimer forMode:NSEventTrackingRunLoopMode];
}

- (void)stopScrolling
{
	[scrollTimer invalidate]; [scrollTimer release]; scrollTimer = nil;
	[eventLoopScrollTimer invalidate]; [eventLoopScrollTimer release]; eventLoopScrollTimer = nil;

	//Enable scrolling and show the scrollbar
	[[self enclosingScrollView] setLineScroll:10.0f];
	[[self enclosingScrollView] setPageScroll:10.0f];
	[[self enclosingScrollView] setVerticalScroller:[[[NSScroller alloc] init] autorelease]];
	[[self enclosingScrollView] setHasVerticalScroller:YES];
}

//Scroll the credits
- (void)scrollTimer:(NSTimer *)scrollTimer
{
	scrollLocation += ABOUT_SCROLL_RATE;
	
	if (scrollLocation > maxScroll) scrollLocation = 0;
	if (scrollLocation < 0) scrollLocation = maxScroll;
	
	[self scrollPoint:NSMakePoint(0, scrollLocation)];
}

@end
