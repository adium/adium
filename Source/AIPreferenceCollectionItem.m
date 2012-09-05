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

#import "AIPreferenceCollectionItem.h"

@implementation AIPreferenceCollectionItem
@synthesize image = _image;

- (NSImage *)image
{
	return (self.isSelected && darkIcon ? darkIcon : [self.representedObject paneIcon]);
}

- (void)setSelected:(BOOL)flag
{
	BOOL old = self.isSelected;
	[super setSelected:flag];
	
	//Create the dark icon if it doesn't exist
	if (flag && !darkIcon) {
		NSImage *image = [self.representedObject paneIcon];
		if (!image)
			return;
		
		NSRect imgRect = NSZeroRect;
		imgRect.size = [image size];
		
		darkIcon = [[NSImage alloc] initWithSize:[image size]];
		[darkIcon lockFocus];
		[image drawInRect:imgRect
				 fromRect:imgRect
				operation:NSCompositeSourceOver
				 fraction:1];
		[[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.5] set];
		NSRectFillUsingOperation(imgRect, NSCompositeSourceAtop);
		[darkIcon unlockFocus];
	}
	
	if (flag != old)
		self.image = nil;
}

@end
