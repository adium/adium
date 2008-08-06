//
//  AIContentEvent.m
//  Adium
//
//  Created by Evan Schoenberg on 7/8/06.
//

#import <Adium/AIContentEvent.h>
#import <AIUtilities/AITigerCompatibility.h>

@implementation AIContentEvent

//Content Identifier
- (NSString *)type
{
    return CONTENT_EVENT_TYPE;
}

- (NSMutableArray *)displayClasses
{
	NSMutableArray *classes = [super displayClasses];
	
	//Events are not really status changes...
	NSUInteger idx = [classes indexOfObject:@"status"];
	if(idx != NSNotFound)
		[classes removeObjectAtIndex:idx];
	
	[classes addObject:@"event"];
	return classes;
}

- (NSAttributedString *)loggedMessage
{
	return [self message];
}

- (NSString *)eventType
{
	return statusType;
}

@end
