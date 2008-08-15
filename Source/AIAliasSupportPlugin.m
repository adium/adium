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

#import "AIAliasSupportPlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import "AIContactInfoWindowController.h"
#import "AIContactListEditorPlugin.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMutableOwnerArray.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>

#define ALIASES_DEFAULT_PREFS		@"Alias Defaults"
#define DISPLAYFORMAT_DEFAULT_PREFS	@"Display Format Defaults"

#define CONTACT_NAME_MENU_TITLE		AILocalizedString(@"Contact Name Format",nil)
#define ALIAS						AILocalizedString(@"Alias",nil)
#define ALIAS_SCREENNAME			AILocalizedString(@"Alias (User Name)",nil)
#define SCREENNAME_ALIAS			AILocalizedString(@"User Name (Alias)",nil)
#define SCREENNAME					AILocalizedString(@"User Name",nil)

@interface AIAliasSupportPlugin ()
- (NSSet *)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject notify:(BOOL)notify;
- (NSMenu *)_contactNameMenu;
@end

/*!
 * @class AIAliasSupportPlugin
 * @brief Plugin to handle applying aliases to contacts
 *
 * This plugin applies aliases to contacts.  It also responsible for generating the "long display name"
 * used in the contact list which may include some combination of alias and screen name.
 */
@implementation AIAliasSupportPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
    //Register our default preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:ALIASES_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_ALIASES];
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:DISPLAYFORMAT_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_DISPLAYFORMAT];
	
	//Create the menu item
	menuItem_contactName = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:CONTACT_NAME_MENU_TITLE
																				 target:nil
																				 action:nil
																		  keyEquivalent:@""] autorelease];
	
	//Add the menu item (which will have _contactNameMenu as its submenu)
	[adium.menuController addMenuItem:menuItem_contactName toLocation:LOC_View_Additions];
	
	menu_contactSubmenu = [[self _contactNameMenu] retain];
	[menuItem_contactName setSubmenu:menu_contactSubmenu];

    //Observe preferences changes
    [[adium notificationCenter] addObserver:self
								   selector:@selector(applyAliasRequested:)
									   name:Contact_ApplyDisplayName
									 object:nil];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_DISPLAYFORMAT];	
}

/*!
 * @brief Uninstall plugin
 */
