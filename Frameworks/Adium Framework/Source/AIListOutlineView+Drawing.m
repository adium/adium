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

#import "AIListOutlineView+Drawing.h"
#import <Adium/AIListCell.h>
#import <AIUtilities/AIGradientAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <Adium/AIListGroup.h>

@interface AIListOutlineView (AIListOutlineView_Drawing_Private)
- (void)windowBecameMain:(NSNotification *)notification;
- (void)windowResignedMain:(NSNotification *)notification;
@end

@implementation AIListOutlineView (AIListOutlineView_Drawing)

//Prevent the display of a focus ring around the contact list in 10.3 and greater
- (NSFocusRingType)focusRingType
{
    return NSFocusRingTypeNone;
}

#pragma mark Background image

/*!
 * @brief Draw our background image or color, with transparency as appropriate
 */
- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if ([self drawsBackground]) {
		//BG Color
		[[self backgroundColor] set];
		NSRectFill(clipRect);
		
		//Image
		NSScrollView	*enclosingScrollView = [self enclosingScrollView];
		if (backgroundImage && enclosingScrollView) {
			NSRect	visRect = [enclosingScrollView documentVisibleRect];
			NSSize	imageSize = [backgroundImage size];
			NSRect	imageRect = NSMakeRect(0.0f, 0.0f, imageSize.width, imageSize.height);
			CGFloat imageFade = backgroundFade * backgroundOpacity;
			
			switch (backgroundStyle) {
					
				case AINormalBackground: {
					//Background image normal
					[backgroundImage drawInRect:NSMakeRect(visRect.origin.x, visRect.origin.y, imageSize.width, imageSize.height)
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:imageFade];
					break;
				}
				case AIFillProportionatelyBackground: {
					//Background image proportional stretch
					
					/*
					 Alternately: Make the width change by the same proportion as the height will change
					 visRect.size.width = imageSize.width * (visRect.size.height / imageSize.height);
					 */
					
					//Make the height change by the same proportion as the width will change
					visRect.size.height = imageSize.height * (visRect.size.width / imageSize.width);
					
					//Background image stretch
					[backgroundImage drawInRect:visRect
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:imageFade];
					break;
				}
				case AIFillStretchBackground: {
					//Background image stretch
					[backgroundImage drawInRect:visRect
									   fromRect:imageRect
									  operation:NSCompositeSourceOver
									   fraction:imageFade];
					break;
				}
				case AITileBackground: {
					//Tiling
					NSPoint	currentOrigin;
					currentOrigin = visRect.origin;
					
					//We'll repeat this vertical process as long as necessary
					while (currentOrigin.y < (visRect.origin.y + visRect.size.height)) {
						//Reset the x axis to draw a series of images horizontally at this height
						currentOrigin.x = visRect.origin.x;
						
						//Draw as long as our origin is within the visible rect
						while (currentOrigin.x < (visRect.origin.x + visRect.size.width)) {
							NSRect drawingRect = NSMakeRect(currentOrigin.x, currentOrigin.y, imageSize.width, imageSize.height);
							if (NSIntersectsRect(drawingRect, clipRect)) {
								//Draw at the current x and y at least once with the original size
								[backgroundImage drawInRect:drawingRect
												   fromRect:imageRect
												  operation:NSCompositeSourceOver
												   fraction:imageFade];
							}
							
							//Shift right for the next iteration
							currentOrigin.x += imageSize.width;
						}
						
						//Shift down for the next series of horizontal draws
						currentOrigin.y += imageSize.height;
					}
					break;
				}
			}
		}
		
	} else {
		//If we aren't drawing a background, fill the rect with clearColor
		[[NSColor clearColor] set];
		NSRectFill(clipRect);
	}
	
	if([self conformsToProtocol:@protocol(AIAlternatingRowsProtocol)])
		[(id<AIAlternatingRowsProtocol>)self drawAlternatingRowsInRect:clipRect];
}

#pragma mark Background

