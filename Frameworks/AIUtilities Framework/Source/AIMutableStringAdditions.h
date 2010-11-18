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

@interface NSMutableString (AIMutableStringAdditions)
+ (NSMutableString *)stringWithContentsOfASCIIFile:(NSString *)path;

//This is so that code that may be dealing with a mutable string
//or mutable attributed string can call [str mutableString] and get 
//a mutable string out of it, that it can work with that without
//worrying about what kind of string it's dealing with
- (NSMutableString*)mutableString;

- (void)convertNewlinesToSlashes;

//There is/was code in Adium that attempted to be smart about avoiding doing NSMakeRange(0, [str length]) over and over again
//At least a few cases were wrong, and it's generally pointless. Please use this instead and ignore the slight overhead.
- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)opts;

@end
