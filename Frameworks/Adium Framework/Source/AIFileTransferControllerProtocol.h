/*
 *  AIFileTransferControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

#define	FileTransfer_NewFileTransfer	@"NewFileTransfer"

#define	PREF_GROUP_FILE_TRANSFER		@"FileTransfer"

#define	KEY_FT_AUTO_ACCEPT				@"FT AutoAccept"
#define KEY_FT_AUTO_OPEN_SAFE			@"FT AutoOpenSafe"
#define	KEY_FT_AUTO_CLEAR_COMPLETED		@"FT AutoClearCompleted"
#define	KEY_FT_SHOW_PROGRESS_WINDOW		@"FT ShowProgressWindow"

typedef enum {
	Unknown_FileTransfer = 0,
    Incoming_FileTransfer,
    Outgoing_FileTransfer,
} AIFileTransferType;

typedef enum {
	Unknown_Status_FileTransfer = 0,
	Not_Started_FileTransfer,		//File transfer has not yet started
	Checksumming_Filetransfer,		//Calculating a checksum for a file that is to be sent
	Waiting_on_Remote_User_FileTransfer, //Is pending confirmation from the remote user
	Connecting_FileTransfer,		//Is negotiating a connection
	Accepted_FileTransfer,			//Could also be called Began_FileTransfer or Started_FileTransfer
	In_Progress_FileTransfer,		//Currently transferring, not yet complete
	Complete_FileTransfer,			//File is complete; transferring is finished.
	Cancelled_Local_FileTransfer,	//The local user cancelled the transfer
	Cancelled_Remote_FileTransfer,	//The remote user cancelled the transfer
	Failed_FileTransfer				//The transfer failed.
} AIFileTransferStatus;

typedef enum {
	AutoAccept_None = 0,
    AutoAccept_All,
    AutoAccept_FromContactList,
} AIFileTransferAutoAcceptType;

@class ESFileTransfer, AIAccount, AIListContact;

@protocol AIFileTransferController <AIController>
//Should be the only vendor of new ESFileTransfer* objects, as it creates, tracks, and returns them
- (ESFileTransfer *)newFileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount type:(AIFileTransferType)type;

- (NSArray *)fileTransferArray;

- (NSUInteger)activeTransferCount;

- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer;

- (void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(AIFileTransferStatus)status;

- (void)sendFile:(NSString *)inFile toListContact:(AIListContact *)listContact;
- (void)requestForSendingFileToListContact:(AIListContact *)listContact;

- (NSString *)stringForSize:(unsigned long long)inSize;
- (NSString *)stringForSize:(unsigned long long)inSize of:(unsigned long long)totalSize ofString:(NSString *)totalSizeString;

- (void)_removeFileTransfer:(ESFileTransfer *)fileTransfer;
@end