- (void)setBackgroundImage:(NSImage *)inImage
{
	if (backgroundImage != inImage) {
		[backgroundImage release];
		backgroundImage = [inImage retain];		
		[backgroundImage setFlipped:YES];
	}
	
	[(NSClipView *)[self superview] setCopiesOnScroll:(!backgroundImage)];
	[self setNeedsDisplay:YES];
}

- (void)setBackgroundStyle:(AIBackgroundStyle)inBackgroundStyle
{
	backgroundStyle = inBackgroundStyle;
	[self setNeedsDisplay:YES];
}

- (void)setBackgroundOpacity:(CGFloat)opacity forWindowStyle:(AIContactListWindowStyle)inWindowStyle
{
	backgroundOpacity = opacity;
	
	//Reset all our opacity dependent values
	[_backgroundColorWithOpacity release]; _backgroundColorWithOpacity = nil;
	[_rowColorWithOpacity release]; _rowColorWithOpacity = nil;
	
	windowStyle = inWindowStyle;
	
	[self setNeedsDisplay:YES];
	
	/* This may be called repeatedly. We want to invalidate our shadow as our opacity changes, but we'll flicker
	 * if we do it immediately.
	 */
	[NSObject cancelPreviousPerformRequestsWithTarget:[self window]
											 selector:@selector(invalidateShadow)
											   object:nil];
	[[self window] performSelector:@selector(invalidateShadow)
	                    withObject:nil
	                    afterDelay:0.2];
}

- (void)setBackgroundFade:(CGFloat)fade
{
	backgroundFade = fade;
	[self setNeedsDisplay:YES];
}
- (CGFloat)backgroundFade
{
	//Factor in opacity
	return backgroundFade * backgroundOpacity;
}

//Background color (Opacity is added into the return automatically)
- (void)setBackgroundColor:(NSColor *)inColor
{
	if (backgroundColor != inColor) {
		[backgroundColor release];
		backgroundColor = [inColor retain];
		[_backgroundColorWithOpacity release];
		_backgroundColorWithOpacity = nil;
	}
	[self setNeedsDisplay:YES];
}
- (NSColor *)backgroundColor
{
	//Factor in opacity
	if (!_backgroundColorWithOpacity) { 
		CGFloat backgroundAlpha = ([backgroundColor alphaComponent] * backgroundOpacity);
		_backgroundColorWithOpacity = [[backgroundColor colorWithAlphaComponent:backgroundAlpha] retain];
		
		//Mockie and pillow lists always require a non-opaque window, other lists only require a non-opaque window when
		//the user has requested transparency.
		if (windowStyle == AIContactListWindowStyleGroupBubbles || windowStyle == AIContactListWindowStyleContactBubbles || windowStyle == AIContactListWindowStyleContactBubbles_Fitted) {
			[[self window] setOpaque:NO];
		} else {
			[[self window] setOpaque:(backgroundAlpha == 1.0f)];
		}
		
		//Turn our shadow drawing hack on if they're going to be visible through the transparency
		[self setUpdateShadowsWhileDrawing:(![[self window] isOpaque])];		
	}
	
	return _backgroundColorWithOpacity;
}

- (void)setDrawsBackground:(BOOL)inDraw
{
	[super setDrawsBackground:inDraw];
	
	//Mockie and pillow lists always require a non-opaque window, other lists only require a non-opaque window when
	//the user has requested transparency.
	if (windowStyle == AIContactListWindowStyleGroupBubbles || windowStyle == AIContactListWindowStyleContactBubbles || windowStyle == AIContactListWindowStyleContactBubbles_Fitted) {
		[[self window] setOpaque:NO];
	} else {
		//XXX Should we still use backgroundOpacity
		[[self window] setOpaque:(backgroundOpacity == 1.0)];
	}
}

- (void)setHighlightColor:(NSColor *)inColor
{
	if (highlightColor != inColor) {
		[self willChangeValueForKey:@"highlightColor"];
		[highlightColor release];
		highlightColor = [inColor retain];
		[self  didChangeValueForKey:@"highlightColor"];
	}
	[self setNeedsDisplay:YES];
}
- (NSColor *)highlightColor
{
	return highlightColor;
}

