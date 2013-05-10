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

#import "TestColorAdditions.h"

#import <AIUtilities/AIColorAdditions.h>

//Test strings chosen by hand from output of dissociated-press on the Adium blog as of 2008-03-02.
#define TEST_STRING_1 @"We've fixes failure code IS want to videopletely unable to downly hope."
#define TEST_STRING_2 @"Adium hase. It's it wildbot. This a reality of Adium. You add both acheFly!"
#define TEST_STRING_3 @"We're proud to a misperception his blog. Now your patience, so include That means you!"
#define TEST_STRING_4 @"Great fort this is powerful numberted, but and thuse everyone has no way to a closedish, Russiate it!"
#define TEST_STRING_5 @"You capacith this by having testing: there's sting AV coming from other Skype?"
#define TEST_STRING_6 @"To can rience lawyers involvement in the most from the publicant progres is not running and tell you what we did pas alway or may not be submits IP. If the IP hunt down bugs will beta iterat yet."
#define TEST_STRING_7 @"What about stransfers, bettelephoo!"

@implementation TestColorAdditions

#pragma mark -equalToRGBColor:
- (void)testCompareEqualColors
{
	NSColor *colorA = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	NSColor *colorB = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	STAssertTrue([colorA equalToRGBColor:colorB], @"Two colors with equal R, G, B, and A must compare equal");
}
- (void)testCompareColorsInequalInRed
{
	NSColor *colorA = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	NSColor *colorB = [NSColor colorWithCalibratedRed:0.0f green:1.0f blue:1.0f alpha:1.0f];
	//                                                ^ The difference
	STAssertFalse([colorA equalToRGBColor:colorB], @"Two colors with inequal R must compare equal");
}
- (void)testCompareColorsInequalInGreen
{
	NSColor *colorA = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	NSColor *colorB = [NSColor colorWithCalibratedRed:1.0f green:0.0f blue:1.0f alpha:1.0f];
	//                                                          ^ The difference
	STAssertFalse([colorA equalToRGBColor:colorB], @"Two colors with inequal G must compare equal");
}
- (void)testCompareColorsInequalInBlue
{
	NSColor *colorA = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	NSColor *colorB = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:0.0f alpha:1.0f];
	//                                                                   ^ The difference
	STAssertFalse([colorA equalToRGBColor:colorB], @"Two colors with inequal B must compare equal");
}
- (void)testCompareColorsInequalInAlpha
{
	NSColor *colorA = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	NSColor *colorB = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:0.0f];
	//                                                                             ^ The difference
	STAssertFalse([colorA equalToRGBColor:colorB], @"Two colors with inequal A must compare equal");
}

#pragma mark -colorIsDark
- (void)testWhiteColorIsDark
{
	STAssertFalse([[NSColor whiteColor] colorIsDark], @"White is not dark");
}
- (void)testBlackColorIsDark
{
	STAssertTrue([[NSColor blackColor] colorIsDark], @"Black is dark");
}

#pragma mark -colorIsMedium
- (void)testWhiteColorIsMedium
{
	STAssertFalse([[NSColor whiteColor] colorIsMedium], @"White is not medium");
}
- (void)testGrayColorIsMedium
{
	STAssertTrue([[NSColor grayColor] colorIsMedium], @"Gray is medium");
}
- (void)testBlackColorIsMedium
{
	STAssertFalse([[NSColor blackColor] colorIsMedium], @"Black is not medium");
}

#pragma mark -darkenBy:
- (void)testDarkenRed
{
	NSColor *red = [NSColor redColor];
	STAssertEquals([red redComponent], (CGFloat)1.0f, @"Expected red's red component to be 1.0f");
	NSColor *redDarkened = [red darkenBy:0.5f];
	STAssertEquals([redDarkened redComponent],   (CGFloat)0.5f, @"Darkening red by 0.5 should result in 0.5, 0, 0");
	STAssertEquals([redDarkened greenComponent], [red greenComponent], @"Darkening red by 0.5 should not change its green");
	STAssertEquals([redDarkened blueComponent],  [red blueComponent],  @"Darkening red by 0.5 should not change its blue");
}

#pragma mark -darkenAndAdjustSaturationBy:
//Pure red already has 1.0 saturation, so this method has the same effect on it as darkenBy:.
- (void)testDarkenAndSaturateRed
{
	NSColor *red = [NSColor redColor];
	STAssertEquals([red redComponent], (CGFloat)1.0f, @"Expected red's red component to be 1.0");
	NSColor *redDarkened = [red darkenBy:0.5f];
	STAssertEquals([redDarkened redComponent],   (CGFloat)0.5f, @"Darkening and saturating red by 0.5 should result in 0.5, 0, 0");
	STAssertEquals([redDarkened greenComponent], [red greenComponent], @"Darkening and saturating red by 0.5 should not change its green");
	STAssertEquals([redDarkened blueComponent],  [red blueComponent],  @"Darkening and saturating red by 0.5 should not change its blue");
}
- (void)testDarkenAndSaturatePink
{
	NSColor *pink = [NSColor colorWithCalibratedHue:0.0f
										 saturation:0.5f //This is what makes it pink, rather than red.
										 brightness:1.0f
											  alpha:1.0f];
	STAssertEquals([pink   redComponent], (CGFloat)1.0f, @"Expected pink's red component to be 1.0");
	STAssertEquals([pink greenComponent], (CGFloat)0.5f, @"Expected pink's green component to be 0.5");
	STAssertEquals([pink  blueComponent], (CGFloat)0.5f, @"Expected pink's blue component to be 0.5");
	NSColor *pinkDarkened = [pink darkenBy:0.5f];
	STAssertEquals([pinkDarkened   redComponent], (CGFloat)0.5f, @"Darkening and saturating pink by 0.5 should result in 0.5, 0.25, 0.25");
	STAssertEquals([pinkDarkened greenComponent], (CGFloat)0.25f, @"Darkening and saturating pink by 0.5 should result in 0.5, 0.25, 0.25");
	STAssertEquals([pinkDarkened  blueComponent], (CGFloat)0.25f, @"Darkening and saturating pink by 0.5 should result in 0.5, 0.25, 0.25");
}

