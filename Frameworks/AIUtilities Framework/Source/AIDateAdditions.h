//
//  AIDateAdditions.h
//  AIUtilities.framework
//
//  Created by Peter Hosey on 2007-11-12.
//  Copyright 2007 Adium Team. All rights reserved.
//

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
