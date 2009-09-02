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
    Utilities for creating a NSColor from a hex string representation, and storing colors as a string
*/

#import "AIColorAdditions.h"
#import "AIStringAdditions.h"
#import <string.h>

static NSArray *defaultValidColors = nil;
#define VALID_COLORS_ARRAY [[NSArray alloc] initWithObjects:@"aqua", @"aquamarine", @"blue", @"blueviolet", @"brown", @"burlywood", @"cadetblue", @"chartreuse", @"chocolate", @"coral", @"cornflowerblue", @"crimson", @"cyan", @"darkblue", @"darkcyan", @"darkgoldenrod", @"darkgreen", @"darkgrey", @"darkkhaki", @"darkmagenta", @"darkolivegreen", @"darkorange", @"darkorchid", @"darkred", @"darksalmon", @"darkseagreen", @"darkslateblue", @"darkslategrey", @"darkturquoise", @"darkviolet", @"deeppink", @"deepskyblue", @"dimgrey", @"dodgerblue", @"firebrick", @"forestgreen", @"fuchsia", @"gold", @"goldenrod", @"green", @"greenyellow", @"grey", @"hotpink", @"indianred", @"indigo", @"lawngreen", @"lightblue", @"lightcoral", @"lightgreen", @"lightgrey", @"lightpink", @"lightsalmon", @"lightseagreen", @"lightskyblue", @"lightslategrey", @"lightsteelblue", @"lime", @"limegreen", @"magenta", @"maroon", @"mediumaquamarine", @"mediumblue", @"mediumorchid", @"mediumpurple", @"mediumseagreen", @"mediumslateblue", @"mediumspringgreen", @"mediumturquoise", @"mediumvioletred", @"midnightblue", @"navy", @"olive", @"olivedrab", @"orange", @"orangered", @"orchid", @"palegreen", @"paleturquoise", @"palevioletred", @"peru", @"pink", @"plum", @"powderblue", @"purple", @"red", @"rosybrown", @"royalblue", @"saddlebrown", @"salmon", @"sandybrown", @"seagreen", @"sienna", @"silver", @"skyblue", @"slateblue", @"slategrey", @"springgreen", @"steelblue", @"tan", @"teal", @"thistle", @"tomato", @"turquoise", @"violet", @"yellowgreen", nil]

static const float ONE_THIRD = 1.0/3.0;
static const float ONE_SIXTH = 1.0/6.0;
static const float TWO_THIRD = 2.0/3.0;

static NSMutableDictionary *RGBColorValues = nil;

//two parts of a single path:
//	defaultRGBTxtLocation1/VERSION/defaultRGBTxtLocation2
static NSString *defaultRGBTxtLocation1 = @"/usr/share/emacs";
static NSString *defaultRGBTxtLocation2 = @"etc/rgb.txt";

#ifdef DEBUG_BUILD
	#define COLOR_DEBUG TRUE
#else
	#define COLOR_DEBUG FALSE
#endif

@implementation NSDictionary (AIColorAdditions_RGBTxtFiles)