- (void)uninstallPlugin
{
    [[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[adium notificationCenter] removeObserver:self];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[menu_contactSubmenu release];
	[super dealloc];
}

/*!
 * @brief Change the format for the long display name used in the contact list
 *
 * @param sender An NSMenuItem which was clicked. Its tag should be an AIDisplayNameType.
 */
-(IBAction)changeFormat:(id)sender
{
	[adium.preferenceController setPreference:[NSNumber numberWithInteger:[sender tag]]
										 forKey:@"Long Display Format"
										  group:PREF_GROUP_DISPLAYFORMAT];
}

/*!
 * @brief Update list object
 *
 * As contacts are created or a formattedUID is received, update their alias, display name, and long display name
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
    if ((inModifiedKeys == nil) || ([inModifiedKeys containsObject:@"FormattedUID"])) {
		return [self _applyAlias:[inObject preferenceForKey:@"Alias"
													  group:PREF_GROUP_ALIASES 
									  ignoreInheritedValues:YES]
						toObject:inObject
						  notify:NO];
    }
	
	return nil;
}

/*!
 * @brief Preferences changed. Our only preference is for the Long Display Name format
 *
 * Update the checked menu item since this is not done automatically.
 * Update all list objects so we make use of the new long display format preference.
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Clear old checkmark
	[[menu_contactSubmenu itemWithTag:displayFormat] setState:NSOffState];
	
	//Load new displayFormat
	displayFormat = [[prefDict objectForKey:@"Long Display Format"] integerValue]; 
	
	//Set new checkmark
	[[menu_contactSubmenu itemWithTag:displayFormat] setState:NSOnState];
	
	if (firstTime) {
		//Register ourself as a handle observer
		[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
	} else {
		//Update all existing contacts
		[[AIContactObserverManager sharedManager] updateAllListObjectsForObserver:self];

	}
}

/*!
 * @brief Notification was posted to apply a specific alias
 *
 * This is used from elsewhere in Adium to request the alias of the object be updated. It's a bit ugly, really.
 * The object of the notification is an AIListObject.
 * The userInfo is a dictionary with an NSNumber on key @"Notify" indicating if a 'changed' notification should be sent out as a result.
 *		If this is NO, it is equivalent to a 'silent' update.
 * The user info dictionary also has the desired NSString alias on the key @"Alias".
 *		If this is not specified, the object's preference is reloaded.
 */
- (void)applyAliasRequested:(NSNotification *)notification
{
	AIListObject	*object = [notification object];
	NSDictionary	*userInfo = [notification userInfo];
	
	NSNumber		*shouldNotifyNumber = [userInfo objectForKey:@"Notify"];
	
	NSString		*alias = [userInfo objectForKey:@"Alias"];
	if (!alias) {
		alias = [object preferenceForKey:@"Alias"
								   group:PREF_GROUP_ALIASES 
				   ignoreInheritedValues:YES];
	}
	
	[self _applyAlias:alias
			 toObject:object
			   notify:(shouldNotifyNumber ? [shouldNotifyNumber boolValue] : NO)];
}

//Private ---------------------------------------------------------------------------------------
/*!
 * @brief Apply an alias to an object
 *
 * This does not save any preferences.
 *
 * @param inAlias The alias to apply. 
 * @param inObject The object to which the alias should be applied
 * @param notify YES if a notification should be sent out after the alias is applied
 */
- (NSSet *)_applyAlias:(NSString *)inAlias toObject:(AIListObject *)inObject notify:(BOOL)notify
{
	NSSet				*modifiedAttributes;
    NSString			*displayName = nil;
    NSString			*longDisplayName = nil;
    NSString			*formattedUID = nil;

	//Apply the alias
	[[inObject displayArrayForKey:@"Display Name" create:(inAlias != nil)] setObject:inAlias withOwner:self priorityLevel:High_Priority];

	//Get the displayName which is now active for the object
	displayName = [inObject displayName];

    //Build and set the Long Display Name
	if ([inObject isKindOfClass:[AIListContact class]]) {
		switch (displayFormat)
		{
			case AINameFormat_DisplayName:
				longDisplayName = displayName;
				break;
				
			case AINameFormat_DisplayName_ScreenName:
				formattedUID = [inObject formattedUID];
				
				if (!displayName || !formattedUID || [displayName isEqualToString:formattedUID]) {
					longDisplayName = displayName;
				} else {
					longDisplayName = [NSString stringWithFormat:@"%@ (%@)",displayName,formattedUID];
				}
					break;
				
			case AINameFormat_ScreenName_DisplayName:
				formattedUID = [inObject formattedUID];
				if (!displayName || !formattedUID || [displayName isEqualToString:formattedUID]) {
					longDisplayName = displayName;
				} else {
					longDisplayName = [NSString stringWithFormat:@"%@ (%@)",formattedUID,displayName];
				}
					break;
				
			case AINameFormat_ScreenName:
				//??? - How should this be handled for metaContacts?  What if there are no aliases set?
				formattedUID = [inObject formattedUID];
				longDisplayName = (formattedUID ? formattedUID : displayName);
				break;
				
			default:
				longDisplayName = nil;
				break;
		}
		
		//Apply the Long Display Name
		[[inObject displayArrayForKey:@"Long Display Name" create:(longDisplayName &&
																   ![longDisplayName isEqualToString:displayName])] setObject:longDisplayName
																													withOwner:self];
	}

	modifiedAttributes = [NSSet setWithObjects:@"Display Name", @"Long Display Name", nil];

	//If notify is YES, send out a manual listObjectAttributesChanged notice; 
	//if NO, the observer methods will be handling it
	if (notify) {
		[[AIContactObserverManager sharedManager] listObjectAttributesChanged:inObject
												  modifiedKeys:modifiedAttributes];
	}
	
	return modifiedAttributes;
}

/*!
 * @brief Generate the menu of long display name format choices
 *
 * @result The autoreleased menu
 */
- (NSMenu *)_contactNameMenu
{
	
	NSMenu		*choicesMenu;
	NSMenuItem  *menuItem;
	
	choicesMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@""] autorelease];
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ALIAS
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:AINameFormat_DisplayName];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:ALIAS_SCREENNAME
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:AINameFormat_DisplayName_ScreenName];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SCREENNAME_ALIAS
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:AINameFormat_ScreenName_DisplayName];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:SCREENNAME
																	 target:self
																	 action:@selector(changeFormat:)
															  keyEquivalent:@""] autorelease];
    [menuItem setTag:AINameFormat_ScreenName];
    [choicesMenu addItem:menuItem];
	
	return choicesMenu;
}

@end
