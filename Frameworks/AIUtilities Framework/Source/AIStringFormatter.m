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

#import "AIStringFormatter.h"
#import "AIStringUtilities.h"

#define ERRORS_BEFORE_DIALOG	3	//Number of mistakes that can be made before an error dialog will appear

@interface AIStringFormatter ()
- (id)initAllowingCharacters:(NSCharacterSet *)inCharacters length:(NSInteger)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)inErrorMessage;
@end

@implementation AIStringFormatter

+ (id)stringFormatterAllowingCharacters:(NSCharacterSet *)inCharacters length:(NSInteger)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)inErrorMessage
{
    return [[self alloc] initAllowingCharacters:inCharacters length:inLength caseSensitive:inCaseSensitive errorMessage:inErrorMessage];
}

- (id)initAllowingCharacters:(NSCharacterSet *)inCharacters length:(NSInteger)inLength caseSensitive:(BOOL)inCaseSensitive errorMessage:(NSString *)inErrorMessage
{
	if ((self = [super init])) {
		errorMessage = inErrorMessage;
		characters = inCharacters;
		length = inLength;
		caseSensitive = inCaseSensitive;
		errorCount = 0;
	}

	return self;
}

- (NSString *)stringForObjectValue:(id)obj
{
    if (![obj isKindOfClass:[NSString class]]) {
        return nil;
    }

    return obj;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
    *obj = string;
    return YES;
}

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error
{
    BOOL	valid = YES;
	BOOL	shouldIncreaseErrorCounter = NO;
	
    //Check length
    if (length > 0 && [*partialStringPtr length] > length) {
        valid = NO;
		shouldIncreaseErrorCounter = YES;
    }
	
    //Check for invalid characters
    if (characters != nil && [*partialStringPtr length] > 0) {
        NSScanner	*scanner = [NSScanner scannerWithString:(caseSensitive ? *partialStringPtr : [*partialStringPtr lowercaseString])];
        NSString	*validSegment;
		
        if (![scanner scanCharactersFromSet:characters intoString:&validSegment]) {
            valid = NO;
			shouldIncreaseErrorCounter = YES;
			
        } else {
			NSUInteger validSegmentLength = [validSegment length];
			NSUInteger partialStringPtrLength = [*partialStringPtr length];
			
			if (validSegmentLength != partialStringPtrLength) {
				valid = NO;
				
				//If the string is valid except for the last character, and the last character is a newline, strip the newline and allow the change
				if ((validSegmentLength + 1 == partialStringPtrLength) &&
					([*partialStringPtr characterAtIndex:validSegmentLength] == '\r' ||
					 [*partialStringPtr characterAtIndex:validSegmentLength] == '\n')) {
					*partialStringPtr = [*partialStringPtr substringToIndex:validSegmentLength];
					
					if ((*proposedSelRangePtr).length == 0) {
						(*proposedSelRangePtr).location = (((*proposedSelRangePtr).location) - 1);
					} else {
						(*proposedSelRangePtr).length = (((*proposedSelRangePtr).length) - 1);	
					}
					
					shouldIncreaseErrorCounter = NO;
					
				} else {
					shouldIncreaseErrorCounter = YES;
					
				}
			}
		}
	}
	
	if (shouldIncreaseErrorCounter) {
		errorCount++;
		
		if (errorMessage != nil && errorCount > ERRORS_BEFORE_DIALOG) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-security"
			NSRunAlertPanel(AILocalizedStringFromTableInBundle(@"Invalid Input",nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil),
							errorMessage, 
							AILocalizedStringFromTableInBundle(@"OK", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil), nil, nil);
#pragma GCC diagnostic pop
			errorCount = 0;
			
		} else {
			NSBeep();
		}
	}
	
	return valid;
}

@end