//see /usr/share/emacs/(some version)/etc/rgb.txt for an example of such a file.
//the pathname does not need to end in 'rgb.txt', but it must be a file in UTF-8 encoding.
//the keys are colour names (all converted to lowercase); the values are RGB NSColors.
+ (id)dictionaryWithContentsOfRGBTxtFile:(NSString *)path
{
	NSMutableData *data = [NSMutableData dataWithContentsOfFile:path];
	if (!data) return nil;
	
	char *ch = [data mutableBytes]; //we use mutable bytes because we want to tokenise the string by replacing separators with '\0'.
	unsigned length = [data length];
	struct {
		const char *redStart, *greenStart, *blueStart, *nameStart;
		const char *redEnd,   *greenEnd,   *blueEnd;
		float red, green, blue;
		unsigned reserved: 23;
		unsigned inComment: 1;
		char prevChar;
	} state = {
		.prevChar = '\n',
		.redStart = NULL, .greenStart = NULL, .blueStart = NULL, .nameStart = NULL,
		.inComment = NO,
	};
	
	NSDictionary *result = nil;
	
	//the rgb.txt file that comes with Mac OS X 10.3.8 contains 752 entries.
	//we create 3 autoreleased objects for each one.
	//best to not pollute our caller's autorelease pool.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
	
	for (unsigned i = 0; i < length; ++i) {
		if (state.inComment) {
			if (ch[i] == '\n') state.inComment = NO;
		} else if (ch[i] == '\n') {
			if (state.prevChar != '\n') { //ignore blank lines
				if (	! ((state.redStart   != NULL)
					   && (state.greenStart != NULL)
					   && (state.blueStart  != NULL)
					   && (state.nameStart  != NULL)))
				{
#if COLOR_DEBUG
					NSLog(@"Parse error reading rgb.txt file: a non-comment line was encountered that did not have all four of red (%p), green (%p), blue (%p), and name (%p) - index is %u",
						  state.redStart,
						  state.greenStart,
						  state.blueStart,
						  state.nameStart, i);
#endif
					goto end;
				}
				
				NSRange range = {
					.location = state.nameStart - ch,
					.length   = (&ch[i]) - state.nameStart,
				};
				NSString *name = [NSString stringWithData:[data subdataWithRange:range] encoding:NSUTF8StringEncoding];
				NSColor *color = [NSColor colorWithCalibratedRed:state.red
														   green:state.green
															blue:state.blue
														   alpha:1.0];
				[mutableDict setObject:color forKey:name];
				NSString *lowercaseName = [name lowercaseString];
				if (![mutableDict objectForKey:lowercaseName]) {
					//only add the lowercase version if it isn't already defined
					[mutableDict setObject:color forKey:lowercaseName];
				}

				state.redStart = state.greenStart = state.blueStart = state.nameStart = 
				state.redEnd   = state.greenEnd   = state.blueEnd   = NULL;
			} //if (prevChar != '\n')
		} else if ((ch[i] != ' ') && (ch[i] != '\t')) {
			if (state.prevChar == '\n' && ch[i] == '#') {
				state.inComment = YES;
			} else {
				if (!state.redStart) {
					state.redStart = &ch[i];
					state.red = (float)(strtod(state.redStart, (char **)&state.redEnd) / 255.0);
				} else if ((!state.greenStart) && state.redEnd && (&ch[i] >= state.redEnd)) {
					state.greenStart = &ch[i];
					state.green = (float)(strtod(state.greenStart, (char **)&state.greenEnd) / 255.0);
				} else if ((!state.blueStart) && state.greenEnd && (&ch[i] >= state.greenEnd)) {
					state.blueStart = &ch[i];
					state.blue = (float)(strtod(state.blueStart, (char **)&state.blueEnd) / 255.0);
				} else if ((!state.nameStart) && state.blueEnd && (&ch[i] >= state.blueEnd)) {
					state.nameStart  = &ch[i];
				}
			}
		}
		state.prevChar = ch[i];
	} //for (unsigned i = 0; i < length; ++i)
	
	//why not use -copy? because this is subclass-friendly.
	//you can call this method on NSMutableDictionary and get a mutable dictionary back.
	result = [[self alloc] initWithDictionary:mutableDict];
end:
	[pool release];

	return [result autorelease];
}

@end

@implementation NSColor (AIColorAdditions_RGBTxtFiles)

+ (NSDictionary *)colorNamesDictionary
{
	if (!RGBColorValues) {
		RGBColorValues = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
						  [NSColor colorWithHTMLString:@"#000"],    @"black",
						  [NSColor colorWithHTMLString:@"#c0c0c0"], @"silver",
						  [NSColor colorWithHTMLString:@"#808080"], @"gray",
						  [NSColor colorWithHTMLString:@"#808080"], @"grey",
						  [NSColor colorWithHTMLString:@"#fff"],    @"white",
						  [NSColor colorWithHTMLString:@"#800000"], @"maroon",
						  [NSColor colorWithHTMLString:@"#f00"],    @"red",
						  [NSColor colorWithHTMLString:@"#800080"], @"purple",
						  [NSColor colorWithHTMLString:@"#f0f"],    @"fuchsia",
						  [NSColor colorWithHTMLString:@"#008000"], @"green",
						  [NSColor colorWithHTMLString:@"#0f0"],    @"lime",
						  [NSColor colorWithHTMLString:@"#808000"], @"olive",
						  [NSColor colorWithHTMLString:@"#ff0"],    @"yellow",
						  [NSColor colorWithHTMLString:@"#000080"], @"navy",
						  [NSColor colorWithHTMLString:@"#00f"],    @"blue",
						  [NSColor colorWithHTMLString:@"#008080"], @"teal",
						  [NSColor colorWithHTMLString:@"#0ff"],    @"aqua",
						  nil];
		NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:defaultRGBTxtLocation1 error:NULL];
		for (NSString *middlePath in paths) {
			NSString *path = [defaultRGBTxtLocation1 stringByAppendingPathComponent:[middlePath stringByAppendingPathComponent:defaultRGBTxtLocation2]];
			NSDictionary *extraColors = [NSDictionary dictionaryWithContentsOfRGBTxtFile:path];
			[RGBColorValues addEntriesFromDictionary:extraColors];
			if (extraColors) {
#if COLOR_DEBUG
				NSLog(@"Got colour values from %@", path);
#endif
				break;
			}
		}
	}
	return RGBColorValues;
}

