// JVMarkedScroller.m
// From Colloquy  (www.colloquy.info)

#import "JVMarkedScroller.h"
#import "AIStringUtilities.h"

struct _mark {
	unsigned long long location;
	NSString *identifier;
	NSColor *color;
};

@implementation JVMarkedScroller
- (id) initWithFrame:(NSRect) frame {
	if( ( self = [super initWithFrame:frame] ) ) {
		_marks = [[NSMutableSet set] retain];
		_shades = [[NSMutableArray array] retain];
		_nearestPreviousMark = NSNotFound;
		_nearestNextMark = NSNotFound;
		_currentMark = NSNotFound;
	}
	return self;
}

- (void) dealloc {
	[_marks release];
	[_shades release];
	
	_marks = nil;
	_shades = nil;
	
	[super dealloc];
}

#pragma mark -

- (void) drawRect:(NSRect) rect {
	[super drawRect:rect];
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	CGFloat width = [[self class] scrollerWidthForControlSize:[self controlSize]];
	
	CGFloat scale = [self scaleToContentView];
	[transform scaleXBy:( sFlags.isHoriz ? scale : 1. ) yBy:( sFlags.isHoriz ? 1. : scale )];
	
	CGFloat offset = [self rectForPart:NSScrollerKnobSlot].origin.y;
	[transform translateXBy:( sFlags.isHoriz ? offset / scale : 0. ) yBy:( sFlags.isHoriz ? 0. : offset / scale )];
	
	NSBezierPath *shades = [NSBezierPath bezierPath];
	NSEnumerator *enumerator = [_shades objectEnumerator];
	NSNumber *startNum = nil;
	NSNumber *stopNum = nil;
	
	while( ( startNum = [enumerator nextObject] ) && ( stopNum = [enumerator nextObject] ) ) {
		unsigned long long start = [startNum unsignedLongLongValue];
		unsigned long long stop = [stopNum unsignedLongLongValue];
		
		NSRect rect = NSZeroRect;
		if( sFlags.isHoriz ) rect = NSMakeRect( start, 0., ( stop - start ), width );
		else rect = NSMakeRect( 0., start, width, ( stop - start ) );
		
		rect.origin = [transform transformPoint:rect.origin];
		rect.size = [transform transformSize:rect.size];
		
		[shades appendBezierPathWithRect:rect];
	}
	
	if( ( [_shades count] % 2 ) == 1 ) {
		NSRect rect = NSZeroRect;
		unsigned long long start = [[_shades lastObject] unsignedLongLongValue];
		unsigned long long stop = [self contentViewLength];
		
		if( sFlags.isHoriz ) rect = NSMakeRect( start, 0., ( stop - start ), width );
		else rect = NSMakeRect( 0., start, width, ( stop - start ) );
		
		rect.origin = [transform transformPoint:rect.origin];
		rect.size = [transform transformSize:rect.size];
		
		[shades appendBezierPathWithRect:NSIntegralRect( rect )];
	}
	
	NSRectClip( NSInsetRect( [self rectForPart:NSScrollerKnobSlot], ( sFlags.isHoriz ? 4. : 3. ), ( sFlags.isHoriz ? 3. : 4. ) ) );
	
	if( ! [shades isEmpty ] ) {
		[[[NSColor knobColor] colorWithAlphaComponent:0.45] set];
		[shades fill];
	}
	
	NSBezierPath *lines = [NSBezierPath bezierPath];
	NSMutableArray *lineArray = [NSMutableArray array];
	enumerator = [_marks objectEnumerator];
	NSValue *currentMark = nil;
	
	unsigned long long currentPosition = ( _currentMark != NSNotFound ? _currentMark : (CGFloat)[self floatValue] * [self contentViewLength] );
	BOOL foundNext = NO, foundPrevious = NO;
	NSRect knobRect = [self rectForPart:NSScrollerKnob];
	
	while( ( currentMark = [enumerator nextObject] ) ) {
		struct _mark mark;
		[currentMark getValue:&mark];
		unsigned long long value = mark.location;
		
		if( value < currentPosition && ( ! foundPrevious || value > _nearestPreviousMark ) ) {
			_nearestPreviousMark = value;
			foundPrevious = YES;
		}
		
		if( value > currentPosition && ( ! foundNext || value < _nearestNextMark ) ) {
			_nearestNextMark = value;
			foundNext = YES;
		}
		
		NSPoint point = NSMakePoint( ( sFlags.isHoriz ? value : 0. ), ( sFlags.isHoriz ? 0. : value ) );
		point = [transform transformPoint:point];
		point.x = ( sFlags.isHoriz ? round( point.x ) + 0.5 : point.x );
		point.y = ( sFlags.isHoriz ? point.y : round( point.y ) + 0.5 );
		
		if( ! NSPointInRect( point, knobRect ) ) {
			if( mark.color ) {
				NSBezierPath *line = [NSBezierPath bezierPath];
				[line moveToPoint:point];
				
				point = NSMakePoint( ( sFlags.isHoriz ? 0. : width ), ( sFlags.isHoriz ? width : 0. ) );
				[line relativeLineToPoint:point];
				[lineArray addObject:mark.color];
				[lineArray addObject:line];
			} else {
				[lines moveToPoint:point];
				
				point = NSMakePoint( ( sFlags.isHoriz ? 0. : width ), ( sFlags.isHoriz ? width : 0. ) );
				[lines relativeLineToPoint:point];
			}
		}
	}
	
	if( ! foundPrevious ) _nearestPreviousMark = NSNotFound;
	if( ! foundNext ) _nearestNextMark = NSNotFound;
	
	if( ! [lines isEmpty] ) {
		[[NSColor selectedKnobColor] set];
		[lines stroke];
	}
	
	// This is so we can draw the colored lines after the regular lines
	enumerator = [lineArray objectEnumerator];
	NSColor *lineColor = nil;
	while( ( lineColor = [enumerator nextObject] ) ) {
		[lineColor set];
		[[enumerator nextObject] stroke];
	}
	
	if( ! [shades isEmpty] )
		[self drawKnob];
}

