//
//  ESPurpleAIMAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 2/23/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESPurpleAIMAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>

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

- (void)dealloc
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	
	[super dealloc];
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
	NSString	*formattedUID;
	
	//Set our capitilization properly if necessary
	formattedUID = self.formattedUID;
	
	if (![[formattedUID lowercaseString] isEqualToString:formattedUID]) {
		
		//Remove trailing and leading whitespace
		formattedUID = [formattedUID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		[[self purpleAdapter] performSelector:@selector(OSCARSetFormatTo:onAccount:)
								withObject:formattedUID
								withObject:self
								afterDelay:5.0];
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
	
	switch ([event intValue]) {
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

#pragma mark Status
/*!
* @brief Encode an attributed string for a status type
 *
 * Away messages are HTML encoded.  Available messages are plaintext.
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forStatusState:(AIStatus *)statusState
{
	if (statusState && ([statusState statusType] == AIAvailableStatusType)) {
		NSString	*messageString = [[inAttributedString attributedStringByConvertingLinksToStrings] string];
		return [messageString stringWithEllipsisByTruncatingToLength:MAX_AVAILABLE_MESSAGE_LENGTH];
	} else {
		return [super encodedAttributedString:inAttributedString forStatusState:statusState];
	}
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

- (void)addUser:(NSString *)contactName toChat:(AIChat *)chat newArrival:(NSNumber *)newArrival
{
	AIListContact *listContact;
	
	if ((chat) &&
		(listContact = [self contactWithUID:contactName])) {
		
		if (!namesAreCaseSensitive) {
			[listContact setValue:contactName forProperty:@"FormattedUID" notify:NotifyNow];
		}
		
		/* Purple incorrectly flags group chat participants as being on a mobile device... we're just going
		 * to assume that a contact in a group chat is by definition not on their cell phone. This assumption
		 * could become wrong in the future... we can deal with it more properly at that time. :P -eds
		 */	
		if ([listContact isMobile]) {
			[listContact setIsMobile:NO notify:NotifyLater];
			
			[listContact setValue:nil
								  forProperty:@"Client"
								  notify:NotifyLater];
			
			[listContact notifyOfChangedPropertiesSilently:NO];
		}
		
		[chat addParticipatingListObject:listContact notify:(newArrival && [newArrival boolValue])];
	}
}


@end
