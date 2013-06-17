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

#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIChat.h>

#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIBezierPathAdditions.h>

#define MAGIC_ARROW_SCALE       0.85f
#define MAGIC_ARROW_TRANSLATE_X 2.85f
#define MAGIC_ARROW_TRANSLATE_Y 0.75f

@interface ESFileTransfer ()
- (id)initWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount type:(AIFileTransferType)inType;
- (void)recreateMessage;
@end

@implementation ESFileTransfer

static NSMutableDictionary *fileTransferDict = nil;

//Init
+ (id)fileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount type:(AIFileTransferType)inType
{
    return [[[self alloc] initWithContact:inContact forAccount:inAccount type:inType] autorelease];    
}

+ (ESFileTransfer *)existingFileTransferWithID:(NSString *)fileTransferID
{
	return [[[[fileTransferDict objectForKey:fileTransferID] nonretainedObjectValue] retain] autorelease];
}

//Content Identifier
- (NSString *)type
{
    return CONTENT_FILE_TRANSFER_TYPE;
}

- (id)initWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount type:(AIFileTransferType)inType
{
	AIChat			*aChat = [adium.chatController chatWithContact:inContact];
	AIListObject	*s, *d;

	switch (inType) {
		case Outgoing_FileTransfer:
			s = inAccount;
			d = inContact;
			break;
		case Incoming_FileTransfer:
		default: //we have to pick one or the other, and we can set it correctly when they set the type
			s = inContact;
			d = inAccount;
			break;
	}
    if ((self = [super initWithChat:aChat
							 source:s
						 sourceNick:nil
						destination:d
							   date:[NSDate date]
							message:[[[NSAttributedString alloc] initWithString:@""] autorelease]
						  autoreply:NO])) {
		type = inType;
		status = Unknown_Status_FileTransfer;
		delegate = nil;

		[self recreateMessage];

		if (!fileTransferDict) fileTransferDict = [[NSMutableDictionary alloc] init];
		[fileTransferDict setObject:[NSValue valueWithNonretainedObject:self]
							 forKey:[self uniqueID]];
	}

	return self;
}

- (void)dealloc
{
	[fileTransferDict removeObjectForKey:[self uniqueID]];
	[uniqueID release];

    [remoteFilename release];
    [localFilename release];
    [accountData release];
    [promptController release];

    [super dealloc];
}

- (AIListContact *)contact
{
    return (self.fileTransferType == Incoming_FileTransfer || self.fileTransferType == Unknown_FileTransfer) ? (AIListContact *)[self source] : (AIListContact *)[self destination];   
}

- (AIAccount<AIAccount_Files> *)account
{
    return (AIAccount<AIAccount_Files> *)self.chat.account;   
}

- (void)setRemoteFilename:(NSString *)inRemoteFilename
{
    if (remoteFilename != inRemoteFilename) {
        [remoteFilename release];
        remoteFilename = [inRemoteFilename retain];
    }
	[self recreateMessage];
}

- (NSString *)remoteFilename
{
    return remoteFilename;
}

- (void)setLocalFilename:(NSString *)inLocalFilename
{
    if (localFilename != inLocalFilename) {
        [localFilename release];
        localFilename = [inLocalFilename retain];
	}
	
	if (delegate)
		[delegate fileTransfer:self didSetLocalFilename:localFilename];
}

- (NSString *)localFilename
{
    return localFilename;
}

- (NSString *)displayFilename
{
	NSString	*displayFilename = [localFilename lastPathComponent];
	
	//If we don't have a local file name, try to use the remote file name.
	if (!displayFilename) displayFilename = [remoteFilename lastPathComponent];
	
	return displayFilename;
}

- (void)setSizeWithNumber:(NSNumber *)newSize
{
	[self setSize:[newSize unsignedLongLongValue]];
}

- (void)setSize:(unsigned long long)inSize
{
    size = inSize;
	
	if (delegate)
		[delegate fileTransfer:self didSetSize:size];
	
	[self recreateMessage];
}

- (unsigned long long)size
{
    return size;
}

- (NSNumber *)sizeNumber 
{
	return [NSNumber numberWithUnsignedLongLong:size];
}

@synthesize isDirectory;

- (void)setFileTransferType:(AIFileTransferType)inType
{
	//incoming file transfers should always have a non-account as the source, and outgoing ones should always have an account as the source
	if((inType == Incoming_FileTransfer && [source isKindOfClass:[AIAccount class]]) ||
	   (inType == Outgoing_FileTransfer && [destination isKindOfClass:[AIAccount class]]))
	{
		AIListObject *temp = source;
		source = destination;
		destination = temp;
	}
    type = inType;
	
	if (delegate)
		[delegate fileTransfer:self didSetType:type];
	
	[self recreateMessage];
}

@synthesize fileTransferType = type;

