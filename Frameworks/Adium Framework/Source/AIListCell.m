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

#import <Adium/AIListCell.h>

#import <Adium/AIListGroup.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIListOutlineView.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>

#import <Adium/AIStatusControllerProtocol.h>

#import <AIUtilities/AITigerCompatibility.h>

//#define	ORDERING_DEBUG

@implementation AIListCell

static NSMutableParagraphStyle	*leftParagraphStyleWithTruncatingTail = nil;

//Init
- (id)init
{
    if ((self = [super init]))
	{
		   topSpacing = 
		bottomSpacing = 
		  leftSpacing = 
		 rightSpacing = 0;

		   topPadding = 
		bottomPadding = 
		  leftPadding = 
		 rightPadding = 0;
		
		font = [[NSFont systemFontOfSize:12] retain];
		textColor = [[NSColor blackColor] retain];
		invertedTextColor = [[NSColor whiteColor] retain];
		
		useAliasesAsRequested = YES;

		if (!leftParagraphStyleWithTruncatingTail) {
			leftParagraphStyleWithTruncatingTail = [[NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																				  lineBreakMode:NSLineBreakByTruncatingTail] retain];
		}
		
	}
		
    return self;
}

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListCell *newCell = [super copyWithZone:zone];

	newCell->listObject = nil;
	[newCell setListObject:listObject];

	[newCell->font retain];
	[newCell->textColor retain];
	[newCell->invertedTextColor retain];

	return newCell;
}

//Dealloc
- (void)dealloc
{
	[textColor release];
	[invertedTextColor release];
	
	[font release];
	
	[listObject release];

	[super dealloc];
}

//Set the list object being drawn
- (void)setListObject:(AIListObject *)inObject
{
	if (inObject != listObject) {
		[listObject release];
		listObject = [inObject retain];

		isGroup = [listObject isKindOfClass:[AIListGroup class]];
	}
}
- (BOOL)isGroup{
	return isGroup;
}

//Set our control view (Better than passing this around like crazy)
- (void)setControlView:(AIListOutlineView *)inControlView
{
	controlView = inControlView;
}

//Return that this cell is draggable
- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	return NSCellHitContentArea;
}

//Display options ------------------------------------------------------------------------------------------------------
#pragma mark Display options
//Font used to display label
- (void)setFont:(NSFont *)inFont
{
	if (inFont != font) {
		[font release];
		font = [inFont retain];
	}

	//Calculate and cache the height of this font
	labelFontHeight = [[[[NSLayoutManager alloc] init] autorelease] defaultLineHeightForFont:[self font]]; 
}
- (NSFont *)font{
	return font;
}

//Alignment of label text
- (void)setTextAlignment:(NSTextAlignment)inAlignment
{
	textAlignment = inAlignment;
}
- (NSTextAlignment)textAlignment{
	return textAlignment;
}

//Text color
- (void)setTextColor:(NSColor *)inColor
{
	if (inColor != textColor) {
		[textColor release];
		textColor = [inColor retain];
	}
}
- (NSColor *)textColor{
	return textColor;
}

- (void)setInvertedTextColor:(NSColor *)inColor
{
	if (inColor != invertedTextColor) {
		[invertedTextColor release];
		invertedTextColor = [inColor retain];
	}
}
- (NSColor *)invertedTextColor{
	return invertedTextColor;
}


//Cell sizing and padding ----------------------------------------------------------------------------------------------
#pragma mark Cell sizing and padding
//Default cell size just contains our padding and spacing
- (NSSize)cellSize
{
	return NSMakeSize(0, [self topSpacing] + [self topPadding] + [self bottomPadding] + [self bottomSpacing]);
}

- (int)cellWidth
{
	return [self leftSpacing] + [self leftPadding] + [self rightPadding] + [self rightSpacing];
}

//User-defined spacing offsets.  A cell may adjust these values to to obtain a more desirable default. 
//These are offsets, they may be negative!  Spacing is the distance between cells (Spacing gaps are not filled).
- (void)setSplitVerticalSpacing:(int)inSpacing{
	topSpacing = inSpacing / 2;
	bottomSpacing = (inSpacing + 1) / 2;
}
- (void)setTopSpacing:(int)inSpacing{
	topSpacing = inSpacing;
}
- (int)topSpacing{
	return topSpacing;
}
- (void)setBottomSpacing:(int)inSpacing{
	bottomSpacing = inSpacing;
}
- (int)bottomSpacing{
	return bottomSpacing;
}
- (void)setLeftSpacing:(int)inSpacing{
	leftSpacing = inSpacing;
}
- (int)leftSpacing{
	return leftSpacing;
}
- (void)setRightSpacing:(int)inSpacing{
	rightSpacing = inSpacing;
}
- (int)rightSpacing{
	return rightSpacing;
}

