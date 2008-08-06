//
//  AIDateFormatterAdditions.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 01 2003.
//

#import "AIDateFormatterAdditions.h"
#import "AIApplicationAdditions.h"
#import "AIDateAdditions.h"
#import "AIStringUtilities.h"
#import "AITigercompatibility.h"

#define ONE_WEEK AILocalizedStringFromTableInBundle(@"1 week", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_WEEKS AILocalizedStringFromTableInBundle(@"%i weeks", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_DAY AILocalizedStringFromTableInBundle(@"1 day", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_DAYS AILocalizedStringFromTableInBundle(@"%i days", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_HOUR AILocalizedStringFromTableInBundle(@"1 hour", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_HOURS AILocalizedStringFromTableInBundle(@"%i hours", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_MINUTE AILocalizedStringFromTableInBundle(@"1 minute", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_MINUTES AILocalizedStringFromTableInBundle(@"%i minutes", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define ONE_SECOND AILocalizedStringFromTableInBundle(@"1 second", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define MULTIPLE_SECONDS AILocalizedStringFromTableInBundle(@"%1.0lf seconds", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)

typedef enum {
    NONE,
    SECONDS,
    AMPM,
    BOTH
} StringType;

@implementation NSDateFormatter (AIDateFormatterAdditions)

+ (NSDateFormatter *)localizedDateFormatter
{
	// Thursday, July 31, 2008
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateStyle:NSDateFormatterFullStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	return [formatter autorelease];
}

+ (NSDateFormatter *)localizedShortDateFormatter
{
	// 7/31/08
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	return [formatter autorelease];
}

+ (NSDateFormatter *)localizedDateFormatterShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
	NSDateFormatter	*formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateFormat:[self localizedDateFormatStringShowingSeconds:seconds showingAMorPM:showAmPm]];
	return [formatter autorelease];
}

+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
	NSString *formatString;
	
	// Get the current time format string
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateStyle:NSDateFormatterNoStyle];
	[formatter setTimeStyle:(seconds) ? NSDateFormatterMediumStyle : NSDateFormatterShortStyle];
	
	if(!showAmPm) {
		NSMutableString *newFormat = [[NSMutableString alloc] initWithString:[formatter dateFormat]];
		[newFormat replaceOccurrencesOfString:@" a"
								   withString:@""
									  options:NSBackwardsSearch | NSLiteralSearch
										range:NSMakeRange(0,[newFormat length])];
		formatString = [newFormat copy];
		[newFormat release];
	} else {
		formatString = [[formatter dateFormat] retain];
	}
	
	[formatter release];
	
    return formatString;
}




+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate
{
    return ([self stringForTimeIntervalSinceDate:inDate showingSeconds:YES abbreviated:NO]);
}

/*!
 *@brief format time for the interval since the given date
 *
 *@param inDate Date which starts the interval
 *@param showSeconds switch to determine if seconds should be shown
 *@param abbreviate switch to chose if w/d/h/ or weeks/days/hours/minutes is used to indicate the unit
 *
 *@result a localized NSString containing the Interval in weeks, days, hours or minutes (the largest usable)
 */
 
+ (NSString *)stringForTimeIntervalSinceDate:(NSDate *)inDate showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate;
{
    return [self stringForTimeInterval:[[NSDate date] timeIntervalSinceDate:inDate]
						showingSeconds:showSeconds
						   abbreviated:abbreviate
						  approximated:NO];
}


/*!
 *@brief format time for the interval between two dates
 *
 *@param firstDate first date of the interval
 *@param secondDate second date of the interval
 *
 *@result a localized NSString containing the Interval in weeks, days, hours or minutes (the largest usable)
 */
 
+ (NSString *)stringForApproximateTimeIntervalBetweenDate:(NSDate *)firstDate andDate:(NSDate *)secondDate
{
	return  [self stringForTimeInterval:[firstDate timeIntervalSinceDate:secondDate]
						 showingSeconds:NO
							abbreviated:NO
						   approximated:YES];
}

/*!
 *@brief format time for an interval
 *
 *@param interval NSTimeInterval to format
 *@param abbreviate switch to chose if w/d/h/ or weeks/days/hours/minutes is used to indicate the unit
 *
 *@result a localized NSString containing the Interval in weeks, days, hours or minutes (the largest usable)
 */
 
+ (NSString *)stringForApproximateTimeInterval:(NSTimeInterval)interval abbreviated:(BOOL)abbreviate
{
	return  [self stringForTimeInterval:interval
						 showingSeconds:NO
							abbreviated:abbreviate
						   approximated:YES];
}

