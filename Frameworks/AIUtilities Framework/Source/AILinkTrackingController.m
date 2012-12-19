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

/*
 Add link tracking support to a view/cell.
 
 - Create an instance of AILinkTracking
 - Call resetCursorRectsInView:visibleRect: in response to resetCursorRects for your view
 - Call setContentString when your content changes
 */

#import "AILinkTrackingController.h"
#import "AIFlexibleLink.h"
#import "AITooltipUtilities.h"
#import "AIStringUtilities.h"
#import "AIMenuAdditions.h"

#define COPY_LINK   AILocalizedStringFromTableInBundle(@"Copy Link", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], "Copy the link to the clipboard")

@interface AILinkTrackingController ()
- (id)initForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer;
- (void)_beginCursorTrackingInRect:(NSRect)visibleRect withOffset:(NSPoint)offset;
- (void)_endCursorTracking;
- (void)_setMouseOverLink:(AIFlexibleLink *)inHoveredLink atPoint:(NSPoint)inPoint;
- (void)copyLink:(id)sender;
@end

BOOL _mouseInRects(NSPoint aPoint, NSRectArray someRects, NSUInteger arraySize, BOOL flipped);
NSRectArray _copyRectArray(NSRectArray someRects, NSUInteger arraySize);

@implementation AILinkTrackingController
//Create a link tracking controller for any view
+ (id)linkTrackingControllerForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer
{
    return [[self alloc] initForView:inControlView withTextStorage:inTextStorage layoutManager:inLayoutManager textContainer:inTextContainer];
}

//Create a tracking controller for a text view
+ (id)linkTrackingControllerForTextView:(NSTextView *)inTextView
{
    return [[self alloc] initForView:inTextView withTextStorage:[inTextView textStorage] layoutManager:[inTextView layoutManager] textContainer:[inTextView textContainer]];
}

//Track links in the passed rect.  Returns YES if links exist within our text.  Pass a 0 width/height visible rect to stop any link tracking.
- (void)trackLinksInRect:(NSRect)visibleRect withOffset:(NSPoint)offset
{
    //remove any existing tooltips
    [self _setMouseOverLink:nil atPoint:NSMakePoint(0,0)];

    //Reset the cursor tracking rects
    [self _endCursorTracking];
    if (visibleRect.size.width && visibleRect.size.height) {
        [self _beginCursorTrackingInRect:visibleRect withOffset:offset];
    }
}

//Toggle display of tooltips
- (void)setShowTooltip:(BOOL)inShowTooltip
{
    showTooltip = inShowTooltip;
}

//Called when the mouse enters the link
- (void)mouseEntered:(NSEvent *)theEvent
{
	NSWindow		*window = [theEvent window];
    AIFlexibleLink	*trackedLink = [theEvent userData];
    NSPoint		location;

    location = [trackedLink trackingRect].origin;
    location = [controlView convertPoint:location toView:nil];
    location = [[theEvent window] convertBaseToScreen:location];

    //Ignore the mouse entry if our view is hidden, or our window is non-main
    if ([window isMainWindow] && [controlView canDraw]) {
        [self _setMouseOverLink:trackedLink
                        atPoint:location];
    }
}

//Called when the mouse leaves the link
- (void)mouseExited:(NSEvent *)theEvent
{
    [self _setMouseOverLink:nil atPoint:NSMakePoint(0,0)];
}

