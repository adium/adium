//
//  AXCIconPackDocument.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCIconPackDocument.h"

#import "NSMutableArrayAdditions.h"
#import "NSMenu+ImmediatePopulation.h"
#import "AXCIconPackEntry.h"

//columns of the icon keys outline view.
#define KEY_COLUMN_NAME @"key"
#define RESOURCE_COLUMN_NAME @"file"

@implementation AXCIconPackDocument

- (id) init
{
	if ((self = [super init])) {
		categoryNames = [[self categoryNames] copy];

		NSMutableDictionary *temp = [[NSMutableDictionary alloc] initWithCapacity:[categoryNames count]];
		NSEnumerator *categoryNamesEnum = [categoryNames objectEnumerator];
		NSString *categoryName;
		while ((categoryName = [categoryNamesEnum nextObject]))
			[temp setObject:[[[self entriesForNewDocumentInCategory:categoryName] mutableCopy] autorelease] forKey:categoryName];

		categoryStorage = [temp copy];
		[temp release];
	}
	return self;
}

- (void) dealloc
{
	[categoryNames release];
	[categoryStorage release];

	[iconPlistView release];
	[tabViewItems release];

	[super dealloc];
}

#pragma mark Document nature

- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
	[super windowControllerDidLoadNib:controller];

	[[[[iconPlistView tableColumnWithIdentifier:RESOURCE_COLUMN_NAME] dataCell] menu] populateFromDelegate];
}

