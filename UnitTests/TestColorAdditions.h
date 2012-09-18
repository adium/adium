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

@interface TestColorAdditions : SenTestCase {

}

#pragma mark -equalToRGBColor:
- (void)testCompareEqualColors;
- (void)testCompareColorsInequalInRed;
- (void)testCompareColorsInequalInGreen;
- (void)testCompareColorsInequalInBlue;
- (void)testCompareColorsInequalInAlpha;

#pragma mark -isDark
- (void)testWhiteColorIsDark;
- (void)testBlackColorIsDark;

#pragma mark -isMedium
- (void)testWhiteColorIsMedium;
- (void)testGrayColorIsMedium;
- (void)testBlackColorIsMedium;

#pragma mark -darkenBy:
- (void)testDarkenRed;

#pragma mark -darkenAndAdjustSaturationBy:
- (void)testDarkenAndSaturateRed;
- (void)testDarkenAndSaturatePink;

#pragma mark -colorWithInvertedLuminance
- (void)testInvertLuminanceOfWhite;
- (void)testInvertLuminanceOfBlack;
- (void)testInvertLuminanceOfRed;

#pragma mark -contrastingColor
- (void)testContrastingColorForWhite;
- (void)testContrastingColorForBlack;
- (void)testContrastingColorForGray;

#pragma mark -adjustHue:saturation:brightness:
- (void)testAdjustRedToGreen; //Hue += 1/3
- (void)testAdjustRedToWhite; //Saturation -= 1
- (void)testAdjustRedToBlack; //Brightness -= 1

#pragma mark -hexString
- (void)testHexStringForRed;
- (void)testHexStringForYellow;
- (void)testHexStringForGreen;
- (void)testHexStringForCyan;
- (void)testHexStringForBlue;
- (void)testHexStringForMagenta;
- (void)testHexStringForWhite;
- (void)testHexStringForBlack;

#pragma mark -stringRepresentation
- (void)testStringRepresentationForRed;
- (void)testStringRepresentationForYellow;
- (void)testStringRepresentationForGreen;
- (void)testStringRepresentationForCyan;
- (void)testStringRepresentationForBlue;
- (void)testStringRepresentationForMagenta;
- (void)testStringRepresentationForWhite;
- (void)testStringRepresentationForBlack;

- (void)testStringRepresentationForSemiTransparentRed;
- (void)testStringRepresentationForSemiTransparentYellow;
- (void)testStringRepresentationForSemiTransparentGreen;
- (void)testStringRepresentationForSemiTransparentCyan;
- (void)testStringRepresentationForSemiTransparentBlue;
- (void)testStringRepresentationForSemiTransparentMagenta;
- (void)testStringRepresentationForSemiTransparentWhite;
- (void)testStringRepresentationForSemiTransparentBlack;

#pragma mark -CSSRepresentation
- (void)testCSSRepresentationForRed;
- (void)testCSSRepresentationForYellow;
- (void)testCSSRepresentationForGreen;
- (void)testCSSRepresentationForCyan;
- (void)testCSSRepresentationForBlue;
- (void)testCSSRepresentationForMagenta;
- (void)testCSSRepresentationForWhite;
- (void)testCSSRepresentationForBlack;

- (void)testCSSRepresentationForSemiTransparentRed;
- (void)testCSSRepresentationForSemiTransparentYellow;
- (void)testCSSRepresentationForSemiTransparentGreen;
- (void)testCSSRepresentationForSemiTransparentCyan;
- (void)testCSSRepresentationForSemiTransparentBlue;
- (void)testCSSRepresentationForSemiTransparentMagenta;
- (void)testCSSRepresentationForSemiTransparentWhite;
- (void)testCSSRepresentationForSemiTransparentBlack;

- (void)testCSSRepresentationForTransparentRed;
- (void)testCSSRepresentationForTransparentYellow;
- (void)testCSSRepresentationForTransparentGreen;
- (void)testCSSRepresentationForTransparentCyan;
- (void)testCSSRepresentationForTransparentBlue;
- (void)testCSSRepresentationForTransparentMagenta;
- (void)testCSSRepresentationForTransparentWhite;
- (void)testCSSRepresentationForTransparentBlack;

#pragma mark hexToInt/intToHex
- (void)testHexToInt_DecimalNumeral;
- (void)testHexToInt_UppercaseLetter;
- (void)testHexToInt_LowercaseLetter;
- (void)testHexToInt_InvalidCharacters;
- (void)testIntToHex_0;
- (void)testIntToHex_15;
- (void)testIntToHex_16; //Invalid
- (void)testIntToHex_Neg1; //Invalid

#pragma mark -representedColor
//Valid
- (void)testRepresentedColorWithThreeNonZeroComponents;
- (void)testRepresentedColorWithThreeZeroComponents;
- (void)testRepresentedColorWithFourNonZeroComponents;
- (void)testRepresentedColorWithFourZeroComponents;
//Invalid
- (void)testRepresentedColorWithEmptyString;
- (void)testRepresentedColorWithInvalidString;
- (void)testRepresentedColorWithTwoCommas;
- (void)testRepresentedColorWithThreeCommas;
- (void)testRepresentedColorWithFourCommas;

