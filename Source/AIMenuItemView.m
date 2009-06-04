//
//  AIMenuItemView.m
//  Adium
//
//  Created by Evan Schoenberg on 12/20/05.
//

#import "AIMenuItemView.h"

#define CHECK_UNICODE	0x2713 /* Unicode CHECK MARK*/

#define MENU_ITEM_HEIGHT	17
#define	MENU_ITEM_SPACING	2

@interface AIMenuItemView ()

@end

@implementation AIMenuItemView
- (void)_initMenuItemView
{
	currentHoveredIndex = -1;
}

- (void)awakeFromNib
{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
	}

	if (delegate && [delegate respondsToSelector:@selector(menuForMenuItemView:)]) {
		[self setMenu:[delegate menuForMenuItemView:self]];
	}
	
	[self _initMenuItemView];
}

- (id)initWithFrame:(NSRect)inFrame
{
	if ((self = [super initWithFrame:inFrame])) {
		[self _initMenuItemView];
	}
	
	return self;
}

- (void)dealloc
{
	[menu release];
	[trackingTags release];
	[menuItemAttributes release];
	[disabledMenuItemAttributes release];
	[hoveredMenuItemAttributes release];

	[super dealloc];
}


#pragma mark Menu

/*!
 * @brief Set the menu we display
 */
- (void)setMenu:(NSMenu *)inMenu
{
//	NSLog(@"Set menu: %@",inMenu);
	if (menu != inMenu) {
		[menu release];
		menu = [inMenu retain];
	}
	
	[self setNeedsDisplay:YES];
	
	if ([delegate respondsToSelector:@selector(menuItemViewDidChangeMenu:)]) {
		[delegate menuItemViewDidChangeMenu:self];
	}
//	NSLog(@"set menu reset");
	[self resetCursorRects];
}

- (NSMenu *)menu
{
	return menu;
}

@synthesize delegate;

#pragma mark Index and Point/Rect Correlation

/*!
 * @brief Return the index at a point
 *
 * @param inPoint The point in our local coordinates
 */
- (NSInteger)indexAtPoint:(NSPoint)inPoint
{
	CGFloat	heightFromTop = [self frame].size.height - inPoint.y;
	NSInteger		index = 0;

	while ((heightFromTop - (((MENU_ITEM_HEIGHT + MENU_ITEM_SPACING) * index) + MENU_ITEM_HEIGHT)) > 0) {
		index++;
	}

	return index;
}

/*!
 * @brief Return the rect (in local coordinates) for a menu item by index
 */
- (NSRect)rectForIndex:(NSInteger)index
{
	NSRect	myFrame = [self frame];
	return NSMakeRect(0,
					  (myFrame.size.height - (((MENU_ITEM_HEIGHT + MENU_ITEM_SPACING) * index) + MENU_ITEM_HEIGHT)),
					  myFrame.size.width,
					  MENU_ITEM_HEIGHT);
	
}

#pragma mark Drawing
- (void)drawRect:(NSRect)inRect
{
	NSInteger		i, numberOfMenuItems;
	BOOL	willDisplayACheckbox = NO;

	numberOfMenuItems = [menu numberOfItems];
	
	//Determine if one or more menu items is in a non-off (that it, on or mixed) state.
	for (i = 0; i < numberOfMenuItems; i++) {
		NSMenuItem			*menuItem = [menu itemAtIndex:i];
		if ([menuItem state] != NSOffState) {
			willDisplayACheckbox = YES;
			break;
		}
	}
	
	//Now do the actual drawing
	for (i = 0; i < numberOfMenuItems; i++) {
		NSRect	menuItemRect = [self rectForIndex:i];

		if (NSIntersectsRect(menuItemRect,inRect)) {
			NSMenuItem			*menuItem = [menu itemAtIndex:i];

			if ([menuItem isSeparatorItem]) {
				//Draw the separatorItem line centered in the menu item rect
				menuItemRect.origin.y = (menuItemRect.origin.y + (menuItemRect.size.height / 2) - 1);
				menuItemRect.size.height = 1;
				
				[[NSColor grayColor] set];
				NSRectFill(menuItemRect);
	
			} else {
				NSAttributedString	*title;
				BOOL				currentlyHovered = ((currentHoveredIndex == i) && [menuItem isEnabled]);

				if (currentlyHovered) {
					//Draw a selectedMenuItemColor box if we are hovered...
					[[NSColor selectedMenuItemColor] set];
					NSRectFill(menuItemRect);
				}
				
				//Move in so the highlight drawn above has proper borders around a checkmark
				menuItemRect.origin.x += 1;
				menuItemRect.size.width -= 1;
				
				//Indent the menu item if appropriate
				CGFloat indentation = [menuItem indentationLevel] * 5.0;
				menuItemRect.origin.x += indentation;
				menuItemRect.size.width -= indentation;

				if ([menuItem state] == NSOnState) {
					NSImage	*onStateImage;
					NSSize	size;

					if (currentlyHovered) {
						//If we're currently hovered, we need to turn our checkmark white...
						NSImage	*originalImage = [menuItem onStateImage];
						size = [originalImage size];

						onStateImage = [[[NSImage alloc] initWithSize:[originalImage size]] autorelease];
						
						[onStateImage lockFocus];

						//Fill the new image with white
						[[NSColor whiteColor] set];
						NSRectFill(NSMakeRect(0, 0, size.width, size.height));

						//But only keep the white where originalImage (the checkmark) exists
						[originalImage drawInRect:NSMakeRect(0, 0, size.width, size.height)
										 fromRect:NSMakeRect(0, 0, size.width, size.height)
										operation:NSCompositeDestinationAtop
										 fraction:1.0];
						[onStateImage unlockFocus];
						
					} else {
						onStateImage = [menuItem onStateImage];
						size = [onStateImage size];
					}
					
					[onStateImage drawAtPoint:NSMakePoint(menuItemRect.origin.x, 
														  menuItemRect.origin.y + ((menuItemRect.size.height - size.height) / 2))
									 fromRect:NSMakeRect(0, 0, size.width, size.height)
									operation:NSCompositeSourceOver
									 fraction:(currentlyHovered ? 1.0 : 0.85)];
				}
				
				NSDictionary	*currentTextAttributes;

				if (currentlyHovered) {
					//We're displaying the hovered menu item
					if (!hoveredMenuItemAttributes) {
						hoveredMenuItemAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
							[NSFont menuFontOfSize:13], NSFontAttributeName,
							[NSColor selectedMenuItemTextColor], NSForegroundColorAttributeName,
							nil];
					}
					
					currentTextAttributes = hoveredMenuItemAttributes;
					
				} else if (![menuItem isEnabled]) {
					//We're displaying a disabled menu item
					if (!disabledMenuItemAttributes) {
						disabledMenuItemAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
						[NSFont menuFontOfSize:13], NSFontAttributeName,
						[NSColor disabledControlTextColor], NSForegroundColorAttributeName,
						nil];
					}

					currentTextAttributes = disabledMenuItemAttributes;

				} else {
					//We're displaying a non-hovered menu item
					if (!menuItemAttributes) {
						menuItemAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
							[NSFont menuFontOfSize:13], NSFontAttributeName,
							nil];
					}
					
					currentTextAttributes = menuItemAttributes;
				}

				title = [[NSAttributedString alloc] initWithString:[menuItem title]
														attributes:currentTextAttributes];

				menuItemRect.origin.x += 2;
				menuItemRect.size.width -= 2;

				if (willDisplayACheckbox) {
					//Shift right, and shorten our width, for indentation like a real menu, leaving space for the checkmark if it's needed
#define CHECKMARK_WIDTH 9
					menuItemRect.origin.x += CHECKMARK_WIDTH;
					menuItemRect.size.width -= CHECKMARK_WIDTH;
				}

				[title drawInRect:menuItemRect];
				[title release];
			}
		}
	}
}

