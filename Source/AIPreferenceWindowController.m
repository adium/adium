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

#import "AIPreferenceWindowController.h"
#import "AIPreferencePane.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIModularPaneCategoryView.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIViewAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIWindowControllerAdditions.h>
#import "AIPreferenceCollectionView.h"
#import "AIHighlightingTextField.h"

#define SUGGESTION_ENTRY_HEIGHT 17
#define PREFERENCES_LAST_PANE_KEY @"Preferences Last Pane"
#define PREFERENCES_MINIMUM_WIDTH 600

@interface AIPreferenceWindowController ()
- (void)showPreferencesWindow;
- (void)displayPane:(AIPreferencePane *)pane;
- (void)displayView:(NSView *)pane;
- (void)displayPaneWithIdentifier:(NSString *)identifier;
- (NSArray *)paneControllerSort;

- (void)getSuggestions;
- (void)cancelSuggestions;
- (void)layoutEntries:(NSArray *)entries;
@end

@implementation AIPreferenceWindowController

@synthesize generalController, appearanceController, eventsController, advancedController;
@synthesize window;
@synthesize allPanes;
@synthesize itemPrototypeView;
@synthesize searchField, button_showAll;
@synthesize label_general, label_advanced, label_events, label_appearance;
@synthesize generalPaneArray, appearancePaneArray, eventsPaneArray, advancedPaneArray;
@synthesize generalCV, appearanceCV, eventsCV, advancedCV;

#pragma mark - Singleton
+ (AIPreferenceWindowController *)sharedAIPreferenceWindowController
{
	static AIPreferenceWindowController *sharedAIPreferenceWindowController = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedAIPreferenceWindowController = [[self alloc] init];
	});
	
	return sharedAIPreferenceWindowController;
}

- (void)dealloc
{
	if (skIndex) {
		SKIndexClose (skIndex);
		skIndex = nil;
 	}
	
	[super dealloc];
}

/*!
 * @brief Open the preference window
 */
+ (void)openPreferenceWindow
{
	[[self sharedAIPreferenceWindowController] showPreferencesWindow];
}

/*!
 * @brief Open the preference window to a specific category
 */
+ (void)openPreferenceWindowToCategoryWithIdentifier:(NSString *)identifier
{	
	[self openPreferenceWindow];
	[[self sharedAIPreferenceWindowController] displayPaneWithIdentifier:identifier];
}

/*!
 * @brief Close the preference window
 */
- (void)closeWindow
{
	[generalController unbind:NSContentArrayBinding];
	[appearanceController unbind:NSContentArrayBinding];
	[eventsController unbind:NSContentArrayBinding];
	[advancedController unbind:NSContentArrayBinding];
	
	if ([window contentView] != allPanes)
		[allPanes release];
	
	[generalPaneArray release], generalPaneArray = nil;
	[appearancePaneArray release], appearancePaneArray = nil;
	[eventsPaneArray release], eventsPaneArray = nil;
	[advancedPaneArray release], advancedPaneArray = nil;
	
	[panes release], panes = nil;
	[paneMenu release], paneMenu = nil;
	[_trackingAreas release], _trackingAreas = nil;
	
	[AI_topLevelObjects release];
	window = nil;
}

/*!
 * @brief Close the preference window
 */
+ (void)closePreferenceWindow
{
	[[[self sharedAIPreferenceWindowController] window] close];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self closeWindow];
}

/*!
 * @brief Load a saved search index
 *
 * Check for an existing search index and compare the saved language with the current system language.
 * Create the index if the language differs or an existing index cannot be loaded.
 */
