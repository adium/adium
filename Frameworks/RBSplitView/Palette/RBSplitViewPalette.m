//
//  RBSplitViewPalette.m version 1.1.4
//  RBSplitView
//
//  Created by Rainer Brockerhoff on 24/09/2004.
//  Copyright 2004-2006 Rainer Brockerhoff.
//	Some Rights Reserved under the Creative Commons Attribution License, version 2.5, and/or the MIT License.
//

#import "RBSplitViewPalette.h"
#import "RBSplitViewPrivateDefines.h"

// Please don't remove this copyright notice!
static const unsigned char RBSplitViewPalette_Copyright[] __attribute__ ((used)) =
	"RBSplitViewPalette 1.1.4 Copyright(c)2004-2006 by Rainer Brockerhoff <rainer@brockerhoff.net>.";

// Main palette class...
// Writing a palette for a complex container view is insufficiently documented. Still, this works
// mostly as expected.

// These globals will always point to the 8x8 and 9x9 thumb images.
static NSImage* thumb8 = nil;
static NSImage* thumb9 = nil;

@implementation RBSplitViewPalette

// Release the palette image when going away.
- (void)dealloc {
	[thumb8 release];
	thumb8 = nil;
	[thumb9 release];
	thumb9 = nil;
	[splitView release];
	[super dealloc];
}

// Called when the palette is loaded
- (void)finishInstantiate {
// Creates a RBSplitView with the same size as the sample image and two subviews.
	NSRect bounds = [splitImage bounds];
	splitView = [[RBSplitView alloc] initWithFrame:bounds andSubviews:2];
// Sets the default divider image. This is 8x8 pixels instead of NSSplitView's 9x9, but looks as good.
	thumb8 = [[self imageNamed:@"Thumb8"] retain];
	[thumb8 setFlipped:YES];
	thumb9 = [[self imageNamed:@"Thumb9"] retain];
	[thumb9 setFlipped:YES];
	[splitView setDivider:thumb8];
// Associate the image with our prototype RBSplitView.
	[self associateObject:splitView ofType:IBViewPboardType withView:splitImage];
// Finish instantiating the palette, and register as a dragging delegate.
	[super finishInstantiate];
}

@end

// This implements the attribute inspector for RBSplitSubview...
@implementation RBSplitSubviewInspector

// Loads the proper inspector nib file.
- (id)init {
    self = [super init];
    [NSBundle loadNibNamed:@"RBSplitSubviewInspector" owner:self];
    return self;
}

// Called to move values from the inspected view into the inspector window. Quite straightforward.
- (void)revert:(id)sender {
	RBSplitSubview* suv = (RBSplitSubview*)[self object];
	RBSplitView* sv = [suv splitView];
	[collapseButton setState:[suv canCollapse]];
	[[identifierValue cellAtIndex:0] setStringValue:[suv identifier]];
	[[minimumValue cellAtIndex:0] setDoubleValue:[suv minDimension]];
// No max limit is indicated by a blank value; don't want to confuse the user with 1000000.0
	CGFloat dimension = [suv maxDimension];
	if (dimension<WAYOUT) {
		[[maximumValue cellAtIndex:0] setDoubleValue:dimension];
	} else {
		[[maximumValue cellAtIndex:0] setStringValue:@""];
	}
	NSUInteger position = [suv position];
	[[positionValue cellAtIndex:0] setIntegerValue:position];
	[positionStepper setIntegerValue:position];
	[[tagValue cellAtIndex:0] setIntegerValue:[suv tag]];
	[adjustButton setEnabled:([[suv subviews] count]==1)];
	[sv adjustSubviews];
	[[self inspectedDocument] drawObject:sv];
	[super revert:sender];
}

// Adjust enclosed subview with undo support.
- (void)setSubview:(NSView*)subview withUndo:(NSUndoManager*)undo frame:(NSRect)frame andAutoresizingMask:(NSUInteger)autoresizingMask {
	if (undo) {
		[[undo prepareWithInvocationTarget:self] setSubview:subview withUndo:undo frame:[subview frame] andAutoresizingMask:[subview autoresizingMask]];
		[undo setActionName:@"Adjust Enclosed"];
	}
	[subview placeView:frame];
	[subview setAutoresizingMask:autoresizingMask];
}