- (void) setFloatValue:(float) position
{
	if( ! _jumpingToMark ) _currentMark = NSNotFound;
	if( ( [self floatValue] != position) && ( [_marks count] || [_shades count] ) )
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	[super setFloatValue:position];
}

- (void) setKnobProportion:(CGFloat)percent 
{
	if( ! _jumpingToMark ) _currentMark = NSNotFound;
	if(([self knobProportion] != percent ) && ( [_marks count] || [_shades count] ) )
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	[super setKnobProportion:percent];
}

- (NSMenu *) menuForEvent:(NSEvent *) event {
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSMenuItem *item = nil;
	
	item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Clear All Marks", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "clear all marks contextual menu item title" ) 
									   action:@selector( removeAllMarks ) 
								keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[menu addItem:item];
	
	if( sFlags.isHoriz ) {
		item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Clear Marks from Here Left", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "clear marks from here left contextual menu") 
										   action:@selector( clearMarksHereLess: ) 
									keyEquivalent:@""] autorelease];
		[item setTarget:self];
		[menu addItem:item];
		
		item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Clear Marks from Here Right", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "clear marks from here right contextual menu") 
										   action:@selector( clearMarksHereGreater: ) keyEquivalent:@""] 
				autorelease];
		[item setTarget:self];
		[menu addItem:item];
	} else {
		item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Clear Marks from Here Up", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "clear marks from here up contextual menu") 
										   action:@selector( clearMarksHereLess: ) 
									keyEquivalent:@""] autorelease];
		[item setTarget:self];
		[menu addItem:item];
		
		item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Clear Marks from Here Down", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "clear marks from here up contextual menu") 
										   action:@selector( clearMarksHereGreater: ) 
									keyEquivalent:@""] autorelease];
		[item setTarget:self];
		[menu addItem:item];
	}
	
	[menu addItem:[NSMenuItem separatorItem]];
	
	item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Jump to Previous Mark", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "jump to previous mark contextual menu") 
									   action:@selector( jumpToPreviousMark: ) 
								keyEquivalent:@"["] autorelease];
	[item setTarget:self];
	[item setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
	[menu addItem:item];
	
	item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Jump to Next Mark", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "jump to next mark contextual menu")
									   action:@selector( jumpToNextMark: )
								keyEquivalent:@"]"] autorelease];
	[item setTarget:self];
	[item setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
	[menu addItem:item];
	
	item = [[[NSMenuItem alloc] initWithTitle:AILocalizedStringFromTableInBundle( @"Jump to Focus Mark", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "jump to the mark where the last content the user saw ends")
									   action:@selector( jumpToFocusMark: ) 
								keyEquivalent:@""] autorelease];
	[item setTarget:self];
	[menu addItem:item];	
	
	return menu;
}