@end

@implementation NSColor (AIColorAdditions_Comparison)

//Returns YES if the colors are equal
- (BOOL)equalToRGBColor:(NSColor *)inColor
{
    NSColor	*convertedA = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    NSColor	*convertedB = [inColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return (([convertedA redComponent]   == [convertedB redComponent])   &&
            ([convertedA blueComponent]  == [convertedB blueComponent])  &&
            ([convertedA greenComponent] == [convertedB greenComponent]) &&
            ([convertedA alphaComponent] == [convertedB alphaComponent]));
}

@end

@implementation NSColor (AIColorAdditions_DarknessAndContrast)

//Returns YES if this color is dark
- (BOOL)colorIsDark
{
    return ([[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] brightnessComponent] < 0.5);
}

- (BOOL)colorIsMedium
{
	float brightness = [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] brightnessComponent];
	return (0.35 < brightness && brightness < 0.65);
}

//Percent should be -1.0 to 1.0 (negatives will make the color brighter)
- (NSColor *)darkenBy:(float)amount
{
    NSColor	*convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return [NSColor colorWithCalibratedHue:[convertedColor hueComponent]
                                saturation:[convertedColor saturationComponent]
                                brightness:([convertedColor brightnessComponent] - amount)
                                     alpha:[convertedColor alphaComponent]];
}

- (NSColor *)darkenAndAdjustSaturationBy:(float)amount
{
    NSColor	*convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    return [NSColor colorWithCalibratedHue:[convertedColor hueComponent]
                                saturation:(([convertedColor saturationComponent] == 0.0) ? [convertedColor saturationComponent] : ([convertedColor saturationComponent] + amount))
                                brightness:([convertedColor brightnessComponent] - amount)
                                     alpha:[convertedColor alphaComponent]];
}

//Inverts the luminance of this color so it looks good on selected/dark backgrounds
- (NSColor *)colorWithInvertedLuminance
{
    CGFloat h,l,s;

	NSColor *convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

    //Get our HLS
    [convertedColor getHue:&h saturation:&s brightness:&l alpha:NULL];

    //Invert L
    l = 1.0 - l;

    //Return the new color
    return [NSColor colorWithCalibratedHue:h saturation:s brightness:l alpha:1.0];
}

//Returns a color that contrasts well with this one
- (NSColor *)contrastingColor
{
	if ([self colorIsMedium]) {
		if ([self colorIsDark])
			return [NSColor whiteColor];
		else
			return [NSColor blackColor];

	} else {
		NSColor *rgbColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		return [NSColor colorWithCalibratedRed:(1.0 - [rgbColor redComponent])
										 green:(1.0 - [rgbColor greenComponent])
										  blue:(1.0 - [rgbColor blueComponent])
										 alpha:1.0];
	}
}

@end

@implementation NSColor (AIColorAdditions_HLS)

//Linearly adjust a color
#define cap(x) { if (x < 0) {x = 0;} else if (x > 1) {x = 1;} }
- (NSColor *)adjustHue:(CGFloat)dHue saturation:(CGFloat)dSat brightness:(CGFloat)dBrit
{
    CGFloat hue, sat, brit, alpha;
    
    [self getHue:&hue saturation:&sat brightness:&brit alpha:&alpha];

	//For some reason, redColor's hue is 1.0f, not 0.0f, as of Mac OS X 10.4.10 and 10.5.2. Therefore, we must normalize any multiple of 1.0 to 0.0. We do this by taking the remainder of hue ÷ 1.
	hue = fmodf(hue, 1.0f);

    hue += dHue;
    cap(hue);
    sat += dSat;
    cap(sat);
    brit += dBrit;
    cap(brit);
    
    return [NSColor colorWithCalibratedHue:hue saturation:sat brightness:brit alpha:alpha];
}