#pragma mark -representedColorWithAlpha:
//Valid
- (void)testRepresentedColorWithAlphaWithThreeNonZeroComponents;
- (void)testRepresentedColorWithAlphaWithThreeZeroComponents;
- (void)testRepresentedColorWithAlphaWithFourNonZeroComponents;
- (void)testRepresentedColorWithAlphaWithFourZeroComponents;
//Invalid
- (void)testRepresentedColorWithAlphaWithEmptyString;
- (void)testRepresentedColorWithAlphaWithInvalidString;
- (void)testRepresentedColorWithAlphaWithTwoCommas;
- (void)testRepresentedColorWithAlphaWithThreeCommas;

#pragma mark -randomColor
- (void)testRandomColorHasAlpha1;

#pragma mark +colorWithHTMLString:
//These method declarations are automatically generated! If you want to change them, please change the program in the Utilities folder instead. Otherwise, your changes may be clobbered by the next person.
- (void)testColorWith6DigitHTMLStringForRedLowercase;
- (void)testColorWith6DigitHTMLStringForRedUppercase;
- (void)testColorWith6DigitHTMLStringForYellowLowercase;
- (void)testColorWith6DigitHTMLStringForYellowUppercase;
- (void)testColorWith6DigitHTMLStringForGreenLowercase;
- (void)testColorWith6DigitHTMLStringForGreenUppercase;
- (void)testColorWith6DigitHTMLStringForCyanLowercase;
- (void)testColorWith6DigitHTMLStringForCyanUppercase;
- (void)testColorWith6DigitHTMLStringForBlueLowercase;
- (void)testColorWith6DigitHTMLStringForBlueUppercase;
- (void)testColorWith6DigitHTMLStringForMagentaLowercase;
- (void)testColorWith6DigitHTMLStringForMagentaUppercase;
- (void)testColorWith6DigitHTMLStringForWhiteLowercase;
- (void)testColorWith6DigitHTMLStringForWhiteUppercase;
- (void)testColorWith6DigitHTMLStringForBlackLowercase;
- (void)testColorWith6DigitHTMLStringForBlackUppercase;

- (void)testColorWith3DigitHTMLStringForRedLowercase;
- (void)testColorWith3DigitHTMLStringForRedUppercase;
- (void)testColorWith3DigitHTMLStringForYellowLowercase;
- (void)testColorWith3DigitHTMLStringForYellowUppercase;
- (void)testColorWith3DigitHTMLStringForGreenLowercase;
- (void)testColorWith3DigitHTMLStringForGreenUppercase;
- (void)testColorWith3DigitHTMLStringForCyanLowercase;
- (void)testColorWith3DigitHTMLStringForCyanUppercase;
- (void)testColorWith3DigitHTMLStringForBlueLowercase;
- (void)testColorWith3DigitHTMLStringForBlueUppercase;
- (void)testColorWith3DigitHTMLStringForMagentaLowercase;
- (void)testColorWith3DigitHTMLStringForMagentaUppercase;
- (void)testColorWith3DigitHTMLStringForWhiteLowercase;
- (void)testColorWith3DigitHTMLStringForWhiteUppercase;
- (void)testColorWith3DigitHTMLStringForBlackLowercase;
- (void)testColorWith3DigitHTMLStringForBlackUppercase;

- (void)testColorWith8DigitHTMLStringForRedLowercase;
- (void)testColorWith8DigitHTMLStringForRedUppercase;
- (void)testColorWith8DigitHTMLStringForYellowLowercase;
- (void)testColorWith8DigitHTMLStringForYellowUppercase;
- (void)testColorWith8DigitHTMLStringForGreenLowercase;
- (void)testColorWith8DigitHTMLStringForGreenUppercase;
- (void)testColorWith8DigitHTMLStringForCyanLowercase;
- (void)testColorWith8DigitHTMLStringForCyanUppercase;
- (void)testColorWith8DigitHTMLStringForBlueLowercase;
- (void)testColorWith8DigitHTMLStringForBlueUppercase;
- (void)testColorWith8DigitHTMLStringForMagentaLowercase;
- (void)testColorWith8DigitHTMLStringForMagentaUppercase;
- (void)testColorWith8DigitHTMLStringForWhiteLowercase;
- (void)testColorWith8DigitHTMLStringForWhiteUppercase;
- (void)testColorWith8DigitHTMLStringForBlackLowercase;
- (void)testColorWith8DigitHTMLStringForBlackUppercase;