#pragma mark -colorWithInvertedLuminance
- (void)testInvertLuminanceOfWhite
{
	NSColor *white = [NSColor whiteColor];
	NSColor *black = [white colorWithInvertedLuminance];
	STAssertEquals([black   redComponent], (CGFloat)1.0f - [white whiteComponent], @"White, luminance-inverted, should be black (red component should be %f",   (CGFloat)1.0f - [white whiteComponent]);
	STAssertEquals([black greenComponent], (CGFloat)1.0f - [white whiteComponent], @"White, luminance-inverted, should be black (green component should be %f", (CGFloat)1.0f - [white whiteComponent]);
	STAssertEquals([black  blueComponent], (CGFloat)1.0f - [white whiteComponent], @"White, luminance-inverted, should be black (blue component should be %f",  (CGFloat)1.0f - [white whiteComponent]);
}
- (void)testInvertLuminanceOfBlack
{
	NSColor *black = [NSColor blackColor];
	NSColor *white = [black colorWithInvertedLuminance];
	STAssertEquals([white   redComponent], (CGFloat)1.0f - [black whiteComponent], @"Black, luminance-inverted, should be white (red component should be %f",   (CGFloat)1.0f - [white whiteComponent]);
	STAssertEquals([white greenComponent], (CGFloat)1.0f - [black whiteComponent], @"Black, luminance-inverted, should be white (green component should be %f", (CGFloat)1.0f - [white whiteComponent]);
	STAssertEquals([white  blueComponent], (CGFloat)1.0f - [black whiteComponent], @"Black, luminance-inverted, should be white (blue component should be %f",  (CGFloat)1.0f - [white whiteComponent]);
}
- (void)testInvertLuminanceOfRed
{
	NSColor *red = [NSColor redColor];
	NSColor *black = [red colorWithInvertedLuminance];
	STAssertEquals([black   redComponent], (CGFloat)0.0f, @"Red, luminance-inverted, should be black");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Red, luminance-inverted, should not have any green");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f, @"Red, luminance-inverted, should not have any blue");
}

#pragma mark -contrastingColor
- (void)testContrastingColorForWhite
{
	NSColor *white = [NSColor whiteColor];
	NSColor *contrastingColor = [white contrastingColor];
	//contrastingColor inverts the R, G, and B components if the receiver is not medium, so its result will be in an RGB color space. This is why we compare its RGB components rather than its white component (it has no white component).
	STAssertEquals([contrastingColor   redComponent], (CGFloat)0.0f, @"White's contrasting color should be black (its red component should be 0)");
	STAssertEquals([contrastingColor greenComponent], (CGFloat)0.0f, @"White's contrasting color should be black (its green component should be 0)");
	STAssertEquals([contrastingColor  blueComponent], (CGFloat)0.0f, @"White's contrasting color should be black (its blue component should be 0)");
}
- (void)testContrastingColorForBlack
{
	NSColor *black = [NSColor blackColor];
	NSColor *contrastingColor = [black contrastingColor];
	//contrastingColor inverts the R, G, and B components if the receiver is not medium, so its result will be in an RGB color space. This is why we compare its RGB components rather than its white component (it has no white component).
	STAssertEquals([contrastingColor   redComponent], (CGFloat)1.0f, @"Black's contrasting color should be white (its red component should be 1)");
	STAssertEquals([contrastingColor greenComponent], (CGFloat)1.0f, @"Black's contrasting color should be white (its green component should be 1)");
	STAssertEquals([contrastingColor  blueComponent], (CGFloat)1.0f, @"Black's contrasting color should be white (its blue component should be 1)");
}
- (void)testContrastingColorForGray
{
	NSColor *gray = [NSColor grayColor];
	//Gray's whiteComponent is 0.5. This is medium, but not dark. As such, its contrasting color should be black.
	NSColor *contrastingColor = [gray contrastingColor];
	STAssertEquals([contrastingColor whiteComponent], (CGFloat)0.0f, @"Gray's contrasting color should be black");
}

#pragma mark -adjustHue:saturation:brightness:
//Hue += 1/3
- (void)testAdjustRedToGreen
{
	NSColor *red = [NSColor redColor];
	NSColor *green = [red adjustHue:(CGFloat)(+(1.0 / 3.0)) saturation:0.0f brightness:0.0f];
	STAssertEquals([green   redComponent], (CGFloat)0.0,   @"Red component of green should be 0");
	STAssertEquals([green greenComponent], (CGFloat)1.0, @"Green component of green should be 1");
	STAssertEquals([green  blueComponent], (CGFloat)0.0,  @"Blue component of green should be 0");
}
//Saturation -= 1
- (void)testAdjustRedToWhite
{
	NSColor *red = [NSColor redColor];
	NSColor *white = [red adjustHue:0.0f saturation:-1.0f brightness:0.0f];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of green should be 1");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1");
}
//Brightness -= 1
- (void)testAdjustRedToBlack
{
	NSColor *red = [NSColor redColor];
	NSColor *white = [red adjustHue:0.0f saturation:0.0f brightness:-1.0f];
	STAssertEquals([white   redComponent], (CGFloat)0.0f,   @"Red component of white should be 0");
	STAssertEquals([white greenComponent], (CGFloat)0.0f, @"Green component of green should be 0");
	STAssertEquals([white  blueComponent], (CGFloat)0.0f,  @"Blue component of white should be 0");
}

#pragma mark -hexString
- (void)testHexStringForRed
{
	NSColor *color = [NSColor redColor];
	NSString *correctString = @"ff0000";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for red should be %@", correctString);
}
- (void)testHexStringForYellow
{
	NSColor *color = [NSColor yellowColor];
	NSString *correctString = @"ffff00";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for yellow should be %@", correctString);
}
- (void)testHexStringForGreen
{
	NSColor *color = [NSColor greenColor];
	NSString *correctString = @"00ff00";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for green should be %@", correctString);
}
- (void)testHexStringForCyan
{
	NSColor *color = [NSColor cyanColor];
	NSString *correctString = @"00ffff";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for cyan should be %@", correctString);
}
- (void)testHexStringForBlue
{
	NSColor *color = [NSColor blueColor];
	NSString *correctString = @"0000ff";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for blue should be %@", correctString);
}
- (void)testHexStringForMagenta
{
	NSColor *color = [NSColor magentaColor];
	NSString *correctString = @"ff00ff";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for magenta should be %@", correctString);
}
- (void)testHexStringForWhite
{
	NSColor *color = [NSColor whiteColor];
	NSString *correctString = @"ffffff";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for white should be %@", correctString);
}
- (void)testHexStringForBlack
{
	NSColor *color = [NSColor blackColor];
	NSString *correctString = @"000000";
	STAssertEqualObjects([color hexString], correctString, @"Hex string for black should be %@", correctString);
}

