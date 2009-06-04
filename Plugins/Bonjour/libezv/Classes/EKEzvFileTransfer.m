#import "EKEzvFileTransfer.h"
#import "EKEzvIncomingFileTransfer.h"
#import "EKEzvOutgoingFileTransfer.h"

@implementation EKEzvFileTransfer

- (void)dealloc
{
	[self setContact:nil];
	[self setManager:nil];
	[self setLocalFilename:nil];
	[self setRemoteFilename:nil];
	[self setUrl:nil];
	[self setMimeType:nil];
	[self setAccountData:nil];
	[self setUniqueID:nil];

	[super dealloc];
}
#pragma mark -
#pragma mark accessors


- (AWEzvContact *)contact
{
    //NSLog(@"in -contact, returned contact = %@", contact);

    return contact; 
}
- (void)setContact:(AWEzvContact *)aContact
{
    //NSLog(@"in -setContact:, old value of contact: %@, changed to: %@", contact, aContact);

    if (contact != aContact) {
        [contact release];
        contact = [aContact retain];
    }
}


- (AWEzvContactManager *)manager
{
    //NSLog(@"in -manager, returned manager = %@", manager);

    return manager; 
}
- (void)setManager:(AWEzvContactManager *)aManager
{
    //NSLog(@"in -setManager:, old value of manager: %@, changed to: %@", manager, aManager);

    if (manager != aManager) {
        [manager release];
        manager = [aManager retain];
    }
}

- (EKFileTransferDirection)direction
{
    return direction;
}
- (void)setDirection:(EKFileTransferDirection)aDirection
{
	direction = aDirection;
}

- (EKFileTransferType)type
{
    //NSLog(@"in -type, returned type = (null)", type);

    return type;
}
- (void)setType:(EKFileTransferType)aType
{
    //NSLog(@"in -setType, old value of type: (null), changed to: (null)", type, aType);

    type = aType;
}


- (float)percentComplete
{
    //NSLog(@"in -percentComplete, returned percentComplete = %f", percentComplete);

    return percentComplete;
}
- (void)setPercentComplete:(float)aPercentComplete
{
    //NSLog(@"in -setPercentComplete, old value of percentComplete: %f, changed to: %f", percentComplete, aPercentComplete);

    percentComplete = aPercentComplete;
}


- (int)status
{
    //NSLog(@"in -status, returned status = %i", status);

    return status;
}
- (void)setStatus:(int)aStatus
{
    //NSLog(@"in -setStatus, old value of status: %i, changed to: %i", status, aStatus);

    status = aStatus;
}


- (NSString *)localFilename
{
    //NSLog(@"in -localFilename, returned localFilename = %@", localFilename);

    return localFilename; 
}
- (void)setLocalFilename:(NSString *)aLocalFilename
{
    //NSLog(@"in -setLocalFilename:, old value of localFilename: %@, changed to: %@", localFilename, aLocalFilename);

    if (localFilename != aLocalFilename) {
        [localFilename release];
        localFilename = [aLocalFilename retain];
    }
}


- (NSString *)remoteFilename
{
    //NSLog(@"in -remoteFilename, returned remoteFilename = %@", remoteFilename);

    return remoteFilename; 
}
- (void)setRemoteFilename:(NSString *)aRemoteFilename
{
    //NSLog(@"in -setRemoteFilename:, old value of remoteFilename: %@, changed to: %@", remoteFilename, aRemoteFilename);

    if (remoteFilename != aRemoteFilename) {
        [remoteFilename release];
        remoteFilename = [aRemoteFilename retain];
    }
}


- (NSString *)url
{
    //NSLog(@"in -url, returned url = %@", url);

    return url; 
}
- (void)setUrl:(NSString *)anUrl
{
    //NSLog(@"in -setUrl:, old value of url: %@, changed to: %@", url, anUrl);

    if (url != anUrl) {
        [url release];
        url = [anUrl retain];
    }
}


- (NSString *)mimeType
{
    //NSLog(@"in -mimeType, returned mimeType = %@", mimeType);

    return mimeType; 
}
- (void)setMimeType:(NSString *)aMimeType
{
    //NSLog(@"in -setMimeType:, old value of mimeType: %@, changed to: %@", mimeType, aMimeType);

    if (mimeType != aMimeType) {
        [mimeType release];
        mimeType = [aMimeType retain];
    }
}


- (id)accountData
{
    //NSLog(@"in -accountData, returned accountData = %@", accountData);

    return accountData; 
}
- (void)setAccountData:(id)anAccountData
{
    //NSLog(@"in -setAccountData:, old value of accountData: %@, changed to: %@", accountData, anAccountData);

    if (accountData != anAccountData) {
        [accountData release];
        accountData = [anAccountData retain];
    }
}


- (unsigned long long)size
{
    // NSLog(@"in -size, returned size = %qu", size);

    return size;
}
- (void)setSize:(unsigned long long)aSize
{
    // NSLog(@"in -setSize, old value of size: %qu, changed to: %qu", size, aSize);

    size = aSize;
}

- (void)setSizeWithNSNumber:(NSNumber *)number
{
	[self setSize:[number unsignedLongLongValue]];
}

- (NSNumber *)sizeNumber
{
	return [NSNumber numberWithUnsignedLongLong:size];
}
- (unsigned long long)bytesSent
{
    //NSLog(@"in -bytesSent, returned bytesSent = %qu", bytesSent);

    return bytesSent;
}
- (void)setBytesSent:(unsigned long long)aBytesSent
{
    //NSLog(@"in -setBytesSent, old value of bytesSent: %qu, changed to: %qu", bytesSent, aBytesSent);

    bytesSent = aBytesSent;
}


- (NSString *)uniqueID
{
    //NSLog(@"in -uniqueID, returned uniqueID = %@", uniqueID);

    return uniqueID; 
}
- (void)setUniqueID:(NSString *)anUniqueID
{
    //NSLog(@"in -setUniqueID:, old value of uniqueID: %@, changed to: %@", uniqueID, anUniqueID);

    if (uniqueID != anUniqueID) {
        [uniqueID release];
        uniqueID = [anUniqueID retain];
    }
}

#pragma mark Process File Transfers
- (void) begin
{
	if (direction == EKEzvIncomingTransfer) {
		EKEzvIncomingFileTransfer *incoming = (EKEzvIncomingFileTransfer *)self;
		[incoming startDownload];
	} else if (direction == EKEzvOutgoingTransfer) {
		EKEzvOutgoingFileTransfer *outgoing = (EKEzvOutgoingFileTransfer *)self;
		[outgoing startSending];
	} else {
		
	}
}

- (void) cancel
{
	if (direction == EKEzvIncomingTransfer) {
		EKEzvIncomingFileTransfer *incoming = (EKEzvIncomingFileTransfer *)self;
		[incoming cancelDownload];
	} else if (direction == EKEzvOutgoingTransfer) {
		EKEzvOutgoingFileTransfer *outgoing = (EKEzvOutgoingFileTransfer *)self;
		[outgoing cancelTransfer];
	} else {
		
	}
}

@end