//User-defined padding offsets.  A cell may adjust these values to to obtain a more desirable default.
//These are offsets, they may be negative!  Padding is the distance between cell edges and their content.
- (void)setSplitVerticalPadding:(int)inPadding{
	topPadding = inPadding / 2;
	bottomPadding = (inPadding + 1) / 2;
}
- (void)setTopPadding:(int)inPadding{
	topPadding = inPadding;
}
- (void)setBottomPadding:(int)inPadding{
	bottomPadding = inPadding;
}
- (int)topPadding{
	return topPadding;
}
- (int)bottomPadding{
	return bottomPadding;
}
- (void)setLeftPadding:(int)inPadding{
	leftPadding = inPadding;
}
- (int)leftPadding{
	return leftPadding;
}
- (void)setRightPadding:(int)inPadding{
	rightPadding = inPadding;
}
- (int)rightPadding{
	return rightPadding;
}

- (void)setIndentation:(int)inIndentation{
	indentation = inIndentation;
}
- (int)indentation{
	return indentation;
}

//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)inControlView{
    [self drawInteriorWithFrame:cellFrame inView:inControlView];
}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)inControlView
{	
	if (listObject) {
		//Cell spacing
		cellFrame.origin.y += [self topSpacing];
		cellFrame.size.height -= [self bottomSpacing] + [self topSpacing];
		cellFrame.origin.x += [self leftSpacing];
		cellFrame.size.width -= [self rightSpacing] + [self leftSpacing];
		
		[self drawBackgroundWithFrame:cellFrame];

		//Padding
		cellFrame.origin.y += [self topPadding];
		cellFrame.size.height -= [self bottomPadding] + [self topPadding];
		cellFrame.origin.x += [self leftPadding];
		cellFrame.size.width -= [self rightPadding] + [self leftPadding];

		switch ([self textAlignment]) {
			case NSRightTextAlignment:
				//Right alignment indents on the right
				cellFrame.size.width -= [self indentation];
				break;
			default:
				//All other alignments indent on the left
				cellFrame.origin.x += [self indentation];
				cellFrame.size.width -= [self indentation];
				break;
		}
		[self drawContentWithFrame:cellFrame];
	}
}

#warning It's quite possible that we don't need to use this private method.
//Custom highlighting (This is a private cell method we're overriding that handles selection drawing)
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)inControlView
{
	AILogWithSignature(@"");
	//Cell spacing
	cellFrame.origin.y += [self topSpacing];
	cellFrame.size.height -= [self bottomSpacing] + [self topSpacing];
	cellFrame.origin.x += [self leftSpacing];
	cellFrame.size.width -= [self rightSpacing] + [self leftSpacing];
	
	[self drawSelectionWithFrame:cellFrame];
}

//Draw Selection
- (void)drawSelectionWithFrame:(NSRect)rect
{
	//
}
	
//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	//
}

//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	[self drawDisplayNameWithFrame:rect];
}

- (void)drawDropHighlightWithFrame:(NSRect)rect
{	
	[NSGraphicsContext saveGraphicsState];

	//Ensure we don't draw outside our rect
	[[NSBezierPath bezierPathWithRect:rect] addClip];
	
	rect.size.width -= DROP_HIGHLIGHT_WIDTH_MARGIN;
	rect.origin.x += DROP_HIGHLIGHT_WIDTH_MARGIN / 2.0;
	
	rect.size.height -= DROP_HIGHLIGHT_HEIGHT_MARGIN;
	rect.origin.y += DROP_HIGHLIGHT_HEIGHT_MARGIN / 2.0;

	NSBezierPath	*path = [NSBezierPath bezierPathWithRoundedRect:rect radius:4.0];

	[[[NSColor blueColor] colorWithAlphaComponent:0.2] set];
	[path fill];
	
	[[[NSColor blueColor] colorWithAlphaComponent:0.8] set];
	[path setLineWidth:2.0];
	[path stroke];

	[NSGraphicsContext restoreGraphicsState];	
}

//Draw our display name
- (NSRect)drawDisplayNameWithFrame:(NSRect)inRect
{
	NSAttributedString	*displayName = [[NSAttributedString alloc] initWithString:[self labelString]
																	   attributes:[self labelAttributes]];
																	   
	NSSize				nameSize = [displayName size];
	NSRect				rect = inRect;

	if (nameSize.width > rect.size.width) nameSize.width = rect.size.width;
	if (nameSize.height > rect.size.height) nameSize.height = rect.size.height;

	//Alignment
	switch ([self textAlignment]) {
		case NSCenterTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width) / 2.0;
		break;
		case NSRightTextAlignment:
			rect.origin.x += (rect.size.width - nameSize.width);
		break;
		default:
		break;
	}

	//Draw (centered vertical)
	int half = ceil((rect.size.height - labelFontHeight) / 2.0);
	[displayName drawInRect:NSMakeRect(rect.origin.x,
									   rect.origin.y + half,
									   rect.size.width,
									   nameSize.height)];
	[displayName release];

	//Adjust the drawing rect
	switch ([self textAlignment]) {
		case NSRightTextAlignment:
			inRect.size.width -= nameSize.width;
		break;
		case NSLeftTextAlignment:
			inRect.origin.x += nameSize.width;
			inRect.size.width -= nameSize.width;
		break;
		default:
		break;
	}
	
	return inRect;
}