// This is the same action method for all inspector controls. Makes for a messy implementation
// with all these if...then...else if thingies. The alternative would be to have a different
// action method for every control, this is on the to-do list.
// Note that some controls have their value immediately written back into the window. As those
// setter methods do consistency checking, this is necessary; if the user enters an invalid
// value, it gets corrected immediately.
- (void)ok:(id)sender {
	RBSplitSubview* suv = (RBSplitSubview*)[self object];
	RBSplitView* sv = [suv ibSplitView];
    [self beginUndoGrouping];
    [self noteAttributesWillChangeForObject:sv];
	if (sender==collapseButton) {
		[suv setCanCollapse:[collapseButton state]];
	} else if (sender==adjustButton) {
		NSArray* subs = [suv subviews];
		if ([subs count]==1) {
			NSView<IBEditors>* owner = (NSView<IBEditors>*)[NSApp selectionOwner];
			NSUndoManager* undo = nil;
			if ([owner respondsToSelector:@selector(undoManager)]) {
				undo = [owner undoManager];
			}
			[self setSubview:[subs objectAtIndex:0] withUndo:undo frame:[suv bounds] andAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
		}
	} else if (sender==identifierValue) {
		[suv setIdentifier:[[identifierValue cellAtIndex:0] stringValue]];
	} else if ((sender==minimumValue)||(sender==maximumValue)) {
		[suv setMinDimension:[[minimumValue cellAtIndex:0] doubleValue] andMaxDimension:[[maximumValue cellAtIndex:0] doubleValue]];
// No max limit is indicated by a blank value; don't want to confuse the user with 1000000.0
		CGFloat dimension = [suv maxDimension];
		if (dimension<WAYOUT) {
			[[maximumValue cellAtIndex:0] setDoubleValue:dimension];
		} else {
			[[maximumValue cellAtIndex:0] setStringValue:@""];
		}
	} else if (sender==currentMinButton) {
		CGFloat dim = [suv dimension];
		[suv setMinDimension:dim andMaxDimension:[suv maxDimension]];
		[[minimumValue cellAtIndex:0] setDoubleValue:dim];
	} else if (sender==currentMaxButton) {
		CGFloat dim = [suv dimension];
		[suv setMinDimension:[suv minDimension] andMaxDimension:dim];
		[[maximumValue cellAtIndex:0] setDoubleValue:dim];
	} else if (sender==positionValue) {
		NSUInteger position = [[positionValue cellAtIndex:0] integerValue];
		[suv setPosition:position];
		position = [suv position];
		[[positionValue cellAtIndex:0] setIntegerValue:position];
		[positionStepper setIntegerValue:position];
	} else if (sender==positionStepper) {
		NSUInteger position = [positionStepper integerValue];
		[suv setPosition:position];
		position = [suv position];
		[[positionValue cellAtIndex:0] setIntegerValue:position];
		[positionStepper setIntegerValue:position];
	} else if (sender==tagValue) {
		[suv setTag:[[tagValue cellAtIndex:0] integerValue]];
	}
	[sv adjustSubviews];
	[[self inspectedDocument] drawObject:sv];
	[super ok:sender];
}

@end

// This implements the size inspector for RBSplitSubview... we don't use the standard size
// inspector as RBSplitSubviews only have one "dimension".
@implementation RBSplitSubviewSizeInspector

// Loads the proper inspector nib file.
- (id)init {
	self = [super init];
	[NSBundle loadNibNamed:@"RBSplitSubviewSizeInspector" owner:self];
	return self;
}

// Called to move values from the inspected view into the inspector window. Quite straightforward.
- (void)revert:(id)sender {
	RBSplitSubview* suv = (RBSplitSubview*)[self object];
	RBSplitView* sv = [suv ibSplitView];
	[[sizeValue cellAtIndex:0] setDoubleValue:[suv dimension]];
// As a convenience, we show the minimum and (if present) maximum dimensions.
	CGFloat limit = [suv maxDimension];
	if (limit>=WAYOUT) {
#warning 64BIT: Check formatting arguments
		[sizeLimits setStringValue:[NSString stringWithFormat:@"Minimum %g",[suv minDimension]]];
	} else {
#warning 64BIT: Check formatting arguments
		[sizeLimits setStringValue:[NSString stringWithFormat:@"Minimum %g\nMaximum %g",[suv minDimension],[suv maxDimension]]];
	}
	[collapsedButton setEnabled:[suv canCollapse]];
	[collapsedButton setState:[suv isCollapsed]];
	[sv adjustSubviews];
	[[self inspectedDocument] drawObject:sv];
    [super revert:sender];
}

// The action method for the inspector control.
- (void)ok:(id)sender {
	RBSplitSubview* suv = (RBSplitSubview*)[self object];
	RBSplitView* sv = [suv ibSplitView];
    [self beginUndoGrouping];
    [self noteAttributesWillChangeForObject:suv];
	if (sender==sizeValue) {
		[suv setDimension:[[sizeValue cellAtIndex:0] doubleValue]];
		[[sizeValue cellAtIndex:0] setDoubleValue:[suv dimension]];
	} else if (sender==collapsedButton) {
		if ([sender state]) {
			[suv collapse];
		} else {
			[suv expand];
		}
		[collapsedButton setState:[suv isCollapsed]];
	}
	[[self inspectedDocument] drawObject:sv];
	[super ok:sender];
}

@end

// This implements the attribute inspector for RBSplitView...
@implementation RBSplitViewInspector

- (id)init {
    self = [super init];
    [NSBundle loadNibNamed:@"RBSplitViewInspector" owner:self];
    return self;
}

// Called to move values from the inspected view into the inspector window. Quite straightforward.
- (void)revert:(id)sender {
	RBSplitView* sv = (RBSplitView*)[self object];
	[[autosaveName cellAtIndex:0] setStringValue:[sv autosaveName]];
// Show clearColor if background is nil.
	[hiddenButton setState:[sv isHidden]];
	NSInteger count = [[sv subviews] count];
	[[subviewCount cellAtIndex:0] setIntegerValue:count];
	[subviewStepper setIntegerValue:count];
	[[tagValue cellAtIndex:0] setIntegerValue:[sv tag]];
	CGFloat divt = [sv RB___dividerThickness];
	[thicknessValue setEnabled:(divt>0.0)||![sv divider]];
	[useButton setState:divt<1.0];
	[[thicknessValue cellAtIndex:0] setDoubleValue:[sv dividerThickness]];
	RBSplitView* suv = [sv ibSplitView];
	BOOL notc = ![sv isCoupled];
	[coupledButton setState:!notc];
	[coupledButton setEnabled:[sv splitView]!=nil];
// We select one or another tab depending on whether we're a nested RBSplitView or not.
	[tabView selectTabViewItemAtIndex:suv?1:0];
// Switch the next key view according to the tab.
	[autosaveName setNextKeyView:suv?positionValue:subviewCount];
	[collapseButton setState:[sv canCollapse]];
	[[identifierValue cellAtIndex:0] setStringValue:[sv identifier]];
	[[minimumValue cellAtIndex:0] setDoubleValue:[sv minDimension]];
// No max limit is indicated by a blank value; don't want to confuse the user with 1000000.0
	CGFloat dimension = [sv maxDimension];
	if (dimension<WAYOUT) {
		[[maximumValue cellAtIndex:0] setDoubleValue:dimension];
	} else {
		[[maximumValue cellAtIndex:0] setStringValue:@""];
	}
	NSUInteger position = [sv position];
	[[positionValue cellAtIndex:0] setIntegerValue:position];
	[positionStepper setIntegerValue:position];
	[orientation selectCellWithTag:[sv isVertical]];
	NSColor* background = [sv background];
	[backgroundWell setColor:background?background:[NSColor clearColor]];
	[backgroundWell setEnabled:notc];
	NSImage* divider = [[[sv divider] copy] autorelease];
	[divider setFlipped:NO];
	[[[dividerImage menu] itemAtIndex:0] setImage:divider];
	[dividerImage setEnabled:notc];
	NSSize size = divider?[divider size]:NSZeroSize;
#warning 64BIT: Check formatting arguments
	[dividerSize setStringValue:notc?[NSString stringWithFormat:@"(%g x %g)",size.width,size.height]:
		@"(from containing view)"];
	[sv adjustSubviews];
	[[self inspectedDocument] drawObject:sv];
    [super revert:sender];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)anItem {
	if ([anItem tag]==5) {
		if (![NSImage canInitWithPasteboard:[NSPasteboard generalPasteboard]]) {
			return NO;
		} 
	}
	return YES;
}

// This is the same action method for all inspector controls. Makes for a messy implementation
// with all these if...then...else if thingies. The alternative would be to have a different
// action method for every control,  this is on the to-do list.
// Note that some controls have their value immediately written back into the window. As those
// setter methods do consistency checking, this is necessary; if the user enters an invalid
// value, it gets corrected immediately.
- (void)ok:(id)sender {
	RBSplitView* sv = (RBSplitView*)[self object];
    [self beginUndoGrouping];
    [self noteAttributesWillChangeForObject:sv];
	if (sender==collapseButton) {
		[sv setCanCollapse:[collapseButton state]];
	} else if (sender==useButton) {
		if ([useButton state]) {
			[sv setDividerThickness:0.0];
		} else {
			[sv setDividerThickness:[sv dividerThickness]];
		}
		CGFloat divt = [sv RB___dividerThickness];
		[thicknessValue setEnabled:(divt>0.0)||![sv divider]];
		[[thicknessValue cellAtIndex:0] setDoubleValue:[sv dividerThickness]];
		[useButton setState:divt<1.0];	
	} else if (sender==coupledButton) {
		[sv setCoupled:[coupledButton state]];
		BOOL notc = ![sv isCoupled];
		NSColor* background = [sv background];
		[backgroundWell setColor:background?background:[NSColor clearColor]];
		[backgroundWell setEnabled:notc];
		NSImage* divider = [[[sv divider] copy] autorelease];
		[divider setFlipped:NO];
		[[[dividerImage menu] itemAtIndex:0] setImage:divider];
		[dividerImage setEnabled:notc];
		NSSize size = divider?[divider size]:NSZeroSize;
#warning 64BIT: Check formatting arguments
		[dividerSize setStringValue:notc?[NSString stringWithFormat:@"(%g x %g)",size.width,size.height]:
			@"(from containing view)"];
	} else if (sender==identifierValue) {
		[sv setIdentifier:[[identifierValue cellAtIndex:0] stringValue]];
	} else if ((sender==minimumValue)||(sender==maximumValue)) {
		[sv setMinDimension:[[minimumValue cellAtIndex:0] doubleValue] andMaxDimension:[[maximumValue cellAtIndex:0] doubleValue]];
// No max limit is indicated by a blank value; don't want to confuse the user with 1000000.0
		CGFloat dimension = [sv maxDimension];
		if (dimension<WAYOUT) {
			[[maximumValue cellAtIndex:0] setDoubleValue:dimension];
		} else {
			[[maximumValue cellAtIndex:0] setStringValue:@""];
		}
	} else if (sender==positionValue) {
		NSUInteger position = [[positionValue cellAtIndex:0] integerValue];
		[sv setPosition:position];
		position = [sv position];
		[[positionValue cellAtIndex:0] setIntegerValue:position];
		[positionStepper setIntegerValue:position];
	} else if (sender==positionStepper) {
		NSUInteger position = [positionStepper integerValue];
		[sv setPosition:position];
		position = [sv position];
		[[positionValue cellAtIndex:0] setIntegerValue:position];
		[positionStepper setIntegerValue:position];
	} else if (sender==thicknessValue) {
		[sv setDividerThickness:[[thicknessValue cellAtIndex:0] doubleValue]];
		[[thicknessValue cellAtIndex:0] setDoubleValue:[sv dividerThickness]];
	} else if (sender==autosaveName) {
		[sv setAutosaveName:[[autosaveName cellAtIndex:0] stringValue] recursively:YES];
	} else if (sender==backgroundWell) {
		[sv setBackground:[backgroundWell color]];
	} else if (sender==dividerImage) {
		NSImage* thi = nil;
		switch ([[dividerImage selectedItem] tag]) {
//			case 1:	// None
//				thi = nil;
//				break;
			case 2: // Empty
				thi = [[[NSImage alloc] initWithSize:NSMakeSize(1.0,1.0)] autorelease];
				[thi lockFocus];
				[[NSColor clearColor] set];
				NSRectFill(NSMakeRect(0.0,0.0,1.0,1.0));
				[thi unlockFocus];
				[thi setFlipped:YES];
				break;
			case 3:	// Default 8x8
				thi = thumb8;
				break;
			case 4:	// NSSplitView 9x9
				thi = thumb9;
				break;
			case 5:	// Paste Image
				thi = [[[NSImage alloc] initWithPasteboard:[NSPasteboard generalPasteboard]] autorelease];
				[thi setFlipped:YES];
				break;
		}
		[sv setDivider:thi];
		[[[dividerImage menu] itemAtIndex:0] setImage:thi];
	} else if (sender==hiddenButton) {
		[sv setHidden:[hiddenButton state]];
	} else if (sender==orientation) {
		[sv setVertical:[[orientation selectedCell] tag]];
	} else if (sender==subviewCount) {
		NSInteger count = [[subviewCount cellAtIndex:0] integerValue];
		[sv ibSetNumberOfSubviews:count];
		count = [sv numberOfSubviews];
		[subviewStepper setIntegerValue:count];
		[[subviewCount cellAtIndex:0] setIntegerValue:count];
	} else if (sender==subviewStepper) {
		NSInteger count = [subviewStepper integerValue];
		[sv ibSetNumberOfSubviews:count];
		count = [sv numberOfSubviews];
		[subviewStepper setIntegerValue:count];
		[[subviewCount cellAtIndex:0] setIntegerValue:count];
	} else if (sender==tagValue) {
		[sv setTag:[[tagValue cellAtIndex:0] integerValue]];
	}
// If we're nested, adjust and redraw the containing RBSplitView.
	RBSplitView* svv = [sv splitView];
	if (svv) {
		sv = svv;
	}
	[sv adjustSubviews];
	[[self inspectedDocument] drawObject:sv];
    [super ok:sender];
}

@end

// This category adds some functionality to RBSplitSubview to support Interface Builder stuff.
// Since RBSplitView is a subclass of RBSplitSubview, in several places we have to check which class we are.

@implementation RBSplitSubview (RBSSIBAdditions)

// We override this here to get the owning RBSplitView.
- (BOOL)splitViewIsHorizontal {
	return [[self ibSplitView] isHorizontal];
}

// This overrides RBSplitSubview's drawRect: method, to draw the nice brown background for
// empty subviews. As a convenience, the subview's dimension is also shown.
- (void)drawRect:(NSRect)rect {
// Draw only if a normal subview.
		if ([self numberOfSubviews]>0) {
// Don't draw brown background if there are any subviews; draw the set background, if any.
			NSColor* bg = [[self splitView] background];
			if (bg) {
				[bg set];
				NSRectFillUsingOperation(rect,NSCompositeSourceOver);
			}
			return;
		}
	if (![self asSplitView]) {
		if (
// Comment out the next line ("YES||") for normal operation. Leaving it in shows the brown background even
// under IB's "test interface" mode, which is very convenient for debugging.
			YES||
			![NSApp isTestingInterface]) {
			rect = [self bounds];
// Draws the bezel around the subview.
			static NSRectEdge mySides[] = {NSMinXEdge,NSMaxYEdge,NSMinXEdge,NSMinYEdge,NSMaxXEdge,NSMaxYEdge,NSMaxXEdge,NSMinYEdge};
			static CGFloat myGrays[] = {0.5,0.5,1.0,1.0,1.0,1.0,0.5,0.5};
			rect = NSDrawTiledRects(rect,rect,mySides,myGrays,8);
			static NSColor* brown = nil;
			if (!brown) {
				brown = [[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.5] retain];
			}
			[brown set];
			NSRectFillUsingOperation(rect,NSCompositeSourceOver);
// Sets up the text attributes for the dimension text.
			static NSDictionary* attributes = nil;
			if (!attributes) {
				attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor whiteColor],NSForegroundColorAttributeName,[NSFont systemFontOfSize:12.0],NSFontAttributeName,nil];
			}
// Sets up the "nnnpx" string and draws it centered into the subview.
#warning 64BIT: Check formatting arguments
			NSAttributedString* label = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%gpx",[self dimension]] attributes:attributes] autorelease];
			NSSize labelSize = [label size];
			rect.origin.y += floorf((rect.size.height-labelSize.height)/2.0);
			rect.origin.x += floorf((rect.size.width-labelSize.width)/2.0);
			rect.size = labelSize;
			[label drawInRect:rect];
		}
	}
}

