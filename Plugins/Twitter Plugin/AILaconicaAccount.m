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

#import "AILaconicaAccount.h"
#import "AITwitterURLParser.h"
#import <Adium/AIContactObserverManager.h>
#import <Adium/AIChatControllerProtocol.h>

@interface AITwitterAccount()

- (BOOL)checkForCursorSupport;

@end


@implementation AILaconicaAccount

- (void)initAccount
{
	[super initAccount];
	textLimitConfigDownload = nil;
	configData = nil;
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSNumber numberWithBool:YES], LACONICA_PREFERENCE_SSL, nil]
										forGroup:LACONICA_PREF_GROUP
										  object:self];
	supportsCursors = [self checkForCursorSupport];
}

- (void)connect
{	
	if (!self.host) {
		[self setLastDisconnectionError:AILocalizedString(@"No Host set", nil)];
		[self didDisconnect];
	} else {
		[super connect];
	}
}

/*!
 * @brief Our default server if none is provided.
 *
 * Do not set a default server.
 */
- (NSString *)defaultServer
{
	return nil;
}

/*!
 * @brief API path
 *
 * The API path extension for the given host.
 */
- (NSString *)apiPath
{
	// We need to guarantee this is an NSString, so -stringByAppendingPathComponent works.
	NSString *path = [self preferenceForKey:LACONICA_PREFERENCE_PATH group:LACONICA_PREF_GROUP] ?: @"";
	
	return [path stringByAppendingPathComponent:@"api"];
}

/*!
 * @brief Our source token
 *
 * On Laconica, our given source token is "adium".
 */
- (NSString *)sourceToken
{
	return @"adium";
}

/*!
 * @brief Our explicit formatted UID
 * 
 * This includes "additional necessary identifying information".
 */
- (NSString *)explicitFormattedUID
{
	if (self.host) {
		return [NSString stringWithFormat:@"%@ (%@)", self.UID, self.host];
	} else {
		return self.UID;
	}
}

/*!
 * @brief Use our host for the servername when storing password
 */
- (BOOL)useHostForPasswordServerName
{
	return YES;
}

/*!
 * @brief Not all StatusNet instances support HTTPS connections.
 */
- (BOOL)useSSL
{
	return [[self preferenceForKey:LACONICA_PREFERENCE_SSL group:LACONICA_PREF_GROUP] boolValue];
}

/*!
 * @brief Laconica does not yet support OAuth.
 */
- (BOOL)useOAuth
{
	return NO;
}

/*!
 * @brief Connection successful
 *
 * Pull all the usual stuff, but also check for the max notice length,
 * provided by StatusNet 0.9 and later.
 */
- (void)didConnect
{
	[super didConnect];

    textLimitConfigDownload = nil;
	[self queryTextLimit];
    
	AIGroupChat *timelineChat = [adium.chatController existingChatWithName:self.timelineChatName
															onAccount:self];
	if (timelineChat) {
		[self updateTimelineChat: timelineChat];
	}
}

/*!
 * @brief Query the StatusNet API for the site/textlimit config variable.
 * Returns the limit if present, or the default of 140.
 */
- (void)queryTextLimit
{
	// Hardcoded default for older servers that don't report their configured limit.
	textlimit = 140;

    NSString        *path = [[@"/" stringByAppendingPathComponent:self.apiPath]
                                   stringByAppendingPathComponent:@"statusnet/config.xml"];
    
	NSURL           *url = [[NSURL alloc] initWithScheme:(self.useSSL ? @"https" : @"http")
													 host:self.host
													 path:path];
    
    NSURLRequest    *configRequest = [NSURLRequest requestWithURL:url];
    
    if (textLimitConfigDownload) {
        [textLimitConfigDownload cancel];
        textLimitConfigDownload = nil;
    }
    
    textLimitConfigDownload = [[NSURLConnection alloc] initWithRequest:configRequest delegate:self];
}

/*!
 * @brief Downloads the configuration xml file from the server.
 */
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([connection isEqual:textLimitConfigDownload])
        [configData appendData:data];
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([connection isEqual:textLimitConfigDownload]) {
        NSError         *err = nil;
        NSXMLDocument   *config = [[NSXMLDocument alloc] initWithData:configData
                                                              options:0
                                                                error:&err];
    
        if (config != nil) {
            NSArray *nodes = [config nodesForXPath:@"/config/site/textlimit"
                                             error:&err];
            if (nodes != nil) {
                if ([nodes count] > 0)
                    textlimit = [[(NSXMLNode *)[nodes objectAtIndex: 0] stringValue] intValue];
            }
        }
        
        if (err != nil)
            AILogWithSignature(@"Failed fetching StatusNet server config for %@: %ld %@", self.host, [err code], [err localizedDescription]);
	
		configData = nil;
		textLimitConfigDownload = nil;
    }
}

