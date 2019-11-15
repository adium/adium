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

#import "AIDateFormatterAdditions.h"
#import "AIApplicationAdditions.h"
#import "AIDateAdditions.h"
#import "AIStringUtilities.h"

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

@interface NSDateFormatter (PRIVATE)
+ (NSDateFormatter *)localizedDateFormatter;
+ (NSDateFormatter *)localizedShortDateFormatter;
+ (NSDateFormatter *)localizedDateFormatterShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm;
+ (dispatch_queue_t)localizedFormatterQueue;
@end

typedef enum {
    NONE,
    SECONDS,
    AMPM,
    BOTH
} StringType;

@interface AIDateFormatterCache : NSObject
{
	NSDateFormatter *localizedDateFormatter;
	NSDateFormatter *localizedShortDateFormatter;
	NSDateFormatter *localizedDateFormatterShowingSecondsAndAMPM;
	NSDateFormatter *localizedDateFormatterShowingAMPM;
	NSDateFormatter *localizedDateFormatterShowingSeconds;
	NSDateFormatter *localizedDateFormatterShowingNoSecondsOrAMPM;
}

+ (AIDateFormatterCache *)sharedInstance;
- (void) flushFormatterCache:(NSNotification *)dnc;
- (NSDateFormatter **)formatterShowingSeconds:(BOOL)sec showingAMorPM:(BOOL)ampm;
- (NSDateFormatter **)formatter;
- (NSDateFormatter **)shortFormatter;
@end

static AIDateFormatterCache *sharedFormatterCache = nil;

@implementation AIDateFormatterCache
- (id) init {
	if ((self = [super init])) {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(flushFormatterCache:) name:@"AppleDatePreferencesChangedNotification" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(flushFormatterCache:) name:@"AppleTimePreferencesChangedNotification" object:nil];
	}
	return self;
}

- (void) flushFormatterCache:(NSNotification *)dnc
{
	[sharedFormatterCache release]; sharedFormatterCache = nil;
}

+ (AIDateFormatterCache *)sharedInstance
{
	NSAssert(dispatch_get_current_queue() == [NSDateFormatter localizedFormatterQueue], @"Wrong queue");
	
	if (!sharedFormatterCache)
		sharedFormatterCache = [[AIDateFormatterCache alloc] init];
	return sharedFormatterCache;
}

- (NSDateFormatter **)formatterShowingSeconds:(BOOL)sec showingAMorPM:(BOOL)ampm
{
	if (sec && ampm)
		return &localizedDateFormatterShowingSecondsAndAMPM;
	else if (sec && !ampm)
		return &localizedDateFormatterShowingSeconds;
	else if (!sec && ampm)
		return &localizedDateFormatterShowingAMPM;
	else // if (!sec && !ampm)
		return &localizedDateFormatterShowingNoSecondsOrAMPM;
}

- (NSDateFormatter **)formatter
{
	return &localizedDateFormatter;
}

- (NSDateFormatter **)shortFormatter
{
	return &localizedShortDateFormatter;
}

- (void) dealloc
{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
	[localizedDateFormatter release];
	[localizedShortDateFormatter release];
	[localizedDateFormatterShowingSecondsAndAMPM release];
	[localizedDateFormatterShowingAMPM release];
	[localizedDateFormatterShowingSeconds release];
	[localizedDateFormatterShowingNoSecondsOrAMPM release];
	[super dealloc];
}
@end

@implementation NSDateFormatter (AIDateFormatterAdditions)

+ (dispatch_queue_t)localizedFormatterQueue
{
	static dispatch_once_t onceToken;
	static dispatch_queue_t localizedFormatterQueue;
	dispatch_once(&onceToken, ^{
		localizedFormatterQueue = dispatch_queue_create("im.adium.LocalizedDateFormatterQueue", NULL);
	});
	
	return localizedFormatterQueue;
}