- (void)testColorWith4DigitHTMLStringForRedLowercase;
- (void)testColorWith4DigitHTMLStringForRedUppercase;
- (void)testColorWith4DigitHTMLStringForYellowLowercase;
- (void)testColorWith4DigitHTMLStringForYellowUppercase;
- (void)testColorWith4DigitHTMLStringForGreenLowercase;
- (void)testColorWith4DigitHTMLStringForGreenUppercase;
- (void)testColorWith4DigitHTMLStringForCyanLowercase;
- (void)testColorWith4DigitHTMLStringForCyanUppercase;
- (void)testColorWith4DigitHTMLStringForBlueLowercase;
- (void)testColorWith4DigitHTMLStringForBlueUppercase;
- (void)testColorWith4DigitHTMLStringForMagentaLowercase;
- (void)testColorWith4DigitHTMLStringForMagentaUppercase;
- (void)testColorWith4DigitHTMLStringForWhiteLowercase;
- (void)testColorWith4DigitHTMLStringForWhiteUppercase;
- (void)testColorWith4DigitHTMLStringForBlackLowercase;
- (void)testColorWith4DigitHTMLStringForBlackUppercase;

- (void)testColorWith6DigitHTMLStringForTransparentRedLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentRedUppercase;
- (void)testColorWith6DigitHTMLStringForTransparentYellowLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentYellowUppercase;
- (void)testColorWith6DigitHTMLStringForTransparentGreenLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentGreenUppercase;
- (void)testColorWith6DigitHTMLStringForTransparentCyanLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentCyanUppercase;
- (void)testColorWith6DigitHTMLStringForTransparentBlueLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentBlueUppercase;
- (void)testColorWith6DigitHTMLStringForTransparentMagentaLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentMagentaUppercase;
- (void)testColorWith6DigitHTMLStringForTransparentWhiteLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentWhiteUppercase;
- (void)testColorWith6DigitHTMLStringForTransparentBlackLowercase;
- (void)testColorWith6DigitHTMLStringForTransparentBlackUppercase;

- (void)testColorWith3DigitHTMLStringForTransparentRedLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentRedUppercase;
- (void)testColorWith3DigitHTMLStringForTransparentYellowLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentYellowUppercase;
- (void)testColorWith3DigitHTMLStringForTransparentGreenLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentGreenUppercase;
- (void)testColorWith3DigitHTMLStringForTransparentCyanLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentCyanUppercase;
- (void)testColorWith3DigitHTMLStringForTransparentBlueLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentBlueUppercase;
- (void)testColorWith3DigitHTMLStringForTransparentMagentaLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentMagentaUppercase;
- (void)testColorWith3DigitHTMLStringForTransparentWhiteLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentWhiteUppercase;
- (void)testColorWith3DigitHTMLStringForTransparentBlackLowercase;
- (void)testColorWith3DigitHTMLStringForTransparentBlackUppercase;

- (void)testColorWith8DigitHTMLStringForTransparentRedLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentRedUppercase;
- (void)testColorWith8DigitHTMLStringForTransparentYellowLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentYellowUppercase;
- (void)testColorWith8DigitHTMLStringForTransparentGreenLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentGreenUppercase;
- (void)testColorWith8DigitHTMLStringForTransparentCyanLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentCyanUppercase;
- (void)testColorWith8DigitHTMLStringForTransparentBlueLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentBlueUppercase;
- (void)testColorWith8DigitHTMLStringForTransparentMagentaLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentMagentaUppercase;
- (void)testColorWith8DigitHTMLStringForTransparentWhiteLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentWhiteUppercase;
- (void)testColorWith8DigitHTMLStringForTransparentBlackLowercase;
- (void)testColorWith8DigitHTMLStringForTransparentBlackUppercase;

- (void)testColorWith4DigitHTMLStringForTransparentRedLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentRedUppercase;
- (void)testColorWith4DigitHTMLStringForTransparentYellowLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentYellowUppercase;
- (void)testColorWith4DigitHTMLStringForTransparentGreenLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentGreenUppercase;
- (void)testColorWith4DigitHTMLStringForTransparentCyanLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentCyanUppercase;
- (void)testColorWith4DigitHTMLStringForTransparentBlueLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentBlueUppercase;
- (void)testColorWith4DigitHTMLStringForTransparentMagentaLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentMagentaUppercase;
- (void)testColorWith4DigitHTMLStringForTransparentWhiteLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentWhiteUppercase;
- (void)testColorWith4DigitHTMLStringForTransparentBlackLowercase;
- (void)testColorWith4DigitHTMLStringForTransparentBlackUppercase;

//End of automatically-generated method declarations

- (void)testColorWithHTMLStringWithNil;
- (void)testColorWithHTMLStringWithEmptyString;
- (void)testColorWithHTMLStringWithInvalidColor;

- (void)testColorWithHTMLStringWithNilWithDefaultColorRed;
- (void)testColorWithHTMLStringWithNilWithDefaultColorGreen;
- (void)testColorWithHTMLStringWithNilWithDefaultColorNil;
- (void)testColorWithHTMLStringWithEmptyStringWithDefaultColorRed;
- (void)testColorWithHTMLStringWithEmptyStringWithDefaultColorGreen;
- (void)testColorWithHTMLStringWithEmptyStringWithDefaultColorNil;
- (void)testColorWithHTMLStringWithInvalidColorWithDefaultColorRed;
- (void)testColorWithHTMLStringWithInvalidColorWithDefaultColorGreen;
- (void)testColorWithHTMLStringWithInvalidColorWithDefaultColorNil;

@end
