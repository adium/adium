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

- (BOOL)supportsTopic
{
	return isGroupChat;
}

- (NSString *)topic
{
	return AILocalizedString(@"This is a sample topic for this chat. Enjoy!",nil);
}

- (void)setTopic:(NSString *)inTopic
{
	return;
}

- (NSString *)aliasForContact:(AIListObject *)contact
{
	return contact.displayName;
}

@end
