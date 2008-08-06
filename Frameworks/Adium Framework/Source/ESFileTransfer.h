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
#import <Adium/AIFileTransferControllerProtocol.h>

#define CONTENT_FILE_TRANSFER_TYPE  @"File Transfer Type"

@class AIAccount, AIListObject, ESFileTransfer, ESFileTransferRequestPromptController;

@protocol FileTransferDelegate
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetType:(AIFileTransferType)type;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(AIFileTransferStatus)status;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetSize:(unsigned long long)size;
-(void)fileTransfer:(ESFileTransfer *)fileTransfer didSetLocalFilename:(NSString *)inLocalFilename;
-(void)gotUpdateForFileTransfer:(ESFileTransfer *)fileTransfer;
@end

@interface ESFileTransfer : AIContentMessage {
    NSString					*localFilename;
    NSString					*remoteFilename;
    id							accountData;
    
    float						percentDone;
    unsigned long long			size;
    unsigned long long			bytesSent;
	BOOL                        isDirectory;
    AIFileTransferType			type;
	AIFileTransferStatus		status;

	NSString					*uniqueID;
	id <FileTransferDelegate>   delegate;
	
	ESFileTransferRequestPromptController *promptController;
}

+ (id)fileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount type:(AIFileTransferType)t;
+ (ESFileTransfer *)existingFileTransferWithID:(NSString *)fileTransferID;

- (AIListContact *)contact;
- (AIAccount<AIAccount_Files> *)account;

- (void)setRemoteFilename:(NSString *)inRemoteFilename;
- (NSString *)remoteFilename;

- (void)setLocalFilename:(NSString *)inLocalFilename;
- (NSString *)localFilename;

- (NSString *)displayFilename;

- (void)setSize:(unsigned long long)inSize;
- (unsigned long long)size;

- (void)setIsDirectory:(BOOL)inIsDirectory;
- (BOOL)isDirectory;

- (void)setFileTransferType:(AIFileTransferType)inType;
- (AIFileTransferType)fileTransferType;

- (void)setStatus:(AIFileTransferStatus)inStatus;
- (AIFileTransferStatus)status;

- (void)setPercentDone:(float)inPercent bytesSent:(unsigned long long)inBytesSent;
- (float)percentDone;
- (unsigned long long)bytesSent;

- (void)setAccountData:(id)inAccountData;
- (id)accountData;

- (void)setDelegate:(id <FileTransferDelegate>)inDelegate;
- (id <FileTransferDelegate>)delegate;

- (BOOL)isStopped;

- (void)cancel;
- (void)reveal;
- (void)openFile;

- (NSImage *)iconImage;

- (NSString *)uniqueID;

- (void)setFileTransferRequestPromptController:(ESFileTransferRequestPromptController *)inPromptController;
- (ESFileTransferRequestPromptController *)fileTransferRequestPromptController;

@end
