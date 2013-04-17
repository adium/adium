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

#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import "ESFileTransferMessagesPlugin.h"
#import <Adium/AIChat.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>

@interface ESFileTransferMessagesPlugin ()
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type;
- (void)handleFileTransferEvent:(NSNotification *)notification;
@end

/*!
 * @class ESFileTransferMessagesPlugin
 * @brief Component which handles sending file transfer status messages
 */
@implementation ESFileTransferMessagesPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//Install our observers
    [[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(handleFileTransferEvent:) 
									   name:FILE_TRANSFER_CANCELLED 
									 object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(handleFileTransferEvent:) 
									   name:FILE_TRANSFER_COMPLETE 
									 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(handleFileTransferEvent:) 
									   name:FILE_TRANSFER_WAITING_REMOTE 
									 object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(handleFileTransferEvent:) 
									   name:FILE_TRANSFER_BEGAN 
									 object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self 
								   selector:@selector(handleFileTransferEvent:) 
									   name:FILE_TRANSFER_FAILED 
									 object:nil];
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * @brief A file transfer event occurred
 */
- (void)handleFileTransferEvent:(NSNotification *)notification
{
	ESFileTransfer	*fileTransfer = (ESFileTransfer *)[notification userInfo];

	if ([fileTransfer.account accountDisplaysFileTransferMessages]) return;

	AIListContact	*listContact = [notification object];
	NSString		*notificationName = [notification name];
	NSString		*filename;

	if (!(filename = [[fileTransfer localFilename] lastPathComponent])) {
		filename = [[fileTransfer remoteFilename] lastPathComponent];
	}

	if (filename) {
		NSString		*message = nil;
		NSString		*type = nil;

		if ([notificationName isEqualToString:FILE_TRANSFER_CANCELLED]) {
			type = @"fileTransferAborted";
			message = [NSString stringWithFormat:AILocalizedString(@"%@ cancelled the transfer of %@",nil),listContact.formattedUID,filename];

		} else if ([notificationName isEqualToString:FILE_TRANSFER_FAILED]) {
			type = @"fileTransferAborted";
			message = [NSString stringWithFormat:AILocalizedString(@"The transfer of %@ failed",nil),filename];
		}else if ([notificationName isEqualToString:FILE_TRANSFER_COMPLETE]) {
			type = @"fileTransferCompleted";
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				message = [NSString stringWithFormat:AILocalizedString(@"Successfully received %@",nil),filename];
			} else {
				message = [NSString stringWithFormat:AILocalizedString(@"Successfully sent %@",nil),filename];			
			}
		} else if ([notificationName isEqualToString:FILE_TRANSFER_BEGAN]) {
			type = @"fileTransferStarted";
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				message = [NSString stringWithFormat:AILocalizedString(@"Began receiving %@",nil),filename];
			} else {
				message = [NSString stringWithFormat:AILocalizedString(@"Began sending %@",nil),filename];			
			}
		} else if ([notificationName isEqualToString:FILE_TRANSFER_WAITING_REMOTE]) {
			type = @"fileTransferWaitingRemote";
			//We should only receive this notification upon sending a file
			message = [NSString stringWithFormat:AILocalizedString(@"Offering to send %@ to %@",nil),filename,listContact.formattedUID];
		}

		[self statusMessage:message forContact:listContact withType:type];
	}
}

/*!
 * @brief Post a status message on all active chats for this object
 */
- (void)statusMessage:(NSString *)message forContact:(AIListContact *)contact withType:(NSString *)type
{
	NSAttributedString	*attributedMessage = nil;

    for (AIChat *chat in [adium.chatController allChatsWithContact:contact]) {
        AIContentEvent	*content; 
		
		if (!attributedMessage)
			attributedMessage = [[[NSAttributedString alloc] initWithString:message
																 attributes:[adium.contentController defaultFormattingAttributes]] autorelease];
		
        //Create our content object
        content = [AIContentEvent statusInChat:chat
									withSource:contact
								   destination:chat.account
										  date:[NSDate date]
									   message:attributedMessage
									  withType:type];
		
        //Add the object
        [adium.contentController receiveContentObject:content];
    }
}

@end