- (BOOL) writeToFile:(NSString *)path ofType:(NSString *)docType
{
	BOOL success = [super writeToFile:path ofType:docType];
	if (success) {
		NSMutableDictionary *iconsPlist = [NSMutableDictionary dictionaryWithCapacity:[categoryStorage count]];

		NSEnumerator *categoryNamesEnum = [categoryStorage keyEnumerator];
		NSString *categoryName;
		while ((categoryName = [categoryNamesEnum nextObject])) {
			NSArray *categoryArray = [categoryStorage objectForKey:categoryName];

			NSMutableDictionary *categoryPlist = [NSMutableDictionary dictionaryWithCapacity:[categoryArray count]];

			NSEnumerator *categoryEnum = [categoryArray objectEnumerator];
			AXCIconPackEntry *entry;
			while ((entry = [categoryEnum nextObject])) {
				NSString *resourcePath = [[entry path] lastPathComponent];
				if (resourcePath)
					[categoryPlist setObject:resourcePath forKey:[entry key]];
			}

			[iconsPlist setObject:categoryPlist forKey:categoryName];
		}

		NSString *iconsPlistPath = [[[path stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:@"Icons.plist"];
		success = [iconsPlist writeToFile:iconsPlistPath atomically:NO];
	}
	return success;
}

- (BOOL) readFromFile:(NSString *)path ofType:(NSString *)type
{
	BOOL success = [super readFromFile:path ofType:type];
	if (success) {
		[self removeResource:@"Icons.plist"];

		NSDictionary *iconsPlist = [NSDictionary dictionaryWithContentsOfFile:[bundle pathForResource:@"Icons" ofType:@"plist"]];
		categoryNames = [[iconsPlist allKeys] retain];

		NSMutableDictionary *storage = [[NSMutableDictionary alloc] initWithCapacity:[categoryNames count]];

		NSEnumerator *categoryNamesEnum = [categoryNames objectEnumerator];
		NSString *categoryName;
		while ((categoryName = [categoryNamesEnum nextObject])) {
			NSDictionary *category = [iconsPlist objectForKey:categoryName];

			NSMutableArray *entries = [[NSMutableArray alloc] initWithCapacity:[category count]];

			NSEnumerator *categoryKeysEnum = [category keyEnumerator];
			NSString *key;
			while ((key = [categoryKeysEnum nextObject])) {
				NSString *iconPath = [category objectForKey:key];
				if ([resourcesSet containsObject:iconPath]) {
					AXCIconPackEntry *entry = [[AXCIconPackEntry alloc] initWithKey:key path:iconPath];
					[entries addObject:entry];
					[entry release];
				} else {
					NSLog(@"Error while loading %@: Icons.plist contains a key (%@) in category %@ whose resource path (%@) does not exist in this bundle", path, key, categoryName, iconPath);
				}
			}

			[storage setObject:entries forKey:categoryName];
			[entries release];
		}

		[categoryStorage release];
		 categoryStorage = [storage retain];
	}
	return success;
}

#pragma mark Bindings

//use this, NOT -categoryNames, for bindings.
- (NSArray *) categoryNamesArray
{
	return categoryNames;
}

#pragma mark Outline view data source conformance

- (id) outlineView:(NSOutlineView *)outlineView child:(int)idx ofItem:(id)item
{
	if (!item) //return a category name
		return [categoryNames objectAtIndex:idx];
	else //return category storage
		return [[categoryStorage objectForKey:item] objectAtIndex:idx];
}
- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return ([categoryStorage objectForKey:item] != nil);
}
- (int) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item)
		return [categoryNames count];

	NSDictionary *storage = [categoryStorage objectForKey:item];
	if (storage)
		return [storage count];
	else
		return 0;
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)col byItem:(id)item
{
	BOOL isKeyColumn = [KEY_COLUMN_NAME isEqualToString:[col identifier]];
	unsigned categoryIndex = [categoryNames indexOfObjectIdenticalTo:item];

	if (categoryIndex != NSNotFound)
		return isKeyColumn ? item : [NSNumber numberWithInt:-1];
	else
		return isKeyColumn ? (NSObject *)[item key] : (NSObject *)[NSNumber numberWithUnsignedInt:[resources indexOfObject:[item path]]];
}
- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)newValue forTableColumn:(NSTableColumn *)col byItem:(id)item
{
	int index = [(NSNumber *)newValue intValue];
	if (index > -1)
		[(AXCIconPackEntry *)item setPath:[resources objectAtIndex:index]];
	else
		[(AXCIconPackEntry *)item setPath:nil];
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index
{
	NSArray *plist = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];

	if ([item isKindOfClass:[AXCIconPackEntry class]] //it's an icon pack entry
		&& ([plist count] == 1) //the user is only dragging one file
		&& (index == NSOutlineViewDropOnItemIndex) //we're dropping onto the entry
	) {
		return NSDragOperationLink;
	} else
		return NSDragOperationNone;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index
{
	[(AXCIconPackEntry *)item setPath:[[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	return YES;
}

#pragma mark NSOutlineView delegate conformance

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([cell isKindOfClass:[NSPopUpButtonCell class]]) {
		if ([categoryNames containsObject:item]) {
			[cell setMenu:emptyMenu];
			[cell setArrowPosition:NSPopUpNoArrow]; //hide arrow for categories
		} else {
			[cell setMenu:menuWithResourceFiles];
			[cell setArrowPosition:NSPopUpArrowAtBottom]; //show arrow for item pairs

			//we have to do this because of an NSMenu bug.
			//http://www.corbinstreehouse.com/blog/archives/2005/07/dynamically_pop.html
			NSMenu *menu = [cell menu];
			[menu setDelegate:self];
			[menu populateFromDelegate];

			//this is lame but necessary too.
			if (![item path])
				[cell selectItemAtIndex:-1];
			else //because we just changed the menu of the cell...
				[cell selectItemAtIndex:[resources indexOfObject:[item path]]];
		}
	}
}

/*keep the outline view from changing the width of the Key column (thereby
 *	 hiding the pop-up menu arrows and showing a scroll-bar) whenever the user expands or collapses a category.
 */
- (void) restoreKeyColumnMaxWidth
{
	[[iconPlistView tableColumnWithIdentifier:KEY_COLUMN_NAME] setMaxWidth:previousColumnMaxWidth];
}
- (void) outlineViewItemWillExpand:(NSNotification *)notification
{
	NSTableColumn *col = [iconPlistView tableColumnWithIdentifier:KEY_COLUMN_NAME];
	previousColumnMaxWidth = [col maxWidth];
	[col setMaxWidth:[col width]];
}
- (void) outlineViewItemDidExpand:(NSNotification *)notification
{
	[self performSelector:@selector(restoreKeyColumnMaxWidth) withObject:nil afterDelay:0.05];
}

#pragma mark NSMenu delegate conformance

- (int) numberOfItemsInMenu:(NSMenu *)menu
{
	return [resources count];
}
- (BOOL) menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	NSString *path = [resources objectAtIndex:index];

	[item setTitle:[displayNames  objectForKey:path]];

	NSImage *image = [[imagePreviews objectForKey:path] copy];
	[image setFlipped:NO];
	[item setImage:image];
	[image release];

	return !shouldCancel;
}

#pragma mark Implementation of Xtra-document methods

- (NSArray *) validResourceTypes
{
	return [NSImage imageFileTypes];
}

- (NSArray *) tabViewItems
{
	if (!tabViewItems) {
		if (!iconPlistView)
			[NSBundle loadNibNamed:@"IconPack_IconPlistView" owner:self];

		NSTabViewItem *tvi = [[NSTabViewItem alloc] initWithIdentifier:@"IconPlist"];
		[tvi setView:topLevelView];
		[tvi setLabel:@"Icon keys"]; //XXX LOCALIZEME

		tabViewItems = [[NSArray alloc] initWithObjects:&tvi count:1];
		[tvi release];
	}

	return tabViewItems;
}

#pragma mark Implementation of icon-pack abstract methods

- (NSArray *) categoryNames
{
	return [NSArray array];
}

- (NSArray *) entriesInCategory:(NSString *)categoryName
{
	return [categoryStorage objectForKey:categoryName];
}

- (NSArray *) entriesForNewDocumentInCategory:(NSString *)categoryName
{
	return [NSArray array];
}

@end
