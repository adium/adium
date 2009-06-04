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

@property (readonly, nonatomic) NSString *eventType;

+ (id)eventInChat:(AIChat *)inChat
	   withSource:(id)inSource
	  destination:(id)inDest
			 date:(NSDate *)inDate
		  message:(NSAttributedString *)inMessage
		 withType:(NSString *)inStatus;

@end
