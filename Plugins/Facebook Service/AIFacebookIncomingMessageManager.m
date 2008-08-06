//
//  AIFacebookIncomingMessageManager.m
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import "AIFacebookIncomingMessageManager.h"
#import "AIFacebookAccount.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIListContact.h>
#import <Adium/AIChat.h>
#import <JSON/JSON.h>

@interface AIFacebookIncomingMessageManager (PRIVATE)
- (id)initForAccount:(AIFacebookAccount *)inAccount;
- (void)setupIncomingMessageMonitoring;
@end

@implementation AIFacebookIncomingMessageManager

+ (AIFacebookIncomingMessageManager *)incomingMessageManagerForAccount:(AIFacebookAccount *)inAccount
{
	return [[[self alloc] initForAccount:inAccount] autorelease];
}

- (id)initForAccount:(AIFacebookAccount *)inAccount
{
	if ((self = [super init])) {
		account = [inAccount retain];
		receivedData = [[NSMutableData alloc] init];
		
		channel = [[account channel] retain];
		facebookUID = [[account facebookUID] retain];
		sequenceNumber = -1;
		
		[self setupIncomingMessageMonitoring];
	}
	
	return self;
}

- (void)disconnect
{
	[channel release]; channel = nil;
	[facebookUID release]; facebookUID = nil;
	[account release]; account = nil;
	
	//XXX Cancel current connection
}

/*!
 * @brief We received a message
 */
- (void)receivedMessage:(NSDictionary *)messageDict
{
	NSString			*fromUID = [messageDict objectForKey:@"from"];
	//fromUID may be a number rather than a string
	if ([fromUID isKindOfClass:[NSNumber class]]) fromUID = [(NSNumber *)fromUID stringValue];

	//Don't display messages we send, which will be mirrored back to us here.
	if ([fromUID isEqualToString:[account facebookUID]]) return;

	AIListContact		*listContact = [account contactWithUID:fromUID];
	AIChat				*chat = [[adium chatController] chatWithContact:listContact];
	NSDictionary		*messageTextDict = [messageDict objectForKey:@"msg"];
	if (messageTextDict) {
		NSString			*text = [[messageTextDict objectForKey:@"text"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString			*timeString = [messageTextDict objectForKey:@"time"];
		AIContentMessage	*messageObject;
		
		messageObject = [AIContentMessage messageInChat:chat
											 withSource:listContact
											destination:account
												   date:([timeString isKindOfClass:[NSString class]] ? [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]] : nil)
												message:[[[NSAttributedString alloc] initWithString:text] autorelease]
											  autoreply:NO];
		
		[[adium contentController] receiveContentObject:messageObject];
	}
	
	NSDictionary *typingDict = [messageDict objectForKey:@"typ"];
	if (typingDict) {
		if ([[typingDict objectForKey:@"st"] isEqualToString:@"1"]) {
			[chat setValue:[NSNumber numberWithInteger:AITyping]
			   forProperty:KEY_TYPING
					notify:YES];

		} else {
			[chat setValue:nil
			   forProperty:KEY_TYPING
					notify:YES];
		}
	}
		
		
}

#pragma mark Initiating the connection
- (NSURL *)currentMessageURL
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://0.channel%@.facebook.com/x/0/false/p_%@=%ld", channel, facebookUID, sequenceNumber]];
}

- (void)setupIncomingMessageMonitoring
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self currentMessageURL]
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];
	[loveConnection release]; 
	loveConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];	
}

#pragma mark Connection response

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //It can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Append the new data to the receivedData
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSMutableString *receivedString = [[NSMutableString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
	
	//Remove the javascript part of the response so we just have a JSON string
	if ([receivedString hasPrefix:@"for (;;);"])
		[receivedString deleteCharactersInRange:NSMakeRange(0, [@"for (;;);" length])];

	NSDictionary *reply = [receivedString JSONValue];

	AILogWithSignature(@"Received %@", reply)

	NSString *command = [reply objectForKey:@"t"];
	if ([command isEqualToString:@"refresh"]) {
		//We've been told to update to a new sequence number
		sequenceNumber = [[reply objectForKey:@"seq"] integerValue];

	} else if ([command isEqualToString:@"continue"]) {
		//Just keep waiting; do nothing besides reconfiguring our connection monitoring

	} else if ([command isEqualToString:@"msg"]) {
		//We got a message! (It's an array, so we might have gotten more than one at once, actually)
		NSEnumerator *enumerator = [[reply objectForKey:@"ms"] objectEnumerator];
		NSDictionary *messageDict;
		while ((messageDict = [enumerator nextObject])) {
			[self receivedMessage:messageDict];
		}

		sequenceNumber++;
	}

	[receivedString release];
	
    //Release the connection, and trunacte the data object
	[loveConnection autorelease]; loveConnection = nil;
    [receivedData setLength:0];

	[self setupIncomingMessageMonitoring];
}

@end
