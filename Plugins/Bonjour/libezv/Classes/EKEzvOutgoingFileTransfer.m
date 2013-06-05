//
//  EKEzvOutgoingFileTransfer.m
//  Adium
//
//  Created by Erich Kreutzer on 8/10/07.
//  Copyright 2007 The Adium Team. All rights reserved.
//

#import "EKEzvOutgoingFileTransfer.h"
#import "AWEzv.h"
#import "AWEzvContactManager.h"

#define APPLE_SINGLE_HEADER_LENGTH 26
#define APPLE_SINGLE_MAGIC_NUMBER 0x00051600
#define APPLE_SINGLE_VERSION_NUMBER 0x00020000

#define AS_ENTRY_DATA_FORK 1
#define AS_ENTRY_RESOURCE_FORK 2
#define AS_ENTRY_REAL_NAME 3
#define AS_ENTRY_COMMENT 4
#define AS_ENTRY_ICON_BW 5
#define AS_ENTRY_ICON_COLOR 6
#define AS_ENTRY_DATE_INFO 8
#define AS_ENTRY_FINDER_INFO 9
#define AS_ENTRY_MACINTOSH_FILE_INFO 10
#define AS_ENTRY_PRODOS_FILE_INFO 11
#define AS_ENTRY_MSDOS_FILE_INFO 12
#define AS_ENTRY_AFP_SHORT_NAME 13
#define AS_ENTRY_AFP_FILE_INFO 14
#define AS_ENTRY_AFP_DIRECTORY_ID 15

struct AppleSingleHeader {
	UInt32 magicNumber;
	UInt32 versionNumber;
	char filler[16];
	UInt16 numberEntries;
};
typedef struct AppleSingleHeader AppleSingleHeader;

struct AppleSingleEntry {
	UInt32 entryID;
	UInt32 offset;
	UInt32 length;
};
typedef struct AppleSingleEntry AppleSingleEntry;

struct AppleSingleFinderInfo {
	struct FileInfo finderInfo;
	struct FXInfo extendedFinderInfo; 
};
typedef struct AppleSingleFinderInfo AppleSingleFinderInfo;


@implementation EKEzvOutgoingFileTransfer
- (id)init
{
	if ((self = [super init])) {
		urlSizes = [[NSMutableDictionary alloc] initWithCapacity:10];
		validURLS = [[NSMutableArray alloc] initWithCapacity:10];
		urlData = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}

- (BOOL)isDirectory
{
	return isDirectory;
}

- (NSString *)posixflags
{
	return posixflags;
}

- (void)setContactUID:(NSString *)newUID
{
	if (contactUID != newUID) {
		contactUID = newUID;
	}
}

- (void)startSending
{
	bool success = NO;

	/* Get contact from UID */
	[self setContact:[[self manager] contactForIdentifier:contactUID]];

	success = [self processTransfer];
	if (!success) {
		[[[[self manager] client] client] transferFailed:self];
		return;
	}

	success = [self getData];
	if (!success) {
		[[[[self manager] client] client] transferFailed:self];
		return;
	}

	/* We need to start the server */
	success = [self startHTTPServer];
	if (!success) {
		[[[[self manager] client] client] transferFailed:self];
		return;
	}
	
	/* Now we send the correct information to the contact */
	[self sendTransferMessage];
}

- (void)stopSending
{
	[server stop];
}

- (bool) processTransfer
{
	/*Check to see if it is a directory, mimetype, etc... */
	NSString *path = [self localFilename];
	BOOL directory = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&directory];
	if (!exists) {
		[self cancelTransfer];
		return NO;
	}
	if (directory) {
		isDirectory = YES;
	}

	[self setMimeType:[self mimeTypeForPath:path]];
	posixflags = [self posixFlagsForPath:path];

	if (posixflags == nil) {
		return NO;
	}

	return YES;
}

