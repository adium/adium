//
//  EKEzvIncomingFileTransfer.m
//  Adium
//
//  Created by Erich Kreutzer on 8/14/07.
//

#import "EKEzvIncomingFileTransfer.h"
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

@implementation EKEzvIncomingFileTransfer
#pragma mark Downloading

- (void) startDownload
{
	currentDownloads = [[NSMutableArray alloc] initWithCapacity: 10];
	encodedDownloads = [[NSMutableArray alloc] initWithCapacity: 10];
	if (type == EKEzvFile_Transfer) {
		[self downloadFile];
	} else if (type == EKEzvDirectory_Transfer) {
		[self downloadFolder];
	} else {
		[[[manager client] client] reportError:@"Don't know what type of item we are downloading" ofLevel:AWEzvError];
		[[[manager client] client] remoteCanceledFileTransfer:self];
	}

}

- (void) cancelDownload
{
	if ([currentDownloads count] > 0) {
		NSURLDownload *download;
		for ( download in currentDownloads) {
			[download cancel];
		}
		currentDownloads = nil;
		encodedDownloads = nil;
	}
}
- (void) downloadFolder
{
	/*We need to first get the xml for the layout */
	NSURL *URL = [NSURL URLWithString:url];
	NSError *error = nil;
	NSXMLDocument *documentRoot = [[NSXMLDocument alloc] initWithContentsOfURL:URL options:0 error:&error];
	if (error) {
		[[[[self manager] client] client] remoteCanceledFileTransfer:self];
		return;
	}
	/*NO error so we have the xml */
	NSXMLElement *root = [documentRoot rootElement];
	/*We don't care about the root name because the user can rename it*/
	NSString *posixFlags = [[root attributeForName:@"posixflags"] objectValue];

	NSFileManager *fileManager = [NSFileManager defaultManager];

	BOOL isDirectory = NO;
	BOOL exists = [fileManager fileExistsAtPath:localFilename isDirectory:&isDirectory];
	if (exists && isDirectory) {
		/*We need to remove this file*/
		if (![fileManager removeItemAtPath:localFilename error:NULL]) {
			[[[[self manager] client] client] reportError:@"Could not replace old file at path" ofLevel:AWEzvError];
			[[[[self manager] client] client] remoteCanceledFileTransfer:self];
			return;
		}
	}

	if (![fileManager createDirectoryAtPath:localFilename
                withIntermediateDirectories:YES
                                 attributes:[self posixAttributesFromString:posixFlags]
                                      error:NULL]) {
		[[[[self manager] client] client] reportError:@"There was an error creating the root directory for the file tranfer" ofLevel:AWEzvError];
		[[[[self manager] client] client] remoteCanceledFileTransfer:self];
		return;
	}


	bool folderSuccess = YES;
	bool fileSuccess = YES;

	itemsToDownload = [NSMutableDictionary dictionaryWithCapacity:10];
	permissionsToApply = [[NSMutableDictionary  alloc] initWithCapacity:10];
		
	/*Call downloadFolder:path:url: for dir children */
	for (NSXMLElement *nextElement in [root elementsForName:@"dir"]) {
		folderSuccess = [self downloadFolder:nextElement path:localFilename url:[self url]];
	}
	
	/*Call downloadFolder:path:url: for file children */
	for (NSXMLElement *nextElement in [root elementsForName:@"file"]) {
		fileSuccess = [self downloadFolder:nextElement path:localFilename url:[self url]];
	}
	
	if (folderSuccess && fileSuccess) {

		/*Now go through itemsToDownload and download the files*/
		NSURL *downloadURL;
		for (NSString* path in [itemsToDownload keyEnumerator]) {
			/* code that uses the returned key */
			downloadURL = [itemsToDownload valueForKey:path];
			if (downloadURL) {
				[self downloadURL:downloadURL toPath:path];
				downloadURL = nil;
			} else {
				[[[[self manager] client] client] reportError:[NSString stringWithFormat:@"Error downloading file from %@ to %@", downloadURL, path] ofLevel:AWEzvError];
				[[[[self manager] client] client] remoteCanceledFileTransfer:self];
			}
		}

	} else {
		[[[[self manager] client] client] remoteCanceledFileTransfer:self];
	}
}
- (bool)downloadFolder:(NSXMLElement *)root path:(NSString *)rootPath url:(NSString *)rootURL
{
	/*Helper method to recursively download a folder using the xml*/
	/*root will be the current folder or file to download */
	/*rootPath will be the path -without- root's name appended */
	if ([[root name] isEqualToString:@"file"]) {
		/*We have a file so get it's info and then download it*/
	//	NSString *mimeType = [[root attributeForName:@"mimetype"] objectValue];
		NSString *posixFlags = [[root attributeForName:@"posixflags"] objectValue];
	//	NSString *hfsFlags = [[root attributeForName:@"hfsflags"] objectValue];
	//	NSString *size = [[root attributeForName:@"size"] objectValue];

		NSArray *nameChildren = [root elementsForName:@"name"];
		if (!nameChildren) {
			[[[[self manager] client] client] reportError:@"Could not download file because there is no name" ofLevel:AWEzvError];
			return NO;
		}
		NSString *name = [[nameChildren objectAtIndex:0] stringValue];
		NSString *newPath = [rootPath stringByAppendingPathComponent:name];
		NSString *newURL = [rootURL stringByAppendingPathComponent:[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

		/*Download file to newPath from newURL*/
		[itemsToDownload setValue:[NSURL URLWithString:newURL] forKey:newPath];
		[permissionsToApply setValue:[self posixAttributesFromString:posixFlags] forKey:newPath];

		return YES;

	} else if ([[root name] isEqualToString:@"dir"]) {
		/*We have a directory so crete the directory then recursively create the files/dirs */
		NSString *posixFlags = [[root attributeForName:@"posixflags"] objectValue];

		/*Find the name of the directory*/
		NSArray *nameChildren = [root elementsForName:@"name"];
		if (!nameChildren) {
			[[[[self manager] client] client] reportError:@"Could not download directory because there was no name." ofLevel: AWEzvError];
			return NO;
		}
		NSString *name = [[nameChildren objectAtIndex:0] stringValue];

		/* Create the directory */
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		NSString *newPath = [rootPath stringByAppendingPathComponent:name];

		if (![defaultManager createDirectoryAtPath:newPath
                       withIntermediateDirectories:YES
                                        attributes:[self posixAttributesFromString:posixFlags]
                                             error:NULL]) {
			[[[[self manager] client] client] reportError:@"Could not create directory for transfer." ofLevel: AWEzvError];
			
			return NO;	
		}


		bool folderSuccess = YES;
		bool fileSuccess = YES;
		/* Now call downloadFolder for dir and file children */
		NSString *newURL = [rootURL stringByAppendingPathComponent:[name stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

		for (NSXMLElement *nextElement in [root elementsForName:@"dir"]) {
			folderSuccess = [self downloadFolder:nextElement path:newPath url:newURL];
		}
		for (NSXMLElement *nextElement in [root elementsForName:@"file"]) {
			fileSuccess = [self downloadFolder:nextElement path:newPath url:newURL];
		}
		return fileSuccess && folderSuccess;
	} else {
		[[[[self manager] client] client] reportError:@"Error, attempting to download something which is not a directory or a file." ofLevel: AWEzvError];
		
		return NO;
	}
	return NO;
}
- (void) downloadFile
{
	[self downloadURL:[NSURL URLWithString:url] toPath:localFilename];
}

#pragma mark Download Helper Methods

/*Download helpers*/
- (NSDictionary *)posixAttributesFromString:(NSString *)posixFlags
{
	NSDictionary *attributes = NULL;
	if (posixFlags) {
		NSScanner *scanner;
		unsigned tempInt;

		scanner = [NSScanner scannerWithString:posixFlags];
		[scanner scanHexInt:&tempInt];
		NSNumber *number = [NSNumber numberWithUnsignedInt:tempInt];

		attributes = [NSMutableDictionary dictionary];
		[attributes setValue:number forKey:@"NSFilePosixPermissions"];
	}
	return attributes;

}
- (BOOL) applyPermissions
{
	/*Now go through and apply the permissions*/
	if (!permissionsToApply) {
		return YES;
	}
	if ([permissionsToApply count] <= 0) {
		permissionsToApply = nil;
		return YES;
	}
	NSDictionary *attributes;
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	for (NSString *path in permissionsToApply) {
		/* code that uses the returned key */
		attributes = [permissionsToApply valueForKey:path];		
		if (![defaultManager setAttributes:attributes ofItemAtPath:path error:NULL]) {
			[[[manager client] client] reportError:[NSString stringWithFormat:@"Error applying permissions of %@ to file at %@", attributes, path] ofLevel: AWEzvError];
			[[[manager client] client] remoteCanceledFileTransfer:self];
			permissionsToApply = nil;
			return NO;
		}
	}
	permissionsToApply = nil;
	return YES;
}
- (void)downloadURL:(NSURL *)downloadURL toPath:(NSString *)path
{
	/* This should be easy.  We have a url and a location so let's download things to a location! */

	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:downloadURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
	NSString *value = @"AppleSingle";
	[theRequest addValue:value forHTTPHeaderField:@"Accept-Encoding"];
	[theRequest setHTTPShouldHandleCookies:NO];

	// create the connection with the request
	// and start loading the data
	NSURLDownload *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
	if (theDownload) {
		[currentDownloads addObject:theDownload];
		// set the destination file now
		[theDownload setDestination:path allowOverwrite:YES];
	} else {
		// inform the user that the download could not be made
		[[[manager client] client] reportError:@"Error starting download of file transfer." ofLevel: AWEzvError];
		[[[manager client] client] remoteCanceledFileTransfer:self];
	}

}

#pragma mark NSURLDownload Delegate Methods
- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[[[manager client] client] remoteCanceledFileTransfer:self];
	// inform the user
	[[[manager client] client] reportError:[NSString stringWithFormat: @"Download failed! Error - %@ %@",
	         [error localizedDescription],
	         [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]] ofLevel: AWEzvError];
}
- (void)downloadDidFinish:(NSURLDownload *)download
{
	/*This will get called even when not all of the file has been downloaded so need to check bytes received */

	/*Let's look up the local file and then decode *if* it is an AppleSingle file*/
	NSURL *itemURL = [[download request] URL];
	if ([encodedDownloads containsObject:itemURL]) {
		NSString *itemPath = [self urlToPath:itemURL];
		BOOL decoded = [self decodeAppleSingleAtPath: itemPath];
		if (!decoded) {
			[[[manager client] client] remoteCanceledFileTransfer: self];
		}
	}
	percentComplete=((float)bytesReceived/(float)size);
	BOOL success = TRUE;
	if (percentComplete >= 1.0) {
		success = [self applyPermissions];
	}
	if (success)
		[[[manager client] client] updateProgressForFileTransfer:self percent:[NSNumber numberWithFloat:percentComplete] bytesSent:[NSNumber numberWithLongLong:bytesReceived]];

	[currentDownloads removeObject:download];
}
- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
	if ([(NSString *)[headers objectForKey:@"Content-Encoding"] isEqualToString:@"AppleSingle"]) {
		[encodedDownloads addObject: [[download request] URL]];
	}
}
- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	bytesReceived=bytesReceived+length;
	percentComplete=((float)bytesReceived/(float)size);
	if (percentComplete >= 1.0) {
		/*This will prevent Adium from believing that the download is complete before possible decoding */
		return;
	}
	[[[manager client] client] updateProgressForFileTransfer:self percent:[NSNumber numberWithFloat:percentComplete] bytesSent:[NSNumber numberWithLongLong:bytesReceived]];
}

#pragma mark Encoding Helper Methods

- (NSString *)urlToPath:(NSURL *)itemURL
{
	NSString *urlString = [itemURL absoluteString];
	if ([urlString hasPrefix:url]) {
		/*Remove the base url from the string*/
		NSRange range = [urlString rangeOfString:url];
		NSString *path = [urlString substringFromIndex:(range.location + range.length)];
		path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		if (localFilename) {
			path = [localFilename stringByAppendingPathComponent:path];
			return path;
		} else {
			return NULL;
		}
	}
	return NULL;
}

- (BOOL)decodeAppleSingleAtPath:(NSString *)path
{
	/*Get NSData from path*/
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[[[manager client] client] reportError:@"AppleSingle: Could not apply permissions to file because it does not exist." ofLevel: AWEzvError];
		return NO;
	}
	NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];

	/*Declarations*/
	unsigned long length = [data length];
	size_t offset;
	struct AppleSingleFinderInfo info;
	struct AppleSingleHeader header;
	struct AppleSingleEntry entry;
	NSRange resourceRange = NSMakeRange(0, 0);
	BOOL resourceExist = NO;
	offset = 0;


	if (length < APPLE_SINGLE_HEADER_LENGTH ) {
		[[[manager client] client] reportError:@"AppleSingle: Invalid AppleSingle File." ofLevel: AWEzvError];
		return NO;
	}
	[data getBytes:&header length:APPLE_SINGLE_HEADER_LENGTH];
	offset += APPLE_SINGLE_HEADER_LENGTH;

	/* switch items to host from network byteorder*/
	header.magicNumber = ntohl(header.magicNumber);
	header.versionNumber = ntohl(header.versionNumber);
	header.numberEntries = ntohs(header.numberEntries);

	if (!(header.magicNumber == APPLE_SINGLE_MAGIC_NUMBER && header.versionNumber == APPLE_SINGLE_VERSION_NUMBER)) {
		[[[manager client] client] reportError:@"AppleSingle: Supposed AppleSingle file is not AppleSingle." ofLevel: AWEzvError];
		return NO;
	}
	/* The magicNumber and versionNumber are correct so we have an AppleSingle file */
	/*Now let's read the entries */
	for (unsigned i = 0; i < header.numberEntries; ++i)
	{
		if (length < (offset + sizeof(entry))) {
			[[[manager client] client] reportError:@"AppleSingle: Not enough reoom for declared number of entries." ofLevel: AWEzvError];
			
			return NO;
		}
		[data getBytes:&entry range: NSMakeRange(offset, sizeof(entry))];
		offset += sizeof(entry);

		/* switch items to host from network byteorder*/
		entry.entryID = ntohl(entry.entryID);
		entry.offset = ntohl(entry.offset);
		entry.length = ntohl(entry.length);
		/*Validate the entry*/
		if (entry.entryID == 0) {
			[[[manager client] client] reportError:@"AppleSingle: Invalid Entry ID of value 0." ofLevel: AWEzvError];
			return NO;
		}

		if (entry.offset > length) {
			[[[manager client] client] reportError:@"AppleSingle: Invalid AppleSingle Encoding." ofLevel: AWEzvError];
			
			return NO;
		}

		if ((entry.offset + entry.length) > length) {
			[[[manager client] client] reportError:@"AppleSingle: Invalid AppleSingle Encoding." ofLevel: AWEzvError];
			return NO;
		}
		switch(entry.entryID) {
			case AS_ENTRY_DATA_FORK:
				//NSLog(@"AS_ENTRY_DATA_FORK");
				resourceRange = NSMakeRange(entry.offset, entry.length);
				resourceExist = YES;
				break;
			case AS_ENTRY_RESOURCE_FORK:
				//NSLog(@"AS_ENTRY_RESOURCE_FORK");
				resourceRange = NSMakeRange(entry.offset, entry.length);
				resourceExist = YES;
				break;
			case AS_ENTRY_FINDER_INFO:
				//NSLog(@"AS_ENTRY_FINDER_INFO");
				[data getBytes:&info range:NSMakeRange(entry.offset, entry.length)];
				info.finderInfo.finderFlags = ntohs(info.finderInfo.finderFlags);
				break;
			case AS_ENTRY_REAL_NAME:
				// NSLog(@"AS_ENTRY_REAL_NAME");
				break;
			case AS_ENTRY_COMMENT:
				// NSLog(@"AS_ENTRY_COMMENT");
				break;
			case AS_ENTRY_ICON_BW:
				// NSLog(@"AS_ENTRY_ICON_BW");
				break;
			case AS_ENTRY_ICON_COLOR:
				// NSLog(@"AS_ENTRY_ICON_COLOR");
				break;
			case AS_ENTRY_DATE_INFO:
				// NSLog(@"AS_ENTRY_DATE_INFO");
				break;
			case AS_ENTRY_MACINTOSH_FILE_INFO:
				// NSLog(@"AS_ENTRY_MACINTOSH_FILE_INFO");
				break;
			case AS_ENTRY_PRODOS_FILE_INFO:
				// NSLog(@"AS_ENTRY_PRODOS_FILE_INFO");
				break;
			case AS_ENTRY_MSDOS_FILE_INFO:
				// NSLog(@"AS_ENTRY_MSDOS_FILE_INFO");
				break;
			case AS_ENTRY_AFP_SHORT_NAME:
				// NSLog(@"AS_ENTRY_AFP_SHORT_NAME");
				break;
			case AS_ENTRY_AFP_FILE_INFO:
				// NSLog(@"AS_ENTRY_AFP_FILE_INFO");
				break;
			case AS_ENTRY_AFP_DIRECTORY_ID:
				// NSLog(@"AS_ENTRY_AFP_DIRECTORY_ID");
				break;
			default:
				// NSLog(@"default");
				break;
		}
	}

	/*Now we can write the date and apply the attributes */
	if (resourceExist) {
		NSData *decodedData = [data subdataWithRange: resourceRange];
		if (![decodedData writeToFile: path atomically:YES]) {
			[[[manager client] client] reportError:@"AppleSingle: Could not write decoded data." ofLevel: AWEzvError];
			
		}
		/*Now apply attributes */
		FSRef ref;
		OSStatus err;
		Boolean isDirectory = NO;
		err = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &ref, &isDirectory);
		if (err != noErr) {
			[[[manager client] client] reportError:@"AppleSingle: Error creating FSRef" ofLevel: AWEzvError];
			
			return NO;
		}
		struct FSCatalogInfo catalogInfo;
		memset(&catalogInfo, 0, sizeof(catalogInfo));
		Size byteCount = sizeof(info.finderInfo);
		if(byteCount > 0)
		    memmove(&(info.finderInfo), &(catalogInfo.finderInfo), byteCount);
		OSErr error = FSSetCatalogInfo(/*(const FSRef *)*/ &ref,
		                               /*(FSCatalogInfoBitmap)*/ (kFSCatInfoFinderInfo),
		                               /*(const FSCatalogInfo *)*/ &catalogInfo);
		if (error != noErr) {
			[[[manager client] client] reportError:@"AppleSingle: Error setting catalog info." ofLevel: AWEzvError];
			
			return NO;
		}
	}
	return YES;
}

@end
