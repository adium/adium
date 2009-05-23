//
//  AIContactMenu.m
//  Adium
//
//  Created by Adam Iser on 5/31/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AISortController.h>
#import <Adium/AIContactMenu.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIContactList.h>

@interface AIContactMenu ()
- (id)initWithDelegate:(id<AIContactMenuDelegate>)inDelegate forContactsInObject:(AIListObject *)inContainingObject;
- (NSArray *)contactMenusForListObjects:(NSArray *)listObjects;
- (NSArray *)listObjectsForMenuFromArrayOfListObjects:(NSArray *)listObjects;
- (void)_updateMenuItem:(NSMenuItem *)menuItem;
@end

@implementation AIContactMenu

/*!
 * @brief Create a new contact menu
 * @param inDelegate Delegate in charge of adding menu items
 * @param inContainingObject Containing contact whose contents will be displayed in the menu, nil for all contacts/groups
 */
+ (id)contactMenuWithDelegate:(id<AIContactMenuDelegate>)inDelegate forContactsInObject:(AIListObject *)inContainingObject
{
	return [[[self alloc] initWithDelegate:inDelegate forContactsInObject:inContainingObject] autorelease];
}

/*!
 * @brief Init
 * @param inDelegate Delegate in charge of adding menu items
 * @param inContainingObject Containing contact whose contents will be displayed in the menu, nil for all contacts/groups
 */
- (id)initWithDelegate:(id<AIContactMenuDelegate>)inDelegate forContactsInObject:(AIListObject *)inContainingObject
{
	if ((self = [super init])) {
		[self setDelegate:inDelegate];
		containingObject = [inContainingObject retain];

		// Register as a list observer
		[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
		
		// Register for contact list order notifications (so we can update our sorting)
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(contactOrderChanged:)
										   name:Contact_OrderChanged
										 object:nil];

		[self rebuildMenu];
	}
	
	return self;
}

- (void)dealloc
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[containingObject release]; containingObject = nil;
	delegate = nil;
	
	[super dealloc];
}

/*!
 * @brief Set the containing object
 *
 * Updates the containing object, and rebuilds the menu items.
 */
- (void)setContainingObject:(AIListObject *)inContainingObject
{
	[containingObject release];
	
	containingObject = [inContainingObject retain];
	
	[self rebuildMenu];
}

/*!
 * @brief Returns the existing menu item for a specific contact
 *
 * @param contact AIListContact whose menu item to return
 * @return NSMenuItem instance for the contact
 */
- (NSMenuItem *)existingMenuItemForContact:(AIListContact *)contact
{
	return (menuItems ? [self menuItemWithRepresentedObject:contact] : nil);
}

- (void)contactOrderChanged:(NSNotification *)notification
{
	AIListObject *changedObject = [notification object];
	if (changedObject && changedObject == containingObject) {
		[self rebuildMenu];
	}
}

//Delegate -------------------------------------------------------------------------------------------------------------
#pragma mark Delegate
/*!
 * @brief Set our contact menu delegate
 */
- (void)setDelegate:(id<AIContactMenuDelegate>	)inDelegate
{
	delegate = inDelegate;
	
	//Ensure the the delegate implements all required selectors and remember which optional selectors it supports.
	if (delegate) NSParameterAssert([delegate respondsToSelector:@selector(contactMenu:didRebuildMenuItems:)]);
	delegateRespondsToDidSelectContact = [delegate respondsToSelector:@selector(contactMenu:didSelectContact:)];
	delegateRespondsToShouldIncludeContact = [delegate respondsToSelector:@selector(contactMenu:shouldIncludeContact:)];
	delegateRespondsToValidateContact = [delegate respondsToSelector:@selector(contactMenu:validateContact:)];

	shouldUseUserIcon = ([delegate respondsToSelector:@selector(contactMenuShouldUseUserIcon:)] &&
								 [delegate contactMenuShouldUseUserIcon:self]);
	
	shouldUseDisplayName = ([delegate respondsToSelector:@selector(contactMenuShouldUseDisplayName:)] &&
							[delegate contactMenuShouldUseDisplayName:self]);
	
	shouldDisplayGroupHeaders = ([delegate respondsToSelector:@selector(contactMenuShouldDisplayGroupHeaders:)] &&
								 [delegate contactMenuShouldDisplayGroupHeaders:self]);
	
	shouldSetTooltip = ([delegate respondsToSelector:@selector(contactMenuShouldSetTooltip:)] &&
								 [delegate contactMenuShouldSetTooltip:self]);	
}
- (id<AIContactMenuDelegate>	)delegate
{
	return delegate;
}

