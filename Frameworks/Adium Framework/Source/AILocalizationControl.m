/*
 Note: This file is dual-licensed under the BSD "3-Clause" license and the GPL license.
 
 Copyright (c) 2009, Evan Schoenberg
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
 following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following
 disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
 disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of the Adium nor the names of its contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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

//Implementation file for AILocalizationXXXX classes; this is imported by them and should not be used directly

@class AILocalizationTextField;

- (id)initWithCoder:(NSCoder *)inCoder
{
	if ((self = [super initWithCoder:inCoder])) {
		[self _initLocalizationControl];
	}
	
	return self;
}

- (void)awakeFromNib
{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
		[super awakeFromNib];
	}

	originalFrame = [TARGET_CONTROL frame];
}

- (void)setRightAnchorMovementType:(AILocalizationAnchorMovementType)inType
{
	rightAnchorMovementType = inType;
}

/*!
 * @brief Set if resizing of this control should always resize its right-anchored window
 *
 * The default is NO.  If YES, resizing the control will maintain distance to the right side of the window
 * even if by resizing the control isn't at the window's edge.  This is useful, for example, to keep a left-aligned checkbox
 * with a right-aligned button to its right from overlapping the button.  In a perfect world, we would move the button
 * which would then shift the window, but we're not set up for that kind of recursively intelligent positioning.
 */
- (void)setAlwaysMoveRightAnchoredWindow:(BOOL)inAlwaysMove
{
	alwaysMoveRightAnchoredWindow = inAlwaysMove;
}

/*!
 * @brief Handle automatic sizing and positioning
 *
 * There's a lot of magic in this method, unfortunately, but it does what it does quite well.
 * The goal: Start off with a nicely positioned control.  It looks good containing the text it contains; it is positioned
 * properly in relation to other controls.  Then, change its string value, generally bringing in a localized string from
 * the Localizable.strings file via XXLocalizedString().  The control should 'magically' be resized, maintaining
 * its position [including taking into account its alignment].  Furthermore, if the control is informed of other views
 * relative to it via having its view_anchorTo* outlets connected, take into account these other views.  Resize them if possible
 * to maintain the same relative spacing as they had originally.  If the control has a window it is allowed to resize,
 * informed of it via a connected window_anchorTo* outlet, resize the window as necessary to allow enough space for the 
 * newly sized control.
 *
 * The TARGET_CONTROL &#35;define is used rather than self because classes using this method can choose to send sizing messages
 * to another object.  For example, AILocalizationButtonCell uses (NSControl *)[self controlView].
 *
 * Whew.
 *
 * @param oldFrame The original frame, before sizing
 * @param inStringValue The string value which was set. This is passed purely for debugging purposes and is not used in this method.
 */
