/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

/*
 Some useful additions for attributed strings
 */

#import "AIAttributedStringAdditions.h"
#import "AIColorAdditions.h"
#import "AITextAttributes.h"
#import "AIApplicationAdditions.h"
#import "AIStringUtilities.h"

NSString *AIFontFamilyAttributeName = @"AIFontFamily";
NSString *AIFontSizeAttributeName   = @"AIFontSize";
NSString *AIFontWeightAttributeName = @"AIFontWeight";
NSString *AIFontStyleAttributeName  = @"AIFontStyle";

@implementation NSMutableAttributedString (AIAttributedStringAdditions)

//Append a plain string, adding the specified attributes
- (void)appendString:(NSString *)aString withAttributes:(NSDictionary *)attrs
{
    NSAttributedString	*tempString;

    if (attrs) {
        tempString = [[NSAttributedString alloc] initWithString:aString attributes:attrs];
    } else {
        tempString = [[NSAttributedString alloc] initWithString:aString];
    }

    [self appendAttributedString:tempString];
    [tempString release];
}

- (unsigned int)replaceOccurrencesOfString:(NSString *)target withString:(NSString*)replacement options:(unsigned)opts range:(NSRange)searchRange
{
    NSRange		theRange;
    unsigned	numberOfReplacements = 0, replacementLength = [replacement length];

    while ( (theRange = [[self string] rangeOfString:target 
											 options:opts
											   range:searchRange]).location != NSNotFound ) {
        [self replaceCharactersInRange:theRange withString:replacement];
        numberOfReplacements++;
        searchRange.length = searchRange.length - ((theRange.location + theRange.length) - searchRange.location);
        
        searchRange.location = theRange.location + replacementLength;
        if (searchRange.length - searchRange.location < 1)
            break;
    }
    return numberOfReplacements;
}

- (unsigned int)replaceOccurrencesOfString:(NSString *)target withString:(NSString*)replacement attributes:(NSDictionary*)attributes options:(unsigned)opts range:(NSRange)searchRange
{
    NSRange				theRange;
    unsigned			numberOfReplacements = 0, replacementLength = [replacement length];
    NSAttributedString	*replacementString = [[NSAttributedString alloc] initWithString:replacement 
																			 attributes:attributes];
    
    while ( (theRange = [[self string] rangeOfString:target
											 options:opts
											   range:searchRange]).location != NSNotFound ) {
		
        [self replaceCharactersInRange:theRange withAttributedString:replacementString];
        numberOfReplacements++;
        searchRange.length = searchRange.length - ((theRange.location + theRange.length) - searchRange.location);
        
        searchRange.location = theRange.location + replacementLength;
        if (searchRange.length - searchRange.location < 1)
            break;
    }
    
    [replacementString release];
    
    return numberOfReplacements;
}


