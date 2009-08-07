//
//  NSString-FBAdditions.m
//  FriBidi
//
//  Created by Ofri Wolfus on 22/08/06.
//  Copyright 2006 Ofri Wolfus. All rights reserved.
//

#import "NSString-FBAdditions.h"
#import "fribidi.h"
#import "ConvertUTF.h"


@implementation NSString (FBAdditions)

/*
 * This method attempts to determine the base writing direction of our string.
 * We do this by looping through our characters until we find the first one that knows its writing direction.
 * This method will usually get the right direction, unless someone accidentally put a random letter at the
 * beginning of the string, which has a different writing direction.
 * But since this will be the user's fault, he'll have to deal with it :)
 * Anyhow, AppKit also uses this method when displaying bidi text.
 */
- (NSWritingDirection)baseWritingDirection {
	unsigned int		len = [self length];
	unsigned int		i;
	FriBidiChar			*f, fch;
	UTF16				*u, uch;
	NSWritingDirection	dir = NSWritingDirectionNatural;
	
	/*
	 * Loop through all our characters, one by one, until we find one which knows its writing direction.
	 * Note: If our string begins with lots of universal characters (characters without a direction), this
	 * could get very inefficient.
	 */
	for (i = 0U; i < len; i++) {
		FriBidiCharType type;
		
		// Get a single character
		uch = (UTF16)CFStringGetCharacterAtIndex((CFStringRef)self, i);
		u = &uch;
		f = &fch;
		
		// Convert our UniChar (which is UTF16) to FriBidiChar (which is UTF32)
		if (ConvertUTF16toUTF32((const UTF16**)&u, (u + 1), &f, (f + 1), lenientConversion) == conversionOK) {
			// Get the type of our character
			type = fribidi_get_type(fch);
			
			// LTR char?
			if (type == FRIBIDI_TYPE_LTR) {
				dir = NSWritingDirectionLeftToRight;
				break;
			}
			
			// RTL char?
			if (type == FRIBIDI_TYPE_RTL) {
				dir = NSWritingDirectionRightToLeft;
				break;
			}
		}
	}
	
	return dir;
}

@end
