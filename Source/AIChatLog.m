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

#import "AIChatLog.h"
#import "AILoginController.h"
#import "AILogViewerWindowController.h"
#import "AILoggerPlugin.h"

#import <AIUtilities/ISO8601DateFormatter.h>

@implementation AIChatLog

- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass
{
    if ((self = [super init])) {
		relativePath = [inPath retain];
		from = [inFrom retain];
		to = [inTo retain];
		serviceClass = [inServiceClass retain];
		rankingPercentage = 0;
		
		formatter = [[ISO8601DateFormatter alloc] init];
	}

    return self;
}

- (id)initWithPath:(NSString *)inPath
{
	NSString *parentPath = [inPath stringByDeletingLastPathComponent];
	NSString *toUID = [parentPath lastPathComponent];
	NSString *serviceAndFromUID = [[parentPath stringByDeletingLastPathComponent] lastPathComponent];

	NSString *myServiceClass, *fromUID;

	//Determine the service and fromUID - should be SERVICE.ACCOUNT_NAME
	//Check against count to guard in case of old, malformed or otherwise odd folders & whatnot sitting in log base
	NSArray *serviceAndFromUIDArray = [serviceAndFromUID componentsSeparatedByString:@"."];
	
	if ([serviceAndFromUIDArray count] >= 2) {
		myServiceClass = handleSpecialCasesForUIDAndServiceClass(toUID, [serviceAndFromUIDArray objectAtIndex:0]);
		
		//Use substringFromIndex so we include the rest of the string in the case of a UID with a . in it
		fromUID = [serviceAndFromUID substringFromIndex:([serviceClass length] + 1)]; //One off for the '.'

	} else {
		//Fallback: blank non-nil serviceClass; folderName as the fromUID
		myServiceClass = @"";
		fromUID = serviceAndFromUID;
	}

	return [self initWithPath:inPath
						 from:fromUID
						   to:toUID
				 serviceClass:myServiceClass];
}

- (void)dealloc
{
    [relativePath release];
    [from release];
    [to release];
	[serviceClass release];
    [date release];
	[formatter release];
    
    [super dealloc];
}

- (NSString *)relativePath{
    return relativePath;
}
- (NSString *)from{
    return from;
}
- (NSString *)to{
    return to;
}
- (NSString *)serviceClass{
	return serviceClass;
}
- (NSDate *)date{
	//Determine the date of this log lazily
	if (!date) {
		date = [dateFromFileName([relativePath lastPathComponent]) retain];

		if (!date) {
			//Sometimes the filename doesn't have a date (e.g., “jdoe ((null)).chatlog”). In such cases, if it's a chatlog, parse it and get the date from the first element that has one.
			//We don't do this first because NSXMLParser uses +[NSData dataWithContentsOfURL:], which is painful for large log files.
			if ([[relativePath pathExtension] isEqualToString:@"chatlog"]) {
				NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[AILoggerPlugin logBasePath] stringByAppendingPathComponent:relativePath]]];
				[parser setDelegate:self];
				[parser parse];
				[parser release];
			}
		}
	}
		
    return date;
}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	//Stop at the first element with a date.
	NSString *dateString = nil;
	if ((dateString = [attributeDict objectForKey:@"time"])) {
		date = [[formatter dateFromString:dateString] retain];
		if (date)
			[parser abortParsing];
	}
}

- (CGFloat)rankingPercentage
{
	return rankingPercentage;
}
- (void)setRankingPercentage:(CGFloat)inRankingPercentage
{
	rankingPercentage = inRankingPercentage;
}

- (void)setRankingValueOnArbitraryScale:(CGFloat)inRankingValue
{
	rankingValue = inRankingValue;
}
- (CGFloat)rankingValueOnArbitraryScale
{
	return rankingValue;
}

#pragma mark Sort Selectors

//Sort by To, then Date
- (NSComparisonResult)compareTo:(AIChatLog *)inLog
{
    NSComparisonResult  result = [to caseInsensitiveCompare:[inLog to]];
    if (result == NSOrderedSame) {
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0) {
			result = NSOrderedAscending;
		} else if (interval > 0) {
			result = NSOrderedDescending;
		}
	}
	
    return result;
}
- (NSComparisonResult)compareToReverse:(AIChatLog *)inLog
{
    NSComparisonResult  result = [[inLog to] caseInsensitiveCompare:to];
    if (result == NSOrderedSame) {
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0) {
			result = NSOrderedAscending;
		} else if (interval > 0) {
			result = NSOrderedDescending;
		}
	}
	
    return result;
}
//Sort by From, then Date
- (NSComparisonResult)compareFrom:(AIChatLog *)inLog
{
    NSComparisonResult  result = [from caseInsensitiveCompare:[inLog from]];
    if (result == NSOrderedSame) {
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0) {
			result = NSOrderedAscending;
		} else if (interval > 0) {
			result = NSOrderedDescending;
		}
	} 
	
    return result;
}
- (NSComparisonResult)compareFromReverse:(AIChatLog *)inLog
{
    NSComparisonResult  result = [[inLog from] caseInsensitiveCompare:from];
    if (result == NSOrderedSame) {
		NSTimeInterval		interval = [date timeIntervalSinceDate:[inLog date]];
		
		if (interval < 0) {
			result = NSOrderedAscending;
		} else if (interval > 0) {
			result = NSOrderedDescending;
		}
	}
    
    return result;
}