// This returns the owning splitview. It's guaranteed to return a RBSplitView or nil.
- (RBSplitView*)ibSplitView {
	id<IBDocuments> document = [NSApp documentForObject:self];
	id result = document?[document parentOfObject:self]:[self superview];
	if ([result isKindOfClass:[RBSplitView class]]) {
		return (RBSplitView*)result;
	}
	return nil;
}

// Returns the proper class name for the attribute inspector.
- (NSString *)inspectorClassName {
    return [self asSplitView]?@"RBSplitViewInspector":@"RBSplitSubviewInspector";
}

// Returns the class name for the size inspector (for RBSplitSubviews only). We expect never to
// find RBSplitSubviews outside a RBSPlitView.
- (NSString *)sizeInspectorClassName {
	return [self ibSplitView]?@"RBSplitSubviewSizeInspector":[super sizeInspectorClassName];
}

// Shows the proper name and identifier string in the object outline view, if there's any.
- (NSString *)nibLabel:(NSString*)objectName {
	NSString* name = [self asSplitView]?@"RBSplitView":@"RBSplitSubview";
	if ([identifier length]) {
		return [NSString stringWithFormat:@"%@ (%@)",name,identifier];
	}
	return name;
}

// RBSplitSubview presents itself as a candidate for accepting a drag. Without this, the subview wouldn't
// accept drags at all. RBSplitViews don't accept drags directly.
- (id)ibNearestTargetForDrag {
	return [self asSplitView]?nil:self;
}

