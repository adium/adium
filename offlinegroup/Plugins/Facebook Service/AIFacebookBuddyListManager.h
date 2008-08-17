//
//  AIFacebookBuddyListManager.h
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//


@class AIFacebookAccount;
@class AIListContact;

@interface AIFacebookBuddyListManager : NSObject {
	AIFacebookAccount	*account;
	NSURLConnection		*loveConnection;
	NSTimer				*timer_polling;
	NSMutableData		*receivedData;
	
	NSDictionary		*lastAvailableBuddiesList;
}

+ (AIFacebookBuddyListManager *)buddyListManagerForAccount:(AIFacebookAccount *)inAccount;
- (void)disconnect;
- (void)moveContact:(AIListContact *)listContact toGroupWithName:(NSString *)groupName;

@end
