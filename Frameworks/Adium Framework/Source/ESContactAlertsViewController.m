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

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>
#import <Adium/CSNewContactAlertWindowController.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/ESContactAlertsViewController.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIVariableHeightFlexibleColumnsOutlineView.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIScaledImageCell.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

#define VERTICAL_ROW_PADDING	6
#define MINIMUM_IMAGE_HEIGHT		20.0f
#define MINIMUM_ROW_HEIGHT			/* 32.0f */ 16.0f

#define	EVENT_COLUMN_INDEX		1

@interface ESContactAlertsViewController ()
- (BOOL)outlineView:(NSOutlineView *)inOutlineView extendToEdgeColumn:(NSInteger)column ofRow:(NSInteger)row;
- (void)configureEventSummaryOutlineView;
- (void)reloadSummaryData;
- (void)deleteContactActionsInArray:(NSArray *)contactEventArray;

- (void)calculateAllHeights;
- (void)calculateHeightForItem:(id)item;
@end

int alertAlphabeticalSort(id objectA, id objectB, void *context);
int globalAlertAlphabeticalSort(id objectA, id objectB, void *context);

//#define HEIGHT_DEBUG

@implementation ESContactAlertsViewController

//Configure the preference view
- (void)awakeFromNib
{
	AILogWithSignature(@"");
	[expandStateDict release]; expandStateDict = [[NSMutableDictionary alloc] init];
	[requiredHeightDict release]; requiredHeightDict = [[NSMutableDictionary alloc] init];

	//Configure Table view
	[self configureEventSummaryOutlineView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(outlineViewColumnDidResize:)
									   name:NSOutlineViewColumnDidResizeNotification
									 object:outlineView_summary];
	
	//Manually size and position our buttons
	{
		NSRect	newFrame, oldFrame;

		//Edit, right justified and far enough away from Remove that it can't conceivably overlap
		oldFrame = [button_edit frame];
		
		/* Note: This is using the "Buttons" table from the main bundle. The string gets into the strings file there from other parts of Adium;
		 * this is incorrect but not particularly worth fixing.
		 */
		[button_edit setTitle:AILocalizedStringFromTable(@"Edit", @"Buttons", "Verb 'edit' on a button")];
		[button_edit sizeToFit];
		newFrame = [button_edit frame];
		if (newFrame.size.width < oldFrame.size.width) newFrame.size.width = oldFrame.size.width;
		newFrame.origin.x = oldFrame.origin.x + oldFrame.size.width - newFrame.size.width;
		[button_edit setFrame:newFrame];
	}
		
	[button_add setToolTip:AILocalizedString(@"Add an action for the selected event", nil)];
	[button_delete setToolTip:AILocalizedString(@"Remove the selected action(s)", nil)];
	[button_edit setToolTip:AILocalizedString(@"Configure the selected action", nil)];
	
	[outlineView_summary accessibilitySetOverrideValue:AILocalizedString(@"Events", nil)
										  forAttribute:NSAccessibilityDescriptionAttribute];

	//Update enable state of our buttons
	[self outlineViewSelectionDidChange:nil];
		
	configureForGlobal = NO;
	showEventsInEditSheet = NO;

	//
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTACT_ALERTS];
}

//Preference view is closing - stop observing preferences immediately, even if we aren't immediately deallocating
- (void)viewWillClose
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	//Ensure that we have unregistered as a preference observer
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[outlineView_summary setDelegate:nil];
	[outlineView_summary setDataSource:nil];

	[editingPanel release]; editingPanel = nil;
	[contactAlertsEvents release]; contactAlertsEvents = nil;
	[contactAlertsActions release]; contactAlertsActions = nil;
	[listObject release]; listObject = nil;
	[expandStateDict release]; expandStateDict = nil;
	[requiredHeightDict release]; requiredHeightDict = nil;

	// I don't think this needs to be released, because the contact-specific
	// alerts view does not appear to get released. But anyway...
	[targetEventID release]; targetEventID = nil;

	[super dealloc];
}

- (void)setDelegate:(id)inDelegate
{
	NSParameterAssert([inDelegate respondsToSelector:@selector(contactAlertsViewController:updatedAlert:oldAlert:)]);
	NSParameterAssert([inDelegate respondsToSelector:@selector(contactAlertsViewController:deletedAlert:)]);
	delegate = inDelegate;
}