- (void)openSearchIndex
{
	if (skIndex)
		return;
	
	NSURL *indexURL = [NSURL fileURLWithPath:[[[adium cachesPath] stringByDeletingLastPathComponent]
											stringByAppendingPathComponent:@"preferences.searchIndex"]];
	NSURL *termsURL = [[NSBundle mainBundle] URLForResource:@"SearchTerms" withExtension:@"plist"];
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
	
	//Check the language of the user vs the search index and recreate it if it looks like the language has changed
	NSString *indexLocale = [adium.preferenceController preferenceForKey:@"search locale" group:PREF_GROUP_GENERAL];
	NSString *newLocale = [[NSLocale preferredLanguages] objectAtIndex:0];
	if (![indexLocale isEqualToString:newLocale]) {
		AILog(@"Recreating preferences search index for language: %@", newLocale);
		[fm removeItemAtURL:indexURL error:nil];
		[adium.preferenceController setPreference:newLocale forKey:@"search locale" group:PREF_GROUP_GENERAL];
	}
	
	//Check the date of the search index and recreate it if we have newer terms
	NSDictionary *properties = [fm attributesOfItemAtPath:indexURL.path error:nil];
	NSDate *indexDate = [properties objectForKey:NSFileModificationDate];
	properties = [fm attributesOfItemAtPath:termsURL.path error:nil];
	NSDate *termsDate = [properties objectForKey:NSFileModificationDate];
	if ([termsDate timeIntervalSinceDate:indexDate] > 0) {
		AILog(@"Recreating preferences search index for new terms.");
		[fm removeItemAtURL:indexURL error:nil];
	}
	
	if ([fm isReadableFileAtPath:indexURL.path]) {
		//Open the existing index
		skIndex = SKIndexOpenWithURL((CFURLRef)indexURL,
									 (CFStringRef)@"terms",
									 YES);
	}
	
	if (!skIndex || (SKIndexGetDocumentCount(skIndex) == 0)) {
		//Create a new index
		SKIndexType type = kSKIndexInverted;
		
		if (skIndex)
			SKIndexClose (skIndex);
		
		skIndex = SKIndexCreateWithURL((CFURLRef)indexURL,
									   (CFStringRef)@"terms",
									   (SKIndexType)type,
									   NULL);
		if (!skIndex) {
			AILog(@"Could not create preferences search index");
			return;
		}
		
		__block NSMutableSet *skipSet = [[[NSMutableSet alloc] init] autorelease];
		
		if (termsURL) {
			NSDictionary *terms = [NSDictionary dictionaryWithContentsOfURL:termsURL];
			//The file is laid out with each pane having an array of sections with each section having search terms
			[terms enumerateKeysAndObjectsUsingBlock:^(id paneKey, id paneSection, BOOL *stop) {
				__block NSString *pane = paneKey;
				
				//Add the section
				[(NSArray *)paneSection enumerateObjectsUsingBlock:^(id termDict, NSUInteger idx, BOOL *aStop) {
					NSString *title = [termDict objectForKey:@"title"];
					if ([title isEqualToString:@""])
						[skipSet addObject:pane];
					
					NSString *paneURL = [NSString stringWithFormat:@"%@/%@", pane, title];
					SKDocumentRef doc = SKDocumentCreate((CFStringRef)@"file",
														 NULL,
														 (CFStringRef)paneURL);
					[(id)doc autorelease];
					
					//Add the terms
					NSString *contents = [termDict objectForKey:@"index"];
					SKIndexAddDocumentWithText (skIndex,
												doc,
												(CFStringRef)contents,
												NO);
				}];
			}];
		}
		
		//Add each pane to the index
		id _skPaneNames = ^(id obj, NSUInteger idx, BOOL *stop) {
			NSString *paneName = [obj paneName];
			if ([skipSet containsObject:paneName])
				return;
			
			NSString *paneURL = [NSString stringWithFormat:@"%@/", paneName];
			SKDocumentRef doc = SKDocumentCreate((CFStringRef)@"file",
												 NULL,
												 (CFStringRef)paneURL);
			[(id) doc autorelease];
			
			SKIndexAddDocumentWithText (skIndex,
										doc,
										(CFStringRef)paneName,
										NO);
		};
		[generalPaneArray enumerateObjectsUsingBlock:_skPaneNames];
		[appearancePaneArray enumerateObjectsUsingBlock:_skPaneNames];
		[eventsPaneArray enumerateObjectsUsingBlock:_skPaneNames];
		[advancedPaneArray enumerateObjectsUsingBlock:_skPaneNames];
		
		SKIndexFlush(skIndex);
	}
}

