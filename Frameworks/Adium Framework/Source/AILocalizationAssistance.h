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

typedef enum {
	AILOCALIZATION_MOVE_SELF = 0,
	AILOCALIZATION_MOVE_ANCHOR
} AILocalizationAnchorMovementType;

@interface NSObject (PRIVATE_AILocalizationControls)
- (void)_resizeWindow:(NSWindow *)inWindow leftBy:(float)difference;
- (void)_resizeWindow:(NSWindow *)inWindow rightBy:(float)difference;
- (void)setRightAnchorMovementType:(AILocalizationAnchorMovementType)inType;
- (void)_handleSizingWithOldFrame:(NSRect)oldFrame stringValue:(NSString *)inStringValue;
- (NSControl *)viewForSizing;
@end

#import <Adium/AILocalizationButton.h>
#import <Adium/AILocalizationButtonCell.h>
#import <Adium/AILocalizationTextField.h>
