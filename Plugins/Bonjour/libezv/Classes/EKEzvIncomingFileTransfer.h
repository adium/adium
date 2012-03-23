//
//  EKEzvIncomingFileTransfer.h
//  Adium
//
//  Created by Erich Kreutzer on 8/14/07.
//

#import "EKEzvFileTransfer.h"
#import "AIOSCompatibility.h"

@interface EKEzvIncomingFileTransfer : EKEzvFileTransfer <NSURLDownloadDelegate> {
	NSMutableDictionary *itemsToDownload;
	NSMutableDictionary *permissionsToApply;
	
	NSMutableArray *encodedDownloads;
	NSMutableArray *currentDownloads;
}
- (void) startDownload;
- (void) cancelDownload;
- (void) downloadFolder;
- (bool)downloadFolder:(NSXMLElement *)root path:(NSString *)rootPath url:(NSString *)rootURL;
- (void) downloadFile;
- (NSDictionary *)posixAttributesFromString:(NSString *)posixFlags;
- (BOOL) applyPermissions;
- (void)downloadURL:(NSURL *)url toPath:(NSString *)path;
- (NSString *)urlToPath:(NSURL *)itemURL;
- (BOOL)decodeAppleSingleAtPath:(NSString *)path;
@end
