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

#import "AIListObjectContentsPlugin.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIContactHidingController.h>

#define META_TOOLTIP_ICON_SIZE NSMakeSize(11,11)

#define EXPAND_CONTACT		AILocalizedString(@"Expand Combined Contact", nil)
#define COLLAPSE_CONTACT	AILocalizedString(@"Collapse Combined Contact", nil)

#define MAX_CONTACTS 20
#define MORE_CONTACTS_STRING AILocalizedString(@"%d others", @"Used to describe omitted contacts.\
                                                               The first parameter is the number of omitted contacts")

@interface AIListObjectContentsPlugin ()
- (void)toggleMetaContactExpansion:(id)sender;
- (void)inspectedObjectDidChange:(NSNotification *)inNotification;
@end

/*!
 * @class AIListObjectContentsPlugin
 * @brief Tooltip component: Show the contacts contained by metaContacts, with service and status state.
 */
@implementation AIListObjectContentsPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
    //Install our tooltip entry
    [adium.interfaceController registerContactListTooltipEntry:self secondaryEntry:YES];
	
	contextualMenuItem = [[NSMenuItem alloc] initWithTitle:EXPAND_CONTACT
													target:self
													action:@selector(toggleMetaContactExpansion:)
											 keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:contextualMenuItem
									   toLocation:Context_Contact_ListAction];

	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(inspectedObjectDidChange:)
									   name:AIContactInfoInspectorDidChangeInspectedObject
									 object:nil];
}

/*!
 * @brief Tooltip label
 *
 * @result A label, or nil if no tooltip entry should be shown
 */
- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([inObject conformsToProtocol:@protocol(AIContainingObject)] || 
		([inObject isKindOfClass:[AIListContact class]] &&
		![inObject isKindOfClass:[AIListBookmark class]])) {
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
    NSMutableString				*entryString = nil;
	NSArray						*listContacts = nil;
	NSUInteger					count = 0;
	BOOL						shouldAppendString = NO;
	id<AIContainingObject>		containingObject = nil;
	
	entry = [[NSMutableAttributedString alloc] init];
	entryString = [entry mutableString];
	
	if ([inObject conformsToProtocol:@protocol(AIContainingObject)]) {
		containingObject = (id<AIContainingObject>)inObject;
		
		listContacts = [containingObject uniqueContainedObjects];
	} else  if ([inObject isKindOfClass:[AIListContact class]]) {
		listContacts = [NSArray arrayWithObject:inObject];
	}
		
	for (AIListContact *contact in listContacts) {
		NSImage	*statusIcon, *serviceIcon;
		
		if (containingObject != nil && [inObject isKindOfClass:[AIListGroup class]] && 
			![[AIContactHidingController sharedController] visibilityOfListObject:contact inContainer:containingObject]) {
			continue;
		}
				
		if (shouldAppendString) {
			[entryString appendString:@"\r"];
		} else {
			shouldAppendString = YES;
		}
				
		// If there are a lot of contacts, just stop.
		if (++count >= MAX_CONTACTS) {
			[entryString appendString:[NSString stringWithFormat:MORE_CONTACTS_STRING, listContacts.count - MAX_CONTACTS]];
			break;
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

			[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];

			[entryString appendString:@" "];
		}
			
		if ([inObject isKindOfClass:[AIMetaContact class]]) {
			[entryString appendString:contact.formattedUID];
		} else if ([inObject isKindOfClass:[AIListGroup class]] ||
				   [inObject isKindOfClass:[AIListContact class]]) {
			[entryString appendString:contact.displayName];
		}
				
		serviceIcon = [[AIServiceIcons serviceIconForObject:contact type:AIServiceIconSmall direction:AIIconNormal]
						imageByScalingToSize:META_TOOLTIP_ICON_SIZE];
		if (serviceIcon) {
			NSTextAttachment		*attachment;
			NSTextAttachmentCell	*cell;
					
			cell = [[NSTextAttachmentCell alloc] init];
			[cell setImage:serviceIcon];
					
			attachment = [[NSTextAttachment alloc] init];
			[attachment setAttachmentCell:cell];
			
			[entryString appendString:@" "];
			[entry appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
		}
	}
    
    return entry;
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
		[oldListObject boolValueForProperty:@"TemporaryMetaContactExpansion"]) {
		[oldListObject setValue:nil
					forProperty:@"TemporaryMetaContactExpansion"
						 notify:NotifyNever];
		[[NSNotificationCenter defaultCenter] postNotificationName:AIPerformCollapseItemNotification
												  object:oldListObject];
	}

	if (newListObject && [newListObject isKindOfClass:[AIMetaContact class]] &&
		![(AIMetaContact *)newListObject isExpanded]) {
		[newListObject setValue:[NSNumber numberWithBool:YES]
					forProperty:@"TemporaryMetaContactExpansion"
						 notify:NotifyNever];
		[[NSNotificationCenter defaultCenter] postNotificationName:AIPerformExpandItemNotification
												  object:newListObject];
	}
}

#pragma mark Menu
- (void)toggleMetaContactExpansion:(id)sender
{
	AIListObject *listObject = adium.menuController.currentContextMenuObject;
	if ([listObject isKindOfClass:[AIMetaContact class]]) {
		BOOL currentlyExpanded = [(AIMetaContact *)listObject isExpanded];
		
		if (currentlyExpanded) {
			[[NSNotificationCenter defaultCenter] postNotificationName:AIPerformCollapseItemNotification
													 object:listObject];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:AIPerformExpandItemNotification
													 object:listObject];
		}
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *listObject = adium.menuController.currentContextMenuObject;
	return ([listObject isKindOfClass:[AIMetaContact class]] &&
			[(AIMetaContact *)listObject uniqueContainedObjectsCount] > 1);
}

- (void)menu:(NSMenu *)menu needsUpdateForMenuItem:(NSMenuItem *)menuItem
{
	AIListObject *listObject = adium.menuController.currentContextMenuObject;
	if (menuItem == contextualMenuItem) {
		if ([listObject isKindOfClass:[AIMetaContact class]] &&
			[(AIMetaContact *)listObject uniqueContainedObjectsCount] > 1) {
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