- (void)setStatus:(AIFileTransferStatus)inStatus
{
	if (status != inStatus) {
		status = inStatus;
		
		[adium.fileTransferController fileTransfer:self didSetStatus:status];
		
		if (delegate)
			[delegate fileTransfer:self didSetStatus:status];
		
		//Once we're stopped, no further need for a request prompt
		if (self.isStopped) {
			self.fileTransferRequestPromptController = nil;
		}
	}
}

@synthesize status;

/*!
 * @brief Report a progress update on the file transfer
 *
 * @param inPercent The percentage complete.  If 0, inBytesSent will be used to calculate the percent complete if possible.
 * @param inBytesSent The number of bytes sent. If 0, inPercent will be used to calculate bytes sent if possible.
 */
- (void)setPercentDone:(CGFloat)inPercent bytesSent:(unsigned long long)inBytesSent
{	
	CGFloat oldPercentDone = percentDone;
	unsigned long long oldBytesSent = bytesSent;

    if (inPercent == 0) {		
        if (inBytesSent != 0 && size != 0) {
            percentDone = ((float)inBytesSent / (float)size);
		} else {
			percentDone = inPercent;
		}

    } else {
        percentDone = inPercent;
    }

    if (inBytesSent == 0) {
        if (inPercent != 0 && size != 0) {
            bytesSent = (double)inPercent * size;
		} else {
			bytesSent = inBytesSent;			
		}

    } else {

        bytesSent = inBytesSent;
	}
	if ((percentDone != oldPercentDone) || (bytesSent != oldBytesSent)) {
		if (delegate) {
			[delegate gotUpdateForFileTransfer:self];
		}
		
		if (percentDone >= 1.0) {
			[self setStatus:Complete_FileTransfer];
			
			if (type == Incoming_FileTransfer) {
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DownloadFileFinished"
																			   object:localFilename];
				
				FSRef fsRef;
				OSErr err;
				
				if (FSPathMakeRef((const UInt8 *)[localFilename fileSystemRepresentation], &fsRef, NULL) == noErr) {
					
					NSMutableDictionary *quarantineProperties = nil;
					CFTypeRef cfOldQuarantineProperties = NULL;
					
					err = LSCopyItemAttribute(&fsRef, kLSRolesAll, kLSItemQuarantineProperties, &cfOldQuarantineProperties);
					
					if (err == noErr) {
						
						if (CFGetTypeID(cfOldQuarantineProperties) == CFDictionaryGetTypeID()) {
							quarantineProperties = [[(NSDictionary *)cfOldQuarantineProperties mutableCopy] autorelease];
						} else {
							AILogWithSignature(@"Getting quarantine data failed for %@ (%@)", self, localFilename);
							return;
						}
						
						CFRelease(cfOldQuarantineProperties);
						
						if (!quarantineProperties) {
							return;
						}
						
					} else if (err == kLSAttributeNotFoundErr) {
						quarantineProperties = [NSMutableDictionary dictionaryWithCapacity:2];
					}
					
					[quarantineProperties setObject:(NSString *)kLSQuarantineTypeInstantMessageAttachment
											 forKey:(NSString *)kLSQuarantineTypeKey];
					// TODO Figure out the file URL to the transcript
//					[quarantineProperties setObject:[NSURL URLWithString:@"file:///dev/null"]
//											 forKey:(NSString *)kLSQuarantineOriginURLKey];
					
					if (LSSetItemAttribute(&fsRef, kLSRolesAll, kLSItemQuarantineProperties, quarantineProperties) != noErr) {
						AILogWithSignature(@"Danger! Quarantining file %@ failed!", localFilename);
					}
					
					AILogWithSignature(@"Quarantined %@ with %@", localFilename, quarantineProperties);
					
				} else {
					AILogWithSignature(@"Danger! Could not find file to quarantine: %@!", localFilename);
				}
			}
			
		} else if ((percentDone != 0) && (status != In_Progress_FileTransfer)) {
			[self setStatus:In_Progress_FileTransfer];
		}
	}
}

-(void)setPercentDone:(NSNumber *)percent bytes:(NSNumber *)bytes
{
	[self setPercentDone:[percent floatValue] bytesSent:[bytes unsignedLongLongValue]];
	
}

@synthesize percentDone;
@synthesize bytesSent;
@synthesize accountData;
@synthesize delegate;

- (void)cancel
{
	[self.account cancelFileTransfer:self];
}

- (void)reveal
{
	[[NSWorkspace sharedWorkspace] selectFile:localFilename
					 inFileViewerRootedAtPath:[localFilename stringByDeletingLastPathComponent]];
}

- (void)openFile
{
	[[NSWorkspace sharedWorkspace] openFile:localFilename];
}

