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

#import "AICharacterSetAdditions.h"

@implementation NSCharacterSet (AICharacterSetAdditions)
/*
 * @brief Make an immutable copy of an NSCharacterSet or NSMutableCharacterSet
 *
 * NSMutableCharacterSet's documentation states that immutable NSCharacterSets are more efficient than NSMutableCharacterSets.
 * Shark sampling demonstrates this to be true as of OS X 10.4.5.
 *
 * However, -[NSMutableCharacterSet copy] returns a new NSMutableCharacterSet which remains inefficient!
 *
 * XXX: This is still true as of 10.7.2.
 */
- (NSCharacterSet *)immutableCopy
{
	return [[NSCharacterSet characterSetWithBitmapRepresentation:[self bitmapRepresentation]] retain];
}

@end
