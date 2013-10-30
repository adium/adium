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

#import <Adium/AIActionDetailsPane.h>
#import <Adium/ESContactAlertsViewController.h>

@implementation AIActionDetailsPane

/*!
 * @brief Return a new action details pane
*/
+ (AIActionDetailsPane *)actionDetailsPane
{
    return [[self alloc] init];
}

/*!
 * @brief Return a new action details pane, passing plugin
 * @param inPlugin The plugin associated with this pane
 */
+ (AIActionDetailsPane *)actionDetailsPaneForPlugin:(id)inPlugin
{
    return [[self alloc] initForPlugin:inPlugin];
}

/*!
 * @brief Called by subclasses when the header should be updated
 */
- (void)detailsForHeaderChanged
{
   [[NSNotificationCenter defaultCenter] postNotificationName:CONTACT_ALERTS_DETAILS_FOR_HEADER_CHANGED
											 object:self];
}

//For subclasses -------------------------------------------------------------------------------

/*!
 * @brief Called only when the pane is displayed a result of its action being selected
 *
 * @param inDetails A previously created details dicionary, or nil if none exists
 * @param inObject The object for which to configure
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	
}

/*!
 * @brief Configure for an event
 *
 * Called whenever the event changes.  Most subclasses will have no no need for this method;
 * it should only be used for custom handling of particular events, and only with good reason.
 *
 * Example: Some options in the Speak Event action are only relevant to message-related events.
 *
 * @param eventID The event ID
 * @param inObject The object for which to configure
 */
- (void)configureForEventID:(NSString *)eventID listObject:(AIListObject *)inObject
{
	
}

/*!
 * @brief Return the details associated with this action
 *
 * This will be called automatically when an action is to be saved.  It should generated and return
 * an <tt>NSDictionary</tt> which will subsequently be passed when executing or editing this action.
 *
 * @result The details dictionary.  It must be plist-encodable.
 */
- (NSDictionary *)actionDetails
{
	return nil;
}

@end
