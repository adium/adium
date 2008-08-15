//
//  AIServiceMenu.m
//  Adium
//
//  Created by Adam Iser on 5/19/05.
//

#import <Adium/AIServiceMenu.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIMenuAdditions.h>

/*!
 * @class AIServiceMenu
 * @brief Class to provide a menu of services
 *
 * See menuOfServicesWithTarget:activeServicesOnly:longDescription:format:
 */
@implementation AIServiceMenu

/*!
 * @brief Sort menu items by title
 */
NSInteger titleSort(NSMenuItem *itemA, NSMenuItem *itemB, void *context)
{
	return [[itemA title] compare:[itemB title] options:NSLiteralSearch];
}

/*!
 * @brief Returns a menu of services.
 *
 * Each menu item's represented object is the AIService it represents.  Services are grouped by 'importance' and sorted alphabetically within groups.
 *
 * @param target Target on which \@selector(selectAccount:) is called when the user makes a selection
 * @param activeServicesOnly If YES, only services for enabled accounts are included. If NO, all possible services are included.
 * @param longDescription If YES, use the service's longer (more verbose) description -- for example, AOL Instant Messenger rather than AIM
 * @param format Allows the description to be placed within a format string. If it is nil, the description alone will be used.
 */
+ (NSMenu *)menuOfServicesWithTarget:(id)target activeServicesOnly:(BOOL)activeServicesOnly
					 longDescription:(BOOL)longDescription format:(NSString *)format
{
	id<AIAccountController> accountController = adium.accountController;
	AIServiceImportance	importance;
	NSUInteger			numberOfItems = 0;
	id					serviceArray;
	
	BOOL targetRespondsToShouldIncludeService = [target respondsToSelector:@selector(serviceMenuShouldIncludeService:)];

	//Prepare our menu
	NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	
	serviceArray = (activeServicesOnly ? (id)[accountController activeServicesIncludingCompatibleServices:YES] : (id)[accountController services]);
	
	//Divide our menu into sections.  This helps separate less important services from the others (sorry guys!)
	for (importance = AIServicePrimary; importance <= AIServiceUnsupported; importance++) {
		NSEnumerator	*enumerator;
		AIService		*service;
		NSMutableArray	*menuItemArray = [[NSMutableArray alloc] init];
		NSMenuItem		*menuItem;
		NSUInteger		currentNumberOfItems;
		BOOL			addedDivider = NO;
		
		//Divider
		currentNumberOfItems = [menu numberOfItems];
		if (currentNumberOfItems > numberOfItems) {
			[menu addItem:[NSMenuItem separatorItem]];
			numberOfItems = currentNumberOfItems + 1;
			addedDivider = YES;
		}
		
		//Insert a menu item for each service of this importance
		enumerator = [serviceArray objectEnumerator];
		while ((service = [enumerator nextObject])) {
			if (([service serviceImportance] == importance) &&
				![service isHidden] &&
				(!targetRespondsToShouldIncludeService || [target serviceMenuShouldIncludeService:service])) {
				NSString	*description = (longDescription ?
											[service longDescription] :
											[service shortDescription]);
				
				menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(format ? 
																						[NSString stringWithFormat:format,description] :
																						description)
																				target:target 
																				action:@selector(selectServiceType:) 
																		 keyEquivalent:@""];
				[menuItem setRepresentedObject:service];
				[menuItem setImage:[AIServiceIcons serviceIconForService:service
																	type:AIServiceIconSmall
															   direction:AIIconNormal]];
				[menuItemArray addObject:menuItem];
				[menuItem release];
			}
		}

		[menuItemArray sortUsingFunction:titleSort context:NULL];
		
		for (menuItem in menuItemArray) {
			[menu addItem:menuItem];
		}
		
		[menuItemArray release];

		//If we added a divider but didn't add any items, remove it
		currentNumberOfItems = [menu numberOfItems];
		if (addedDivider && (currentNumberOfItems <= numberOfItems) && (currentNumberOfItems > 0)) {
			[menu removeItemAtIndex:(currentNumberOfItems-1)];
		}
	}
	
	return [menu autorelease];
}	

@end
