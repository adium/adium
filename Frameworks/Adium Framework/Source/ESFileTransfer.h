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

@property (readonly, nonatomic) AIListContact *contact;
@property (readonly, nonatomic) AIAccount<AIAccount_Files> *account;

@property (readwrite, nonatomic, retain) NSString *remoteFilename;
@property (readwrite, nonatomic, retain) NSString *localFilename;
@property (readonly, nonatomic) NSString *displayFilename;

@property (readwrite, nonatomic) unsigned long long size;
@property (readwrite, nonatomic) BOOL isDirectory;
@property (readwrite, nonatomic) AIFileTransferType fileTransferType;
@property (readwrite, nonatomic) AIFileTransferStatus status;

- (void)setPercentDone:(NSNumber *)percent bytes:(NSNumber *)bytes;
- (void)setPercentDone:(float)inPercent bytesSent:(unsigned long long)inBytesSent;
@property (readonly, nonatomic) float percentDone;
@property (readonly, nonatomic) unsigned long long bytesSent;
- (void)setSizeWithNumber:(NSNumber *)newSize;
- (NSNumber *)sizeNumber;

@property (readwrite, nonatomic, retain) id accountData;

@property (readwrite, nonatomic, assign) id <FileTransferDelegate> delegate;

@property (readonly, nonatomic) BOOL isStopped;

- (void)cancel;
- (void)reveal;
- (void)openFile;

@property (readonly, nonatomic) NSImage *iconImage;

@property (readonly, nonatomic) NSString *uniqueID;

@property (readwrite, nonatomic, retain) ESFileTransferRequestPromptController *fileTransferRequestPromptController;

@end
