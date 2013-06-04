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

#import "ESFileTransferController.h"
#import <Adium/ESFileTransfer.h>

@class ESFileTransfer, ESFileTransferProgressView;

@interface ESFileTransferProgressRow : NSObject<FileTransferDelegate> {
	ESFileTransfer			*fileTransfer;
	id						owner;

	UInt32					lastUpdateTick;
	unsigned long long		lastBytesSent;
	unsigned long long		size;
	NSString				*sizeString;
	BOOL					forceUpdate;
	
	NSMutableArray			*bytesSentQueue;
	NSMutableArray			*updateTickQueue;
	
	IBOutlet				ESFileTransferProgressView	*view;
}

+ (ESFileTransferProgressRow *)rowForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)owner;

- (IBAction)stopResumeAction:(id)sender;
- (IBAction)revealAction:(id)sender;
- (IBAction)openFileAction:(id)sender;

- (ESFileTransfer *)fileTransfer;
- (ESFileTransferProgressView *)view;

- (void)fileTransferProgressView:(ESFileTransferProgressView *)inView
			   heightChangedFrom:(CGFloat)oldHeight
							  to:(CGFloat)newHeight;

- (AIFileTransferType)type;

- (NSMenu *)menuForEvent:(NSEvent *)theEvent;

@end
