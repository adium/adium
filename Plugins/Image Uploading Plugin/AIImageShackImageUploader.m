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
