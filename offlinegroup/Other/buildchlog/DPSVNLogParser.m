//
//  DPSVNLogParser.m
//  buildchlog
//
//  Created by Ofri Wolfus on 09/07/07.
//  Copyright 2007 Ofri Wolfus. All rights reserved.
//

#import "DPSVNLogParser.h"


enum {
	DPUselessElement = -1,
	DPAuthorElement = 1,
	DPDateElement,
	DPCommitMessageElement
};


@implementation DPSVNLogParser

- (id)initWithData:(NSData *)data {
	if ((self = [super init])) {
		xmlParser = [[NSXMLParser alloc] initWithData:data];
		[xmlParser setDelegate:self];
		changelog = [[NSMutableDictionary alloc] init];
		delegate = nil;
	}
	
	return self;
}

- (void)dealloc {
	[changelog release]; changelog = nil;
	[xmlParser release]; xmlParser = nil;
	[super dealloc];
}

- (id)delegate {
	return delegate;
}

- (void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}

- (void)parse {
	if (delegate && [delegate respondsToSelector:@selector(parserWillBeginParsing:)])
		[delegate parserWillBeginParsing:self];
	
	[xmlParser parse];
}

- (void)parser:(NSXMLParser *)parser	didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI	  qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict
{
	currentElement = DPUselessElement;
	
	if ([elementName isEqualToString:@"logentry"]) {
		autoreleasePool = [[NSAutoreleasePool alloc] init];
		revision = [[attributeDict objectForKey:@"revision"] intValue];
	} else if ([elementName isEqualToString:@"msg"]) {
		commitMsg = [[NSMutableString alloc] init];
		currentElement = DPCommitMessageElement;
	} else if ([elementName isEqualToString:@"author"]) {
		currentElement = DPAuthorElement;
	} else if ([elementName isEqualToString:@"date"]) {
		currentElement = DPDateElement;
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	switch (currentElement) {
		case DPCommitMessageElement:
			[commitMsg appendString:string];
			break;
		
		case DPAuthorElement:
			// Not really "the right thing" but whatever
			author = [string copy];
			break;
			
		case DPDateElement:
			// svn log outputs something i'm not sure NSDate can chew.
			// I'm leaving this for now.
			break;
			
		default:
			break;
	}
}

- (void)parseCommitMessage {
	NSString *category = @"General";
	NSMutableArray *changes;
	NSString *msgStr = commitMsg;
	NSRange range = [commitMsg rangeOfString:@"changelog:"
									 options:NSCaseInsensitiveSearch];
	NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	while (range.location != NSNotFound) {
		int index = 0;
		unsigned int len = NSMaxRange(range);
		
		NSString *msg = [msgStr substringFromIndex:NSMaxRange(range)];
		msg = [msg stringByTrimmingCharactersInSet:whitespace];
		
		// Prepare the next changelog blog
		range = [msg rangeOfString:@"changelog:"
						   options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound) {
			len = range.location;
			msgStr = [msg substringFromIndex:range.location];
			range = NSMakeRange(0, 10 /* strlen(changelog:) */);
		} else
			len = [msg length];
		
		if (len == 0)
			return;
		
		if ([msg characterAtIndex:0] == '{') {
			
			// Find the closing '}'. I know we can use fancy stuff like NSScanner
			// but this is the easiest and probably also the fastest.
			for (index = 1; index < len && [msg characterAtIndex:index] != '}'; ++index);
			
			// If we have a category, get it as a string
			if (index < len) {
				category = [msg substringWithRange:NSMakeRange(1, index - 1)];
				index++;
			} else {
				// Otherwise we set the index back to the begining ang stick
				// with the general category.
				index = 0;
			}
		}
		
		// Get the changes array for our category
		changes = [changelog objectForKey:category];
		
		// Create it if needed
		if (!changes) {
			changes = [[NSMutableArray alloc] initWithCapacity:1];
			[changelog setObject:changes forKey:category];
			[changes release];
		}
		
		// Finally, add the change we're handling now
		if (index + 1 < len)
			[changes addObject:[[msg substringWithRange:NSMakeRange(index, len - index)] stringByTrimmingCharactersInSet:whitespace]];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if ([elementName isEqualToString:@"logentry"]) {
		[self parseCommitMessage];
		[commitMsg release]; commitMsg = nil;
		[author release]; author = nil;
		[date release]; date = nil;
	}
	
	currentElement = DPUselessElement;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	if (delegate && [delegate respondsToSelector:@selector(parser:parsedChangelog:)]) {
		[delegate parser:self parsedChangelog:changelog];
		[autoreleasePool release]; autoreleasePool = nil;
	}
}

@end
