//
//  AIGenericMultipartImageUploader.m
//  Adium
//
//  Created by Zachary West on 2009-07-01.
//  Copyright 2009  . All rights reserved.
//

#import "AIGenericMultipartImageUploader.h"

#import <Adium/AIChat.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIProgressDataUploader.h>
#import <AIUtilities/AIImageAdditions.h>

#define MULTIPART_FORM_BOUNDARY	@"bf5faadd239c17e35f91e6dafe1d2f96"

@interface AIGenericMultipartImageUploader()
- (id)initWithImage:(NSImage *)inImage
		   uploader:(AIImageUploaderPlugin *)inUploader
			   chat:(AIChat *)inChat;
- (void)uploadImage;
@end

@implementation AIGenericMultipartImageUploader
+ (id)uploadImage:(NSImage *)image forUploader:(AIImageUploaderPlugin *)uploader inChat:(AIChat *)chat;
{
	return [[[self alloc] initWithImage:image uploader:uploader chat:chat] autorelease];
}

+ (NSString *)serviceName
{
	NSAssert1(NO, @"Implementation of %@ lacks serviceName", NSStringFromClass(self));
	
	return nil;
}

- (NSString *)uploadURL
{
	NSAssert1(NO, @"Implementation of %@ lacks uploadURL", self);
	
	return nil;	
}

- (NSString *)fieldName
{
	NSAssert1(NO, @"Implementation of %@ lacks fieldName", self);
	
	return nil;	
}


- (NSArray *)additionalFields
{	
	return nil;
}

- (NSUInteger)maximumSize
{
	NSAssert1(NO, @"Implementation of %@ lacks maximumSize", self);
	
	return 0;
}

- (void)parseResponse:(NSData *)date
{
	NSAssert1(NO, @"Implementation of %@ lacks parseResponse:", self);	
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
	NSData *imageRepresentation;
	
	if (pngRepresentation.length > jpgRepresentation.length) {
		bestType = NSJPEGFileType;
		imageRepresentation = jpgRepresentation;
	} else {
		bestType = NSPNGFileType;
		imageRepresentation = pngRepresentation;
	}
	
	if (imageRepresentation.length > self.maximumSize) {
		imageRepresentation = [image representationWithFileType:bestType maximumFileSize:self.maximumSize];
	}
	
	if (!imageRepresentation) {
		[uploader errorWithMessage:AILocalizedString(@"Unable to upload", nil) forChat:chat];
		return;
	}
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image\"\r\n", self.fieldName] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", (bestType == NSJPEGFileType) ? @"image/jpeg" : @"image/png"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageRepresentation];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
	for (NSDictionary *field in [self additionalFields]) {
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n", MULTIPART_FORM_BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name= \"%@\"\r\n\r\n", [field objectForKey:@"name"]] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"%@", [field objectForKey:@"value"]] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSString stringWithFormat:@"multipart/form-data; boundary=%@", MULTIPART_FORM_BOUNDARY], @"Content-type", nil];
	
	dataUploader = [[AIProgressDataUploader dataUploaderWithData:body
															 URL:[NSURL URLWithString:self.uploadURL]
														 headers:headers
														delegate:self
														 context:nil] retain];
	
	[dataUploader upload];
}

- (void)cancel
{
	[dataUploader cancel];
}

@end
