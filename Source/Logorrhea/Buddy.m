//
//  Buddy.m
//  Logtastic
//
//  Created by Jan Van Tol on Sat Dec 14 2002.
//  Copyright (c) 2002 Spiny Software. All rights reserved.
//

#import "Buddy.h"
#import "FileAttributes.h"

@implementation Buddy

- (id)initWithName:(NSString *)name
{
    self = [super init];
        
    //myName stores the buddies own name.
    myName = [name retain];
    //Inits chats, which is filled with Chat objects each representing a chat log.
    chats = [[NSMutableArray alloc] init];

	return self;
}

- (id) addChatFile:(NSString *)pathToLog
{		
	//Creates a new chat object, inits it with the log, and sets the date.
	Chat *chat = [[Chat alloc] initWithBuddy:self path:pathToLog];
	
	//Adds the chat to the array of chats for this buddy.
	[chats addObject: chat];
    
	[chat release];
	
    return self;
}

- (void) deleteChat:(Chat *) c
{
	NSInteger idx = [chats indexOfObjectIdenticalTo:c];
	if (idx != -1)
		[chats removeObjectAtIndex:idx];
}

- (void) doSort
{
    //Sort chats by date.
    [chats sortUsingSelector:@selector(compareByDate:)];
}

- (NSUInteger)numberOfChats
{
    return [chats count];
}

- (Chat *)chatAtIndex:(NSInteger)idx
{
    return [chats objectAtIndex:idx];
}

//Asks each Chat if it contains string, if so, add that chat to chatsWithString.
- (NSMutableArray *)chatsWithString:(NSString *)string {
    
    NSMutableArray *chatsWithString = [[NSMutableArray alloc] init];
    for (NSUInteger i=0; i < [chats count]; i++) {
        if ([[chats objectAtIndex: i] logContainsString: string]) {
            [chatsWithString addObject: [chats objectAtIndex: i]];
        }
    }
    
    return [chatsWithString autorelease];
}

- (NSString *)description {
    return myName;
}

- (NSUInteger)hash
{
	NSInteger hash = [myName hash];
	
	return hash;
}

- (BOOL)isEqual:(id)anObject
{
	return [myName isEqual:[anObject description]];
}

- (NSComparisonResult)caseInsensitiveCompare:(id)anObject
{
	return [myName caseInsensitiveCompare:[anObject description]];
	
}

@end
