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

#import "XtrasInstaller.h"
#import <AIUtilities/AIBundleAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

//Should only be YES for testing
#define	ALLOW_UNTRUSTED_XTRAS	NO

@interface XtrasInstaller ()
- (void)closeInstaller __attribute__((ns_consumes_self));
- (void)updateInfoText;
@end

/*!
 * @class XtrasInstaller
 * @brief Class which displays a progress window and downloads an AdiumXtra, decompresses it, and installs it.
 */
@implementation XtrasInstaller

@synthesize dest, download, xtraName;

//XtrasInstaller does not autorelease because it will release itself when closed
+ (XtrasInstaller *)installer
{
	return [[XtrasInstaller alloc] init];
}

- (id)init
{
	if ((self = [super init])) {
		self.download = nil;
		window = nil;
	}

	return self;
}

- (IBAction)cancel:(id)sender;
{
	if (self.download) [self.download cancel];
	[self closeInstaller];
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[self cancel:nil];
}

- (void)closeInstaller
{
	if (window) [window close];
}

- (void)installXtraAtURL:(NSURL *)url
{
	if ([[url host] isEqualToString:@"xtras.adium.im"] || [[url host] isEqualToString:@"www.adiumxtras.com"] || ALLOW_UNTRUSTED_XTRAS) {
		NSURL	*urlToDownload;

		[[NSBundle mainBundle] loadNibNamed:@"XtraProgressWindow" owner:self topLevelObjects:nil];
		[progressBar setUsesThreadedAnimation:YES];
		
		xtraName = nil;
		amountDownloaded = 0;
		downloadSize = 0;
		
		[progressBar setDoubleValue:0];
		[cancelButton setLocalizedString:AILocalizedString(@"Cancel",nil)];
		[window setTitle:AILocalizedString(@"Xtra Download",nil)];

		[self updateInfoText];

		[window makeKeyAndOrderFront:self];

		urlToDownload = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@://%@/%@%@%@", @"http", [url host], [url path],
													   ([url query] ? @"?" : @""),
													   ([url query] ? [url query] : @"")]];
		AILogWithSignature(@"Downloading %@", urlToDownload);
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlToDownload];
		[request setHTTPShouldHandleCookies:NO];
		self.download = [[NSURLDownload alloc] initWithRequest:request delegate:self];

	} else {
		NSRunAlertPanel(AILocalizedString(@"Nontrusted Xtra", nil),
						AILocalizedString(@"This Xtra is not hosted on the Adium Xtras website. Automatic installation is not allowed.", nil),
						AILocalizedString(@"Cancel", nil),
						nil, nil);
		[self closeInstaller];
	}
}

- (void)updateInfoText
{
	NSInteger				percentComplete = (downloadSize > 0 ? (NSUInteger)(((double)amountDownloaded / (double)downloadSize) * 100.0) : 0);
	NSString		*installText = [NSString stringWithFormat:AILocalizedString(@"Downloading %@", @"Install an Xtra; %@ is the name of the Xtra."), (self.xtraName ? self.xtraName : @"")];
	
	[infoText setStringValue:[NSString stringWithFormat:@"%@ (%lu%%)", installText, percentComplete]];
}

