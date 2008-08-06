//
//  AIContentNotification.m
//  Adium
//
//  Created by Evan Schoenberg on 9/24/07.
//

#import "AIContentNotification.h"
#import <Adium/AIAccount.h>

@interface AIContentNotification (PRIVATE)
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
  notificationType:(AINotificationType)inNotificationType;
@end

@implementation AIContentNotification

+ (id)notificationInChat:(AIChat *)inChat
			  withSource:(id)inSource
			 destination:(id)inDest
					date:(NSDate *)inDate
		notificationType:(AINotificationType)inNotificationType
{
	return [[[self alloc] initWithChat:inChat
								source:inSource
						   destination:inDest
								  date:inDate
					  notificationType:inNotificationType] autorelease];	
}

- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
  notificationType:(AINotificationType)inNotificationType
{
	NSString *defaultMessage;
	
	if ([inSource isKindOfClass:[AIAccount class]]) {
		defaultMessage = [NSString stringWithFormat:AILocalizedString(@"You requested %@'s attention", "Message displayed when you send a buzz/nudge/other notification. %@ will be the other person's name."),
						  [inDest displayName]];
	} else {
		defaultMessage = (inSource ? [NSString stringWithFormat:AILocalizedString(@"%@ wants your attention!", "Message displayed when a contact sends a buzz/nudge/other notification. %@ will be the other person's name."),
									  [inSource displayName]] :
						  AILocalizedString(@"Your attention is requested!", nil));
	}

	if ((self = [super initWithChat:inChat
							 source:inSource
						destination:inDest
							   date:inDate
							message:[[[NSAttributedString alloc] initWithString:defaultMessage
																	 attributes:nil] autorelease]
						  autoreply:NO])) {
		notificationType = inNotificationType;
	}
	
	return self;
}

//Content Identifier
- (NSString *)type
{
    return CONTENT_NOTIFICATION_TYPE;
}

- (NSString *)eventType
{
	return [self type];
}

- (AINotificationType)notificationType
{
	return notificationType;
}

- (NSMutableArray *)displayClasses
{
	NSMutableArray *classes = [super displayClasses];
	[classes addObject:@"notification"];
	return classes;
}

@end
