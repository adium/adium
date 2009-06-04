//
//  OWAddressBookAdditions.h
//  Adium
//
//  Created by Ofri Wolfus on 09/07/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import <AddressBook/AddressBook.h>


@interface ABAddressBook (OWAddressBookAdditions)

- (NSArray *)peopleFromUniqueIDs:(NSArray *)uniqueIDs;

@end