/*!
 * @brief Inform our delegate when the menu is rebuilt
 */
- (void)rebuildMenu
{
	[super rebuildMenu];
	
	// Update our values for display name and group header options.
	shouldUseDisplayName = ([delegate respondsToSelector:@selector(contactMenuShouldUseDisplayName:)] &&
							[delegate contactMenuShouldUseDisplayName:self]);
	
	shouldDisplayGroupHeaders = ([delegate respondsToSelector:@selector(contactMenuShouldDisplayGroupHeaders:)] &&
								 [delegate contactMenuShouldDisplayGroupHeaders:self]);
	
	[delegate contactMenu:self didRebuildMenuItems:[self menuItems]];
}

/*!
 * @brief Inform our delegate of menu selections
 */
- (void)selectContactMenuItem:(NSMenuItem *)menuItem
{
	if (delegateRespondsToDidSelectContact) {
		[delegate contactMenu:self didSelectContact:[menuItem representedObject]];
	}
}


//Contact Menu ---------------------------------------------------------------------------------------------------------
#pragma mark Contact Menu
/*!
 * @brief Build our contact menu items
 */
- (NSArray *)buildMenuItems
{
	NSArray *listObjects = nil;
	
	// If we're not given a containing object, use all the contacts
	if (containingObject == nil) {
		listObjects = adium.contactController.useContactListGroups ? adium.contactController.allGroups : adium.contactController.allContacts;

		/* The contact controller's -allContacts gives us an array with meta contacts expanded
		 * Let's put together our own list if we need to. This also gives our delegate an opportunity
		 * to decide if the contact should be included.
		 */
		if (!shouldDisplayGroupHeaders) {
			listObjects = [self listObjectsForMenuFromArrayOfListObjects:listObjects];
		}

		// Sort what we're given
		//XXX is this container right?
		listObjects = [listObjects sortedArrayUsingActiveSortControllerInContainer:adium.contactController.contactList];
	} else {
		// We can assume these are already sorted
		listObjects = [self listObjectsForMenuFromArrayOfListObjects:([containingObject conformsToProtocol:@protocol(AIContainingObject)] ?
																	  [(AIListObject<AIContainingObject> *)containingObject uniqueContainedObjects] :
																	  [NSArray arrayWithObject:containingObject])];
	}
	
	// Create menus for them
	return [self contactMenusForListObjects:listObjects];
}

/*!
* @brief Creates an array of list objects which should be presented in the menu, expanding any containing objects
 */
- (NSArray *)listObjectsForMenuFromArrayOfListObjects:(NSArray *)listObjects
{
	NSMutableArray	*listObjectArray = [NSMutableArray array];
	
	for (AIListObject *listObject in [[listObjects copy] autorelease]) {
		if ([listObject isKindOfClass:[AIListContact class]]) {
			/* Include if the delegate doesn't specify, or if the delegate approves the contact.
			 * Note that this includes a metacontact itself, not its contained objects.
			 */
			if (!delegateRespondsToShouldIncludeContact || [delegate contactMenu:self shouldIncludeContact:(AIListContact *)listObject]) {
				if (delegateRespondsToValidateContact)
					listObject = [delegate contactMenu:self validateContact:(AIListContact *)listObject];
				if (listObject)
					[listObjectArray addObject:listObject];
			}

		} else if ([listObject isKindOfClass:[AIListGroup class]]) {
			[listObjectArray addObjectsFromArray:[self listObjectsForMenuFromArrayOfListObjects:[(AIListGroup *)listObject uniqueContainedObjects]]];
		}
	}
	
	return listObjectArray;
}

