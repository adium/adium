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

#import <Adium/AIListContactCell.h>
#import <Adium/AIListContact.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIUserIcons.h>

#define NAME_STATUS_PAD			6

#define HULK_CRUSH_FACTOR 1

//Selections
#define CONTACT_INVERTED_TEXT_COLOR		[NSColor whiteColor]
#define CONTACT_INVERTED_STATUS_COLOR	[NSColor whiteColor]

@implementation AIListContactCell

//Copy
- (id)copyWithZone:(NSZone *)zone
{
	AIListContactCell *newCell = [super copyWithZone:zone];

	newCell->statusFont = [statusFont retain];
	newCell->statusColor = [statusColor retain];
	newCell->_statusAttributes = [_statusAttributes retain];
	newCell->_statusAttributesInverted = [_statusAttributesInverted retain];

	return newCell;
}

//Init
- (id)init
{
    if ((self = [super init]))
	{
		backgroundOpacity = 1.0;
		statusFont = [[NSFont systemFontOfSize:12] retain];
		statusColor = nil;
		_statusAttributes = nil;
		_statusAttributesInverted = nil;
		shouldUseContactTextColors = YES;
		useStatusMessageAsExtendedStatus = NO;
	}

	return self;
}
	
//Dealloc
- (void)dealloc
{
	[statusFont release];
	[statusColor release];
	
	[_statusAttributes release];
	[_statusAttributesInverted release];
	
	[super dealloc];
}


//Cell sizing and padding ----------------------------------------------------------------------------------------------
#pragma mark Cell sizing and padding
//Size our cell to fit our content
- (NSSize)cellSize
{
	int		largestElementHeight;
		
	//Display Name Height (And status text if below name)
	if (extendedStatusVisible && (idleTimeIsBelow || statusMessageIsBelow)) {
		largestElementHeight = labelFontHeight + statusFontHeight;
	} else {
		largestElementHeight = labelFontHeight;
	}
	
	//User Icon Height
	if (userIconVisible) {
		if (userIconSize.height > largestElementHeight) {
			largestElementHeight = userIconSize.height;
		}
	}
	
	//Status text height (If beside name)
	if (extendedStatusVisible && !(idleTimeIsBelow || statusMessageIsBelow)) {
		if (statusFontHeight > largestElementHeight) {
			largestElementHeight = statusFontHeight;
		}
	}
	
	return NSMakeSize(0, [super cellSize].height + largestElementHeight);
}

- (int)cellWidth
{
	int		width = [super cellWidth];
	
	//Name
	NSMutableAttributedString	*displayName = [[NSMutableAttributedString alloc] initWithString:[self labelString] attributes:[self labelAttributes]];
	
	// Also account for idle times.
	if (extendedStatusVisible && idleTimeVisible && !idleTimeIsBelow && [listObject valueForProperty:@"IdleReadable"]) {
		NSString		*idleTimeString = [listObject valueForProperty:@"IdleReadable"];
		
		if (statusMessageVisible && !statusMessageIsBelow && [listObject statusMessageString]) {
			// Account for the size of the ellipsis if there's a status message.
			idleTimeString = [idleTimeString stringByAppendingEllipsis];
		}
		
		[displayName appendString:idleTimeString withAttributes:self.statusAttributes];
		width += NAME_STATUS_PAD;
	}

	width += ceil([displayName size].width);
	[displayName release];
		
	//User icon
	if (userIconVisible) {
		width += ceil(userIconSize.width);
		width += USER_ICON_LEFT_PAD + USER_ICON_RIGHT_PAD;
	}
	
	//Status icon
	if (statusIconsVisible &&
	   (statusIconPosition != LIST_POSITION_BADGE_LEFT && statusIconPosition != LIST_POSITION_BADGE_RIGHT)) {
		width += ceil([[self statusImage] size].width);
		width += STATUS_ICON_LEFT_PAD + STATUS_ICON_RIGHT_PAD;
	}

	//Service icon
	if (serviceIconsVisible &&
	   (serviceIconPosition != LIST_POSITION_BADGE_LEFT && serviceIconPosition != LIST_POSITION_BADGE_RIGHT)) {
		width += ceil([[self serviceImage] size].width);
		width += SERVICE_ICON_LEFT_PAD + SERVICE_ICON_RIGHT_PAD;
	}
	
	if ((userIconVisible && (userIconPosition == LIST_POSITION_FAR_LEFT || userIconPosition == LIST_POSITION_LEFT)) ||
		(serviceIconsVisible && (serviceIconPosition == LIST_POSITION_FAR_LEFT || serviceIconPosition == LIST_POSITION_LEFT)) ||
		(statusIconsVisible && (statusIconPosition == LIST_POSITION_FAR_LEFT || statusIconPosition == LIST_POSITION_LEFT))) {
		//Something is on the left. Give TEXT_WITH_IMAGES_LEFT_PAD between that and the display name
		width += TEXT_WITH_IMAGES_LEFT_PAD;
	}
	
	if ((userIconVisible && (userIconPosition == LIST_POSITION_FAR_RIGHT || userIconPosition == LIST_POSITION_RIGHT)) ||
		(serviceIconsVisible && (serviceIconPosition == LIST_POSITION_FAR_RIGHT || serviceIconPosition == LIST_POSITION_RIGHT)) ||
		(statusIconsVisible && (statusIconPosition == LIST_POSITION_FAR_RIGHT || statusIconPosition == LIST_POSITION_RIGHT))) {
		//Something is on the right. Give TEXT_WITH_IMAGES_LEFT_PAD between that and the display name
		width += TEXT_WITH_IMAGES_RIGHT_PAD;
	}

	return width + 1;
}