//Handle a mouse down.  Returns NO if the mouse down event should continue to be processed
- (BOOL)handleMouseDown:(NSEvent *)theEvent withOffset:(NSPoint)offset
{
    BOOL			success = NO;
    NSPoint			mouseLoc;
    NSUInteger	glyphIndex;
    NSUInteger	charIndex;
    NSRectArray		linkRects = nil;
	
    [self _setMouseOverLink:nil atPoint:NSMakePoint(0,0)]; //Remove any tooltips
	
    //Find clicked char index
    mouseLoc = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
    mouseLoc.x -= offset.x;
    mouseLoc.y -= offset.y;
	
    glyphIndex = [layoutManager glyphIndexForPoint:mouseLoc inTextContainer:textContainer fractionOfDistanceThroughGlyph:nil];
    charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
	
    if (charIndex != NSNotFound && charIndex < [textStorage length]) {
        NSString	*linkString;
        NSURL		*linkURL;
        NSRange		linkRange;
		
        //Check if click is in valid link attributed range, and is inside the bounds of that style range, else fall back to default handler
        linkString = [textStorage attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:&linkRange];
		
		// The string might already have been filtered (i.e. in Context objects)
		if ( [linkString isKindOfClass:[NSURL class]] ) {
			linkString = [(NSURL *)linkString absoluteString];
		}
		
		if (linkString != nil && [linkString length] != 0) {
			//add http:// to the link string if a protocol wasn't specified
			if (([linkString rangeOfString:@"://"].location == NSNotFound) &&
			   ([linkString rangeOfString:@"mailto:"].location == NSNotFound)) {
				linkURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",linkString]];
			} else {
				linkURL = [NSURL URLWithString:linkString];
			}
			
			//bail if a link couldn't be made
			if (linkURL) {
				unsigned int	eventMask;
				NSDate			*distantFuture;
				NSUInteger		linkCount;
				BOOL			done = NO;
				BOOL			inRects = NO;
				
				//Setup Tracking Info
				distantFuture = [NSDate distantFuture];
				eventMask = NSLeftMouseUpMask | NSRightMouseUpMask | NSLeftMouseDraggedMask | NSRightMouseDraggedMask;
				
				//Find region of clicked link
				linkRects = [layoutManager rectArrayForCharacterRange:linkRange
										 withinSelectedCharacterRange:linkRange
													  inTextContainer:textContainer
															rectCount:&linkCount];
				linkRects = _copyRectArray(linkRects, linkCount);
				
				//One last check to make sure we're really in the bounds of the link. Useful when the link runs up to the end of the document and a click in the blank area below still pases the style range test above.
				if (_mouseInRects(mouseLoc, linkRects, linkCount, NO)) {
					//Draw ourselves as clicked and kick off tracking
					[textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:linkRange];
					[controlView setNeedsDisplay:YES];
					
					while (!done) {
						//Get the next event and mouse location
						theEvent = [NSApp nextEventMatchingMask:eventMask untilDate:distantFuture inMode:NSEventTrackingRunLoopMode dequeue:YES];
						mouseLoc = [controlView convertPoint:[theEvent locationInWindow] fromView:nil];
						mouseLoc.x -= offset.x;
						mouseLoc.y -= offset.y;
						
						switch ([theEvent type]) {
							case NSRightMouseUp:		//Done Tracking Clickscr
							case NSLeftMouseUp:
								//If we were still inside the link, draw unclicked and open link
								if (_mouseInRects(mouseLoc, linkRects, linkCount, NO)) {
									[[NSWorkspace sharedWorkspace] openURL:linkURL];
								}
								[textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:linkRange];
								[controlView setNeedsDisplay:YES];
								done = YES;
								break;
							case NSLeftMouseDragged:	//Mouse Moved
							case NSRightMouseDragged:
								//Check if we crossed the link region edge
								if (_mouseInRects(mouseLoc, linkRects, linkCount, NO) && inRects == NO) {
									[textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:linkRange];
									[controlView setNeedsDisplay:YES];
									inRects = YES;
								} else if (!_mouseInRects(mouseLoc, linkRects, linkCount, NO) && inRects == YES) {
									[textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:linkRange];
									[controlView setNeedsDisplay:YES];
									inRects = NO;
								}
								break;
							default:
								break;
						}
					}
					success = YES;
				}
			}
			
		}
		
    }
	
    //Free our copy of the link region
    if (linkRects) free(linkRects);
    return success;
}

//Init
- (id)initForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer
{
	if ((self = [super init])) {
		linkArray = nil;
		mouseOverLink = NO;
		hoveredLink = nil;
		hoveredString = nil;
		showTooltip = YES;

		controlView = inControlView;
		textStorage = inTextStorage;
		layoutManager = inLayoutManager;
		textContainer = inTextContainer;
	}

    return self;
}

//Dealloc
- (void)dealloc
{
    [self _endCursorTracking];
}

//Begins cursor tracking, registering tracking rects for all our available links
- (void)_beginCursorTrackingInRect:(NSRect)visibleRect withOffset:(NSPoint)offset
{
    NSRect		visibleContainerRect;
    NSRange		visibleGlyphRange, visibleCharRange;
    NSRange 	scanRange;

    //Get the range of visible characters
    visibleContainerRect = visibleRect;
    visibleContainerRect.origin.x -= offset.x;
    visibleContainerRect.origin.y -= offset.y;
    visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:visibleContainerRect inTextContainer:textContainer];
    visibleCharRange = [layoutManager characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:NULL];

    //Process all links
    scanRange = NSMakeRange(visibleCharRange.location, 0);
    while (NSMaxRange(scanRange) < NSMaxRange(visibleCharRange)) {
        NSString	*linkURL;

        //Get the link URL
        linkURL = [textStorage attribute:NSLinkAttributeName
                                 atIndex:NSMaxRange(scanRange)
                          effectiveRange:&scanRange];
		
		
		// The string might already have been filtered (i.e. in Context objects)
		if ( [linkURL isKindOfClass:[NSURL class]] ) {
			linkURL = [(NSURL *)linkURL absoluteString];
		}
		
		if (linkURL) {
            NSRectArray linkRects;
            unsigned	idx;
            NSUInteger	linkCount;
			
            //Get an array of rects that define the location of this link
            linkRects = [layoutManager rectArrayForCharacterRange:scanRange
                                     withinSelectedCharacterRange:NSMakeRange(NSNotFound, 0)
                                                  inTextContainer:textContainer
                                                        rectCount:&linkCount];
            for (idx = 0; idx < linkCount; idx++) {
                NSRect			linkRect;
                NSRect			visibleLinkRect;
                AIFlexibleLink		*trackedLink;
                NSTrackingRectTag	trackingTag;

                //Get the link rect
                linkRect = linkRects[idx];

                //Adjust the link rect back to our view's coordinates
                linkRect.origin.x += offset.x;
                linkRect.origin.y += offset.y;
                visibleLinkRect = NSIntersectionRect(linkRect, visibleRect);
                
                //Create a flexible link instance
                trackedLink = [[AIFlexibleLink alloc] initWithTrackingRect:linkRect
																 url:linkURL
															   title:[[textStorage string] substringWithRange:scanRange]];
                if (!linkArray) linkArray = [[NSMutableArray alloc] init];
                [linkArray addObject:trackedLink];

				
                //Install a tracking rect for the link (The userData of each tracking rect is the AIFlexibleLink it covers)
                trackingTag = [controlView addTrackingRect:visibleLinkRect owner:self userData:(__bridge void *)trackedLink assumeInside:NO];
                [trackedLink setTrackingTag:trackingTag];
            }
        }
    }
}

