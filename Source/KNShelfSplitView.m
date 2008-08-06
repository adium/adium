/*

BSD License

Copyright (c) 2006, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

/*
 * Modified to have a glass-style background; this requires the sourceListBackground image.
 */

#import "KNShelfSplitView.h"

#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIAdium.h>

#define DEFAULT_SHELF_WIDTH 200
#define CONTROL_HEIGHT 22
#define BUTTON_WIDTH 30
#define THUMB_WIDTH 15
#define THUMB_LINE_SPACING 2.0
#define RESIZE_BAR_EFFECTIVE_WIDTH 1.0

#define CONTROL_PART_NONE 0
#define CONTROL_PART_ACTION_BUTTON 1
#define CONTROL_PART_CONTEXT_BUTTON 2
#define CONTROL_PART_RESIZE_THUMB 3
#define CONTROL_PART_RESIZE_BAR 4

#define TOOLBAR_TOGGLESHELF_IDENTIFIER @"Toggle Shelf"
#define TOGGLESHELF @"Toggle Shelf"
@implementation KNShelfSplitView

+ (void)initialize
{
	if ((self == [KNShelfSplitView class])) {
		[self exposeBinding:@"contextButtonMenu"];
	}
}


-(IBAction)toggleShelf:(id)sender
{
	#pragma unused(sender)
	[self setShelfIsVisible: ![self isShelfVisible]];
	[self setNeedsDisplay: YES];
}

- (id)initWithFrame:(NSRect)aFrame {
	return [self initWithFrame: aFrame shelfView: nil contentView: nil];
}

-(id)initWithFrame:(NSRect)aFrame shelfView:(NSView *)aShelfView contentView:(NSView *)aContentView{
	self = [super initWithFrame: aFrame];
	if( self ){
		
		currentShelfWidth = DEFAULT_SHELF_WIDTH; //change this
		prevShelfWidthBeforeDoubleClick = currentShelfWidth;
		isShelfVisible = YES;
		shouldHilite = NO;
		activeControlPart = CONTROL_PART_NONE;
		contextButtonMenu = nil;
		[self recalculateSizes];
		
		autosaveName = nil;
		shelfBackgroundColor = nil;
		actionButtonImage = nil;
		contextButtonImage = nil;
		
		background = [[NSImage imageNamed:@"sourceListBackground" forClass:[self class]] retain];
		backgroundSize = [background size];

		[self setDelegate: nil];
		target = nil;
		action = nil;
	
		[self setShelfView: aShelfView];
		[self setContentView: aContentView];
	}
	return self;
}


-(void)dealloc{
	if( autosaveName ){ [autosaveName release]; }
	if( contextButtonImage ){ [contextButtonImage release]; }
	if( actionButtonImage ){ [actionButtonImage release]; }
	if( shelfBackgroundColor ){ [shelfBackgroundColor release]; }
	if( contextButtonMenu ){ [contextButtonMenu release]; }
	if( background ){ [background release]; }
	
	[self unbind:@"contextButtonMenu"];

	[super dealloc];
}

-(void)setDelegate:(id)aDelegate{
	delegate = aDelegate;
	
	delegateHasValidateWidth = NO;
	
	if( delegate ){
		if( [delegate respondsToSelector:@selector(shelfSplitView:validateWidth:)] ){
			delegateHasValidateWidth = YES;
		}
	}
}

-(id)delegate{
	return delegate;
}

-(void)setTarget:(id)aTarget{
	target = aTarget;
	[self recalculateSizes];
}

-(id)target{
	return target;
}

-(void)setAction:(SEL)aSelector{
	action = aSelector;
	[self recalculateSizes];
}

-(SEL)action{
	return action;
}

-(void)setContextButtonMenu:(NSMenu *)aMenu{
	if( contextButtonMenu ){
		[contextButtonMenu autorelease];
		[[NSNotificationCenter defaultCenter] removeObserver: self];
	}
	
	contextButtonMenu = [aMenu retain];
	
	if( contextButtonMenu ){
		[contextButtonMenu setDelegate: self];
		[[NSNotificationCenter defaultCenter] addObserver: self
			selector: @selector(didEndContextMenuTracking)
			name: NSMenuDidEndTrackingNotification
			object: contextButtonMenu
		];
	}

	[self recalculateSizes];
}