- (void)showPreferencesWindow
{
	if (self.window) {
		[self.window makeKeyAndOrderFront:nil];
		return;
	}
	
	_trackingAreas = [[NSMutableArray alloc] init];
	paneMenu = [[NSMenu alloc] init];
	
	panes = [[NSMutableDictionary alloc] init];
	//Sort alphabetically by pane name
	NSArray *paneArray = [[adium.preferenceController paneArray] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [[obj1 paneName] compare:[obj2 paneName]];
	}];
	for (AIPreferencePane *pane in paneArray) {
		//Map each pane to its name and identifier
		[panes setObject:pane forKey:[pane paneIdentifier]];
		[panes setObject:pane forKey:[pane paneName]];
		
		//Setup a menu item for each pane to attach to 'Show All'
		NSMenuItem *paneItem = [[NSMenuItem alloc] initWithTitle:[pane paneName]
														  action:@selector(displayPaneFromMenu:)
												   keyEquivalent:@""];
		NSImage *paneImage = [[pane paneIcon] copy];
		[paneImage setSize:NSMakeSize(16, 16)];
		[paneItem setImage:paneImage];
		[paneMenu addItem:paneItem];
		[paneImage release];
		[paneItem release];
	}
	
	//Sort and separate preference panes into their categories
	generalPaneArray = [[adium.preferenceController paneArrayForCategory:AIPref_General]
								sortedArrayUsingDescriptors:[self paneControllerSort]];
	appearancePaneArray = [[adium.preferenceController paneArrayForCategory:AIPref_Appearance]
								sortedArrayUsingDescriptors:[self paneControllerSort]];
	eventsPaneArray = [[adium.preferenceController paneArrayForCategory:AIPref_Events]
								sortedArrayUsingDescriptors:[self paneControllerSort]];
	advancedPaneArray = [[adium.preferenceController paneArrayForCategory:AIPref_Advanced]
								sortedArrayUsingDescriptors:[self paneControllerSort]];
	
	[self openSearchIndex];
	
	//Load the nib
	if ([[NSBundle mainBundle] loadNibFile:@"Preferences"
						 externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:self, NSNibOwner, AI_topLevelObjects, NSNibTopLevelObjects, nil]
								  withZone:nil]) {
		// Release top level objects, release AI_topLevelObjects in -dealloc
		[AI_topLevelObjects makeObjectsPerformSelector:@selector(release)];
	}
}

- (void)awakeFromNib
{
	//Localize
	[label_general setStringValue:AILocalizedString(@"General", nil)];
	[label_appearance setStringValue:AILocalizedString(@"Appearance", nil)];
	[label_events setStringValue:AILocalizedString(@"Events", nil)];
	[label_advanced setStringValue:AILocalizedString(@"Advanced", nil)];
	[button_showAll setStringValue:AILocalizedString(@"Show All", nil)];
	
	[[generalCV enclosingScrollView] accessibilitySetOverrideValue:AILocalizedString(@"Preference panes", nil)
													  forAttribute:NSAccessibilityDescriptionAttribute];
	[[appearanceCV enclosingScrollView] accessibilitySetOverrideValue:AILocalizedString(@"Preference panes", nil)
														 forAttribute:NSAccessibilityDescriptionAttribute];
	[[eventsCV enclosingScrollView] accessibilitySetOverrideValue:AILocalizedString(@"Preference panes", nil)
													 forAttribute:NSAccessibilityDescriptionAttribute];
	[[advancedCV enclosingScrollView] accessibilitySetOverrideValue:AILocalizedString(@"Preference panes", nil)
													   forAttribute:NSAccessibilityDescriptionAttribute];
	
	//Resize the last collection view and window
	NSUInteger advCount = [advancedPaneArray count];
	NSUInteger advColumns = [advancedCV maxNumberOfColumns];
	if (advCount > advColumns) {
		NSRect newWindowHeight = self.window.frame;
		newWindowHeight.size.height += itemPrototypeView.frame.size.height * (int)(advCount / advColumns);
		[self.window setFrame:newWindowHeight display:YES];
	}
	
	[button_showAll setMenu:paneMenu forSegment:0];
	
	//Load the last viewed pane
	[self displayPaneWithIdentifier:[adium.preferenceController preferenceForKey:PREFERENCES_LAST_PANE_KEY group:PREF_GROUP_GENERAL]];
	
	//Show the window
	[self.window makeKeyAndOrderFront:nil];
}

