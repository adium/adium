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

#import "AIAnimatedFloater.h"
#import "AIAnimatedView.h"

/*
    Create a temporary floating window with an animated image
*/

@interface AIAnimatedFloater (PRIVATE)
- (id)initWithImage:(NSImage *)inImage size:(NSSize)inSize frames:(int)inFrames delay:(float)inDelay at:(NSPoint)inPoint;
@end

@implementation AIAnimatedFloater

+ (id)animatedFloaterWithImage:(NSImage *)inImage size:(NSSize)inSize frames:(int)inFrames delay:(float)inDelay at:(NSPoint)inPoint
{
    return [[self alloc] initWithImage:inImage size:(NSSize)inSize frames:inFrames delay:inDelay at:inPoint];
}

- (id)initWithImage:(NSImage *)inImage size:(NSSize)inSize frames:(int)inFrames delay:(float)inDelay at:(NSPoint)inPoint
{
    NSRect		frame;
    AIAnimatedView	*animatedView;

    [self init];
    
    //Set up the panel
    frame = NSMakeRect(0, 0, inSize.width, inSize.height);    
    panel = [[NSPanel alloc] initWithContentRect:frame
                                         styleMask:NSBorderlessWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
    [panel setHidesOnDeactivate:NO];
    [panel setLevel:NSStatusWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];

    //Setup the animated view
    animatedView = [[AIAnimatedView alloc] initWithFrame:frame image:inImage frames:inFrames delay:inDelay target:self action:@selector(close:)];
    [[panel contentView] addSubview:[animatedView autorelease]];

    //
    [panel setFrameOrigin:inPoint];
    [panel makeKeyAndOrderFront:nil];
    [panel setFrameOrigin:inPoint];
    [animatedView startAnimation:nil];

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (IBAction)close:(id)sender
{
    [panel orderOut:nil];
    [panel release];

    [self release];
}


@end
