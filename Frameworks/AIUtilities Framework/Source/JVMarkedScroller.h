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
// From Colloquy  (www.colloquy.info)

@interface JVMarkedScroller : NSScroller {
	NSMutableSet *_marks;
	NSMutableArray *_shades;
	NSUInteger _nearestPreviousMark;
	NSUInteger _nearestNextMark;
	NSUInteger _currentMark;
	BOOL _jumpingToMark;
}
- (void) setLocationOfCurrentMark:(NSUInteger) location;
- (unsigned long long) locationOfCurrentMark;

- (BOOL)previousMarkExists;
- (IBAction) jumpToPreviousMark:(id) sender;

- (BOOL)nextMarkExists;
- (IBAction) jumpToNextMark:(id) sender;

- (BOOL)focusMarkExists;
- (IBAction)jumpToFocusMark:(id)sender;

- (void) jumpToMarkWithIdentifier:(NSString *) identifier;

- (void) shiftMarksAndShadedAreasBy:(NSInteger) displacement;

- (void) addMarkAt:(NSUInteger) location;
- (void) addMarkAt:(NSUInteger) location withIdentifier:(NSString *) identifier;
- (void) addMarkAt:(NSUInteger) location withColor:(NSColor *) color;
- (void) addMarkAt:(NSUInteger) location withIdentifier:(NSString *) identifier withColor:(NSColor *) color;

- (void) removeMarkAt:(NSUInteger) location;
- (void) removeMarkAt:(NSUInteger) location withIdentifier:(NSString *) identifier;
- (void) removeMarkAt:(NSUInteger) location withColor:(NSColor *) color;
- (void) removeMarkAt:(NSUInteger) location withIdentifier:(NSString *) identifier withColor:(NSColor *) color;
- (void) removeMarkWithIdentifier:(NSString *) identifier;
- (void) removeMarksGreaterThan:(NSUInteger) location;
- (void) removeMarksLessThan:(NSUInteger) location;
- (void) removeMarksInRange:(NSRange) range;
- (void) removeAllMarks;

- (void) setMarks:(NSSet *) marks;
- (NSSet *) marks;

- (void) startShadedAreaAt:(NSUInteger) location;
- (void) stopShadedAreaAt:(NSUInteger) location;

- (void) removeAllShadedAreas;

- (CGFloat) contentViewLength;
- (CGFloat) scaleToContentView;
- (CGFloat) shiftAmountToCenterAlign;
@end