@end

@implementation NSColor (AIColorAdditions_RepresentingColors)

- (NSString *)hexString
{
    CGFloat 	red,green,blue;
    char	hexString[7];
    int		tempNum;
    NSColor	*convertedColor;

    convertedColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [convertedColor getRed:&red green:&green blue:&blue alpha:NULL];
    
    tempNum = (red * 255.0f);
    hexString[0] = intToHex(tempNum / 16);
    hexString[1] = intToHex(tempNum % 16);

    tempNum = (green * 255.0f);
    hexString[2] = intToHex(tempNum / 16);
    hexString[3] = intToHex(tempNum % 16);

    tempNum = (blue * 255.0f);
    hexString[4] = intToHex(tempNum / 16);
    hexString[5] = intToHex(tempNum % 16);
    hexString[6] = '\0';
    
    return [NSString stringWithUTF8String:hexString];
}

//String representation: R,G,B[,A].
- (NSString *)stringRepresentation
{
    NSColor	*tempColor = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	float alphaComponent = [tempColor alphaComponent];

	if (alphaComponent == 1.0) {
		return [NSString stringWithFormat:@"%d,%d,%d",
			(int)([tempColor redComponent] * 255.0),
			(int)([tempColor greenComponent] * 255.0),
			(int)([tempColor blueComponent] * 255.0)];

	} else {
		return [NSString stringWithFormat:@"%d,%d,%d,%d",
			(int)([tempColor redComponent] * 255.0),
			(int)([tempColor greenComponent] * 255.0),
			(int)([tempColor blueComponent] * 255.0),
			(int)(alphaComponent * 255.0)];		
	}
}

- (NSString *)CSSRepresentation
{
	float alpha = [self alphaComponent];
	if ((1.0 - alpha) >= 0.000001) {
		NSColor *rgb = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
		//CSS3 defines rgba() to take 0..255 for the color components, but 0..1 for the alpha component. Thus, we must multiply by 255 for the color components, but not for the alpha component.
		return [NSString stringWithFormat:@"rgba(%@,%@,%@,%@)",
			[NSString stringWithFloat:[rgb redComponent]   * 255.0f maxDigits:6],
			[NSString stringWithFloat:[rgb greenComponent] * 255.0f maxDigits:6],
			[NSString stringWithFloat:[rgb blueComponent]  * 255.0f maxDigits:6],
			[NSString stringWithFloat:alpha                         maxDigits:6]];
	} else {
		return [@"#" stringByAppendingString:[self hexString]];
	}
}

@end

@implementation NSString (AIColorAdditions_RepresentingColors)

- (NSColor *)representedColor
{
    unsigned int	r = 255, g = 255, b = 255;
    unsigned int	a = 255;

	const char *selfUTF8 = [self UTF8String];
	
	//format: r,g,b[,a]
	//all components are decimal numbers 0..255.
	if (!isdigit(*selfUTF8)) goto scanFailed;
	r = strtoul(selfUTF8, (char **)&selfUTF8, /*base*/ 10);

	if(*selfUTF8 == ',') ++selfUTF8;
	else                 goto scanFailed;

	if (!isdigit(*selfUTF8)) goto scanFailed;
	g = strtoul(selfUTF8, (char **)&selfUTF8, /*base*/ 10);
	if(*selfUTF8 == ',') ++selfUTF8;
	else                 goto scanFailed;

	if (!isdigit(*selfUTF8)) goto scanFailed;
	b = strtoul(selfUTF8, (char **)&selfUTF8, /*base*/ 10);
	if (*selfUTF8 == ',') {
		++selfUTF8;
		a = strtoul(selfUTF8, (char **)&selfUTF8, /*base*/ 10);

		if (*selfUTF8) goto scanFailed;
	} else if (*selfUTF8 != '\0') {
		goto scanFailed;
	}

    return [NSColor colorWithCalibratedRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:(a/255.0)] ;
scanFailed:
	return nil;
}