+ (void)withLocalizedDateFormatterPerform:(void (^)(NSDateFormatter *))block
{
	dispatch_queue_t localizedFormatterQueue = [self localizedFormatterQueue];
	
	dispatch_sync(localizedFormatterQueue, ^{
		block([self localizedDateFormatter]);
	});
}

+ (void)withLocalizedShortDateFormatterPerform:(void (^)(NSDateFormatter *))block
{
	dispatch_queue_t localizedFormatterQueue = [self localizedFormatterQueue];
	
	dispatch_sync(localizedFormatterQueue, ^{
		block([self localizedShortDateFormatter]);
	});
}

+ (void)withLocalizedDateFormatterShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm perform:(void (^)(NSDateFormatter *))block
{
	dispatch_queue_t localizedFormatterQueue = [self localizedFormatterQueue];
	
	dispatch_sync(localizedFormatterQueue, ^{
		block([self localizedDateFormatterShowingSeconds:seconds showingAMorPM:showAmPm]);
	});
}


+ (NSDateFormatter *)localizedDateFormatter
{
	NSAssert(dispatch_get_current_queue() == [self localizedFormatterQueue], @"Wrong queue");
	
	// Thursday, July 31, 2008
	NSDateFormatter **cachePointer = [[AIDateFormatterCache sharedInstance] formatter];
	
	if (!(*cachePointer)) {
		*cachePointer = [[NSDateFormatter alloc] init];
		[*cachePointer setDateStyle:NSDateFormatterFullStyle];
		[*cachePointer setTimeStyle:NSDateFormatterNoStyle];
	}
	
	return *cachePointer;
}

+ (NSDateFormatter *)localizedShortDateFormatter
{
	NSAssert(dispatch_get_current_queue() == [self localizedFormatterQueue], @"Wrong queue");
	
	// 7/31/08
	NSDateFormatter **cachePointer = [[AIDateFormatterCache sharedInstance] shortFormatter];
	
	if (!(*cachePointer)) {
		*cachePointer = [[NSDateFormatter alloc] init];
		[*cachePointer setDateStyle:NSDateFormatterShortStyle];
		[*cachePointer setTimeStyle:NSDateFormatterNoStyle];
	}
	
	return *cachePointer;
}

+ (NSDateFormatter *)localizedDateFormatterShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
	NSAssert(dispatch_get_current_queue() == [self localizedFormatterQueue], @"Wrong queue");
	
	NSDateFormatter **cachePointer = [[AIDateFormatterCache sharedInstance] formatterShowingSeconds:seconds showingAMorPM:showAmPm];

	if (!(*cachePointer)) {
		[self localizedDateFormatStringShowingSeconds:seconds showingAMorPM:showAmPm];
	}
	
	return *cachePointer; //this is initialized in localizedDateFormatStringShowingSeconds:showingAMorPM:
}

