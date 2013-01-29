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

#import "SHAutoValidatingTextView.h"

@interface SHAutoValidatingTextView ()
- (void)revalidate;
@end

@implementation SHAutoValidatingTextView

- (id)initWithFrame:(NSRect)frameRect
{
    return [super initWithFrame:frameRect];
}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
    return [super initWithFrame:frameRect textContainer:aTextContainer];
}

//Set Validation Attribs -----------------------------------------------------------------------------------------------
#pragma mark Set Validation Attribs
- (void)setContinuousURLValidationEnabled:(BOOL)flag
{
    //set the validation BOOL, and immeditely reevaluate view
    continuousURLValidation = flag;
	
	if (continuousURLValidation) {
		[self revalidate];
	}
}

- (void)toggleContinuousURLValidationEnabled
{
    //toggle the validation BOOL, and immeditely re-evaluate view
    continuousURLValidation = !continuousURLValidation;
}

- (BOOL)isContinuousURLValidationEnabled
{
    return continuousURLValidation;
}


//Get URL Verification Status ------------------------------------------------------------------------------------------
#pragma mark Get URL Verification Status
- (BOOL)isURLValid
{
    return URLIsValid;
}
- (AH_URI_VERIFICATION_STATUS)validationStatus
{
    return validStatus;
}


//Evaluate URL ---------------------------------------------------------------------------------------------------------
#pragma mark Evaluate URL
//Catch the notification when the text in the view is edited
- (void)textDidChange:(NSNotification *)notification
{
	if (continuousURLValidation) {//call the URL validatation if set
		[self revalidate];
	}
}

- (void)revalidate
{
	NSString			*linkURL = [self linkURL];
	
	URLIsValid = [AHHyperlinkScanner isStringValidURI:linkURL
										  usingStrict:YES
											fromIndex:NULL
										   withStatus:&validStatus
										 schemeLength:NULL];
}

#pragma mark Retrieving URL
/*!
 * @brief Link URL
 */
- (NSString *)linkURL
{
	NSString	*linkURL = [[self textStorage] string];
	CFStringRef preprocessedString, escapedURLString;
	CFStringRef charactersToLeaveUnescaped = CFSTR("#");

	if ([linkURL rangeOfString:@"%n"].location != NSNotFound) {
		NSMutableString	*newLinkURL = [linkURL mutableCopy];
		[newLinkURL replaceOccurrencesOfString:@"%n"
									withString:@"%25n"
									   options:NSLiteralSearch
										 range:NSMakeRange(0, [newLinkURL length])];
		linkURL = newLinkURL;
		
	}

	//Replace all existing percent escapes (in case the user actually escaped the URL properly or it was copy/pasted)
	preprocessedString = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
																				 (__bridge CFStringRef)linkURL,
																				 CFSTR(""),
																				 kCFStringEncodingUTF8);
	//Now escape it the way NSURL demands
	if (preprocessedString) {
		escapedURLString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																   preprocessedString,
																   charactersToLeaveUnescaped,
																   /* legalURLCharactersToBeEscaped */ NULL,
																   kCFStringEncodingUTF8);
		CFRelease(preprocessedString);
	} else {
		escapedURLString = nil;
	}

	return (escapedURLString ? (__bridge NSString *)escapedURLString : linkURL);
}

@end
