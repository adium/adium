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

@interface NSDate (AIDateAdditions)

/*!	@brief	Converts an NSTimeInterval, which is a number of seconds, to the largest units possible.
 *
 *	@par	If the interval is positive, the result numbers will be positive. If the interval is negative, the result numbers will be negative.
 *
 *	@par	The results will be returned by reference. You can pass \c NULL to refuse any result.
 *
 *	@param	interval	The number to convert. This must be in seconds.
 *	@param	outWeeks	If non-\c NULL, the \c int at this address will be set to the number of weeks covered by the interval, rounded down.
 *	@param	outDays	If non-\c NULL, the \c int at this address will be set to the number of days covered by the interval, rounded down.
 *	@param	outHours	If non-\c NULL, the \c int at this address will be set to the number of hours covered by the interval, rounded down.
 *	@param	outMinutes	If non-\c NULL, the \c int at this address will be set to the number of minutes covered by the interval, rounded down.
 *	@param	outSeconds	If non-\c NULL, the \c NSTimeInterval at this address will be set to the number of seconds covered by the interval.
 */
+ (void) convertTimeInterval:(NSTimeInterval)interval
                    toWeeks:(out NSInteger *)outWeeks
                       days:(out NSInteger *)outDays
                      hours:(out NSInteger *)outHours
                    minutes:(out NSInteger *)outMinutes
                    seconds:(out NSTimeInterval *)outSeconds;

@end