- (void)_handleSizingWithOldFrame:(NSRect)oldFrame stringValue:(NSString *)inStringValue
{
	//Textfield uses 17, button uses 14.
	
	NSRect			newFrame;
	NSTextAlignment	textAlignment;
	
	[TARGET_CONTROL sizeToFit];
	
	newFrame = [TARGET_CONTROL frame];
	
	/* For NSButtons, sizeToFit is 8 pixels smaller than the HIG recommended size  */
	if ([self isKindOfClass:[NSButton class]]) {
		newFrame.size.width += 8;
	}
	
	//Only use integral widths to keep alignment correct;
	//round up as an extra pixel of whitespace never hurt anybody
	newFrame.size.width = AIround(NSWidth(newFrame) + 0.5f);
	
	//Enforce a minimum width of the original frame width
	if (NSWidth(newFrame) < NSWidth(originalFrame)) {
		newFrame.size.width = NSWidth(originalFrame);
	}

	textAlignment = [self alignment];
	switch (textAlignment) {
		case NSRightTextAlignment:
			//Keep the right edge in the same place at all times if we are right aligned
			newFrame.origin.x = NSMaxX(oldFrame) - NSWidth(newFrame);
			break;
		case NSCenterTextAlignment:
		{
			//Keep the center in the same place
			CGFloat windowMaxX = NSMaxX([[TARGET_CONTROL superview] frame]);
			
			newFrame.origin.x = NSMinX(oldFrame) + (NSWidth(oldFrame) - NSWidth(newFrame))/2;
			
			if (NSMaxX(newFrame) + 17 > windowMaxX) {
				newFrame.origin.x -= ((NSMaxX(newFrame) + 17) - windowMaxX);
			}

			//Only use integral origins to keep alignment correct;
			//round up as an extra pixel of whitespace never hurt anybody
			newFrame.origin.x = AIround(newFrame.origin.x + 0.5f);			
			break;
		}
		case NSLeftTextAlignment:
		default:
			break;
	}

	newFrame.origin.y = oldFrame.origin.y - (NSHeight(newFrame) - NSHeight(oldFrame));

	CGFloat distanceToRightAnchoredView = 0;
	if (view_anchorToRightSide) {
		distanceToRightAnchoredView = NSMinX([view_anchorToRightSide frame]) - NSMaxX(oldFrame);
	}
	
	[TARGET_CONTROL setFrame:newFrame];
	[TARGET_CONTROL setNeedsDisplay:YES];
	if ([TARGET_CONTROL respondsToSelector:@selector(superview)]) {
		[[TARGET_CONTROL superview] setNeedsDisplayInRect:oldFrame];
	}

	//Resize the window to fit the contactNameLabel if the current size is not correct
	if (NSWidth(newFrame) != NSWidth(oldFrame)) {
		
		//Too close on left; need to expand window left
		if (window_anchorOnLeftSide && NSMinX(newFrame) < 17) {
			CGFloat		difference = 17 - NSMinX(newFrame);

			[self _resizeWindow:window_anchorOnLeftSide leftBy:difference];				
			
			//Fix the origin - autosizing will end up moving this into the proper location
			newFrame.origin.x = 17;
			
			[TARGET_CONTROL setFrame:newFrame];
			[TARGET_CONTROL setNeedsDisplay:YES];
		}
		
		/* If we have a window anchored to our right side, and we are now too close to the right side of that
		 * window, resize the window so it is larger horizontally to compensate */
		if (window_anchorOnRightSide) {
			if (NSMaxX(newFrame) > (NSWidth([window_anchorOnRightSide frame]) - 17)) {
				CGFloat		difference =  NSMaxX(newFrame) - (NSWidth([window_anchorOnRightSide frame]) - 17);
				
				[self _resizeWindow:window_anchorOnRightSide rightBy:difference];
				
				newFrame.origin.x = NSWidth([window_anchorOnRightSide frame]) - newFrame.size.width - 17;
				
				[TARGET_CONTROL setFrame:newFrame];
				[TARGET_CONTROL setNeedsDisplay:YES];

			} else if (alwaysMoveRightAnchoredWindow) {
				CGFloat		difference =  NSMaxX(newFrame) - NSMaxX(oldFrame);
				if (difference > 0) {
					[self _resizeWindow:window_anchorOnRightSide rightBy:difference];
				}
			}

		} else {
			/* We don't have a window anchored to the right side.
			 * If we are outside our superview's frame, we should try moving our origin left.  If we can do
			 * that without exiting our superview, it's probably better. */
			if (NSMaxX(newFrame) > [[TARGET_CONTROL superview] frame].size.width) {
				CGFloat	overshoot = (NSMaxX(newFrame) - NSWidth([[TARGET_CONTROL superview] frame]));

				//Correct for the overshoot, but don't let it go outside the superview.
				newFrame.origin.x -= overshoot;
				if (NSMinX(newFrame) < 0) {
					newFrame.origin.x = 0;
					NSLog(@"*** Localization warning: \"%@\"",inStringValue);
				}

				[TARGET_CONTROL setFrame:newFrame];
				[TARGET_CONTROL setNeedsDisplay:YES];
			}
		}
		
		if (newFrame.origin.x < oldFrame.origin.x) {
			//Shifted further left than it used to be
			if (view_anchorToLeftSide) {
				NSRect		leftAnchorFrame = [view_anchorToLeftSide frame];
				CGFloat		difference = (NSMinX(oldFrame) - NSMinX(newFrame));
	
				leftAnchorFrame.origin.x -= difference;
				
				if (leftAnchorFrame.origin.x < 0) {
					CGFloat	overshoot = -NSMinX(leftAnchorFrame);

					/* We needed to move our left anchored object to the left, but that put it outside its
					 * superview. Use a 0 X origin. */
					leftAnchorFrame.origin.x = 0;
					
					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
					
					/* If we have a window we can resize to the left, do so.  Otherwise, log a warning */
					if (window_anchorOnLeftSide) {
						[self _resizeWindow:window_anchorOnLeftSide leftBy:overshoot];

					} else {
						NSLog(@"*** Localization warning: \"%@\"",inStringValue);
					}
					
				} else {
/*
 NSLog(@"%@: Moving left anchor from %@ to %@",inStringValue,NSStringFromRect([view_anchorToLeftSide frame]),
						  NSStringFromRect(leftAnchorFrame));
 */
					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
				}
			}
			
			if (NSMinX(newFrame) < 0) {
				CGFloat difference = 0 - NSMinX(newFrame);
				newFrame.origin.x = 0;

				if (view_anchorToRightSide) {
					NSRect anchorToRightSideFrame = [view_anchorToRightSide frame];
					anchorToRightSideFrame.origin.x += difference;
					[view_anchorToRightSide setFrame:anchorToRightSideFrame];
					[view_anchorToRightSide setNeedsDisplay:YES];
				}

				[TARGET_CONTROL setFrame:newFrame];
				[TARGET_CONTROL setNeedsDisplay:YES];

			}
			
		} else {
			/* newFrame.origin.x >= oldFrame.origin.x */
			if (view_anchorToRightSide) {
				NSRect		rightAnchorFrame = [view_anchorToRightSide frame];
				if (window_anchorOnLeftSide) {
					CGFloat newDistanceToRightAnchoredView = NSMinX(rightAnchorFrame) - NSMaxX(newFrame);
					
					if (distanceToRightAnchoredView < newDistanceToRightAnchoredView) {
						/* The right-anchored view is now too close to our right side -
						* expand the window left again if needed to keep it the same.
						*/
						CGFloat amountToExpandWindow = (newDistanceToRightAnchoredView - distanceToRightAnchoredView);
						newFrame.origin.x -= amountToExpandWindow;
						if (newFrame.origin.x < 17) {
							amountToExpandWindow += 17 - NSMinX(newFrame);
							newFrame.origin.x = 17;
						}
						
						[self _resizeWindow:window_anchorOnLeftSide leftBy:amountToExpandWindow];				
						
						[TARGET_CONTROL setFrame:newFrame];
						[TARGET_CONTROL setNeedsDisplay:YES];
					}
					
				} else {
					if (rightAnchorMovementType == AILOCALIZATION_MOVE_ANCHOR) {
						//Move our anchor with us
						CGFloat		difference = NSWidth(newFrame) - NSWidth(oldFrame);
						rightAnchorFrame.origin.x += difference;
						
						//If this would put us outside the view, reduce the width of the anchored view
						//XXX could add a window_anchorOnRightSide and have a window expansion behavior instead.
						//XXX needs to be optional via a setting
						/*
						 if ((rightAnchorFrame.origin.x + rightAnchorFrame.size.width) > newFrame.size.width) {
							 rightAnchorFrame.size.width = newFrame.size.width - rightAnchorFrame.origin.x;
						 }
						 */
						
						[view_anchorToRightSide setFrame:rightAnchorFrame];
						[view_anchorToRightSide setNeedsDisplay:YES];
						
					} else { /*rightAnchorMovementType == AILOCALIZATION_MOVE_SELF */
						
						//Move us left to keep our distance from our anchor view to the right
						newFrame.origin.x = NSMinX(rightAnchorFrame) - distanceToRightAnchoredView - NSWidth(newFrame);
						
						[TARGET_CONTROL setFrame:newFrame];
						[TARGET_CONTROL setNeedsDisplay:YES];
					}
					
				}
			}
			
			if (view_anchorToLeftSide) {
				NSRect		leftAnchorFrame = [view_anchorToLeftSide frame];
				CGFloat		difference = (oldFrame.origin.x - newFrame.origin.x);
				
				leftAnchorFrame.origin.x -= difference;
				
				if (leftAnchorFrame.origin.x < 0) {
					CGFloat	overshoot = -leftAnchorFrame.origin.x;
					leftAnchorFrame.origin.x = 0;

					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
					
					[self _resizeWindow:[TARGET_CONTROL window] leftBy:overshoot];

				} else {	
					[view_anchorToLeftSide setFrame:leftAnchorFrame];
					[view_anchorToLeftSide setNeedsDisplay:YES];
				}
			}
		}
		
		//After all this fun and games, check out anchors again, this time to move self if need be
		{
			if (view_anchorToRightSide) {
				NSRect		rightAnchorFrame = [view_anchorToRightSide frame];

				//Ensure we are not now overlapping our right anchor; if so, shift left
				if (window_anchorOnLeftSide) {
					//We'll be able to shit the whole window; maintain distance to the right anchor
					if ((NSMinX(rightAnchorFrame) - NSMaxX(newFrame)) < distanceToRightAnchoredView) {
						newFrame.origin.x = NSMinX(rightAnchorFrame) - distanceToRightAnchoredView - NSWidth(newFrame);
						[TARGET_CONTROL setFrame:newFrame];
						[TARGET_CONTROL setNeedsDisplay:YES];
						
						//As we did initially, check to see if we now need to expand the window to the left
						if (window_anchorOnLeftSide && newFrame.origin.x < 17) {
							CGFloat		difference = 17 - newFrame.origin.x;

							[self _resizeWindow:window_anchorOnLeftSide leftBy:difference];				

							//Fix the origin - autosizing will end up moving this into the proper location
							newFrame.origin.x = 17;
							
							[TARGET_CONTROL setFrame:newFrame];
							[TARGET_CONTROL setNeedsDisplay:YES];
						}
					}
					
				} else {
					//We can't shift the window; just keep it from overlapping the right anchor
					if (NSMaxX(newFrame) > NSMinX(rightAnchorFrame)) {
						//+8 perhaps for textviews; 0 for buttons, which have weird frames.
						newFrame.origin.x -= ((NSMaxX(newFrame) - NSMinX(rightAnchorFrame))/* + 8 */);
						
						[TARGET_CONTROL setFrame:newFrame];
						[TARGET_CONTROL setNeedsDisplay:YES];
					}					
				}
			}
		}
	} /* end of (newFrame.size.width != oldFrame.size.width) */
}

