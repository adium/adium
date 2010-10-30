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

#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContactObserverManager.h>

#import <AIUtilities/AIImageDrawingAdditions.h>
#import <Adium/AIServiceIcons.h>

#import "AIServersideUserIconSource.h"
#import "AIManuallySetUserIconSource.h"
#import "AICachedUserIconSource.h"

static NSMutableArray		*userIconSources = nil;
static BOOL					isQueryingIconSources = NO;

static NSMutableDictionary	*iconCache = nil;
static NSMutableDictionary  *iconCacheOwners = nil;

static NSMutableDictionary	*listIconCache = nil;
static NSMutableDictionary	*menuIconCache = nil;
static NSSize				iconCacheSize;

static AIServersideUserIconSource	*serversideUserIconSource = nil;
static AIManuallySetUserIconSource	*manuallySetUserIconSource = nil;
static AICachedUserIconSource		*cachedUserIconSource = nil;

//#define AIUSERICON_DEBUG

@interface AIUserIcons ()
+ (void)updateAllIcons;
+ (void)updateUserIconForObject:(AIListObject *)inObject;
+ (void)flushCacheForObjectOnly:(AIListObject *)inObject;
+ (void)flushCacheForObjectAndParentOnly:(AIListObject *)inObject;
@end

@implementation AIUserIcons

+ (void)initialize
{
	if (self == [AIUserIcons class]) {
		userIconSources = [[NSMutableArray alloc] init];
		iconCache = [[NSMutableDictionary alloc] init];
		iconCacheOwners = [[NSMutableDictionary alloc] init];

		listIconCache = [[NSMutableDictionary alloc] init];
		menuIconCache = [[NSMutableDictionary alloc] init];
		
		/* Initialize built-in user icon sources */
		serversideUserIconSource = [[AIServersideUserIconSource alloc] init];
		[self registerUserIconSource:serversideUserIconSource];
		
		manuallySetUserIconSource = [[AIManuallySetUserIconSource alloc] init];
		[self registerUserIconSource:manuallySetUserIconSource];

		cachedUserIconSource = [[AICachedUserIconSource alloc] init];
		[self registerUserIconSource:cachedUserIconSource];
	}
}

static NSComparisonResult compareSources(id <AIUserIconSource> sourceA, id <AIUserIconSource> sourceB, void *context)
{
	CGFloat priorityA = [sourceA priority];
	CGFloat priorityB = [sourceB priority];
	if (priorityA < priorityB)
		return NSOrderedAscending;
	else if (priorityB < priorityA)
		return NSOrderedDescending;
	else
		return NSOrderedSame;

}
#pragma mark User Icon Sources
/*!
 * @brief Register a user icon source
 */
+ (void)registerUserIconSource:(id <AIUserIconSource>)inSource
{
	[userIconSources addObject:inSource];
	[userIconSources sortUsingFunction:compareSources context:NULL];

#ifdef AIUSERICON_DEBUG
	AILogWithSignature(@"Sources is %@", userIconSources);
#endif

	[self updateAllIcons];
}

+ (void)updateAllIcons
{
#ifdef AIUSERICON_DEBUG
	AILogWithSignature(@"");
#endif

	[[AIContactObserverManager sharedManager] delayListObjectNotifications];
	
	[self flushAllCaches];
	
	for (AIListObject *listObject in adium.contactController.allContacts) {
		[self updateUserIconForObject:listObject];
	}

	[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];	
}

/*!
 * @brief The priority of a user icon source changed
 */
+ (void)userIconSource:(id <AIUserIconSource>)inSource priorityDidChange:(AIUserIconPriority)newPriority fromPriority:(AIUserIconPriority)oldPriority
{
	[userIconSources sortUsingFunction:compareSources context:NULL];

	[self updateAllIcons];
}


+ (void)notifyOfChangedIconForObject:(AIListObject *)inObject
{
	NSSet			*modifiedKeys = [NSSet setWithObject:KEY_USER_ICON];
	
	//Notify
	[[AIContactObserverManager sharedManager] listObjectAttributesChanged:inObject
											  modifiedKeys:modifiedKeys];		
	
	if ([inObject isKindOfClass:[AIListContact class]] && ((AIListContact *)inObject).metaContact) {		
		//Notify
		[[AIContactObserverManager sharedManager] listObjectAttributesChanged:((AIListContact *)inObject).metaContact
												  modifiedKeys:modifiedKeys];
	}	
}

/*!
 * @brief A user icon source determined a user icon for an object
 *
 * This should be called only by a user icon source upon successful determination of a user icon
 */
