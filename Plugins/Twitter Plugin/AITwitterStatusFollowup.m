//
//  AITwitterStatusFollowup.m
//  Adium
//
//  Created by Zachary West on 2009-05-28.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AITwitterStatusFollowup.h"
#import "AITwitterAccount.h"
#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIStringAdditions.h>

@interface AITwitterStatusFollowup()
- (void)twitterStatusPosted:(NSNotification *)notification;
- (void)imageAdded:(NSNotification *)notification;
- (void)linkTweetID:(NSString *)tweetID
			  tweet:(NSString *)tweetText
		   username:(NSString *)username
			network:(NSString *)network
		  reference:(NSString *)reference;
@end

@implementation AITwitterStatusFollowup
- (void)installPlugin
{
	references = [[NSMutableDictionary alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(twitterStatusPosted:)
												 name:AITwitterNotificationPostedStatus
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(imageAdded:)
												 name:@"AIPicImImageAdded"
											   object:nil];	
}

- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
	[references release];
	
	[super dealloc];
}

- (void)imageAdded:(NSNotification *)notification
{
	NSDictionary *trim = notification.object;
	
	[references setObject:[[trim objectForKey:@"reference"] objectForKey:@"value"] 
				   forKey:[[trim objectForKey:@"url"] objectForKey:@"value"]];
}

- (void)twitterStatusPosted:(NSNotification *)notification
{
	NSDictionary	*update = notification.object;
	AIChat			*chat = [[notification userInfo] objectForKey:@"AIChat"];
	NSString		*updateText = [update objectForKey:TWITTER_STATUS_TEXT];
	
	// Don't link direct messages.
	if ([updateText hasPrefix:@"d "]) {
		return;
	}
	
	for (NSString *purl in references) {
		if ([updateText rangeOfString:purl options:NSCaseInsensitiveSearch].location != NSNotFound) {
			AIAccount *account = chat.account;
			NSString *network = nil;
			
			// Valid network type is either "twitter" or "identica"
			if ([account.host isEqualToString:@"twitter.com"]) {
				network = @"twitter";
			} else if ([account.host isEqualToString:@"identi.ca"]) {
				network = @"identica";
			}
			
			// A random laconica network, or something.
			if (!network)
				continue;
			
			// Perform the link.
			[self linkTweetID:[update objectForKey:TWITTER_STATUS_ID] 
						tweet:updateText
					 username:account.UID
					  network:network
					reference:[references objectForKey:purl]];
		}
	}
}

- (void)linkTweetID:(NSString *)tweetID
			  tweet:(NSString *)tweetText
		   username:(NSString *)username
			network:(NSString *)network
		  reference:(NSString *)reference
{
	NSMutableString *url = [NSMutableString string];
	
	[url appendString:@"http://api.tr.im/api/picim_tweet.xml?api_key=zghQN6sv5y0FkLPNlQAopm7qDQz6ItO33ENU21OBsy3dL1Kl"];
	
	[url appendFormat:@"&reference=%@", reference];
	[url appendFormat:@"&tweet=%@", [tweetText stringByAddingPercentEscapesForAllCharacters]];
	[url appendFormat:@"&tweet_id=%@", tweetID];
	[url appendFormat:@"&username=%@", username];
	[url appendFormat:@"&network=%@", network];
	
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]
																delegate:self];
	
	// We don't implement any delegate methods, because if this fails we don't bother retrying.
	if (!connection) {
		AILogWithSignature(@"Immediate fail when trying to link tweet to %@", reference);
	}
}

@end
