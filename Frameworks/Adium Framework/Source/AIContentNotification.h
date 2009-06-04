//
//  AIContentNotification.h
//  Adium
//
//  Created by Evan Schoenberg on 9/24/07.
//

#import <Adium/AIContentEvent.h>

#define CONTENT_NOTIFICATION_TYPE		@"Notification"		//Type ID for this content

typedef enum {
	AIDefaultNotificationType = 0
} AINotificationType;

@interface AIContentNotification : AIContentEvent {
	AINotificationType notificationType;
}

/*!	@brief	Create and autorelease an AIContentNotification.
 *	@return	An autoreleased AIContentNotification.
 */
+ (id)notificationInChat:(AIChat *)inChat
			  withSource:(id)inSource
			 destination:(id)inDest
					date:(NSDate *)inDate
		notificationType:(AINotificationType)inNotificationType;

@property (readonly, nonatomic) AINotificationType notificationType;
@property (readonly, nonatomic) NSString *eventType;

@end