// This combination of responses seems to be optimal...

- (BOOL)ibIsContainer {
	return YES;
}

- (BOOL)ibSupportsInsideOutSelection {
	return YES;
}

- (BOOL)ibDrawFrameWhileResizing {
	return YES;
}

- (BOOL)ibSupportsLiveResize {
	return YES;
}

- (BOOL)ibShouldShowContainerGuides {
	return NO;
}

// This undocumented method fixes the subview redrawing problem! Yay!
- (BOOL)editorHandlesCaches {
	return YES;
}

// Limits the minimum subview size to 16x16, which shouldn't be too much of hardship.
- (NSSize)minimumFrameSizeFromKnobPosition:(IBKnobPosition)position {
	RBSplitView* sv = [self asSplitView];
	if (sv) {
		NSUInteger count = [sv numberOfSubviews];
		CGFloat size = 16.0*count+[sv dividerThickness]*(count-1);
		return [sv isHorizontal]?NSMakeSize(16.0,size):NSMakeSize(size,16.0);
	}
	return NSMakeSize(16.0,16.0);
}

// This blocks dragging of RBSplitSubviews inside RBSplitViews; non-nested RBSplitViews can be
// dragged around normally.
- (NSString *)trackerClassNameForEvent:(NSEvent *)event {
	return [self asSplitView]?[super trackerClassNameForEvent:event]:nil;
}

