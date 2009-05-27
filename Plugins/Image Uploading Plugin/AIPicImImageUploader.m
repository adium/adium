//
//  AIPicImImageUploader.m
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AIPicImImageUploader.h"

#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>

#define MULTIPART_FORM_BOUNDARY	@"bf5faadd239c17e35f91e6dafe1d2f96"
#define PIC_IM_URL				@"http://api.tr.im/api/picim_url.xml"

@interface AIPicImImageUploader()
- (id)initWithImage:(NSImage *)inImage
		   uploader:(AIImageUploaderPlugin *)inUploader
			   chat:(AIChat *)inChat;
- (void)uploadImage;
- (void)finishResponse;
@end

@implementation AIPicImImageUploader
+ (NSString *)serviceName
{
	return @"pic.im";
}

+ (id)uploadImage:(NSImage *)image forUploader:(AIImageUploaderPlugin *)uploader inChat:(AIChat *)chat;
{
	return [[[self alloc] initWithImage:image uploader:uploader chat:chat] autorelease];
}

- (id)initWithImage:(NSImage *)inImage
		   uploader:(AIImageUploaderPlugin *)inUploader
			   chat:(AIChat *)inChat
{
	if ((self = [super init])) {
		image = [inImage retain];
		uploader = inUploader;
		chat = inChat;
		
		[self uploadImage];
	}
	
	return self;
}

- (void)dealloc
{
	[response release];
	[responseParser release];
	[image release];
	[connection release];
	[receivedData release];
	
	[super dealloc];
}

#pragma mark Image upload

- (void)uploadImage
{
	NSBitmapImageRep *bitmapImageRep = nil;
	
	for (NSImageRep *rep in image.representations) {
		if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
			bitmapImageRep = (NSBitmapImageRep *)rep;
			break;
		}
	}
	
	// This probably won't happen.
	if (!bitmapImageRep) {
		[uploader errorWithMessage:AILocalizedString(@"Unknown image type", nil) forChat:chat];
		return;
	}
	
	NSMutableData *body = [NSMutableData data];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"media\"; filename=\"image.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[bitmapImageRep representationUsingType:NSPNGFileType properties:nil]];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:PIC_IM_URL]];
	
	[request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", MULTIPART_FORM_BOUNDARY] forHTTPHeaderField:@"Content-type"];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:body];

	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection) {
		receivedData = [[NSMutableData data] retain];
	} else {
		[uploader errorWithMessage:AILocalizedString(@"Unable to connect", nil) forChat:chat];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)inConnection
  didFailWithError:(NSError *)error
{
    [connection release]; connection = nil;
    [receivedData release]; receivedData = nil;
	
	[uploader errorWithMessage:error.localizedDescription forChat:chat];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{	
	AILogWithSignature(@"%@", [NSString stringWithData:receivedData encoding:NSUTF8StringEncoding]);
	
	response = [[NSMutableDictionary alloc] init];
	
	responseParser = [[NSXMLParser alloc] initWithData:receivedData];
	[responseParser setDelegate:self];
	[responseParser parse];
	
    [connection release]; connection = nil;
    [receivedData release]; receivedData = nil;
}

- (void)cancel
{
	[connection cancel];
	
	[connection release]; connection = nil;
    [receivedData release]; receivedData = nil;
}

#pragma mark Response parsing

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	currentElement = response;
}

- (void)parser:(NSXMLParser *)parser 
parseErrorOccurred:(NSError *)error
{
	AILogWithSignature(@"%@", [error localizedDescription]);
	
	[responseParser release]; responseParser = nil;
	
	[uploader errorWithMessage:[error localizedDescription] forChat:chat];
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributes
{	
	if (elementName) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		
		[currentElement setValue:dict forKey:elementName];
		
		lastElement = currentElement;
		currentElement = dict;
	}
	
	[currentElement addEntriesFromDictionary:attributes];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	// We don't see anything more than 2-deep. We don't need to check more.
	currentElement = lastElement;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (![currentElement objectForKey:@"value"]) {
		[currentElement setValue:[NSMutableString string] forKey:@"value"];
	}
	
	[[currentElement objectForKey:@"value"] appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{	
	[responseParser release]; responseParser = nil;
	
	[self finishResponse];
}

- (void)finishResponse
{
	NSDictionary *status = [[response objectForKey:@"trim"] objectForKey:@"status"];
	
	if ([[status objectForKey:@"result"] isCaseInsensitivelyEqualToString:@"error"]) {
		[uploader errorWithMessage:[status objectForKey:@"message"] forChat:chat];
	} else {
		// TODO when api key :(
	}
	
	NSLog(@"%@", response);
}

@end
