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
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIBundleAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

//Should only be YES for testing
#define	ALLOW_UNTRUSTED_XTRAS	NO

@interface XtrasInstaller ()
- (void)closeInstaller;
- (void)updateInfoText;
@end

/*!
 * @class XtrasInstaller
 * @brief Class which displays a progress window and downloads an AdiumXtra, decompresses it, and installs it.
 */
@implementation XtrasInstaller

//XtrasInstaller does not autorelease because it will release itself when closed
+ (XtrasInstaller *)installer
{
	return [[XtrasInstaller alloc] init];
}

- (id)init
{
	if ((self = [super init])) {
		download = nil;
		window = nil;
	}

	return self;
}

- (void)dealloc
{
	[download release];

	[super dealloc];
}

- (IBAction)cancel:(id)sender;
{
	if (download) [download cancel];
	[self closeInstaller];
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[self cancel:nil];
}

- (void)closeInstaller
{
	if (window) [window close];
	[self autorelease];	
}

- (void)installXtraAtURL:(NSURL *)url
{
	if ([[url host] isEqualToString:@"www.adiumxtras.com"] || ALLOW_UNTRUSTED_XTRAS) {
		NSURL	*urlToDownload;

		[NSBundle loadNibNamed:@"XtraProgressWindow" owner:self];
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
//		dest = [NSTemporaryDirectory() stringByAppendingPathComponent:[[urlToDownload path] lastPathComponent]];
		AILogWithSignature(@"Downloading %@", urlToDownload);
		download = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:urlToDownload] delegate:self];
//		[download setDestination:dest allowOverwrite:YES];

		[urlToDownload release];

	} else {
		NSRunAlertPanel(AILocalizedString(@"Nontrusted Xtra", nil),
						AILocalizedString(@"This Xtra is not hosted by adiumxtras.com. Automatic installation is not allowed.", nil),
						AILocalizedString(@"Cancel", nil),
						nil, nil);
		[self closeInstaller];
	}
}

- (void)updateInfoText
{
	NSInteger				percentComplete = (downloadSize > 0 ? (NSUInteger)(((double)amountDownloaded / (double)downloadSize) * 100.0) : 0);
	NSString		*installText = [NSString stringWithFormat:AILocalizedString(@"Downloading %@", @"Install an Xtra; %@ is the name of the Xtra."), (xtraName ? xtraName : @"")];
	
	[infoText setStringValue:[NSString stringWithFormat:@"%@ (%lu%%)", installText, percentComplete]];
}

- (void)download:(NSURLDownload *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{	
	xtraName = [[response allHeaderFields] objectForKey:@"X-Xtraname"];
	amountDownloaded = 0;
	downloadSize = [response expectedContentLength];
	[progressBar setMaxValue:(long long)downloadSize];
	[progressBar setDoubleValue:0.0];
	AILogWithSignature(@"Beginning download of %@, which has size %ll", [response allHeaderFields], downloadSize);
	[self updateInfoText];
}

- (void)download:(NSURLDownload *)connection decideDestinationWithSuggestedFilename:(NSString *)filename
{
	NSString * downloadDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uuid]];
	[[NSFileManager defaultManager] createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
	dest = [downloadDir stringByAppendingPathComponent:filename];
	AILogWithSignature(@"Downloading to is %@", dest);
	[download setDestination:dest allowOverwrite:YES];
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
	NSString	*errorMsg;

	errorMsg = [NSString stringWithFormat:AILocalizedString(@"An error occurred while downloading this Xtra: %@.",nil),[error localizedDescription]];
	
	NSBeginAlertSheet(AILocalizedString(@"Xtra Downloading Error",nil), AILocalizedString(@"Cancel",nil), nil, nil, window, self,
					 NULL, @selector(sheetDidDismiss:returnCode:contextInfo:), nil, errorMsg);
}

