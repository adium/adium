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

#import "AIOSCompatibility.h"

@interface XtrasInstaller : NSObject <NSURLDownloadDelegate> {
	IBOutlet NSWindow				*window;
	IBOutlet NSProgressIndicator	*progressBar;
	IBOutlet NSTextField			*infoText;
	IBOutlet NSButton				*cancelButton;
	
	NSURLDownload					*download;
	NSString						*dest;
	NSString						*xtraName;

	long long downloadSize;
	long long amountDownloaded;
}

-(IBAction)cancel:(id)sender;
-(void)installXtraAtURL:(NSURL *)url __attribute__((ns_consumes_self));
+(XtrasInstaller *)installer __attribute__((objc_method_family(new)));

@property (retain) NSURLDownload *download;
@property (retain) NSString *dest;
@property (retain) NSString *xtraName;

@end
