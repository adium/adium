//
//  AIFacebookBuddyIconRequest.m
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import "AIFacebookBuddyIconRequest.h"
#import <Adium/AIListContact.h>

@interface AIFacebookBuddyIconRequest (PRIVATE)
- (id)initForContact:(AIListContact *)inContact withThumbSrc:(NSString *)thumbSrc;
@end 

@implementation AIFacebookBuddyIconRequest

+ (void)retrieveBuddyIconForContact:(AIListContact *)inContact withThumbSrc:(NSString *)thumbSrc
{
	//Will release ourselves when done
	[[self alloc] initForContact:inContact withThumbSrc:thumbSrc];
}

- (id)initForContact:(AIListContact *)inContact withThumbSrc:(NSString *)thumbSrc
{
	if ((self = [super init])) {
		contact = [inContact retain];
		receivedData = [[NSMutableData alloc] init];

		NSURL *URL;
		NSMutableString  *fileName = [[thumbSrc lastPathComponent] mutableCopy];

		/* The file name starts with a 'q' for the small thumbnail and with an 'n' for a higher-resolution one */
		[fileName replaceOccurrencesOfString:@"q"
                                  withString:@"n"
                                     options:NSLiteralSearch
                                       range:NSMakeRange(0, 1)];
		
		URL = [NSURL URLWithString:[[thumbSrc stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName]];
		[fileName release];

		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
															   cachePolicy:NSURLRequestUseProtocolCachePolicy
														   timeoutInterval:120];
		connection = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	}

	return self;
}

- (void)dealloc
{
	[contact release]; contact = nil;
	[connection release]; connection = nil;
	[receivedData release]; receivedData = nil;

	[super dealloc];
}

- (void)connection:(NSURLConnection *)inConnection didReceiveResponse:(NSURLResponse *)response
{
    //This can be called multiple times, for example in the case of a redirect, so each time we reset the data.
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)data
{
    //Append the new data to the receivedData
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{
	[contact setServersideIconData:receivedData notify:NotifyNow];

	[connection release]; connection = nil;

	//Retained when created via the class method
	[self autorelease];
}

@end