+ (void)userIconSource:(id <AIUserIconSource>)inSource
  didDetermineUserIcon:(NSImage *)inUserIcon 
		asynchronously:(BOOL)wasAsynchronous
			 forObject:(AIListObject *)inObject
{
	/* If we're receiving an asynchronous reply, only continue if the replying source has a same or
	 * higher priority than the current one.
	 */
	if (wasAsynchronous && ![self userIconSource:inSource changeWouldBeRelevantForObject:inObject])
		return;

	NSString *internalObjectID = inObject.internalObjectID;

	//Keep the data around so that this image can be resized without loss of quality
	[inUserIcon setDataRetained:YES];

	if (inUserIcon && inSource) {
#ifdef AIUSERICON_DEBUG
		AILogWithSignature(@"%@ provided icon for %@", inSource, inObject);
#endif
		[inUserIcon retain];
		[self flushCacheForObjectAndParentOnly:inObject];

		[iconCache setObject:inUserIcon forKey:internalObjectID];
		[iconCacheOwners setObject:inSource forKey:internalObjectID];
		[inUserIcon release];

	} else {
		id <AIUserIconSource> source = [self userIconSourceForObject:inObject];
		if (!wasAsynchronous || (source == inSource)) {
			/* Either this was a synchronous lookup  (we must take action now to prevent an infinite loop of re-lookup)
			 *  OR
			 * this same source is handling the icon for the object, so its new lack an icon is an important change.
			 */
			if (source) {
				/* We previously had an icon but no longer have one; need to flush.
				 */
				[self flushCacheForObjectAndParentOnly:inObject];
			}
			
#ifdef AIUSERICON_DEBUG
			AILogWithSignature(@"Source %@ got nothing for %@; current source is %@", inSource, inObject, [self userIconSourceForObject:inObject]);
#endif
			
			[iconCache setObject:[NSNull null] forKey:internalObjectID];
			[iconCacheOwners removeObjectForKey:internalObjectID];

		} else {
#ifdef AIUSERICON_DEBUG
			AILogWithSignature(@"Source %@: Ignoring information on %@ for %@", inSource, inUserIcon, inObject);
#endif
		}
	}
		
	if (!isQueryingIconSources) {
		/* We determined a user icon when we weren't in the middle of an update;
		 * this means an asynchronous icon lookup was completed.
		 *
		 * Do we need to do anything differently?
		 */
	}
	
	/* Wait until the next run loop if this was a synchronous lookup;
	 * if a metacontact's investigation of its icon by querying contained contacts
	 * led to a contact's icon being determined, it is necessary to wait for it to receive the return value and
	 * update the cache (by calling +[AIUserIcons setActualUserIcon:andSource:forObject:]) so that we don't notify
	 * prematurely.  Notifying now would lead to a potential race condition in which the wrong icon could be flickered
	 * onto the display or an infinite loop could occur.
	 */
	if (wasAsynchronous)
		[self notifyOfChangedIconForObject:inObject];
	else
		[self performSelector:@selector(notifyOfChangedIconForObject:)
				   withObject:inObject
				   afterDelay:0];
}

/*!
 * @brief Get the user icon source currently providing the icon for an object
 */
+ (id <AIUserIconSource>)userIconSourceForObject:(AIListObject *)inObject
{
	return [iconCacheOwners objectForKey:inObject.internalObjectID];
}

/*!
 * @brief Query all user icon sources to determine the right user icon for an object
 *
 * Higher priority sources will be queried first.  Once one returns YES, we stop going down the line.
 */
+ (void)updateUserIconForObject:(AIListObject *)inObject
{
	id <AIUserIconSource> userIconSource;
	BOOL foundIcon = NO;
	BOOL inProgressForCurrentSource = NO;
	
	isQueryingIconSources = YES;
	for (userIconSource in userIconSources) {
		AIUserIconSourceQueryResult queryResult = [userIconSource updateUserIconForObject:inObject];
		if (queryResult == AIUserIconSourceFoundIcon) {
			foundIcon = YES;
			break;

		} else if (queryResult == AIUserIconSourceLookingUpIconAsynchronously) {
			id <AIUserIconSource> currentUserIconSource = [self userIconSourceForObject:inObject];
			inProgressForCurrentSource = !currentUserIconSource || (currentUserIconSource == userIconSource);
		}
	}
	isQueryingIconSources = NO;

	if (!foundIcon && !inProgressForCurrentSource) {
		//If we -are- in progress for the current source, we'll clear the icon when it returns
		[self userIconSource:nil didDetermineUserIcon:nil asynchronously:NO forObject:inObject];
	}
}

/*!
 * @brief Determine if a change in a given icon source would potentially change the icon of an object
 */
+ (BOOL)userIconSource:(id <AIUserIconSource>)inSource changeWouldBeRelevantForObject:(AIListObject *)inObject
{
	id <AIUserIconSource> currentSource = [self userIconSourceForObject:inObject];

	return (!currentSource || ([currentSource priority] >= [inSource priority]));
}