- (id)delegate
{
	return delegate;
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification
{
	[self calculateAllHeights];
	[outlineView_summary reloadData];
//	[outlineView_summary noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [outlineView_summary numberOfRows]-1)]];
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inObject
{
	[self configureForListObject:inObject showingAlertsForEventID:nil];
}

- (void)configureForListObject:(AIListObject *)inObject showingAlertsForEventID:(NSString *)inTargetEventID
{
	//Cancel any existing edit/add panel, since we're no longer looking at the same object
	if (listObject != inObject) {
		if (editingPanel) {
			[editingPanel cancel:nil];
			[editingPanel release]; editingPanel = nil;
		}

		//Configure for the list object, using the highest-up metacontact if necessary
		[listObject release];
		listObject = ([inObject isKindOfClass:[AIListContact class]] ?
					  [(AIListContact *)inObject parentContact] :
					  inObject);
		[listObject retain];
		
		[targetEventID release];
		targetEventID = [inTargetEventID retain];
		
		//
		[self preferencesChangedForGroup:nil key:nil object:nil preferenceDict:nil firstTime:NO];
	}
}

//Alerts have changed
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (firstTime || (!object || object == listObject)) {
		//Update our list of alerts
		[self reloadSummaryData];
	}
}

//Alert Editing --------------------------------------------------------------------------------------------------------
#pragma mark Actions
//Add new alert
- (IBAction)addAlert:(id)sender
{
	NSString	*defaultEventID;
	id			item = [outlineView_summary itemAtRow:[outlineView_summary selectedRow]];

	if ([contactAlertsActions containsObjectIdenticalTo:item]) {
		defaultEventID = [contactAlertsEvents objectAtIndex:[contactAlertsActions indexOfObjectIdenticalTo:item]];
		
	} else {
		defaultEventID = [item objectForKey:KEY_EVENT_ID];
	}
	
	editingPanel = [[CSNewContactAlertWindowController editAlert:nil 
												   forListObject:listObject
														onWindow:[view window]
												 notifyingTarget:self
											  configureForGlobal:configureForGlobal
												  defaultEventID:defaultEventID] retain];
}

//Edit existing alert
- (IBAction)editAlert:(id)sender
{
	int	selectedRow = [outlineView_summary selectedRow];
	if (selectedRow >= 0 && selectedRow < [outlineView_summary numberOfRows]) {
		NSDictionary	*alert = [outlineView_summary itemAtRow:selectedRow];
		
		editingPanel = [[CSNewContactAlertWindowController editAlert:alert
													   forListObject:listObject
															onWindow:[view window]
													 notifyingTarget:self
												  configureForGlobal:configureForGlobal
													  defaultEventID:nil] retain];
	}
}

//Delete an alert
- (IBAction)deleteAlert:(id)sender
{
	unsigned int selectedRow = [outlineView_summary selectedRow];
	if (selectedRow != -1) {
		id	item = [outlineView_summary itemAtRow:selectedRow];
		
		[item retain];

		if ([contactAlertsActions containsObjectIdenticalTo:item]) {
			/* Deleting an entire event */
			
			NSArray		*contactEvents = (NSArray *)item;
			unsigned	contactEventsCount = [contactEvents count];
			
			if (contactEventsCount > 1) {
				//Warn before deleting more than one event simultaneously
				NSBeginAlertSheet(AILocalizedString(@"Delete Event?", nil),
								  AILocalizedString(@"OK", nil),
								  AILocalizedString(@"Cancel", nil),
								  nil, /*otherButton*/
								  [view window],
								  self,
								  @selector(sheetDidEnd:returnCode:contextInfo:),
								  NULL, /* didDismissSelector */
								  contactEvents,
								  AILocalizedString(@"Remove the %i actions associated with this event?", nil), contactEventsCount);
			} else {
				//Delete a single event immediately
				[self deleteContactActionsInArray:contactEvents];
			}

		} else {
			/* Deleting a single action */
			[adium.contactAlertsController removeAlert:item
										  fromListObject:listObject];

			if (delegate) {
				[delegate contactAlertsViewController:self
										 deletedAlert:item];
			}
			
			//The deletion changed our selection
			[self outlineViewSelectionDidChange:nil];
		}
		[item release];

	} else {
		NSBeep();
	}
}

/*!
 * @brief Warning sheet for deleting multiple events ended
 *
 * If the user pressed OK, go ahead with deleting the events.
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		[self deleteContactActionsInArray:(NSArray *)contextInfo];
	}
}

//Callback from 'new alert' panel.  (Add the alert, or update existing alert)
- (void)alertUpdated:(NSDictionary *)newAlert oldAlert:(NSDictionary *)oldAlert
{
	if (newAlert) {
		//If this was an edit, remove the old alert first
		if (oldAlert) {
			[[oldAlert retain] autorelease];
			[adium.contactAlertsController removeAlert:oldAlert fromListObject:listObject];
		}

		//Add the new alert
    	[adium.contactAlertsController addAlert:newAlert toListObject:listObject setAsNewDefaults:YES];

		if (delegate) {
			[delegate contactAlertsViewController:self
									 updatedAlert:newAlert
										 oldAlert:oldAlert];
		}

		//Update all heights, since there's been a change
		[self calculateAllHeights];
	}

	[editingPanel release]; editingPanel = nil;
}

#pragma mark Outline view
/*!
 * @brief Configure the event summary outline view
 */
- (void)configureEventSummaryOutlineView
{
	AIScaledImageCell				*imageCell;
	AIImageTextCell					*imageTextCell;
	AIVerticallyCenteredTextCell	*verticallyCenteredTextCell;
	
	imageCell = [[AIScaledImageCell alloc] init];
	[imageCell setAlignment:NSCenterTextAlignment];
	[imageCell setMaxSize:NSMakeSize(MINIMUM_IMAGE_HEIGHT, MINIMUM_IMAGE_HEIGHT)];
	[[outlineView_summary tableColumnWithIdentifier:@"image"] setDataCell:imageCell];
	[imageCell release];

	imageTextCell = [[AIImageTextCell alloc] init];
	[imageTextCell setMaxImageWidth:MINIMUM_ROW_HEIGHT];
	[imageTextCell setLineBreakMode:NSLineBreakByWordWrapping];
	[[outlineView_summary tableColumnWithIdentifier:@"event"] setDataCell:imageTextCell];
	[imageTextCell release];
	
	verticallyCenteredTextCell = [[AIVerticallyCenteredTextCell alloc] init];
	[verticallyCenteredTextCell setFont:[NSFont systemFontOfSize:10]];
	[[outlineView_summary tableColumnWithIdentifier:@"action"] setDataCell:verticallyCenteredTextCell];
	[verticallyCenteredTextCell release];

	[outlineView_summary setUsesAlternatingRowBackgroundColors:YES];
	[outlineView_summary setIntercellSpacing:NSMakeSize(6.0,6.0)];
	[outlineView_summary setIndentationPerLevel:0];
	[outlineView_summary setTarget:self];
	[outlineView_summary setDelegate:self];
	[outlineView_summary setDataSource:self];
	[outlineView_summary setDoubleAction:@selector(didDoubleClick:)];
}

//A sort which groups actions together.
NSComparisonResult actionSort(id objectA, id objectB, void *context)
{
	return [(NSString *)[objectA objectForKey:KEY_ACTION_ID] compare:(NSString *)[objectB objectForKey:KEY_ACTION_ID]];
}

- (void)calculateHeightForItem:(id)item
{
	NSEnumerator	*enumerator;
	NSTableColumn	*tableColumn;
	BOOL			eventIsExtended = [self outlineView:outlineView_summary
								extendToEdgeColumn:EVENT_COLUMN_INDEX
											ofRow:[outlineView_summary rowForItem:item]];
	BOOL			enforceMinimumHeight = ([(NSArray *)item count] > 0);
	float			necessaryHeight = 0;
	NSRect			rectOfLastColumn = [outlineView_summary rectOfColumn:([outlineView_summary numberOfColumns] - 1)];
	NSRect			rectOfEventColumn = [outlineView_summary rectOfColumn:EVENT_COLUMN_INDEX];
	float			expandedEventWidth = NSMaxX(rectOfLastColumn) - NSMinX(rectOfEventColumn);

	//This pool seems to fix a crash. I don't know why.
	enumerator = [[outlineView_summary tableColumns] objectEnumerator];
	while ((tableColumn = [enumerator nextObject])) {
		NSString	*identifier = [tableColumn identifier];

		if ([identifier isEqualToString:@"event"] || ([identifier isEqualToString:@"action"] && !eventIsExtended)) {
			/* For the event column, and for the action column if the event is not extended, determine what height is needed */
			NSCell *dataCell = [tableColumn dataCell];

			[self outlineView:outlineView_summary willDisplayCell:dataCell forTableColumn:tableColumn item:item];

			NSString		*objectValue = [self outlineView:outlineView_summary
							 objectValueForTableColumn:tableColumn
												byItem:item];
			
			float			thisHeight, tableColumnWidth;
			NSFont			*font = [dataCell font];
			NSDictionary	*attributes = nil;
			
			if (font) {
				attributes = [NSDictionary dictionaryWithObjectsAndKeys:
							  font, NSFontAttributeName, nil];
			}
			
			NSAttributedString	*attributedTitle = [[NSAttributedString alloc] initWithString:objectValue
																				  attributes:attributes];
			
			if ([identifier isEqualToString:@"event"]) {
				if (eventIsExtended) {
					/* If this is the event column and it is extended, the available width will be from its origin
					 * to the right edge of the frame. Subtract a bit to provide a border */
					tableColumnWidth = expandedEventWidth - 8;
				} else {
					tableColumnWidth = NSWidth(rectOfEventColumn) - 8;
				}

			} else {
				/* Otherwise, it's the width as normal. */
				tableColumnWidth = [tableColumn width];
			}

			thisHeight = [attributedTitle heightWithWidth:tableColumnWidth];
			if (thisHeight > necessaryHeight) necessaryHeight = thisHeight;
#ifdef HEIGHT_DEBUG			
			AILogWithSignature(@"%@: width %f height %f", [attributedTitle string], tableColumnWidth, thisHeight);
#endif
			[attributedTitle release];
		}
	}
	
	necessaryHeight += VERTICAL_ROW_PADDING;
#ifdef HEIGHT_DEBUG
	AILogWithSignature(@"%@: %f", item, (enforceMinimumHeight ? 
										 ((necessaryHeight > MINIMUM_ROW_HEIGHT) ? necessaryHeight : MINIMUM_ROW_HEIGHT) :
										 necessaryHeight));
#endif
	[requiredHeightDict setObject:[NSNumber numberWithFloat:(enforceMinimumHeight ? 
															 ((necessaryHeight > MINIMUM_ROW_HEIGHT) ? necessaryHeight : MINIMUM_ROW_HEIGHT) :
															 necessaryHeight)]
						   forKey:[NSValue valueWithPointer:item]];	
}

- (void)calculateAllHeights
{
	[requiredHeightDict release]; requiredHeightDict = [[NSMutableDictionary alloc] init];

	id item;
	for (item in contactAlertsActions) {
		[self calculateHeightForItem:item];
	}
}

/*!
 * @brief Reload the information for our summary table, then update it
 */
- (void)reloadSummaryData
{
	//Get two parallel arrays for event IDs and the array of actions for that event ID
	NSDictionary	*contactAlertsDict;
	NSEnumerator	*enumerator;
	NSString		*eventID;
	NSString		*selectedEventID = nil;
	
	int		row = [outlineView_summary selectedRow];
	
	if (row != -1) {
		id item = [outlineView_summary itemAtRow:row];

		if ([contactAlertsActions containsObjectIdenticalTo:item]) {
			selectedEventID = [[contactAlertsEvents objectAtIndex:[contactAlertsActions indexOfObjectIdenticalTo:item]] retain];

		} else {
			selectedEventID = [[item objectForKey:KEY_EVENT_ID] retain];
		}
	}
		
	contactAlertsDict = [adium.preferenceController preferenceForKey:KEY_CONTACT_ALERTS
																 group:PREF_GROUP_CONTACT_ALERTS
											 objectIgnoringInheritance:listObject];
	[contactAlertsEvents release]; contactAlertsEvents = [[NSMutableArray alloc] init];
	[contactAlertsActions release]; contactAlertsActions = [[NSMutableArray alloc] init];
	
	enumerator = [[adium.contactAlertsController sortedArrayOfEventIDsFromArray:[contactAlertsDict allKeys]] objectEnumerator];
	
	while ((eventID = [enumerator nextObject])) {
		[contactAlertsEvents addObject:eventID];
		[contactAlertsActions addObject:[[contactAlertsDict objectForKey:eventID] sortedArrayUsingFunction:actionSort
																								   context:NULL]];
	}

	//Now add events which have no actions at present
	NSArray *sourceEventArray = (listObject ? [adium.contactAlertsController nonGlobalEventIDs] : [adium.contactAlertsController allEventIDs]);
	enumerator = [[adium.contactAlertsController sortedArrayOfEventIDsFromArray:sourceEventArray] objectEnumerator];
	while ((eventID = [enumerator nextObject])) {
		if (![contactAlertsEvents containsObject:eventID]) {
			[contactAlertsEvents addObject:eventID];
			
			//XXX
			//This is explicitly a mutable array because Foundation optimizes all zero-count NSArrays to be the same object, and we need it to be different
			[contactAlertsActions addObject:[NSMutableArray array]];
		}
	}

	[outlineView_summary reloadData];
	[self calculateAllHeights];
	[outlineView_summary noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [outlineView_summary numberOfRows])]];
	
	if (selectedEventID) {
		NSInteger actionsIndex = [contactAlertsEvents indexOfObject:selectedEventID];
		if (actionsIndex != NSNotFound) {			
			NSInteger rowToSelect = [outlineView_summary rowForItem:[contactAlertsActions objectAtIndex:actionsIndex]];
			
			[outlineView_summary selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect]
					  byExtendingSelection:NO];
		}
		
		[selectedEventID release];
	}
}

