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

#import <Foundation/Foundation.h>

/*This addition unparses dates to ISO 8601 strings. A good introduction to ISO 8601: <http://www.cl.cam.ac.uk/~mgk25/iso-time.html>
 */

//The default separator for time values. Currently, this is ':'.
extern unichar ISO8601UnparserDefaultTimeSeparatorCharacter;

@interface NSCalendarDate(ISO8601Unparsing)

- (NSString *)ISO8601DateStringWithTime:(BOOL)includeTime timeSeparator:(unichar)timeSep;
- (NSString *)ISO8601WeekDateStringWithTime:(BOOL)includeTime timeSeparator:(unichar)timeSep;
- (NSString *)ISO8601OrdinalDateStringWithTime:(BOOL)includeTime timeSeparator:(unichar)timeSep;

- (NSString *)ISO8601DateStringWithTime:(BOOL)includeTime;
- (NSString *)ISO8601WeekDateStringWithTime:(BOOL)includeTime;
- (NSString *)ISO8601OrdinalDateStringWithTime:(BOOL)includeTime;

//includeTime: YES.
- (NSString *)ISO8601DateStringWithTimeSeparator:(unichar)timeSep;
- (NSString *)ISO8601WeekDateStringWithTimeSeparator:(unichar)timeSep;
- (NSString *)ISO8601OrdinalDateStringWithTimeSeparator:(unichar)timeSep;

//includeTime: YES.
- (NSString *)ISO8601DateString;
- (NSString *)ISO8601WeekDateString;
- (NSString *)ISO8601OrdinalDateString;

@end