#pragma mark -

- (void) updateNextAndPreviousMarks {
	NSEnumerator *enumerator = [_marks objectEnumerator];
	NSValue *currentMark = nil;
	
	unsigned long long currentPosition = ( _currentMark != NSNotFound ? _currentMark : (CGFloat)[self floatValue] * [self contentViewLength] );
	BOOL foundNext = NO, foundPrevious = NO;
	
	while( ( currentMark = [enumerator nextObject] ) ) {
		struct _mark mark;
		[currentMark getValue:&mark];
		unsigned long long value = mark.location;
		
		if( value < currentPosition && ( ! foundPrevious || value > _nearestPreviousMark ) ) {
			_nearestPreviousMark = value;
			foundPrevious = YES;
		}
		
		if( value > currentPosition && ( ! foundNext || value < _nearestNextMark ) ) {
			_nearestNextMark = value;
			foundNext = YES;
		}
	}
	
	if( ! foundPrevious ) _nearestPreviousMark = NSNotFound;
	if( ! foundNext ) _nearestNextMark = NSNotFound;
}

#pragma mark -

- (IBAction) clearMarksHereLess:(id) sender {
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	NSPoint where = [self convertPoint:[event locationInWindow] fromView:nil];
	NSRect slotRect = [self rectForPart:NSScrollerKnobSlot];
	CGFloat scale = [self scaleToContentView];
	[self removeMarksLessThan:( ( sFlags.isHoriz ? where.x - NSMinX( slotRect ) : where.y - NSMinY( slotRect ) ) / scale )];
}

- (IBAction) clearMarksHereGreater:(id) sender {
	NSEvent *event = [[NSApplication sharedApplication] currentEvent];
	NSPoint where = [self convertPoint:[event locationInWindow] fromView:nil];
	NSRect slotRect = [self rectForPart:NSScrollerKnobSlot];
	CGFloat scale = [self scaleToContentView];
	[self removeMarksGreaterThan:( ( sFlags.isHoriz ? where.x - NSMinX( slotRect ) : where.y - NSMinY( slotRect ) ) / scale )];
}

#pragma mark -

- (void) setLocationOfCurrentMark:(unsigned long long) location {
	if( _currentMark != location ) {
		_currentMark = location;
		[self updateNextAndPreviousMarks];
	}
}

- (unsigned long long) locationOfCurrentMark {
	return _currentMark;
}

#pragma mark -

- (BOOL)previousMarkExists
{
	return _nearestPreviousMark != NSNotFound;
}

- (IBAction) jumpToPreviousMark:(id) sender {
	if( _nearestPreviousMark != NSNotFound ) {
		_currentMark = _nearestPreviousMark;
		_jumpingToMark = YES;
		CGFloat shift = [self shiftAmountToCenterAlign];
		[[(NSScrollView *)[self superview] documentView] scrollPoint:NSMakePoint( 0., _currentMark - shift )];
		_jumpingToMark = NO;
		
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	}
}

- (BOOL)nextMarkExists
{
	return _nearestNextMark != NSNotFound;
}

- (IBAction) jumpToNextMark:(id) sender {
	if( _nearestNextMark != NSNotFound ) {
		_currentMark = _nearestNextMark;
		_jumpingToMark = YES;
		CGFloat shift = [self shiftAmountToCenterAlign];
		[[(NSScrollView *)[self superview] documentView] scrollPoint:NSMakePoint( 0., _currentMark - shift )];
		_jumpingToMark = NO;
		
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	}
}