//Status Text ----------------------------------------------------------------------------------------------------------
#pragma mark Status Text
//Font used to display status text
- (void)setStatusFont:(NSFont *)inFont
{
	if (statusFont != inFont) {
		[statusFont release];
		statusFont = [inFont retain];
		
		//Calculate and cache the height of this font
		statusFontHeight = [[[[NSLayoutManager alloc] init] autorelease] defaultLineHeightForFont:[self statusFont]];
		
		//Flush the status attributes cache
		[_statusAttributes release]; _statusAttributes = nil;
	}
}
- (NSFont *)statusFont{
	return statusFont;
}

//Color of status text
- (void)setStatusColor:(NSColor *)inColor
{
	if (statusColor != inColor) {
		[statusColor release];
		statusColor = [inColor retain];

		//Flush the status attributes cache
		[_statusAttributes release]; _statusAttributes = nil;
	}
}
- (NSColor *)statusColor
{
	return statusColor;
}

//Attributes for displaying the status string (Cached)
//Cache is flushed when alignment, color, or font is changed
- (NSDictionary *)statusAttributes
{
	if (!_statusAttributes) {
		NSMutableParagraphStyle	*paragraphStyle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																				lineBreakMode:NSLineBreakByTruncatingTail];
		[paragraphStyle setMaximumLineHeight:(float)labelFontHeight];
		
		_statusAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
			paragraphStyle, NSParagraphStyleAttributeName,
			[self statusColor], NSForegroundColorAttributeName,
			[self statusFont], NSFontAttributeName,nil] retain];
	}
	
	if (backgroundColorIsEvents && [listObject boolValueForProperty:@"Is Event"]) {
		//If we are showing a temporary event with a custom background color, use the standard text color
		//since it will be appropriate to the current background color.
		NSMutableDictionary	*mutableStatusAttributes = [_statusAttributes mutableCopy];
		[mutableStatusAttributes setObject:[self textColor]
									forKey:NSForegroundColorAttributeName];

		return [mutableStatusAttributes autorelease];

	} else {
		return _statusAttributes;
	}
}

- (NSDictionary *)statusAttributesInverted
{
	if (!_statusAttributesInverted) {
		_statusAttributesInverted = [[self statusAttributes] mutableCopy];
		[_statusAttributesInverted setObject:CONTACT_INVERTED_STATUS_COLOR forKey:NSForegroundColorAttributeName];
	}
	
	return _statusAttributesInverted;
}

//Flush status attributes when alignment is changed
- (void)setTextAlignment:(NSTextAlignment)inAlignment
{
	[super setTextAlignment:inAlignment];
	[_statusAttributes release]; _statusAttributes = nil;
}

	
//Display options ------------------------------------------------------------------------------------------------------
#pragma mark Display options
//User Icon Visibility
- (void)setUserIconVisible:(BOOL)inShowIcon
{
	userIconVisible = inShowIcon;
}
- (BOOL)userIconVisible{
	return userIconVisible;
}