- (IBAction)showAllPanes:(id)sender {
	[self displayPane:nil];
}

#pragma mark - Panes
- (void)displayPaneWithIdentifier:(NSString *)identifier
{
	AIPreferencePane *pane = [panes objectForKey:identifier];
	[self displayPane:pane];
}

- (void)displayPaneFromMenu:(id)sender
{
	[self displayPaneWithIdentifier:[sender title]];
}

- (void)displayPane:(AIPreferencePane *)pane
{
	if (!pane) {
		[self displayView:allPanes];
		[self.window setTitle:@"Preferences"];
	} else {
		[self displayView:[pane view]];
		[self.window setTitle:[pane paneName]];
	}
	
	//Save the last viewed pane
	[adium.preferenceController setPreference:[pane paneIdentifier] forKey:PREFERENCES_LAST_PANE_KEY group:PREF_GROUP_GENERAL];
}

/*!
 * @brief Resize the window to the size of the new view and display the view
 */
- (void)displayView:(NSView *)view
{
	[self cancelSuggestions];
	
	if (!view || view == [self.window contentView])
		return;
	
	if (view != allPanes)
		[allPanes retain];
	
	//Set an empty view to make resizing pretty
	NSView *tempView = [[NSView alloc] initWithFrame:[[self.window contentView] frame]];
	[self.window setContentView:tempView];
	[tempView release];
	
	NSRect viewFrame = view.frame;
	NSRect windowFrame = self.window.frame;
	NSRect contentFrame = [[self.window contentView] frame];
	
	windowFrame.size.height = viewFrame.size.height + (windowFrame.size.height - contentFrame.size.height);
	windowFrame.size.width = MAX(viewFrame.size.width, PREFERENCES_MINIMUM_WIDTH);
	
	windowFrame.origin.y += (contentFrame.size.height - viewFrame.size.height);
	[self.window setFrame:windowFrame display:YES animate:YES];
	[self.window setContentView:view];
	
	if (view == allPanes)
		[allPanes release];
}

/*!
 * @brief Highlight the hovered suggestion's entry and its pane.
 */
- (void)setSelectedView:(AIHighlightingTextField *)newView
{
	//Highlight suggestion entry
	[_selectedView setSelected:NO];
	_selectedView = newView;
	[_selectedView setSelected:YES];
	
	//Highlight the item in the collection view
	NSUInteger idx = [generalPaneArray indexOfObject:[_selectedView pane]];
	[generalCV setHighlightedIndex:idx];
	idx = [appearancePaneArray indexOfObject:[_selectedView pane]];
	[appearanceCV setHighlightedIndex:idx];
	idx = [eventsPaneArray indexOfObject:[_selectedView pane]];
	[eventsCV setHighlightedIndex:idx];
	idx = [advancedPaneArray indexOfObject:[_selectedView pane]];
	[advancedCV setHighlightedIndex:idx];
}

- (void)preferenceCollectionView:(AIPreferenceCollectionView *)aCollectionView didSelectItem:(NSCollectionViewItem *)anItem
{
	if ([[anItem representedObject] isKindOfClass:[AIPreferencePane class]])
		[self displayPane:[anItem representedObject]];
}

/*
 * Sort the panes alphabetically by name
 */
- (NSArray *)paneControllerSort
{
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"paneName" ascending:YES]];
}

