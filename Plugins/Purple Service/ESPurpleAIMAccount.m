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

#import "ESPurpleAIMAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <AIUtilities/AIStringAdditions.h>


#define MAX_AVAILABLE_MESSAGE_LENGTH	249

@interface ESPurpleAIMAccount ()
- (void)setFormattedUID;
@end

@implementation ESPurpleAIMAccount

#pragma mark Initialization and setup

- (const char *)protocolPlugin
{
    return "prpl-aim";
}

- (void)initAccount
{
	[super initAccount];

	arrayOfContactsForDelayedUpdates = nil;
	delayedSignonUpdateTimer = nil;
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_NOTES];
}

- (void)migrateSSL
{
	if ([self preferenceForKey:PREFERENCE_SSL_CONNECTION group:GROUP_ACCOUNT_STATUS]) {
		[self setPreference:PREFERENCE_ENCRYPTION_TYPE_REQUIRED
					 forKey:PREFERENCE_ENCRYPTION_TYPE
					  group:GROUP_ACCOUNT_STATUS];
	} else {
		[self setPreference:PREFERENCE_ENCRYPTION_TYPE_OPPORTUNISTIC
					 forKey:PREFERENCE_ENCRYPTION_TYPE
					  group:GROUP_ACCOUNT_STATUS];
	}
}

- (void)dealloc
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

#pragma mark Connectivity

/*!
* @brief We are connected.
 */
- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];
	
	[self setFormattedUID];
}

/*!
* @brief Set the spacing and capitilization of our formatted UID serverside
 */
- (void)setFormattedUID
{
	//Set our capitilization properly if necessary
	
	if (![formattedUID isCaseInsensitivelyEqualToString:formattedUID]) {
		
		//Remove trailing and leading whitespace
		formattedUID = [formattedUID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		double delayInSeconds = 5.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[[self purpleAdapter] OSCARSetFormatTo:formattedUID onAccount:self];
		});
	}
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* Remove various actions which are either duplicates of superior Adium actions (*grin*)
	 * or are just silly ("Confirm Account" for example). */
	if (strcmp(label, _("Set Available Message...")) == 0) {
		return nil;
	} else if (strcmp(label, _("Format Screen Name...")) == 0) {
		return nil;
	} else if (strcmp(label, _("Confirm Account")) == 0) {
		return nil;
	}

	return [super titleForAccountActionMenuLabel:label];
}

#pragma mark Contact updates
- (oneway void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	SEL updateSelector = nil;
	
	switch ([event integerValue]) {
		case PURPLE_BUDDY_INFO_UPDATED: {
			updateSelector = @selector(updateInfo:);
			break;
		}
		case PURPLE_BUDDY_DIRECTIM_CONNECTED: {
			updateSelector = @selector(directIMConnected:);
			break;
		}
		case PURPLE_BUDDY_DIRECTIM_DISCONNECTED:{
			updateSelector = @selector(directIMDisconnected:);
			break;
		}
	}
	
	if (updateSelector) {
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

#pragma mark Suported keys
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"AvailableMessage",
			@"Invisible",
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
}

#pragma mark Typing notifications

/*!
 * @brief Suppress typing notifications after send?
 *
 * AIM assumes that "typing stopped" is not explicitly stopped when the user sends.  This is particularly visible
 * in iChat. Returning YES here prevents messages sent to iChat from jumping up and down in ichat as the typing
 * notification is removed and then the incoming text is added.
 */
- (BOOL)suppressTypingNotificationChangesAfterSend
{
	return YES;
}

#pragma mark Group chat

- (void)addUser:(NSString *)contactName toChat:(AIGroupChat *)chat newArrival:(NSNumber *)newArrival
{
	AIListContact *listContact;
	
	if ((chat) &&
		(listContact = [self contactWithUID:contactName])) {
		
		if (!namesAreCaseSensitive) {
			[listContact setFormattedUID:contactName notify:NotifyNow];
		}
		
		/* Purple incorrectly flags group chat participants as being on a mobile device... we're just going
		 * to assume that a contact in a group chat is by definition not on their cell phone. This assumption
		 * could become wrong in the future... we can deal with it more properly at that time. :P -eds
		 */	
		if (listContact.isMobile) {
			[listContact setIsMobile:NO notify:NotifyLater];
			
			[listContact setValue:nil
								  forProperty:@"Client"
								  notify:NotifyLater];
			
			[listContact notifyOfChangedPropertiesSilently:NO];
		}
		
		[chat addParticipatingNick:contactName notify:(newArrival && [newArrival boolValue])];
		[chat setContact:listContact forNick:contactName];
	}
}


@end
