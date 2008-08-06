//
//  AIFacebookStatusManager.m
//  Adium
//
//  Created by Evan Schoenberg on 5/12/08.
//

#import "AIFacebookStatusManager.h"
#import "AIFacebookAccount.h"

@implementation AIFacebookStatusManager

+ (void)setFacebookStatusMessage:(NSString *)statusMessage forAccount:(AIFacebookAccount *)account
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.facebook.com/updatestatus.php"]
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:120];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [account postFormID], @"post_form_id",
						  statusMessage, @"status",
						  nil];
	NSData *postData = [AIFacebookAccount postDataForDictionary:dict];
	[request setHTTPMethod:@"POST"];
	[request setValue:[NSString stringWithFormat:@"%lu", [postData length]] forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
	
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

+ (void)connection:(NSURLConnection *)inConnection didReceiveResponse:(NSURLResponse *)response
{
    //This can be called multiple times, for example in the case of a redirect, so each time we reset the data.
}

+ (void)connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)data
{
	NSMutableString *receivedString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	AILogWithSignature(@"Received %@", receivedString);
	[receivedString release];
}

+ (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{
	[inConnection release];
}

@end