/*!
 *@brief format time for an interval
 *
 *@param interval NSTimeInterval to format
 *
 *@result a localized NSString containing the interval in weeks, days, hours and minutes
 */
 
+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval
{
	return  [self stringForTimeInterval:interval
						 showingSeconds:NO
							abbreviated:NO
						   approximated:NO];
}

/*!
 *@brief format time for an interval
 *
 *
 *
 *@param interval NSTimeInterval to format
 *@param showSeconds switch to determine if seconds should be shown
 *@param abbreviate switch to chose if w/d/h/ or weeks/days/hours/minutes is used to indicate the unit
 *@param approximate switch to chose if all parts should be shown or only the largest available part. If Hours is the largest available part, Minutes are also shown if applicable.
 *
 *@result a localized NSString containing the Interval formated according to the switches
 */ 

+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval showingSeconds:(BOOL)showSeconds abbreviated:(BOOL)abbreviate approximated:(BOOL)approximate
{
    int				weeks = 0, days = 0, hours = 0, minutes = 0;
	NSTimeInterval	seconds = 0; 
	NSString		*weeksString = nil, *daysString = nil, *hoursString = nil, *minutesString = nil, *secondsString = nil;

	[NSDate convertTimeInterval:interval
	                    toWeeks:&weeks
	                       days:&days
	                      hours:&hours
	                    minutes:&minutes
	                    seconds:&seconds];

	//build the strings for the parts
	if (abbreviate) {
		//Note: after checking with a linguistics student, it appears that we're fine leaving it as w, h, etc... rather than localizing.
		weeksString		= [NSString stringWithFormat: @"%iw",weeks];
		daysString		= [NSString stringWithFormat: @"%id",days];
		hoursString		= [NSString stringWithFormat: @"%ih",hours];
		minutesString	= [NSString stringWithFormat: @"%im",minutes];
		secondsString	= [NSString stringWithFormat: @"%.0fs",seconds];
	} else {
		weeksString		= (weeks == 1)		? ONE_WEEK		: [NSString stringWithFormat:MULTIPLE_WEEKS, weeks];
		daysString		= (days == 1)		? ONE_DAY		: [NSString stringWithFormat:MULTIPLE_DAYS, days];
		hoursString		= (hours == 1)		? ONE_HOUR		: [NSString stringWithFormat:MULTIPLE_HOURS, hours];
		minutesString	= (minutes == 1)	? ONE_MINUTE	: [NSString stringWithFormat:MULTIPLE_MINUTES, minutes];
		secondsString	= (seconds == 1)	? ONE_SECOND	: [NSString stringWithFormat:MULTIPLE_SECONDS, seconds];
	}

	//assemble the parts
	NSMutableArray *parts = [NSMutableArray arrayWithCapacity:5];
	if (approximate) {
		/* We want only one of these. For example, 5 weeks, 5 days, 5 hours, 5 minutes, and 5 seconds should just be "5 weeks".
		 * Exception: Hours should display hours and minutes. 5 hours, 5 minutes, and 5 seconds is "5 hours and 5 minutes".
		 */
		if (weeks)
			[parts addObject:weeksString];
		else if (days)
			[parts addObject:daysString];
		else if (hours) {
			[parts addObject:hoursString];
			if (minutes)
				[parts addObject:minutesString];
		}
		else if (minutes)
			[parts addObject:minutesString];
		else if (showSeconds && (seconds >= 0.01))
			[parts addObject:secondsString];
	} else {
		//We want all of these that aren't zero.
		if (weeks)
			[parts addObject:weeksString];
		if (days)
			[parts addObject:daysString];
		if (hours)
			[parts addObject:hoursString];
		if (minutes)
			[parts addObject:minutesString];
		if (showSeconds && (seconds >= 0.01))
			[parts addObject:secondsString];
	}

	return [parts componentsJoinedByString:@" "];
}


/*!
 *@brief get the strftime-style format string for an NSDateFormatter
 *
 * Translations are approximate! Not all fields supported by TR35-4 are
 * supported by the strftime format style.
 *
 *@result an NSString containing the strftime-style format string
 */ 
