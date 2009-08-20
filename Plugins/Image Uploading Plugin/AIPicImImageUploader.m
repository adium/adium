//
//  AIPicImImageUploader.m
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#import "AIPicImImageUploader.h"
#import <AIUtilities/AIStringAdditions.h>

@implementation AIPicImImageUploader
+ (NSString *)serviceName
{
	return @"pic.im";
}

- (NSString *)uploadURL
{
	return @"http://api.tr.im/api/picim_url.xml?api_key=zghQN6sv5y0FkLPNlQAopm7qDQz6ItO33ENU21OBsy3dL1Kl";
}

- (NSString *)fieldName
{
	return @"media";
}

- (NSUInteger)maximumSize
{
	return 2500000;
}

- (void)dealloc
{
	[resultData release]; resultData = nil;
	[response release]; response = nil;
	[responseParser release]; responseParser = nil;
	
	[super dealloc];
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
