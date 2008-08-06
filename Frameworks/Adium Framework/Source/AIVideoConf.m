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


#import "AIVideoConf.h"

////////////////////////////////////////////////////////////////////////////////
//                          Payload Types
////////////////////////////////////////////////////////////////////////////////
@implementation VCPayload

+ (id) createWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels
{
	return [[[self alloc] initWithId:ptid name:ptname channels:ptchannels] autorelease];
}

- (id) initWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels
{
	self = [super init];
	
	if (self) {
		mId = ptid;
		mName = ptname;
		mChannels = ptchannels;
	}
	
	return self;	
}


@end

////////////////////////////////////////////////////////////////////////////////
//                          Audio Payload Types
////////////////////////////////////////////////////////////////////////////////
@implementation VCAudioPayload

+ (id) createWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels clockrate:(int)ptrate
{
	return [[[self alloc] initWithId:ptid name:ptname channels:ptchannels clockrate:ptrate] autorelease];
}

- (id) initWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels clockrate:(int)ptrate
{
	self = [super init];
	
	if (self) {
		mId = ptid;
		mName = ptname;
		mChannels = ptchannels;
		mClockrate = ptrate;
	}
	
	return self;	
}

@end

////////////////////////////////////////////////////////////////////////////////
//                               Transport
////////////////////////////////////////////////////////////////////////////////
@implementation VCTransport

+ (id) createWithName:(NSString*)name ip:(NSString*)ip port:(int)port
{
	return [[[self alloc] initWithName:name ip:ip port:(int)port] autorelease];
}

- (id) initWithName:(NSString*)name ip:(NSString*)ip port:(int)port
{
	self = [super init];
	
	if (self) {
		mName = name;
		mIp = ip;
		mPort = port;
	}	
	return self;
}

@end