/*!
 * @brief This method is called when there is an error
 */
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	textLimitConfigDownload = nil;
    
    configData = nil;
    
    AILogWithSignature(@"%@",[NSString stringWithFormat:@"Fetch failed: %@", [error localizedDescription]]);
}

/*!
 * @brief Returns the link URL for a specific type of link
 */
- (NSString *)addressForLinkType:(AITwitterLinkType)linkType
						  userID:(NSString *)userID
						statusID:(NSString *)statusID
						 context:(NSString *)context
{
	NSString *address = [super addressForLinkType:linkType userID:userID statusID:statusID context:context];
	
	NSString *fullAddress = [self.host stringByAppendingPathComponent:[self preferenceForKey:LACONICA_PREFERENCE_PATH group:LACONICA_PREF_GROUP]];
	
	NSString *protocol = self.useSSL ? @"https" : @"http";
	
	if (linkType == AITwitterLinkStatus) {
		address = [NSString stringWithFormat:@"%@://%@/notice/%@", protocol, fullAddress, statusID];
	} else if (linkType == AITwitterLinkFriends) {
		address = [NSString stringWithFormat:@"%@://%@/%@/subscriptions", protocol, fullAddress, userID];
	} else if (linkType == AITwitterLinkFollowers) {
		address = [NSString stringWithFormat:@"%@://%@/%@/subscribers", protocol, fullAddress, userID]; 
	} else if (linkType == AITwitterLinkUserPage) {
		address = [NSString stringWithFormat:@"%@://%@/%@", protocol, fullAddress, userID]; 
	} else if (linkType == AITwitterLinkSearchHash) {
		address = [NSString stringWithFormat:@"http://%@/tag/%@", fullAddress, context];
	} else if (linkType == AITwitterLinkGroup) {
		address = [NSString stringWithFormat:@"http://%@/group/%@", fullAddress, context];
	} else if (linkType == AITwitterLinkRetweet) {
		address = nil;
	}
	
	return address;
}

/*!
 * @brief Parse an attributed string into a linkified version.
 */
- (NSAttributedString *)linkifiedAttributedStringFromString:(NSAttributedString *)inString
{	
	NSAttributedString *attributedString = [super linkifiedAttributedStringFromString:inString];
	
	static NSCharacterSet *groupCharacters = nil;
	
	if (!groupCharacters) {
		NSMutableCharacterSet	*disallowedCharacters = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
		[disallowedCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
		
		groupCharacters = [disallowedCharacters invertedSet];
	}
	
	attributedString = [AITwitterURLParser linkifiedStringFromAttributedString:attributedString
															forPrefixCharacter:@"!"
																   forLinkType:AITwitterLinkGroup
																	forAccount:self
															 validCharacterSet:groupCharacters];
	
	return attributedString;
}

/*!
 * @brief Retweet the selected tweet.
 *
 * Attempts to retweet a tweet.
 * Prints a status message in the chat on success/failure, behaves identical to sending a new tweet.
 *
 * @returns YES if the account could send a retweet message, NO if the account doesn't support it.
 *
 * XXX When Laconica officially supports a retweet API, remove this method entirely.
 */
- (BOOL)retweetTweet:(NSString *)tweetID
{
	return NO;
}

/*!
 * @brief Check if the server supports cursor based userlists.
 *
 * @returns YES if the support cursor lists, NO if the account doesn't support it.
 *
 * XXX This should probably do some actual checking so we don't have to touch this when it goes live.
 */
- (BOOL)checkForCursorSupport
{
	return NO;
}

/*!
 * @brief The name of our timeline chat
 */
- (NSString *)timelineChatName
{
	return [NSString stringWithFormat:LACONICA_TIMELINE_NAME, self.host, self.UID];
}

/*!
 * @brief The remote group name we'll stuff the timeline into
 */
- (NSString *)timelineGroupName
{
	return LACONICA_REMOTE_GROUP_NAME;
}

/*!
 * @brief Returns the maximum number of characters available for a post, or 0 if unlimited.
 * For StatusNet servers, this may have been provided via API.
 */
- (int)maxChars
{
	return textlimit;
}

@end
