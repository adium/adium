//
//  AIFacebookIncomingMessageManager.h
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//


@class AIFacebookAccount;

@interface AIFacebookIncomingMessageManager : NSObject {
	AIFacebookAccount	*account;
	NSURLConnection		*loveConnection;
	NSMutableData		*receivedData;
	
	NSString	*channel;
	NSString	*facebookUID;
	NSInteger sequenceNumber;
}

+ (AIFacebookIncomingMessageManager *)incomingMessageManagerForAccount:(AIFacebookAccount *)inAccount;
- (void)disconnect;

@end
