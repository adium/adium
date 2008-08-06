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

#import "QTPlugin.h"

#import <Adium/AIVideoConfControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIVideoConf.h>
#import <Adium/AIListObject.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#import <QuickTime/QuickTime.h>

#import "QTConnection.h"
#import "QTRTPConnection.h"
#import "QTAdvancedPreferences.h"

/*!
 * QuickTime plugin
 */
@implementation QTPlugin

////////////////////////////////////////////////////////////////////////////////
#pragma mark                     QuickTime Initialization
////////////////////////////////////////////////////////////////////////////////

/*!
 * Initialize QuickTime
 */
- (void) startupQuickTime
{
	NSLog(@"QuickTime startup");
	EnterMovies();
}

/*!
 * Shutdown QuickTime
 */
- (void) shutdownQuickTime
{
	NSLog(@"QuickTime shutdown");
	ExitMovies();
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                     QuickTime Properties
////////////////////////////////////////////////////////////////////////////////

/*!
 * @brief Set the mic volume
 */
- (void) setDefaultMicVolumeTo: (int)volume
{
	micVolume = volume;
}

/*!
 * @brief Set the output volume
 */
- (void) setDefaultOutVolumeTo: (int)volume
{
	outVolume = volume;
}

/*!
 * @brief Set the connection speed
 */
- (void) setConnectionSpeed
{
	OSErr err;
	QTAtomContainer prefs;
	QTAtom prefsAtom;
	long dataSize;
	Ptr atomData;
	ConnectionSpeedPrefsRecord prefrec;
	
	err = GetQuickTimePreference (ConnectionSpeedPrefsType, &prefs);
	if (err == noErr) {
		prefsAtom = QTFindChildByID (prefs,
									 kParentAtomIsContainer, 
									 ConnectionSpeedPrefsType,
									 1,
									 NULL);
		
		if (!prefsAtom) {
			// set the default setting to 28.8kpbs
			prefrec.connectionSpeed = kDataRate288ModemRate;
		} else {
			err = QTGetAtomDataPtr (prefs, prefsAtom, &dataSize, &atomData);
			if (dataSize != sizeof(ConnectionSpeedPrefsRecord)) {
				// the prefs record wasn't the right size, 
				// so it must be corrupt -- set to the default
				prefrec.connectionSpeed = kDataRate288ModemRate;
			} else {
				// everything was fine -- read the connection speed
				prefrec = *(ConnectionSpeedPrefsRecord *)atomData;
			}
		}
		
		QTDisposeAtomContainer (prefs);
	}
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                  QuickTime General Information
////////////////////////////////////////////////////////////////////////////////
- (NSArray*) getAudioPayloadsForProtocol:(VCProtocol)protocol
{
	// So far, we only support RTP audio connections: get the list of payloads
	// from there...
	if (protocol == VC_RTP) {
		return [QTAudioRTPConnection getSupportedAudioPayloads];
	} else {
		NSLog (@"Unsupported protocol in getAudioPayloadsForProtocol.");
		return nil;
	}
}

- (NSArray*) getVideoPayloadsForProtocol:(VCProtocol)protocol
{
	// TODO: we dont currently support any video codec...
	NSLog (@"Warning: asking for video payloads to QTPlugin.");
	return nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                      Connections Management
////////////////////////////////////////////////////////////////////////////////
/*!
 * Create a connection between two transport points, with the specified payload
 * type. It should return the new connection, or nil if the protocol can not
 * create this connection.
 */
- (id) createConnectionWithProtocol:(VCProtocol)protocol
							payload:(VCPayload*)payload
							   from:(VCTransport*)local
								 to:(VCTransport*)remote;
{
	id<VCConnection> connection = nil;
	
	if (protocol == VC_RTP) {
		QTAudioRTPConnection	*rtpConnection;

		// Create the audio connection
		rtpConnection = [QTAudioRTPConnection createWithProtocol:protocol
														 payload:payload
															from:local
															  to:remote];
		// ...and set some media properties
		if(rtpConnection != nil) {
			[rtpConnection setMicVolumeTo:micVolume];
			[rtpConnection setOutVolumeTo:outVolume];			
		} else {
			NSLog(@"Error: creating an RTP audio connection.");
		}
		
		connection = rtpConnection;
	} else {
		NSLog(@"The supplied protocol is not supported yet.");
	}
	
	return connection;
}

/*!
 * Create a set of connections between several transport points, with the
 * specified payload types. It should return "nil" if the protocol can not create
 * these connections.
 */
- (NSArray*) createConnectionsWithProtocol:(VCProtocol)protocol
								  payloads:(NSArray*)payload
									  from:(NSArray*)local
										to:(NSArray*)remote
{
	NSLog(@"createConnectionsWithProtocol not implemented.");
	return nil;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                     Plugin Management
////////////////////////////////////////////////////////////////////////////////

/*!
 * Install the plugin
 */
- (void)installPlugin
{
	// Observe workspace activity changes so we can mute sounds as necessary
	NSNotificationCenter	*workspaceCenter;
	
	// Register this for some protocols
	[[adium vcController] registerProvider:self forProtocol:VC_RTP];
	
    // Install some preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:QUICKTIME_PREFS
																		forClass:[self class]]
										  forGroup:QUICKTIME_PREFS];
	
	advancedPreferences = [[QTAdvancedPreferences preferencePane] retain];
	
	// Watch for preferences changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:QUICKTIME_PREFS];
	
	workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	
	[workspaceCenter addObserver:self
						selector:@selector(workspaceSessionDidBecomeActive:)
							name:NSWorkspaceSessionDidBecomeActiveNotification
						  object:nil];
	
	[workspaceCenter addObserver:self
						selector:@selector(workspaceSessionDidResignActive:)
							name:NSWorkspaceSessionDidResignActiveNotification
						  object:nil];	
	
	[self startupQuickTime];
}

/*!
 * Uninstall the plugin
 */
- (void) uninstallPlugin
{
	[self shutdownQuickTime];
	
	[[adium vcController] unregisterProviderForProtocol:VC_RTP];
	
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];	
}


/*!
 * Preferences have changed
 */
- (void) preferencesChangedForGroup:(NSString *)group
								key:(NSString *)key
							 object:(AIListObject *)object
					 preferenceDict:(NSDictionary *)prefDict
						  firstTime:(BOOL)firstTime
{
	[self setDefaultMicVolumeTo: [[prefDict objectForKey:KEY_MIC_VOLUME] intValue]];	
	[self setDefaultOutVolumeTo: [[prefDict objectForKey:KEY_OUT_VOLUME] intValue]];
}

- (void)workspaceSessionDidBecomeActive:(NSNotification *)inNotification
{
	
}

- (void)workspaceSessionDidResignActive:(NSNotification *)inNotification
{
	
}

@end
