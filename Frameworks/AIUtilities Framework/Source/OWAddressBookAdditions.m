//
//  OWAddressBookAdditions.m
//  Adium
//
//  Created by Ofri Wolfus on 09/07/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "OWAddressBookAdditions.h"


@implementation ABAddressBook (OWAddressBookAdditions)

- (NSArray *)peopleFromUniqueIDs:(NSArray *)uniqueIDs
{
	NSMutableArray *result = [[NSMutableArray alloc] init];
	
	for (NSString *uniqueID in uniqueIDs) {
		ABRecord *record;
		
		if ((record = [self recordForUniqueId:uniqueID]) && [record isKindOfClass:[ABPerson class]])
			[result addObject:record];
	}
	
	return [result autorelease];
}

@end