#pragma mark - Suggestions Window
- (id)trackingAreaForView:(NSView *)view {
    //Make tracking data (to be stored in NSTrackingArea's userInfo) so we can later determine the view without hit testing
    NSDictionary *trackerData = [NSDictionary dictionaryWithObjectsAndKeys:view, @"view", nil];
    
    NSRect trackingRect = [[self.window contentView] convertRect:view.bounds fromView:view];
    NSTrackingAreaOptions trackingOptions = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp;
	NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:trackingRect options:trackingOptions owner:self userInfo:trackerData];
    
    return [trackingArea autorelease];
}

/*!
 * @brief Layout the suggestions entries
 * 
 * Create the suggestions window, if needed, create and layout the suggestions, and display the window
 */
- (void)layoutEntries:(NSArray *)entries
{
	[self setSelectedView:nil];
	
	//Remove existing mouse tracking areas
	[_trackingAreas enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[suggestionsWindow.contentView removeTrackingArea:obj];
	}];
	[_trackingAreas removeAllObjects];
	
	NSArray *suggestionsViews = [[[suggestionsWindow.contentView subviews] copy] autorelease];
	[suggestionsViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[suggestionsViews makeObjectsPerformSelector:@selector(release)];
	
	//Set size and location
	NSRect frame = searchField.frame;
	frame.size.width += 25.0;
	frame.size.height = [entries count] * SUGGESTION_ENTRY_HEIGHT;
	NSPoint loc = [searchField.superview convertPoint:frame.origin toView:nil];
	frame.origin = [window convertBaseToScreen:loc];
	frame.origin.y -= frame.size.height + 2.0;
	
	//Create the suggestions window
	if (!suggestionsWindow) {
		suggestionsWindow = [[NSWindow alloc] initWithContentRect:frame
														styleMask:NSBorderlessWindowMask
														  backing:NSBackingStoreBuffered
															defer:YES];
		
		[suggestionsWindow setHasShadow:YES];
		[suggestionsWindow setBackgroundColor:[[NSColor controlBackgroundColor] colorWithAlphaComponent:0.97f]];
		[suggestionsWindow setOpaque:NO];
	}
	
	//Create listeners to cancel the suggestions window if needed
	if (!_localMouseDownEventMonitor) {
		_localMouseDownEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseDownMask|NSRightMouseDownMask|NSOtherMouseDown
																		handler:^(NSEvent *event) {
			//If the mouse event is in the suggestions window then there is nothing to do.
			if ([event window] != suggestionsWindow) {
				if ([event window] == window) {
					NSView *contentView = [window contentView];
					NSPoint location = [contentView convertPoint:[event locationInWindow] fromView:nil];
					NSView *hitView = [contentView hitTest:location];
					NSText *fieldEditor = [searchField currentEditor];
					if (hitView != searchField && (fieldEditor && hitView != fieldEditor) ) {
						//Since the click is not in the parent text field, return nil so that the parent window does not try to process it and cancel the suggestions window.
						event = nil;
						[self cancelSuggestions];
					}
				} else {
					//Not in the suggestions window and not in the parent window.
					[self cancelSuggestions];
				}
			}
			
			return event;
		}];
	}
	if (!_localMouseUpEventHandler) {
		_localMouseUpEventHandler = [NSEvent addLocalMonitorForEventsMatchingMask:NSLeftMouseUp
																	  handler:^(NSEvent *event) {
			//Load the selected suggestion
			if ([event window] == suggestionsWindow) {
				[self displayPane:_selectedView.pane];
				event = nil;
			}
			
			return event;
		}];
	}
	if (!_lostFocusObserver) {
		_lostFocusObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification
																		   object:window
																			queue:nil
																	   usingBlock:^(NSNotification *arg1) {
			//Lost key status so cancel the suggestions window
			[self cancelSuggestions];
		}];
	}
	
	//Create the entries in the suggestions window
	CGFloat y = frame.size.height - SUGGESTION_ENTRY_HEIGHT;
	for (NSDictionary *dict in entries) {
		//This is not a leak, these are released at the start of this method
		AIHighlightingTextField *item = [[AIHighlightingTextField alloc] initWithFrame:NSMakeRect(0, y, frame.size.width, SUGGESTION_ENTRY_HEIGHT)];
		
		[item setString:[dict objectForKey:@"title"]
			   withPane:[dict objectForKey:@"pane"]];
		[suggestionsWindow.contentView addSubview:item];
		
		NSTrackingArea *tA = [self trackingAreaForView:item];
		[suggestionsWindow.contentView addTrackingArea:tA];
		
		[_trackingAreas addObject:tA];
		
		y -= SUGGESTION_ENTRY_HEIGHT;
	}
	
	[suggestionsWindow setFrame:frame display:NO];
	[window addChildWindow:suggestionsWindow ordered:NSWindowAbove];
	
	//Select the best match
	if ([entries count] == 1) {
		//If there's only one entry, select it
		[self setSelectedView:[[suggestionsWindow.contentView subviews] objectAtIndex:0]];
	} else if ([entries count] < 5) {
		//Only select one when there are fewer than five entries
		float score1 = [(NSNumber *)[[entries objectAtIndex:0] objectForKey:@"score"] floatValue];
		float score2 = [(NSNumber *)[[entries objectAtIndex:1] objectForKey:@"score"] floatValue];
		
		//Make sure the score between the top two is at least 5 points
		if ((score1 - score2) > 5)
			[self setSelectedView:[[suggestionsWindow.contentView subviews] objectAtIndex:0]];
	}
}