- (NSString *)dateCalendarFormat {
	NSString *format = [self dateFormat];
	
	// If we're using 10.0-10.3 behavior, it's easy
	if ([self formatterBehavior] == NSDateFormatterBehavior10_0) {
		return format;
	}
	
	// Scan across the format string, building the strftime-style format
	NSMutableString *newFormat = [[NSMutableString alloc] initWithCapacity:[format length]];
	
	NSScanner *scanner = [[NSScanner alloc] initWithString:format];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithRange:NSMakeRange(0, 0)]];
	
	NSCharacterSet *t354symbols = [NSCharacterSet characterSetWithCharactersInString:@"GyYuMwWdDFgEeahHKkmsSAzZ'%"];
	
	while(![scanner isAtEnd]) {		
		// Copy over anything that we don't handle specially
		NSString *skipped;
		if ([scanner scanUpToCharactersFromSet:t354symbols intoString:&skipped]) {
			[newFormat appendString:skipped];
			continue;
		}
		
		// Get the current character and grab all contiguous repetitions of it
		unichar it = [format characterAtIndex:[scanner scanLocation]];
		
		NSString *span;
		if (![scanner scanCharactersFromSet:[NSCharacterSet characterSetWithRange:NSMakeRange(it, 1)]
								 intoString:&span]) {
			break;
		}
		
		// Perform the translation		
		// XXX Not supported or not fully supported: GuwWFgEeKkSAzZ
		
		if (it == 'G') {
			// strftime has no equivalent of era, so we assume it's AD
			[newFormat appendString:@"AD"];
		
		} else if (it == 'y' || it == 'y') {			
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%1y"];
					break;
				case 2:
					[newFormat appendString:@"%y"];
					break;
				case 3:
					[newFormat appendString:@"%3Y"];
					break;
				case 4:
					[newFormat appendString:@"%Y"];
					break;
				default:
					[newFormat appendFormat:@"%%%iY", [span length]];
			}
			
		} else if (it == 'M') {
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%1m"];
					break;
				case 2:
					[newFormat appendString:@"%m"];
					break;
				case 3:
					[newFormat appendString:@"%b"];
					break;
				case 4:
					[newFormat appendString:@"%B"];
					break;
				default:
					[newFormat appendString:@"%1b"];
			}
			
		} else if (it == 'd') {
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%e"];
					break;
				default:
					[newFormat appendString:@"%d"];
			}
		
		} else if (it == 'D') {
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%1j"];
					break;
				case 2:
					[newFormat appendString:@"%2j"];
					break;
				default:
					[newFormat appendString:@"%j"];
			}
		
		} else if (it == 'E' || it == 'e') {
			switch ([span length]) {
				case 1:
				case 2:
					// XXX In TR35-4, Sunday = 1, whereas in strftime Sunday = 0
					[newFormat appendString:@"%w"];
					break;
				case 3:
					[newFormat appendString:@"%a"];
					break;
				case 4:
					[newFormat appendString:@"%A"];
					break;
				default:
					[newFormat appendString:@"%1a"];
			}
		
		} else if (it == 'a') {
			[newFormat appendString:@"%p"];
			
		} else if (it == 'h') {
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%1I"];
					break;
				default:
					[newFormat appendString:@"%I"];
			}
		
		} else if (it == 'H') {
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%1H"];
					break;
				default:
					[newFormat appendString:@"%H"];
			}
			
		} else if (it == 'm') {
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%1M"];
					break;
				default:
					[newFormat appendString:@"%M"];
			}
			
		} else if (it == 's') {
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"%1S"];
					break;
				default:
					[newFormat appendString:@"%S"];
			}
			
		} else if (it == 'z') {
			[newFormat appendString:@"%Z"];
			
		} else if (it == 'Z') {
			[newFormat appendString:@"%z"];
			
		} else if (it == '\'') {
			if ([span length] >= 2) {
				[newFormat appendString:@"'"];
				[scanner setScanLocation:[scanner scanLocation] - [span length] + 2];
			
			} else {
				while(1) {
					NSString *text;
					if ([scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"'%"]
												intoString:&text]) {
						[newFormat appendString:text];
					}
					
					if ([format characterAtIndex:([scanner scanLocation] + 1)] == '\'') {
						if (([scanner scanLocation] + 1 < [format length]) && ([format characterAtIndex:([scanner scanLocation] + 1)] == '\'')) {
							[newFormat appendString:@"'"];
							[scanner setScanLocation:([scanner scanLocation] + 2)];
						} else {
							[scanner setScanLocation:([scanner scanLocation] + 1)];
							break;
						}
					} else {
						[newFormat appendString:@"%%"];
					}
				}
			}
		
		} else if (it == '%') {
			[newFormat appendString:@"%%"];
			[scanner setScanLocation:[scanner scanLocation] - [span length] + 1];
		
		} else {
			//NSLog(@"Unhandled format %@", span);
		}
	}

	// Make it immutable
	NSString *result = [newFormat copy];
	[newFormat release];
	return result;

	// http://developer.apple.com/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatterSyntax.html
	// http://unicode.org/reports/tr35/tr35-4.html#Date_Format_Patterns
}

@end
