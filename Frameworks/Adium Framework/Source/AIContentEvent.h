//
//  AIContentEvent.h
//  Adium
//
//  Created by Evan Schoenberg on 7/8/06.
//

#import <Adium/AIContentStatus.h>

#define CONTENT_EVENT_TYPE		@"Event"		//Type ID for this content

@interface AIContentEvent : AIContentStatus {

}

- (NSString *)eventType;

@end