//from Adium 1.6 AIAttributedStringFormattingAdditions
//adjust the colors in the string so they're visible on the background
- (void)adjustColorsToShowOnBackground:(NSColor *)backgroundColor
{
    int		index = 0;
    int		stringLength = [self length];
    float	backgroundBrightness, backgroundSum;
    
    //--get the brightness of our background--
    backgroundColor = [backgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    backgroundBrightness = [backgroundColor brightnessComponent];
    backgroundSum = [backgroundColor redComponent] + [backgroundColor greenComponent] + [backgroundColor blueComponent];
    //we need to scan each colored "chunk" of the message - and check to make sure it is a "visible" color
    while (index < stringLength) {
        NSColor		*fontColor;
        NSRange		effectiveRange;
        float		brightness, sum;
        float		deltaBrightness, deltaSum;
        BOOL		colorChanged = NO;
        
        //--get the font color--
        fontColor = [self attribute:NSForegroundColorAttributeName atIndex:index effectiveRange:&effectiveRange];                
        if (fontColor == nil) fontColor = [NSColor blackColor];
        fontColor = [fontColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        
        //--check brightness--
        brightness = [fontColor brightnessComponent];
        deltaBrightness = backgroundBrightness - brightness;
        if (deltaBrightness >= 0 && deltaBrightness < 0.4) { //too close                    
                                                           //change the color
            fontColor = [NSColor colorWithCalibratedHue:[fontColor hueComponent] saturation:[fontColor saturationComponent] brightness:backgroundBrightness - 0.4 alpha:[fontColor alphaComponent]];
            fontColor = [fontColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                colorChanged = YES;
            
        } else if (deltaBrightness < 0 && deltaBrightness > -0.4) { //too close
                                                                 //change the color
            fontColor = [NSColor colorWithCalibratedHue:[fontColor hueComponent] saturation:[fontColor saturationComponent] brightness:backgroundBrightness + 0.4 alpha:[fontColor alphaComponent]];
            fontColor = [fontColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            
            colorChanged = YES;
        }
        
        //--check components--
        sum = [fontColor redComponent] + [fontColor greenComponent] + [fontColor blueComponent];
        deltaSum = backgroundSum - sum;
        if (deltaSum < 1.0 && deltaSum > -1.0) { //still too similar                    
                                               //just give up and make the color black or white
            if (backgroundBrightness <= 0.5) {
                fontColor = [[NSColor whiteColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            } else {
                fontColor = [[NSColor blackColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            }
            colorChanged = YES;
        }
        
        if (colorChanged) {
            [self addAttribute:NSForegroundColorAttributeName value:fontColor range:effectiveRange];
        }
        
        index = effectiveRange.location + effectiveRange.length;
    }
}

//adjust the colors in the string so they're visible on the background, adjusting brightness in proportion to the original background
- (void)adjustColorsToShowOnBackgroundRelativeToOriginalBackground:(NSColor *)backgroundColor
{
    int             index = 0;
    int             stringLength = [self length];
    float           backgroundBrightness=0.0f, backgroundSum=0.0f;
    NSColor         *backColor=nil;
    //--get the brightness of our background--
    if (backgroundColor) {
        backColor = [backgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        backgroundBrightness = [backColor brightnessComponent];
        backgroundSum = [backColor redComponent] + [backColor greenComponent] + [backColor blueComponent];
    }
    
    //we need to scan each colored "chunk" of the message - and check to make sure it is a "visible" color
    while (index < stringLength) {
        NSColor		*fontColor;
        NSColor         *fontBackColor;

        NSRange		effectiveRange, backgroundRange;
        float		brightness, newBrightness;
        float		deltaBrightness, deltaSum;
        BOOL		colorChanged = NO, backgroundIsDark, fontBackIsDark;
        
        //--get the font color--
        fontColor = [self attribute:NSForegroundColorAttributeName atIndex:index effectiveRange:&effectiveRange];
        //--get the background color in this range
        fontBackColor = [self attribute:NSBackgroundColorAttributeName atIndex:index effectiveRange:&backgroundRange];
        if (!fontBackColor) {
            //Background coloring
            fontBackColor = [self attribute:AIBodyColorAttributeName atIndex:index effectiveRange:&backgroundRange];
            if (!fontBackColor) {
                fontBackColor = [NSColor whiteColor];
                fontBackColor = [fontBackColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            }
        }
        
        //--use the shorter of these two ranges
        if (backgroundRange.length < effectiveRange.length)
            effectiveRange.length = backgroundRange.length;
        
        if (!fontColor) fontColor = [NSColor blackColor];
        fontColor = [fontColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        
        brightness = [fontColor brightnessComponent];
        
        if (!backgroundColor) {
            backColor = fontBackColor;
            backgroundBrightness = [backColor brightnessComponent];
            backgroundSum = [backColor redComponent] + [backColor greenComponent] + [backColor blueComponent];
        } else {
            deltaBrightness = (brightness - [fontBackColor brightnessComponent]);
            backgroundIsDark = [backgroundColor colorIsDark];
            fontBackIsDark = [fontBackColor colorIsDark];
            if (!backgroundIsDark && fontBackIsDark) {
                newBrightness = brightness - (deltaBrightness)/2;
                if (newBrightness <= 0)
                    newBrightness = .2;
                colorChanged = YES;
            }
            else if (backgroundIsDark && !fontBackIsDark) {
                newBrightness = brightness + (deltaBrightness)/2;
                if (newBrightness >= 1)
                    newBrightness = .8;
                colorChanged = YES;
            }
            
            if (colorChanged) {
                fontColor = [NSColor colorWithCalibratedHue:[fontColor hueComponent] saturation:[fontColor saturationComponent] brightness:newBrightness alpha:[fontColor alphaComponent]];
                fontColor = [fontColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            }
        }
                 
        //--check brightness--
        brightness = [fontColor brightnessComponent];
        deltaBrightness = backgroundBrightness - brightness;       
        if (deltaBrightness >= 0 && deltaBrightness <= 0.4) {    //too close 
            fontColor = [fontColor adjustHue:0.0 saturation:0.0 brightness:-.4]; //change the color
            colorChanged = YES;
            
        } else if (deltaBrightness >= -0.4 && deltaBrightness <0) { //too close
                                                                 //change the color

            fontColor = [fontColor adjustHue:0.0 saturation:0.0 brightness:.4];
            
            colorChanged = YES;
        }

        //--check luminance--
        CGFloat hue,saturation;
        CGFloat fontLuminance,backLuminance;
        
        [fontColor getHue:&hue saturation:&saturation brightness:&fontLuminance alpha:NULL];
        [backColor getHue:&hue saturation:&saturation brightness:&backLuminance alpha:NULL];
            
        deltaSum = backLuminance - fontLuminance;
        
        if (deltaSum >= -0.3 && deltaSum <= 0.3) { //still too similar     
            if (backgroundBrightness <= 0.5) {
               fontColor = [[NSColor whiteColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            } else {
                fontColor = [[NSColor blackColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            }

            colorChanged = YES;
        }
        
        if (colorChanged) {
            [self addAttribute:NSForegroundColorAttributeName value:fontColor range:effectiveRange];
        }
        
        index = effectiveRange.location + effectiveRange.length;
    }
}

- (void)addFormattingForLinks
{
	NSRange		searchRange;
	unsigned	length = [self length];
	
	searchRange = NSMakeRange(0,0);
	while (searchRange.location < length) {
		NSDictionary	*attributes = [self attributesAtIndex:searchRange.location effectiveRange:&searchRange];
		if ([attributes objectForKey:NSLinkAttributeName] != nil) {
			[self addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:searchRange];
			[self addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithBool:YES] range:searchRange];
		}
		searchRange.location += searchRange.length;
	}
}

- (void)convertAttachmentsToStringsUsingPlaceholder:(NSString *)placeholder
{
    if ([self length] && [self containsAttachments]) {
        int							currentLocation = 0;
        NSRange						attachmentRange;
		NSString					*attachmentCharacterString = [NSString stringWithFormat:@"%C",NSAttachmentCharacter];
		
        //find attachment
        attachmentRange = [[self string] rangeOfString:attachmentCharacterString
											   options:0 
												 range:NSMakeRange(currentLocation,
																   [self length] - currentLocation)];
		
        while (attachmentRange.length != 0) { //if we found an attachment
			NSTextAttachment	*attachment = [self attribute:NSAttachmentAttributeName
													  atIndex:attachmentRange.location
											   effectiveRange:nil];
            NSString *replacement = nil;
			if ([attachment respondsToSelector:@selector(string)]) {
				replacement = [attachment performSelector:@selector(string)];
			}
			
            if (!replacement) {
                replacement = placeholder;
            }
			
            //remove the attachment, replacing it with the original text
			[self removeAttribute:NSAttachmentAttributeName range:attachmentRange];
            [self replaceCharactersInRange:attachmentRange withString:replacement];
			
            attachmentRange.length = [replacement length];
			
            currentLocation = attachmentRange.location + attachmentRange.length;
			
            //find the next attachment
            attachmentRange = [[self string] rangeOfString:attachmentCharacterString
												   options:0
													 range:NSMakeRange(currentLocation,
																	   [self length] - currentLocation)];
        }
	}	
}


@end

@implementation NSAttributedString (AIAttributedStringAdditions)

+ (NSSet *)CSSCapableAttributesSet
{
	return [NSSet setWithObjects:
		NSFontAttributeName,
		AIFontFamilyAttributeName,
		AIFontSizeAttributeName,
		AIFontWeightAttributeName,
		AIFontStyleAttributeName,
		NSForegroundColorAttributeName,
		NSBackgroundColorAttributeName,
		NSShadowAttributeName,
		NSCursorAttributeName,
		NSUnderlineStyleAttributeName,
		NSStrikethroughStyleAttributeName,
		NSSuperscriptAttributeName,
		nil];
}
+ (NSString *)CSSStringForTextAttributes:(NSDictionary *)attrs
{
	static NSDictionary *attributeNamesToCSSPropertyNames = nil;
	if (!attributeNamesToCSSPropertyNames) {
		attributeNamesToCSSPropertyNames = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"font",             NSFontAttributeName,
			@"font-family",      AIFontFamilyAttributeName,
			@"font-size",        AIFontSizeAttributeName,
			@"font-weight",      AIFontWeightAttributeName,
			@"font-style",       AIFontStyleAttributeName,
			@"color",            NSForegroundColorAttributeName,
			@"background-color", NSBackgroundColorAttributeName,
			@"text-shadow",      NSShadowAttributeName,
			@"cursor",           NSCursorAttributeName,
			nil];
	}

	NSMutableArray *CSSProperties = [NSMutableArray arrayWithCapacity:[attrs count]];

	BOOL hasLineThrough = NO, hasUnderline = NO;

	NSEnumerator *keysEnum = [attrs keyEnumerator];
	NSString *key;
	while ((key = [keysEnum nextObject])) {
		if ([key isEqualToString:NSUnderlineStyleAttributeName]) {
			hasUnderline = YES;
		} else if ([key isEqualToString:NSStrikethroughStyleAttributeName]) {
			hasLineThrough = YES;
		} else if ([key isEqualToString:NSSuperscriptAttributeName]) {
			[CSSProperties addObject:@"vertical-align: baseline;"];
		} else {
			NSString *CSSPropertyName = [attributeNamesToCSSPropertyNames objectForKey:key];
			id obj = [attrs objectForKey:key];
			if (CSSPropertyName) {
				if ([obj respondsToSelector:@selector(CSSRepresentation)]) {
					obj = [obj CSSRepresentation];
				} else if ([obj respondsToSelector:@selector(stringValue)]) {
					obj = [obj stringValue];
				} else if ([obj respondsToSelector:@selector(absoluteString)]) {
					obj = [obj absoluteString];
				}

				[CSSProperties addObject:[NSString stringWithFormat:@"%@: %@;", CSSPropertyName, obj]];
			}
		}
	}

	if (hasLineThrough && hasUnderline) {
		[CSSProperties addObject:@"text-decoration: line-through underline;"];
	} else if (hasLineThrough) {
		[CSSProperties addObject:@"text-decoration: line-through;"];
	} else if (hasUnderline) {
		[CSSProperties addObject:@"text-decoration: underline;"];
	}

	[CSSProperties sortUsingSelector:@selector(compare:)];

	return [CSSProperties componentsJoinedByString:@" "];
}

//Height of a string
#define FONT_HEIGHT_STRING		@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()"
+ (float)stringHeightForAttributes:(NSDictionary *)attributes
{
	NSAttributedString	*string = [[[NSAttributedString alloc] initWithString:FONT_HEIGHT_STRING
																   attributes:attributes] autorelease];
	return [string heightWithWidth:1e7];
}

+ (NSAttributedString *)stringWithString:(NSString *)inString
{
	return [[[NSAttributedString alloc] initWithString:inString] autorelease];
}

+ (NSAttributedString *)attributedStringWithString:(NSString *)inString linkRange:(NSRange)linkRange linkDestination:(id)link
{
    NSParameterAssert(inString != nil);

    if ([link isKindOfClass:[NSString class]]) {
        link = [NSURL URLWithString:link];
    }
    NSParameterAssert(link != nil);
    NSParameterAssert([link isKindOfClass:[NSURL class]]);

    NSMutableAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithString:inString] autorelease];
    //Throws NSInvalidArgumentException if the range is out-of-range.
    [attributedString addAttribute:NSLinkAttributeName value:link range:linkRange];

    return attributedString;
}
+ (NSAttributedString *)attributedStringWithLinkLabel:(NSString *)inString linkDestination:(id)link
{
    NSParameterAssert(inString != nil);

    if ([link isKindOfClass:[NSString class]]) {
        link = [NSURL URLWithString:link];
    }
    NSParameterAssert(link != nil);
    NSParameterAssert([link isKindOfClass:[NSURL class]]);

    NSDictionary *attributes = [NSDictionary dictionaryWithObject:link forKey:NSLinkAttributeName];
    return [[[self alloc] initWithString:inString attributes:attributes] autorelease];
}

- (float)heightWithWidth:(float)width
{	
    //Setup the layout manager and text container
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, 1e7)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];

    //Configure
    [textContainer setLineFragmentPadding:0.0];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];

    //Force the layout manager to layout its text
    (void)[layoutManager glyphRangeForTextContainer:textContainer];

	float height = [layoutManager usedRectForTextContainer:textContainer].size.height;

	[textStorage release];
	[textContainer release];
	[layoutManager release];
	
    return height;
}

- (NSData *)dataRepresentation
{
	return [NSArchiver archivedDataWithRootObject:self];
}

+ (NSAttributedString *)stringWithData:(NSData *)inData
{
	NSAttributedString	*returnValue = nil;
	
	/* We use an exception handler here because NSUnarchiver can throw an NSInvalidArgumentException with a reason:
	 *		-[NSPlaceholderDictionary initWithObjects_ex:forKeys:count:]: attempt to insert nil value
	 * if we feed it invalid data.
	 */
	@try
	{
		if (inData && [inData length]) {
			//If inData (which must bt non-nil) is not valid archived data, this returns nil.
			NSUnarchiver		*unarchiver = [[NSUnarchiver alloc] initForReadingWithData:inData];
			
			if (unarchiver) {
				/* NSUnarchiver's decodeObject returns an object which is retained by the unarchiver and released
				 * when the unarchiver is deallocated.  We could rely upon autoreleasing the unarchiver, but it
				 * is cleaner to make the NSAttributedString autorelease itself.
				 */
				returnValue = (NSAttributedString *)[[[unarchiver decodeObject] retain] autorelease];
				
			} else {
				/* For reading previously stored NSData objects - we used to store them as RTF data, but that
				 * method is both slower and buggier. Any modern storage will use NSUnarchiver, so leaving this
				 * here isn't a speed problem.  We previously used AIHTMLDecoder to handle Jaguar old-data unarchiving...
				 * but that's in Adium.framework and the cross over most certainly isn't worth it.
				 */
				returnValue = ([[[NSAttributedString alloc] initWithRTF:inData
													 documentAttributes:nil] autorelease]);
			}
			
			[unarchiver release];
		}
	}
	@catch(id exc) {	}
			
	return returnValue;
}

- (NSAttributedString *)attributedStringByConvertingAttachmentsToStrings
{
    if ([self length] && [self containsAttachments]) {
        NSMutableAttributedString	*newAttributedString = [[self mutableCopy] autorelease];
		[newAttributedString convertAttachmentsToStringsUsingPlaceholder:AILocalizedString(@"<<Attachment>>", nil)];

		return newAttributedString;

    } else {
        return self;
    }
}

/* Deprecated */
- (NSAttributedString *)safeString
{
	NSLog(@"%@", @"**** You are using an out of date external Adium plugin [most likely the SQL Logger]. Please recompile and reinstall the plugin. This will crash in a future release. ****");
	return [self attributedStringByConvertingAttachmentsToStrings];
}

- (NSAttributedString *)attributedStringByConvertingLinksToStringsWithTitles:(BOOL)includeTitles
{
	NSMutableAttributedString	*newAttributedString = nil;
	unsigned					length = [self length];

	if (length) {
		NSRange						searchRange = NSMakeRange(0,0);
		NSAttributedString			*currentAttributedString = self;

		while (searchRange.location < length) {
			NSURL			*URL = [currentAttributedString attribute:NSLinkAttributeName
														  atIndex:searchRange.location
												   effectiveRange:&searchRange];
			
			if (URL) {
				if (!newAttributedString) {
					newAttributedString = [[self mutableCopy] autorelease];
					currentAttributedString = newAttributedString;
				}

				NSString	*absoluteString = [URL absoluteString];
				NSString	*originalTitle = [[newAttributedString string] substringWithRange:searchRange];
				NSString	*replacementString;
				
				if ([originalTitle caseInsensitiveCompare:absoluteString] == NSOrderedSame) {
					replacementString = originalTitle;

				} else if (includeTitles) {
					replacementString = [NSString stringWithFormat:@"%@ (%@)", originalTitle, absoluteString];
				} else {
					replacementString = absoluteString;
				}

				[newAttributedString replaceCharactersInRange:searchRange 
												   withString:replacementString];
				
				//Modify our searchRange and cached length to reflect the string we just inserted.
				searchRange.length = [replacementString length];
				length = [newAttributedString length];
				
				//Now remove the link attribute
				[newAttributedString removeAttribute:NSLinkAttributeName range:searchRange];
			}

			searchRange.location += searchRange.length;
		}
	}

	return (newAttributedString ? newAttributedString : [[self copy] autorelease]);
}

- (NSAttributedString *)attributedStringByConvertingLinksToStrings
{
	return [self attributedStringByConvertingLinksToStringsWithTitles:YES];
}
- (NSAttributedString *)attributedStringByConvertingLinksToURLStrings
{
	return [self attributedStringByConvertingLinksToStringsWithTitles:NO];
}

- (NSAttributedString *)stringByAddingFormattingForLinks
{
	NSMutableAttributedString  *str = [self mutableCopy];
	[str addFormattingForLinks];
	return [str autorelease];
}

@end

@implementation NSData (AIAttributedStringAdditions)

- (NSAttributedString *)attributedString
{
	return [NSAttributedString stringWithData:self];
}

@end
