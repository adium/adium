//
//  AIPreviewChat.m
//  Adium
//
//  Created by Evan Schoenberg on 9/21/06.
//

#import "AIPreviewChat.h"

@implementation AIPreviewChat

+ (AIPreviewChat *)previewChat
{
	return [self chatForAccount:nil];
}

- (void)setDateOpened:(NSDate *)inDate
{
	if (dateOpened != inDate) {
		[dateOpened release]; 
		dateOpened = [inDate retain];
    }
}

@end