- (bool)getData
{
	/*Let's load the data from disk into the urlData dictionary */
	if (!isDirectory) {
		/*Only one file so let's add the path */

		[urlData setObject:[self localFilename] forKey:[[self localFilename] lastPathComponent]];

	} else {
		/* We will need to update the size of the transfer so let's set it to 0 so we can add to it */
		[self setSize:0u];

		/*First we need to get the NSData for the xml to describe the directory contents*/
		directoryXMLData = [self generateDirectoryXML];
		/* Now we need to get the NSData for each item in the directory */
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *basePath = [[self localFilename] stringByAppendingString:@"/"];
		
		for (NSString *file in [fileManager enumeratorAtPath:[self localFilename]]) {
			NSString *fullPath = [basePath stringByAppendingString:file];

			BOOL exists = NO;
			BOOL directory = NO;
			exists = [fileManager fileExistsAtPath:fullPath isDirectory:&directory];
			if (!exists) {
				[[[[self manager] client] client] reportError:@"File to transfer no longer exists." ofLevel:AWEzvError];

				return nil;
			}
			if (!directory && ![file hasPrefix:@".DS_Store"]) {
				NSString *subPath = [[[[self localFilename] lastPathComponent] stringByAppendingString:@"/"] stringByAppendingString: file];

				/*Reset the size */
				NSNumber *sizeNumber = [self sizeNumberForPath:fullPath];
				if (sizeNumber) {
					[urlSizes setObject:sizeNumber forKey:subPath];
					[self setSize:[self size] + [sizeNumber unsignedLongLongValue]];
				}

				[urlData setObject:fullPath forKey:subPath];
			}
		}
	}
	return YES;
}

- (bool) startHTTPServer
{
	server = [[HTTPServer alloc] init];

	NSError *error;
	BOOL success = [server start:&error];

	if (!success)
	{
		[[[[self manager] client] client] reportError:@"Could not start HTTP Server." ofLevel:AWEzvError];
		return NO;
	} else {
		[server setTransfer: self];
		return YES;
	}
}

- (void)sendTransferMessage
{
	[[self contact] sendOutgoingFileTransfer: self];
}

#pragma mark Support Methods

- (NSData *)generateDirectoryXML
{
	/*Example XML:
	 * <dir posixflags="01ED"> <name>untitled folder</name>
	 *  <file mimetype="application/rtf" size="318"> <name>blah copy.rtf</name></file>
	 *  <file mimetype="application/rtf" size="318"> <name>blah.rtf</name></file>
	 *  <dir posixflags="01ED"> <name>folder</name>
	 *  </dir>
	 * </dir>
	 **/
	NSString *newPath = [self localFilename];
	/*Create the dir */
	NSXMLElement *root = [[NSXMLElement alloc] initWithName:@"dir"];
	NSString *posixFlags = [self posixFlagsForPath: newPath];
	if (posixFlags != nil) {
		[root addAttribute:[NSXMLNode attributeWithName:@"posixflags" stringValue:posixFlags]];
	}

	/*Add the name */
	NSXMLElement *name = [[NSXMLElement alloc] initWithName:@"name" stringValue:[newPath lastPathComponent]];
	[root addChild:name];
	NSArray *children = [self generateXMLFromDirectory:newPath];

	NSXMLElement *child;
	for (child in children) {
		[root addChild:child];
	}

	NSString *xmlString = [root XMLString];
	return [NSData dataWithBytes:[xmlString UTF8String] length:[xmlString length]];
}

