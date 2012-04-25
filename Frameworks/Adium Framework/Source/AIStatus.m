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

#import <Adium/AIStatus.h>
#import <Adium/AIStatusIcons.h>

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>


@implementation AIStatus

/*!
 * @brief Create an autoreleased AIStatus
 *
 * @result New autoreleased AIStatus
 */
+ (AIStatus *)status
{
	AIStatus	*newStatus = [[self alloc] init];
	
	//Configure defaults as necessary
	[newStatus setAutoReplyIsStatusMessage:YES];

	return newStatus;
}

/*!
 * @brief Crate an AIStatus from a dictionary
 *
 * @param inDictionary A dictionary of keys to use as the new AIStatus's statusDict
 * @result AIStatus from inDictionary
 */
+ (AIStatus *)statusWithDictionary:(NSDictionary *)inDictionary
{
	AIStatus	*status = [self status];
	[status->statusDict addEntriesFromDictionary:inDictionary];

	return status; 
}

/*!
 * @brief Create an autoreleased AIStatus of a specified type
 *
 * The new AIStatus will have its statusType and statusName set appropriately.
 *
 * @result New autoreleased AIStatus
 */
+ (AIStatus *)statusOfType:(AIStatusType)inStatusType
{
	AIStatus	*status = [self status];
	[status setStatusType:inStatusType];
	[status setStatusName:[adium.statusController defaultStatusNameForType:inStatusType]];
	
	if (inStatusType == AIAwayStatusType) {
		[status setHasAutoReply:YES];
	}
	
	return status;
}

/*!
* @brief Returns an appropriate icon for this state
 *
 * This method will generate an appropriate status icon based on the state's content.
 *
 * @param iconType The AIStatusIconType to use
 * @result An <tt>NSImage</tt>
 */
- (NSImage *)iconOfType:(AIStatusIconType)iconType direction:(AIIconDirection)direction
{
	NSString		*statusName;
	AIStatusType	statusType;
	
	if ([self shouldForceInitialIdleTime]) {
		statusName = @"Idle";
		statusType = AIAwayStatusType;
	} else {
		statusName = self.statusName;
		statusType = self.statusType;
	}
	
	return [AIStatusIcons statusIconForStatusName:statusName
									   statusType:statusType
										 iconType:iconType
										direction:direction];
}


/*!
 * @brief The status message for this status
 *
 * @result An NSAttributedString status message, or nil if no status message or a 0-length status message is set
 */
- (NSAttributedString *)statusMessage
{
	NSAttributedString	*statusMessage;
	
	statusMessage = [statusDict objectForKey:STATUS_STATUS_MESSAGE];

	if (![statusMessage length]) statusMessage = nil;

	return statusMessage;
}

/*!
 * @brief Return the status message as a string
 */
- (NSString *)statusMessageString
{
	return [self.statusMessage string];
}

/*!
 * @brief Set the status message
 */
- (void)setStatusMessage:(NSAttributedString *)statusMessage
{
	if (statusMessage) {
		[statusDict setObject:statusMessage
					   forKey:STATUS_STATUS_MESSAGE];
	} else {
		[statusDict removeObjectForKey:STATUS_STATUS_MESSAGE];
	}
	
	filteredStatusMessage = nil;
}

/*!
 * @brief Set the status message as a string
 *
 * @param statusMessageString The status message as a string; HTML may be passed if desired
 */
- (void)setStatusMessageString:(NSString *)statusMessageString
{
	[self setStatusMessage:[AIHTMLDecoder decodeHTML:statusMessageString]];
}

- (void)setFilteredStatusMessage:(NSString *)inFilteredStatusMessage
{
	if (![filteredStatusMessage isEqualToString:inFilteredStatusMessage]) {
		filteredStatusMessage = inFilteredStatusMessage;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AIStatusFilteredStatusMessageChanged"
												  object:self];
	}
}

- (NSString *)statusMessageTooltipString
{
	return (filteredStatusMessage ? filteredStatusMessage : [self statusMessageString]);
}

/*!
 * @brief The auto reply to send when in this status
 *
 * @result An NSAttributedString auto reply, or nil if no auto reply should be sent
 */
- (NSAttributedString *)autoReply
{
	NSAttributedString	*autoReply = nil;

	if ([self hasAutoReply]) {
		autoReply = ([self autoReplyIsStatusMessage] ?
					 self.statusMessage :
					 [statusDict objectForKey:STATUS_AUTO_REPLY_MESSAGE]);
	}

	if (![autoReply length]) autoReply = nil;
	
	return autoReply;
}

