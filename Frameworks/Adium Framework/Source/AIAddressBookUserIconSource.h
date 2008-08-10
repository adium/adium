//
//  AIAddressBookUserIconSource.h
//  Adium
//
//  Created by Evan Schoenberg on 1/4/08.
//

#import <Adium/AIUserIcons.h>
#import <AddressBook/AddressBook.h>

@interface AIAddressBookUserIconSource : NSObject <AIUserIconSource, ABImageClient> {
	AIUserIconPriority	priority;
    BOOL                preferAddressBookImages;
    BOOL                useABImages;
	
	NSMutableDictionary *trackingDictPersonToTagNumber;
	NSMutableDictionary *trackingDictTagNumberToPerson;	
    NSMutableDictionary *trackingDict;
}

- (BOOL)queueDelayedFetchOfImageFromAnySourceForPerson:(ABPerson *)person object:(AIListObject *)inObject;

@end
