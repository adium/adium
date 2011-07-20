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

#import "adiumPurpleFt.h"
#import <AIUtilities/AIObjectAdditions.h>

static void adiumPurpleNewXfer(PurpleXfer *xfer)
{
	
}

static void adiumPurpleDestroy(PurpleXfer *xfer)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	[accountLookup(xfer->account) destroyFileTransfer:fileTransfer];
	
	xfer->ui_data = nil;
    [pool drain];
}

static void adiumPurpleAddXfer(PurpleXfer *xfer)
{
	
}

static void adiumPurpleUpdateProgress(PurpleXfer *xfer, double percent)
{	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
	
	if (fileTransfer) {
		[accountLookup(xfer->account) updateProgressForFileTransfer:fileTransfer
															percent:[NSNumber numberWithDouble:percent]
														  bytesSent:[NSNumber numberWithUnsignedLong:xfer->bytes_sent]];
	}
    [pool drain];
}

static void adiumPurpleCancelLocal(PurpleXfer *xfer)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	AILog(@"adiumPurpleCancelLocal");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) fileTransferCancelledLocally:fileTransfer];
    [pool drain];
}

static void adiumPurpleCancelRemote(PurpleXfer *xfer)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	AILog(@"adiumPurpleCancelRemote");
	ESFileTransfer *fileTransfer = (ESFileTransfer *)xfer->ui_data;
    [accountLookup(xfer->account) fileTransferCancelledRemotely:fileTransfer];
    [pool drain];
}

static PurpleXferUiOps adiumPurpleFileTransferOps = {
    adiumPurpleNewXfer,
    adiumPurpleDestroy,
    adiumPurpleAddXfer,
    adiumPurpleUpdateProgress,
    adiumPurpleCancelLocal,
    adiumPurpleCancelRemote,
	
	/* ui_write */ NULL,
	/* ui_read */ NULL,
	/* data_not_sent */ NULL,
	/* reserved 1 */ NULL
};

PurpleXferUiOps *adium_purple_xfers_get_ui_ops()
{
	return &adiumPurpleFileTransferOps;
}