// This must return YES to allow receiving drags, or handling mouse clicks.
- (BOOL)canEditSelf {
	return YES;
}

// The default NSView editor works quite well, but for RBSplitViews we need special handling for clicks.
- (void)editSelf:(NSEvent*)theEvent in:(NSView<IBEditors>*)viewEditor {
	if ([theEvent type]==NSLeftMouseDown) {
// We handle mouse clicks separately if we're a RBSplitView, to allow for divider dragging in IB.
		if ([[self asSplitView] ibHandleMouseDown:theEvent in:viewEditor]) {
			return;
		}
	}
// Otherwise have the view editor handle it.
	[(id)super editSelf:theEvent in:viewEditor];
}

// This redisplays the receiver and all nested RBSplitSubviews.
- (void)ibResetObjectInEditor:(NSView<IBEditors>*)viewEditor {
	[viewEditor resetObject:self];
	NSEnumerator* enumerator = [[self subviews] objectEnumerator];
	RBSplitSubview* sub;
	while ((sub = [enumerator nextObject])) {
		if ([sub isKindOfClass:[RBSplitSubview class]]) {
			[sub ibResetObjectInEditor:viewEditor];
		}
	}
}

// This handles undoing over KVC. Or something. :-P
- (void)setIsCollapsed:(BOOL)status {
	if (status) {
		[self RB___collapse];
	} else {
		[self RB___expandAndSetToMinimum:NO];
	}
	RBSplitView* sv = [self splitView];
	if (sv) {
		[sv adjustSubviews];
		id<IBDocuments> document = [NSApp documentForObject:self];
		[document drawObject:sv];
	}
}