/*!
 * @brief Autoreply as a string
 */
- (NSString *)autoReplyString
{
	return [[self autoReply] string];
}

/*!
 * @brief Set the autoReply
 */
- (void)setAutoReply:(NSAttributedString *)autoReply
{
	if (autoReply) {
		[statusDict setObject:autoReply
					   forKey:STATUS_AUTO_REPLY_MESSAGE];
	} else {
		[statusDict removeObjectForKey:STATUS_AUTO_REPLY_MESSAGE];
	}
}

/*!
 * @brief Set the autoreply as a string
 *
 * @param autoReplyString The autoreply as a string; HTML may be passed if desired
 */
- (void)setAutoReplyString:(NSString *)autoReplyString
{
	[self setAutoReply:[AIHTMLDecoder decodeHTML:autoReplyString]];
}

/*!
 * @brief Does this status state send an autoReeply?
 */
- (BOOL)hasAutoReply
{
	return [[statusDict objectForKey:STATUS_HAS_AUTO_REPLY] boolValue];
}

/*!
 * @brief Set if this status sends an autoReply
 */
- (void)setHasAutoReply:(BOOL)hasAutoReply
{
	[statusDict setObject:[NSNumber numberWithBool:hasAutoReply]
				   forKey:STATUS_HAS_AUTO_REPLY];
}

/*!
 * @brief Is the autoReply the same as the status message?
 */
- (BOOL)autoReplyIsStatusMessage
{
	return [[statusDict objectForKey:STATUS_AUTO_REPLY_IS_STATUS_MESSAGE] boolValue];
}

/*!
 * @brief Set if the autoReply is the same as the status message
 */
- (void)setAutoReplyIsStatusMessage:(BOOL)autoReplyIsStatusMessage
{
	[statusDict setObject:[NSNumber numberWithBool:autoReplyIsStatusMessage]
				   forKey:STATUS_AUTO_REPLY_IS_STATUS_MESSAGE];
}

/*!
* @brief Returns an appropriate title
 *
 * Not all states provide a title.  This method will generate an appropriate title based on the states' content.
 * If the state has a specified title, it will always be used.
 */ 
- (NSString *)title
{
	NSAttributedString	*statusMessage, *autoReply;
	NSString			*title = nil;
	AIStatusType		statusType;
	NSRange				linebreakRange;

	//Start off using super's implementation, looking for a directly assigned title
	title = [super title];
	
	/* Now we start falling through looking to generate a title if we don't have one yet */
	
	//If the state has a status message, use it.
	if (!title && 
	   (statusMessage = self.statusMessage) &&
	   ([statusMessage length])) {
		title = [statusMessage string];
	}

	//If the state has an autoreply (but no status message), use it.
	if (!title &&
	   (autoReply = [self autoReply]) &&
	   ([autoReply length])) {
		title = [autoReply string];
	}
	
	/* If the state is not an available state, or it's an available state with a non-default statusName,
 	 * use the description of the state itself. */
	statusType = self.statusType;
	if (!title &&
	   ((self.statusType != AIAvailableStatusType) || ((self.statusName != nil) &&
														 ![self.statusName isEqualToString:STATUS_NAME_AVAILABLE]))) {
		title = [adium.statusController descriptionForStateOfStatus:self];
	}

	//If the state is simply idle, use the string "Idle"
	if (!title && [self shouldForceInitialIdleTime]) {
		title = AILocalizedString(@"Idle", nil);
	}

	if (!title && (statusType == AIOfflineStatusType)) {
		title = [adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_OFFLINE];
	}

	//If the state is none of the above, use the string "Available"
	if (!title) title = [adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE];
	
	//Strip newlines and whitespace from the beginning and the end
	title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	//Only use the first line of a multi-line title
	linebreakRange = [title lineRangeForRange:NSMakeRange(0, 0)];
	//check to make sure that there actually is a linebreak to account for
	//	by comparing the linebreak range against the whole string's range.
	if ( !NSEqualRanges(linebreakRange, NSMakeRange(0, [title length])) ) {  
		title = [title substringWithRange:linebreakRange];  
	}
	
	return title;
}

/*!
 * @brief The specific status name
 *
 * This is a name which was added as available by one or more installed AIService objects. Accounts should
 * use this name if possible, handle the other Adium default statusName values if not, and then, if all else fails
 * use the return of statusType to know the general type of status.
 */
