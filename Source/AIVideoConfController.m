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

#import "AIVideoConfController.h"

#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListObject.h>
#import <Adium/AIPreferencePane.h>

@implementation AIVideoConfController

////////////////////////////////////////////////////////////////////////////////
#pragma mark                         Initializers
////////////////////////////////////////////////////////////////////////////////

/*!
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		providers = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/*!
 * @brief Finish initialization
 */
- (void)controllerDidLoad
{
	// Nothing to do...
}

/*!
 * @brief Close
 */
- (void)controllerWillClose
{
	// Nothing to do...
} 

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[providers release]; providers = nil;
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                 Protocol Providers Management
////////////////////////////////////////////////////////////////////////////////

/*!
 * @brief Register a protocol provider
 */
- (void) registerProvider:(id)provider forProtocol:(VCProtocol)protocol
{
	NSAssert([provider conformsToProtocol:@protocol(VCProtocolProvider)],
			 @"Protocol does not conform to the VCProtocolProvider protocol.");

	// Add our new provider
	[providers setObject:provider forKey:[NSNumber numberWithInt:protocol]];	
}

/*!
 * @brief Unregister a protocol provider
 */
- (void) unregisterProviderForProtocol:(VCProtocol)protocol
{
	[providers removeObjectForKey:[NSNumber numberWithInt:protocol]];
}

/*!
 * @brief	Return the list of providers for a protocol
 */
- (NSDictionary*) providersForProtocol:(VCProtocol)protocol
{
	NSMutableDictionary	*providersSet	= [NSMutableDictionary dictionary];	
	NSDictionary		*availableProviders;
	
	if ((availableProviders = [providers objectForKey:[NSNumber numberWithInt:protocol]])) {
		[providersSet addEntriesFromDictionary:availableProviders];
	}
	
	return providersSet;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                     Payloads
////////////////////////////////////////////////////////////////////////////////
- (NSArray*) getAudioPayloadsForProtocol:(VCProtocol)protocol
{
	NSArray					*listOfPayloads	= nil;
	id<VCProtocolProvider>	 provider;
	
	provider = [providers objectForKey:[NSNumber numberWithInt:protocol]];
	if (provider != nil) {
		listOfPayloads = [provider getAudioPayloadsForProtocol:protocol];
	}
	
	return listOfPayloads;	
}

- (NSArray*) getVideoPayloadsForProtocol:(VCProtocol)protocol
{
	NSArray					*listOfPayloads	= nil;
	id<VCProtocolProvider>	 provider;
	
	provider = [providers objectForKey:[NSNumber numberWithInt:protocol]];
	if (provider != nil) {
		listOfPayloads = [provider getVideoPayloadsForProtocol:protocol];
	}
	
	return listOfPayloads;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                  Connections Creation
////////////////////////////////////////////////////////////////////////////////
- (id) createConnectionWithProtocol:(VCProtocol)protocol
							payload:(VCPayload*)pt 
							   from:(VCTransport*)local
								 to:(VCTransport*)remote
{
	id<VCConnection>		connection = nil;
	id<VCProtocolProvider>	provider;
	
	provider = [providers objectForKey:[NSNumber numberWithInt:protocol]];	
	if (provider != nil) {
		connection = [provider createConnectionWithProtocol:protocol payload:pt from:local to:remote];
	}
	
	return connection;
}


@end
