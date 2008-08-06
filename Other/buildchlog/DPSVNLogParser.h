//
//  DPSVNLogParser.h
//  buildchlog
//
//  Created by Ofri Wolfus on 09/07/07.
//  Copyright 2007 Ofri Wolfus. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DPSVNLogParser : NSObject {
	NSXMLParser *xmlParser;
	id delegate;
	
	unsigned int revision;
	NSString *author;
	NSDate *date;
	NSMutableString *commitMsg;
	int currentElement;
	NSAutoreleasePool *autoreleasePool;
	
	NSMutableDictionary *changelog;
}

- (id)initWithData:(NSData *)data;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void)parse;

@end

@interface NSObject (DPSVNLogParserDelegate)

- (void)parserWillBeginParsing:(DPSVNLogParser *)parser;
- (void)parser:(DPSVNLogParser *)parser parsedChangelog:(NSDictionary *)log;

@end
