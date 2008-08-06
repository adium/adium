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

#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIHTMLDecoder.h>

@implementation AIContentObject

//
- (id)initWithChat:(AIChat *)inChat
			source:(AIListObject *)inSource
	   destination:(AIListObject *)inDest
			  date:(NSDate*)inDate
{
	return [self initWithChat:inChat source:inSource destination:inDest date:inDate message:nil];
}
- (id)initWithChat:(AIChat *)inChat
			source:(AIListObject *)inSource
	   destination:(AIListObject *)inDest
			  date:(NSDate*)inDate
		   message:(NSAttributedString *)inMessage
{
    if ((self = [super init]))
	{
		//Default Behavior
		filterContent = YES;
		trackContent = YES;
		displayContent = YES;
		displayContentImmediately = YES;
		sendContent = YES;
		postProcessContent = YES;
	
		//Store source, dest, chat, ...
		source = [inSource retain];
		destination = [inDest retain];
		message = [inMessage retain];
		date = [(inDate ? inDate : [NSDate date]) retain];
		
		chat = [inChat retain];
		outgoing = ([source isKindOfClass:[AIAccount class]]);
		userInfo = nil;
	}
    
    return self;
}

- (void)dealloc
{
    [source release]; source = nil;
    [destination release]; destination = nil;
	[date release]; date = nil;
	[message release]; message = nil;
	[chat release]; chat = nil;
	[userInfo release]; userInfo = nil;
	if(customDisplayClasses)
		[customDisplayClasses release];
	customDisplayClasses = nil;

    [super dealloc];
}

//Content Identifier
- (NSString *)type
{
    return @"";
}

- (void) addDisplayClass:(NSString *)className
{
	if(!customDisplayClasses)
		customDisplayClasses = [[NSMutableArray alloc] init];
	
	[customDisplayClasses addObject:className];
}

- (NSMutableArray *)displayClasses
{
	NSMutableArray *classes = customDisplayClasses ? customDisplayClasses : [NSMutableArray array];
	[classes addObject:(outgoing) ? @"outgoing" : @"incoming"];
	return classes;
}

- (id)userInfo
{
	return userInfo;
}

- (void)setUserInfo:(id)inUserInfo
{
	if (userInfo != inUserInfo) {
		[userInfo release];
		userInfo = [inUserInfo retain];
	}
}

//Comparing ------------------------------------------------------------------------------------------------------------
#pragma mark Comparing
//Content is similar if it's from the same source, of the same type, and sent within 5 minutes.
- (BOOL)isSimilarToContent:(AIContentObject *)inContent
{
	if (source == [inContent source] && [[self type] compare:[inContent type]] == NSOrderedSame) {
		NSTimeInterval	timeInterval = [date timeIntervalSinceDate:[inContent date]];
		
		return ((timeInterval > -300) && (timeInterval < 300));
	}
	
	return NO;
}

//Content is from the same day. If passed nil, content is from the current day.
- (BOOL)isFromSameDayAsContent:(AIContentObject *)inContent
{
	NSCalendarDate *ourDate = [[self date] dateWithCalendarFormat:nil timeZone:nil];
	NSCalendarDate *inDate = [(inContent ? [inContent date] : [NSDate date]) dateWithCalendarFormat:nil timeZone:nil];
	
	return [ourDate dayOfCommonEra] == [inDate dayOfCommonEra];
}

//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content
//Message Source and destination
- (AIListObject *)source
{
    return source;
}
- (AIListObject *)destination
{
    return destination;
}

//Date and time of this message
- (NSDate *)date
{
    return date;
}

//Is this content incoming or outgoing?
- (BOOL)isOutgoing
{
    return outgoing;
}

//Chat containing this content
- (void)setChat:(AIChat *)inChat
{
    chat = inChat;
}
- (AIChat *)chat
{
    return chat;
}

//Attributed Message
- (void)setMessage:(NSAttributedString *)inMessage
{
	if (message != inMessage) {
		[message release];
		message = [inMessage retain];
	}
}
- (NSAttributedString *)message
{
	return message;
}

//HTML string message
- (void)setMessageHTML:(NSString *)inMessageString
{
	[message release];
	message = [[AIHTMLDecoder decodeHTML:inMessageString] retain];
}
- (NSString *)messageHTML
{
	return [AIHTMLDecoder encodeHTML:message encodeFullString:YES];
}

/*!
 * @brief Set a string for this message using the default formatting attributes
 */
- (void)setMessageString:(NSString *)inMessageString
{
	[message release];
	message = [[NSAttributedString alloc] initWithString:inMessageString
											  attributes:[[adium contentController] defaultFormattingAttributes]];
	
}

/*!
 * @brief Retrieve the message string as plaintext.
 *
 * This existed for AppleScript support of obtaining the message string in 1.1 and below.  I don't believe it worked -eds.
 * It will likely no longer be necessary with the GSoC 2007 Applescripting changes.  I've removed it from the public API
 * but left it here for now. -eds
 */
- (NSString *)messageString
{
	return [message string];
}


//Behavior -------------------------------------------------------------------------------------------------------------
#pragma mark Behavior
- (void)setFilterContent:(BOOL)inFilterContent
{
	filterContent = inFilterContent;
}
- (BOOL)filterContent
{
    return filterContent;
}

- (void)setTrackContent:(BOOL)inTrackContent
{
	trackContent = inTrackContent;
}
- (BOOL)trackContent
{
    return trackContent;
}

- (void)setDisplayContent:(BOOL)inDisplayContent
{
	displayContent = inDisplayContent;
}
- (BOOL)displayContent
{
    return displayContent;
}

- (void)setDisplayContentImmediately:(BOOL)inDisplayContentImmediately
{
	displayContentImmediately = inDisplayContentImmediately;
}
- (BOOL)displayContentImmediately
{
	return displayContentImmediately;
}

- (void)setSendContent:(BOOL)inSendContent{
	sendContent = inSendContent;
}
- (BOOL)sendContent{
	return sendContent;
}

- (void)setPostProcessContent:(BOOL)inPostProcessContent
{
	postProcessContent = inPostProcessContent;
}
- (BOOL)postProcessContent
{
	return postProcessContent;
}

#pragma mark Debug
- (NSString *)description
{
	return  [NSString stringWithFormat:@"{%@ :<Source=%@> <Destination=%@> <Message=%@>}",
		[super description],
		[self source],
		[self destination],
		[self message]];
}

@end
