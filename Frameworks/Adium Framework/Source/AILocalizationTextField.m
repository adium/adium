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

#import <Adium/AILocalizationTextField.h>

#define	TARGET_CONTROL	super

@implementation AILocalizationTextField

//Set up our defaults
- (void)_initLocalizationControl
{
	rightAnchorMovementType = AILOCALIZATION_MOVE_ANCHOR;
}

- (void)setStringValue:(NSString *)inStringValue
{
	NSRect			oldFrame;
	
	//If the old frame is smaller than our original frame, treat the old frame as that original frame
	//for resizing and positioning purposes
	oldFrame  = [self frame];
	if (oldFrame.size.width < originalFrame.size.width) {
		oldFrame = originalFrame;
	}
	
	//Set to inStringValue, then sizeToFit
	[super setStringValue:inStringValue];
	
	[self _handleSizingWithOldFrame:oldFrame stringValue:inStringValue];
}

- (NSControl *)viewForSizing
{
	return (NSTextField *)self;
}

- (id)initWithFrame:(NSRect)inFrame
{
	if ((self = [super initWithFrame:inFrame])) {
		originalFrame = inFrame;
		[self _initLocalizationControl];
	}
	
	return self;
}

#import "AILocalizationControl.m"

- (void)setFrame:(NSRect)inFrame
{
	originalFrame = inFrame;
	
	[super setFrame:inFrame];
}

@end

@implementation NSTextField (AILocalizationAssistance)
- (void)setLocalizedString:(NSString *)inString
{
	if ([self isKindOfClass:[AILocalizationTextField class]]) {
		[self setStringValue:inString];
	}
}
@end