@end


// This category adds some functionality to RBSplitView to support Interface Builder stuff.
// Most of the basic stuff is actually done in RBSplitSubview.

@implementation RBSplitView (RBSVIBAdditions)

- (RBSplitView*)couplingSplitView {
	return isCoupled?[self ibSplitView]:nil;
}

- (RBSplitView*)splitView {
	return [self ibSplitView];
}

// Overrides the corresponding method in RBSplitView to do nothing, since we don't
// want to save state inside Interface Builder.
- (BOOL)saveState:(BOOL)recurse {
	return NO;
}

// These two methods add subviews. (Both override the corresponding methods in RBSplitView).
// IB may add dummy NSViews so we allow anything here, with no special handling.
- (void)addSubview:(NSView*)aView {
	[super addSubview:aView];
	[self setMustAdjust];
}

- (void)addSubview:(NSView *)aView positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView {
	[super addSubview:aView positioned:place relativeTo:otherView];
	[self setMustAdjust];
}

// Called just after a RBSplitView has been decoded from either a palette or a nib file.
- (id)awakeAfterUsingCoder:(NSCoder*)aDecoder {
// At this point the RBSplitView hasn't been inserted into anything, so we ask for
// ibSetupSelf to be performed in the run loop, when it will (presumably) have been.
	[self performSelector:@selector(ibSetupSelf) withObject:nil afterDelay:0.0];
	return self;
}

