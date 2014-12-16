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
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIChat.h>
#import <Adium/AIGroupChat.h>

@implementation AIContentMessage

+ (id)messageInChat:(AIChat *)inChat
		 withSource:(id)inSource
		destination:(id)inDest
			   date:(NSDate *)inDate
			message:(NSAttributedString *)inMessage
		  autoreply:(BOOL)inAutoReply
{
	return [[[self alloc] initWithChat:inChat
								source:inSource
							sourceNick:nil
						   destination:inDest
								  date:inDate
							   message:inMessage
							 autoreply:inAutoReply] autorelease];
}

//Create a content message
+ (id)messageInChat:(AIChat *)inChat
		 withSource:(id)inSource
		 sourceNick:(NSString *)inSourceNick
		destination:(id)inDest
			   date:(NSDate *)inDate
			message:(NSAttributedString *)inMessage
		  autoreply:(BOOL)inAutoReply
{
    return [[[self alloc] initWithChat:inChat
								source:inSource
							sourceNick:inSourceNick
						   destination:inDest
								  date:inDate
							   message:inMessage
							 autoreply:inAutoReply] autorelease];
}

//Content Identifier
- (NSString *)type
{
    return CONTENT_MESSAGE_TYPE;
}

//Init
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
		sourceNick:(NSString *)inSourceNick
	   destination:(id)inDest
			  date:(NSDate *)inDate
		   message:(NSAttributedString *)inMessage
		 autoreply:(BOOL)inAutoReply
{
	if ((self = [super initWithChat:inChat source:inSource sourceNick:inSourceNick destination:inDest date:inDate message:inMessage])) {
		isAutoreply = inAutoReply;
		encodedMessage = nil;
		encodedMessageAccountData = nil;
	}

	return self;
}

- (void)dealloc
{
	if (encodedMessage)
		[encodedMessage release];
	if (encodedMessageAccountData)
		[encodedMessageAccountData release];
	
	[super dealloc];
}

- (NSMutableArray *)displayClasses
{
	NSMutableArray *classes = [super displayClasses];
	[classes addObject:@"message"];
	if(isAutoreply) [classes addObject:@"autoreply"];
	if(self.chat.isGroupChat) {
		AIGroupChatFlags flags = [(AIGroupChat *)self.chat flagsForNick:self.sourceNick];
		if (flags & AIGroupChatOp)
			[classes addObject:@"op"];
		if (flags & AIGroupChatHalfOp)
			[classes addObject:@"half-op"];
		if (flags & AIGroupChatFounder)
			[classes addObject:@"roomfounder"];
		if (flags & AIGroupChatVoice)
			[classes addObject:@"voice"];
	}
	return classes;
}

- (NSString *)senderPrefix
{
    if (!self.chat.isGroupChat) return @"";
    
	AIGroupChatFlags flags = [(AIGroupChat *)self.chat flagsForNick:self.sourceNick];
	
	if ((flags & AIGroupChatFounder) == AIGroupChatFounder) {
		return @"~";
	}
	
	if ((flags & AIGroupChatOp) == AIGroupChatOp) {
		return @"@";
	}
	
	if ((flags & AIGroupChatHalfOp) == AIGroupChatHalfOp) {
		return @"%";
	}
	
	if ((flags & AIGroupChatVoice) == AIGroupChatVoice) {
		return @"+";
	}
	
	return @"";
}

//This message was automatically generated
@synthesize isAutoreply;

/*!
 * @brief The AIAccount-generated contents of the message as a simple string
 *
 * This will often be an HTML string. It is the form in which the account wishes to send data to the other side.
 * It may be an encrypted string.
 */
@synthesize encodedMessage;

/*!
 * @brief For AIAccount internal use: data associated with this message
 */
@synthesize encodedMessageAccountData;

@end
