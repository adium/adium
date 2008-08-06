/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AIAnimatedView.h"

/*
    An animated image.  Image file should be frames stacked vertically.
*/

@interface AIAnimatedView (PRIVATE)
    - (void)animate:(NSTimer *)timer;
@end

@implementation AIAnimatedView

- (id)initWithFrame:(NSRect)frameRect image:(NSImage *)inImage frames:(int)inFrames delay:(float)inDelay target:(id)inTarget action:(SEL)inAction
{
	if ((self = [super initWithFrame:frameRect])) {
		image = [inImage retain];
		frames = inFrames;
		delay = inDelay;
		target = [inTarget retain];
		action = inAction;
	}

	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		image = nil;
		frames = 1;
		delay = 0;
		target = nil;
		action = nil;
	}

	return self;
}

- (void)dealloc
{
    [image release];
    [target release];

    [super dealloc];
}

- (void)setImage:(NSImage *)inImage
{
    if (inImage != image) {
        [image release];
        image = [inImage retain];
    }
}

- (void)setTarget:(id)inTarget
{
    if (target != inTarget) {
        [target release];
        target = [inTarget retain];
    }
}

- (void)setAction:(SEL)inAction
{
    action = inAction;
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)setDelay:(float)inDelay
{
    delay = inDelay;
}

- (void)setFrames:(int)inFrames
{
    frames = inFrames;
}

- (IBAction)startAnimation:(id)sender
{
    currentFrame = frames;
    [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(animate:) userInfo:nil repeats:YES];
}

- (void)drawRect:(NSRect)rect
{
    NSRect	sourceRect;
    int		frameHeight;

    //Clear
    [[NSColor clearColor] set];
    [NSBezierPath fillRect:rect];

    //Set up the source rect
    frameHeight = ((float)[image size].height / (float)frames);
    sourceRect.origin.x = 0;
    sourceRect.size.width = [image size].width;
    sourceRect.origin.y = frameHeight * currentFrame;
    sourceRect.size.height = frameHeight;

    //Draw
    [image drawInRect:rect fromRect:sourceRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)animate:(NSTimer *)timer
{
    //Move to the next frame
    currentFrame--;
    if (currentFrame <= 0) {
        [timer invalidate];

        //Notify our target that the animation is complete (after a delay for the final image)
        if (target && action) {
            [target performSelector:action withObject:nil afterDelay:delay];
        }
    }

    //Display
    [self setNeedsDisplay:YES];
}



@end
