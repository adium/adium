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

#import <Adium/AIIconState.h>

@interface AIIconState (PRIVATE)
- (void)_init;
@end

@implementation AIIconState

//
- (id)initWithImages:(NSArray *)inImages delay:(float)inDelay looping:(BOOL)inLooping overlay:(BOOL)inOverlay
{
    //init
    if ((self = [super init]))
	{
		[self _init];

		//
		animated = YES;
		imageArray = [inImages mutableCopy];
		numberOfFrames = [imageArray count];
		delay = inDelay;
		looping = inLooping;
		overlay = inOverlay;
	}
		        
    return self;
}

- (id)initWithImage:(NSImage *)inImage overlay:(BOOL)inOverlay
{
    //init
    if ((self = [super init]))
	{
		[self _init];

		//
		image = [inImage retain];
		overlay = inOverlay;
	}

    return self;
}

//Create a new icon state by combining/compositing others
- (id)initByCompositingStates:(NSArray *)inIconStates
{
    AIIconState		*animatingState = nil;
	AIIconState		*overlayAnimatingState = nil;
    AIIconState		*baseIconState = nil;

	NSEnumerator	*enumerator;
	AIIconState		*iconState;
	
    //init
    if ((self = [super init]))
	{
		[self _init];
		

		enumerator = [inIconStates reverseObjectEnumerator];
		while ((iconState = [enumerator nextObject]) && !baseIconState && !animatingState) {
			//Find the base image (The image of the top-most non-overlay state)
			if (!baseIconState && ![iconState overlay]) baseIconState = iconState;
			
			if (!animatingState && [iconState animated]) {
				if (![iconState overlay]) {
					animatingState = iconState;
				} else {
					overlayAnimatingState = iconState;
				}
			}
		}

		//Abort if no base state image is found
		if (!baseIconState) return self;

		//We prefer to have an animated state that isn't an overly, but if we didn't find one we'll take the overlay
		//animating state if that was found
		if (!animatingState) animatingState = overlayAnimatingState;
		
		if (!animatingState) { //Static icon
			//init
			delay = 0;
			animated = NO;
			image = [[self _compositeStates:inIconStates
							  withBaseState:baseIconState
							 animatingState:animatingState 
								   forFrame:0] retain];

		} else { //Animating icon
			//init
			animated = YES;
			delay = [animatingState animationDelay];
			numberOfFrames = [[animatingState imageArray] count];
			imageArray = [[NSMutableArray alloc] init];

			//Hold onto some of this info so we can render the additional images later
			iconRendering_states = [inIconStates retain];
			iconRendering_baseState = [baseIconState retain];
			iconRendering_animationState = [animatingState retain];

			//Render the first image
			image = [[self _compositeStates:inIconStates 
							  withBaseState:baseIconState
							 animatingState:animatingState
								   forFrame:0] retain];
			[imageArray addObject:image];
		}
	}
		
    return self;
}

//Generic init
- (void)_init
{
    image = nil;
    animated = NO;
    imageArray = nil;

    iconRendering_states = nil;
    iconRendering_baseState = nil;
    iconRendering_animationState = nil;
    
    delay = 1.0;
    looping = NO;
    overlay = NO;
    currentFrame = 0;
    numberOfFrames = 0;
}

- (void)dealloc
{
    [image release];
    [imageArray release];
    [iconRendering_states release];
    [iconRendering_baseState release];
    [iconRendering_animationState release];
    
    [super dealloc];
}

- (int)currentFrame
{
    return currentFrame;
}

- (void)nextFrame
{
    if (animated) {
		unsigned imageArrayCount = [imageArray count];

        //Next frame
        if (++currentFrame >= numberOfFrames) {
            currentFrame = 0;
        }

        //Get the new image (compositing if necessary)
        if ((currentFrame >= imageArrayCount) &&
		   iconRendering_states &&
		   iconRendering_baseState &&
		   iconRendering_animationState) {
            [imageArray addObject:[self _compositeStates:iconRendering_states 
										   withBaseState:iconRendering_baseState 
										  animatingState:iconRendering_animationState
												forFrame:currentFrame]];
			imageArrayCount++;

            //After rendering the last frame, we can release our icon rendering information (it's no longer needed)
            if (currentFrame >= (numberOfFrames - 1)) {
                [iconRendering_states release]; iconRendering_states = nil;
                [iconRendering_baseState release]; iconRendering_baseState = nil;
                [iconRendering_animationState release]; iconRendering_animationState = nil;
            }
        }

		if (currentFrame < imageArrayCount) {
			[image release];
			image = [[imageArray objectAtIndex:currentFrame] retain];
		}
    }
}

- (BOOL)animated{
    return animated;
}

- (float)animationDelay{
    return delay;
}

- (int)numberOfFrames{
    return numberOfFrames;
}

- (BOOL)looping{
    return looping;
}

- (BOOL)overlay{
    return overlay;
}

- (NSArray *)imageArray{
    return imageArray;
}

- (NSImage *)image{
    return image;
}

- (NSImage *)_compositeStates:(NSArray *)iconStateArray withBaseState:(AIIconState *)baseState animatingState:(AIIconState *)animatingState forFrame:(int)frame
{
    NSEnumerator	*enumerator;
    NSImage			*workingImage;
    AIIconState		*iconState;
	int				animatingStateNumberOfFrames = [animatingState numberOfFrames];
	
    //Use the base image as our starting point
    if ([baseState animated]) {
        if (baseState == animatingState) { //Only one state animates at a time
            workingImage = [[[baseState imageArray] objectAtIndex:frame] copy];
        } else {
            workingImage = [[[baseState imageArray] objectAtIndex:0] copy];
        }
    } else {
        workingImage = [[baseState image] copy];
    }
	
    //Draw on the images of all overlayed states
    enumerator = [iconStateArray objectEnumerator];
    while ((iconState = [enumerator nextObject])) {
        if ([iconState overlay]) {
            NSImage	*overlayImage;
			
            //Get the overlay image
            if ([iconState animated] && animatingStateNumberOfFrames) {
                if (iconState == animatingState) { //Only one state animates at a time
                    overlayImage = [[iconState imageArray] objectAtIndex:frame];
                } else {
                    overlayImage = [[iconState imageArray] objectAtIndex:( ((frame + 1) / animatingStateNumberOfFrames) * ([iconState numberOfFrames] - 1)) ];
				}
            } else {
                overlayImage = [iconState image];
            }
			
			NSSize size = [overlayImage size];
			
            //Layer it on top of our working image
            [workingImage lockFocus];
            [overlayImage drawAtPoint:NSMakePoint(0,0)
							 fromRect:NSMakeRect(0,0,size.width,size.height)
							operation:NSCompositeSourceOver
							 fraction:1.0];
            [workingImage unlockFocus];
        }
    }
	
    return [workingImage autorelease];
}

@end