- (NSImage *)iconImage
{
	NSImage		*iconImage = nil;
	NSString	*extension;
	NSImage		*systemIcon;

	extension = self.localFilename.pathExtension;
	
	//Fall back on the remote filename if necessary
	if (!extension || ![extension length]) extension = self.remoteFilename.pathExtension; 
	
	if (extension && [extension length]) {
		systemIcon = [[NSWorkspace sharedWorkspace] iconForFileType:extension];

	} else {
		if ([self.account canSendFolders] && [self isDirectory]){
			systemIcon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
		} else {
			systemIcon = [[NSWorkspace sharedWorkspace] iconForFile:self.localFilename];
		}
	}

	BOOL pointingDown = (type == Incoming_FileTransfer);
	BOOL drawArrow = pointingDown || (type == Outgoing_FileTransfer);
	
	// If type is Incoming (*down*load) or Outgoing (*up*load), overlay an arrow in a circle.
	iconImage = [[NSImage alloc] initWithSize:[systemIcon size]];
	
	NSRect	rect = { NSZeroPoint, [iconImage size] };
	NSRect	bottomRight = NSMakeRect(NSMidX(rect), 
									 ([iconImage isFlipped] ? NSMidY(rect) : NSMinY(rect)), 
									 (NSWidth(rect)/2.0f),
									 (NSHeight(rect)/2.0f));		
	
	[iconImage lockFocus];
	
	[systemIcon drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
	CGFloat line = ((NSWidth(bottomRight) / 15) + ((NSHeight(bottomRight) / 15) / 2));
	NSRect	circleRect = NSMakeRect(NSMinX(bottomRight),
									NSMinY(bottomRight) + (line),
									NSWidth(bottomRight) - (line),
									NSHeight(bottomRight) - (line));
	
	//draw our circle background...
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:circleRect];
	[circle setLineWidth:line];
	[[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.75f] setStroke];
	[[[NSColor alternateSelectedControlTextColor] colorWithAlphaComponent:0.75f] setFill];
	[circle fill];
	[circle stroke];
	
	//and the arrow on top of it.
	if(drawArrow) {
		NSBezierPath *arrow = [NSBezierPath bezierPathWithArrowWithShaftLengthMultiplier:2.0f];
		if(pointingDown) [arrow flipVertically];
		[arrow scaleToSize:bottomRight.size];
		
		//bring it into position.
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy:circleRect.origin.x yBy:circleRect.origin.y];
		[arrow transformUsingAffineTransform:transform];
		
		//fine-tune size.
		transform = [NSAffineTransform transform];
		[transform scaleBy:MAGIC_ARROW_SCALE];
		[arrow transformUsingAffineTransform:transform];
		
		//fine-tune position.
		transform = [NSAffineTransform transform];
		[transform translateXBy:MAGIC_ARROW_TRANSLATE_X yBy:MAGIC_ARROW_TRANSLATE_Y];
		[arrow transformUsingAffineTransform:transform];
		
		[circle addClip];
		[[NSColor alternateSelectedControlColor] setFill];
		[arrow fill];
	}
	
	[iconImage unlockFocus];

	return [iconImage autorelease];
}	

- (BOOL)isStopped
{
	return ((status == Complete_FileTransfer) ||
		   (status == Cancelled_Local_FileTransfer) ||
		   (status == Cancelled_Remote_FileTransfer) ||
			(status == Failed_FileTransfer));
}

- (void)recreateMessage
{
	NSString			*filenameDisplay;
	NSString			*rFilename = [self remoteFilename];
	if(!rFilename) rFilename = @"";
	
	//Display the name of the file, with the file's size if available
	unsigned long long fileSize = [self size];
	
	if (fileSize) {
		NSString	*fileSizeString;
		
		fileSizeString = [adium.fileTransferController stringForSize:fileSize];
		filenameDisplay = [NSString stringWithFormat:@"%@ (%@)", rFilename, fileSizeString];
	} else {
		filenameDisplay = rFilename;
	}
	
	[self setMessage:[NSAttributedString stringWithString:
		[NSString stringWithFormat:AILocalizedString(@"%@ requests to send you %@","This is displayed in the message window when prompting to receive a file. The first %@ is the sender; the second %@ is the filename of the file being sent. It will be followed by buttons such as 'Save' and 'Cancel'."),
			[[self contact] formattedUID],
			filenameDisplay]]];
	
}

@synthesize fileTransferRequestPromptController = promptController;

- (NSString *)uniqueID
{
	if (!uniqueID) {
		static unsigned long long fileTransferID = 0;

		uniqueID = [[NSString alloc] initWithFormat:@"FileTransfer-%qu",fileTransferID++];
	}

	return uniqueID;
}

#pragma mark AIContentObject
/*!
* @brief Is this content tracked with notifications?
 *
 * If NO, the content will not trigger message sent/message received events such as a sound playing.
 */
- (BOOL)trackContent
{
    return NO;
}
/*!
 * @brief Is this content passed through content filters?
 */
- (BOOL)filterContent
{
	return NO;
}
/*!
* @brief Post process this content?
 *
 * For example, this should be YES if the content is to be logged and NO if it is not.
 */
- (BOOL)postProcessContent
{
	return NO;
}
@end
