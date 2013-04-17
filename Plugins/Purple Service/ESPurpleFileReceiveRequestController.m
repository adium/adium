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

#import "ESPurpleFileReceiveRequestController.h"
#import "adiumPurpleRequest.h"
#import "CBPurpleAccount.h"
#import <Adium/AIWindowController.h>
#import <Adium/ESFileTransfer.h>

@interface ESPurpleFileReceiveRequestController ()
- (id)initWithDict:(NSDictionary *)inDict;
@end

@implementation ESPurpleFileReceiveRequestController

+ (ESPurpleFileReceiveRequestController *)showFileReceiveWindowWithDict:(NSDictionary *)inDict
{
	return [[self alloc] initWithDict:inDict];
}

- (id)initWithDict:(NSDictionary *)inDict
{
	if ((self = [super init])) {
		CBPurpleAccount		*account = [inDict objectForKey:@"CBPurpleAccount"];
		ESFileTransfer		*fileTransfer = [inDict objectForKey:@"ESFileTransfer"];
		
		[account requestReceiveOfFileTransfer:fileTransfer];

		[[NSNotificationCenter defaultCenter] addObserver:self
																selector:@selector(cancel:)
																	name:FILE_TRANSFER_CANCELLED
																  object:nil];

	}
	
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

/*!
 * @brief libpurple has been made aware we closed or has informed us we should close
 *
 * release (we returned without autoreleasing initially).
 */
- (void)purpleRequestClose
{	
	[self release];
}

/*!
 * @brief Our file transfer was cancelled
 */
- (void)cancel:(NSNotification *)inNotification
{
	//Inform libpurple that the request was cancelled
	[ESPurpleRequestAdapter requestCloseWithHandle:self];
}

@end