-(void)didEndContextMenuTracking{
	shouldHilite = NO;
	[self setNeedsDisplayInRect: controlRect];
}

-(NSMenu *)contextButtonMenu{
	return contextButtonMenu;
}

-(void)setShelfView:(NSView *)aView{
	if( shelfView ){
		[shelfView removeFromSuperview];
	}
	
	shelfView = aView;
	
	if( shelfView ){
		[self addSubview: shelfView];
	}
	[self recalculateSizes];
}

-(NSView *)shelfView{
	return shelfView;
}

-(void)setContentView:(NSView *)aView{
	if( contentView ){
		[contentView removeFromSuperview];
	}
	
	contentView = aView;
	
	if( contentView ){
		[self addSubview: contentView];
	}
	
	[self recalculateSizes];
}

-(NSView *)contentView{
	return contentView;
}

-(void)setShelfWidthNoConstraints:(float)aWidth
{
	currentShelfWidth = aWidth;
	
	[self recalculateSizes];	
}

-(void)setShelfWidth:(float)aWidth{
	float newWidth = aWidth;

	// The shelf can never be completely closed. We always have at least enough to show our resize thumb, otherwise
	// if the delegate responds to shelfSplitView:validateWidth:, we use that width as our minimum shelf size
	float				minShelf = THUMB_WIDTH;
	if( delegateHasValidateWidth ){
		float				requestedWidth = [delegate shelfSplitView:self validateWidth: aWidth];
		if( requestedWidth > minShelf ){
			minShelf = requestedWidth;
		}
	}
	
	if( minShelf > newWidth ){
		newWidth = minShelf;
	}
	
	// The shelf can never be wider than half the entire view
	float maxShelf = [self frame].size.width / 2;
	
	if( newWidth > maxShelf ){
		newWidth = maxShelf;
	}
	
	currentShelfWidth = newWidth;
	
	[self recalculateSizes];
}

-(float)shelfWidth{
	return currentShelfWidth;
}

-(void)setAutosaveName:(NSString *)aName{
	if( autosaveName ){
		[autosaveName autorelease];
	}
	autosaveName = [aName retain];
}

-(NSString *)autosaveName{
	return autosaveName;
}

-(void)recalculateSizes{	
	if( isShelfVisible ){
		controlRect = NSMakeRect( 0, 0, currentShelfWidth, CONTROL_HEIGHT );
		
		resizeThumbRect = NSMakeRect( (controlRect.size.width - THUMB_WIDTH), 0, THUMB_WIDTH, CONTROL_HEIGHT );
		resizeBarRect = NSMakeRect( currentShelfWidth - (RESIZE_BAR_EFFECTIVE_WIDTH / 2), 0, RESIZE_BAR_EFFECTIVE_WIDTH, [self frame].size.height );
		
		float availableSpace = controlRect.size.width - THUMB_WIDTH;
		
		if( target && action && (availableSpace > BUTTON_WIDTH) ){
			shouldDrawActionButton = YES;
			actionButtonRect = NSMakeRect( 0, 0, BUTTON_WIDTH, CONTROL_HEIGHT );
			availableSpace -= BUTTON_WIDTH;
		}
		
		if( contextButtonMenu && [contextButtonMenu numberOfItems] && (availableSpace > BUTTON_WIDTH) ){
			shouldDrawContextButton = YES;
			contextButtonRect = NSMakeRect(controlRect.size.width - (THUMB_WIDTH + availableSpace), 0, BUTTON_WIDTH, CONTROL_HEIGHT);
		}
	}
	
	if( shelfView ){
		[shelfView setFrame: NSMakeRect( 0, CONTROL_HEIGHT + 1, currentShelfWidth, [self bounds].size.height - (CONTROL_HEIGHT + 1) )];
	}
	
	if( contentView ){
		float contentViewX = (isShelfVisible ? (currentShelfWidth + 1) : 0);
		NSRect newRect = NSMakeRect(contentViewX, 0, NSWidth([self bounds]) - contentViewX, NSHeight([self bounds]));
		if (!NSEqualRects(newRect, [contentView frame])){
			[contentView setFrame:newRect];
		}
	}
	
	[self setNeedsDisplay: YES];
	[[self window] invalidateCursorRectsForView: self];
	
}

