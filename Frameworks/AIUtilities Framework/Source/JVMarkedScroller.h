// JVMarkedScroller.h
// From Colloquy  (www.colloquy.info)

@interface JVMarkedScroller : NSScroller {
	NSMutableSet *_marks;
	NSMutableArray *_shades;
	unsigned long long _nearestPreviousMark;
	unsigned long long _nearestNextMark;
	unsigned long long _currentMark;
	BOOL _jumpingToMark;
}
- (void) setLocationOfCurrentMark:(unsigned long long) location;
- (unsigned long long) locationOfCurrentMark;

- (BOOL)previousMarkExists;
- (IBAction) jumpToPreviousMark:(id) sender;

- (BOOL)nextMarkExists;
- (IBAction) jumpToNextMark:(id) sender;

- (BOOL)focusMarkExists;
- (IBAction)jumpToFocusMark:(id)sender;

- (void) jumpToMarkWithIdentifier:(NSString *) identifier;

- (void) shiftMarksAndShadedAreasBy:(long long) displacement;

- (void) addMarkAt:(unsigned long long) location;
- (void) addMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier;
- (void) addMarkAt:(unsigned long long) location withColor:(NSColor *) color;
- (void) addMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier withColor:(NSColor *) color;

- (void) removeMarkAt:(unsigned long long) location;
- (void) removeMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier;
- (void) removeMarkAt:(unsigned long long) location withColor:(NSColor *) color;
- (void) removeMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier withColor:(NSColor *) color;
- (void) removeMarkWithIdentifier:(NSString *) identifier;
- (void) removeMarksGreaterThan:(unsigned long long) location;
- (void) removeMarksLessThan:(unsigned long long) location;
- (void) removeMarksInRange:(NSRange) range;
- (void) removeAllMarks;

- (void) setMarks:(NSSet *) marks;
- (NSSet *) marks;

- (void) startShadedAreaAt:(unsigned long long) location;
- (void) stopShadedAreaAt:(unsigned long long) location;

- (void) removeAllShadedAreas;

- (unsigned long long) contentViewLength;
- (float) scaleToContentView;
- (float) shiftAmountToCenterAlign;
@end