- (void)downloadDidFinish:(NSURLDownload *)download {
	NSString		*lastPathComponent = [[dest lowercaseString] lastPathComponent];
	NSString		*pathExtension = [lastPathComponent pathExtension];
	BOOL			decompressionSuccess = YES, success = NO;
	
	if ([pathExtension isEqualToString:@"tgz"] || [lastPathComponent hasSuffix:@".tar.gz"]) {
		NSTask			*uncompress, *untar;

		uncompress = [[NSTask alloc] init];
		[uncompress setLaunchPath:@"/usr/bin/gunzip"];
		[uncompress setArguments:[NSArray arrayWithObjects:@"-df" , [dest lastPathComponent] ,  nil]];
		[uncompress setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];
		
		@try
		{
			[uncompress launch];
			[uncompress waitUntilExit];
		}
		@catch(id exc)
		{
			decompressionSuccess = NO;	
		}
			
		[uncompress release];
		
		if (decompressionSuccess) {
			if ([pathExtension isEqualToString:@"tgz"]) {
				dest = [[dest stringByDeletingPathExtension] stringByAppendingPathExtension:@"tar"];
			} else {
				//hasSuffix .tar.gz
				dest = [dest substringToIndex:[dest length] - 3];//remove the .gz, leaving us with .tar
			}
			
			untar = [[NSTask alloc] init];
			[untar setLaunchPath:@"/usr/bin/tar"];
			[untar setArguments:[NSArray arrayWithObjects:@"-xvf", [dest lastPathComponent], nil]];
			[untar setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];
			
			@try
			{
				[untar launch];
				[untar waitUntilExit];
			}
			@catch(id exc)
			{
				decompressionSuccess = NO;
			}
			[untar release];
		}
		
	} else if ([pathExtension isEqualToString:@"zip"]) {
		NSTask	*unzip;
		
		//First, perform the actual unzipping
		unzip = [[NSTask alloc] init];
		[unzip setLaunchPath:@"/usr/bin/unzip"];
		[unzip setArguments:[NSArray arrayWithObjects:
			@"-o",  /* overwrite */
			@"-q", /* quiet! */
			dest, /* source zip file */
			@"-d", [dest stringByDeletingLastPathComponent], /*destination folder*/
			nil]];

		[unzip setCurrentDirectoryPath:[dest stringByDeletingLastPathComponent]];

		@try
		{
			[unzip launch];
			[unzip waitUntilExit];
		}
		@catch(id exc)
		{
			decompressionSuccess = NO;			
		}
		[unzip release];

	} else {
		decompressionSuccess = NO;
	}
	
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	NSEnumerator	*fileEnumerator;

	//Delete the compressed xtra, now that we've decompressed it
#ifdef DEBUG_BUILD
	if (decompressionSuccess)
		[fileManager removeItemAtPath:dest error:NULL];
#else
	[fileManager removeItemAtPath:dest error:NULL];
#endif
	
	dest = [dest stringByDeletingLastPathComponent];
	
	//the remaining files in the directory should be the contents of the xtra
	fileEnumerator = [fileManager enumeratorAtPath:dest];

	if (decompressionSuccess && fileEnumerator) {
		NSString		*xtraPath;
		NSString		*nextFile;
		NSSet			*supportedDocumentExtensions = [[NSBundle mainBundle] supportedDocumentExtensions];

		while((nextFile = [fileEnumerator nextObject])) {
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
					xtraPath = [dest stringByAppendingPathComponent:nextFile];

					//Open the file directly
					AILogWithSignature(@"Installing %@",xtraPath);
					success = [[NSApp delegate] application:NSApp
											   openTempFile:xtraPath];

					if (!success) {
						NSLog(@"Installation Error: %@",xtraPath);
					}
				}
			}
		}
		
	} else {
		NSLog(@"Installation Error: %@ (%@)",dest, (decompressionSuccess ? @"Decompressed succesfully" : @"Failed to decompress"));
	}
	
	//delete our temporary directory, and any files remaining in it
#ifdef DEBUG_BUILD
	if (success)
		[fileManager removeFileAtPath:dest error:NULL];
#else
	[fileManager removeFileAtPath:dest error:NULL];
#endif

	[self closeInstaller];
}

@end
