//
//  AIDateFormatterAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 01 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

@interface NSDateFormatter (AIDateFormatterAdditions)

+ (NSDateFormatter *)localizedDateFormatter;
+ (NSDateFormatter *)localizedShortDateFormatter;
+ (NSDateFormatter *)localizedDateFormatterShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm;
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