- (NSString *)statusName
{
	return [statusDict objectForKey:STATUS_STATUS_NAME];
}

/*!
 * @brief Set the specific status name
 *
 * Set the name which will be used by accounts to know which specific state to apply when this status is made active.
 * This name is for internal use only and should not be localized.
 */
- (void)setStatusName:(NSString *)statusName
{
	if (statusName) {
		[statusDict setObject:statusName
					   forKey:STATUS_STATUS_NAME];
	} else {
		[statusDict removeObjectForKey:STATUS_STATUS_NAME];
	}
}

/*!
 * @brief Should this state force an account to be idle?
 *
 * @result YES if the account will be forced to be idle
 */
- (BOOL)shouldForceInitialIdleTime
{
	return [[statusDict objectForKey:STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME] boolValue];	
}

/*!
 * @brief Set if this state should force an account to be idle?
 *
 * @param shouldForceInitialIdleTime YES if the account will be forced to be idle
 */
- (void)setShouldForceInitialIdleTime:(BOOL)shouldForceInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithBool:shouldForceInitialIdleTime]
				   forKey:STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME];
}

/*!
 * @brief The time the account should be set to have been idle when this state is set
 *
 * @result Number of seconds idle 
 */
- (double)forcedInitialIdleTime
{
	return [[statusDict objectForKey:STATUS_FORCED_INITIAL_IDLE_TIME] doubleValue];
}

/*!
 * @brief The time the account should be set to have been idle when this state is set
 *
 * @param forcedInitialIdleTime Number of seconds idle 
 */
- (void)setForcedInitialIdleTime:(double)forcedInitialIdleTime
{
	[statusDict setObject:[NSNumber numberWithDouble:forcedInitialIdleTime]
				   forKey:STATUS_FORCED_INITIAL_IDLE_TIME];
}

/*!
 * @brief Is this status state mutable?
 *
 * If this method indicates the status state is not mutable,  it should not be presented to the user for editing. 
 * This should be the condition for (and only for) basic saved states built in to Adium.
 *
 * @result AIStateMutabilityType value
 */
- (AIStatusMutabilityType)mutabilityType
{
	return [[statusDict objectForKey:STATUS_MUTABILITY_TYPE] intValue];
}

/*!
 * @brief Set the mutability type of this status. The default is AIEditableState
 */
- (void)setMutabilityType:(AIStatusMutabilityType)mutabilityType
{
	[statusDict setObject:[NSNumber numberWithInt:mutabilityType]
				   forKey:STATUS_MUTABILITY_TYPE];
}

- (BOOL)mutesSound
{
	return [[statusDict objectForKey:STATUS_MUTE_SOUNDS] boolValue];
}

- (void)setMutesSound:(BOOL)mutes
{
	[statusDict setObject:[NSNumber numberWithBool:mutes] forKey:STATUS_MUTE_SOUNDS];
}

- (BOOL)silencesGrowl
{
	return [[statusDict objectForKey:STATUS_SILENCE_GROWL] boolValue];
}

- (void)setSilencesGrowl:(BOOL)mutes
{
	[statusDict setObject:[NSNumber numberWithBool:mutes] forKey:STATUS_SILENCE_GROWL];
}

- (void)setSpecialStatusType:(AISpecialStatusType)inSpecialStatusType
{
	[statusDict setObject:[NSNumber numberWithInt:inSpecialStatusType] forKey:STATUS_SPECIAL_TYPE];
}

- (AISpecialStatusType)specialStatusType
{
	return [[statusDict objectForKey:STATUS_SPECIAL_TYPE] intValue];
}

#pragma mark Applescript
/**
 * @brief Returns the message of this status as an NSTextStorage
 */