-(BOOL)isShelfVisible{
	return isShelfVisible;
}

-(void)setShelfIsVisible:(BOOL)visible{
	if( shelfView ){
		if( isShelfVisible && !visible ){
			[shelfView retain];
			[shelfView removeFromSuperview];
		} else if( !isShelfVisible && visible ){
			[self addSubview: shelfView];
			[shelfView release];
		}
	}

	isShelfVisible = visible;
	[self recalculateSizes];
}

-(void)setActionButtonImage:(NSImage *)anImage{
	if( actionButtonImage ){
		[actionButtonImage autorelease];
	}
	
	actionButtonImage = [anImage retain];
	
	[self setNeedsDisplayInRect: controlRect];
}

-(NSImage *)actionButtonImage{
		return actionButtonImage;
}

-(void)setContextButtonImage:(NSImage *)anImage{
	if( contextButtonImage ){
		[contextButtonImage autorelease];
	}
	
	contextButtonImage = [anImage retain];
	
	[self setNeedsDisplayInRect: controlRect];
}

-(NSImage *)contextButtonImage{
	return contextButtonImage;
}

-(void)setShelfBackgroundColor:(NSColor *)aColor{
	if( shelfBackgroundColor ){
		[shelfBackgroundColor autorelease];
	}
	
	shelfBackgroundColor = [aColor retain];
	[self setNeedsDisplay: YES];
}

-(NSColor *)shelfBackgroundColor{
	return shelfBackgroundColor;
}

-(void)resetCursorRects{
	[super resetCursorRects];
	if( isShelfVisible ){
		[self addCursorRect: resizeThumbRect cursor: [NSCursor resizeLeftRightCursor]];
		[self addCursorRect: resizeBarRect cursor: [NSCursor resizeLeftRightCursor]];
	}
}

-(void)mouseDown:(NSEvent *)anEvent{
	BOOL					stillMouseDown = YES;
	NSPoint					currentLocation;

	// determine if we're in a control part we care about
	currentLocation = [self convertPoint: [anEvent locationInWindow] fromView: nil];
	
	if( shouldDrawActionButton && NSPointInRect( currentLocation, actionButtonRect ) ){
		activeControlPart = CONTROL_PART_ACTION_BUTTON;
		shouldHilite = YES;
	}else if( shouldDrawContextButton && NSPointInRect( currentLocation, contextButtonRect ) ){
		activeControlPart = CONTROL_PART_CONTEXT_BUTTON;
		shouldHilite = YES;
		
		NSEvent *			contextEvent = [NSEvent mouseEventWithType: [anEvent type]
												location: NSMakePoint( contextButtonRect.origin.x + (contextButtonRect.size.width / 2) , contextButtonRect.origin.y + (contextButtonRect.size.height / 2) )
												modifierFlags: [anEvent modifierFlags]
												timestamp: [anEvent timestamp]
												windowNumber: [anEvent windowNumber]
												context: [anEvent context]
												eventNumber: [anEvent eventNumber]
												clickCount: [anEvent clickCount]
												pressure: [anEvent pressure]
											];
		[self setNeedsDisplayInRect: controlRect];
		[NSMenu popUpContextMenu: contextButtonMenu withEvent: contextEvent forView: self];
		[super mouseDown: contextEvent];
		return;
		
	}else if( NSPointInRect( currentLocation, resizeThumbRect ) ){
		activeControlPart = CONTROL_PART_RESIZE_THUMB;
	}else if( NSPointInRect( currentLocation, resizeBarRect ) ){
		activeControlPart = CONTROL_PART_RESIZE_BAR;
	}else{
		activeControlPart = CONTROL_PART_NONE;
	}
	
	[self setNeedsDisplayInRect: controlRect];

	if( activeControlPart != CONTROL_PART_NONE ){
		if([anEvent clickCount] == 2){
			if( (activeControlPart == CONTROL_PART_RESIZE_THUMB) || (activeControlPart == CONTROL_PART_RESIZE_BAR) ){
				if (currentShelfWidth > NSWidth(resizeBarRect)) {
					prevShelfWidthBeforeDoubleClick = currentShelfWidth;
					[self setShelfWidthNoConstraints:NSWidth(resizeBarRect)];
				} else {
					[self setShelfWidth:prevShelfWidthBeforeDoubleClick];
				}
			}

		} else {
		while( stillMouseDown ){
			anEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
			currentLocation = [self convertPoint: [anEvent locationInWindow] fromView: nil];
			shouldHilite = NO;
			
			if( (activeControlPart == CONTROL_PART_ACTION_BUTTON) && NSPointInRect( currentLocation, actionButtonRect ) ){
				shouldHilite = YES;
			}else if( (activeControlPart == CONTROL_PART_CONTEXT_BUTTON) && NSPointInRect( currentLocation, contextButtonRect ) ){
				shouldHilite = YES;
			}
			
			switch( [anEvent type] ){
				case NSLeftMouseDragged:
					if( (activeControlPart == CONTROL_PART_RESIZE_THUMB) || (activeControlPart == CONTROL_PART_RESIZE_BAR) ){
						[self setShelfWidth: currentLocation.x];
					}else{
						[self setNeedsDisplayInRect: controlRect];
					}
					break;
					
				case NSLeftMouseUp:
					shouldHilite = NO;
					[self setNeedsDisplayInRect: controlRect];
					
					if( (activeControlPart == CONTROL_PART_ACTION_BUTTON) && NSPointInRect( currentLocation, actionButtonRect ) ){
						// trigger an action
						if( target && action && [target respondsToSelector:action]){
							[target performSelector: action withObject: self];
						}
					}					
					stillMouseDown = NO;
					
					break;
					
				default:
					break;
			}
		}
	}
	}else{
		[super mouseDown:anEvent];
	}
}