- (NSColor *)representedColorWithAlpha:(float)alpha
{
	//this is the same as above, but the alpha component is overridden.

    unsigned int	r, g, b;

	const char *selfUTF8 = [self UTF8String];
	
	//format: r,g,b
	//all components are decimal numbers 0..255.
	if (!isdigit(*selfUTF8)) goto scanFailed;
	r = strtoul(selfUTF8, (char **)&selfUTF8, /*base*/ 10);

	if (*selfUTF8 != ',') goto scanFailed;
	++selfUTF8;

	if (!isdigit(*selfUTF8)) goto scanFailed;
	g = strtoul(selfUTF8, (char **)&selfUTF8, /*base*/ 10);

	if (*selfUTF8 != ',') goto scanFailed;
	++selfUTF8;

	if (!isdigit(*selfUTF8)) goto scanFailed;
	b = strtoul(selfUTF8, (char **)&selfUTF8, /*base*/ 10);

    return [NSColor colorWithCalibratedRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:alpha];
scanFailed:
	return nil;
}

@end

@implementation NSColor (AIColorAdditions_RandomColor)

+ (NSColor *)randomColor
{
	return [NSColor colorWithCalibratedRed:(arc4random() % 65536) / 65536.0
	                                 green:(arc4random() % 65536) / 65536.0
	                                  blue:(arc4random() % 65536) / 65536.0
	                                 alpha:1.0];
}
+ (NSColor *)randomColorWithAlpha
{
	return [NSColor colorWithCalibratedRed:(arc4random() % 65536) / 65536.0
	                                 green:(arc4random() % 65536) / 65536.0
	                                  blue:(arc4random() % 65536) / 65536.0
	                                 alpha:(arc4random() % 65536) / 65536.0];
}

@end

@implementation NSColor (AIColorAdditions_HTMLSVGCSSColors)

+ (id)colorWithHTMLString:(NSString *)str
{
	return [self colorWithHTMLString:str defaultColor:nil];
}

/*!
 * @brief Convert one or two hex characters to a float
 *
 * @param firstChar The first hex character
 * @param secondChar The second hex character, or 0x0 if only one character is to be used
 * @result The float value. Returns 0 as a bailout value if firstChar or secondChar are not valid hexadecimal characters ([0-9]|[A-F]|[a-f]). Also returns 0 if firstChar and secondChar equal 0.
 */
static float hexCharsToFloat(char firstChar, char secondChar)
{
	float	hexValue;
	int		firstDigit;
	firstDigit = hexToInt(firstChar);
	if (firstDigit != -1) {
		hexValue = firstDigit;
		if (secondChar != 0x0) {
			int secondDigit = hexToInt(secondChar);
			if (secondDigit != -1)
				hexValue = (hexValue * 16.0 + secondDigit) / 255.0;
			else
				hexValue = 0;
		} else {
			hexValue /= 15.0;
		}

	} else {
		hexValue = 0;
	}

	return hexValue;
}