//Alternating row color (Opacity is added into the return automatically)
- (void)setAlternatingRowColor:(NSColor *)color
{
	if (rowColor != color) {
		[rowColor release];
		rowColor = [color retain];
		[_rowColorWithOpacity release];
		_rowColorWithOpacity = nil;
	}
	
	[self setNeedsDisplay:YES];
}

- (NSColor *)alternatingRowColor
{
	if (!_rowColorWithOpacity) {
		CGFloat rowAlpha = [rowColor alphaComponent];
		_rowColorWithOpacity = [[rowColor colorWithAlphaComponent:(rowAlpha * backgroundOpacity)] retain];
	}
	
	return _rowColorWithOpacity;
}

// Don't consider list groups when highlighting
- (BOOL)shouldResetAlternating:(int)row
{
	return ([[self itemAtRow:row] isKindOfClass:[AIListGroup class]] && groupsHaveBackground);
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	
	[(NSClipView *)newSuperview setCopiesOnScroll:(!backgroundImage)];
}

- (void)drawRect:(NSRect)rect
{	
	[super drawRect:rect];
	
	/*	#################### Crappy Code ###################
	 *	Mac OS X 10.0 through 10.5.2 (and possibly beyond) do NOT invalidate the shadow
	 *	of a transparent window correctly, forcing us to do it manually each
	 *	time the window content is changed.  This is absolutely horrible for
	 *	performance, but the only way to avoid shadow ghosting :(
	 */
	if (updateShadowsWhileDrawing) [[self window] invalidateShadow];
}

- (void)setUpdateShadowsWhileDrawing:(BOOL)update{
	updateShadowsWhileDrawing = update;
}

#pragma mark Drag & Drop Drawing
/* The drop highlight hackery below was heavily inspired by Cathy Shive's "Styling an NSTableView" sample code at http://katidev.com/blog/tag/nstableview/
 * which is distributed under the following license:
 *
 * Copyright (c) 2008 Cathy Shive
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this code to reuse the code without restriction, subject to the following conditions:
 * 
 * My name may not be used to endorse or promote products derived from this software without prior written permission from me.
 * 
 * THIS CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND. In other words, you agree not to sue me if anything goes wrong.
 */

/*!
 * @brief Called by NSOutineView to draw a drop highight
 *
 * Note: We are overriding a private method
 */
- (void)_drawDropHighlightOnRow:(int)rowIndex
{
	id item = [self itemAtRow:rowIndex];
	AIListCell *cell = [self cellForTableColumn:nil item:item];
	
	[self.delegate outlineView:self
	 willDisplayCell:cell 
	 forTableColumn:nil
	 item:item];
	
	[self lockFocus];
	[cell drawDropHighlightWithFrame:[self rectOfRow:rowIndex]];
	[self unlockFocus];
}

/*!
 * @brief Called in 10.5.
 * 
 * A default fill will be applied to drop highlights unless this is overridden to return clearColor
 */
+ (NSColor *)_dropHighlightBackgroundColor
{
	return [NSColor clearColor];
}


/*!
 * @brief Draw the line between two rows during a drag
 */