- (void)download:(NSURLDownload *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{	
	self.xtraName = [[response allHeaderFields] objectForKey:@"X-Xtraname"];
	amountDownloaded = 0;
	downloadSize = [response expectedContentLength];
	[progressBar setMaxValue:downloadSize];
	[progressBar setDoubleValue:0.0];
	AILogWithSignature(@"Beginning download of %@, which has size %lld", [response allHeaderFields], downloadSize);
	[self updateInfoText];
}

- (void)download:(NSURLDownload *)connection decideDestinationWithSuggestedFilename:(NSString *)filename
{
	NSString * downloadDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uuid]];
	[[NSFileManager defaultManager] createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
	self.dest = [downloadDir stringByAppendingPathComponent:filename];
	AILogWithSignature(@"Downloading to is %@", self.dest);
	[self.download setDestination:self.dest allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	amountDownloaded += (long long)length;
	if (downloadSize != NSURLResponseUnknownLength) {
		[progressBar setDoubleValue:(double)amountDownloaded];
		[self updateInfoText];
	}
	else
		[progressBar setIndeterminate:YES];
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
    return NO;
}

- (void)download:(NSURLDownload *)inDownload didFailWithError:(NSError *)error {
	NSBeginAlertSheet(AILocalizedString(@"Xtra Downloading Error",nil), AILocalizedString(@"Cancel",nil), nil, nil, window, self,
					 NULL, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, AILocalizedString(@"An error occurred while downloading this Xtra: %@.",nil), [error localizedDescription]);
}

- (void)setQuarantineProperties:(NSDictionary *)dict forDirectory:(FSRef *)dir
{
	FSIterator iterator;
	
	if (FSOpenIterator(dir, kFSIterateFlat, &iterator) != noErr) {
		AILogWithSignature(@"Error quarantining %p", dir);
	}
	
	FSRef ref;
	ItemCount num;
	
	while (FSGetCatalogInfoBulk(iterator, 1, &num, NULL, kFSCatInfoNone, NULL, &ref, NULL, NULL) == noErr)
	{
		LSSetItemAttribute(&ref, kLSRolesAll, kLSItemQuarantineProperties, (__bridge void *) dict);
		
		FSCatalogInfo catinfo;
		FSGetCatalogInfo(&ref, kFSCatInfoNodeFlags, &catinfo, NULL, NULL, NULL);
		
		if(catinfo.nodeFlags & kFSNodeIsDirectoryMask) {
			[self setQuarantineProperties:dict forDirectory:&ref];
		}
	}
	
	FSCloseIterator(iterator);
}

- (void)downloadDidFinish:(NSURLDownload *)inDownload {
	NSString		*lastPathComponent = [self.dest lastPathComponent];
	NSString		*pathExtension = [[lastPathComponent pathExtension] lowercaseString];
	BOOL			decompressionSuccess = YES, success = NO;
	
	if ([pathExtension isEqualToString:@"tgz"] || [lastPathComponent hasSuffix:@".tar.gz"]) {
		NSTask			*uncompress, *untar;

		uncompress = [[NSTask alloc] init];
		[uncompress setLaunchPath:@"/usr/bin/gunzip"];
		[uncompress setArguments:[NSArray arrayWithObjects:@"-df" , [self.dest lastPathComponent] ,  nil]];
		[uncompress setCurrentDirectoryPath:[self.dest stringByDeletingLastPathComponent]];
		
		@try
		{
			[uncompress launch];
			[uncompress waitUntilExit];
		}
		@catch(id exc)
		{
			decompressionSuccess = NO;	
		}
		
		if (decompressionSuccess) {
			if ([pathExtension isEqualToString:@"tgz"]) {
				self.dest = [[self.dest stringByDeletingPathExtension] stringByAppendingPathExtension:@"tar"];
			} else {
				//hasSuffix .tar.gz
				self.dest = [self.dest substringToIndex:[self.dest length] - 3];//remove the .gz, leaving us with .tar
			}
			
			untar = [[NSTask alloc] init];
			[untar setLaunchPath:@"/usr/bin/tar"];
			[untar setArguments:[NSArray arrayWithObjects:@"-xvf", [self.dest lastPathComponent], nil]];
			[untar setCurrentDirectoryPath:[self.dest stringByDeletingLastPathComponent]];
			
			@try
			{
				[untar launch];
				[untar waitUntilExit];
			}
			@catch(id exc)
			{
				decompressionSuccess = NO;
			}
		}
		
	} else if ([pathExtension isEqualToString:@"zip"]) {
		NSTask	*unzip;
		
		//First, perform the actual unzipping
		unzip = [[NSTask alloc] init];
		[unzip setLaunchPath:@"/usr/bin/unzip"];
		[unzip setArguments:[NSArray arrayWithObjects:
			@"-o",  /* overwrite */
			@"-q", /* quiet! */
			self.dest, /* source zip file */
			@"-d", [self.dest stringByDeletingLastPathComponent], /*destination folder*/
			nil]];

		[unzip setCurrentDirectoryPath:[self.dest stringByDeletingLastPathComponent]];

		@try
		{
			[unzip launch];
			[unzip waitUntilExit];
		}
		@catch(id exc)
		{
			decompressionSuccess = NO;			
		}

	} else {
		decompressionSuccess = NO;
	}
	
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	NSEnumerator	*fileEnumerator;

	//Delete the compressed xtra, now that we've decompressed it
#ifdef DEBUG_BUILD
	if (decompressionSuccess)
		[fileManager removeItemAtPath:self.dest error:NULL];
#else
	[fileManager removeItemAtPath:self.dest error:NULL];
#endif
	
	self.dest = [self.dest stringByDeletingLastPathComponent];
	
	FSRef fsRef;
	OSStatus err;
	
	if (FSPathMakeRef((const UInt8 *)[self.dest fileSystemRepresentation], &fsRef, NULL) == noErr) {
		
		NSMutableDictionary *quarantineProperties = nil;
		CFTypeRef cfOldQuarantineProperties = NULL;
		
		err = LSCopyItemAttribute(&fsRef, kLSRolesAll, kLSItemQuarantineProperties, &cfOldQuarantineProperties);
		
		if (err == noErr) {
			
			if (CFGetTypeID(cfOldQuarantineProperties) == CFDictionaryGetTypeID()) {
				quarantineProperties = [(__bridge NSDictionary *)cfOldQuarantineProperties mutableCopy];
			} else {
				AILogWithSignature(@"Getting quarantine data failed for %@ (%@)", self, self.dest);
				[self closeInstaller];
				return;
			}
			
			CFRelease(cfOldQuarantineProperties);
			
			if (!quarantineProperties) {
				[self closeInstaller];
				return;
			}
			
			AILogWithSignature(@"Old quarantine data: %@", quarantineProperties);
			
		} else if (err == kLSAttributeNotFoundErr) {
			quarantineProperties = [NSMutableDictionary dictionaryWithCapacity:2];
		}
		
		[quarantineProperties setObject:(NSString *)kLSQuarantineTypeWebDownload
								 forKey:(NSString *)kLSQuarantineTypeKey];
		
		[quarantineProperties setObject:[[self.download request] URL]
								 forKey:(NSString *)kLSQuarantineDataURLKey];
		
		[self setQuarantineProperties:quarantineProperties forDirectory:&fsRef];
		
		AILogWithSignature(@"Quarantined %@ with %@", self.dest, quarantineProperties);
		
	} else {
		AILogWithSignature(@"Danger! Could not find file to quarantine: %@!", self.dest);
	}
	
	//the remaining files in the directory should be the contents of the xtra
	fileEnumerator = [fileManager enumeratorAtPath:self.dest];

	if (decompressionSuccess && fileEnumerator) {
		NSSet			*supportedDocumentExtensions = [[NSBundle mainBundle] supportedDocumentExtensions];

		for (NSString *nextFile in fileEnumerator) {
			
			/* Ignore hidden files and the __MACOSX folder which some compression engines stick into the archive but
			 * /usr/bin/unzip doesn't handle properly.
			 */
			if ((![[nextFile lastPathComponent] hasPrefix:@"."]) &&
				(![[nextFile pathComponents] containsObject:@"__MACOSX"])) {
				NSString		*fileExtension = [nextFile pathExtension];
				NSEnumerator	*supportedDocumentExtensionsEnumerator;
				NSString		*extension;
				BOOL			isSupported = NO;

				//We want to do a case-insensitive path extension comparison
				supportedDocumentExtensionsEnumerator = [supportedDocumentExtensions objectEnumerator];
				while (!isSupported &&
					   (extension = [supportedDocumentExtensionsEnumerator nextObject])) {
					isSupported = ([fileExtension caseInsensitiveCompare:extension] == NSOrderedSame);
				}

				if (isSupported) {
					NSString *xtraPath = [self.dest stringByAppendingPathComponent:nextFile];

					//Open the file directly
					AILogWithSignature(@"Installing %@",xtraPath);
					success = [[[NSApplication sharedApplication] delegate] application:NSApp
																		   openTempFile:xtraPath];

					if (!success) {
						NSLog(@"Installation Error: %@",xtraPath);
					}
				}
			}
		}
		
	} else {
		NSLog(@"Installation Error: %@ (%@)",self.dest, (decompressionSuccess ? @"Decompressed succesfully" : @"Failed to decompress"));
	}
	
	//delete our temporary directory, and any files remaining in it
#ifdef DEBUG_BUILD
	if (success)
		[fileManager removeItemAtPath:self.dest error:NULL];
#else
	[fileManager removeItemAtPath:self.dest error:NULL];
#endif

	[self closeInstaller];
}

@end