#pragma mark - Suggestions Mouse and Keyboard Tracking
- (void)mouseEntered:(NSEvent*)event {
	[self setSelectedView:[(NSDictionary*)[event userData] objectForKey:@"view"]];
}

- (void)mouseExited:(NSEvent*)event {
	[self setSelectedView:nil];
}

- (void)moveUp:(id)sender {
	AIHighlightingTextField *selectedView = _selectedView;
	AIHighlightingTextField *previousView = nil;
	for (AIHighlightingTextField *viewController in [suggestionsWindow.contentView subviews]) {
		if (viewController == selectedView) {
			break;
		}
		previousView = viewController;
	}
	
	if (previousView) {
		[self setSelectedView:previousView];
	}
}

- (void)moveDown:(id)sender {
	AIHighlightingTextField *selectedView = _selectedView;
	AIHighlightingTextField *previousView = nil;
	for (AIHighlightingTextField *viewController in [[suggestionsWindow.contentView subviews] reverseObjectEnumerator]) {
		if (viewController == selectedView) {
			break;
		}
		previousView = viewController;
	}
	
	if (previousView) {
		[self setSelectedView:previousView];
	}
}

/*!
 * @brief Query the search index for matches
 * 
 * Highlight each match in their associated collection view and send the results to be displayed in the suggesions window.
 */
- (void)getSuggestions
{
	NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
	NSMutableIndexSet *generalIndexes = [NSMutableIndexSet indexSet];
	NSMutableIndexSet *appearanceIndexes = [NSMutableIndexSet indexSet];
	NSMutableIndexSet *eventsIndexes = [NSMutableIndexSet indexSet];
	NSMutableIndexSet *advancedIndexes = [NSMutableIndexSet indexSet];
	
	//Open search index
	NSString *query = [NSString stringWithFormat:@"*%@*", [searchField stringValue]];
	SKSearchRef search = SKSearchCreate (skIndex,
										 (CFStringRef) query,
										 kSKSearchOptionDefault);
	int kSearchMax = 20;
	CFURLRef foundURLs[kSearchMax];
	SKDocumentID foundDocIDs[kSearchMax];
	float foundScores[kSearchMax];
	UInt32 totalCount = 0;
	BOOL more = YES;
	while (more) {
		CFIndex foundCount = 0;
		more = SKSearchFindMatches (search,
									kSearchMax,
									foundDocIDs,
									foundScores,
									1,
									&foundCount);
		//Display or accumulate results here
		SKIndexCopyDocumentURLsForDocumentIDs( skIndex, foundCount, foundDocIDs, foundURLs );
		
		totalCount += foundCount;
		for (int i = 0; i < foundCount; i++) {
			NSString *paneName = [[(NSURL *)foundURLs[i] pathComponents] objectAtIndex:1];
			AIPreferencePane *pane = [panes objectForKey:paneName];
			[results addObject:[NSDictionary dictionaryWithObjectsAndKeys:[(NSURL *)foundURLs[i] lastPathComponent], @"title", pane, @"pane", [NSNumber numberWithFloat:foundScores[i]], @"score", nil]];
			NSUInteger idx = [generalPaneArray indexOfObject:pane];
			if (idx != NSNotFound)
				[generalIndexes addIndex:idx];
			idx = [appearancePaneArray indexOfObject:pane];
			if (idx != NSNotFound)
				[appearanceIndexes addIndex:idx];
			idx = [eventsPaneArray indexOfObject:pane];
			if (idx != NSNotFound)
				[eventsIndexes addIndex:idx];
			idx = [advancedPaneArray indexOfObject:pane];
			if (idx != NSNotFound)
				[advancedIndexes addIndex:idx];
			CFRelease(foundURLs[i]);
		}
	}
	
	CFRelease(search);
	
	//Highlight matches in the collection views
	generalCV.matchedSearchIndexes = generalIndexes;
	appearanceCV.matchedSearchIndexes = appearanceIndexes;
	eventsCV.matchedSearchIndexes = eventsIndexes;
	advancedCV.matchedSearchIndexes = advancedIndexes;
	
	if (results.count > 0) {
		//Sort by score
		[results sortUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]]];
		[self layoutEntries:results];
	} else
		[self cancelSuggestions];
}

