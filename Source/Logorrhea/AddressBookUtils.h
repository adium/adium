//
//  AddressBookUtils.h
//  Logtastic
//
//  Created by Ladd Van Tol on Sat Mar 29 2003.
//  Copyright (c) 2003 Spiny. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>


@interface AddressBookUtils : NSObject
{

}

+ (NSString *) lookupRealNameForIMNick:(NSString*) nick;

@end