#pragma mark Sizing
- (void)sizeToFit
{
	NSRect frame = [self frame];

	CGFloat change = (([[self menu] numberOfItems] * (MENU_ITEM_HEIGHT + MENU_ITEM_SPACING)) - MENU_ITEM_SPACING) - frame.size.height;
	frame.size.height += change;
	frame.origin.y -= change;

	[self setFrame:frame];
}

#pragma mark Hovering tracking

/*!
 * @brief The mouse is hovering over a point
 *
 * @param inPoint The point in our local coordinates, or NULL if we are no longer hovering
 */
- (void)setHoveringAtPoint:(NSPoint)inPoint
{
	if (!NSEqualPoints(inPoint, NSZeroPoint)) {
		currentHoveredIndex = [self indexAtPoint:inPoint];
	} else {
		currentHoveredIndex = -1;
	}

	[self setNeedsDisplay:YES];
}


//Cursor entered one of our tracking rects
- (void)mouseEntered:(NSEvent *)theEvent
{
	[self setHoveringAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	
	[super mouseEntered:theEvent];
}


//Cursor left one of our tracking rects
- (void)mouseExited:(NSEvent *)theEvent
{
	[self setHoveringAtPoint:NSZeroPoint];

	[super mouseExited:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (currentHoveredIndex != -1) {
		NSMenuItem	*menuItem = [[self menu] itemAtIndex:currentHoveredIndex];
		[[menuItem target] performSelector:[menuItem action] withObject:menuItem];
	}
	
	[super mouseDown:theEvent];
}


#pragma mark Tracking rects

/*!
 * @brief Remove all our tracking rects
 */
- (void)removeTrackingRects
{
	NSNumber	 *trackingTag;
	
	for (trackingTag in trackingTags) {
		[self removeTrackingRect:[trackingTag integerValue]];
	}
	
	[trackingTags release]; trackingTags = nil;	
}

//Reset our cursor tracking
- (void)resetCursorRects
{
	//Stop any existing tracking
	if (trackingTags) {
		[self removeTrackingRects];
	}
	
	//Add tracking rects if our superview and window are ready
	if ([self superview] && [self window]) {		
		NSInteger		i, numberOfMenuItems;

		trackingTags = [[NSMutableSet alloc] init];

		numberOfMenuItems = [menu numberOfItems];
		for (i = 0; i < numberOfMenuItems; i++) {
			NSTrackingRectTag	trackingTag;
			NSRect				trackRect = [self rectForIndex:i];
			NSPoint				localPoint = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]]
													   fromView:nil];
			BOOL				mouseInside = NSPointInRect(localPoint, trackRect);

			trackingTag = [self addTrackingRect:trackRect owner:self userData:nil assumeInside:mouseInside];
			[trackingTags addObject:[NSNumber numberWithInteger:trackingTag]];
		    NSLog(@"Added tracking rect %ld for %@ (%@)",trackingTag,NSStringFromRect(trackRect), mouseInside ? @"inside" : @"outside");
			if (mouseInside) [self mouseEntered:nil];
		}
	}
}

@end