/*!
 * @brief A row in the outline view was double clicked
 *
 * If an event was double clicked, expand or collapse the disclosure triangle. If an action was double clicked, edit it.
 */
- (IBAction)didDoubleClick:(id)sender
{
	int		row = [outlineView_summary selectedRow];
	
	if (row != -1) {
		id item = [outlineView_summary itemAtRow:row];
		
		if ([contactAlertsActions containsObjectIdenticalTo:item]) {
			if ([item count] == 0) {
				[self addAlert:nil];
			} else if ([outlineView_summary isItemExpanded:item]) {
				[outlineView_summary collapseItem:item];
			} else {
				[outlineView_summary expandItem:item];
			}
		} else {
			[self editAlert:nil];
		}
	}
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil) item = contactAlertsActions;
	
	//Return an event array from whithin contactAlertsActions
	if (index < [item count]) {
		return [item objectAtIndex:index];
	} else {
		return nil;
	}
}

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) {
		return [contactAlertsActions count];
	} else {
		if ([item isKindOfClass:[NSArray class]] && [contactAlertsActions containsObjectIdenticalTo:item]) {
			return [item count];
		} else {
			return 0;
		}
	}
}

/*!
 * @brief Is an item expandable?
 *
 * Events are expandable.  Actions are not.
 */
- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(id)item
{
	if ([item isKindOfClass:[NSArray class]] && [contactAlertsActions containsObjectIdenticalTo:item]) {
		return [item count] > 0;
	} else {
		return NO;
	}
}

/*!
 * @brief An item's expanded state was set
 *
 * Cache this so we can use it in outlineView:expandStateOfItem:
 *
 * We cache by the associated Event ID so we can expand/contract the same perceived item, which is actually a different
 * NSArray instance, after a reload.
 */
- (void)outlineView:(NSOutlineView *)outlineView setExpandState:(BOOL)state ofItem:(id)item
{
	[expandStateDict setObject:[NSNumber numberWithBool:state]
						forKey:[contactAlertsEvents objectAtIndex:[contactAlertsActions indexOfObjectIdenticalTo:item]]];

	[self calculateHeightForItem:item];
	[outlineView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:[outlineView rowForItem:item]]];
}

/*!
 * @brief Should an item be expanded?
 *
 * Used when reloading to determine if items should be expanded or not.
 *
 * We cache by the associated Event ID so we can expand/contract the same perceived item, which is actually a different
 * NSArray instance, after a reload.
 */
- (BOOL)outlineView:(NSOutlineView *)inOutlineView expandStateOfItem:(id)item
{
	NSNumber	*expandState = [expandStateDict objectForKey:[contactAlertsEvents objectAtIndex:[contactAlertsActions indexOfObjectIdenticalTo:item]]];
	return expandState ? [expandState boolValue] : NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSString	*identifier = [tableColumn identifier];

	if ([contactAlertsActions containsObjectIdenticalTo:item]) {
		/* item is an array of contact events */
		NSArray	*contactEvents = (NSArray *)item;
		
		if ([identifier isEqualToString:@"event"]) {
			NSString	*eventID;
			
			eventID = [contactAlertsEvents objectAtIndex:[contactAlertsActions indexOfObjectIdenticalTo:contactEvents]];

			return [adium.contactAlertsController globalShortDescriptionForEventID:eventID];
			
		} else if ([identifier isEqualToString:@"action"]) {
			NSMutableString	*actionDescription = [NSMutableString string];
			NSDictionary	*eventDict;
			BOOL			appended = NO;
			unsigned		i, count;
			
			count = [contactEvents count];
			for (i = 0; i < count; i++) {
				NSString				*actionID;
				id <AIActionHandler>	actionHandler;
				
				eventDict = [contactEvents objectAtIndex:i];
				actionID = [eventDict objectForKey:KEY_ACTION_ID];
				actionHandler = [[adium.contactAlertsController actionHandlers] objectForKey:actionID];
				
				if (actionHandler) {
					NSString	*thisDescription;
					
					thisDescription = [actionHandler longDescriptionForActionID:actionID
																	withDetails:[eventDict objectForKey:KEY_ACTION_DETAILS]];
					if (thisDescription && [thisDescription length]) {
						if (appended) {
							/* We are on the second or later action. */
							NSString	*conjunctionIfNeeded;
							NSString	*commaAndSpaceIfNeeded;

							//If we have more than 2 actions, we'll be combining them with commas
							if ((count > 2) && (i != (count - 1))) {
								commaAndSpaceIfNeeded = AILocalizedString(@",", "comma between actions in the events list");
							} else {
								commaAndSpaceIfNeeded = @"";
							}
							
							//If we are on the last action, we'll want to add a conjunction to finish the compound sentence
							if (i == (count - 1)) {
								conjunctionIfNeeded = AILocalizedString(@" and", "conjunction to end a compound sentence");
							} else {
								conjunctionIfNeeded = @"";
							}
							
							/* Silly Localization hack: if Growl begins this phrase, don't make it lowercase, since it's
							 * a proper noun.
							 */
							if ([thisDescription rangeOfString:@"Growl" options:(NSLiteralSearch | NSAnchoredSearch)].location == 0) {
								[actionDescription appendString:[NSString stringWithFormat:@"%@%@ %@",
									commaAndSpaceIfNeeded,
									conjunctionIfNeeded,
									thisDescription]];
	
							} else {
								//Construct the string to append, then append it
								[actionDescription appendString:[NSString stringWithFormat:@"%@%@ %@%@",
									commaAndSpaceIfNeeded,
									conjunctionIfNeeded,
									[[thisDescription substringToIndex:1] lowercaseString],
									[thisDescription substringFromIndex:1]]];
							}
							
						} else {
							/* We are on the first action.
							 *
							 * This is easy; just append the description.
							 */
							[actionDescription appendString:thisDescription];
							appended = YES;
						}
						
						if (i == (count - 1)) {
							[actionDescription appendString:AILocalizedString(@".", "period at the end of the Events pane sentence describing actions taken for an event")];
						}
					}
				}
			}
			
			return actionDescription;
			
		} else if ([identifier isEqualToString:@"image"]) {
			NSString	*eventID;
			
			eventID = [contactAlertsEvents objectAtIndex:[contactAlertsActions indexOfObjectIdenticalTo:contactEvents]];
			
			return [adium.contactAlertsController imageForEventID:eventID];
		}
	} else {
		/* item is an individual event */
		if ([identifier isEqualToString:@"event"]) {
			NSDictionary			*alert = (NSDictionary *)item;
			NSString				*actionID = [alert objectForKey:KEY_ACTION_ID];
			id <AIActionHandler>	actionHandler = [[adium.contactAlertsController actionHandlers] objectForKey:actionID];

			return [actionHandler longDescriptionForActionID:actionID
												 withDetails:[alert objectForKey:KEY_ACTION_DETAILS]];
		} else if ([identifier isEqualToString:@"action"]) {
			return @"";

		} else if ([identifier isEqualToString:@"image"]) {
			return nil;
		}
	}

	return @"";
}