/*!
 * @brief Called by an icon source to inform us that its provided icon changed
 */
+ (void)userIconSource:(id <AIUserIconSource>)inSource didChangeForObject:(AIListObject *)inObject
{
	if ([self userIconSource:inSource changeWouldBeRelevantForObject:inObject]) {
		[self updateUserIconForObject:inObject];
	}
}

#pragma mark Icon setting pass-throughs

/*!
 * @brief Inform AIUserIcons a new manually-set icon data for an object
 *
 * We take responsibility (via AIManuallySetUserIconSource) for saving the data
 */
+ (void)setManuallySetUserIconData:(NSData *)inData forObject:(AIListObject *)inObject
{
	[manuallySetUserIconSource setManuallySetUserIconData:inData forObject:inObject];
}

/*!
 * @brief Inform AIUserIcons of new serverside icon data for an object.
 *
 * This is likely called by a contact for itself or by an accont for a contact.
 */
+ (void)setServersideIconData:(NSData *)inData forObject:(AIListObject *)inObject notify:(NotifyTiming)notify
{
	[serversideUserIconSource setServersideUserIconData:inData forObject:inObject];
}

#pragma mark Icon retrieval

/*!
 * @brief Retrieve the manually set user icon (a stored preference) for an object, if there is one
 */
+ (NSData *)manuallySetUserIconDataForObject:(AIListObject *)inObject
{
	return [manuallySetUserIconSource manuallySetUserIconDataForObject:inObject];
}

/*!
 * @brief Retreive the serverside icon for an object, if there is one.
 */
+ (NSData *)serversideUserIconDataForObject:(AIListObject *)inObject
{
	return [serversideUserIconSource serversideUserIconDataForObject:inObject];
}

/*!
 * @brief Retreive the cached icon for an object, if there is one.
 */
+ (NSData *)cachedUserIconDataForObject:(AIListObject *)inObject
{
	return [cachedUserIconSource cachedUserIconDataForObject:inObject];
}

/*!
 * @brief Returns if a cached user icon exists.
 *
 * @result YES if a cached user icon exists, NO otherwise.
 */
+ (BOOL)cachedUserIconExistsForObject:(AIListObject *)inObject
{
	return [cachedUserIconSource cachedUserIconExistsForObject:inObject];
}

/*!
 * @brief Get the user icon for an object
 *
 * If it's not already cached, the icon sources will be queried as needed.
 */
+ (NSImage *)userIconForObject:(AIListObject *)inObject
{
	NSImage		*userIcon = nil;
	NSString	*internalObjectID = inObject.internalObjectID;
	
	userIcon = [iconCache objectForKey:internalObjectID];
	if (!userIcon) {
		[self updateUserIconForObject:inObject];
		userIcon = [iconCache objectForKey:internalObjectID];
#ifdef AIUSERICON_DEBUG
		AILogWithSignature(@"%@ (Got icon? %i)",inObject, (userIcon!=nil));
#endif		
		if (!userIcon) {
			[iconCache setObject:[NSNull null] forKey:internalObjectID];
			[iconCacheOwners removeObjectForKey:internalObjectID];
		}
	}

	if ((id)userIcon == (id)[NSNull null]) userIcon = nil;

	return userIcon;
}

/*!
 * @brief Set what user icon and source an object is currently using (regardless of what AIUserIcon would otherwise do)
 *
 * This is useful if an object knows something AIUserIcons can't. For example, AIMetaContact uses this to let AIUserIcons
 * know how it resolved iterating through its contained contacts based on their respective priorities in order to determine
 * which user icon should be used.  Tracking it here prevents needless repeated lookups of data.
 */
+ (void)setActualUserIcon:(NSImage *)userIcon andSource:(id <AIUserIconSource>)inSource forObject:(AIListObject *)inObject
{
	if (userIcon && inSource) {
		NSString	*internalObjectID = inObject.internalObjectID;
		
		[userIcon retain];
		[self flushCacheForObjectOnly:inObject];

#ifdef AIUSERICON_DEBUG
		AILogWithSignature(@"%@ is using %@", inObject, inSource);
#endif
		
		[iconCache setObject:userIcon
					  forKey:internalObjectID];
		[iconCacheOwners setObject:inSource
							forKey:internalObjectID];
		[userIcon release];
	}
}

/*
 * @brief Retrieve a user icon sized for the contact list
 *
 * @param inObject The object
 * @param size Size of the returned image. If this is the size passed to -[self setListUserIconSize:], a cache will be used.
 */