// Called by ibSetupSelf to handle nested RBSplitViews, which actually never happens at this point,
// but it's conceptually interesting to see how it would be done.
- (void)ibAttachSubviewsOf:(NSView*)view inDocument:(id<IBDocuments>)document {
	NSEnumerator* enumerator = [[view subviews] objectEnumerator];
	NSView* sub;
// Loop over subviews and attach them to the parent, then recurse on nested RBSplitSubviews
	while ((sub = [enumerator nextObject])) {
		if ([sub isKindOfClass:[RBSplitSubview class]]) {
			[document attachObject:sub toParent:view];
			[self ibAttachSubviewsOf:sub inDocument:document];
		}
	}
}

// Called after a new RBSplitView is dropped into a window.
- (void)ibSetupSelf {
	id<IBDocuments> document = [NSApp documentForObject:self];
// This may be called spuriously when we're not yet inserted into a document, or from IB's simulation mode,
// so we check...
	if (document) {
		NSView* object = [document parentOfObject:self];
		BOOL vert = [self isVertical];
		RBSplitView* sv = nil;
// Check if we've been inserted into a RBSplitSubview.
		if ([object isMemberOfClass:[RBSplitSubview class]]) {
			sv = [(RBSplitSubview*)object splitView];
			if (sv) {
				if ([[(RBSplitSubview*)object subviews] count]>1) {
// We don't nest RBSplitViews directly if there's already another subview there.
					vert = [sv isHorizontal];
					sv = nil;
				}
			}
		}
		[self setVertical:vert];
		if (sv) {
// If we're nesting RBSplitViews we copy the attributes of the subview that's being replaced to the nested RBSplitView.
			[self RB___setFrame:[(RBSplitSubview*)object frame] withFraction:[(RBSplitSubview*)object RB___fraction] notify:NO];
			[self setTag:[(RBSplitSubview*)object tag]];
			[self setIdentifier:[(RBSplitSubview*)object identifier]];
			[self setCanCollapse:[(RBSplitSubview*)object canCollapse]];
			[self setMinDimension:[(RBSplitSubview*)object minDimension] andMaxDimension:[(RBSplitSubview*)object maxDimension]];
// The dropped view will replace the existing subview in both the view and in the IB outline hierarchies.
			[self retain];
			[self removeFromSuperviewWithoutNeedingDisplay];
			[sv replaceSubview:object with:self];
			[document detachObject:self];
			[document replaceObject:object withObject:self];
			[self release];
		} else {
// As a convenience, we set the inner resizing springs if we're not nested.
			[self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
		}
// Set up the IB outline hierarchy correctly for our subviews.
		[self ibAttachSubviewsOf:self inDocument:document];
// Then we recalculate subview dimensions and redraw everything.
		[self adjustSubviews];
		[document drawObject:(sv?sv:object)];
	}
}

// This is called when setting the number of subviews from the inspector. There's some IB stuff
// interleaved to tweak the outline hierarchy.
- (void)ibSetNumberOfSubviews:(NSUInteger)count {
	NSUInteger now = [self numberOfSubviews];
	NSRect frame = NSZeroRect;
	id<IBDocuments> document = nil;
	if (now<count) {
		frame = [[[self subviews] lastObject] frame];
	}
	while (now!=count) {
		if (!document) {
			document = [NSApp documentForObject:self];
		}
		if (now<count) {
			RBSplitSubview* sub = [[[RBSplitSubview alloc] initWithFrame:frame] autorelease];
			[self addSubview:sub positioned:NSWindowAbove relativeTo:nil];
			[document attachObject:sub toParent:self];
		} else {
			RBSplitSubview* sub = [[self subviews] lastObject];
			[sub removeFromSuperviewWithoutNeedingDisplay];
			[document detachObject:sub];
		}
		now = [self numberOfSubviews];
	}
	[self RB___setMustClearFractions];
	[self adjustSubviews];
}

// This is called when handling mouse-down events. Unfortunately the circumstances when this is called
// are somewhat peculiar. We handle dragging individual dividers here, but not double-clicking or two-axis
// dragging. We also allow dragging when no divider image is set.
// To drag a divider, click outside the view to deselect it, then double-click on the divider, but
// don't release the mouse on the second click. After this incantation, the "closed hand" cursor
// should appear and you can drag the divider around. Returns YES if the event was handled.
- (BOOL)ibHandleMouseDown:(NSEvent*)theEvent in:(NSView<IBEditors>*)viewEditor {
	if (!dividers) {
		return NO;
	}
	NSPoint where = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSArray* subviews = [self subviews];
	NSInteger subcount = [subviews count];
	if (subcount>1) {
		NSInteger i;
		NSPoint base = NSZeroPoint;
// Strangely enough, when this is called the view hierarchy isn't inserted into a window at all, but rather
// into a (non-visible) container view, so we have to account for its frame offset.
		if (![self window]) {
			NSView* superv = self;
// Loop over the superviews and get the outermost one's offset
			while (superv) {
				NSRect frame = [superv frame];
				if (!(superv = [superv superview])) {
					base.x += frame.origin.x;
					base.y += frame.origin.y;
				}
			}
		}
		BOOL ishor = [self isHorizontal];
		where.x -= base.x;
		where.y -= base.y;
// Loop over the subviews and divider rectangles until the mouse is within one.
		for (i=0;i<subcount;i++) {
			RBSplitSubview* sub = [subviews objectAtIndex:i];
// First test the subview...
			if ([self mouse:where inRect:[sub frame]]) {
				RBSplitView* sv = [sub asSplitView];
				if (sv) {
// If it's a nested RBSplitView, have it handle the event
					return [sv ibHandleMouseDown:theEvent in:viewEditor];
				}
				return NO;
			} else if (i<subcount-1) {
				NSRect* divi = &dividers[i];
				if ([self mouse:where inRect:*divi]) {
// Found one; record the offset within the divider rectangle and show the cursor.
					CGFloat offset = DIM(where)-DIM(divi->origin);
					[[NSCursor closedHandCursor] push];
// Save state for undoing the divider drag.
					NSUndoManager* undo = [viewEditor undoManager];
					if (undo) {
						[[undo prepareWithInvocationTarget:self] ibRestoreState:[self stringWithSavedState] in:viewEditor];
						[undo setActionName:@"Divider Drag"];
					}
// Now we loop handling mouse events until we get a mouse up event.
					while ((theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask|NSLeftMouseDraggedMask|NSLeftMouseUpMask untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES])&&([theEvent type]!=NSLeftMouseUp)) {
// Set up a local autorelease pool for the loop to prevent buildup of temporary objects.
						NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
						[self RB___trackMouseEvent:theEvent from:where withBase:base inDivider:i];
						if (mustAdjust) {
// The mouse was dragged and the subviews changed, so we adjust the subviews, as
// several divider rectangles may have changed.
							[self adjustSubviews];
// Display the changed split view (or its outermost parent, if it's nested) and adjust
// to the new cursor coordinate.
							RBSplitView* sv = [self outermostSplitView];
							[sv?sv:self ibResetObjectInEditor:viewEditor];
							DIM(where) = DIM(divi->origin)+offset;
						}
						[pool release];
					}
					[NSCursor pop];
// Touch the document to show it's been changed.
					[[viewEditor document] touch];
					return YES;
				}
			}
		}
	}
	return NO;
}

// This methods undoes divider drags.
- (void)ibRestoreState:(NSString*)string in:(NSView<IBEditors>*)viewEditor {
	NSUndoManager* undo = [viewEditor undoManager];
	if (undo) {
		[[undo prepareWithInvocationTarget:self] ibRestoreState:[self stringWithSavedState] in:viewEditor];
		[undo setActionName:@"Divider Drag"];
	}
	[self setStateFromString:string];
	[self adjustSubviews];
	RBSplitView* sv = [self outermostSplitView];
	[sv?sv:self ibResetObjectInEditor:viewEditor];
}

@end