- (NSArray *)generateXMLFromDirectory:(NSString *)basePath
{
	/*Example XML:
	 * <dir posixflags="01ED"> <name>untitled folder</name>
	 *  <file mimetype="application/rtf" size="318"> <name>blah copy.rtf</name></file>
	 *  <file mimetype="application/rtf" size="318"> <name>blah.rtf</name></file>
	 *  <dir posixflags="01ED"> <name>folder</name>
	 *  </dir>
	 * </dir>
	 **/
	NSMutableArray *children = [NSMutableArray arrayWithCapacity:10];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	for (NSString *file in [fileManager contentsOfDirectoryAtPath:basePath error:NULL]){
		NSString *newPath = [basePath stringByAppendingPathComponent:file];
		BOOL exists = NO;
		BOOL directory = NO;
		exists = [fileManager fileExistsAtPath:newPath isDirectory:&directory];
		if (!exists) {
			[[[[self manager] client] client] reportError:@"File to transfer no longer exists." ofLevel:AWEzvError];
			return nil;
		}
		if ([file hasPrefix:@".DS_Store"]) {
			continue;
		}

		if (directory) {
			// handle the creation of the directory xml
			NSXMLElement *directoryNode = [[NSXMLElement alloc] initWithName:@"dir"];
			NSString *posixFlags = [self posixFlagsForPath: newPath];
			if (posixFlags != nil) {
				[directoryNode addAttribute:[NSXMLNode attributeWithName:@"posixflags" stringValue:posixFlags]];
			}

			NSXMLElement *name = [[NSXMLElement alloc] initWithName:@"name" stringValue:file];
			[directoryNode addChild:name];

			NSArray *dirChildren = [self generateXMLFromDirectory:newPath];

			for (NSXMLElement *child in dirChildren) {
				[directoryNode addChild:child];
			}

			[children addObject:directoryNode];
		} else {
			// create the file xml
			NSXMLElement *fileXML = [[NSXMLElement alloc] initWithName:@"file"];
			NSString *mimeTypeString = [self mimeTypeForPath:newPath];
			if (mimeType != nil) {
				[fileXML addAttribute:[NSXMLNode attributeWithName:@"mimetype" stringValue:mimeTypeString]];
			}

			NSString *posixFlags = [self posixFlagsForPath:newPath];
			if (posixFlags != nil) {
				[fileXML addAttribute:[NSXMLNode attributeWithName:@"posixflags" stringValue:posixFlags]];
			}
			NSString *sizeString = [self sizeForPath:newPath];
			if (size != 0) {
				[fileXML addAttribute:[NSXMLNode attributeWithName:@"size" stringValue:sizeString]];
			}

			NSXMLElement *name = [[NSXMLElement alloc] initWithName:@"name" stringValue:file];
			[fileXML addChild:name];

			/*Now add this to the array */
			[children addObject:fileXML];
		}
	}
	return children;
}
- (NSString *)baseURL
{

	NSString *component = [NSString stringWithFormat:@"http://%@:%hu", [server localHost], [server port]];

	NSString *URI = @"/";

	URI = [URI stringByAppendingString:[[NSProcessInfo processInfo] globallyUniqueString]];	

	randomString = [URI stringByAppendingString:@"/"];

	URI = [URI stringByAppendingPathComponent:[[[self localFilename] lastPathComponent] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if (isDirectory)
		URI = [URI stringByAppendingString:@"/"];

	[validURLS addObject:URI];

	component = [component stringByAppendingString:URI];

	return component;
}
- (BOOL)isBaseURIForDirectoryTransfer:(NSString *)URI
{
	BOOL isBase = NO;
	if ([URI hasPrefix:randomString] && ([URI length] > [randomString length])) {
		NSString *path = [URI substringFromIndex:[randomString length]];
		if ([path isEqualToString:[[[self localFilename] lastPathComponent] stringByAppendingString:@"/"]]) {
			isBase = YES;
		}
	}
	return isBase;
}
- (BOOL)isValidURI:(NSString *)URI
{
	bool isValid = NO;
	isValid = [validURLS containsObject:URI];
	if (!isValid) {
		[[[[self manager] client] client] reportError:@"Client requested an invalid file." ofLevel:AWEzvError];
	}
	return isValid;
}

- (NSData *)appleSingleDataForURI:(NSString *)URI
{
	NSString *filePath = nil;
	NSNumber *singleSize = nil;
	if ([URI hasPrefix:randomString] && ([URI length] > [randomString length])) {
		NSString *path = [URI substringFromIndex:[randomString length]];
		filePath = [[[self localFilename] stringByDeletingLastPathComponent] stringByAppendingPathComponent: path];
		singleSize = [urlSizes valueForKey:path];
	}


	/*Include the three entries that iChat includes */
	struct AppleSingleHeader info;
	memset(&info, 0, sizeof(info));
	info.magicNumber = htonl(APPLE_SINGLE_MAGIC_NUMBER);
	info.versionNumber = htonl(APPLE_SINGLE_VERSION_NUMBER);
	info.numberEntries = htons(3);

	/* Setup the three AppleSingleEntrys */
	struct AppleSingleEntry finderInfoEntry;
	struct AppleSingleEntry realNameEntry;
	struct AppleSingleEntry dataEntry;

	memset(&finderInfoEntry, 0, sizeof(finderInfoEntry));
	memset(&realNameEntry, 0, sizeof(realNameEntry));
	memset(&dataEntry, 0, sizeof(dataEntry));

	unsigned long long offset = APPLE_SINGLE_HEADER_LENGTH + sizeof(finderInfoEntry) * 3;
	/*Finder info */
	/*Get the info from the finder */
	FSRef ref;
	FSCatalogInfo catalogInfo;
	OSStatus err;
	Boolean itemIsDirectory = NO;
	err = FSPathMakeRef((const UInt8 *)[filePath fileSystemRepresentation], &ref, &itemIsDirectory);
	if (err != noErr) {
		[[[[self manager] client] client] reportError:@"AppleSingle: Error creating FSRef" ofLevel:AWEzvError];
		return nil;
	}
	err = FSGetCatalogInfo (/*const FSRef * ref*/ &ref,
	                        /*FSCatalogInfoBitmap whichInfo*/ (kFSCatInfoFinderInfo | kFSCatInfoFinderXInfo),
	                        /*FSCatalogInfo * catalogInfo*/ &catalogInfo,
	                        /*HFSUniStr255 * outName*/ NULL,
	                        /*FSSpec * fsSpec*/ NULL,
	                        /*FSRef * parentRef*/ NULL);
	if (err != noErr) {
		[[[[self manager] client] client] reportError:@"AppleSingle: Error creating FSRef" ofLevel:AWEzvError];
		return nil;
	}

	/*Use the info from finder to create the AppleSingleFinderInfo struct */
	struct AppleSingleFinderInfo fileInfo;
	memset(&fileInfo, 0, sizeof(fileInfo));
	Size byteCount = sizeof(fileInfo.finderInfo);
	if(byteCount > 0)
	    memmove(&(catalogInfo.finderInfo), &(fileInfo.finderInfo), byteCount);
	byteCount = sizeof(fileInfo.extendedFinderInfo);
	if(byteCount > 0)
	    memmove(&(catalogInfo.extFinderInfo), &(fileInfo.extendedFinderInfo), byteCount);

	/*Now switch from host to network byte order */
	fileInfo.finderInfo.finderFlags = htons(fileInfo.finderInfo.finderFlags);

	/*Create the AppleSingleEntry for this data */
	finderInfoEntry.entryID = htonl(AS_ENTRY_FINDER_INFO);
	finderInfoEntry.length = htonl(sizeof(fileInfo));
	/*Offset so that it is at the end of the *3* AppleSingleEntries*/
	NSAssert( UINT_MAX >= offset, @"offset exceeds UINT_MAX");
	finderInfoEntry.offset = htonl((UInt32)offset);
	offset += sizeof(fileInfo);

	/*Real Name*/
	const char *realName = [[URI lastPathComponent] UTF8String];
	NSUInteger nameLength = [[URI lastPathComponent] length];

	realNameEntry.entryID = htonl(AS_ENTRY_REAL_NAME);
	NSAssert( UINT_MAX >= nameLength, @"nameLength exceeds UINT_MAX");
	realNameEntry.length = htonl((UInt32)nameLength);
	/*Offset so that it is at the end of the *3* AppleSingleEntries*/
	NSAssert( UINT_MAX >= offset, @"offset exceeds UINT_MAX");
	realNameEntry.offset = htonl((UInt32)offset);

	offset += nameLength;
	unsigned long long newSize;
	if ([self isDirectory]) {
		newSize = (singleSize ? [singleSize unsignedLongLongValue] : 0);
	} else {
		newSize = [self size];
	}
	/*Data resource fork */
	dataEntry.entryID = htonl(AS_ENTRY_DATA_FORK);
	NSAssert( UINT_MAX >= newSize, @"offset exceeds UINT_MAX");
	dataEntry.length = htonl((UInt32)newSize);
	NSAssert( UINT_MAX >= offset, @"offset exceeds UINT_MAX");
	dataEntry.offset = htonl((UInt32)offset);

	NSMutableData *data = [NSMutableData dataWithBytes:&info length: APPLE_SINGLE_HEADER_LENGTH];
	[data appendBytes:&finderInfoEntry length:sizeof(finderInfoEntry)];
	[data appendBytes:&realNameEntry length:sizeof(realNameEntry)];
	[data appendBytes:&dataEntry length:sizeof(dataEntry)];
	[data appendBytes:&fileInfo length:sizeof(fileInfo)];
	[data appendBytes:realName length:nameLength];
	/*Data will be appended in the HTTPServer*/
	return data;
}
- (NSString *)fileDataForURI:(NSString *)URI
{
	NSString *data = nil;
	if ([URI hasPrefix:randomString] && ([URI length] > [randomString length])) {
		NSString *path = [URI substringFromIndex:[randomString length]];
		data = (NSString *)[urlData valueForKey:path];
		[urlData removeObjectForKey:path];
	}
	return data;
}

- (NSString *)posixFlagsForPath:(NSString *)filePath
{
	NSString *posixFlags = nil;
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
	if (attributes && [attributes objectForKey:NSFilePosixPermissions]) {
		NSNumber *posixInfo = [attributes objectForKey:NSFilePosixPermissions];
		posixFlags = [NSString stringWithFormat:@"%lX", [posixInfo longValue]];
	}

	return posixFlags;
}

- (NSString *)mimeTypeForPath:(NSString *)filePath
{
	NSString *mime = nil;
	NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
	                                                                   (__bridge CFStringRef)[filePath pathExtension],
	                                                                   NULL);
	mime = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
	if (!mime || [mime length] == 0)
	{
		mime = @"application/octet-stream";
	}
	return mime;
}

- (NSString *)sizeForPath:(NSString *)filePath
{
	NSString *fileSize = nil;
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
	if (attributes && [attributes objectForKey:NSFileSize]) {
		NSNumber *fileSizeNumber = [attributes objectForKey:NSFileSize];
		fileSize = [NSString stringWithFormat:@"%qu", [fileSizeNumber unsignedLongLongValue]];
	}

	return fileSize;
}

- (NSNumber *)sizeNumberForPath:(NSString *)filePath
{
	NSNumber *fileSize = nil;
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
	if (attributes && [attributes objectForKey:NSFileSize]) {
		fileSize = [attributes objectForKey:NSFileSize];
	}

	return fileSize;
}

- (void)cancelTransfer
{
	[self stopSending];
}

- (void)userFailedDownload
{
	[[[[self manager] client] client] remoteCanceledFileTransfer:self];
}
- (void)userBeganDownload
{
	[[[[self manager] client] client] remoteUserBeganDownload:self];
}

- (void)userFinishedDownload
{
	/* Cleanup the data lying around */
	[self stopSending];

	[[[[self manager] client] client] remoteUserFinishedDownload:self];	
}

- (void)didSendDataWithLength:(UInt32)length
{
	bytesSent = bytesSent+length;
	percentComplete = ((float)bytesSent/(float)[[self sizeNumber] floatValue]);
	if (percentComplete < 1.0) {
		[[[[self manager] client] client] updateProgressForFileTransfer:self
																percent:[NSNumber numberWithFloat:percentComplete] 
															  bytesSent:[NSNumber numberWithLongLong:bytesSent]];
	}
}

- (BOOL)moreFilesToDownload
{
	BOOL more = NO;
	if (isDirectory && urlData)
		more = ([urlData count] > 0);
	return more;
}

- (NSData *)directoryXMLData
{
	return directoryXMLData;
}
@end
