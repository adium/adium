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

#import "AdiumTyping.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import "AIContentTyping.h"
#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>

#define OUR_TYPING_STATE						@"ourTypingState"
#define ENTERED_TEXT_TIMER						@"enteredTextTimer"

#define DELAY_BEFORE_PAUSING_TYPING		3.0		//Wait for 3 seconds of inactivity before pausing typing
#define DELAY_BEFORE_CLEARING_TYPING	2.0		//Wait 2 seconds before clearing the typing flag

@interface AdiumTyping ()
- (void)setTypingState:(AITypingState)typingState ofChat:(AIChat *)chat;
- (void)monitorTypingInChat:(AIChat *)chat;
- (void)stopMonitoringTypingInChat:(AIChat *)chat;
- (void)_clearUserTypingForChat:(AIChat *)chat;
- (void)_typingHasPausedInChat:(NSTimer *)inTimer;

- (void)didSendMessage:(NSNotification *)notification;
- (void)chatWillClose:(NSNotification *)notification;
@end

@implementation AdiumTyping

/*!
 * @brief Init
 */
 - (id)init
{
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(didSendMessage:)
										   name:Interface_DidSendEnteredMessage
										 object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(chatWillClose:)
										   name:Chat_WillClose
										 object:nil];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

/*!
 * @brief Update the typing status of a chat
 * 
 * @param hasEnteredText YES if there is text entered for the chat
 * @param chat AIChat where typing has occured
 */
- (void)userIsTypingContentForChat:(AIChat *)chat hasEnteredText:(BOOL)hasEnteredText
{
	//Cancel any existing delayed perform selectors waiting to clear our typing flag
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(_clearUserTypingForChat:)
											   object:chat];

	//To prevent "Flickering" of our typing state, we wait a short period of time before clearing our typing flag.
	//Setting our typing flag always happens immediately.
	if (hasEnteredText) {
		[self monitorTypingInChat:chat];
		[self setTypingState:AITyping ofChat:chat];
	} else {
		[self performSelector:@selector(_clearUserTypingForChat:)
				   withObject:chat
				   afterDelay:DELAY_BEFORE_CLEARING_TYPING];
	}
}

/*!
 * @brief Clear the typing state of a chat
 */
- (void)_clearUserTypingForChat:(AIChat *)chat
{
	[self stopMonitoringTypingInChat:chat];
	[self setTypingState:AINotTyping ofChat:chat];
}

/*!
 * @brief Clear typing after a message is sent
 */
- (void)didSendMessage:(NSNotification *)notification
{
	AIChat	*chat = [notification object];
	
	if (![chat.account suppressTypingNotificationChangesAfterSend]) {
		[self _clearUserTypingForChat:chat];
	} else {
		//Some protocols implicitly clear typing when a message is sent.  For these protocols we'll just update our
		//typing state locally.  There is no need to send out a typing notification and doing so may actually cause
		//undesirable behavior.
		[chat setValue:nil forProperty:OUR_TYPING_STATE notify:NotifyNever];	
	}
}

/*!
 * @brief Clear all typing information we've placed on a chat before it closes
 */
- (void)chatWillClose:(NSNotification *)notification
{
    AIChat	*chat = [notification object];
	
	[self setTypingState:AINotTyping ofChat:chat];
	[self stopMonitoringTypingInChat:chat];
}


//Typing State ---------------------------------------------------------------------------------------------------------
#pragma mark Typing State
/*!
 * @brief Send an AIContentTyping object for an AITypingState on a given chat
 *
 * The chat determines whether the notification should be sent or not, based on the account preference and, possibly,
 * the temporary suppression  property.
 */
- (void)setTypingState:(AITypingState)typingState ofChat:(AIChat *)chat
{
	if ([chat integerValueForProperty:OUR_TYPING_STATE] != typingState) {
		AIContentTyping	*contentObject;

		//Send typing content object (It will go directly to the account since typing content isn't tracked or filtered)
		contentObject = [AIContentTyping typingContentInChat:chat
												  withSource:chat.account
												 destination:nil
												 typingState:typingState];
		[adium.contentController sendContentObject:contentObject];
		
		//Remember the state
		[chat setValue:(typingState == AINotTyping ? nil : [NSNumber numberWithInteger:typingState])
					   forProperty:OUR_TYPING_STATE
					   notify:NotifyNever];
	}
}


//Typing "Time-Out" ----------------------------------------------------------------------------------------------------
#pragma mark Typing "Time-Out"
/*!
 * @brief Monitor a chat to detect pauses in our user's typing
 */
- (void)monitorTypingInChat:(AIChat *)chat
{
	NSTimer	*existingTimer = [chat valueForProperty:ENTERED_TEXT_TIMER];
	
	if (existingTimer) {
		//If a timer exists, it is cheaper to reset it rather than create a new one
		[existingTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:DELAY_BEFORE_PAUSING_TYPING]];
		
	} else {
		//If no timer exists, create one for the chat
		existingTimer = [NSTimer scheduledTimerWithTimeInterval:DELAY_BEFORE_PAUSING_TYPING
														 target:self
													   selector:@selector(_typingHasPausedInChat:)
													   userInfo:chat
														repeats:NO];
		[chat setValue:existingTimer forProperty:ENTERED_TEXT_TIMER notify:NotifyNever];
		
	}
}

/*!
 * @brief Stop monitoring typing in a chat
 */
- (void)stopMonitoringTypingInChat:(AIChat *)chat
{
	[[chat valueForProperty:ENTERED_TEXT_TIMER] invalidate];
	[chat setValue:nil forProperty:ENTERED_TEXT_TIMER notify:NotifyNever];
}

/*!
 * @brief Invoked when the user 
 */
- (void)_typingHasPausedInChat:(NSTimer *)inTimer
{
	AIChat	*chat = [inTimer userInfo];
	
	[self setTypingState:AIEnteredText ofChat:chat];
	[self stopMonitoringTypingInChat:chat];
}

@end
