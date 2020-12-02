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

@interface NSDateFormatter (AIDateFormatterAdditions)

+ (void)withLocalizedDateFormatterPerform:(void (^)(NSDateFormatter *))block;
+ (void)withLocalizedShortDateFormatterPerform:(void (^)(NSDateFormatter *))block;
+ (void)withLocalizedDateFormatterShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm perform:(void (^)(NSDateFormatter *))block;
+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm;
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate;
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate;
+ (NSString *)stringForApproximateTimeIntervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate;
+ (NSString *)stringForApproximateTimeInterval:(NSTimeInterval)interval abbreviated:(BOOL)abbreviate;
+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval;
+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate approximated:(BOOL)approximate;
- (NSString *)dateCalendarFormat;
- (NSString *)dateUnicodeFormat;
@end
