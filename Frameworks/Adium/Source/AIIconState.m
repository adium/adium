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

@interface AIIconState ()
- (void)_init;
@end

@implementation AIIconState

- (id)initWithImages:(NSArray *)inImages delay:(CGFloat)inDelay looping:(BOOL)inLooping overlay:(BOOL)inOverlay
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
    //init
    if ((self = [super init])) {
		AIIconState		*animatingState = nil;
		AIIconState		*overlayAnimatingState = nil;
		AIIconState		*baseIconState = nil;
		
		[self _init];

		for (AIIconState *iconState in [inIconStates reverseObjectEnumerator]) {
			if (baseIconState || animatingState)
				break;

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
    
    delay = 1.0f;
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

- (NSInteger)currentFrame
{
    return currentFrame;
}

- (void)nextFrame
{
    if (animated) {
		NSUInteger imageArrayCount = [imageArray count];

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

- (CGFloat)animationDelay{
    return delay;
}

- (NSInteger)numberOfFrames{
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

- (NSImage *)_compositeStates:(NSArray *)iconStateArray withBaseState:(AIIconState *)baseState animatingState:(AIIconState *)animatingState forFrame:(NSInteger)frame
{
    NSImage			*workingImage;
    AIIconState		*iconState;
	NSInteger				animatingStateNumberOfFrames = [animatingState numberOfFrames];
	
	NSMutableArray *imagesToComposite = [NSMutableArray array];
	
    //Use the base image as our starting point
    if ([baseState animated]) {
        if (baseState == animatingState) { //Only one state animates at a time
            [imagesToComposite addObject:[[baseState imageArray] objectAtIndex:frame]];
        } else {
            [imagesToComposite addObject:[[baseState imageArray] objectAtIndex:0]];
        }
    } else {
        [imagesToComposite addObject:[baseState image]];
    }
	
    //Draw on the images of all overlayed states
    for (iconState in iconStateArray) {
        if ([iconState overlay]) {
            //Get the overlay image
            if ([iconState animated] && animatingStateNumberOfFrames) {
                if (iconState == animatingState) { //Only one state animates at a time
                    [imagesToComposite addObject:[[iconState imageArray] objectAtIndex:frame]];
                } else {
                    [imagesToComposite addObject:[[iconState imageArray] objectAtIndex:( ((frame + 1) / animatingStateNumberOfFrames) * ([iconState numberOfFrames] - 1)) ]];
				}
            } else {
				NSImage *img = [iconState image];
				if(img)
					[imagesToComposite addObject:img];
            }
        }
    }
	
	workingImage = [[NSImage alloc] initWithSize:[[imagesToComposite objectAtIndex:0] size]];
	[workingImage lockFocus];
	for (NSImage *overlayImage in imagesToComposite)
	{
		NSSize size = [overlayImage size];
		[overlayImage drawAtPoint:NSMakePoint(0,0)
						 fromRect:NSMakeRect(0,0,size.width,size.height)
						operation:NSCompositeSourceOver
						 fraction:1.0f];
	}
	[workingImage unlockFocus];
	
    return [workingImage autorelease];
}

@end