- (BOOL)focusMarkExists
{
	NSEnumerator *e = [_marks objectEnumerator];
	NSValue *obj = nil;
	BOOL foundMark = NO;
	
	while( ( obj = [e nextObject] ) ) {
		struct _mark mark;
		[obj getValue:&mark];
		if( [mark.identifier isEqualToString:@"focus"] ) {
			_currentMark = mark.location;
			foundMark = YES;
			break;
		}
	}
	
	return foundMark;
}

- (IBAction)jumpToFocusMark:(id)sender
{
	[self jumpToMarkWithIdentifier:@"focus"];
}

- (void) jumpToMarkWithIdentifier:(NSString *) identifier {
	_jumpingToMark = YES;
	
	NSEnumerator *e = [_marks objectEnumerator];
	NSValue *obj = nil;
	BOOL foundMark = NO;
	
	while( ( obj = [e nextObject] ) ) {
		struct _mark mark;
		[obj getValue:&mark];
		if( [mark.identifier isEqualToString:identifier] ) {
			_currentMark = mark.location;
			foundMark = YES;
			break;
		}
	}
	
	if( foundMark ) {
		CGFloat shift = [self shiftAmountToCenterAlign];
		[[(NSScrollView *)[self superview] documentView] scrollPoint:NSMakePoint( 0., _currentMark - shift )];
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	}
	
	_jumpingToMark = NO;
}

#pragma mark -