- (void)drawRect:(NSRect)rect {
#pragma unused( rect )
	
		if( isShelfVisible ){
		//NSLog(@"Drawing Control( %f, %f) (%f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
		
		float remainderStart = 0.0;
		
		// action button
		if( shouldDrawActionButton  == YES){
			[self drawControlBackgroundInRect: actionButtonRect
				active: (activeControlPart == CONTROL_PART_ACTION_BUTTON) && shouldHilite
			];
			[[NSColor windowFrameColor] set];
		//	NSRectFill( NSMakeRect( (actionButtonRect.origin.x + actionButtonRect.size.width) - 1, 0, 1, controlRect.size.height ) );
			remainderStart += actionButtonRect.size.width;
			
			if( actionButtonImage ){
				
				NSRect			targetRect = NSMakeRect(actionButtonRect.origin.x,
														actionButtonRect.origin.y,
														[actionButtonImage size].width, 
														[actionButtonImage size].height
											);
				
				if( targetRect.size.width > actionButtonRect.size.width ){
					targetRect.size.width = actionButtonRect.size.width;
				}
				if( targetRect.size.width < actionButtonRect.size.width ){
					targetRect.origin.x += (actionButtonRect.size.width - targetRect.size.width) / 2.0;
				}
				if( targetRect.size.height > actionButtonRect.size.height ){
					targetRect.size.height = actionButtonRect.size.height;
				}
				if( targetRect.size.height < actionButtonRect.size.height ){
					targetRect.origin.y += (actionButtonRect.size.height - targetRect.size.height) / 2.0;
				}
				
				[actionButtonImage compositeToPoint:NSMakePoint(actionButtonRect.origin.x,
														actionButtonRect.origin.y) operation:NSCompositeDestinationAtop];

	
			}
		}
		
		// context button
		
		if( shouldDrawContextButton ){
			[self drawControlBackgroundInRect: contextButtonRect
				active: (activeControlPart == CONTROL_PART_CONTEXT_BUTTON ) && shouldHilite
			];
			[[NSColor windowFrameColor] set];
			NSRectFill( NSMakeRect( (contextButtonRect.origin.x + contextButtonRect.size.width) - 1, 0, 1, controlRect.size.height ) );
			remainderStart += contextButtonRect.size.width;
			
			if( contextButtonImage ){
		
				NSRect			targetRect = NSMakeRect(contextButtonRect.origin.x,
														contextButtonRect.origin.y,
														[contextButtonImage size].width, 
														[contextButtonImage size].height
											);
				
				if( targetRect.size.width > contextButtonRect.size.width ){
					targetRect.size.width = contextButtonRect.size.width;
				}
				if( targetRect.size.width < contextButtonRect.size.width ){
					targetRect.origin.x += (contextButtonRect.size.width - targetRect.size.width) / 2.0;
				}
				if( targetRect.size.height > contextButtonRect.size.height ){
					targetRect.size.height = contextButtonRect.size.height;
				}
				if( targetRect.size.height < contextButtonRect.size.height ){
					targetRect.origin.y += (contextButtonRect.size.height - targetRect.size.height) / 2.0;
				}
				[contextButtonImage drawInRect: targetRect
					fromRect: NSMakeRect( 0, 0, [contextButtonImage size].width, [contextButtonImage size].height )
					operation: NSCompositeSourceOver
					fraction: 1.0f
				]; 
			}
		}
		
		//remainder and thumb
		[self drawControlBackgroundInRect:NSMakeRect( remainderStart, 0, (controlRect.size.width - remainderStart), controlRect.size.height )
								   active:NO];

		[[NSColor windowFrameColor] set];
		NSRectFill( NSMakeRect( 0, CONTROL_HEIGHT, currentShelfWidth, 1 ) );
		
		// Draw our split line
		[[NSColor windowFrameColor] set];
		NSRectFill( NSMakeRect( currentShelfWidth, 0, 1, [self frame].size.height ) );
		
		// Draw our thumb lines
		[[NSColor disabledControlTextColor] set];
		NSRect			thumbLineRect = NSMakeRect( 
											resizeThumbRect.origin.x + (resizeThumbRect.size.width - ((2*THUMB_LINE_SPACING) + 3.0)) / 2.0, 
											resizeThumbRect.size.height / 4.0, 
											1.0, 
											resizeThumbRect.size.height / 2.0
										);
		int i;
		for( i=0; i<3; i++ ){
			NSRectFill( thumbLineRect );
			thumbLineRect.origin.x += (1+THUMB_LINE_SPACING);
		}
		
		if( shelfBackgroundColor ){
			[shelfBackgroundColor set];
			NSRectFill( NSMakeRect( 0, CONTROL_HEIGHT+1, currentShelfWidth, [self frame].size.height ) );
		}
		
		//Draw the string
		if (attributedStringValue && !shouldDrawContextButton && !shouldDrawActionButton) {
			NSRect	textRect = NSMakeRect(6, (NSHeight(controlRect) - stringHeight)/2, NSMinX(resizeThumbRect) - 8, stringHeight);
			
			[attributedStringValue drawInRect:textRect];
		} 
	}
}