#pragma mark -stringRepresentation
- (void)testStringRepresentationForRed
{
	NSColor *color = [NSColor redColor];
	NSString *correctString = @"255,0,0";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for red should be %@", correctString);
}
- (void)testStringRepresentationForYellow
{
	NSColor *color = [NSColor yellowColor];
	NSString *correctString = @"255,255,0";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for yellow should be %@", correctString);
}
- (void)testStringRepresentationForGreen
{
	NSColor *color = [NSColor greenColor];
	NSString *correctString = @"0,255,0";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for green should be %@", correctString);
}
- (void)testStringRepresentationForCyan
{
	NSColor *color = [NSColor cyanColor];
	NSString *correctString = @"0,255,255";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for cyan should be %@", correctString);
}
- (void)testStringRepresentationForBlue
{
	NSColor *color = [NSColor blueColor];
	NSString *correctString = @"0,0,255";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for blue should be %@", correctString);
}
- (void)testStringRepresentationForMagenta
{
	NSColor *color = [NSColor magentaColor];
	NSString *correctString = @"255,0,255";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for magenta should be %@", correctString);
}
- (void)testStringRepresentationForWhite
{
	NSColor *color = [NSColor whiteColor];
	NSString *correctString = @"255,255,255";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for white should be %@", correctString);
}
- (void)testStringRepresentationForBlack
{
	NSColor *color = [NSColor blackColor];
	NSString *correctString = @"0,0,0";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for black should be %@", correctString);
}

