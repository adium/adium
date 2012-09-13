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

#import "ESFileTransferRequestPromptController.h"
#import "ESFileTransferController.h"
#import "ESFileTransfer.h"
#import <Adium/AIListContact.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESFileTransferRequestPromptController ()
- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer
		  notifyingTarget:(id)inTarget
				 selector:(SEL)inSelector;
@end

@implementation ESFileTransferRequestPromptController

/*!
 * @brief Display a prompt for a file transfer to save, save as, or cancel
 *
 * @param inFileTransfer The file transfer
 * @param inTarget The target on which inSelector will be called
 * @param inSelector A selector, which must accept two arguments. The first will be inFileTransfer. The second will be the filename to save to, or nil to cancel.
 */
+ (void)displayPromptForFileTransfer:(ESFileTransfer *)inFileTransfer
									 notifyingTarget:(id)inTarget
											selector:(SEL)inSelector
{	
	(void)[[self alloc] initForFileTransfer:inFileTransfer
							notifyingTarget:inTarget
								   selector:inSelector];
}

- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer
		  notifyingTarget:(id)inTarget
				 selector:(SEL)inSelector
{
	if ((self = [super init])) {
		fileTransfer = inFileTransfer;
		target       = inTarget;
		selector     =  inSelector;
		
		[fileTransfer setFileTransferRequestPromptController:self];
		AILog(@"%@: Requeseting file transfer %@", self, fileTransfer);
		[adium.contentController receiveContentObject:fileTransfer];
		
		// We don't want it to be a normal event, but we DO want to increment the unviewed content count.
		[fileTransfer.chat incrementUnviewedContentCount];
	}

	return self;
}

/*!
 * @brief The user did something with the file transfer request
 */
- (void)handleFileTransferAction:(AIFileTransferAction)action
{
	
	NSString	*downloadFolder = [[[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory
																	   inDomain:NSUserDomainMask
															  appropriateForURL:nil
																		 create:NO
																		  error:NULL] path];
	NSString	*localFilename = [downloadFolder stringByAppendingPathComponent:[fileTransfer remoteFilename]];;
	BOOL		finished = NO;
	
	switch (action) {
		case AISaveFileAs: /* Save As... */
		{
			//Prompt for a location to save
			NSSavePanel *savePanel = [NSSavePanel savePanel];
			savePanel.directoryURL = [NSURL fileURLWithPath:localFilename];
			savePanel.nameFieldStringValue = [localFilename lastPathComponent];
			NSInteger returnCode = [savePanel runModal];
			//Only need to take action if the user pressed OK; if she pressed cancel, just return to our window.
			if (returnCode == NSFileHandlingPanelOKButton) {
				localFilename = savePanel.URL.path;
				finished = YES;
			}
			
			break;
		}
		case AICancel: /* Closed = Cancel */
		{
			localFilename = nil;
			/* File name remains nil and the transfer will therefore be cancelled */
			finished = YES;
			break;
		}
	}
	
	BOOL remotelyCanceled = [fileTransfer isStopped];
	if(remotelyCanceled) {
		return;
	}
	
	if (finished) {
		[target performSelector:selector
					 withObject:fileTransfer
					 withObject:localFilename];
		
		[fileTransfer setFileTransferRequestPromptController:nil];
	}
}

- (ESFileTransfer *)fileTransfer
{
	return fileTransfer;
}

@end