/*!
* @brief Creates an array of NSMenuItems for each AIListObject
 */
- (NSArray *)contactMenusForListObjects:(NSArray *)listObjects
{
	NSMutableArray	*menuItemArray = [NSMutableArray array];
	
	for (AIListObject *listObject in listObjects) {
		// Display groups inline
		if ([listObject isKindOfClass:[AIListGroup class]]) {
			NSArray			*containedListObjects = [self listObjectsForMenuFromArrayOfListObjects:[(AIListObject<AIContainingObject> *)listObject uniqueContainedObjects]];
			
			// If there's any contained list objects, add ourself as a group and add the contained objects.
			if ([containedListObjects count] > 0) {
				// Create our menu item
				NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																							target:self
																							action:nil
																					 keyEquivalent:@""
																				 representedObject:listObject];

				// The group isn't clickable.
				[menuItem setEnabled:NO];
				[self _updateMenuItem:menuItem];
				
				// Add the group and contained objects to the array.
				[menuItemArray addObject:menuItem];
				[menuItemArray addObjectsFromArray:[self contactMenusForListObjects:containedListObjects]];
				
				[menuItem release];
			}
		} else {
			// Just add the menu item.
			NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@""
																						target:self
																						action:@selector(selectContactMenuItem:)
																				 keyEquivalent:@""
																			 representedObject:listObject];
			[self _updateMenuItem:menuItem];
			[menuItemArray addObject:menuItem];
			[menuItem release];
		}

	}
	
	return menuItemArray;
}

/*!
 * @brief Update a menu item to reflect its contact's current status
 */
- (void)_updateMenuItem:(NSMenuItem *)menuItem
{
	AIListObject	*listObject = [menuItem representedObject];
	
	if (listObject) {
		[[menuItem menu] setMenuChangedMessagesEnabled:NO];

		if ([listObject isKindOfClass:[AIListContact class]]) {
			[menuItem setImage:[self imageForListObject:listObject usingUserIcon:shouldUseUserIcon]];
		}
		
		NSString *displayName = listObject.displayName;
		
		if (!shouldUseDisplayName && listObject.formattedUID) {
			displayName = listObject.formattedUID;
		}
		
		[menuItem setTitle:displayName];
		[menuItem setToolTip:(shouldSetTooltip ? [listObject.statusMessage string] : nil)];

		[[menuItem menu] setMenuChangedMessagesEnabled:YES];
	}
}

/*!
 * @brief Update menu when a contact's status changes
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIListContact class]]) {

		//Update menu items to reflect status changes
		if ([inModifiedKeys containsObject:@"Online"] ||
			[inModifiedKeys containsObject:@"Connecting"] ||
			[inModifiedKeys containsObject:@"Disconnecting"] ||
			[inModifiedKeys containsObject:@"IdleSince"] ||
			[inModifiedKeys containsObject:@"StatusType"]) {

			//Note that this will return nil if we don't ahve a menu item for inObject
			NSMenuItem	*menuItem = [self existingMenuItemForContact:(AIListContact *)inObject];

			//Update the changed menu item (or rebuild the entire menu if this item should be removed or added)
			if (delegateRespondsToShouldIncludeContact) {
				BOOL shouldIncludeContact = [delegate contactMenu:self shouldIncludeContact:(AIListContact *)inObject];
				BOOL menuItemExists		  = (menuItem != nil);
				//If we disagree on item inclusion and existence, rebuild the menu.
				if (shouldIncludeContact != menuItemExists) {
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(rebuildMenu) object:nil];

					if (silent) {
						//If it's silent, wait for a pause before performing the actual rebuild
						[self performSelector:@selector(rebuildMenu) withObject:nil afterDelay:1.0];

					} else {
						[self rebuildMenu];
					}
				} else { 
					[self _updateMenuItem:menuItem];
				}
			} else {
				[self _updateMenuItem:menuItem];
			}
		}
	}
	
    return nil;
}

@end