//User Icon Size
- (void)setUserIconSize:(int)inSize
{
	userIconSize = NSMakeSize(inSize, inSize);
	userIconRoundingRadius = (userIconSize.width / 4.0);
	if (userIconRoundingRadius > 3) userIconRoundingRadius = 3;
}

- (int)userIconSize{
	return userIconSize.height;
}

//Extended Status Visibility
- (void)setExtendedStatusVisible:(BOOL)inShowStatus
{
	extendedStatusVisible = inShowStatus;
}
- (BOOL)extendedStatusVisible{
	return extendedStatusVisible;
}

//Status Icon Visibility
- (void)setStatusIconsVisible:(BOOL)inShowStatus
{
	statusIconsVisible = inShowStatus;
}
- (BOOL)statusIconsVisible{
	return statusIconsVisible;
}

//Service Icon Visibility
- (void)setServiceIconsVisible:(BOOL)inShowService
{
	serviceIconsVisible = inShowService;
}
- (BOOL)serviceIconsVisible{
	return serviceIconsVisible;
}

//Element Positioning
- (void)setIdleTimeIsBelowName:(BOOL)isBelow{
	idleTimeIsBelow = isBelow;
}

- (void)setStatusMessageIsBelowName:(BOOL)isBelow{
	statusMessageIsBelow = isBelow;
}

- (void)setStatusMessageIsVisible:(BOOL)isVisible{
	statusMessageVisible = isVisible;
}
- (void)setIdleTimeIsVisible:(BOOL)isVisible{
	idleTimeVisible = isVisible;	
}

- (void)setUserIconPosition:(LIST_POSITION)inPosition{
	userIconPosition = inPosition;
}
- (void)setStatusIconPosition:(LIST_POSITION)inPosition{
	statusIconPosition = inPosition;
}
- (void)setServiceIconPosition:(LIST_POSITION)inPosition{
	serviceIconPosition = inPosition;
}

//Opacity
- (void)setBackgroundOpacity:(float)inOpacity
{
	backgroundOpacity = inOpacity;
}
- (float)backgroundOpacity{
	return backgroundOpacity;
}

//
- (void)setBackgroundColorIsStatus:(BOOL)isStatus
{
	backgroundColorIsStatus = isStatus;
}
- (void)setBackgroundColorIsEvents:(BOOL)isEvents
{
	backgroundColorIsEvents = isEvents;
}

- (void)setShouldUseContactTextColors:(BOOL)flag
{
	shouldUseContactTextColors = flag;
}

- (void)setUseStatusMessageAsExtendedStatus:(BOOL)flag
{
	useStatusMessageAsExtendedStatus = flag;
}

