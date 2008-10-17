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

#import "AIListThemePreviewCell.h"
#import "AIListThemeWindowController.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIGradientAdditions.h>
#import <Adium/AIAbstractListController.h>

@implementation AIListThemePreviewCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListThemePreviewCell *newCell = [super copyWithZone:zone];
	
	newCell->themeDict = nil;
	[newCell setThemeDict:themeDict];
	
	newCell->colorKeyArray = [colorKeyArray retain];
	
	return newCell;
}

- (id)init
{
	if ((self = [super init]))
	{
		themeDict = nil;
		colorKeyArray = [[NSArray arrayWithObjects:
			KEY_LABEL_AWAY_COLOR,
			KEY_LABEL_IDLE_COLOR,
			KEY_LABEL_TYPING_COLOR,
			KEY_LABEL_SIGNED_OFF_COLOR,
			KEY_LABEL_SIGNED_ON_COLOR,
			KEY_LABEL_UNVIEWED_COLOR,
			KEY_LABEL_ONLINE_COLOR,
			KEY_LABEL_IDLE_AWAY_COLOR,
			KEY_LABEL_OFFLINE_COLOR,
			
			KEY_AWAY_COLOR,
			KEY_IDLE_COLOR,
			KEY_TYPING_COLOR,
			KEY_SIGNED_OFF_COLOR,
			KEY_SIGNED_ON_COLOR,
			KEY_UNVIEWED_COLOR,
			KEY_ONLINE_COLOR,
			KEY_IDLE_AWAY_COLOR,
			KEY_OFFLINE_COLOR,
			
			KEY_LIST_THEME_BACKGROUND_COLOR,
			KEY_LIST_THEME_GRID_COLOR,
			
			KEY_LIST_THEME_GROUP_BACKGROUND,
			KEY_LIST_THEME_GROUP_BACKGROUND_GRADIENT,
			nil] retain];
	}
			
	return self;
}

- (void)dealloc
{
	[themeDict release];
	[colorKeyArray release];
	[super dealloc];
}

- (void)setThemeDict:(NSDictionary *)inDict
{
	if (inDict != themeDict) {
		[themeDict release];
		themeDict = [inDict retain];
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	cellFrame.origin.y += 2;
	cellFrame.size.height -= 4;
	
	NSString		*key;
	NSRect			segmentRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y,
											 (cellFrame.size.width / [colorKeyArray count]), cellFrame.size.height);
	
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:cellFrame];
	
	for (key in colorKeyArray) {
		[[[themeDict objectForKey:key] representedColor] set];
		[NSBezierPath fillRect:segmentRect];
		segmentRect.origin.x += segmentRect.size.width;
	}

	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:NSOffsetRect(cellFrame, .5, .5)];
	
}

//Draw with the selected-control colours.
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	//Draw the gradient
	NSGradient *gradient = [NSGradient selectedControlGradient];
	[gradient drawInRect:cellFrame angle:90.0];
	
	//Draw a line at the light side, to make it look a lot cleaner
	cellFrame.size.height = 1;
	[[NSColor alternateSelectedControlColor] set];
	NSRectFillUsingOperation(cellFrame,NSCompositeSourceOver);
}

@end
