//
//  AIImageShackImageUploader.m
//  Adium
//
//  Created by Zachary West on 2009-07-01.
//  Copyright 2009  . All rights reserved.
//

#import "AIImageShackImageUploader.h"
#import <AIUtilities/AIStringAdditions.h>

@implementation AIImageShackImageUploader
+ (NSString *)serviceName
{
	return @"ImageShack";
}

- (NSString *)uploadURL
{
	return @"http://www.imageshack.us/upload_api.php?key=5FGHPUWX06560cfca5af85e920262ac699251d4d";
}

- (NSString *)fieldName
{
	return @"fileupload";
}

- (NSUInteger)maximumSize
{
	return 2500000;
}

- (void)dealloc
{
	[resultData release]; resultData = nil;
	[links release]; links = nil;
	[responseParser release]; responseParser = nil;
	
	[super dealloc];
}

#pragma mark Response parsing
- (void)parseResponse:(NSData *)data
{
	links = [[NSMutableDictionary alloc] init];
	resultData = [data copy];
	
	AILogWithSignature(@"%@", [NSString stringWithData:data encoding:NSUTF8StringEncoding]);
	
	responseParser = [[NSXMLParser alloc] initWithData:resultData];
	[responseParser setDelegate:self];
	[responseParser parse];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{

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
	if ([elementName isEqualToString:@"links"]) {
		currentElement = links;
	}
	
	currentElementName = elementName;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"links"]) {
		currentElement = nil;
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (![currentElementName isEqualToString:@"links"] && ![currentElement objectForKey:currentElementName]) {
		[currentElement setObject:[NSMutableString string] forKey:currentElementName];
	}
	
	[[currentElement objectForKey:currentElementName] appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	if ([links objectForKey:@"error"]) {
		NSString *error = [[links objectForKey:@"error"] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		[uploader errorWithMessage:error forChat:chat];	
	} else if ([links objectForKey:@"yfrog_link"]) {
		NSString *url = [[links objectForKey:@"yfrog_link"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		[uploader uploadedURL:url forChat:chat];	
	} else {
		[uploader errorWithMessage:AILocalizedString(@"Unable to upload", nil) forChat:chat];
	}
}

@end
