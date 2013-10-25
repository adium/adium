//
//  AXCStartingPointsController.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-31.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCStartingPointsController.h"

#import "AXCDocumentController.h"
#import "NSMutableArrayAdditions.h"
#import "AXCPreferenceController.h"

@implementation AXCStartingPointsController

- (void) awakeFromNib
{
	NSString * startupAction = [[NSUserDefaults standardUserDefaults] objectForKey:STARTUP_ACTION_KEY];
	if ([startupAction isEqualToString:STARTING_POINTS_STARTUP_ACTION]) {
		if (!startingPointsWindow)
			[NSBundle loadNibNamed:@"StartingPoints" owner:self];
		else {
			[startingPointsTableView setDoubleAction:@selector(makeNewDocumentOfSelectedType:)];
			[startingPointsTableView setTarget:self];

			//question for the ages: would it be possible to extend the selection to an empty selection?
			[startingPointsTableView selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];

			//set the window's frame appropriately, then show it.
			if(![startingPointsWindow setFrameUsingName:[startingPointsWindow frameAutosaveName]])
				[startingPointsWindow center];
			[startingPointsWindow makeKeyAndOrderFront:nil];
		}
	}
}

- (void) dealloc
{
	[documentTypes release];
	[usableDocTypes release];
	[startingPointsWindow release];

	[super dealloc];
}

#pragma mark -

- (NSArray *) documentTypes
{
	if (!documentTypes) {
		NSDictionary *typeDicts = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
		unsigned numTypes = [typeDicts count];
		NSMutableArray *temp = [[NSMutableArray alloc] initWithCapacity:numTypes];
		usableDocTypes = [[NSMutableSet alloc] initWithCapacity:numTypes];

		NSEnumerator *typeDictsEnum = [typeDicts objectEnumerator];
		NSDictionary *typeDict;
		while ((typeDict = [typeDictsEnum nextObject])) {
			NSString *type = [[typeDict objectForKey:@"LSItemContentTypes"] objectAtIndex:0UL];
			unsigned newIdx = [temp indexForInsortingObject:type usingSelector:@selector(caseInsensitiveCompare:)];
			[temp insertObject:type atIndex:newIdx];

			if (NSClassFromString([typeDict objectForKey:@"NSDocumentClass"]))
				[usableDocTypes addObject:type];
		}

		[temp sortUsingSelector:@selector(caseInsensitiveCompare:)];

		documentTypes = [temp copy];
		[temp release];
	}

	return documentTypes;
}
- (unsigned) countOfDocumentTypeNames
{
	return [[self documentTypes] count];
}
- (NSString *) objectInDocumentTypeNamesAtIndex:(unsigned) idx {
	return [[AXCDocumentController sharedDocumentController] displayNameForType:[documentTypes objectAtIndex:idx]];
}

- (void) setStartingPointsVisible:(BOOL)flag
{
	if (flag)
		[startingPointsWindow makeKeyAndOrderFront:nil];
	else
		[startingPointsWindow orderOut:nil];
}
- (BOOL) isStartingPointsVisible
{
	return [startingPointsWindow isVisible];
}

#pragma mark -
#pragma mark Actions

- (IBAction) makeNewDocumentOfType:(NSString *) type
{
	[[AXCDocumentController sharedDocumentController] openUntitledDocumentOfType:type display:YES];
}
- (IBAction) makeNewDocumentOfSelectedType:(id)sender
{
	int selection = [sender selectedRow];
	if (selection >= 0)
		[self makeNewDocumentOfType:[documentTypes objectAtIndex:selection]];
}
- (IBAction) makeNewDocumentWithTypeFromMenuItem:(NSMenuItem *)sender
{
	[self makeNewDocumentOfType:[sender representedObject]];
}

- (IBAction) displayStartingPoints:(id)sender
{
	[self setStartingPointsVisible:YES];
}

#pragma mark -
#pragma mark NSTableView delegate conformance

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
	return ([[AXCDocumentController sharedDocumentController] documentClassForType:[[self documentTypes] objectAtIndex:row]] != Nil);
}

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)col row:(int)row
{
	//if this is a valid type (has a class we can instantiate), enable it. else, disable it.
	BOOL isValidType = [usableDocTypes containsObject:[documentTypes objectAtIndex:row]];
	NSColor *textColor = isValidType ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
	//B&R: assumes that the cell is an NSTextFieldCell
	[(NSTextFieldCell *)cell setTextColor:textColor];
}

#pragma mark -
#pragma mark NSMenu delegate conformance

- (int) numberOfItemsInMenu:(NSMenu *)menu
{
	return [[self documentTypes] count];
}
- (BOOL) menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)index shouldCancel:(BOOL)shouldCancel
{
	NSString *type = [[self documentTypes] objectAtIndex:index];
	[item setRepresentedObject:type];
	//Note: If this raises an exception, make sure that all the document types' names are listed in the relevant language's InfoPlist.strings.
	[item setTitle:[[AXCDocumentController sharedDocumentController] displayNameForType:type]];

	[item setAction:@selector(makeNewDocumentWithTypeFromMenuItem:)];
	[item setTarget:self];

	return !shouldCancel;
}

#pragma mark -
#pragma mark NSMenuItem validation

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	//the Starting Points command has a tag of 1. all the menu items in the New submenu have a tag of 0.
	if ([item tag])
		return ![self isStartingPointsVisible];
	else
		return ([[AXCDocumentController sharedDocumentController] documentClassForType:[item representedObject]] != Nil);
}

@end