- (NSTextStorage *)scriptingMessage
{
	return [[NSTextStorage alloc] initWithAttributedString:self.statusMessage];
}
- (void)setScriptingMessage:(NSTextStorage *)newMessage
{
	NSLog(@"setScriptingMessage: %@", newMessage);
	if ([self mutabilityType] == AIEditableStatusState || [self mutabilityType] == AITemporaryEditableStatusState) {
		if ([newMessage isKindOfClass:[NSAttributedString class]])
			[self setStatusMessage:newMessage];
		else if ([newMessage isKindOfClass:[NSString class]])
			[self setStatusMessageString:(NSString *)newMessage];
		else {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Status message must be a string or an attributed string."];
			return;
		}
		[adium.statusController savedStatusesChanged];
		AILogWithSignature(@"Applying %@ to %@", self, [adium.accountController accountsWithCurrentStatus:self]);
		[adium.statusController applyState:self toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	} else {
		AIStatus *newStatus = [self mutableCopy];
		[newStatus setMutabilityType:AITemporaryEditableStatusState];
		if ([newMessage isKindOfClass:[NSAttributedString class]])
			[newStatus setStatusMessage:newMessage];
		else if ([newMessage isKindOfClass:[NSString class]])
			[newStatus setStatusMessageString:(NSString *)newMessage];
		else {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Status message must be a string or an attributed string."];
			return;
		}
		[adium.statusController savedStatusesChanged];		
		[adium.statusController applyState:newStatus toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	}
}
- (NSTextStorage *)scriptingAutoreply
{
	return [[NSTextStorage alloc] initWithAttributedString:[self autoReply]];
}
- (void)setScriptingAutoreply:(NSTextStorage *)newAutoreply
{
	if ([self mutabilityType] == AIEditableStatusState || [self mutabilityType] == AITemporaryEditableStatusState) {
		if ([newAutoreply isKindOfClass:[NSAttributedString class]])
			[self setAutoReply:newAutoreply];
		else if ([newAutoreply isKindOfClass:[NSString class]])
			[self setAutoReplyString:(NSString *)newAutoreply];
		else {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Autoreply message must be a string or an attributed string."];
			return;
		}
		[adium.statusController savedStatusesChanged];
		[adium.statusController applyState:self toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	} else {
		AIStatus *newStatus = [self mutableCopy];
		[newStatus setMutabilityType:AITemporaryEditableStatusState];
		if ([newAutoreply isKindOfClass:[NSAttributedString class]])
			[newStatus setAutoReply:newAutoreply];
		else if ([newAutoreply isKindOfClass:[NSString class]])
			[newStatus setAutoReplyString:(NSString *)newAutoreply];
		else {
			[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
			[[NSScriptCommand currentCommand] setScriptErrorString:@"Autoreply message must be a string or an attributed string."];
			return;
		}
		[adium.statusController savedStatusesChanged];		
		[adium.statusController applyState:newStatus toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	}
}

- (void)setStatusTypeApplescript:(AIStatusTypeApplescript)statusTypeApplescript
{
	AIStatusType			statusType;
	
	switch (statusTypeApplescript) {
		case AIAvailableStatusTypeAS:
			statusType = AIAvailableStatusType;
			break;
		case AIAwayStatusTypeAS:
			statusType = AIAwayStatusType;
			break;
		case AIInvisibleStatusTypeAS:
			statusType = AIInvisibleStatusType;
			break;
		case AIOfflineStatusTypeAS:
		default:
			statusType = AIOfflineStatusType;
			break;
	}
	if ([self mutabilityType] == AIEditableStatusState || [self mutabilityType] == AITemporaryEditableStatusState) {
		[self setStatusType:statusType];
		[adium.statusController savedStatusesChanged];
		[adium.statusController applyState:self toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	} else {
		AIStatus *newStatus = [self mutableCopy];
		[newStatus setMutabilityType:AITemporaryEditableStatusState];
		[newStatus setStatusType:statusType];
		[newStatus setStatusName:[adium.statusController defaultStatusNameForType:statusType]];
		[adium.statusController savedStatusesChanged];		
		[adium.statusController applyState:newStatus toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	}
}

/**
 * @brief Returns the title of this status.
 */
- (NSString *)scriptingTitle
{
	return [self title];
}
/**
 * @brief Sets the title of this status to the given value.
 *
 * This may copy self, if self is not editable.
 */
- (void)setScriptingTitle:(NSString *)newTitle
{
	if ([self mutabilityType] == AIEditableStatusState || [self mutabilityType] == AITemporaryEditableStatusState) {
		[self setTitle:newTitle];
		[adium.statusController savedStatusesChanged];
		[adium.statusController applyState:self toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	} else {
		AIStatus *newStatus = [self mutableCopy];
		[newStatus setMutabilityType:AITemporaryEditableStatusState];
		[newStatus setTitle:newTitle];
		[adium.statusController savedStatusesChanged];		
		[adium.statusController applyState:newStatus toAccounts:[adium.accountController accountsWithCurrentStatus:self]];
	}
}

- (BOOL)scriptingMutabilityType
{
	return [self mutabilityType] != AITemporaryEditableStatusState;
}

@end