+ (id)colorWithHTMLString:(NSString *)str defaultColor:(NSColor *)defaultColor
{
	if (!str) return defaultColor;

	unsigned strLength = [str length];
	
	NSString *colorValue = str;
	
	if ([str hasPrefix:@"rgb"]) {
		NSUInteger leftParIndex = [colorValue rangeOfString:@"("].location;
		NSUInteger rightParIndex = [colorValue rangeOfString:@")"].location;
		if (leftParIndex == NSNotFound || rightParIndex == NSNotFound)
		{
			NSLog(@"+[NSColor(AIColorAdditions) colorWithHTMLString:] called with unrecognised color function (str is %@); returning %@", str, defaultColor);
			return defaultColor;
		}
		leftParIndex++;
		NSRange substrRange = NSMakeRange(leftParIndex, rightParIndex - leftParIndex);
		colorValue = [colorValue substringWithRange:substrRange];
		NSArray *colorComponents = [colorValue componentsSeparatedByString:@","];
		if ([colorComponents count] < 3 || [colorComponents count] > 4) {
			NSLog(@"+[NSColor(AIColorAdditions) colorWithHTMLString:] called with a color function with the wrong number of arguments (str is %@); returning %@", str, defaultColor);
			return defaultColor;
		}
		float red, green, blue, alpha = 1.0f;
		red = [[colorComponents objectAtIndex:0] floatValue];
		green = [[colorComponents objectAtIndex:1] floatValue];
		blue = [[colorComponents objectAtIndex:2] floatValue];
		if ([colorComponents count] == 4)
			alpha = [[colorComponents objectAtIndex:3] floatValue];
		return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
	}
	
	if ((!strLength) || ([str characterAtIndex:0] != '#')) {
		//look it up; it's a colour name
		NSDictionary *colorValues = [self colorNamesDictionary];
		colorValue = [colorValues objectForKey:str];
		if (!colorValue) colorValue = [colorValues objectForKey:[str lowercaseString]];
		if (!colorValue) {
#if COLOR_DEBUG
			NSLog(@"+[NSColor(AIColorAdditions) colorWithHTMLString:] called with unrecognised color name (str is %@); returning %@", str, defaultColor);
#endif
			return defaultColor;
		}
	}

	//we need room for at least 9 characters (#00ff00ff) plus the NUL terminator.
	//this array is 12 bytes long because I like multiples of four. ;)
	enum { hexStringArrayLength = 12 };
	size_t hexStringLength = 0;
	char hexStringArray[hexStringArrayLength] = { 0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0, };
	{
		NSData *stringData = [str dataUsingEncoding:NSUTF8StringEncoding];
		hexStringLength = [stringData length];
		//subtract 1 because we don't want to overwrite that last NUL.
		memcpy(hexStringArray, [stringData bytes], MIN(hexStringLength, hexStringArrayLength - 1));
	}
	const char *hexString = hexStringArray;

	float 	red,green,blue;
	float	alpha = 1.0;

	//skip # if present.
	if (*hexString == '#') {
		++hexString;
		--hexStringLength;
	}

	if (hexStringLength < 3) {
#if COLOR_DEBUG
		NSLog(@"+[%@ colorWithHTMLString:] called with a string that cannot possibly be a hexadecimal color specification (e.g. #ff0000, #00b, #cc08) (string: %@ input: %@); returning %@", NSStringFromClass(self), colorValue, str, defaultColor);
#endif
		return defaultColor;
	}

	//long specification:  #rrggbb[aa]
	//short specification: #rgb[a]
	//e.g. these all specify pure opaque blue: #0000ff #00f #0000ffff #00ff
	BOOL isLong = hexStringLength > 4;

	//for a long component c = 'xy':
	//	c = (x * 0x10 + y) / 0xff
	//for a short component c = 'x':
	//	c = x / 0xf

	char firstChar, secondChar;
	
	firstChar = *(hexString++);
	secondChar = (isLong ? *(hexString++) : 0x0);
	red = hexCharsToFloat(firstChar, secondChar);

	firstChar = *(hexString++);
	secondChar = (isLong ? *(hexString++) : 0x0);
	green = hexCharsToFloat(firstChar, secondChar);

	firstChar = *(hexString++);
	secondChar = (isLong ? *(hexString++) : 0x0);
	blue = hexCharsToFloat(firstChar, secondChar);

	if (*hexString) {
		//we still have one more component to go: this is alpha.
		//without this component, alpha defaults to 1.0 (see initialiser above).
		firstChar = *(hexString++);
		secondChar = (isLong ? *(hexString++) : 0x0);
		alpha = hexCharsToFloat(firstChar, secondChar);
	}

	return [self colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

@end

@implementation NSColor (AIColorAdditions_ObjectColor)

+ (NSString *)representedColorForObject: (id)anObject withValidColors: (NSArray *)validColors
{
	NSArray *validColorsArray = validColors;

	if (!validColorsArray || [validColorsArray count] == 0) {
		if (!defaultValidColors) {
			defaultValidColors = VALID_COLORS_ARRAY;
		}
		validColorsArray = defaultValidColors;
	}

	return [validColorsArray objectAtIndex:([anObject hash] % ([validColorsArray count]))];
}

@end

//Convert hex to an int
int hexToInt(char hex)
{
    if (hex >= '0' && hex <= '9') {
        return (hex - '0');
    } else if (hex >= 'a' && hex <= 'f') {
        return (hex - 'a' + 10);
    } else if (hex >= 'A' && hex <= 'F') {
        return (hex - 'A' + 10);
    } else {
        return -1;
    }
}

//Convert int to a hex
char intToHex(int digit)
{
    if (digit > 9) {
		if (digit <= 0xf) {
			return ('a' + digit - 10);
		}
    } else if (digit >= 0) {
        return ('0' + digit);
    }

	return '\0'; //NUL
}