-(void)drawControlBackgroundInRect:(NSRect)aRect active:(BOOL)isActive{	
	//Draw the background, tiling across
    NSRect sourceRect = NSMakeRect(0, 0, backgroundSize.width, backgroundSize.height);
    NSRect destRect = NSMakeRect(aRect.origin.x, aRect.origin.y, sourceRect.size.width, aRect.size.height);
	
    while ((destRect.origin.x < NSMaxX(aRect)) && destRect.size.width > 0) {
        //Crop
        if (NSMaxX(destRect) > NSMaxX(aRect)) {
			destRect.size.width = NSMaxX(aRect) - NSMinX(destRect);
            sourceRect.size.width = NSWidth(destRect);
        }
		
        [background drawInRect:destRect
					  fromRect:sourceRect
					 operation:NSCompositeSourceOver
					  fraction:1.0];
        destRect.origin.x += destRect.size.width;
    }
}

-(void)setFrame:(NSRect)aRect{
	[super setFrame: aRect];
	[self recalculateSizes];
}

#pragma mark Status string
- (void)setResizeThumbStringValue:(NSString *)inString
{
	if (![inString isEqualToString:stringValue]) {
		[stringValue release];
		stringValue = [inString copy];
		
		[attributedStringValue release];
		if (stringValue) {
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSParagraphStyle styleWithAlignment:NSLeftTextAlignment
									   lineBreakMode:NSLineBreakByTruncatingTail], NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, 
				nil];
			
			stringHeight = [NSAttributedString stringHeightForAttributes:attributes];
			attributedStringValue = [[NSAttributedString alloc] initWithString:stringValue
																	attributes:attributes];
		} else {
			attributedStringValue = nil;
		}
		[self setNeedsDisplay:YES];
	}
}

@end
