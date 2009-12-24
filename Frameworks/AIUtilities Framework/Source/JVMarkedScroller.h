// JVMarkedScroller.h
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
