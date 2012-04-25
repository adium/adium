/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContentNotification.h"
#import <Adium/AIContentEvent.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIAccount.h>

@interface AIContentNotification ()
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
	return [[self alloc] initWithChat:inChat
								source:inSource
						   destination:inDest
								  date:inDate
					  notificationType:inNotificationType];	
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
							message:[NSAttributedString stringWithString:defaultMessage]
						   withType:@"notification"])) {
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
	return self.type;
}

@synthesize notificationType;
@end
