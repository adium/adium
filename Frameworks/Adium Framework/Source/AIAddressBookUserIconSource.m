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

#import "AIAddressBookUserIconSource.h"
#import "AIAddressBookController.h"
#import <Adium/AIMetaContact.h>
#import <AIUtilities/AIImageDrawingAdditions.h>

#define KEY_AB_IMAGE_SYNC						@"AB Image Sync"
#define KEY_AB_PREFER_ADDRESS_BOOK_IMAGES		@"AB Prefer AB Images"

@interface AIAddressBookUserIconSource ()
- (BOOL)updateFromLocalImageForPerson:(ABPerson *)person object:(AIListObject *)inObject;
@end

@implementation AIAddressBookUserIconSource

- (id)init
{
	if ((self = [super init])) {
		//Tracking dictionary for asynchronous image loads
		trackingDict = [[NSMutableDictionary alloc] init];
		trackingDictPersonToTagNumber = [[NSMutableDictionary alloc] init];
		trackingDictTagNumberToPerson = [[NSMutableDictionary alloc] init];
		priority = AIUserIconLowPriority;

		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_ADDRESSBOOK];
	}
	
	return self;
}

/*!
 * @brief AIUserIcons wants this source to update its user icon for an object
 *
 * Call +[AIUserIcons userIconSource:didDetermineUserIcon:asynchronously:forObject:] with the new icon, if appropriate
 *
 * @result An AIUserIconSourceQueryResult indicating the result
 */
- (AIUserIconSourceQueryResult)updateUserIconForObject:(AIListObject *)inObject
{
	if (!useABImages)
		return AIUserIconSourceDidNotFindIcon;

	ABPerson *person = [AIAddressBookController personForListObject:inObject];
	
	if (!person)
		return AIUserIconSourceDidNotFindIcon;
	
	/* Some mild complexity here. If inObject is a metacontact, we should only proceed if
	 * none of its contained contacts have a higher-priority user icon than we will be.
	 * This prevents a metacontact-associated address book image from overriding a serverside
	 * contained-contact image if that isn't the sort of thing that the user might be into.
	 */
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		for (AIListContact *listContact in ((AIMetaContact *)inObject).uniqueContainedObjects) {
			if (![AIUserIcons userIconSource:self changeWouldBeRelevantForObject:listContact])
				return AIUserIconSourceDidNotFindIcon;
		}
	}

	if ([self updateFromLocalImageForPerson:person
									 object:inObject]) {
		return AIUserIconSourceFoundIcon;

	} else if ([self queueDelayedFetchOfImageFromAnySourceForPerson:person
															 object:inObject]) {
		return AIUserIconSourceLookingUpIconAsynchronously;

	} else {
		return AIUserIconSourceDidNotFindIcon;
	}
}

/*!
 * @brief The priority at which this source should be used. See the #defines in AIUserIcons.h for posible values.
 */
- (AIUserIconPriority)priority
{
	return priority;
}

#pragma mark -

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (object) {
		[AIUserIcons userIconSource:self didChangeForObject:object];

	} else {
		AIUserIconPriority oldPriority = priority;
		BOOL oldUseABImages = useABImages;
		
		preferAddressBookImages = [[prefDict objectForKey:KEY_AB_PREFER_ADDRESS_BOOK_IMAGES] boolValue];
		useABImages = [[prefDict objectForKey:KEY_AB_USE_IMAGES] boolValue];
		
		priority = (preferAddressBookImages ? AIUserIconHighPriority : AIUserIconLowPriority);
		if ((priority != oldPriority) || (oldUseABImages != useABImages)) {
			[AIUserIcons userIconSource:self priorityDidChange:priority fromPriority:oldPriority];
		}
	}
}

#pragma mark Address Book
/*!
 * @brief Called when the address book completes an asynchronous image lookup
 *
 * @param inData NSData representing an NSImage
 * @param tag A tag indicating the lookup with which this call is associated. We use a tracking dictionary, trackingDict, to associate this int back to a usable object.
 */
