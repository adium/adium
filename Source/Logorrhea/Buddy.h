//
//  Buddy.h
//  Logtastic
//
//  Created by Jan Van Tol on Sat Dec 14 2002.
//  Copyright (c) 2002 Spiny Software. All rights reserved.
//

#import "Chat.h"

@class Chat;

@interface Buddy : NSObject {
    NSString *myName;
    NSMutableArray *chats;
}

- (id)initWithName:(NSString *)name;
- (NSUInteger)numberOfChats;
- (Chat *)chatAtIndex:(NSInteger)index;
- (NSMutableArray *)chatsWithString:(NSString *)string;
- (id) addChatFile:(NSString *)pathToLog;
- (void) doSort;
- (NSComparisonResult)caseInsensitiveCompare:(id)anObject;
- (void) deleteChat:(Chat *) c;

@end