//Sort by From, then Date
- (NSComparisonResult)compareService:(AIChatLog *)inLog
{
    NSComparisonResult  result = [serviceClass caseInsensitiveCompare:inLog.serviceClass];
    if (result == NSOrderedSame) {
		NSTimeInterval		interval = [date timeIntervalSinceDate:inLog.date];
		
		if (interval < 0) {
			result = NSOrderedAscending;
		} else if (interval > 0) {
			result = NSOrderedDescending;
		}
	} 
	
    return result;
}
- (NSComparisonResult)compareServiceReverse:(AIChatLog *)inLog
{
    NSComparisonResult  result = [inLog.serviceClass caseInsensitiveCompare:serviceClass];
    if (result == NSOrderedSame) {
		NSTimeInterval		interval = [date timeIntervalSinceDate:inLog.date];
		
		if (interval < 0) {
			result = NSOrderedAscending;
		} else if (interval > 0) {
			result = NSOrderedDescending;
		}
	}
    
    return result;
}

//Sort by Date, then To
- (NSComparisonResult)compareDate:(AIChatLog *)inLog
{
	NSComparisonResult  result;
	NSTimeInterval		interval = [[self date] timeIntervalSinceDate:[inLog date]];
	
	if (interval < 0) {
		result = NSOrderedAscending;
	} else if (interval > 0) {
		result = NSOrderedDescending;
	} else {
		result = [to caseInsensitiveCompare:[inLog to]];
    }
	
    return result;
}
- (NSComparisonResult)compareDateReverse:(AIChatLog *)inLog
{
	NSComparisonResult  result;
	NSTimeInterval		interval = [[inLog date] timeIntervalSinceDate:[self date]];

	if (interval < 0) {
		result = NSOrderedAscending;
	} else if (interval > 0) {
		result = NSOrderedDescending;
	} else {
		result = [[inLog to] caseInsensitiveCompare:to];
    }
	
    return result;
}

-(NSComparisonResult)compareRank:(AIChatLog *)inLog
{
	NSComparisonResult  result;
	CGFloat				otherRankingPercentage = [inLog rankingPercentage];
	
	if (rankingPercentage > otherRankingPercentage) {
		result = NSOrderedDescending;		
	} else if (rankingPercentage < otherRankingPercentage) {
		result = NSOrderedAscending;	
	} else {
		result = [to caseInsensitiveCompare:[inLog to]];
    }
	
	return result;
}
-(NSComparisonResult)compareRankReverse:(AIChatLog *)inLog
{
	NSComparisonResult  result;
	CGFloat				otherRankingPercentage = [inLog rankingPercentage];
	
	if (rankingPercentage > otherRankingPercentage) {
		result = NSOrderedAscending;		
	} else if (rankingPercentage < otherRankingPercentage) {
		result = NSOrderedDescending;				
	} else {
		result = [[inLog to] caseInsensitiveCompare:to];
    }
	
	return result;
}

#pragma mark Date utilities

//Given an Adium log file name, return an NSDate with year, month, and day specified
NSDate *dateFromFileName(NSString *fileName)
{
	ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
	formatter.timeSeparator = '.';
	NSRange openParenRange, closeParenRange;
	
	if ((openParenRange = [fileName rangeOfString:@"(" options:NSBackwardsSearch]).location != NSNotFound) {
		openParenRange = NSMakeRange(openParenRange.location, [fileName length] - openParenRange.location);
		if ((closeParenRange = [fileName rangeOfString:@")" options:0 range:openParenRange]).location != NSNotFound) {
			//Add and subtract one to remove the parenthesis
			NSString *dateString = [fileName substringWithRange:NSMakeRange(openParenRange.location + 1, (closeParenRange.location - openParenRange.location))];
			// Fix really old chatlogs which use "(2005|05|07)".
			return [formatter dateFromString:[dateString stringByReplacingOccurrencesOfString:@"|" withString:@"-"]];
		}
	}
	return nil;
}

@end