- (void)consumeImageData:(NSData *)inData forTag:(NSInteger)tag
{
	if (useABImages) {
		NSNumber		*tagNumber;
		NSImage			*image;
		//		AIListContact	*parentContact;
		NSString		*uniqueID;
		id				setOrObject;
		
		tagNumber = [NSNumber numberWithInteger:tag];
		
		//Apply the image to the appropriate listObject
		image = (inData ? [[NSImage alloc] initWithData:inData] : nil);

		if (image) {
			//Address book can feed us giant images, which we really don't want to keep around
			NSSize size = [image size];
			if (size.width > 96 || size.height > 96)
				image = [image imageByScalingToSize:NSMakeSize(96, 96)];
		}
		
		//Get the object from our tracking dictionary
		setOrObject = [trackingDict objectForKey:tagNumber];

		if ([setOrObject isKindOfClass:[AIListObject class]]) {
			AIListObject *listObject = (AIListObject *)setOrObject;
			
			[AIUserIcons userIconSource:self
				   didDetermineUserIcon:image
						 asynchronously:YES
							  forObject:listObject];
			
		} else /*if ([setOrObject isKindOfClass:[NSSet class]])*/{
			//Apply the image to each listObject at the appropriate priority
			for (AIListObject *listObject in [(NSSet *)setOrObject copy]) {
				[AIUserIcons userIconSource:self
					   didDetermineUserIcon:image
							 asynchronously:YES
								  forObject:listObject];
			}
		}

		//No further need for the dictionary entries
		[trackingDict removeObjectForKey:tagNumber];
		
		if ((uniqueID = [trackingDictTagNumberToPerson objectForKey:tagNumber])) {
			[trackingDictPersonToTagNumber removeObjectForKey:uniqueID];
			[trackingDictTagNumberToPerson removeObjectForKey:tagNumber];
		}
	}
}

/*!
 * @brief Queue an asynchronous image fetch for person associated with inObject
 *
 * Image lookups are done asynchronously.  This allows other processing to be done between image calls, improving the perceived
 * speed.  [Evan: I have seen one instance of this being problematic. My localhost loop was broken due to odd network problems,
 *			and the asynchronous lookup therefore hung the problem.  Submitted as radar 3977541.]
 *
 * We load from the same ABPerson for multiple AIListObjects, one for each service/UID combination times
 * the number of accounts on that service.  We therefore aggregate the lookups to lower the address book search
 * and image/data creation overhead.
 *
 * @param person The ABPerson to fetch the image from
 * @param inObject The AIListObject with which to ultimately associate the image
 */
- (BOOL)queueDelayedFetchOfImageFromAnySourceForPerson:(ABPerson *)person object:(AIListObject *)inObject
{
	NSInteger				tag;
	NSNumber		*tagNumber;
	NSString		*uniqueId;

	uniqueId = [person uniqueId];
	
	//Check if we already have a tag for the loading of another object with the same
	//internalObjectID
	if ((tagNumber = [trackingDictPersonToTagNumber objectForKey:uniqueId])) {
		id				previousValue;
		NSMutableSet	*objectSet;
		
		previousValue = [trackingDict objectForKey:tagNumber];
		
		if ([previousValue isKindOfClass:[AIListObject class]]) {
			//If the old value is just a listObject, create a mutable set with the old object
			//and the new object
			if (previousValue != inObject) {
				objectSet = [NSMutableSet setWithObjects:previousValue,inObject,nil];
				
				//Store the set in the tracking dict
				[trackingDict setObject:objectSet forKey:tagNumber];
			}

		} else /*if ([previousValue isKindOfClass:[NSMutableSet class]])*/{
			//Add the new object to the previously-created set
			[(NSMutableSet *)previousValue addObject:inObject];
		}

	} else {
		//Begin the image load
		tag = [person beginLoadingImageDataForClient:self];
		tagNumber = [NSNumber numberWithInteger:tag];
		
		//We need to be able to take a tagNumber and retrieve the object
		[trackingDict setObject:inObject forKey:tagNumber];
		
		//We also want to take a person's uniqueID and potentially find an existing tag number
		[trackingDictPersonToTagNumber setObject:tagNumber forKey:uniqueId];
		[trackingDictTagNumberToPerson setObject:uniqueId forKey:tagNumber];
	}

	return YES;
}

- (BOOL)updateFromLocalImageForPerson:(ABPerson *)person object:(AIListObject *)inObject
{
	NSData *imageData = [person imageData];
	NSImage *image = (imageData ? [[NSImage alloc] initWithData:imageData] : nil);

	//Address book can feed us giant images, which we really don't want to keep around
	if (image) {
		NSSize size = [image size];
		if (size.width > 96 || size.height > 96)
			image = [image imageByScalingToSize:NSMakeSize(96, 96)];
		
		[AIUserIcons userIconSource:self
			   didDetermineUserIcon:image
					 asynchronously:NO
						  forObject:inObject];
		
		NSInteger tag;
		if ((tag = [[trackingDictPersonToTagNumber objectForKey:[person uniqueId]] integerValue])) {
			[ABPerson cancelLoadingImageDataForTag:tag];
		}

		return YES;

	} else {
		return NO;
	}
}

@end