//Display string for our list object
- (NSString *)labelString
{
	NSString *leftText = [listObject valueForProperty:@"Left Text"];
	NSString *rightText = [listObject valueForProperty:@"Right Text"];

	//Ordering debug
#ifdef ORDERING_DEBUG
	rightText = (rightText ?
				 [rightText stringByAppendingFormat:@" %f",[listObject orderIndex]] :
				 [NSString stringWithFormat:@" %f",[listObject orderIndex]]); 
#endif

	if (!leftText && !rightText) {
		return ([self shouldShowAlias] ? 
				[listObject longDisplayName] :
				([listObject formattedUID] ? [listObject formattedUID] : [listObject longDisplayName]));
	} else {
		//Combine left text, the object name, and right text
		return [NSString stringWithFormat:@"%@%@%@",
			(leftText ? leftText : @""),
			([self shouldShowAlias] ? [listObject longDisplayName] : ([listObject formattedUID] ?
																	 [listObject formattedUID] :
																	 [listObject longDisplayName])),
			(rightText ? rightText : @"")];
	}

}

- (BOOL)shouldShowAlias
{
	return useAliasesAsRequested;
}

- (void)setUseAliasesAsRequested:(BOOL)inFlag
{
	useAliasesAsRequested = inFlag;
}

//Attributes for displaying the label string
- (NSDictionary *)labelAttributes
{
	NSMutableDictionary	*labelAttributes;
	NSDictionary		*additionalAttributes = [self additionalLabelAttributes];
	NSColor				*currentTextColor = ([self cellIsSelected] ? [self invertedTextColor] : [self textColor]);

	[leftParagraphStyleWithTruncatingTail setMaximumLineHeight:(float)labelFontHeight];

	if (additionalAttributes) {
		labelAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			currentTextColor, NSForegroundColorAttributeName,
			leftParagraphStyleWithTruncatingTail, NSParagraphStyleAttributeName,
			[self font], NSFontAttributeName,
			nil];
		[labelAttributes addEntriesFromDictionary:additionalAttributes];

	} else {
		labelAttributes = (NSMutableDictionary *)[NSDictionary dictionaryWithObjectsAndKeys:
			currentTextColor, NSForegroundColorAttributeName,
			leftParagraphStyleWithTruncatingTail, NSParagraphStyleAttributeName,
			[self font], NSFontAttributeName,
			nil];
	}
	
	return labelAttributes;
}

//Additional attributes to apply to our label string (For Sub-Classes)
- (NSDictionary *)additionalLabelAttributes
{
	return nil;
}

//YES if our cell is currently selected
- (BOOL)cellIsSelected
{
	return ([self isHighlighted] &&
		   [[controlView window] isKeyWindow] &&
		   [[controlView window] firstResponder] == controlView);
}

//YES if a grid would be visible behind this cell (needs to be drawn)
- (BOOL)drawGridBehindCell
{
	return YES;
}

//The background color for this cell.  This will either be [controlView backgroundColor] or [controlView alternatingGridColor]
- (NSColor *)backgroundColor
{
	//We could just call backgroundColorForRow: but it's best to avoid doing a rowForItem lookup if there is no grid
	if ([controlView drawsAlternatingRows]) {
		return [controlView backgroundColorForRow:[controlView rowForItem:listObject]];
	} else {
		return [controlView backgroundColor];
	}
}

#pragma mark Accessibility

- (NSArray *)accessibilityAttributeNames
{
	AILogWithSignature(@"names: %@", [super accessibilityAttributeNames]);
	return [super accessibilityAttributeNames];
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	id value;

	AILogWithSignature(@"Asked %@ for %@", listObject, attribute);

	if([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		value = NSAccessibilityRowRole;
		
	} else if([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
		if ([listObject isKindOfClass:[AIListGroup class]]) {
			value = [NSString stringWithFormat:AILocalizedString(@"contact group %@", "%@ will be the name of a group in the contact list"), [listObject longDisplayName]];

		} else if ([listObject isKindOfClass:[AIListBookmark class]]) {			
			value = [NSString stringWithFormat:AILocalizedString(@"group chat bookmark %@", "%@ will be the name of a bookmark"), [listObject longDisplayName]];			

		} else {
			NSString *name, *statusDescription, *statusMessage;
			
			name = [listObject longDisplayName];
			statusDescription = [[adium statusController] localizedDescriptionForStatusName:([listObject statusName] ?
																					  [listObject statusName] :
																					  [[adium statusController] defaultStatusNameForType:[listObject statusType]])
																		  statusType:[listObject statusType]];
			statusMessage = [listObject statusMessageString];
			
			value = [[name mutableCopy] autorelease];
			if (statusDescription) [value appendFormat:@"; %@", statusDescription];
			if (statusMessage) [value appendFormat:AILocalizedString(@"; status message %@", "please keep the semicolon at the start of the line. %@ will be replaced by a status message. This is used when reading an entry in the contact list aloud, such as 'Evan Schoenberg; status message I am bouncing up and down'"), statusMessage];
		}

	} else if([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
		value = [self labelString];
		
	} else if([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
		value = [controlView window];
                
	} else {
		value = [super accessibilityAttributeValue:attribute];
	}

	return value;
}

@end
