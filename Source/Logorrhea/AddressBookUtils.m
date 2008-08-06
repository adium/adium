//
//  AddressBookUtils.m
//  Logtastic
//
//  Created by Ladd Van Tol on Sat Mar 29 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import "AddressBookUtils.h"


@implementation AddressBookUtils
+ (NSString *) lookupRealNameForIMNick:(NSString*) nick
{
	ABAddressBook *AB = [ABAddressBook sharedAddressBook];
	ABSearchElement *imNick = [ABPerson searchElementForProperty:kABAIMInstantProperty label:nil key:nil value:nick comparison:kABEqualCaseInsensitive];
	NSArray *peopleFound = [AB recordsMatchingSearchElement:imNick];
	
	if (peopleFound && [peopleFound count] > 0)
	{
		ABRecord *record = [peopleFound objectAtIndex:0];
		
		NSString *firstName = [record valueForProperty:kABFirstNameProperty];
		NSString *lastName = [record valueForProperty:kABLastNameProperty];
		
		if (firstName && lastName)
		{
			return [[firstName stringByAppendingString:@" "] stringByAppendingString:lastName];
		}
	}
	
	return NULL;
}

@end