+ (NSImage *)listUserIconForContact:(AIListObject *)inObject size:(NSSize)size
{
	BOOL	cache = NSEqualSizes(iconCacheSize, size);
	NSImage *userIcon = nil;
	
	//Retrieve the icon from our cache
	if (cache) userIcon = [listIconCache objectForKey:inObject.internalObjectID];

	//Render the icon if it's not cached
	if (!userIcon) {
		userIcon = [[inObject userIcon] imageByScalingToSize:size 
													 fraction:1.0f
													flipImage:YES
											   proportionally:YES
											   allowAnimation:YES];
#ifdef AIUSERICON_DEBUG
		AILogWithSignature(@"%@ regenerated (cache? %i)",inObject, cache);
#endif
		
		if (cache) {
			if (userIcon) 
				[listIconCache setObject:userIcon forKey:inObject.internalObjectID];
			else 
				[listIconCache setObject:[NSNull null] forKey:inObject.internalObjectID];
		}
	}
	
	if ((id)userIcon == (id)[NSNull null]) userIcon = nil;

	return userIcon;
}

/*!
 * @brief Retrieve a user icon sized for a menu
 *
 * Returns the appropriate service icon if no user icon is found
 */
+ (NSImage *)menuUserIconForObject:(AIListObject *)inObject
{
	NSImage *userIcon;
	
	//Retrieve the icon from our cache
	userIcon = [menuIconCache objectForKey:inObject.internalObjectID];
	
	//Render the icon if it's not cached
	if (!userIcon) {
		userIcon = [[inObject userIcon] imageByScalingForMenuItem];
		if (userIcon) {
			[menuIconCache setObject:userIcon
							  forKey:inObject.internalObjectID];
		} else {
			[menuIconCache setObject:[NSNull null] forKey:inObject.internalObjectID];
		}
#ifdef AIUSERICON_DEBUG
		AILogWithSignature(@"%@",inObject);
#endif
	}

	if ((id)userIcon == (id)[NSNull null]) userIcon = nil;

	if(!userIcon)
		userIcon = [AIServiceIcons serviceIconForObject:inObject
												   type:AIServiceIconSmall
											  direction:AIIconNormal];
	
	return [[userIcon retain] autorelease];
}

#pragma mark -

/*!
 * @brief Flush the cache of listUserIcons
 */
+ (void)flushListUserIconCache
{
#ifdef AIUSERICON_DEBUG
	AILogWithSignature(@"");
#endif
	[listIconCache removeAllObjects];
}

/*
 * @brief Set the current contact list user icon size
 * This determines the size at which images are cached for listUserIconForContact:size:
 */
+ (void)setListUserIconSize:(NSSize)inSize
{
	if (!NSEqualSizes(inSize, iconCacheSize)) {
		iconCacheSize = inSize;
		[self flushListUserIconCache];
	}	
}

+ (void)flushCacheForObjectOnly:(AIListObject *)inObject
{
	NSString *internalObjectID = inObject.internalObjectID;
	[iconCache removeObjectForKey:internalObjectID];
	[iconCacheOwners removeObjectForKey:internalObjectID];
	
	[listIconCache removeObjectForKey:internalObjectID];
	[menuIconCache removeObjectForKey:internalObjectID];
}

+ (void)flushCacheForObjectAndParentOnly:(AIListObject *)inObject
{
	[self flushCacheForObjectOnly:inObject];

	AIListContact *parentContact = [(AIListContact *)inObject parentContact];
	if (parentContact != inObject)
		[self flushCacheForObjectOnly:parentContact];
}

/*!
 * @brief Clear the cache for a specific object
 */
+ (void)flushCacheForObject:(AIListObject *)inObject
{
#ifdef AIUSERICON_DEBUG
	AILogWithSignature(@"%@",inObject);
#endif
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		/* If a metacontact is cleared, the contained contacts should be, too cleared;
		 * one or more of their icons may no longer be needed depending on what the new preferredContact is
		 * for the metaContact. */

		for (AIListObject *containedObject in [(AIMetaContact *)inObject containedObjects]) {
			[self flushCacheForObjectOnly:containedObject];
		}
		
		[self flushCacheForObjectOnly:inObject];

	} else if ([inObject isKindOfClass:[AIListContact class]]) {
		/* If a contact within a metacontact is cleared, the metacontact itself should also be cleared, as
		 * it may be depending upon this contact.This will clear us, too.
		 *
		 * If we're not in a metacontact, parentContact returns self. */
		
		AIListContact *parentContact = [(AIListContact *)inObject parentContact];
		if (parentContact != inObject) {
			[self flushCacheForObject:parentContact];	
		} else {
			[self flushCacheForObjectOnly:inObject];
		}
	}
}

/*!
 * @brief Clear all caches
 */
+ (void)flushAllCaches
{
#ifdef AIUSERICON_DEBUG
	AILogWithSignature(@"");
#endif
	
	[iconCache removeAllObjects];
	[iconCacheOwners removeAllObjects];

	[listIconCache removeAllObjects];
	[menuIconCache removeAllObjects];	 
}

@end