- (void)_resizeWindow:(NSWindow *)inWindow leftBy:(CGFloat)difference
{
	NSRect		windowFrame = [inWindow frame];
	NSRect		screenFrame = [[inWindow screen] frame];

	//Shift the origin
	windowFrame.origin.x -= difference;
	//But keep it on the screen
	if (windowFrame.origin.x < screenFrame.origin.x) windowFrame.origin.x = screenFrame.origin.x;
				
	//Increase the width
	windowFrame.size.width += difference;
	//But keep it on the screen
	if ((windowFrame.origin.x + windowFrame.size.width) > (screenFrame.origin.x + screenFrame.size.width)) {
		windowFrame.origin.x -= (screenFrame.origin.x + screenFrame.size.width) - (windowFrame.origin.x + windowFrame.size.width);
	}
	
	[inWindow setFrame:windowFrame display:NO];
}				

- (void)_resizeWindow:(NSWindow *)inWindow rightBy:(CGFloat)difference
{
	NSRect		windowFrame = [inWindow frame];
	NSRect		screenFrame = [[inWindow screen] frame];

	//Increase the width
	windowFrame.size.width += difference;
	//But keep it on the screen
	if ((windowFrame.origin.x + windowFrame.size.width) > (screenFrame.origin.x + screenFrame.size.width)) {
		windowFrame.origin.x -= (screenFrame.origin.x + screenFrame.size.width) - (windowFrame.origin.x + windowFrame.size.width);
	}
	
	[inWindow setFrame:windowFrame display:NO];
}				