- (void)cancelSuggestions {
	if ([suggestionsWindow isVisible]) {
		//Remove the suggestion window from parent window's child window collection before ordering out or the parent window will get ordered out with the suggestion window.
		[[suggestionsWindow parentWindow] removeChildWindow:suggestionsWindow];
		[suggestionsWindow orderOut:nil];
	}
	
	NSArray *suggestionsViews = [[[suggestionsWindow.contentView subviews] copy] autorelease];
	[suggestionsViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[suggestionsViews makeObjectsPerformSelector:@selector(release)];
	
	//Dismantle any observers for auto cancel
	if (_lostFocusObserver) {
		[[NSNotificationCenter defaultCenter] removeObserver:_lostFocusObserver];
		_lostFocusObserver = nil;
	}
	if (_localMouseDownEventMonitor) {
		[NSEvent removeMonitor:_localMouseDownEventMonitor];
		_localMouseDownEventMonitor = nil;
	}
	if (_localMouseUpEventHandler) {
		[NSEvent removeMonitor:_localMouseUpEventHandler];
		_localMouseUpEventHandler = nil;
	}
	
	//Clear all matches
	generalCV.matchedSearchIndexes = nil;
	appearanceCV.matchedSearchIndexes = nil;
	eventsCV.matchedSearchIndexes = nil;
	advancedCV.matchedSearchIndexes = nil;
	
	_selectedView = nil;
}

#pragma mark - Search Field Delegate
- (void)controlTextDidChange:(NSNotification *)obj
{
	//Prevent calling "complete" too often
	if (!completePosting && !commandHandling)
	{
		completePosting = YES;
		[self getSuggestions];
		completePosting = NO;
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
	if (_selectedView)
		[self displayPane:_selectedView.pane];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
	if (commandSelector == @selector(moveUp:)) {
		[self moveUp:textView];
		return YES;
	} else if (commandSelector == @selector(moveDown:)) {
		[self moveDown:textView];
		return YES;
	} else if (commandSelector == @selector(deleteForward:) || commandSelector == @selector(deleteBackward:)) {
		//Close the suggestions window when there is no query
		if ([[textView string] isEqualToString:@""])
			[self cancelSuggestions];
	} else if (commandSelector == @selector(complete:)) {
		//By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
		if ([suggestionsWindow isVisible]) {
			[self cancelSuggestions];
		} else {
			[self getSuggestions];
		}
		return YES;
	} else if ([textView respondsToSelector:commandSelector]) {
		commandHandling = YES;
		[textView performSelector:commandSelector withObject:nil];
		commandHandling = NO;
		
		return YES;
	}
	
	return NO;
}

@end
