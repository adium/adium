//
//  MGTwitterUsersParser.m
//  MGTwitterEngine
//
//  Created by Matt Gemmell on 19/02/2008.
//  Copyright 2008 Instinctive Code.
//

#import "MGTwitterUsersParser.h"


@implementation MGTwitterUsersParser


#pragma mark NSXMLParser delegate methods


- (void)parser:(NSXMLParser *)theParser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
    attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"Started element: %@ (%@)", elementName, attributeDict);
    [self setLastOpenedElement:elementName];
    
	if ([elementName isEqualToString:@"users_list"]) {
		supportsCursorPaging = YES;
		NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
		[parsedObjects addObject:newNode];
		currentNode = newNode;
	} else if ([elementName isEqualToString:@"users"]) {
		if (!supportsCursorPaging) {
			NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
			[parsedObjects addObject:newNode];
			currentNode = newNode;
		}
		// Create the users mutable array
		[currentNode setObject:[NSMutableArray arrayWithCapacity:0] forKey:elementName];
	} else if ([elementName isEqualToString:@"user"]) {
		// Add the user object into the users array
		NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
		
		// Accomodate different type of xml response
		NSMutableArray *users = [currentNode objectForKey:@"users"];
		
		if (users) {
			[users addObject:newNode];
		} else {
			[parsedObjects addObject:newNode];
		}

		currentNode = newNode;
	} else if ([elementName isEqualToString:@"status"]) {
		// Add an appropriate dictionary to current node.
		NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
		[currentNode setObject:newNode forKey:elementName];
		currentNode = newNode;
	} else if ([elementName isEqualToString:@"next_cursor"]) {
		// Add a new entry for next cursor object
		NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
		[parsedObjects addObject:newNode];
		currentNode = newNode;
		[currentNode setObject:[NSMutableString string] forKey:elementName];
	} else if ([elementName isEqualToString:@"previous_cursor"]) {
		// Add a new entry for previous cursor object
		NSMutableDictionary *newNode = [NSMutableDictionary dictionaryWithCapacity:0];
		[parsedObjects addObject:newNode];
		currentNode = newNode;
		[currentNode setObject:[NSMutableString string] forKey:elementName];
	} else if (currentNode) {
		// Create relevant name-value pair.
		[currentNode setObject:[NSMutableString string] forKey:elementName];
	}
}

- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)characters
{
	if (![lastOpenedElement isEqualToString:@"users"] && currentNode) {
		[[currentNode objectForKey:lastOpenedElement] appendString:characters];
	}
}

- (void)parser:(NSXMLParser *)theParser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	[super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	
	if ([elementName isEqualToString:@"status"]) {
		NSMutableArray *users = [[parsedObjects lastObject] objectForKey:@"users"];
		
		if (users) {
			currentNode = [users lastObject];
		} else {
			currentNode = [parsedObjects lastObject];
		}

		currentNode = [parsedObjects lastObject];
	} else if ([elementName isEqualToString:@"user"]) {
		[self addSource];
		
		NSMutableArray *users = [[parsedObjects lastObject] objectForKey:@"users"];
		
		if (users) {
			currentNode = [parsedObjects lastObject];
		} else {
			currentNode = nil;
		}

	}
}


@end
