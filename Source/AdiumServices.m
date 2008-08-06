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

#import <Adium/AIAccountControllerProtocol.h>
#import "AdiumServices.h"
#import <Adium/AIService.h>
#import <Adium/AIAccount.h>

@implementation AdiumServices

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		services = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[services release]; services = nil;
	[super dealloc];
}

/*!
 * @brief Register an AIService instance
 *
 * All services should be registered before they are used
 */
- (void)registerService:(AIService *)inService
{
    [services setObject:inService forKey:[inService serviceCodeUniqueID]];
}

/*!
 * @brief Returns an array of all available services
 *
 * @return NSArray of AIService instances
 */
- (NSArray *)services
{
	return [services allValues];
}

/*!
 * @brief Returns an array of all active services
 *
 * "Active" services are those for which the user has an enabled account.
 * @param includeCompatible Include services which are compatible with an enabled account but not specifically active.
 *        For example, if an AIM account is enabled, the ICQ service will be included if this is YES.
 * @return NSArray of AIService instances
 */
- (NSSet *)activeServicesIncludingCompatibleServices:(BOOL)includeCompatible
{
	NSMutableSet	*activeServices = [NSMutableSet set];
	NSEnumerator	*accountEnumerator = [[[adium accountController] accounts] objectEnumerator];
	AIAccount		*account;

	if (includeCompatible) {
		//Scan our user's accounts and build a list of service classes that they cover
		NSMutableSet	*serviceClasses = [NSMutableSet set];
		
		while ((account = [accountEnumerator nextObject])) {
			if ([account enabled]) {
				[serviceClasses addObject:[[account service] serviceClass]];
			}
		}
		
		//Gather and return all services compatible with these service classes
		NSEnumerator	*serviceEnumerator = [services objectEnumerator];
		AIService		*service;
		
		while ((service = [serviceEnumerator nextObject])) {
			if ([serviceClasses containsObject:[service serviceClass]]) {
				[activeServices addObject:service];
			}
		}
		
	} else {
		while ((account = [accountEnumerator nextObject])) {
			if ([account enabled]) {
				[activeServices addObject:[account service]];
			}
		}		
	}

	return activeServices;
}

/*!
 * @brief Retrieves a service by its unique ID
 *
 * Unique IDs are returned by -[AIService serviceCodeUniqueID]. An example is @"libpurple-oscar-AIM".
 * @param uniqueID The serviceCodeUniqueID of the desired service
 * @return AIService if found, nil if not found
 */
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID
{
    return [services objectForKey:uniqueID];
}

/*!
 * @brief Retrieves a service by service ID.
 *
 * Service IDs may be shared by multiple services if the same service is provided by two different plugins.
 * -[AIService serviceID] returns serviceIDs. An example is @"AIM".
 * @return The first service with the matching service ID, or nil if none is found.
 */
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID
{
	NSEnumerator	*enumerator = [services objectEnumerator];
	AIService		*service;
	
	while ((service = [enumerator nextObject])) {
		if ([[service serviceID] isEqualToString:serviceID]) break;
	}
	
	return service;
}

@end
