//
//  AIFacebookBuddyListManager.m
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import "AIFacebookBuddyListManager.h"
#import "AIFacebookAccount.h"
#import "AIFacebookBuddyIconRequest.h"
#import <JSON/JSON.h>
#import <Adium/AIListContact.h>

@interface AIFacebookBuddyListManager (PRIVATE)
- (id)initForAccount:(AIFacebookAccount *)inAccount;
- (void)setupBuddyListPolling;
@end

@implementation AIFacebookBuddyListManager

+ (AIFacebookBuddyListManager *)buddyListManagerForAccount:(AIFacebookAccount *)inAccount
{
	return [[[self alloc] initForAccount:inAccount] autorelease];
}

- (id)initForAccount:(AIFacebookAccount *)inAccount
{
	if ((self = [super init])) {
		account = [inAccount retain];
		receivedData = [[NSMutableData alloc] init];

		[self setupBuddyListPolling];
	}
	
	return self;
}

- (void)disconnect
{
	[timer_polling invalidate];
	[timer_polling release]; timer_polling = nil;
	
	[account release]; account = nil;
}

- (void)parseBuddyList:(NSDictionary *)buddyList
{
	NSDictionary *nowAvailableList = [buddyList objectForKey:@"nowAvailableList"];
	NSDictionary *userInfos = [buddyList objectForKey:@"userInfos"];

	NSSet *nowAvailableContacts = [NSSet setWithArray:[nowAvailableList allKeys]];

	BOOL isSigningOn = [account isSigningOn];

	//Process each online contact's information
	NSEnumerator *enumerator = [nowAvailableContacts objectEnumerator];
	NSString	 *contactUID;
	while ((contactUID = [enumerator nextObject])) {
		AIListContact *listContact = [account contactWithUID:contactUID];
		NSDictionary  *dict = [userInfos objectForKey:contactUID];
		NSString	  *name = [dict objectForKey:@"name"];
		/*
		 NSString	  *firstName = [dict objectForKey:@"firstName"];
		 if ([firstName isKindOfClass:[NSNull class]]) firstName = nil;
		 */
		NSString	  *status = [dict objectForKey:@"status"];
		/*
		 NSString	  *statusTime = [dict objectForKey:@"statusTime"];
		 if ([statusTime isKindOfClass:[NSNull class]]) statusTime = nil;
		 NSDate		  *dateStatusLastChanged = (statusTime ?
												[NSDate dateWithTimeIntervalSince1970:([statusTime intValue])] :
												nil);		
		 */
		NSString	  *pictureSrc = [dict objectForKey:@"thumbSrc"];
		
		//The parser gives us NSNull in place of a string if there is a nil value
		if ([name isKindOfClass:[NSNull class]]) name = nil;
		if ([status isKindOfClass:[NSNull class]]) status = nil;

		[listContact setFormattedUID:name notify:NotifyLater];
	
		[listContact setStatusMessage:((status && [status length]) ? 
									   [[[NSAttributedString alloc] initWithString:status] autorelease] :
									   nil)
							   notify:NotifyLater];
		[listContact setIdle:[[[nowAvailableList objectForKey:contactUID] objectForKey:@"i"] boolValue]
				   sinceDate:nil
					  notify:NotifyLater];

		if (pictureSrc)
			[AIFacebookBuddyIconRequest retrieveBuddyIconForContact:listContact
													   withThumbSrc:pictureSrc];
	
		if (![listContact remoteGroupName]) {
			NSString *groupName = [listContact preferenceForKey:@"Facebook Local Group"
														  group:@"Facebook"];
			if (!groupName) groupName = @"Facebook";
			[listContact setRemoteGroupName:groupName];
		}

		[listContact setOnline:YES notify:NotifyLater silently:isSigningOn];

		//Apply any changes
		[listContact notifyOfChangedPropertiesSilently:isSigningOn];	
	}
	
	if (lastAvailableBuddiesList) {
		NSMutableSet *signedOffContacts = [lastAvailableBuddiesList mutableCopy];
		[signedOffContacts minusSet:nowAvailableContacts];
		
		enumerator = [signedOffContacts objectEnumerator];
		while ((contactUID = [enumerator nextObject])) {
			AIListContact *listContact = [account contactWithUID:contactUID];
			[listContact setOnline:NO notify:NotifyLater silently:isSigningOn];
			
			//Apply any changes
			[listContact notifyOfChangedPropertiesSilently:isSigningOn];
		}

		[signedOffContacts release];
	}
	
	[lastAvailableBuddiesList release]; lastAvailableBuddiesList = [nowAvailableContacts retain];
}

- (void)moveContact:(AIListContact *)listContact toGroupWithName:(NSString *)groupName
{
	//Tell the purple thread to perform the serverside operation
	[listContact setPreference:groupName
					   forKey:@"Facebook Local Group"
						group:@"Facebook"];
	
	//Use the non-mapped group name locally
	[listContact setRemoteGroupName:groupName];
}	

- (void)parseNotifications:(NSDictionary *)notifications
{
	AILogWithSignature(@"Parsing %@", notifications);
}

- (void)pollBuddyList:(NSTimer *)inTimer
{
	/* If we have an existing connection, it timed out. Give up and try again. */
	if (loveConnection) {
		[loveConnection cancel];
		[loveConnection release];
	}

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.facebook.com/ajax/presence/update.php"]
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];
	NSData *postData = [AIFacebookAccount postDataForDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"1", @"buddy_list",
																 @"1", @"notifications",
																 @"true", @"force_render",
																 [account postFormID], @"post_form_id",
																 [account facebookUID], @"user",
																 nil]];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%lu", [postData length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
	
	loveConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)setupBuddyListPolling
{
	timer_polling = [[NSTimer scheduledTimerWithTimeInterval:60
													  target:self
													selector:@selector(pollBuddyList:)
													userInfo:nil
													 repeats:YES] retain];
	[self pollBuddyList:timer_polling];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // it can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
    // receivedData is declared as a method instance elsewhere
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    // receivedData is declared as a method instance elsewhere
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSMutableString *receivedString = [[NSMutableString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];

	//Remove the javascript part of the response so we just have a JSON string
	if ([receivedString hasPrefix:@"for (;;);"])
		[receivedString deleteCharactersInRange:NSMakeRange(0, [@"for (;;);" length])];

	NSDictionary *buddyListJSONDict = [receivedString JSONValue];

	AILogWithSignature(@"%@", buddyListJSONDict);
	if ([[buddyListJSONDict objectForKey:@"error"] integerValue]) {
		if ([[buddyListJSONDict objectForKey:@"errorSummary"] length] &&
			[[buddyListJSONDict objectForKey:@"errorSummary"] isEqualToString:@"Not Logged In"]) {
				[account reconnect];		
		} else if ([[buddyListJSONDict objectForKey:@"error"] integerValue] == 1357001) {
			[account setLastDisconnectionError:AILocalizedString(@"Logged in from another location", nil)];
			[account disconnect];
		}
	}

	NSDictionary *payload = [buddyListJSONDict objectForKey:@"payload"];
	[self parseBuddyList:[payload objectForKey:@"buddy_list"]];
	[self parseNotifications:[payload objectForKey:@"notifications"]];

	[receivedString release];
	
    //Release the connection, and trunacte the data object
    [loveConnection release]; loveConnection = nil;
    [receivedData setLength:0];
}

@end