+ (NSString *)localizedDateFormatStringShowingSeconds:(BOOL)seconds showingAMorPM:(BOOL)showAmPm
{
	dispatch_queue_t localizedFormatterQueue = [self localizedFormatterQueue];
	__block NSString *formatString;
	
	if (dispatch_get_current_queue() != localizedFormatterQueue) {
		dispatch_sync(localizedFormatterQueue, ^{
			formatString = [[self localizedDateFormatStringShowingSeconds:seconds showingAMorPM:showAmPm] retain];
		});
		return [formatString autorelease];
	}
	
	NSDateFormatter **cachePointer = [[AIDateFormatterCache sharedInstance] formatterShowingSeconds:seconds showingAMorPM:showAmPm];
	
	BOOL setFormat = NO;
	
	if (!(*cachePointer)) {
		// Get the current time format string
		*cachePointer = [[NSDateFormatter alloc] init];
		[*cachePointer setDateStyle:NSDateFormatterNoStyle];
		[*cachePointer setTimeStyle:(seconds) ? NSDateFormatterMediumStyle : NSDateFormatterShortStyle];
		
		setFormat = YES;
	}
	
	if(!showAmPm) {
		NSMutableString *newFormat = [[NSMutableString alloc] initWithString:[*cachePointer dateFormat]];
		[newFormat replaceOccurrencesOfString:@"a"
								   withString:@""
									  options:NSBackwardsSearch | NSLiteralSearch
										range:NSMakeRange(0,[newFormat length])];
		
		formatString = [newFormat autorelease];
	} else {
		formatString = [*cachePointer dateFormat];
	}
	
	formatString = [formatString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (setFormat)
		[*cachePointer setDateFormat:formatString];
		
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
    NSInteger		weeks = 0, days = 0, hours = 0, minutes = 0;
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
        weeksString		= [NSString stringWithFormat: @"%liw",(long)weeks];
		daysString		= [NSString stringWithFormat: @"%id",(int)days];
		hoursString		= [NSString stringWithFormat: @"%ih",(int)hours];
		minutesString	= [NSString stringWithFormat: @"%im",(int)minutes];
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
		else if (showSeconds && (seconds >= 0.5))
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
		if (showSeconds && (seconds >= 0.5))
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
	
	NSScanner *scanner = [[[NSScanner alloc] initWithString:format] autorelease];
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
                    [newFormat appendFormat:@"%%%luY", (unsigned long)[span length]];
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
			switch ([span length]) {
				case 1:
					[newFormat appendString:@"GMT%z"];
					break;
				default:
					[newFormat appendString:@"%z"];
			}
			
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
	NSString *result = [[newFormat copy] autorelease];
	[newFormat release];
	return result;

	// http://developer.apple.com/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatterSyntax.html
	// http://unicode.org/reports/tr35/tr35-4.html#Date_Format_Patterns
}

/*!
 *@brief get the Unicode TR35-4-style format string for an NSDateFormatter
 *
 *@result an NSString containing the Unicode-style format string
 */ 
- (NSString *)dateUnicodeFormat {
	NSString *format = [self dateFormat];
	
	// If we're using 10.4+ behavior, it's easy
	if ([self formatterBehavior] == NSDateFormatterBehavior10_4) {
		return format;
	}
	
	// Scan across the format string, building the strftime-style format
	NSMutableString *newFormat = [[NSMutableString alloc] initWithCapacity:[format length]];
	
	NSScanner *scanner = [[[NSScanner alloc] initWithString:format] autorelease];
	[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithRange:NSMakeRange(0, 0)]];
		
	while(![scanner isAtEnd]) {		
		// Skip to the first percentage sign
		NSString *skipped;
		if ([scanner scanUpToString:@"%" intoString:&skipped]) {
			[newFormat appendString:skipped];
			continue;
		}
		
		// Scan the percentage sign, we don't care about it
		[scanner scanString:@"%" intoString:nil];

		// Get the character following the format string
		NSUInteger n = 2;
		unichar it = [format characterAtIndex:[scanner scanLocation]];
		
		// Did we get a numeric flag? These aren't actually documented, so
		// it's unclear as to how to treat them. Can you have multiple digits?
		// Currently we don't support padding, so %5Y will incorrectly yield
		// 2008 (yyyy) instead of 02008 (yyyyy).
		if (it >= '0' && it <= '9') {
			n = it - '0';
			[scanner setScanLocation:[scanner scanLocation] + 2];
			it = [format characterAtIndex:[scanner scanLocation]];
		} else {
			[scanner setScanLocation:[scanner scanLocation] + 1];
		}
		
		// Perform the translation		
		// XXX Not supported or not fully supported: 
		
		if (it == '%') {
			[newFormat appendString:@"%"];
			
		} else if (it == 'a') {
			[newFormat appendString:@"EEE"];
			
		} else if (it == 'A') {
			[newFormat appendString:@"EEEE"];
			
		} else if (it == 'b') {
			[newFormat appendString:@"MMM"];
		
		} else if (it == 'B') {
			[newFormat appendString:@"MMMM"];
			
		} else if (it == 'c') {
			// Same as "%X %x"
			// Not an exact conversion, I should see what matches most closely.
			NSDateFormatter *tempFormatter = [[NSDateFormatter alloc] init];
			[tempFormatter setDateStyle:NSDateFormatterFullStyle];
			[tempFormatter setTimeStyle:NSDateFormatterFullStyle];
			[newFormat appendString:[tempFormatter dateFormat]];
			[tempFormatter release];
			
		} else if (it == 'd') {
			if (n < 2) {
				[newFormat appendString:@"d"];
			} else {
				[newFormat appendString:@"dd"];
			}
			
		} else if (it == 'e') {
			[newFormat appendString:@"d"];
			
		} else if (it == 'F') {
			[newFormat appendString:@"SSSS"];
			
		} else if (it == 'H') {
			if (n < 2) {
				[newFormat appendString:@"H"];
			} else {
				[newFormat appendString:@"HH"];
			}
			
		} else if (it == 'I') {
			if (n < 2) {
				[newFormat appendString:@"h"];
			} else {
				[newFormat appendString:@"hh"];
			}
			
		} else if (it == 'j') {
			if (n < 2) {
				[newFormat appendString:@"D"];
			} else if (n == 2) {
				[newFormat appendString:@"DD"];
			} else {
				[newFormat appendString:@"DDD"];
			}
		
		} else if (it == 'm') {
			if (n < 2) {
				[newFormat appendString:@"M"];
			} else {
				[newFormat appendString:@"MM"];
			}
			
		} else if (it == 'M') {
			if (n < 2) {
				[newFormat appendString:@"m"];
			} else {
				[newFormat appendString:@"mm"];
			}
			
		} else if (it == 'p') {
			[newFormat appendString:@"a"];
			
		} else if (it == 's') {
			if (n < 2) {
				[newFormat appendString:@"s"];
			} else {
				[newFormat appendString:@"ss"];
			}
			
		} else if (it == 'w') {
			// Not a perfect translation, assumes start of week is Sunday. If it
			// is Monday, should use 'E' instead of 'e'.
			if (n < 2) {
				[newFormat appendString:@"e"];
			} else {
				[newFormat appendString:@"ee"];
			}
			
		} else if (it == 'x') {
			// Date representation for the locale, including time zone.
			// Not an exact conversion, I should see what matches most closely.
			NSDateFormatter *tempFormatter = [[NSDateFormatter alloc] init];
			[tempFormatter setDateStyle:NSDateFormatterFullStyle];
			[tempFormatter setTimeStyle:NSDateFormatterNoStyle];
			[newFormat appendString:[tempFormatter dateFormat]];
			[tempFormatter release];
			
			
		} else if (it == 'X') {
			// Time representation for the locale.
			// Not an exact conversion, I should see what matches most closely.
			NSDateFormatter *tempFormatter = [[NSDateFormatter alloc] init];
			[tempFormatter setDateStyle:NSDateFormatterNoStyle];
			[tempFormatter setTimeStyle:NSDateFormatterFullStyle];
			[newFormat appendString:[tempFormatter dateFormat]];
			[tempFormatter release];
			
		} else if (it == 'y' || (it == 'Y' && n <= 2)) {
			if (n < 2) {
				[newFormat appendString:@"y"];
			} else {
				[newFormat appendString:@"yy"];
			}
			
		} else if (it == 'Y') {
			if (n == 3) {
				[newFormat appendString:@"yyy"];
			} else {
				[newFormat appendString:@"yyyy"];
			}
			
		} else if (it == 'Z') {
			[newFormat appendString:@"zzzz"];
		
		} else if (it == 'z') {
			[newFormat appendString:@"ZZ"];
		
		} else {
			// Not a supported identifier
		}
			
			
	}
	
	// Make it immutable
	NSString *result = [[newFormat copy] autorelease];
	[newFormat release];
	return result;
	
	// http://developer.apple.com/documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatterSyntax.html
	// http://unicode.org/reports/tr35/tr35-4.html#Date_Format_Patterns
}

@end
