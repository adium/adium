//
//  AICalendarDateAdditions.h
//  AIUtilities.framework
//
//  Created by Peter Hosey on 2007-11-11.
//  Copyright 2007 Adium Team. All rights reserved.
//

@interface NSCalendarDate (AICalendarDateAdditions)

/*!	@brief	Convert the receiver to have the same DST status as the other date.
 *
 *	@par	If the receiver is in Daylight-Saving Time and the other date is not, this method returns a date created by adding one hour to the receiver (e.g., 16:00→17:00).
 *
 *	@par	If the receiver is not in Daylight-Saving Time and the other date is, this method returns a date created by subtracting one hour from the receiver (e.g., 17:00→16:00).
 *
 *	@par	If both dates are in DST, or neither date is in DST, this method returns the receiver unchanged.
 *
 *	@bug	This method assumes that DST is a one-hour shift. This may not be true of all states in the world that observe DST.
 */
- (NSCalendarDate *)dateByMatchingDSTOfDate:(NSDate *)otherDate;

@end
