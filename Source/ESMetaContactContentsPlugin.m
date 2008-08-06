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

#import "ESMetaContactContentsPlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>

#define META_TOOLTIP_ICON_SIZE NSMakeSize(11,11)

#define EXPAND_CONTACT		AILocalizedString(@"Expand Combined Contact", nil)
#define COLLAPSE_CONTACT	AILocalizedString(@"Collapse Combined Contact", nil)
/*!
 * @class ESMetaContactContentsPlugin
 * @brief Tooltip component: Show the contacts contained by metaContacts, with service and status state.
 */
@implementation ESMetaContactContentsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our tooltip entry
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
	
	contextualMenuItem = [[NSMenuItem alloc] initWithTitle:EXPAND_CONTACT
													target:self
													action:@selector(toggleMetaContactExpansion:)
											 keyEquivalent:@""];
	[[adium menuController] addContextualMenuItem:contextualMenuItem
									   toLocation:Context_Contact_ListAction];

	[[adium notificationCenter] addObserver:self
								   selector:@selector(inspectedObjectDidChange:)
									   name:AIContactInfoInspectorDidChangeInspectedObject
									 object:nil];
}

- (void)dealloc
{
	[contextualMenuItem release]; contextualMenuItem = nil;

	[super dealloc];
}

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		return AILocalizedString(@"Contacts",nil);
	}
	
	return nil;
}

/*!
 * @brief Tooltip entry
 *
 * @result The tooltip entry, or nil if no tooltip should be shown
 */
- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSMutableAttributedString	*entry = nil;
	
	if ([inObject isKindOfClass:[AIMetaContact class]]) {
		NSArray				*listContacts = [(AIMetaContact *)inObject listContacts];
		
		//Only display the contents if it has more than one contact within it.
		if ([listContacts count] > 1) {
			NSMutableString	*entryString;
			AIListContact	*contact;
			NSEnumerator	*enumerator;
			BOOL			shouldAppendString = NO;
			BOOL			shouldAppendServiceIcon = ![(AIMetaContact *)inObject containsOnlyOneService];

			entry = [[NSMutableAttributedString alloc] init];
			entryString = [entry mutableString];
			
			enumerator = [listContacts objectEnumerator];
			while ((contact = [enumerator nextObject])) {
				NSImage	*statusIcon, *serviceIcon;
				
				if (shouldAppendString) {
					[entryString appendString:@"\r"];
				} else {
					shouldAppendString = YES;
				}
				
				statusIcon = [[AIStatusIcons statusIconForListObject:contact
																type:AIStatusIconTab
														   direction:AIIconNormal] imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
				
				if (statusIcon) {
					NSTextAttachment		*attachment;
					NSTextAttachmentCell	*cell;
						
					cell = [[NSTextAttachmentCell alloc] init];
					[cell setImage:statusIcon];
					
					attachment = [[NSTextAttachment alloc] init];
					[attachment setAttachmentCell:cell];
					[cell release];

					[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
					[attachment release];

					[entryString appendString:@" "];
				}
				
				[entryString appendString:[contact formattedUID]];
				
				if (shouldAppendServiceIcon) {
					serviceIcon = [[AIServiceIcons serviceIconForObject:contact type:AIServiceIconSmall direction:AIIconNormal]
									imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
					if (serviceIcon) {
						NSTextAttachment		*attachment;
						NSTextAttachmentCell	*cell;
						
						cell = [[NSTextAttachmentCell alloc] init];
						[cell setImage:serviceIcon];
						
						attachment = [[NSTextAttachment alloc] init];
						[attachment setAttachmentCell:cell];
						[cell release];

						[entryString appendString:@" "];
						[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
						[attachment release];
					}
				}
			}
		}
	}
    
    return [entry autorelease];
}

- (BOOL)shouldDisplayInContactInspector
{
	return YES;
}

#pragma mark Automatic temporary expansion
- (void)inspectedObjectDidChange:(NSNotification *)inNotification
{
	AIListObject *oldListObject = [[inNotification userInfo] objectForKey:KEY_PREVIOUS_INSPECTED_OBJECT];
	AIListObject *newListObject = [[inNotification userInfo] objectForKey:KEY_NEW_INSPECTED_OBJECT];

	if (oldListObject && [oldListObject isKindOfClass:[AIMetaContact class]] &&
		[[oldListObject valueForProperty:@"TemporaryMetaContactExpansion"] boolValue]) {
		[oldListObject setValue:nil
					forProperty:@"TemporaryMetaContactExpansion"
						 notify:NotifyNever];
		[[adium notificationCenter] postNotificationName:AIPerformCollapseItemNotification
												  object:oldListObject];
	}

	if (newListObject && [newListObject isKindOfClass:[AIMetaContact class]] &&
		![(AIMetaContact *)newListObject isExpanded]) {
		[newListObject setValue:[NSNumber numberWithBool:YES]
					forProperty:@"TemporaryMetaContactExpansion"
						 notify:NotifyNever];
		[[adium notificationCenter] postNotificationName:AIPerformExpandItemNotification
												  object:newListObject];
	}
}

#pragma mark Menu
- (void)toggleMetaContactExpansion:(id)sender
{
	AIListObject *listObject = [[adium menuController] currentContextMenuObject];
	if ([listObject isKindOfClass:[AIMetaContact class]]) {
		BOOL currentlyExpanded = [(AIMetaContact *)listObject isExpanded];
		
		if (currentlyExpanded) {
			[[adium notificationCenter] postNotificationName:AIPerformCollapseItemNotification
													 object:listObject];
		} else {
			[[adium notificationCenter] postNotificationName:AIPerformExpandItemNotification
													 object:listObject];
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *listObject = [[adium menuController] currentContextMenuObject];
	return ([listObject isKindOfClass:[AIMetaContact class]] &&
			[(AIMetaContact *)listObject containsMultipleContacts]);
}

- (void)menu:(NSMenu *)menu needsUpdateForMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *listObject = [[adium menuController] currentContextMenuObject];
	if (menuItem == contextualMenuItem) {
		if ([listObject isKindOfClass:[AIMetaContact class]] &&
			[(AIMetaContact *)listObject containsMultipleContacts]) {
			BOOL currentlyExpanded = [(AIMetaContact *)listObject isExpanded];
			
			if (currentlyExpanded) {
				[menuItem setTitle:COLLAPSE_CONTACT];
			} else {
				[menuItem setTitle:EXPAND_CONTACT];				
			}
		} else {
			[menuItem setTitle:EXPAND_CONTACT];
		}
	}
}

@end
