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

/*!
 * A payload type.
 */
@interface VCPayload : NSObject {
	int			mId;			// Id (in the RTP domain)
	NSString*	mName;			// Printable name 
	int			mChannels;		// Number of channels
	
	int			mQuality;		// Overall output quality (0:worst - 10:best)
	int			mCost;			// Computational cost (0:light - 10:heavy)
}

+ (id) createWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels;
- (id) initWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels;

@end


/*!
 * Audio payload type.
 */
@interface VCAudioPayload : VCPayload {
	int			mClockrate;		// Sample rate
}

+ (id) createWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels clockrate:(int)ptrate;
- (id) initWithId:(int)ptid name:(NSString*)ptname channels:(int)ptchannels clockrate:(int)ptrate;

@end



/*!
 * Transport endpoint definition.
 */
@interface VCTransport : NSObject {
	NSString	*mName;		// Transport name (optional)
	NSString	*mIp;		// IP address or hostname
	int			 mPort;		// Port number
}

+ (id) createWithName:(NSString*)name ip:(NSString*)ip port:(int)port;
- (id) initWithName:(NSString*)name ip:(NSString*)ip port:(int)port;

@end


/*!
 * Supported protocols.
 * This list should grow in the future...
 */
typedef enum {
	VC_RTP = 0
} VCProtocol;


/*!
 * Protocol provider.
 * A "protocol provider" must implement a protocol (ie, RTP) and be able to
 * create connections with that protocol between two endpoints.
 */
@protocol VCProtocolProvider
/*!
 * Provides a list of audio payloads this protocol provider supports. 
 */
- (NSArray*) getAudioPayloadsForProtocol:(VCProtocol)protocol;

/*!
 * Provides a list of video payloads this protocol provider supports. 
 */
- (NSArray*) getVideoPayloadsForProtocol:(VCProtocol)protocol;

/*!
 * Create a connection between two transport points, with the specified payload
 * type. It should return FALSE if the protocol can not create this connection.
 */
- (id) createConnectionWithProtocol:(VCProtocol)protocol
							payload:(VCPayload*)payload
							   from:(VCTransport*)local
								 to:(VCTransport*)remote;

/*!
 * Create a set of connections between several transport points, with the
 * specified payload types. It should return "nil" if the protocol can not create
 * these connections.
 */
- (NSArray*) createConnectionsWithProtocol:(VCProtocol)protocol
								  payloads:(NSArray*)payload
									  from:(NSArray*)local
										to:(NSArray*)remote;
@end


/*!
 * Connection.
 */
@protocol VCConnection
- (BOOL) start;
- (BOOL) stop;
@end

