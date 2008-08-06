//
//  Chat.h
//  Logtastic
//
//  Created by Jan Van Tol on Sat Dec 14 2002.
//  Copyright (c) 2002 Spiny Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Buddy.h"

@class Buddy;

@interface Chat : NSObject {
	NSArray		*chatContents;
	NSArray 	*instantMessages;
		
	NSString 	*myPath;
    Buddy 		*myBuddy;
    NSDate 		*creationDate;
}

- (id)initWithBuddy:(Buddy *)buddy path:(NSString *)path;
- (void)setCreationDate:(NSDate *)date;
- (NSDate *)creationDate;
- (Buddy *)buddy;
- (NSString *)path;
- (NSString *)description;
- (void)open;
- (void) loadContents;

//Sorting and searching
- (NSComparisonResult)compareByDate:(Chat *)otherChat;
- (BOOL)logContainsString:(NSString *)string;
- (NSAttributedString *) getFormattedContents;
- (NSAttributedString *) getFormattedContentsWithSearchTermsHilighted:(NSString *) searchTermsStr firstFoundIndex:(NSInteger *) foundIndex;
- (NSString *) exportableContents;

@end
