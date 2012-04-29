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

#import "ESFileTransferProgressRow.h"
#import "ESFileTransferProgressView.h"
#import "ESFileTransferProgressWindowController.h"
#import <Adium/AIListObject.h>
#import <Adium/AIUserIcons.h>
#import "ESFileTransfer.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define	BYTES_RECEIVED		[NSString stringWithFormat:AILocalizedString(@"%@ received","%@ will be replaced by a string such as '5 MB' in the file transfer window"),bytesString]
#define	BYTES_SENT			[NSString stringWithFormat:AILocalizedString(@"%@ sent","%@ will be replaced by a string such as '5 MB' in the file transfer window"),bytesString]
#define	BUFFER_SIZE			25

@interface ESFileTransferProgressRow ()
- (NSString *)readableTimeForSecs:(NSTimeInterval)secs inLongFormat:(BOOL)longFormat;
- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)owner;
- (void)updateIconImage;
- (void)updateSourceAndDestination;
@end

@implementation ESFileTransferProgressRow

+ (ESFileTransferProgressRow *)rowForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)inOwner
{
	return [[ESFileTransferProgressRow alloc] initForFileTransfer:inFileTransfer withOwner:inOwner];
}

- (id)initForFileTransfer:(ESFileTransfer *)inFileTransfer withOwner:(id)inOwner
{
	if ((self = [super init])) {
		sizeString = nil;
		forceUpdate = NO;

		fileTransfer = inFileTransfer;
		[fileTransfer setDelegate:self];

		owner = inOwner;
		
		bytesSentQueue = [[NSMutableArray alloc] init];
		updateTickQueue = [[NSMutableArray alloc] init];

		[NSBundle loadNibNamed:@"ESFileTransferProgressView" owner:self];
	}
	
	return self;
}

- (void)dealloc
{
	[fileTransfer setDelegate:nil];
}

- (ESFileTransfer *)fileTransfer
{
	return fileTransfer;
}

- (ESFileTransferProgressView *)view
{	
	return view;
}

- (void)awakeFromNib
{	
	//If we already know something about this file transfer, update since we missed delegate calls
	[self fileTransfer:fileTransfer didSetSize:[fileTransfer size]];
	[self fileTransfer:fileTransfer didSetLocalFilename:[fileTransfer localFilename]];
	[self fileTransfer:fileTransfer didSetType:[fileTransfer fileTransferType]];

	//This always calls gotUpdate and display, so do it last
	[self fileTransfer:fileTransfer didSetStatus:[fileTransfer status]];

	//Once we've set up some basic information, tell our owner it can add the view
	[owner progressRowDidAwakeFromNib:self];
	/*
	[self performSelector:@selector(informOfAwakefromNib)
			   withObject:nil
			   afterDelay:0];
	 */
}

- (void)informOfAwakefromNib
{
	//Once we've set up some basic information, tell our owner it can add the view
	[owner progressRowDidAwakeFromNib:self];
}


- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetType:(AIFileTransferType)type
{
	[self updateSourceAndDestination];
	[self updateIconImage];
	
	[owner progressRowDidChangeType:self];
}