- (void)testStringRepresentationForSemiTransparentRed
{
	NSColor *color = [[NSColor redColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"255,0,0,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for red should be %@", correctString);
}
- (void)testStringRepresentationForSemiTransparentYellow
{
	NSColor *color = [[NSColor yellowColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"255,255,0,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for yellow should be %@", correctString);
}
- (void)testStringRepresentationForSemiTransparentGreen
{
	NSColor *color = [[NSColor greenColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"0,255,0,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for green should be %@", correctString);
}
- (void)testStringRepresentationForSemiTransparentCyan
{
	NSColor *color = [[NSColor cyanColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"0,255,255,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for cyan should be %@", correctString);
}
- (void)testStringRepresentationForSemiTransparentBlue
{
	NSColor *color = [[NSColor blueColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"0,0,255,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for blue should be %@", correctString);
}
- (void)testStringRepresentationForSemiTransparentMagenta
{
	NSColor *color = [[NSColor magentaColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"255,0,255,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for magenta should be %@", correctString);
}
- (void)testStringRepresentationForSemiTransparentWhite
{
	NSColor *color = [[NSColor whiteColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"255,255,255,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for white should be %@", correctString);
}
- (void)testStringRepresentationForSemiTransparentBlack
{
	NSColor *color = [[NSColor blackColor] colorWithAlphaComponent:0.5f];
	NSString *correctString = @"0,0,0,127";
	STAssertEqualObjects([color stringRepresentation], correctString, @"String representation for black should be %@", correctString);
}

#pragma mark -CSSRepresentation
- (void)testCSSRepresentationForRed
{
	NSColor *color = [NSColor redColor];
	NSString *correctString = @"#ff0000";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for red (with alpha = 1) should be %@", correctString);
}
- (void)testCSSRepresentationForYellow
{
	NSColor *color = [NSColor yellowColor];
	NSString *correctString = @"#ffff00";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for yellow (with alpha = 1) should be %@", correctString);
}
- (void)testCSSRepresentationForGreen
{
	NSColor *color = [NSColor greenColor];
	NSString *correctString = @"#00ff00";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for green (with alpha = 1) should be %@", correctString);
}
- (void)testCSSRepresentationForCyan
{
	NSColor *color = [NSColor cyanColor];
	NSString *correctString = @"#00ffff";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for cyan (with alpha = 1) should be %@", correctString);
}
- (void)testCSSRepresentationForBlue
{
	NSColor *color = [NSColor blueColor];
	NSString *correctString = @"#0000ff";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for blue (with alpha = 1) should be %@", correctString);
}
- (void)testCSSRepresentationForMagenta
{
	NSColor *color = [NSColor magentaColor];
	NSString *correctString = @"#ff00ff";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for magenta (with alpha = 1) should be %@", correctString);
}
- (void)testCSSRepresentationForWhite
{
	NSColor *color = [NSColor whiteColor];
	NSString *correctString = @"#ffffff";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for white (with alpha = 1) should be %@", correctString);
}
- (void)testCSSRepresentationForBlack
{
	NSColor *color = [NSColor blackColor];
	NSString *correctString = @"#000000";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for black (with alpha = 1) should be %@", correctString);
}

#pragma mark -

- (void)testCSSRepresentationForSemiTransparentRed
{
	NSColor *color = [[NSColor redColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(255,0,0,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for red (with alpha = 0.5) should be %@", correctString);
}
- (void)testCSSRepresentationForSemiTransparentYellow
{
	NSColor *color = [[NSColor yellowColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(255,255,0,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for yellow (with alpha = 0.5) should be %@", correctString);
}
- (void)testCSSRepresentationForSemiTransparentGreen
{
	NSColor *color = [[NSColor greenColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(0,255,0,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for green (with alpha = 0.5) should be %@", correctString);
}
- (void)testCSSRepresentationForSemiTransparentCyan
{
	NSColor *color = [[NSColor cyanColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(0,255,255,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for cyan (with alpha = 0.5) should be %@", correctString);
}
- (void)testCSSRepresentationForSemiTransparentBlue
{
	NSColor *color = [[NSColor blueColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(0,0,255,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for blue (with alpha = 0.5) should be %@", correctString);
}
- (void)testCSSRepresentationForSemiTransparentMagenta
{
	NSColor *color = [[NSColor magentaColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(255,0,255,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for magenta (with alpha = 0.5) should be %@", correctString);
}
- (void)testCSSRepresentationForSemiTransparentWhite
{
	NSColor *color = [[NSColor whiteColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(255,255,255,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for white (with alpha = 0.5) should be %@", correctString);
}
- (void)testCSSRepresentationForSemiTransparentBlack
{
	NSColor *color = [[NSColor blackColor] colorWithAlphaComponent:(CGFloat)0.5f];
	NSString *correctString = @"rgba(0,0,0,0.5)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for black (with alpha = 0.5) should be %@", correctString);
}

#pragma mark -

- (void)testCSSRepresentationForTransparentRed
{
	NSColor *color = [[NSColor redColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(255,0,0,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for red (with alpha = 0) should be %@", correctString);
}
- (void)testCSSRepresentationForTransparentYellow
{
	NSColor *color = [[NSColor yellowColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(255,255,0,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for yellow (with alpha = 0) should be %@", correctString);
}
- (void)testCSSRepresentationForTransparentGreen
{
	NSColor *color = [[NSColor greenColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(0,255,0,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for green (with alpha = 0) should be %@", correctString);
}
- (void)testCSSRepresentationForTransparentCyan
{
	NSColor *color = [[NSColor cyanColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(0,255,255,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for cyan (with alpha = 0) should be %@", correctString);
}
- (void)testCSSRepresentationForTransparentBlue
{
	NSColor *color = [[NSColor blueColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(0,0,255,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for blue (with alpha = 0) should be %@", correctString);
}
- (void)testCSSRepresentationForTransparentMagenta
{
	NSColor *color = [[NSColor magentaColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(255,0,255,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for magenta (with alpha = 0) should be %@", correctString);
}
- (void)testCSSRepresentationForTransparentWhite
{
	NSColor *color = [[NSColor whiteColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(255,255,255,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for white (with alpha = 0) should be %@", correctString);
}
- (void)testCSSRepresentationForTransparentBlack
{
	NSColor *color = [[NSColor blackColor] colorWithAlphaComponent:(CGFloat)0.0f];
	NSString *correctString = @"rgba(0,0,0,0)";
	STAssertEqualObjects([color CSSRepresentation], correctString, @"CSS representation for black (with alpha = 0) should be %@", correctString);
}

#pragma mark hexToInt/intToHex
- (void)testHexToInt_DecimalNumeral
{
	STAssertEquals(hexToInt('0'), 0x0, @"'0' as hex should be 0");
	STAssertEquals(hexToInt('9'), 0x9, @"'9' as hex should be 9");
}
- (void)testHexToInt_UppercaseLetter
{
	STAssertEquals(hexToInt('A'), 0xA, @"'A' as hex should be 0xA (10)");
	STAssertEquals(hexToInt('F'), 0xF, @"'F' as hex should be 0xF (15)");
}
- (void)testHexToInt_LowercaseLetter
{
	STAssertEquals(hexToInt('a'), 0xa, @"'a' as hex should be 0xa (10)");
	STAssertEquals(hexToInt('f'), 0xf, @"'f' as hex should be 0xf (15)");
}
- (void)testHexToInt_InvalidCharacters
{
	//Outside the range '0' through '9': Invalid.
	STAssertEquals(hexToInt('0' - 1), -1, @"'%c' is not valid hex; hexToInt should return -1", '0' - 1);
	STAssertEquals(hexToInt('9' + 1), -1, @"'%c' is not valid hex; hexToInt should return -1", '9' + 1);
	//Outside the range 'a' through 'f': Invalid.
	STAssertEquals(hexToInt('a' - 1), -1, @"'%c' is not valid hex; hexToInt should return -1", 'a' - 1);
	STAssertEquals(hexToInt('f' + 1), -1, @"'%c' is not valid hex; hexToInt should return -1", 'f' + 1);
	//Outside the range 'A' through 'F': Invalid.
	STAssertEquals(hexToInt('A' - 1), -1, @"'%c' is not valid hex; hexToInt should return -1", 'A' - 1);
	STAssertEquals(hexToInt('F' + 1), -1, @"'%c' is not valid hex; hexToInt should return -1", 'F' + 1);
}
- (void)testIntToHex_0
{
	//Cast explanation: 'x' literals are ints, whereas intToHex returns a char. STAssertEquals fails if the two objects are not *exactly* the same type.
	STAssertEquals(intToHex(0x0), (char)'0', @"0 as hex should be '0'");
}
- (void)testIntToHex_15
{
	//Cast explanation: 'x' literals are ints, whereas intToHex returns a char. STAssertEquals fails if the two objects are not *exactly* the same type.
	STAssertEquals(intToHex(0xa), (char)'a', @"0xa (15) as hex should be 'a'");
}
- (void)testIntToHex_16
{
	//Cast explanation: 'x' literals are ints, whereas intToHex returns a char. STAssertEquals fails if the two objects are not *exactly* the same type.
	STAssertEquals(intToHex(16), (char)'\0', @"0xf + 1 (16) as hex should be NUL");
}
- (void)testIntToHex_Neg1
{
	//Cast explanation: 'x' literals are ints, whereas intToHex returns a char. STAssertEquals fails if the two objects are not *exactly* the same type.
	STAssertEquals(intToHex(-1), (char)'\0', @"-1 as hex should be NUL");
}

#pragma mark -representedColor
//Valid
- (void)testRepresentedColorWithThreeNonZeroComponents
{
	NSColor *white = [@"255,255,255" representedColor];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1");
}
- (void)testRepresentedColorWithThreeZeroComponents
{
	NSColor *black = [@"0,0,0" representedColor];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0");
}
- (void)testRepresentedColorWithFourNonZeroComponents;
{
	NSColor *white = [@"255,255,255,127" representedColor];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1");
	STAssertEquals([white alphaComponent], (CGFloat)127.0f / (CGFloat)255.0f, @"Alpha component of white should be %f", (CGFloat)127.0f / (CGFloat)255.0f);
}
- (void)testRepresentedColorWithFourZeroComponents;
{
	NSColor *black = [@"0,0,0,0" representedColor];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0");
	STAssertEquals([black alphaComponent], (CGFloat)0.0f, @"Alpha component of black should be 0");
}
//Invalid
- (void)testRepresentedColorWithEmptyString
{
	NSColor *noColor = [@"" representedColor];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by the empty string should be nil");
}
- (void)testRepresentedColorWithInvalidString;
{
	NSColor *noColor = [TEST_STRING_1 representedColor];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by '%@' should be nil", TEST_STRING_1);
}
- (void)testRepresentedColorWithTwoCommas;
{
	NSColor *noColor = [@",," representedColor];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by two commas should be nil");
}
- (void)testRepresentedColorWithThreeCommas;
{
	NSColor *noColor = [@",,," representedColor];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by three commas should be nil");
}
- (void)testRepresentedColorWithFourCommas
{
	NSColor *noColor = [@",,,," representedColor];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by four commas should be nil");
}

#pragma mark -representedColorWithAlpha:
//Valid
- (void)testRepresentedColorWithAlphaWithThreeNonZeroComponents
{
	NSColor *white = [@"255,255,255" representedColorWithAlpha:0.5f];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white (with alpha forced to 0.5) should be 1");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white (with alpha forced to 0.5) should be 1");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white (with alpha forced to 0.5) should be 1");
	STAssertEquals([white alphaComponent], (CGFloat)0.5f, @"Alpha component of white (with alpha forced to 0.5) should be 0.5");
}
- (void)testRepresentedColorWithAlphaWithThreeZeroComponents
{
	NSColor *black = [@"0,0,0" representedColorWithAlpha:0.5f];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black (with alpha forced to 0.5) should be 0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black (with alpha forced to 0.5) should be 0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black (with alpha forced to 0.5) should be 0");
	STAssertEquals([black alphaComponent], (CGFloat)0.5f, @"Alpha component of black (with alpha forced to 0.5) should be 0.5");
}
- (void)testRepresentedColorWithAlphaWithFourNonZeroComponents;
{
	NSColor *white = [@"255,255,255,127" representedColorWithAlpha:0.5f];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white (with alpha forced to 0.5) should be 1");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white (with alpha forced to 0.5) should be 1");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white (with alpha forced to 0.5) should be 1");
	STAssertEquals([white alphaComponent], (CGFloat)0.5f, @"Alpha component of white (with alpha forced to 0.5) should be 0.5");
}
- (void)testRepresentedColorWithAlphaWithFourZeroComponents;
{
	NSColor *black = [@"0,0,0,0" representedColorWithAlpha:0.5f];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black (with alpha forced to 0.5) should be 0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black (with alpha forced to 0.5) should be 0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black (with alpha forced to 0.5) should be 0");
	STAssertEquals([black alphaComponent], (CGFloat)0.5f, @"Alpha component of black (with alpha forced to 0.5) should be 0.5");
}
//Invalid
- (void)testRepresentedColorWithAlphaWithEmptyString
{
	NSColor *noColor = [@"" representedColorWithAlpha:0.5f];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by the empty string (with alpha forced to 0.5f) should be nil");
}
- (void)testRepresentedColorWithAlphaWithInvalidString;
{
	NSColor *noColor = [TEST_STRING_2 representedColorWithAlpha:0.5f];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by '%@' (with alpha forced to 0.5) should be nil", TEST_STRING_1);
}
- (void)testRepresentedColorWithAlphaWithTwoCommas;
{
	NSColor *noColor = [@",," representedColorWithAlpha:0.5f];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by two commas (with alpha forced to 0.5) should be nil");
}
- (void)testRepresentedColorWithAlphaWithThreeCommas;
{
	NSColor *noColor = [@",,," representedColorWithAlpha:0.5f];
	STAssertEquals(noColor, (NSColor *)nil, @"Color represented by three commas (with alpha forced to 0.5) should be nil");
}

#pragma mark -randomColor
- (void)testRandomColorHasAlpha1
{
	NSColor *color = [NSColor randomColor];
	STAssertEquals([color alphaComponent], (CGFloat)1.0f, @"Alpha component of color from +randomColor should be 1");
}

#pragma mark +colorWithHTMLString:

//These methods are automatically generated! If you want to change them, please change the program in the Utilities folder instead. Otherwise, your changes may be clobbered by the next person.
- (void)testColorWith6DigitHTMLStringForRedLowercase
{
	NSString *string = @"#ff0000";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForRedUppercase
{
	NSString *string = @"#FF0000";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForYellowLowercase
{
	NSString *string = @"#ffff00";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForYellowUppercase
{
	NSString *string = @"#FFFF00";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForGreenLowercase
{
	NSString *string = @"#00ff00";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForGreenUppercase
{
	NSString *string = @"#00FF00";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForCyanLowercase
{
	NSString *string = @"#00ffff";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForCyanUppercase
{
	NSString *string = @"#00FFFF";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForBlueLowercase
{
	NSString *string = @"#0000ff";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForBlueUppercase
{
	NSString *string = @"#0000FF";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForMagentaLowercase
{
	NSString *string = @"#ff00ff";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForMagentaUppercase
{
	NSString *string = @"#FF00FF";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForWhiteLowercase
{
	NSString *string = @"#ffffff";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForWhiteUppercase
{
	NSString *string = @"#FFFFFF";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForBlackLowercase
{
	NSString *string = @"#000000";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForBlackUppercase
{
	NSString *string = @"#000000";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
}

- (void)testColorWith3DigitHTMLStringForRedLowercase
{
	NSString *string = @"#f00";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForRedUppercase
{
	NSString *string = @"#F00";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForYellowLowercase
{
	NSString *string = @"#ff0";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForYellowUppercase
{
	NSString *string = @"#FF0";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForGreenLowercase
{
	NSString *string = @"#0f0";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForGreenUppercase
{
	NSString *string = @"#0F0";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForCyanLowercase
{
	NSString *string = @"#0ff";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForCyanUppercase
{
	NSString *string = @"#0FF";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForBlueLowercase
{
	NSString *string = @"#00f";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForBlueUppercase
{
	NSString *string = @"#00F";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForMagentaLowercase
{
	NSString *string = @"#f0f";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForMagentaUppercase
{
	NSString *string = @"#F0F";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForWhiteLowercase
{
	NSString *string = @"#fff";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForWhiteUppercase
{
	NSString *string = @"#FFF";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForBlackLowercase
{
	NSString *string = @"#000";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForBlackUppercase
{
	NSString *string = @"#000";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
}

- (void)testColorWith8DigitHTMLStringForRedLowercase
{
	NSString *string = @"#ff0000ff";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
	STAssertEquals([red alphaComponent], (CGFloat)1.0f, @"Alpha component of red should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForRedUppercase
{
	NSString *string = @"#FF0000FF";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
	STAssertEquals([red alphaComponent], (CGFloat)1.0f, @"Alpha component of red should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForYellowLowercase
{
	NSString *string = @"#ffff00ff";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
	STAssertEquals([yellow alphaComponent], (CGFloat)1.0f, @"Alpha component of yellow should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForYellowUppercase
{
	NSString *string = @"#FFFF00FF";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
	STAssertEquals([yellow alphaComponent], (CGFloat)1.0f, @"Alpha component of yellow should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForGreenLowercase
{
	NSString *string = @"#00ff00ff";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
	STAssertEquals([green alphaComponent], (CGFloat)1.0f, @"Alpha component of green should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForGreenUppercase
{
	NSString *string = @"#00FF00FF";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
	STAssertEquals([green alphaComponent], (CGFloat)1.0f, @"Alpha component of green should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForCyanLowercase
{
	NSString *string = @"#00ffffff";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
	STAssertEquals([cyan alphaComponent], (CGFloat)1.0f, @"Alpha component of cyan should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForCyanUppercase
{
	NSString *string = @"#00FFFFFF";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
	STAssertEquals([cyan alphaComponent], (CGFloat)1.0f, @"Alpha component of cyan should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForBlueLowercase
{
	NSString *string = @"#0000ffff";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
	STAssertEquals([blue alphaComponent], (CGFloat)1.0f, @"Alpha component of blue should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForBlueUppercase
{
	NSString *string = @"#0000FFFF";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
	STAssertEquals([blue alphaComponent], (CGFloat)1.0f, @"Alpha component of blue should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForMagentaLowercase
{
	NSString *string = @"#ff00ffff";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
	STAssertEquals([magenta alphaComponent], (CGFloat)1.0f, @"Alpha component of magenta should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForMagentaUppercase
{
	NSString *string = @"#FF00FFFF";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
	STAssertEquals([magenta alphaComponent], (CGFloat)1.0f, @"Alpha component of magenta should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForWhiteLowercase
{
	NSString *string = @"#ffffffff";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
	STAssertEquals([white alphaComponent], (CGFloat)1.0f, @"Alpha component of white should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForWhiteUppercase
{
	NSString *string = @"#FFFFFFFF";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
	STAssertEquals([white alphaComponent], (CGFloat)1.0f, @"Alpha component of white should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForBlackLowercase
{
	NSString *string = @"#000000ff";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
	STAssertEquals([black alphaComponent], (CGFloat)1.0f, @"Alpha component of black should be 1.0");
}
- (void)testColorWith8DigitHTMLStringForBlackUppercase
{
	NSString *string = @"#000000FF";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
	STAssertEquals([black alphaComponent], (CGFloat)1.0f, @"Alpha component of black should be 1.0");
}

- (void)testColorWith4DigitHTMLStringForRedLowercase
{
	NSString *string = @"#f00f";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
	STAssertEquals([red alphaComponent], (CGFloat)1.0f, @"Alpha component of red should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForRedUppercase
{
	NSString *string = @"#F00F";
	NSColor *red = [NSColor colorWithHTMLString:string];
	STAssertEquals([red   redComponent], (CGFloat)1.0f,   @"Red component of red should be 1.0");
	STAssertEquals([red greenComponent], (CGFloat)0.0f, @"Green component of red should be 0.0");
	STAssertEquals([red  blueComponent], (CGFloat)0.0f,  @"Blue component of red should be 0.0");
	STAssertEquals([red alphaComponent], (CGFloat)1.0f, @"Alpha component of red should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForYellowLowercase
{
	NSString *string = @"#ff0f";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
	STAssertEquals([yellow alphaComponent], (CGFloat)1.0f, @"Alpha component of yellow should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForYellowUppercase
{
	NSString *string = @"#FF0F";
	NSColor *yellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([yellow   redComponent], (CGFloat)1.0f,   @"Red component of yellow should be 1.0");
	STAssertEquals([yellow greenComponent], (CGFloat)1.0f, @"Green component of yellow should be 1.0");
	STAssertEquals([yellow  blueComponent], (CGFloat)0.0f,  @"Blue component of yellow should be 0.0");
	STAssertEquals([yellow alphaComponent], (CGFloat)1.0f, @"Alpha component of yellow should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForGreenLowercase
{
	NSString *string = @"#0f0f";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
	STAssertEquals([green alphaComponent], (CGFloat)1.0f, @"Alpha component of green should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForGreenUppercase
{
	NSString *string = @"#0F0F";
	NSColor *green = [NSColor colorWithHTMLString:string];
	STAssertEquals([green   redComponent], (CGFloat)0.0f,   @"Red component of green should be 0.0");
	STAssertEquals([green greenComponent], (CGFloat)1.0f, @"Green component of green should be 1.0");
	STAssertEquals([green  blueComponent], (CGFloat)0.0f,  @"Blue component of green should be 0.0");
	STAssertEquals([green alphaComponent], (CGFloat)1.0f, @"Alpha component of green should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForCyanLowercase
{
	NSString *string = @"#0fff";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
	STAssertEquals([cyan alphaComponent], (CGFloat)1.0f, @"Alpha component of cyan should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForCyanUppercase
{
	NSString *string = @"#0FFF";
	NSColor *cyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([cyan   redComponent], (CGFloat)0.0f,   @"Red component of cyan should be 0.0");
	STAssertEquals([cyan greenComponent], (CGFloat)1.0f, @"Green component of cyan should be 1.0");
	STAssertEquals([cyan  blueComponent], (CGFloat)1.0f,  @"Blue component of cyan should be 1.0");
	STAssertEquals([cyan alphaComponent], (CGFloat)1.0f, @"Alpha component of cyan should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForBlueLowercase
{
	NSString *string = @"#00ff";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
	STAssertEquals([blue alphaComponent], (CGFloat)1.0f, @"Alpha component of blue should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForBlueUppercase
{
	NSString *string = @"#00FF";
	NSColor *blue = [NSColor colorWithHTMLString:string];
	STAssertEquals([blue   redComponent], (CGFloat)0.0f,   @"Red component of blue should be 0.0");
	STAssertEquals([blue greenComponent], (CGFloat)0.0f, @"Green component of blue should be 0.0");
	STAssertEquals([blue  blueComponent], (CGFloat)1.0f,  @"Blue component of blue should be 1.0");
	STAssertEquals([blue alphaComponent], (CGFloat)1.0f, @"Alpha component of blue should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForMagentaLowercase
{
	NSString *string = @"#f0ff";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
	STAssertEquals([magenta alphaComponent], (CGFloat)1.0f, @"Alpha component of magenta should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForMagentaUppercase
{
	NSString *string = @"#F0FF";
	NSColor *magenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([magenta   redComponent], (CGFloat)1.0f,   @"Red component of magenta should be 1.0");
	STAssertEquals([magenta greenComponent], (CGFloat)0.0f, @"Green component of magenta should be 0.0");
	STAssertEquals([magenta  blueComponent], (CGFloat)1.0f,  @"Blue component of magenta should be 1.0");
	STAssertEquals([magenta alphaComponent], (CGFloat)1.0f, @"Alpha component of magenta should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForWhiteLowercase
{
	NSString *string = @"#ffff";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
	STAssertEquals([white alphaComponent], (CGFloat)1.0f, @"Alpha component of white should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForWhiteUppercase
{
	NSString *string = @"#FFFF";
	NSColor *white = [NSColor colorWithHTMLString:string];
	STAssertEquals([white   redComponent], (CGFloat)1.0f,   @"Red component of white should be 1.0");
	STAssertEquals([white greenComponent], (CGFloat)1.0f, @"Green component of white should be 1.0");
	STAssertEquals([white  blueComponent], (CGFloat)1.0f,  @"Blue component of white should be 1.0");
	STAssertEquals([white alphaComponent], (CGFloat)1.0f, @"Alpha component of white should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForBlackLowercase
{
	NSString *string = @"#000f";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
	STAssertEquals([black alphaComponent], (CGFloat)1.0f, @"Alpha component of black should be 1.0");
}
- (void)testColorWith4DigitHTMLStringForBlackUppercase
{
	NSString *string = @"#000F";
	NSColor *black = [NSColor colorWithHTMLString:string];
	STAssertEquals([black   redComponent], (CGFloat)0.0f,   @"Red component of black should be 0.0");
	STAssertEquals([black greenComponent], (CGFloat)0.0f, @"Green component of black should be 0.0");
	STAssertEquals([black  blueComponent], (CGFloat)0.0f,  @"Blue component of black should be 0.0");
	STAssertEquals([black alphaComponent], (CGFloat)1.0f, @"Alpha component of black should be 1.0");
}

- (void)testColorWith6DigitHTMLStringForTransparentRedLowercase
{
	NSString *string = @"#ff0000";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentRedUppercase
{
	NSString *string = @"#FF0000";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentYellowLowercase
{
	NSString *string = @"#ffff00";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentYellowUppercase
{
	NSString *string = @"#FFFF00";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentGreenLowercase
{
	NSString *string = @"#00ff00";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentGreenUppercase
{
	NSString *string = @"#00FF00";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentCyanLowercase
{
	NSString *string = @"#00ffff";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentCyanUppercase
{
	NSString *string = @"#00FFFF";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentBlueLowercase
{
	NSString *string = @"#0000ff";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentBlueUppercase
{
	NSString *string = @"#0000FF";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentMagentaLowercase
{
	NSString *string = @"#ff00ff";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentMagentaUppercase
{
	NSString *string = @"#FF00FF";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentWhiteLowercase
{
	NSString *string = @"#ffffff";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentWhiteUppercase
{
	NSString *string = @"#FFFFFF";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentBlackLowercase
{
	NSString *string = @"#000000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
}
- (void)testColorWith6DigitHTMLStringForTransparentBlackUppercase
{
	NSString *string = @"#000000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
}

- (void)testColorWith3DigitHTMLStringForTransparentRedLowercase
{
	NSString *string = @"#f00";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentRedUppercase
{
	NSString *string = @"#F00";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentYellowLowercase
{
	NSString *string = @"#ff0";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentYellowUppercase
{
	NSString *string = @"#FF0";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentGreenLowercase
{
	NSString *string = @"#0f0";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentGreenUppercase
{
	NSString *string = @"#0F0";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentCyanLowercase
{
	NSString *string = @"#0ff";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentCyanUppercase
{
	NSString *string = @"#0FF";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentBlueLowercase
{
	NSString *string = @"#00f";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentBlueUppercase
{
	NSString *string = @"#00F";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentMagentaLowercase
{
	NSString *string = @"#f0f";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentMagentaUppercase
{
	NSString *string = @"#F0F";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentWhiteLowercase
{
	NSString *string = @"#fff";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentWhiteUppercase
{
	NSString *string = @"#FFF";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentBlackLowercase
{
	NSString *string = @"#000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
}
- (void)testColorWith3DigitHTMLStringForTransparentBlackUppercase
{
	NSString *string = @"#000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
}

- (void)testColorWith8DigitHTMLStringForTransparentRedLowercase
{
	NSString *string = @"#ff000000";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
	STAssertEquals([transparentRed alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent red should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentRedUppercase
{
	NSString *string = @"#FF000000";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
	STAssertEquals([transparentRed alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent red should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentYellowLowercase
{
	NSString *string = @"#ffff0000";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
	STAssertEquals([transparentYellow alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent yellow should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentYellowUppercase
{
	NSString *string = @"#FFFF0000";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
	STAssertEquals([transparentYellow alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent yellow should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentGreenLowercase
{
	NSString *string = @"#00ff0000";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
	STAssertEquals([transparentGreen alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent green should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentGreenUppercase
{
	NSString *string = @"#00FF0000";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
	STAssertEquals([transparentGreen alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent green should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentCyanLowercase
{
	NSString *string = @"#00ffff00";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent cyan should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentCyanUppercase
{
	NSString *string = @"#00FFFF00";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent cyan should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentBlueLowercase
{
	NSString *string = @"#0000ff00";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
	STAssertEquals([transparentBlue alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent blue should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentBlueUppercase
{
	NSString *string = @"#0000FF00";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
	STAssertEquals([transparentBlue alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent blue should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentMagentaLowercase
{
	NSString *string = @"#ff00ff00";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent magenta should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentMagentaUppercase
{
	NSString *string = @"#FF00FF00";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent magenta should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentWhiteLowercase
{
	NSString *string = @"#ffffff00";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
	STAssertEquals([transparentWhite alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent white should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentWhiteUppercase
{
	NSString *string = @"#FFFFFF00";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
	STAssertEquals([transparentWhite alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent white should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentBlackLowercase
{
	NSString *string = @"#00000000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
	STAssertEquals([transparentBlack alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent black should be 0.0");
}
- (void)testColorWith8DigitHTMLStringForTransparentBlackUppercase
{
	NSString *string = @"#00000000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
	STAssertEquals([transparentBlack alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent black should be 0.0");
}

- (void)testColorWith4DigitHTMLStringForTransparentRedLowercase
{
	NSString *string = @"#f000";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
	STAssertEquals([transparentRed alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent red should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentRedUppercase
{
	NSString *string = @"#F000";
	NSColor *transparentRed = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentRed   redComponent], (CGFloat)1.0f,   @"Red component of transparent red should be 1.0");
	STAssertEquals([transparentRed greenComponent], (CGFloat)0.0f, @"Green component of transparent red should be 0.0");
	STAssertEquals([transparentRed  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent red should be 0.0");
	STAssertEquals([transparentRed alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent red should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentYellowLowercase
{
	NSString *string = @"#ff00";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
	STAssertEquals([transparentYellow alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent yellow should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentYellowUppercase
{
	NSString *string = @"#FF00";
	NSColor *transparentYellow = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentYellow   redComponent], (CGFloat)1.0f,   @"Red component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow greenComponent], (CGFloat)1.0f, @"Green component of transparent yellow should be 1.0");
	STAssertEquals([transparentYellow  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent yellow should be 0.0");
	STAssertEquals([transparentYellow alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent yellow should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentGreenLowercase
{
	NSString *string = @"#0f00";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
	STAssertEquals([transparentGreen alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent green should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentGreenUppercase
{
	NSString *string = @"#0F00";
	NSColor *transparentGreen = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentGreen   redComponent], (CGFloat)0.0f,   @"Red component of transparent green should be 0.0");
	STAssertEquals([transparentGreen greenComponent], (CGFloat)1.0f, @"Green component of transparent green should be 1.0");
	STAssertEquals([transparentGreen  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent green should be 0.0");
	STAssertEquals([transparentGreen alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent green should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentCyanLowercase
{
	NSString *string = @"#0ff0";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent cyan should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentCyanUppercase
{
	NSString *string = @"#0FF0";
	NSColor *transparentCyan = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentCyan   redComponent], (CGFloat)0.0f,   @"Red component of transparent cyan should be 0.0");
	STAssertEquals([transparentCyan greenComponent], (CGFloat)1.0f, @"Green component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent cyan should be 1.0");
	STAssertEquals([transparentCyan alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent cyan should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentBlueLowercase
{
	NSString *string = @"#00f0";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
	STAssertEquals([transparentBlue alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent blue should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentBlueUppercase
{
	NSString *string = @"#00F0";
	NSColor *transparentBlue = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlue   redComponent], (CGFloat)0.0f,   @"Red component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue greenComponent], (CGFloat)0.0f, @"Green component of transparent blue should be 0.0");
	STAssertEquals([transparentBlue  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent blue should be 1.0");
	STAssertEquals([transparentBlue alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent blue should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentMagentaLowercase
{
	NSString *string = @"#f0f0";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent magenta should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentMagentaUppercase
{
	NSString *string = @"#F0F0";
	NSColor *transparentMagenta = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentMagenta   redComponent], (CGFloat)1.0f,   @"Red component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta greenComponent], (CGFloat)0.0f, @"Green component of transparent magenta should be 0.0");
	STAssertEquals([transparentMagenta  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent magenta should be 1.0");
	STAssertEquals([transparentMagenta alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent magenta should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentWhiteLowercase
{
	NSString *string = @"#fff0";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
	STAssertEquals([transparentWhite alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent white should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentWhiteUppercase
{
	NSString *string = @"#FFF0";
	NSColor *transparentWhite = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentWhite   redComponent], (CGFloat)1.0f,   @"Red component of transparent white should be 1.0");
	STAssertEquals([transparentWhite greenComponent], (CGFloat)1.0f, @"Green component of transparent white should be 1.0");
	STAssertEquals([transparentWhite  blueComponent], (CGFloat)1.0f,  @"Blue component of transparent white should be 1.0");
	STAssertEquals([transparentWhite alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent white should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentBlackLowercase
{
	NSString *string = @"#0000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
	STAssertEquals([transparentBlack alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent black should be 0.0");
}
- (void)testColorWith4DigitHTMLStringForTransparentBlackUppercase
{
	NSString *string = @"#0000";
	NSColor *transparentBlack = [NSColor colorWithHTMLString:string];
	STAssertEquals([transparentBlack   redComponent], (CGFloat)0.0f,   @"Red component of transparent black should be 0.0");
	STAssertEquals([transparentBlack greenComponent], (CGFloat)0.0f, @"Green component of transparent black should be 0.0");
	STAssertEquals([transparentBlack  blueComponent], (CGFloat)0.0f,  @"Blue component of transparent black should be 0.0");
	STAssertEquals([transparentBlack alphaComponent], (CGFloat)0.0f, @"Alpha component of transparent black should be 0.0");
}

//End of automatically-generated methods

#pragma mark -

- (void) testColorWithRGBAString
{
	NSString *string = @"rgba(255, 255, 0, 0.75)";
	NSColor *color = [NSColor colorWithHTMLString:string];
	STAssertEquals([color redComponent], (CGFloat)1.0f, @"Red component of color should be 1.0");
	STAssertEquals([color greenComponent], (CGFloat)1.0f, @"Green component of color should be 1.0");
	STAssertEquals([color blueComponent], (CGFloat)0.0f, @"Blue component of color should be 0.0");
	STAssertEquals([color alphaComponent], (CGFloat)0.75f, @"Alpha component of color should be 0.75");
}

#pragma mark -

- (void)testColorWithHTMLStringWithNil
{
	NSColor *noColor = [NSColor colorWithHTMLString:nil];
	STAssertEquals(noColor, (NSColor *)nil, @"Color from HTML string nil should be nil");
}
- (void)testColorWithHTMLStringWithEmptyString;
{
	NSColor *noColor = [NSColor colorWithHTMLString:@""];
	STAssertEquals(noColor, (NSColor *)nil, @"Color from the empty string should be nil");
}
- (void)testColorWithHTMLStringWithInvalidColor
{
	NSColor *noColor = [NSColor colorWithHTMLString:TEST_STRING_3];
	STAssertEquals(noColor, (NSColor *)nil, @"Color from invalid string '%@' should be nil", TEST_STRING_3);
}

#pragma mark -

- (void)testColorWithHTMLStringWithNilWithDefaultColorRed;
{
	NSColor *red = [NSColor redColor];
	NSColor *color = [NSColor colorWithHTMLString:nil defaultColor:red];
	STAssertEquals(color, red, @"colorWithHTMLString:defaultColor:, when passed nil and redColor, should return redColor");
}
- (void)testColorWithHTMLStringWithNilWithDefaultColorGreen;
{
	NSColor *green = [NSColor greenColor];
	NSColor *color = [NSColor colorWithHTMLString:nil defaultColor:green];
	STAssertEquals(color, green, @"colorWithHTMLString:defaultColor:, when passed nil and greenColor, should return greenColor");
}
- (void)testColorWithHTMLStringWithNilWithDefaultColorNil;
{
	NSColor *color = [NSColor colorWithHTMLString:nil defaultColor:nil];
	STAssertEquals(color, (NSColor *)nil, @"colorWithHTMLString:defaultColor:, when passed nil (string) and nil (default color), should return nil (default color)");
}

#pragma mark -

- (void)testColorWithHTMLStringWithEmptyStringWithDefaultColorRed
{
	NSColor *red = [NSColor redColor];
	NSColor *color = [NSColor colorWithHTMLString:@"" defaultColor:red];
	STAssertEquals(color, red, @"colorWithHTMLString:defaultColor:, when passed the empty string and redColor, should return redColor");
}
- (void)testColorWithHTMLStringWithEmptyStringWithDefaultColorGreen;
{
	NSColor *green = [NSColor greenColor];
	NSColor *color = [NSColor colorWithHTMLString:@"" defaultColor:green];
	STAssertEquals(color, green, @"colorWithHTMLString:defaultColor:, when passed the empty string and greenColor, should return greenColor");
}
- (void)testColorWithHTMLStringWithEmptyStringWithDefaultColorNil;
{
	NSColor *color = [NSColor colorWithHTMLString:@"" defaultColor:nil];
	STAssertEquals(color, (NSColor *)nil, @"colorWithHTMLString:defaultColor:, when passed the empty string and nil, should return nil");
}

#pragma mark -

- (void)testColorWithHTMLStringWithInvalidColorWithDefaultColorRed
{
	NSColor *red = [NSColor redColor];
	NSColor *color = [NSColor colorWithHTMLString:TEST_STRING_4 defaultColor:red];
	STAssertEquals(color, red, @"colorWithHTMLString:defaultColor:, when passed an invalid string and redColor, should return redColor");
}
- (void)testColorWithHTMLStringWithInvalidColorWithDefaultColorGreen
{
	NSColor *green = [NSColor greenColor];
	NSColor *color = [NSColor colorWithHTMLString:TEST_STRING_5 defaultColor:green];
	STAssertEquals(color, green, @"colorWithHTMLString:defaultColor:, when passed an invalid string and greenColor, should return greenColor");
}
- (void)testColorWithHTMLStringWithInvalidColorWithDefaultColorNil
{
	NSColor *blue = [NSColor blueColor];
	NSColor *color = [NSColor colorWithHTMLString:TEST_STRING_6 defaultColor:blue];
	STAssertEquals(color, blue, @"colorWithHTMLString:defaultColor:, when passed an invalid string and blueColor, should return blueColor");
}

@end