- (void)performDrawDropHighlightBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex atOffset:(float)theOffset
{	
	NSRect	aHighlightRect;
	CGFloat	aYPosition = 0;
	int		indentationLevelRow;
	
	if (theUpperRowIndex < 0) {
		//If the lower row index is the first row, get the rect of the lowerRowIndex and draw above it
		indentationLevelRow = theLowerRowIndex;
		aHighlightRect = [self rectOfRow:theLowerRowIndex];
		aYPosition = NSMinY(aHighlightRect);
		
	} else {
		//In all other cases draw below theUpperRowIndex. However, we'll be dropping at the indentation level of the one below.
		indentationLevelRow = theUpperRowIndex + 1;
		aHighlightRect = [self rectOfRow:theUpperRowIndex];
		aYPosition = NSMinY(aHighlightRect) + NSHeight(aHighlightRect);
	}
	
	
	id item = [self itemAtRow:indentationLevelRow];
	AIListCell *cell = [self cellForTableColumn:nil item:item];
	
	[self.delegate outlineView:self
	 willDisplayCell:cell 
	 forTableColumn:nil
	 item:item];
	
	switch ([cell textAlignment]) {
		case NSRightTextAlignment:
			//Right alignment indents on the right
			aHighlightRect.size.width -= [cell indentation];
			break;
		default:
			//All other alignments indent on the left
			aHighlightRect.origin.x += [cell indentation];
			aHighlightRect.size.width -= [cell indentation];
			break;
	}
	
	//Accent rect will be where we draw the little circle
	float	anAccentRectSize = 6;
	float	anAccentRectXOffset = 2;
	NSRect	anAccentRect = NSMakeRect(NSMinX(aHighlightRect) + anAccentRectXOffset,
									  aYPosition - anAccentRectSize*0.5f,
									  anAccentRectSize,
									  anAccentRectSize);
	
	//Make points to define the line starting after the accent circle, extending the width of the row
	NSPoint aStartPoint = NSMakePoint(NSMaxX(anAccentRect), aYPosition);
	NSPoint anEndPoint = NSMakePoint(NSMaxX(aHighlightRect) - NSWidth(anAccentRect), aYPosition);
	
	//Lock focus for drawing
	[self lockFocus];
	
	//Make a bezier path, add the circle and line
	NSBezierPath *aHighlightPath = [NSBezierPath bezierPath];
	[aHighlightPath appendBezierPathWithOvalInRect:anAccentRect];
	[aHighlightPath moveToPoint:aStartPoint];
	[aHighlightPath lineToPoint:anEndPoint];
	
	//Fill with white for the accent circle and stroke the path with black
	[[NSColor whiteColor] set];
	[aHighlightPath fill];
	[aHighlightPath setLineWidth:2.0f];
	[[NSColor blackColor] set];
	[aHighlightPath stroke];
	
	//Unlock focus
	[self unlockFocus];
}

/*!
 * @brief Private NSOutlineView method called in 10.5 to draw the line between rows during a drag&drop operation
 */
- (void)_drawDropHighlightBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex onRow:(int)theRow atOffset:(float)theOffset
{
	[self performDrawDropHighlightBetweenUpperRow:theUpperRowIndex
									  andLowerRow:theLowerRowIndex
										 atOffset:theOffset];
}

/*!
 * @brief Private NSOutlineView method called in 10.4 to draw the line between rows during a drag&drop operation
 */
- (void) _drawDropHighlightBetweenUpperRow:(int)theUpperRowIndex andLowerRow:(int)theLowerRowIndex atOffset:(float)theOffset
{
	[self performDrawDropHighlightBetweenUpperRow:theUpperRowIndex
									  andLowerRow:theLowerRowIndex
										 atOffset:theOffset];
}

#pragma mark Selection Hiding

//If our window isn't in the foreground, we're not displaying a selection.  So override this method to pass NO for
//selected in that situation
- (void)_drawRowInRect:(NSRect)rect colored:(BOOL)colored selected:(BOOL)selected
{
	if (![[self window] isKeyWindow]) selected = NO;
	[super _drawRowInRect:rect colored:colored selected:selected];
}

//When our view is inserted into a window, observe that window so we can hide selection when it's not main
- (void)configureSelectionHidingForNewSuperview:(NSView *)newSuperview
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:[self window]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:[self window]];
    if ([newSuperview window]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowBecameMain:) name:NSWindowDidBecomeMainNotification object:[newSuperview window]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResignedMain:) name:NSWindowDidResignMainNotification object:[newSuperview window]];
    }
}

//Redraw our cells so they can select or de-select
- (void)windowBecameMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}
- (void)windowResignedMain:(NSNotification *)notification{
	[self setNeedsDisplay:YES];
}

@end