- (AIFileTransferType)type
{
	return [fileTransfer fileTransferType];
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetSize:(unsigned long long)inSize
{
	size = inSize;
	
	sizeString = [adium.fileTransferController stringForSize:size];
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetLocalFilename:(NSString *)inLocalFilename
{
	NSString	*filename = [inLocalFilename lastPathComponent];
	
	//If we don't have a local file name, try to use the remote file name.
	if (!filename) filename = [[inFileTransfer remoteFilename] lastPathComponent];
	
	[view setFileName:filename];

	[self updateIconImage];
}

- (void)fileTransfer:(ESFileTransfer *)inFileTransfer didSetStatus:(AIFileTransferStatus)inStatus
{
	forceUpdate = YES;
	[self gotUpdateForFileTransfer:inFileTransfer];
	
	[owner progressRowDidChangeStatus:self];
	
	[[view window] display];
	forceUpdate = NO;
}

//Handle progress, bytes transferred/bytes total, rate, and time remaining
- (void)gotUpdateForFileTransfer:(ESFileTransfer *)inFileTransfer
{
	UInt32				updateTick = TickCount();
	AIFileTransferStatus	status = [inFileTransfer status];
	
	//Don't update continously; on a LAN transfer, for instance, we'll get almost constant updates
	if (lastUpdateTick && (((updateTick - lastUpdateTick) / 60.0) < 0.2) && (status == In_Progress_FileTransfer) && !forceUpdate) {
		return;
	}

	unsigned long long	bytesSent = [inFileTransfer bytesSent];
	NSString			*transferBytesStatus = nil, *transferSpeedStatus = nil, *transferRemainingStatus = nil;
	AIFileTransferType	type = [inFileTransfer fileTransferType];
	
	if (!size) {
		size = [inFileTransfer size];
		
		sizeString = [adium.fileTransferController stringForSize:size];
	}

	switch (status) {
		case Unknown_Status_FileTransfer:
		case Not_Started_FileTransfer:
		case Accepted_FileTransfer:
		case Waiting_on_Remote_User_FileTransfer:
		case Connecting_FileTransfer:
			[view setProgressIndeterminate:YES];
			[view setProgressAnimation:YES];
			transferSpeedStatus = AILocalizedString(@"Waiting to start.","waiting to begin a file transfer status");
			break;
		case Checksumming_Filetransfer:
			[view setProgressIndeterminate:YES];
			[view setProgressAnimation:YES];
			transferSpeedStatus = [AILocalizedString(@"Preparing file","waiting to begin a file transfer status") stringByAppendingEllipsis];
			break;
		case In_Progress_FileTransfer:
			[view setProgressIndeterminate:NO];
			[view setProgressDoubleValue:[inFileTransfer percentDone]];
			break;
		case Complete_FileTransfer:
			[view setProgressVisible:NO];
            [view setButtonStopResumeVisible:NO];
			transferSpeedStatus = AILocalizedString(@"Complete",nil);
			break;
		case Cancelled_Local_FileTransfer:
		    [view setProgressVisible:NO];
			if (type == Outgoing_FileTransfer) {
	            [view setButtonStopResumeIsResend:YES];
			} else {
				//can't resend what wasn't ours
				[view setButtonStopResumeVisible:NO];
			}
			transferSpeedStatus = AILocalizedString(@"Stopped",nil);
			break;
		case Cancelled_Remote_FileTransfer:
			[view setProgressVisible:NO];
			[view setButtonStopResumeVisible:NO];
			transferSpeedStatus = AILocalizedString(@"Stopped",nil);
			break;
		case Failed_FileTransfer:
			[view setProgressVisible:NO];
			[view setButtonStopResumeIsResend:YES];
			transferSpeedStatus = AILocalizedString(@"Failed",nil);
			break;
	}

	if (type == Unknown_FileTransfer) {
		transferBytesStatus = [AILocalizedString(@"Initiating file transfer",nil) stringByAppendingEllipsis];

	} else {		
		switch (status) {
			case Unknown_Status_FileTransfer:
			case Not_Started_FileTransfer:
				transferBytesStatus = [AILocalizedString(@"Initiating file transfer",nil) stringByAppendingEllipsis];
				break;
			case Checksumming_Filetransfer:
				transferBytesStatus = [AILocalizedString(@"Preparing file transfer","File transfer preparing status description") stringByAppendingEllipsis];
				break;
			case Waiting_on_Remote_User_FileTransfer:
				transferBytesStatus = [AILocalizedString(@"Waiting for transfer to be accepted","File transfer waiting on remote user status description") stringByAppendingEllipsis];
				break;
			case Connecting_FileTransfer:
				transferBytesStatus = [AILocalizedString(@"Establishing file transfer connection","File transfer connecting status description") stringByAppendingEllipsis];
				break;
			case Accepted_FileTransfer:
				transferBytesStatus = [AILocalizedString(@"Accepted file transfer",nil) stringByAppendingEllipsis];
			break;
			case In_Progress_FileTransfer:
			{
				NSString			*bytesString = [adium.fileTransferController stringForSize:bytesSent
																							  of:size
																						ofString:sizeString];

				switch (type) {
					case Incoming_FileTransfer:
						transferBytesStatus = BYTES_RECEIVED;
						break;
					case Outgoing_FileTransfer:
						transferBytesStatus = BYTES_SENT;
						break;
					default:
						break;
				}
				
				break;
			}
			case Complete_FileTransfer:
			{
				NSString			*bytesString = sizeString;
				switch (type) {
					case Incoming_FileTransfer:
						transferBytesStatus = BYTES_RECEIVED;
						break;
					case Outgoing_FileTransfer:
						transferBytesStatus = BYTES_SENT;
						break;
					default:
						break;
				}
				
				break;
			}
			case Cancelled_Local_FileTransfer:
				transferBytesStatus = AILocalizedString(@"Cancelled","File transfer cancelled locally status description");
				break;
			case Cancelled_Remote_FileTransfer:
				transferBytesStatus = AILocalizedString(@"Remote contact cancelled","File transfer cancelled remotely status description");
				break;
			case Failed_FileTransfer:
				transferBytesStatus = AILocalizedString(@"Failed","File transfer failed status description");
				break;
			default: 
				break;
		}
	}
	
	if ((status == In_Progress_FileTransfer) && lastUpdateTick && lastBytesSent) {
		if (updateTick != lastUpdateTick) {
			if ([bytesSentQueue count] == 0) {
				[bytesSentQueue insertObject:[NSNumber numberWithUnsignedLongLong:lastBytesSent] atIndex:0];
				[updateTickQueue insertObject:[NSNumber numberWithUnsignedLong:lastUpdateTick] atIndex:0];
			} else if ([bytesSentQueue count] >= BUFFER_SIZE) {
				[bytesSentQueue removeObjectAtIndex:0];
				[updateTickQueue removeObjectAtIndex:0];
			}
			
			[bytesSentQueue addObject:[NSNumber numberWithUnsignedLongLong:bytesSent]];
			[updateTickQueue addObject:[NSNumber numberWithUnsignedLong:updateTick]];
			
			unsigned long long	bytesDifference = bytesSent - [[bytesSentQueue objectAtIndex:0] unsignedLongLongValue];
			unsigned long		ticksDifference = updateTick - [[updateTickQueue objectAtIndex:0] unsignedLongValue];
			unsigned long long	rate = bytesDifference / (ticksDifference / 60.0);
			
			transferSpeedStatus = [NSString stringWithFormat:AILocalizedString(@"%@/sec","Rate of transfer phrase. %@ will be replaced by an abbreviated data amount such as 4 KB or 1 MB"),[adium.fileTransferController stringForSize:rate]];
			
			if (rate > 0) {
				unsigned long long secsRemaining = ((size - bytesSent) / rate);
				transferRemainingStatus = [NSString stringWithFormat:AILocalizedString(@"%@ remaining","Time remaining for a file transfer to be completed phrase. %@ will be replaced by an amount of time such as '5 seconds' or '4 minutes and 30 seconds'."),[self readableTimeForSecs:secsRemaining inLongFormat:YES]];
			} else {
				transferRemainingStatus = AILocalizedString(@"Stalled","file transfer is stalled status message");
			}
		}
	}
	
	[view setTransferBytesStatus:transferBytesStatus
				 remainingStatus:transferRemainingStatus
					 speedStatus:transferSpeedStatus];
	[view setNeedsDisplay:YES];

	lastBytesSent = bytesSent;
	lastUpdateTick = updateTick;
}

- (void)updateIconImage
{
	NSImage	*iconImage;

	if ((iconImage = [fileTransfer iconImage])) {
		[view setIconImage:iconImage];		
	}
}

- (void)updateSourceAndDestination
{	
	AIListObject	*source = [fileTransfer source];
	AIListObject	*destination = [fileTransfer destination];
	
	[view setSourceName:source.formattedUID];
	[view setSourceIcon:[AIUserIcons menuUserIconForObject:source]];
	
	[view setDestinationName:destination.formattedUID];
	[view setDestinationIcon:[AIUserIcons menuUserIconForObject:destination]];
}

//Button actions
#pragma mark Button actions
- (IBAction)stopResumeAction:(id)sender
{
    if ([view buttonStopResumeIsResend]) {
        [adium.fileTransferController sendFile:[fileTransfer localFilename] toListContact:[fileTransfer contact]];
		[owner _removeFileTransferRow:self];
    } else {
        [fileTransfer cancel];
    }
}

- (IBAction)revealAction:(id)sender
{
	[fileTransfer reveal];	
}
- (IBAction)openFileAction:(id)sender
{
	if ([fileTransfer status] == Complete_FileTransfer) {
		[fileTransfer openFile];
	}
}
- (void)removeRowAction:(id)sender
{
	if ([fileTransfer isStopped]) {
		[owner _removeFileTransferRow:self];
	}
}

#pragma mark Contextual menu
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu		*contextualMenu = [[NSMenu alloc] init];
	NSMenuItem  *menuItem;
	
	//Allow open and show in finder on complete incoming transfers and all outgoing transfers
	if (([fileTransfer status] == Complete_FileTransfer) ||
	   ([fileTransfer fileTransferType] == Outgoing_FileTransfer)) {
		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Open",nil)
																		 target:self
																		 action:@selector(openFileAction:)
																  keyEquivalent:@""];
		[contextualMenu addItem:menuItem];

		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Show in Finder",nil)
																		 target:self
																		 action:@selector(revealAction:)
																  keyEquivalent:@""];
		[contextualMenu addItem:menuItem];
		
	}	

	if ([fileTransfer isStopped]) {
		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Remove from List",nil)
																		 target:self
																		 action:@selector(removeRowAction:)
																  keyEquivalent:@""];
		[contextualMenu addItem:menuItem];	
	} else {
		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Cancel",nil)
																		 target:self
																		 action:@selector(stopResumeAction:)
																  keyEquivalent:@""];
		[contextualMenu addItem:menuItem];
	}	
	
	return contextualMenu;
}

