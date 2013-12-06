/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

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
