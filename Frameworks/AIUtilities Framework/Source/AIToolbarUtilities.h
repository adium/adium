/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */


/*!	@class AIToolbarUtilities <AIToolbarUtilities.h> <AIUtilities/AIToolbarUtilities.h>
 *	@brief Helpful methods for creating window toolbar items.
 *
 *	Methods for conveniently creating, storing, and retrieivng \c NSToolbarItem objects.
 */
@interface AIToolbarUtilities : NSObject {

}

/*!	@brief Create an \c NSToolbarItem and add it to an \c NSDictionary
 *
*	Calls <code>+toolbarItemWithIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:</code> and adds the result to a dictionary (\a theDict).
 *
 *	@param theDict A dictionary in which to store the \c NSToolbarItem.
 *	@param identifier
 *	@param label
 *	@param paletteLabel
 *	@param toolTip
 *	@param target
 *	@param action
 *	@param settingSelector Selector to call on the \c NSToolbarItem after it is created.  It should take a single object, which will be \a itemContent.  May be \c nil.
 *	@param itemContent Object for \c settingSelector.  May be \c nil.
 *	@param menu	A menu to set on the \c NSToolbarItem.  It will be automatically encapsulated by an \c NSMenuItem as \c NSToolbarItem requires.
 */
+ (void)addToolbarItemToDictionary:(NSMutableDictionary *)theDict 
					withIdentifier:(NSString *)identifier
							 label:(NSString *)label
					  paletteLabel:(NSString *)paletteLabel
						   toolTip:(NSString *)toolTip
							target:(id)target
				   settingSelector:(SEL)settingSelector
					   itemContent:(id)itemContent
							action:(SEL)action
							  menu:(NSMenu *)menu;

/*!	@brief Convenience method for creating an \c NSToolbarItem
 *
 *	Parameters not discussed below are simply set using the \c NSToolbarItem setters; see its documentation for details.
 *	@param identifier
 *	@param label
 *	@param paletteLabel
 *	@param toolTip
 *	@param target
 *	@param action
 *	@param settingSelector Selector to call on the \c NSToolbarItem after it is created.  It should take a single object, which will be \a itemContent.  May be \c nil.
 *	@param itemContent Object for \c settingSelector.  May be \c nil.
 *	@param menu	A menu to set on the \c NSToolbarItem.  It will be automatically encapsulated by an \c NSMenuItem as \c NSToolbarItem requires.
 */
+ (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier
									   label:(NSString *)label
								paletteLabel:(NSString *)paletteLabel
									 toolTip:(NSString *)toolTip
									  target:(id)target
							 settingSelector:(SEL)settingSelector
								 itemContent:(id)itemContent
									  action:(SEL)action
										menu:(NSMenu *)menu;

/*!	@brief Retrieve a new \c NSToolbarItem instance based on a dictionary's entry
 *
 *	Retrieves a new copy of the \c NSToolbarItem stored in \c theDict with the \c itemIdentifier identifier.  This should be used rather than simply copying the existing \c NSToolbarItem so custom copying behaviors to maintain custom view, image, and menu settings are utilized.
 *	@param theDict The source \c NSDictionary.
 *	@param itemIdentifier The identifier of the \c NSToolbarItem previous stored with <code>+addToolbarItemToDictionary:withIdentifier:label:paletteLabel:toolTip:target:settingSelector:itemContent:action:menu:</code>.
 *	@return The retrieved \c NSToolbarItem.
 */
+ (NSToolbarItem *)toolbarItemFromDictionary:(NSDictionary *)theDict withIdentifier:(NSString *)itemIdentifier;

@end

@interface NSObject (AIToolbarUtilitiesAdditions)
- (void)setToolbarItem:(NSToolbarItem *)item;
@end