//Each row should be tall enough to fit its event and action descriptions as necessary
- (CGFloat)outlineView:(NSOutlineView *)inOutlineView heightOfRowByItem:(id)item
{	
	CGFloat	necessaryHeight;

	if ([contactAlertsActions containsObjectIdenticalTo:item]) {
		NSNumber *cachedHeight = [requiredHeightDict objectForKey:[NSValue valueWithPointer:item]];
		necessaryHeight = (cachedHeight ? [cachedHeight floatValue] : MINIMUM_ROW_HEIGHT);

	} else {
		//This item isn't an action; use the minimum row height
		necessaryHeight = MINIMUM_ROW_HEIGHT;
	}
	return necessaryHeight;
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView extendToEdgeColumn:(NSInteger)column ofRow:(NSInteger)row
{
	if (column == 1) {
		if ([outlineView_summary levelForRow:row] > 0) {
			//This is an action underneath an event; extend the column
			return YES;
		} else {
			id item = [outlineView_summary itemAtRow:row];
			return (([item count] == 0) ||  //This is an event with no actions
					([outlineView_summary isItemExpanded:item])); //Or it has actions and is expanded
		}
	} else {
		return NO;
	}
}

- (void)outlineView:(NSOutlineView *)inOutlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	//Only needed for the single-action event column
	if ([[tableColumn identifier] isEqualToString:@"event"]) {
		NSImage	*image = nil;
		NSFont	*font;
		
		if ([contactAlertsActions containsObjectIdenticalTo:item]) {
			/* item is an array of contact events */
			NSArray	*contactEvents = (NSArray *)item;

			if ([contactEvents count]) {
				font = [NSFont boldSystemFontOfSize:12];
			} else {
				font = [NSFont boldSystemFontOfSize:11];				
			}

		} else {
			NSDictionary			*alert = (NSDictionary *)item;
			NSString				*actionID = [alert objectForKey:KEY_ACTION_ID];
			id <AIActionHandler>	actionHandler = [[adium.contactAlertsController actionHandlers] objectForKey:actionID];
		
			image = [actionHandler imageForActionID:actionID];
			font = [NSFont systemFontOfSize:11];
		}
		
		[cell setImage:image];
		[cell setFont:font];
	}
}

