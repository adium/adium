//
//  AIImgurImageUploader.m
//  Adium
//

#import "AIImgurImageUploader.h"
#import <AIUtilities/AIStringAdditions.h>

@implementation AIImgurImageUploader
+ (NSString *)serviceName
{
	return @"Imgur";
}

- (NSString *)uploadURL
{
	return @"http://imgur.com/api/upload.xml";
}

- (NSString *)fieldName
{
	return @"image";
}

- (NSArray *)additionalFields
{
	return [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"key", @"name", @"c8f0b307b20aae0cbdb0b66b195eedf9", @"value", nil]];
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
	NSDictionary *rsp = [response objectForKey:@"rsp"];
	NSString *status = [rsp objectForKey:@"stat"];
	
	if ([status isCaseInsensitivelyEqualToString:@"fail"]) {
		[uploader errorWithMessage:[rsp valueForKeyPath:@"error_msg.value"] forChat:chat];
	} else if ([status isCaseInsensitivelyEqualToString:@"ok"]) {
		[uploader uploadedURL:[rsp valueForKeyPath:@"original_image.value"] forChat:chat];
	} else {
		[uploader errorWithMessage:AILocalizedString(@"Unable to upload", nil) forChat:chat];
	}
}

@end
