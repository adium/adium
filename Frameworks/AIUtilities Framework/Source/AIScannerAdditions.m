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

#import "AIScannerAdditions.h"

@implementation NSScanner(AIScannerAdditions)

- (BOOL)scanUnsignedInt:(unsigned int *)unsignedIntValue
{
	//skip characters if necessary
	NSCharacterSet *skipSet = [self charactersToBeSkipped];
	[self setCharactersToBeSkipped:nil];
	[self scanCharactersFromSet:skipSet intoString:NULL];
	[self setCharactersToBeSkipped:skipSet];

	NSString *string = [self string];
	NSRange range = { .location = [self scanLocation], .length = 0 };
	NSInteger length = [string length] - range.location;
	range.length = length;

	unichar *buf = malloc(length * sizeof(unichar));
	[string getCharacters:buf range:range];

	unsigned i = 0;

	if (length && (buf[i] == '+')) {
		++i;
	}
	if (i >= length) {
		free(buf);
		return NO;
	}
	if ((buf[i] < '0') || (buf[i] > '9')) {
		free(buf);
		return NO;
	}

	unsigned total = 0;
	while (i < length) {
		if ((buf[i] >= '0') && (buf[i] <= '9')) {
			total *= 10;
			total += buf[i] - '0';
			++i;
		} else {
			break;
		}
	}
	[self setScanLocation:i];
	*unsignedIntValue = total;
	free(buf);
	return YES;
}

@end