/*!
 * @brief Outline view selection changed
 *
 * Update the enabled state of our buttons as appropriate.
 * Also, give action handlers a chance to preview.
 */
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSOutlineView	*outlineView = [notification object];
	if (!outlineView || (outlineView == outlineView_summary)) {
		//Enable/disable our configure button
		int row = [outlineView_summary selectedRow];
		
		if (row != -1) {
			[button_add	setEnabled:YES];
			
			id item = [outlineView_summary itemAtRow:row];
			if ([contactAlertsActions containsObjectIdenticalTo:item]) {
				[button_edit setEnabled:NO];
				[button_delete setEnabled:([(NSArray *)item count] > 0)];
				
			} else {
				[button_edit setEnabled:YES];
				[button_delete setEnabled:YES];
				
				//Preview if possible
				NSDictionary			*eventDict = (NSDictionary *)item;
				NSString				*actionID;
				id <AIActionHandler>	actionHandler;
				
				actionID = [eventDict objectForKey:KEY_ACTION_ID];
				
				actionHandler = [[adium.contactAlertsController actionHandlers] objectForKey:actionID];
				
				if (actionHandler && [actionHandler respondsToSelector:@selector(performPreviewForAlert:)]) {
					[(id)actionHandler performPreviewForAlert:eventDict];
				}				
			}
		} else {
			[button_add setEnabled:NO];
			[button_delete setEnabled:NO];
			[button_edit setEnabled:NO];
		
		}
	}
}

- (void)deleteContactActionsInArray:(NSArray *)contactEventArray
{
	NSDictionary	*eventDict;

	[adium.preferenceController delayPreferenceChangedNotifications:YES];
	for (eventDict in [[contactEventArray copy] autorelease]) {
		[adium.contactAlertsController removeAlert:eventDict fromListObject:listObject];
	}
	[adium.preferenceController delayPreferenceChangedNotifications:NO];

	if (delegate) {
		[delegate contactAlertsViewController:self
								 deletedAlert:nil];
	}

	//The deletion may have changed our selection
	[self outlineViewSelectionDidChange:nil];
}

- (void)outlineViewDeleteSelectedRows:(NSOutlineView *)inOutlineView
{
	[self deleteAlert:nil];
}

#pragma mark Global configuration
- (void)setConfigureForGlobal:(BOOL)inConfigureForGlobal
{
	configureForGlobal = inConfigureForGlobal;
}

- (void)setShowEventsInEditSheet:(BOOL)inShowEventsInEditSheet
{
	showEventsInEditSheet = inShowEventsInEditSheet;
}

@end
