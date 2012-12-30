#import "AWEzvContact.h"

typedef enum {
	EKEzvUnknown_Transfer = 0,
    EKEzvDirectory_Transfer,
    EKEzvFile_Transfer,
} EKFileTransferType;

typedef enum {
	EKEzvUnknownDirection = 0,
	EKEzvIncomingTransfer,
	EKEzvOutgoingTransfer,
} EKFileTransferDirection;

@class EKEzvIncomingFileTransfer, EKEzvOutgoingFileTransfer;
@interface EKEzvFileTransfer : NSObject {
	AWEzvContact *contact;
	AWEzvContactManager *manager;
	EKFileTransferType type;
	EKFileTransferDirection direction;
	
	float percentComplete;
	float previousPercentComplete;
	int status;
	
	NSString *localFilename;
    NSString *remoteFilename;
	NSString *url;
	NSString *mimeType;
    id 	accountData;

    unsigned long long size;
    unsigned long long bytesSent;

	long long bytesReceived;

	NSString *uniqueID;
}

- (AWEzvContact *)contact;
- (void)setContact:(AWEzvContact *)aContact;
- (AWEzvContactManager *)manager;
- (void)setManager:(AWEzvContactManager *)aManager;
- (EKFileTransferType)type;
- (EKFileTransferDirection)direction;
- (void)setDirection:(EKFileTransferDirection)aDirection;
- (void)setType:(EKFileTransferType)aType;
- (float)percentComplete;
- (void)setPercentComplete:(float)aPercentComplete;
- (int)status;
- (void)setStatus:(int)aStatus;
- (NSString *)localFilename;
- (void)setLocalFilename:(NSString *)aLocalFilename;
- (NSString *)remoteFilename;
- (void)setRemoteFilename:(NSString *)aRemoteFilename;
- (NSString *)url;
- (void)setUrl:(NSString *)anUrl;
- (void)setMimeType:(NSString *)aMimeType;
- (id)accountData;
- (void)setAccountData:(id)anAccountData;
- (unsigned long long)size;
- (void)setSize:(unsigned long long)aSize;
- (void)setSizeWithNSNumber:(NSNumber *)number;
- (unsigned long long)bytesSent;
- (void)setBytesSent:(unsigned long long)aBytesSent;
- (NSString *)uniqueID;
- (void)setUniqueID:(NSString *)anUniqueID;

- (void) begin;
- (void) cancel;
- (NSString *)mimeType;
- (NSNumber *)sizeNumber;
@end
