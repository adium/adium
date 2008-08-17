//
//  FileAttributes.m
//  Logtastic
//
//  Created by Ladd Van Tol on Sat Mar 29 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import "FileAttributes.h"

NSDate* convertUTCtoNSDate(UTCDateTime input);
NSDate* dateForJan1904();
UTCDateTime convertNSDatetoUTC(NSDate* date);

NSDate* dateForJan1904()
{		// utility to return a singleton reference NSDate
	static NSDate* Jan1904 = nil;
	if (!Jan1904) {
		Jan1904 = [[NSDate dateWithString:@"1904-01-01 00:00:00 +0000"] retain];
	}
	return Jan1904;
}

NSDate* convertUTCtoNSDate(UTCDateTime input)
{
	NSDate* result = nil;
	union
	{
		UTCDateTime local;
		UInt64 shifted;
	} time;
	time.local = input;
	if (time.shifted)
	{
		result = [[[NSDate alloc] initWithTimeInterval:time.shifted/65536
			sinceDate:dateForJan1904()] autorelease];
	}
	return result;
}

@implementation FileAttributes

+ (NSDate *) getCreationDateForPath:(NSString *) path
{
	FSCatalogInfo catalogInfo;
	FSRef fsRef;
	OSStatus err = noErr;
	
	err = FSPathMakeRef((UInt8 *) [path UTF8String], &fsRef, NULL);
	if (err == noErr)
	{
		err = FSGetCatalogInfo(&fsRef, kFSCatInfoCreateDate, &catalogInfo, NULL, NULL, NULL);
		if (err == noErr)
		{
			return convertUTCtoNSDate(catalogInfo.createDate);
		}
	}
	
	return NULL;
}

@end
