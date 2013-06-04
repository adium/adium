//
//  EKEzvOutgoingFileTransfer.h
//  Adium
//
//  Created by Erich Kreutzer on 8/10/07.
//

#import "EKEzvFileTransfer.h"
#import "HTTPServer.h"

@interface EKEzvOutgoingFileTransfer : EKEzvFileTransfer{
	bool isDirectory;
	HTTPServer *server;
	NSString *hfsflags;
	NSString *posixflags;
	NSString *contactUID;
	
	NSString *randomString;
	
	NSData *directoryXMLData;

	NSMutableDictionary *urlSizes;
	NSMutableArray *validURLS;
	NSMutableDictionary *urlData;
}
- (BOOL)isDirectory;
- (NSString *)posixflags;
- (void) setContactUID:(NSString *)newUID;
- (void) startSending;
- (bool) processTransfer;
- (bool)getData;
- (bool) startHTTPServer;
- (void) sendTransferMessage;
- (NSData *)generateDirectoryXML;
- (NSArray *)generateXMLFromDirectory:(NSString *)basePath;
- (NSString *)baseURL;
- (BOOL)isBaseURIForDirectoryTransfer:(NSString *)URI;
- (BOOL)isValidURI:(NSString *)URI;
- (NSData *)appleSingleDataForURI:(NSString *)URI;
- (NSString *)fileDataForURI:(NSString *)URI;
- (NSString *)posixFlagsForPath:(NSString *)filePath;
- (NSString *)mimeTypeForPath:(NSString *)filePath;
- (NSString *)sizeForPath:(NSString *)filePath;
- (NSNumber *)sizeNumberForPath:(NSString *)filePath;
- (void) cancelTransfer;
- (void) userFailedDownload;
- (void) userBeganDownload;
- (void) userFinishedDownload;
- (void)didSendDataWithLength:(UInt32)length;
- (BOOL)moreFilesToDownload;
- (NSData *)directoryXMLData;

@end