//Pass height change information on to our owner
- (void)fileTransferProgressView:(ESFileTransferProgressView *)inView
			   heightChangedFrom:(CGFloat)oldHeight
							 to:(CGFloat)newHeight
{
	[owner fileTransferProgressRow:self
				 heightChangedFrom:oldHeight
								to:newHeight];
}

#pragma mark Localized readable values
//From Colloquy
- (NSString *)readableTimeForSecs:(NSTimeInterval)secs inLongFormat:(BOOL)longFormat
{
	NSUInteger i = 0, stop = 0;
	NSDictionary *desc = [NSDictionary dictionaryWithObjectsAndKeys:AILocalizedString( @"second", "singular second" ), [NSNumber numberWithUnsignedInteger:1], AILocalizedString( @"minute", "singular minute" ), [NSNumber numberWithUnsignedInteger:60], AILocalizedString( @"hour", "singular hour" ), [NSNumber numberWithUnsignedInteger:3600], AILocalizedString( @"day", "singular day" ), [NSNumber numberWithUnsignedInteger:86400], AILocalizedString( @"week", "singular week" ), [NSNumber numberWithUnsignedInteger:604800], AILocalizedString( @"month", "singular month" ), [NSNumber numberWithUnsignedInteger:2628000], AILocalizedString( @"year", "singular year" ), [NSNumber numberWithUnsignedInteger:31536000], nil];
	NSDictionary *plural = [NSDictionary dictionaryWithObjectsAndKeys:AILocalizedString( @"seconds", "plural seconds" ), [NSNumber numberWithUnsignedInteger:1], AILocalizedString( @"minutes", "plural minutes" ), [NSNumber numberWithUnsignedInteger:60], AILocalizedString( @"hours", "plural hours" ), [NSNumber numberWithUnsignedInteger:3600], AILocalizedString( @"days", "plural days" ), [NSNumber numberWithUnsignedInteger:86400], AILocalizedString( @"weeks", "plural weeks" ), [NSNumber numberWithUnsignedInteger:604800], AILocalizedString( @"months", "plural months" ), [NSNumber numberWithUnsignedInteger:2628000], AILocalizedString( @"years", "plural years" ), [NSNumber numberWithUnsignedInteger:31536000], nil];
	NSDictionary *use = nil;
	NSMutableArray *breaks = nil;
	NSUInteger val = 0;
	NSString *retval = nil;
	
	if ( secs < 0 ) secs *= -1;
	
	breaks = [[desc allKeys] mutableCopy];
	[breaks sortUsingSelector:@selector( compare: )];
	
	while ( i < [breaks count] && secs >= (NSTimeInterval) [[breaks objectAtIndex:i] unsignedIntegerValue] ) i++;
	if ( i > 0 ) i--;
	stop = [[breaks objectAtIndex:i] unsignedIntegerValue];
	
	val = (NSUInteger) ( secs / stop );
	use = ( val != 1 ? plural : desc );
	retval = [NSString stringWithFormat:@"%lu %@", val, [use objectForKey:[NSNumber numberWithUnsignedInteger:stop]]];
	if ( longFormat && i > 0 ) {
		NSUInteger rest = (NSUInteger) ( (NSUInteger) secs % stop );
		stop = [[breaks objectAtIndex:--i] unsignedIntegerValue];
		rest = (NSUInteger) ( rest / stop );
		if ( rest > 0 ) {
			use = ( rest > 1 ? plural : desc );
			retval = [retval stringByAppendingFormat:@" %lu %@", rest, [use objectForKey:[breaks objectAtIndex:i]]];
		}
	}
	
	return retval;
}

@end