- (void) shiftMarksAndShadedAreasBy:(long long) displacement {
	BOOL negative = ( displacement >= 0 ? NO : YES );
	NSMutableSet *shiftedMarks = [NSMutableSet set];
	NSValue *location = nil;
	
	if( ! ( negative && _nearestPreviousMark < ABS( displacement ) ) ) _nearestPreviousMark += displacement;
	else _nearestPreviousMark = NSNotFound;
	
	if( ! ( negative && _nearestNextMark < ABS( displacement ) ) ) _nearestNextMark += displacement;
	else _nearestNextMark = NSNotFound;
	
	if( ! ( negative && _currentMark < ABS( displacement ) ) ) _currentMark += displacement;
	else _currentMark = NSNotFound;
	
	NSEnumerator *enumerator = [_marks objectEnumerator];
	while( ( location = [enumerator nextObject] ) ) {
		struct _mark mark;
		[location getValue:&mark];
		if( ! ( negative && mark.location < ABS( displacement ) ) ) {
			mark.location += displacement;
			[shiftedMarks addObject:[NSValue value:&mark withObjCType:@encode( struct _mark )]];
		}
	}
	
	[_marks setSet:shiftedMarks];
	
	NSMutableArray *shiftedShades = [NSMutableArray array];
	NSNumber *start = nil;
	NSNumber *stop = nil;
	
	enumerator = [_shades objectEnumerator];
	while( ( start = [enumerator nextObject] ) && ( ( stop = [enumerator nextObject] ) || YES ) ) {
		unsigned long long shiftedStart = [start unsignedLongLongValue];
		
		if( stop ) {
			unsigned long long shiftedStop = [stop unsignedLongLongValue];
			if( ! ( negative && shiftedStart < ABS( displacement ) ) && ! ( negative && shiftedStop < ABS( displacement ) ) ) {
				[shiftedShades addObject:[NSNumber numberWithUnsignedLongLong:( shiftedStart + displacement )]];
				[shiftedShades addObject:[NSNumber numberWithUnsignedLongLong:( shiftedStop + displacement )]];
			}
		} else if( ! ( negative && shiftedStart < ABS( displacement ) ) ) {
			[shiftedShades addObject:[NSNumber numberWithUnsignedLongLong:( shiftedStart + displacement )]];
		}
	}
	
	[_shades setArray:shiftedShades];
	
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

#pragma mark -

- (void) addMarkAt:(unsigned long long) location {
	[self addMarkAt:location withIdentifier:nil withColor:nil];
}

- (void) addMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier {
	[self addMarkAt:location withIdentifier:identifier withColor:nil];
}

- (void) addMarkAt:(unsigned long long) location withColor:(NSColor *) color {
	[self addMarkAt:location withIdentifier:nil withColor:color];
}

- (void) addMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier withColor:(NSColor *) color {
	struct _mark mark = {location, identifier, color};
	[_marks addObject:[NSValue value:&mark withObjCType:@encode( struct _mark )]];
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) removeMarkAt:(unsigned long long) location {
	[self removeMarkAt:location withIdentifier:nil withColor:nil];
}

- (void) removeMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier {
	[self removeMarkAt:location withIdentifier:identifier withColor:nil];
}

- (void) removeMarkAt:(unsigned long long) location withColor:(NSColor *) color {
	[self removeMarkAt:location withIdentifier:nil withColor:color];
}

- (void) removeMarkAt:(unsigned long long) location withIdentifier:(NSString *) identifier withColor:(NSColor *) color {
	struct _mark mark = {location, identifier, color};
	[_marks removeObject:[NSValue value:&mark withObjCType:@encode( struct _mark )]];
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) removeMarkWithIdentifier:(NSString *) identifier {
	NSEnumerator *e = [[[_marks copy] autorelease] objectEnumerator];
	NSValue *obj = nil;
	while( ( obj = [e nextObject] ) ) {
		struct _mark mark;
		[obj getValue:&mark];
		if( [mark.identifier isEqualToString:identifier] ) {
			[_marks removeObject:obj];
		}
	}
	
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) removeMarksGreaterThan:(unsigned long long) location {
	NSEnumerator *enumerator = [[[_marks copy] autorelease] objectEnumerator];
	NSValue *obj = nil;
	
	while( ( obj = [enumerator nextObject] ) ) {
		struct _mark mark;
		[obj getValue:&mark];
		if( mark.location > location )
			[_marks removeObject:obj];
	}
	
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) removeMarksLessThan:(unsigned long long) location {
	NSEnumerator *enumerator = [[[_marks copy] autorelease] objectEnumerator];
	NSValue *obj = nil;
	
	while( ( obj = [enumerator nextObject] ) ) {
		struct _mark mark;
		[obj getValue:&mark];
		if( mark.location < location )
			[_marks removeObject:obj];
	}
	
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) removeMarksInRange:(NSRange) range {
	NSEnumerator *enumerator = [[[_marks copy] autorelease] objectEnumerator];
	NSValue *obj = nil;
	
	while( ( obj = [enumerator nextObject] ) ) {
		struct _mark mark;
		[obj getValue:&mark];
		if( NSLocationInRange( (unsigned int)mark.location, range ) )
			[_marks removeObject:obj];
	}
	
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) removeAllMarks {
	[_marks removeAllObjects];
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

#pragma mark -

- (void) setMarks:(NSSet *) marks {
	[_marks setSet:marks];
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (NSSet *) marks {
	return _marks;
}

#pragma mark -

- (void) startShadedAreaAt:(unsigned long long) location {
	if( ! [_shades count] || ! ( [_shades count] % 2 ) ) {
		[_shades addObject:[NSNumber numberWithUnsignedLongLong:location]];
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	}
}

- (void) stopShadedAreaAt:(unsigned long long) location {
	if( [_shades count] && ( [_shades count] % 2 ) == 1 ) {
		[_shades addObject:[NSNumber numberWithUnsignedLongLong:location]];
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
	}
}

#pragma mark -

- (void) removeAllShadedAreas {
	[_shades removeAllObjects];
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

#pragma mark -

- (unsigned long long) contentViewLength {
	if( sFlags.isHoriz ) return ( NSWidth( [self frame] ) / [self knobProportion] );
	else return ( NSHeight( [self frame] ) / [self knobProportion] );
}

- (CGFloat) scaleToContentView {
	if( sFlags.isHoriz ) return NSWidth( [self rectForPart:NSScrollerKnobSlot] ) / NSWidth( [[(NSScrollView *)[self superview] contentView] documentRect] );
	else return NSHeight( [self rectForPart:NSScrollerKnobSlot] ) / NSHeight( [[(NSScrollView *)[self superview] contentView] documentRect] );
}

- (CGFloat) shiftAmountToCenterAlign {
	CGFloat scale = [self scaleToContentView];
	if( sFlags.isHoriz ) return ( ( NSWidth( [self rectForPart:NSScrollerKnobSlot] ) * [self knobProportion] ) / 2. ) / scale;
	else return ( ( NSHeight( [self rectForPart:NSScrollerKnobSlot] ) * [self knobProportion] ) / 2. ) / scale;
}
@end
