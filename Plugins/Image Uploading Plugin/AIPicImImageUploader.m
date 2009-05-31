//
//  AIPicImImageUploader.m
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AIPicImImageUploader.h"

#import <Adium/AIChat.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIProgressDataUploader.h>
#import <AIUtilities/AIImageAdditions.h>

#define MULTIPART_FORM_BOUNDARY	@"bf5faadd239c17e35f91e6dafe1d2f96"
#define PIC_IM_URL				@"http://api.tr.im/api/picim_url.xml?api_key=zghQN6sv5y0FkLPNlQAopm7qDQz6ItO33ENU21OBsy3dL1Kl"
#define PIC_IM_MAX_SIZE			2500000

@interface AIPicImImageUploader()
- (id)initWithImage:(NSImage *)inImage
		   uploader:(AIImageUploaderPlugin *)inUploader
			   chat:(AIChat *)inChat;
- (void)uploadImage;
- (void)parseResponse:(NSData *)data;
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
	[dataUploader release]; dataUploader = nil;
	[resultData release]; resultData = nil;
	[response release]; response = nil;
	[responseParser release]; responseParser = nil;
	[image release]; image = nil;
	
	[super dealloc];
}

#pragma mark Data uploader delegate
- (void)updateUploadProgress:(NSUInteger)uploaded total:(NSUInteger)total context:(id)context
{
	[uploader updateProgress:uploaded total:total forChat:chat];
}

- (void)uploadCompleted:(id)context result:(NSData *)result
{
	if (result.length) {
		[self parseResponse:result];
	} else {
		[uploader errorWithMessage:AILocalizedString(@"Unable to upload", nil) forChat:chat];
	}
}

- (void)uploadFailed:(id)context
{
	[uploader errorWithMessage:AILocalizedString(@"Unable to upload", nil) forChat:chat];
}

#pragma mark Image upload

- (void)uploadImage
{
	NSMutableData *body = [NSMutableData data];
	
	NSBitmapImageFileType bestType;
	
	NSData *pngRepresentation = [[image largestBitmapImageRep] representationUsingType:NSPNGFileType properties:nil];
	NSData *jpgRepresentation = [[image largestBitmapImageRep] representationUsingType:NSJPEGFileType properties:nil];

	if (pngRepresentation.length > jpgRepresentation.length) {
		bestType = NSJPEGFileType;
	} else {
		bestType = NSPNGFileType;
	}
	
	NSData *imageRepresentation = [image representationWithFileType:bestType maximumFileSize:PIC_IM_MAX_SIZE];
	
	if (!imageRepresentation) {
		[uploader errorWithMessage:AILocalizedString(@"Unable to upload", nil) forChat:chat];
		return;
	}
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"media\"; filename=\"image.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", (bestType == NSJPEGFileType) ? @"image/jpeg" : @"image/png"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageRepresentation];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];

	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSString stringWithFormat:@"multipart/form-data; boundary=%@", MULTIPART_FORM_BOUNDARY], @"Content-type", nil];
	
	dataUploader = [[AIProgressDataUploader dataUploaderWithData:body
															 URL:[NSURL URLWithString:PIC_IM_URL]
														 headers:headers
														delegate:self
														 context:nil] retain];
	
	[dataUploader upload];
}

- (void)cancel
{
	[dataUploader cancel];
}

#pragma mark Response parsing
- (void)parseResponse:(NSData *)data
{
	response = [[NSMutableDictionary alloc] init];
	resultData = [data copy];
	
	AILogWithSignature(@"%@", [NSString stringWithData:data encoding:NSUTF8StringEncoding]);
	
	responseParser = [[NSXMLParser alloc] initWithData:resultData];
	[responseParser setDelegate:self];
	[responseParser parse];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	currentElement = response;
}

- (void)parser:(NSXMLParser *)parser 
parseErrorOccurred:(NSError *)error
{
	AILogWithSignature(@"%@", [error localizedDescription]);
	
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
	NSDictionary *trim = [response objectForKey:@"trim"];
	NSDictionary *status = [trim objectForKey:@"status"];
	
	if ([[status objectForKey:@"result"] isCaseInsensitivelyEqualToString:@"error"]) {
		[uploader errorWithMessage:[status objectForKey:@"message"] forChat:chat];
	} else if ([[status objectForKey:@"result"] isCaseInsensitivelyEqualToString:@"ok"]) {
		[uploader uploadedURL:[[trim objectForKey:@"url"] objectForKey:@"value"] forChat:chat];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AIPicImImageAdded"
															object:trim];
	} else {
		[uploader errorWithMessage:AILocalizedString(@"Unable to upload", nil) forChat:chat];
	}
}

@end