//Drawing --------------------------------------------------------------------------------------------------------------
#pragma mark Drawing
//Draw content of our cell
- (void)drawContentWithFrame:(NSRect)rect
{
	//Far Left
	if (statusIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_LEFT];
	if (serviceIconPosition == LIST_POSITION_FAR_LEFT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//User Icon [Left]
	if (userIconPosition == LIST_POSITION_LEFT) rect = [self drawUserIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//Left
	if (statusIconPosition == LIST_POSITION_LEFT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_LEFT];
	if (serviceIconPosition == LIST_POSITION_LEFT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_LEFT];
	
	//Far Right
	if (statusIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if (serviceIconPosition == LIST_POSITION_FAR_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//User Icon [Right]
	if (userIconPosition == LIST_POSITION_RIGHT) rect = [self drawUserIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	//Right
	if (statusIconPosition == LIST_POSITION_RIGHT) rect = [self drawStatusIconInRect:rect position:IMAGE_POSITION_RIGHT];
	if (serviceIconPosition == LIST_POSITION_RIGHT) rect = [self drawServiceIconInRect:rect position:IMAGE_POSITION_RIGHT];
	
	if ((userIconVisible && (userIconPosition == LIST_POSITION_FAR_LEFT || userIconPosition == LIST_POSITION_LEFT)) ||
		(serviceIconsVisible && (serviceIconPosition == LIST_POSITION_FAR_LEFT || serviceIconPosition == LIST_POSITION_LEFT)) ||
		(statusIconsVisible && (statusIconPosition == LIST_POSITION_FAR_LEFT || statusIconPosition == LIST_POSITION_LEFT))) {
		//Something is on the left. Give TEXT_WITH_IMAGES_LEFT_PAD between that and the display name
		rect.origin.x += TEXT_WITH_IMAGES_LEFT_PAD;
		rect.size.width -= TEXT_WITH_IMAGES_LEFT_PAD;
	}

	if ((userIconVisible && (userIconPosition == LIST_POSITION_FAR_RIGHT || userIconPosition == LIST_POSITION_RIGHT)) ||
		(serviceIconsVisible && (serviceIconPosition == LIST_POSITION_FAR_RIGHT || serviceIconPosition == LIST_POSITION_RIGHT)) ||
		(statusIconsVisible && (statusIconPosition == LIST_POSITION_FAR_RIGHT || statusIconPosition == LIST_POSITION_RIGHT))) {
		//Something is on the right. Give TEXT_WITH_IMAGES_LEFT_PAD between that and the display name
		rect.size.width -= TEXT_WITH_IMAGES_RIGHT_PAD;
	}

	// For the case of either in the same place, use the extended status.
	if (idleTimeIsBelow && statusMessageIsBelow) {
		rect = [self drawUserExtendedStatusInRect:rect
									  withMessage:(useStatusMessageAsExtendedStatus ?
												   [listObject statusMessageString] : 
												   [listObject valueForProperty:@"ExtendedStatus"])
										drawUnder:YES];
		
		rect = [self drawDisplayNameWithFrame:rect];
		
	} else if (!idleTimeIsBelow && !statusMessageIsBelow) {
		// Draw the display name before
		rect = [self drawDisplayNameWithFrame:rect];
		
		rect = [self drawUserExtendedStatusInRect:rect
									  withMessage:(useStatusMessageAsExtendedStatus ?
												   [listObject statusMessageString] : 
												   [listObject valueForProperty:@"ExtendedStatus"])
										drawUnder:NO];	
	} else {
		if (statusMessageIsBelow && statusMessageVisible) {
			rect = [self drawUserExtendedStatusInRect:rect
										  withMessage:[listObject valueForProperty:@"ExtendedStatus"]
											drawUnder:YES];	
		}
		
		if (idleTimeIsBelow && idleTimeVisible) {
			rect = [self drawUserExtendedStatusInRect:rect
										  withMessage:[listObject valueForProperty:@"IdleReadable"]
											drawUnder:YES];
		}
		
		// Draw the display name after we've drawn things that go below it.
		rect = [self drawDisplayNameWithFrame:rect];

		if (!statusMessageIsBelow && statusMessageVisible) {
			rect = [self drawUserExtendedStatusInRect:rect
										  withMessage:[listObject statusMessageString]
											drawUnder:NO];	
		}
		
		if (!idleTimeIsBelow && idleTimeVisible) {
			rect = [self drawUserExtendedStatusInRect:rect
										  withMessage:[listObject valueForProperty:@"IdleReadable"]
											drawUnder:NO];
		}
	}
}

//Draw the background of our cell
- (void)drawBackgroundWithFrame:(NSRect)rect
{
	NSColor	*labelColor = [self labelColor];
	if (labelColor && ![self cellIsSelected]) {
		[labelColor set];
		[NSBezierPath fillRect:rect];
	}
}

//User Icon
- (NSRect)drawUserIconInRect:(NSRect)inRect position:(IMAGE_POSITION)position
{
	NSRect	rect = inRect;
	if (userIconVisible) {
		NSImageInterpolation savedInterpolation = [[NSGraphicsContext currentContext] imageInterpolation];
		NSImage *image;
		NSRect	drawRect;
		
		image = [self userIconImage];
		if (!image) {
			// if using service icons, set the interpolation to high
			[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
			image = [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconLarge direction:AIIconFlipped];
		}

		//Rounded corners for our user images.
		rect = [image drawRoundedInRect:rect
								 atSize:userIconSize
							   position:position
							   fraction:[self imageOpacityForDrawing]
								 radius:userIconRoundingRadius];
		[[NSGraphicsContext currentContext] setImageInterpolation: savedInterpolation];
		
		//If we're using space on the left, shift the origin right
		if (position == IMAGE_POSITION_LEFT) rect.origin.x += USER_ICON_LEFT_PAD;
		rect.size.width -= USER_ICON_LEFT_PAD;
		
		//Badges
		if ((statusIconPosition == LIST_POSITION_BADGE_LEFT) || (statusIconPosition == LIST_POSITION_BADGE_RIGHT) ||
			(serviceIconPosition == LIST_POSITION_BADGE_LEFT) || (serviceIconPosition == LIST_POSITION_BADGE_RIGHT)) {
			drawRect = [image rectForDrawingInRect:inRect
											atSize:userIconSize
										  position:position];
			if (statusIconPosition == LIST_POSITION_BADGE_LEFT) {
				[self drawStatusIconInRect:drawRect position:IMAGE_POSITION_LOWER_LEFT];
			} else if (statusIconPosition == LIST_POSITION_BADGE_RIGHT) {
				[self drawStatusIconInRect:drawRect position:IMAGE_POSITION_LOWER_RIGHT];
			}
			
			if (serviceIconPosition == LIST_POSITION_BADGE_LEFT) {
				[self drawServiceIconInRect:drawRect position:IMAGE_POSITION_LOWER_LEFT];
			} else if (serviceIconPosition == LIST_POSITION_BADGE_RIGHT) {
				[self drawServiceIconInRect:drawRect position:IMAGE_POSITION_LOWER_RIGHT];
			}
		}

		//If we're using space on the right, shrink the width so we won't be overlapped
		if (position == IMAGE_POSITION_LEFT) rect.origin.x += USER_ICON_RIGHT_PAD;
		rect.size.width -= USER_ICON_RIGHT_PAD;
	}
	
	return rect;
}

//Status Icon
- (NSRect)drawStatusIconInRect:(NSRect)rect position:(IMAGE_POSITION)position
{
	if (statusIconsVisible) {
		BOOL	isBadge = (position == IMAGE_POSITION_LOWER_LEFT || position == IMAGE_POSITION_LOWER_RIGHT);
		
		if (!isBadge) {
			if (position == IMAGE_POSITION_LEFT) rect.origin.x += STATUS_ICON_LEFT_PAD;
			rect.size.width -= STATUS_ICON_LEFT_PAD;
		}

		NSImage *image = [self statusImage];
		[image setFlipped:![image isFlipped]];
		rect = [image drawInRect:rect
						  atSize:NSMakeSize(0, 0)
						position:position
						fraction:1.0];
		[image setFlipped:![image isFlipped]];
		
		if (!isBadge) {
			if (position == IMAGE_POSITION_LEFT) rect.origin.x += STATUS_ICON_RIGHT_PAD;
			rect.size.width -= STATUS_ICON_RIGHT_PAD;
		}
	}
	return rect;
}

//Service Icon
- (NSRect)drawServiceIconInRect:(NSRect)rect position:(IMAGE_POSITION)position
{
	if (serviceIconsVisible) {
		BOOL	isBadge = (position == IMAGE_POSITION_LOWER_LEFT || position == IMAGE_POSITION_LOWER_RIGHT);

		if (!isBadge) {
			if (position == IMAGE_POSITION_LEFT) rect.origin.x += SERVICE_ICON_LEFT_PAD;
			rect.size.width -= SERVICE_ICON_LEFT_PAD;
		}
		
		/*
		 Draw the service icon if (it is not a badge), or if (it is a badge and there is a userIconImage)
		 (We have already drawn the service icon if there is no userIconImage, in drawUserIconInRect:position:)
		 */
		if (!isBadge || ([self userIconImage] != nil)) {
			NSImage *image = [self serviceImage];
			rect = [image drawInRect:rect
							  atSize:NSMakeSize(0, 0)
							position:position
							fraction:[self imageOpacityForDrawing]];
		}
		
		if (!isBadge) {
			if (position == IMAGE_POSITION_LEFT) rect.origin.x += SERVICE_ICON_RIGHT_PAD;
			rect.size.width -= SERVICE_ICON_RIGHT_PAD;
		}
	}
	return rect;
}

//User Extended Status
- (NSRect)drawUserExtendedStatusInRect:(NSRect)rect withMessage:(NSString *)string drawUnder:(BOOL)drawUnder
{
	if (extendedStatusVisible && (drawUnder || [self textAlignment] != NSCenterTextAlignment)) {
		if (string) {
			int	halfHeight = rect.size.height / 2;

			//Pad
			if (drawUnder) {
				rect.origin.y += halfHeight;
				rect.size.height -= halfHeight;
			} else {
				if ([self textAlignment] == NSLeftTextAlignment) rect.origin.x += NAME_STATUS_PAD;
				rect.size.width -= NAME_STATUS_PAD;
			}
			
			NSDictionary		*attributes = ([self cellIsSelected] ?
											   [self statusAttributesInverted] :
											   [self statusAttributes]);
			NSAttributedString 	*extStatus = [[NSAttributedString alloc] initWithString:string attributes:attributes];
			
			//Alignment
			NSSize		nameSize = [extStatus size];
			NSRect		drawRect = rect;
			
			if (nameSize.width > drawRect.size.width) nameSize = rect.size;
			
			switch ([self textAlignment]) {
				case NSCenterTextAlignment:
					drawRect.origin.x += (drawRect.size.width - nameSize.width) / 2.0;
				break;
				case NSRightTextAlignment:
					drawRect.origin.x += (drawRect.size.width - nameSize.width);
				break;
				default:
				break;
			}
			
			float half, offset;
			
			if (drawUnder) {
				half = ceilf((drawRect.size.height - statusFontHeight) / 2.0);
				offset = 0;
			} else {
				half = ceilf((drawRect.size.height - labelFontHeight) / 2.0);
				offset = (labelFontHeight - statusFontHeight) + ([[self font] descender] - [[self statusFont] descender]);
			}

			[extStatus drawInRect:NSMakeRect(drawRect.origin.x,
											 drawRect.origin.y + half + offset,
											 drawRect.size.width,
											 drawRect.size.height - (half + offset))];

			[extStatus release];
			
			if (drawUnder) {
				rect.origin.y -= halfHeight;
			}
		}
	}
	return rect;
}

- (void)setUseAliasesOnNonParentContacts:(BOOL)inFlag
{
	useAliasesOnNonParentContacts = inFlag;
}

- (BOOL)shouldShowAlias
{
	// If we use aliases...
	if (useAliasesAsRequested) {
		// If we use aliases on non-parents OR this is a parent...
		if (useAliasesOnNonParentContacts || ![((AIListContact *)listObject).containingObjects containsObject:((AIListContact *)listObject).parentContact]) {
			return YES;
		}
	}
	
	return NO;
}

//Contact label color
- (NSColor *)labelColor
{
	BOOL	isEvent = [listObject boolValueForProperty:@"Is Event"];
	
	if ((isEvent && backgroundColorIsEvents) || (!isEvent && backgroundColorIsStatus)) {
		NSColor		*labelColor = [listObject valueForProperty:@"Label Color"];
		float		colorOpacity = [labelColor alphaComponent];
		float		targetOpacity = backgroundOpacity * colorOpacity;

		return (targetOpacity != colorOpacity) ? [labelColor colorWithAlphaComponent:targetOpacity] : labelColor;

	} else {
		return nil;
	}
}

//Contact text color
- (NSColor *)textColor
{
	NSColor	*theTextColor;
	BOOL	isEvent = [listObject boolValueForProperty:@"Is Event"];
	/* XXX If it's an event, we may want to be inheriting from more than just the metacontact's preferred contact...
	 * this is the only case for that which I've come across */
	if (shouldUseContactTextColors && (theTextColor = [listObject valueForProperty:@"Text Color"])) {
		return theTextColor;
	} else {
		return [super textColor];
	}
}
- (NSColor *)invertedTextColor
{
	return CONTACT_INVERTED_TEXT_COLOR/*[[self textColor] colorWithInvertedLuminance]*/;
}

//Contact user image - AIUserIcons should already have been informed of our desired size by setUserIconSize: above.
- (NSImage *)userIconImage
{
	return [AIUserIcons listUserIconForContact:(AIListContact *)listObject size:userIconSize];
}

//Contact state or status image
- (NSImage *)statusImage
{
	return [listObject statusIcon];
}

//Contact service image
- (NSImage *)serviceImage
{
	return [AIServiceIcons serviceIconForObject:listObject type:AIServiceIconList direction:AIIconFlipped];
}

//
- (float)imageOpacityForDrawing
{
	NSNumber *imageOpacityNumber = [listObject numberValueForProperty:@"Image Opacity"];
	return (imageOpacityNumber ? [imageOpacityNumber floatValue] : 0.0);
}

@end
