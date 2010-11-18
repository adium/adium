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

#import "AIEmoticonPack.h"
#import "AIEmoticonPackPreviewView.h"
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <Adium/AIEmoticon.h>

//Max size + bottom margin should equal previewView's height
#define EMOTICON_MAX_SIZE           20
#define EMOTICON_SPACING            4

#define EMOTICON_LEFT_MARGIN        2		//Left padding of cell
#define EMOTICON_BOTTOM_MARGIN      2

static  CGFloat   distanceBetweenEmoticons = 0;

@implementation AIEmoticonPackPreviewView

- (void)setEmoticonPack:(AIEmoticonPack *)inEmoticonPack
{
	emoticonPack = [inEmoticonPack retain];
}

- (void)dealloc
{
	[emoticonPack release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	NSRect	cellFrame = [view_preview frame];
	NSRect	nameFrame = [view_name frame];
	
	[super drawRect:rect];
	
	if (NSIntersectsRect(rect,nameFrame)) {
		//Display the title, truncating as necessary
		NSMutableParagraphStyle	*paragraphStyle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																				lineBreakMode:NSLineBreakByTruncatingTail];
		[paragraphStyle setMaximumLineHeight:nameFrame.size.height];

		[[emoticonPack name] drawInRect:nameFrame
						 withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
							 paragraphStyle, NSParagraphStyleAttributeName,
							 [NSFont systemFontOfSize:12], NSFontAttributeName/*, 
							 SELECTED_TEXT_COLOR, NSForegroundColorAttributeName*/, nil]];
	}

	if (NSIntersectsRect(rect,cellFrame)) {		
		NSEnumerator    *enumerator;
		AIEmoticon      *emoticon;
		CGFloat			x = 0;

		//Display a few preview emoticons
		enumerator = [[emoticonPack emoticons] objectEnumerator];
		while ((x < cellFrame.size.width) && (emoticon = [enumerator nextObject])) {
			NSImage *image = [emoticon image];
			NSSize  imageSize = [image size];
			NSRect  destRect;
			
			//Scale the emoticon, preserving its proportions.
			if (imageSize.width > EMOTICON_MAX_SIZE) {
				destRect.size.width = EMOTICON_MAX_SIZE;
				destRect.size.height = imageSize.height * (EMOTICON_MAX_SIZE / imageSize.width);
			} else if (imageSize.height > EMOTICON_MAX_SIZE) {
				destRect.size.width = imageSize.width * (EMOTICON_MAX_SIZE / imageSize.height);
				destRect.size.height = EMOTICON_MAX_SIZE;
			} else {
				destRect.size.width = imageSize.width;
				destRect.size.height = imageSize.height;            
			}
			
			//Position it
			destRect.origin.x = cellFrame.origin.x + x;
			destRect.origin.y = cellFrame.origin.y + EMOTICON_BOTTOM_MARGIN;

			//If there is enough room, draw the image
			if ((destRect.origin.x + destRect.size.width) < (cellFrame.origin.x + cellFrame.size.width)) {
				[image drawInRect:destRect
						 fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
						operation:NSCompositeSourceOver
						 fraction:1.0f];
			}
			
			//Move over for the next emoticon, leaving some space
			CGFloat desiredIncrease = destRect.size.width + EMOTICON_SPACING;
			if (distanceBetweenEmoticons < desiredIncrease)
				distanceBetweenEmoticons = desiredIncrease;
			x += distanceBetweenEmoticons;
		}
	}
}

@end