//Stops cursor tracking, removing all cursor rects
- (void)_endCursorTracking
{
    //Remove all existing tracking rects
    for (AIFlexibleLink *trackedLink in linkArray) {
        [controlView removeTrackingRect:[trackedLink trackingTag]];
    }

    //Flush the link array
	linkArray = nil;
}

//Configure the mouse for being over a link or not
- (void)_setMouseOverLink:(AIFlexibleLink *)inHoveredLink atPoint:(NSPoint)inPoint
{
    if (inHoveredLink != nil && mouseOverLink == NO) {
        //Keep track of the hovered link/string
        mouseOverLink = YES;

        [[NSCursor pointingHandCursor] set]; //Set link cursor

		//If the link's title matches its URL, there is no need to show the tooltip.
		if (showTooltip &&
		   [[inHoveredLink title] caseInsensitiveCompare:[inHoveredLink url]] != NSOrderedSame &&
		   [[@"http://" stringByAppendingString:[inHoveredLink title]] caseInsensitiveCompare:[inHoveredLink url]] != NSOrderedSame) {
			
			hoveredLink = inHoveredLink;
			hoveredString = [NSString stringWithFormat:@"%@", [hoveredLink url]];
			
			[AITooltipUtilities showTooltipWithString:hoveredString onWindow:nil atPoint:inPoint orientation:TooltipAbove]; //Show tooltip
		}
		
	} else if (inHoveredLink == nil && mouseOverLink == YES) {
        [[NSCursor arrowCursor] set]; //Restore the regular cursor
        
        if (showTooltip) {
            [AITooltipUtilities showTooltipWithString:nil onWindow:nil atPoint:NSMakePoint(0,0) orientation:TooltipAbove]; //Hide the tooltip
			
            hoveredLink = nil;
            hoveredString = nil;
        }

        mouseOverLink = NO;
    }

}

//Check for the presence of a point in multiple rects
BOOL _mouseInRects(NSPoint aPoint, NSRectArray someRects, NSUInteger arraySize, BOOL flipped)
{
    int	idx;

    for (idx = 0; idx < arraySize; idx++) {
        if (NSMouseInRect(aPoint, someRects[idx], flipped)) {
            return YES;
        }
    }

    return NO;
}

//Copy rects
NSRectArray _copyRectArray(NSRectArray someRects, NSUInteger arraySize)
{
    NSRectArray		newArray;

    newArray = malloc(sizeof(NSRect)*arraySize);
    memcpy( newArray, someRects, sizeof(NSRect)*arraySize );
    return newArray;
}

- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent withOffset:(NSPoint)offset
{
	NSMutableArray	*menuItemsArray = nil;
    NSURL			*linkURL = nil;

    //If a linKURL was created, add menu items for it to the menuItemsArray
    if (linkURL) {
        NSMenuItem  *menuItem;
        
        menuItemsArray = [[NSMutableArray alloc] init];
        menuItem = [[NSMenuItem alloc] initWithTitle:COPY_LINK
                                               target:self
                                               action:@selector(copyLink:)
                                        keyEquivalent:@""];
        [menuItem setRepresentedObject:linkURL];
        [menuItemsArray addObject:menuItem];
    }

    return menuItemsArray;
}

//Copy the absolute URL to the clipboard
- (void)copyLink:(id)sender
{
    NSAttributedString *copyString = [[NSAttributedString alloc] initWithString:[(NSURL *)[sender representedObject] absoluteString] attributes:nil];
    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSRTFPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setData:[copyString RTFFromRange:NSMakeRange(0,[copyString length]) documentAttributes:nil] forType:NSRTFPboardType];
}
@end
