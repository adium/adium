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

#import "AILogViewerWindowController.h"

#import "AIAccountController.h"
#import "AIChatLog.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIGradientView.h"
#import "AILogFromGroup.h"
#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AILogDateFormatter.h"
#import "AIXMLChatlogConverter.h"
#import "ESRankingCell.h" 

#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>

#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIUserIcons.h>

#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITableViewAdditions.h>

#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIDividedAlternatingRowOutlineView.h>


#define KEY_LOG_VIEWER_WINDOW_FRAME		@"Log Viewer Frame"
#define TOOLBAR_LOG_VIEWER				@"Log Viewer Toolbar"

#define MAX_LOGS_TO_SORT_WHILE_SEARCHING	10000	//Max number of logs we will live sort while searching
#define LOG_SEARCH_STATUS_INTERVAL			20		//1/60ths of a second to wait before refreshing search status
#define	REFRESH_RESULTS_INTERVAL			1.0		//Interval between results refreshes while searching

#define DATE_ITEM_IDENTIFIER			@"date"

#define SEARCH_MENU						AILocalizedString(@"Search Menu",nil)
#define FROM							AILocalizedString(@"From",nil)
#define TO								AILocalizedString(@"To",nil)
#define DATE							AILocalizedString(@"Date",nil)
#define CONTENT							AILocalizedString(@"Content",nil)
#define DELETE							AILocalizedString(@"Delete",nil)
#define SEARCH							AILocalizedString(@"Search",nil)
#define SEARCH_LOGS						AILocalizedString(@"Search Logs",nil)

#define HIDE_EMOTICONS					AILocalizedString(@"Hide Emoticons",nil)
#define SHOW_EMOTICONS					AILocalizedString(@"Show Emoticons",nil)
#define HIDE_TIMESTAMPS					AILocalizedString(@"Hide Timestamps",nil)
#define SHOW_TIMESTAMPS					AILocalizedString(@"Show Timestamps",nil)

#define IMAGE_EMOTICONS_OFF				@"emoticon32"
#define IMAGE_EMOTICONS_ON				@"emoticon32_transparent"
#define IMAGE_TIMESTAMPS_OFF			@"timestamp32"
#define IMAGE_TIMESTAMPS_ON				@"timestamp32_transparent"

#define	KEY_LOG_VIEWER_EMOTICONS			@"Log Viewer Emoticons"
#define	KEY_LOG_VIEWER_TIMESTAMPS			@"Log Viewer Timestamps"
#define KEY_LOG_VIEWER_SELECTED_COLUMN		@"Log Viewer Selected Column Identifier"

@interface AILogViewerWindowController ()
+ (NSOperationQueue *)sharedLogViewerQueue;
+ (AILogViewerWindowController *)sharedLogViewerForPlugin:(id)inPlugin;

- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin;
- (void)initLogFiltering;
- (void)displayLog:(AIChatLog *)log;
- (void)hilightOccurrencesOfString:(NSString *)littleString inString:(NSMutableAttributedString *)bigString firstOccurrence:(NSRange *)outRange;
- (void)hilightNextPrevious;
- (void)sortCurrentSearchResultsForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction;
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults;
- (void)buildSearchMenu;
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode;
- (void)_logFilter:(NSString *)searchString searchID:(NSInteger)searchID mode:(LogSearchMode)mode;
- (void)installToolbar;
- (void)updateRankColumnVisibility;
- (void)openLogAtPath:(NSString *)inPath;
- (void)rebuildContactsList;
- (void)filterForContact:(AIListContact *)inContact;
- (void)filterForChatName:(NSString *)chatName withAccount:(AIAccount *)account;
- (void)selectCachedIndex;
- (void)tableViewSelectionDidChangeDelayed;

- (NSAlert *)alertForDeletionOfLogCount:(NSUInteger)logCount;

- (void)_willOpenForContact;
- (void)_didOpenForContact;

- (void)deleteSelection:(id)sender;

- (void)_displayLogs:(NSArray *)logArray;
- (void)_displayLogText:(NSAttributedString *)logText;

- (void)outlineViewSelectionDidChangeDelayed;
- (void)openChatOnDoubleAction:(id)sender;
- (void)deleteLogsAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
NSInteger compareRectLocation(id obj1, id obj2, void *context);

- (void)setNavBarHidden:(NSNumber *)hide;
@end

@implementation AILogViewerWindowController

static NSInteger toArraySort(id itemA, id itemB, void *context);

+ (NSOperationQueue *)sharedLogViewerQueue
{
	static NSOperationQueue *logViewerQueue = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		logViewerQueue = [[NSOperationQueue alloc] init];
		[logViewerQueue setMaxConcurrentOperationCount:1];
		if([logViewerQueue respondsToSelector:@selector(setName:)])
			[logViewerQueue performSelector:@selector(setName:) withObject:@"im.adium.AILogViewerWindowController.logViewerQueue"];
	});
	
	return logViewerQueue;
}

+ (NSString *)nibName
{
	return @"LogViewer";
}

static AILogViewerWindowController *__sharedLogViewer = nil;
+ (AILogViewerWindowController *)sharedLogViewerForPlugin:(id)inPlugin
{
	if (inPlugin && !__sharedLogViewer) {
		__sharedLogViewer = [[self alloc] initWithWindowNibName:[self nibName] plugin:inPlugin];
	}
	return __sharedLogViewer;
}

+ (void)destroySharedLogViewer
{
	[__sharedLogViewer autorelease]; __sharedLogViewer = nil;
}

+ (id)openForPlugin:(id)inPlugin
{
	AILogViewerWindowController *sharedLogViewerInstance = [self sharedLogViewerForPlugin:inPlugin];

    [sharedLogViewerInstance showWindow:nil];
    
	return sharedLogViewerInstance;
}

+ (id)openLogAtPath:(NSString *)inPath plugin:(id)inPlugin
{	
	[self openForPlugin:inPlugin];
	
	AILogViewerWindowController *sharedLogViewerInstance = [self sharedLogViewerForPlugin:inPlugin];
	[sharedLogViewerInstance openLogAtPath:inPath];
	
	return sharedLogViewerInstance;
}

//Open the log viewer window to a specific contact's logs
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin
{
    AILogViewerWindowController *sharedLogViewerInstance = [self sharedLogViewerForPlugin:inPlugin];

	[sharedLogViewerInstance _willOpenForContact];
	[sharedLogViewerInstance showWindow:nil];
	[sharedLogViewerInstance filterForContact:inContact];
	[sharedLogViewerInstance _didOpenForContact];

    return sharedLogViewerInstance;
}

+ (id)openForChatName:(NSString *)inChatName withAccount:(AIAccount *)inAccount plugin:(id)inPlugin
{
	AILogViewerWindowController *sharedLogViewerInstance = [self sharedLogViewerForPlugin:inPlugin];
	
	[sharedLogViewerInstance _willOpenForContact];
	[sharedLogViewerInstance showWindow:nil];
	[sharedLogViewerInstance filterForChatName:inChatName withAccount:inAccount];
	[sharedLogViewerInstance _didOpenForContact];
	
    return sharedLogViewerInstance;
}

//Returns the window controller if one exists
+ (id)existingWindowController
{
    return [self sharedLogViewerForPlugin:nil];
}

//Close the log viewer window
+ (void)closeSharedInstance
{
	AILogViewerWindowController *sharedLogViewerInstance = [self existingWindowController];
    if (sharedLogViewerInstance) {
        [sharedLogViewerInstance closeWindow:nil];
    }
}

//init
- (id)initWithWindowNibName:(NSString *)windowNibName plugin:(id)inPlugin
{
	if((self = [super initWithWindowNibName:windowNibName])) {
		plugin = inPlugin;
		selectedColumn = nil;
		activeSearchID = 0;
		searching = NO;
		automaticSearch = YES;
		showEmoticons = NO;
		showTimestamps = YES;
		activeSearchString = nil;
		displayedLogArray = nil;
		windowIsClosing = NO;

		blankImage = [[NSImage alloc] initWithSize:NSMakeSize(16,16)];

		sortDirection = YES;
		searchMode = LOG_SEARCH_CONTENT;

		currentSearchResults = [[NSMutableArray alloc] init];
		logFromGroupDict = [[NSMutableDictionary alloc] init];
		toArray = [[NSMutableArray alloc] init];
		logToGroupDict = [[NSMutableDictionary alloc] init];
		resultsLock = [[NSRecursiveLock alloc] init];
		contactIDsToFilter = [[NSMutableSet alloc] initWithCapacity:1];

		allContactsIdentifier = [[NSNumber numberWithInteger:-1] retain];

		undoManager = [[NSUndoManager alloc] init];
		currentSearchLock = [[NSLock alloc] init];
		[currentSearchLock setName:@"CurrentLogSearchLock"];
	}
	
	return self;
}

//dealloc
- (void)dealloc
{
	[filterDate release]; filterDate = nil;
	[currentSearchLock release]; currentSearchLock = nil;
	[resultsLock release];
	[toArray release];
	[currentSearchResults release];
	[selectedColumn release];
	[displayedLogArray release];
	[blankImage release];
	[activeSearchString release];
	[contactIDsToFilter release];

	[logFromGroupDict release]; logFromGroupDict = nil;
	[logToGroupDict release]; logToGroupDict = nil;

	[horizontalRule release]; horizontalRule = nil;

	[adiumIcon release]; adiumIcon = nil;
	[adiumIconHighlighted release]; adiumIconHighlighted = nil;

	//We loaded	view_DatePicker from a nib manually, so we must release it
	[view_DatePicker release]; view_DatePicker = nil;

	[allContactsIdentifier release];
	[undoManager release]; undoManager = nil;

	[super dealloc];
}

//Init our log filtering tree
- (void)initLogFiltering
{
    NSMutableDictionary		*toDict = [NSMutableDictionary dictionary];
    NSString				*basePath = [AILoggerPlugin logBasePath];
    NSString				*fromUID, *serviceClass;

    //Process each account folder (/Logs/SERVICE.ACCOUNT_NAME/) - sorting by compare: will result in an ordered list
	//first by service, then by account name.
    for (NSString *folderName in [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:NULL] sortedArrayUsingSelector:@selector(compare:)]) {
		if (![folderName isEqualToString:@".DS_Store"]) { // avoid the directory info
			AILogFromGroup  *logFromGroup;
			NSMutableSet	*toSetForThisService;
			NSArray         *serviceAndFromUIDArray;
			
			/* Determine the service and fromUID - should be SERVICE.ACCOUNT_NAME
			 * Check against count to guard in case of old, malformed or otherwise odd folders & whatnot sitting in log base
			 */
			serviceAndFromUIDArray = [folderName componentsSeparatedByString:@"."];

			if ([serviceAndFromUIDArray count] >= 2) {
				serviceClass = [serviceAndFromUIDArray objectAtIndex:0];

				//Use substringFromIndex so we include the rest of the string in the case of a UID with a . in it
				fromUID = [folderName substringFromIndex:([serviceClass length] + 1)]; //One off for the '.'
			} else {
				//Fallback: blank non-nil serviceClass; folderName as the fromUID
				serviceClass = @"";
				fromUID = folderName;
			}

			logFromGroup = [[AILogFromGroup alloc] initWithPath:folderName fromUID:fromUID serviceClass:serviceClass];

			//Store logFromGroup on a key in the form "SERVICE.ACCOUNT_NAME"
			[logFromGroupDict setObject:logFromGroup forKey:folderName];

			//To processing
			if (!(toSetForThisService = [toDict objectForKey:serviceClass])) {
				toSetForThisService = [NSMutableSet set];
				[toDict setObject:toSetForThisService
						   forKey:serviceClass];
			}

			//Add the 'to' for each grouping on this account
			for (AILogToGroup *currentToGroup in [logFromGroup toGroupArray]) {
				NSString	*currentTo;

				if ((currentTo = [currentToGroup to])) {
					//Store currentToGroup on a key in the form "SERVICE.ACCOUNT_NAME/TARGET_CONTACT"
					[logToGroupDict setObject:currentToGroup forKey:[currentToGroup relativePath]];
				}
			}

			[logFromGroup release];
		}
	}

	[self rebuildContactsList];
}

- (void)rebuildContactsList
{
	NSInteger	oldCount = toArray.count;
	[toArray release]; toArray = [[NSMutableArray alloc] initWithCapacity:(oldCount ? oldCount : 20)];

	for (AILogFromGroup *logFromGroup in [logFromGroupDict objectEnumerator]) {
		//Add the 'to' for each grouping on this account
		for (AILogToGroup *currentToGroup in [logFromGroup toGroupArray]) {
			NSString	*currentTo;
			
			if ((currentTo = [currentToGroup to])) {
				NSString *serviceClass = [currentToGroup serviceClass];
				AIListObject *listObject = ((serviceClass && currentTo) ?
											[adium.contactController existingListObjectWithUniqueID:[AIListObject internalObjectIDForServiceID:serviceClass
																																			 UID:currentTo]] :
											nil);
				if (listObject && [listObject isKindOfClass:[AIListContact class]]) {
					AIListContact *parentContact = [(AIListContact *)listObject parentContact];
					if (![toArray containsObjectIdenticalTo:parentContact]) {
						[toArray addObject:parentContact];
					}
					
				} else {
					if (![toArray containsObject:currentToGroup]) {
						[toArray addObject:currentToGroup];
					}
				}
			}
		}		
	}
	
	[toArray sortUsingFunction:toArraySort context:NULL];
	[outlineView_contacts reloadData];

	if (!isOpeningForContact) {
		//If we're opening for a contact, the outline view selection will be changed in a moment anyways
		[self outlineViewSelectionDidChange:nil];
	}
}

- (NSString *)adiumFrameAutosaveName
{
	return KEY_LOG_VIEWER_WINDOW_FRAME;
}

//Setup the window before it is displayed
- (void)windowDidLoad
{
	suppressSearchRequests = YES;

	[super windowDidLoad];

	[plugin cancelIndexing];

	[[self window] setTitle:AILocalizedString(@"Chat Transcript Viewer",nil)];
    [textField_progress setStringValue:@""];
	[textField_resultCount setStringValue:@""];

	[tableView_results accessibilitySetOverrideValue:AILocalizedString(@"Transcripts", nil)
										forAttribute:NSAccessibilityTitleAttribute];
	[outlineView_contacts accessibilitySetOverrideValue:AILocalizedString(@"Contacts", nil)
										forAttribute:NSAccessibilityTitleAttribute];

	//Set emoticon filtering
	showEmoticons = [[adium.preferenceController preferenceForKey:KEY_LOG_VIEWER_EMOTICONS
															  group:PREF_GROUP_LOGGING] boolValue];
	[[toolbarItems objectForKey:@"toggleemoticons"] setLabel:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)];
	[[toolbarItems objectForKey:@"toggleemoticons"] setImage:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]];

	// Set timestamp filtering
	showTimestamps = [[adium.preferenceController preferenceForKey:KEY_LOG_VIEWER_TIMESTAMPS
															   group:PREF_GROUP_LOGGING] boolValue];
	[[toolbarItems objectForKey:@"toggletimestamps"] setLabel:(showTimestamps ? HIDE_TIMESTAMPS : SHOW_TIMESTAMPS)];
	[[toolbarItems objectForKey:@"toggletimestamps"] setImage:[NSImage imageNamed:(showTimestamps ? IMAGE_TIMESTAMPS_ON : IMAGE_TIMESTAMPS_OFF) forClass:[self class]]];

	//Toolbar
	[self installToolbar];
	
	//Setting this autosave in the nib doesn't work properly
	[splitView_contacts setAutosaveName:@"LogViewer:Contacts"];

	[outlineView_contacts setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];

	AIImageTextCell	*dataCell = [[AIImageTextCell alloc] init];
	NSTableColumn	*tableColumn = [[outlineView_contacts tableColumns] objectAtIndex:0];
	[tableColumn setDataCell:dataCell];
	[tableColumn setEditable:NO];
	[dataCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[dataCell release];

	// Set the selector for doubleAction
	[outlineView_contacts setDoubleAction:@selector(openChatOnDoubleAction:)];
	
	//Localize tableView_results column headers
	[[[tableView_results tableColumnWithIdentifier:@"To"] headerCell] setStringValue:TO];
	[[[tableView_results tableColumnWithIdentifier:@"From"] headerCell] setStringValue:FROM];
	[[[tableView_results tableColumnWithIdentifier:@"Date"] headerCell] setStringValue:DATE];
	[self tableViewColumnDidResize:nil];

	[tableView_results sizeLastColumnToFit];

	//Prepare the search controls
	[self buildSearchMenu];
	if ([textView_content respondsToSelector:@selector(setUsesFindPanel:)]) {
		[textView_content setUsesFindPanel:YES];
	}
	
	//hide find navigation bar
	[self performSelectorOnMainThread:@selector(setNavBarHidden:)
						   withObject:[NSNumber numberWithBool:YES]
						waitUntilDone:YES];

	//Set a gradient for the background
	[view_FindNavigator setStartingColor:[NSColor colorWithCalibratedWhite:0.92f alpha:1.0f]];
	[view_FindNavigator setEndingColor:[NSColor colorWithCalibratedWhite:0.79f alpha:1.0f]];
	[view_FindNavigator setAngle:270];

    //Sort by preference, defaulting to sorting by date
	NSString	*selectedTableColumnPref;
	if ((selectedTableColumnPref = [adium.preferenceController preferenceForKey:KEY_LOG_VIEWER_SELECTED_COLUMN
																		   group:PREF_GROUP_LOGGING])) {
		selectedColumn = [[tableView_results tableColumnWithIdentifier:selectedTableColumnPref] retain];
	}
	if (!selectedColumn) {
		selectedColumn = [[tableView_results tableColumnWithIdentifier:@"Date"] retain];
	}
	[self sortCurrentSearchResultsForTableColumn:selectedColumn direction:YES];

    //Prepare indexing and filter searching
	[plugin prepareLogContentSearching];
    [self initLogFiltering];

    //Begin our initial search
	if (!isOpeningForContact)
		[self setSearchMode:LOG_SEARCH_TO];

    [searchField_logs setStringValue:(activeSearchString ? activeSearchString : @"")];
	[[searchField_logs cell] setPlaceholderString:SEARCH_LOGS];
	suppressSearchRequests = NO;

	if (!isOpeningForContact) {
		//If we're opening for a contact, we'll select it and then begin searching
		[self startSearchingClearingCurrentResults:YES];
	}
}

- (void)rebuildIndices
{
    //Rebuild the 'global' log indexes
    [logFromGroupDict release]; logFromGroupDict = [[NSMutableDictionary alloc] init];
    [toArray removeAllObjects]; //note: even if there are no logs, the name will remain [bug or feature?]
    
    [self initLogFiltering];
    
    [tableView_results reloadData];
    [self selectDisplayedLog];
}

//Called as the window closes
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	//Set preference for emoticon filtering
	[adium.preferenceController setPreference:[NSNumber numberWithBool:showEmoticons]
										 forKey:KEY_LOG_VIEWER_EMOTICONS
										  group:PREF_GROUP_LOGGING];
											
	// Set preference for timestamp filtering
	[adium.preferenceController setPreference:[NSNumber numberWithBool:showTimestamps]
																			 forKey:KEY_LOG_VIEWER_TIMESTAMPS
																				group:PREF_GROUP_LOGGING];
	
	//Set preference for selected column
	[adium.preferenceController setPreference:[selectedColumn identifier]
										 forKey:KEY_LOG_VIEWER_SELECTED_COLUMN
										  group:PREF_GROUP_LOGGING];

    /* Disable the search field.  If we don't disable the search field, it will often try to call its target action
     * after the window has closed (and we are gone).  I'm not sure why this happens, but disabling the field
     * before we close the window down seems to prevent the crash.
	 */
    [searchField_logs setEnabled:NO];
	
	/* Note that the window is closing so we don't take behaviors which could cause messages to the window after
	 * it was gone, like responding to a logIndexUpdated message
	 */
	windowIsClosing = YES;

    //Abort any in-progress searching and indexing, and wait for their completion
    [self stopSearching];
    [plugin cleanUpLogContentSearching];

	//Reset our column widths if needed
	[activeSearchString release]; activeSearchString = nil;
	[self updateRankColumnVisibility];
	
	[[self class] destroySharedLogViewer];
	[toolbarItems autorelease]; toolbarItems = nil;
}

//Display --------------------------------------------------------------------------------------------------------------
#pragma mark Display
//Update log viewer progress string to reflect current status
- (void)updateProgressDisplay
{
    NSMutableString     *progress = nil;
    BOOL				indexing = plugin.isIndexing;

    //We always convey the number of logs being displayed
    [resultsLock lock];
	NSUInteger count = [currentSearchResults count];
    if (activeSearchString && [activeSearchString length]) {
		[textField_resultCount setStringValue:[NSString stringWithFormat:((count != 1) ? 
																			   AILocalizedString(@"%lu matching transcripts",nil) :
																			   AILocalizedString(@"1 matching transcript",nil)),count]];
    } else {
		[textField_resultCount setStringValue:[NSString stringWithFormat:((count != 1) ? 
																			   AILocalizedString(@"%lu transcripts",nil) :
																			   AILocalizedString(@"1 transcript",nil)),count]];
		
		//We are searching, but there is no active search  string. This indicates we're still opening logs.
		if (searching) {
			progress = [[AILocalizedString(@"Opening transcripts",nil) mutableCopy] autorelease];
		}
    }
    [resultsLock unlock];

    //Append search progress
    if (activeSearchString && [activeSearchString length]) {
		if (progress) {
			[progress appendString:@" - "];
		} else {
			progress = [NSMutableString string];
		}

		if (searching || indexing) {
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@"Searching for '%@'",nil),activeSearchString]];
		} else {
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@"Search for '%@' complete.",nil),activeSearchString]];
		}
	}

    //Append indexing progress
    if (indexing) {
		if (progress) {
			[progress appendString:@" - "];
		} else {
			progress = [NSMutableString string];
		}
		
		if (plugin.indexIsFlushing) {
			[progress appendString:AILocalizedString(@"Saving search index",nil)];
		} else {
			[progress appendString:[NSString stringWithFormat:AILocalizedString(@"Indexing %qi of %qi transcripts",nil), plugin.logsIndexed, plugin.logsToIndex]];
		}
    }
	
	if (progress && (searching || indexing || !(activeSearchString && [activeSearchString length]))) {
		[progress appendString:[NSString ellipsis]];
	}

    //Enable/disable the searching animation
    if (searching || indexing) {
		[progressIndicator startAnimation:nil];
    } else {
		[progressIndicator stopAnimation:nil];
    }
    
    [textField_progress setStringValue:(progress ? progress : @"")];
}

//The plugin is informing us that the log indexing changed
- (void)logIndexingProgressUpdate
{
	//Don't do anything if the window is already closing
	if (!windowIsClosing) {
		[self updateProgressDisplay];
		
		//If we are searching by content, we should re-search without clearing our current results so the
		//the newly-indexed logs can be added without blanking the current table contents.
		if (searchMode == LOG_SEARCH_CONTENT && (activeSearchString && [activeSearchString length])) {
			if (searching) {
				//We're already searching; reattempt when done
				searchIDToReattemptWhenComplete = activeSearchID;
			} else {
				//We're not searching - restart the search immediately every 10 updates to utilize the newly indexed logs
				indexingUpdatesReceivedWhileSearching++;
				if ((indexingUpdatesReceivedWhileSearching % 10) == 0)
					[self startSearchingClearingCurrentResults:NO];
			}
		}
	}
}

//Refresh the results table
- (void)refreshResults
{
	[self updateProgressDisplay];

	[self refreshResultsSearchIsComplete:NO];
}

- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete
{
    [resultsLock lock];
    NSInteger count = [currentSearchResults count];
    [resultsLock unlock];
	AILog(@"refreshResultsSearchIsComplete: %i (count is %i)",searchIsComplete,count);
	
	if (searchIsComplete &&
		((activeSearchID == searchIDToReattemptWhenComplete) && !windowIsClosing)) {
		searchIDToReattemptWhenComplete = -1;
		[self startSearchingClearingCurrentResults:NO];
	}
	
    if (!searching || count <= MAX_LOGS_TO_SORT_WHILE_SEARCHING) {
		//Sort the logs correctly which will also reload the table
		[self resortLogs];
		
		if (searchIsComplete && automaticSearch) {
			//If search is complete, select the first log if requested and possible
			[self selectFirstLog];
			
		} else {
			BOOL oldAutomaticSearch = automaticSearch;
			
			//We don't want the above re-selection to change our automaticSearch tracking
			//(The only reason automaticSearch should change is in response to user action)
			automaticSearch = oldAutomaticSearch;
		}
    }
	
	if(deleteOccurred)
		[self selectCachedIndex];

    //Update status
    [self updateProgressDisplay];
}

- (void)searchComplete
{
	[refreshResultsTimer invalidate]; [refreshResultsTimer release]; refreshResultsTimer = nil;
	[self refreshResultsSearchIsComplete:YES];
}

// Called on doubleAction to open a chat
-(void)openChatOnDoubleAction:(id)sender
{
	id item = [outlineView_contacts firstSelectedItem];
	if ([item isKindOfClass:[AIListContact class]]) {
		//Open a new message with the contact
		[adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:(AIListContact *)item onPreferredAccount:YES]];
	}
}

//Detaches a thread which displays the log after rendering it off the main thread
- (void)displayLogs:(NSArray *)logArray
{
	[displayOperation cancel];
	[displayOperation autorelease];
	displayOperation = nil;
	currentMatch = -1;
	[self _displayLogText:[NSAttributedString stringWithString:@"Loading..."]];
	
	if (logArray) {
		displayOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_displayLogs:) object:logArray];
		[[[self class] sharedLogViewerQueue] addOperation:displayOperation];
	}
}

//Displays the contents of the specified log in our window
- (void)_displayLogs:(NSArray *)logArray
{
	NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];
	NSInvocationOperation *thisOperation = displayOperation;
	NSMutableAttributedString	*displayText = nil;
	NSAttributedString			*finalDisplayText = nil;
	BOOL						appendedFirstLog = NO;

    if (![logArray isEqualToArray:displayedLogArray]) {
		[displayedLogArray release];
		displayedLogArray = [logArray copy];
	}

	if ([logArray count] > 1) {
		displayText = [[NSMutableAttributedString alloc] init];
	}

	AIChatLog	 *theLog;
	NSString	 *logBasePath = [AILoggerPlugin logBasePath];
	AILog(@"Displaying %@",logArray);
	for (theLog in logArray) {
		if ([thisOperation isCancelled])
			break;
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (displayText) {
			if (!horizontalRule) {
				#define HORIZONTAL_BAR			0x2013
				#define HORIZONTAL_RULE_LENGTH	18
				
				const unichar separatorUTF16[HORIZONTAL_RULE_LENGTH] = {
					HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR,
					HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR,
					HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR, HORIZONTAL_BAR
				};
				horizontalRule = [[NSString alloc] initWithCharacters:separatorUTF16 length:HORIZONTAL_RULE_LENGTH];
			}	
			
			[NSDateFormatter withLocalizedDateFormatterPerform:^(NSDateFormatter *headerDateFormatter){
				[displayText appendString:[NSString stringWithFormat:@"%@%@\n%@ - %@\n%@\n\n",
										   (appendedFirstLog ? @"\n" : @""),
										   horizontalRule,
										   [headerDateFormatter stringFromDate:[theLog date]],
										   [theLog to],
										   horizontalRule]
						   withAttributes:[[AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:NSBoldFontMask size:12] dictionary]];
			}];
		}
		
		if ([[theLog relativePath] hasSuffix:@".AdiumHTMLLog"] || [[theLog relativePath] hasSuffix:@".html"] || [[theLog relativePath] hasSuffix:@".html.bak"]) {
			//HTML log
			NSURL *logURL = [NSURL fileURLWithPath:[logBasePath stringByAppendingPathComponent:[theLog relativePath]]];
			NSString *logFileText = [NSString stringWithContentsOfURL:logURL encoding:NSUTF8StringEncoding error:NULL];
			NSAttributedString *attributedLogFileText = [AIHTMLDecoder decodeHTML:logFileText];

			if (showEmoticons) {
				attributedLogFileText = [adium.contentController filterAttributedString:attributedLogFileText
																		  usingFilterType:AIFilterMessageDisplay
																				direction:AIFilterOutgoing
																				  context:nil];
			}			

			if (displayText) {
				[displayText appendAttributedString:attributedLogFileText];
			} else {
				displayText = [attributedLogFileText mutableCopy];
			}

		} else if ([[theLog relativePath] hasSuffix:@".chatlog"]){
			//XML log
			NSString *logFullPath = [logBasePath stringByAppendingPathComponent:[theLog relativePath]];
			
			BOOL isDir;
			if ([[NSFileManager defaultManager] fileExistsAtPath:logFullPath isDirectory:&isDir]) {
				/* If we have a chatLog bundle, we want to get the text content for the xml file inside */
				if (isDir) logFullPath = [logFullPath stringByAppendingPathComponent:
										 [[[logFullPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"]];
			}

			NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithBool:showTimestamps], @"showTimestamps",
									 [NSNumber numberWithBool:showEmoticons], @"showEmoticons", 
									 nil];
			NSAttributedString *attributedLogFileText = [AIXMLChatlogConverter readFile:logFullPath withOptions:options];
			if (attributedLogFileText) {
				if (displayText)
					[displayText appendAttributedString:attributedLogFileText];
				else
					displayText = [attributedLogFileText mutableCopy];
			}

		} else {
			//Fallback: Plain text log
			NSURL *logURL = [NSURL fileURLWithPath:[logBasePath stringByAppendingPathComponent:[theLog relativePath]]];
			NSString *logFileText = [NSString stringWithContentsOfURL:logURL encoding:NSUTF8StringEncoding error:NULL];
			if (logFileText) {
				AITextAttributes *textAttributes = [AITextAttributes textAttributesWithFontFamily:@"Helvetica" traits:0 size:12];
				NSAttributedString *attributedLogFileText = [[[NSAttributedString alloc] initWithString:logFileText 
																							 attributes:[textAttributes dictionary]] autorelease];
				if (showEmoticons) {
					attributedLogFileText = [adium.contentController filterAttributedString:attributedLogFileText
																			  usingFilterType:AIFilterMessageDisplay
																					direction:AIFilterOutgoing
																					  context:nil];
				}
				
				if (displayText) {
					[displayText appendAttributedString:attributedLogFileText];
				} else {
					displayText = [attributedLogFileText mutableCopy];
				}
			}
		}
		
		appendedFirstLog = YES;
		
		[pool release];
	}
	
	currentMatch = -1;
	[matches release];
	matches = [[NSMutableArray alloc] init];
	
	if (displayText && [displayText length] && ![thisOperation isCancelled]) {
		//Add pretty formatting to links
		[displayText addFormattingForLinks];

		//If we are searching by content, highlight the search results
		if ((searchMode == LOG_SEARCH_CONTENT) && [activeSearchString length]) {
			NSString					*searchWord;
			NSMutableArray				*searchWordsArray = [[activeSearchString componentsSeparatedByString:@" "] mutableCopy];
			NSScanner					*scanner = [NSScanner scannerWithString:activeSearchString];
			
			//Look for an initial quote
			NSAutoreleasePool *pool = nil;
			while (![scanner isAtEnd]) {
				[pool release];
				pool = [[NSAutoreleasePool alloc] init];
				
				[scanner scanUpToString:@"\"" intoString:NULL];
				
				//Scan past the quote
				if (![scanner scanString:@"\"" intoString:NULL]) {
					[pool release]; pool = nil;
					continue;
				}
				
				NSString *quotedString;
				//And a closing one
				if (![scanner isAtEnd] &&
					[scanner scanUpToString:@"\"" intoString:&quotedString]) {
					//Scan past the quote
					[scanner scanString:@"\"" intoString:NULL];
					/* If a string within quotes is found, remove the words from the quoted string and add the full string
					 * to what we'll be highlighting.
					 *
					 * We'll use indexOfObject: and removeObjectAtIndex: so we only remove _one_ instance. Otherwise, this string:
					 * "killer attack ninja kittens" OR ninja
					 * wouldn't highlight the word ninja by itself.
					 */
					NSArray *quotedWords = [quotedString componentsSeparatedByString:@" "];
					NSInteger quotedWordsCount = [quotedWords count];
					
					for (NSInteger i = 0; i < quotedWordsCount; i++) {
						NSString	*quotedWord = [quotedWords objectAtIndex:i];
						if (i == 0) {
							//Originally started with a quote, so put it back on
							quotedWord = [@"\"" stringByAppendingString:quotedWord];
						}
						if (i == quotedWordsCount - 1) {
							//Originally ended with a quote, so put it back on
							quotedWord = [quotedWord stringByAppendingString:@"\""];
						}
						NSInteger searchWordsIndex = [searchWordsArray indexOfObject:quotedWord];
						if (searchWordsIndex != NSNotFound) {
							[searchWordsArray removeObjectAtIndex:searchWordsIndex];
						} else {
							NSLog(@"displayLog: Couldn't find %@ in %@", quotedWord, searchWordsArray);
						}
					}
					
					//Add the full quoted string
					[searchWordsArray addObject:quotedString];
				}
			}

			for (searchWord in searchWordsArray) {
				NSRange     occurrence;
				
				//Check against and/or.  We don't just remove it from the array because then we couldn't check case insensitively.
				if (([searchWord caseInsensitiveCompare:@"and"] != NSOrderedSame) &&
					([searchWord caseInsensitiveCompare:@"or"] != NSOrderedSame)) {
					[self hilightOccurrencesOfString:searchWord inString:displayText firstOccurrence:&occurrence];
					
					//We'll want to scroll to the first occurrence of any matching word or words
					if (occurrence.location != NSNotFound)
						currentMatch = 1;
				}
			}

			[searchWordsArray release];
		}
		finalDisplayText = displayText;
	}

	// only step into this if the current operation is still running.
	if(![thisOperation isCancelled]) {
		//sort locations of matches
		[matches sortUsingFunction:compareRectLocation context:nil];

		[self performSelectorOnMainThread:@selector(_displayLogText:)
							   withObject:finalDisplayText
							waitUntilDone:YES];

		if (currentMatch > 0) {
			[self performSelectorOnMainThread:@selector(setNavBarHidden:)
								   withObject:[NSNumber numberWithBool:NO]
								waitUntilDone:YES];
		} else {
			[self performSelectorOnMainThread:@selector(setNavBarHidden:)
								   withObject:[NSNumber numberWithBool:YES]
								waitUntilDone:YES];
		}
	}

	[displayText release];
	[threadPool drain];
}

NSInteger compareRectLocation(id obj1, id obj2, void *context)
{
	NSRange r1 = [(NSValue *)obj1 rangeValue];
	NSRange r2 = [(NSValue *)obj2 rangeValue];

	if (NSEqualRanges(r1, r2))
		return NSOrderedSame;
	if (r1.location < r2.location)
		return NSOrderedAscending;

	return NSOrderedDescending;
}

- (void)_displayLogText:(NSAttributedString *)logText
{
	if (logText) {
		[[textView_content textStorage] setAttributedString:logText];
		
		[self hilightNextPrevious];
	} else {
		//No log selected, empty the view
		[textView_content setString:@""];
	}
}

- (void)displayLog:(AIChatLog *)theLog
{
	[self displayLogs:(theLog ? [NSArray arrayWithObject:theLog] : nil)];
}

//Reselect the displayed log (Or another log if not possible)
- (void)selectDisplayedLog
{
    NSInteger     firstIndex = NSNotFound;
    
    /* Is the log we had selected still in the table?
	 * (When performing an automatic search, we ignore the previous selection.  This ensures that we always
     * end up with the newest log selected, even when a search takes multiple passes/refreshes to complete).
	 */
	if (!automaticSearch) {
		[resultsLock lock];
		[tableView_results selectItemsInArray:displayedLogArray usingSourceArray:currentSearchResults];
		[resultsLock unlock];
		
		firstIndex = [[tableView_results selectedRowIndexes] firstIndex];
	}

	if (firstIndex != NSNotFound) {
		[tableView_results scrollRowToVisible:[[tableView_results selectedRowIndexes] firstIndex]];
    } else {
		[self selectFirstLog];
    }
}

- (void)selectFirstLog
{
	AIChatLog   *theLog = nil;
	
	//If our selected log is no more, select the first one in the list
	[resultsLock lock];
	if ([currentSearchResults count] != 0) {
		theLog = [currentSearchResults objectAtIndex:0];
	}
	[resultsLock unlock];
	
	//Change the table selection to this new log
	//We need a little trickery here.  When we change the row, the table view will call our tableViewSelectionDidChange: method.
	//This method will clear the automaticSearch flag, and break any scroll-to-bottom behavior we have going on for the custom
	//search.  As a quick hack, I've added an ignoreSelectionChange flag that can be set to inform our selectionDidChange method
	//that we instantiated this selection change, and not the user.
	ignoreSelectionChange = YES;
	[tableView_results selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[tableView_results scrollRowToVisible:0];
	ignoreSelectionChange = NO;

	[self displayLog:theLog];  //Manually update the displayed log
}

//Highlight the occurences of a search string within a displayed log
- (void)hilightOccurrencesOfString:(NSString *)littleString inString:(NSMutableAttributedString *)bigString firstOccurrence:(NSRange *)outRange
{
    NSInteger			location = 0;
    NSRange				searchRange, foundRange;
    NSString			*plainBigString = [bigString string];
	NSUInteger			plainBigStringLength = [plainBigString length];
	NSMutableDictionary *attributeDictionary = nil;

    outRange->location = NSNotFound;

    //Search for the little string in the big string
    while (location != NSNotFound && location < plainBigStringLength) {
        searchRange = NSMakeRange(location, plainBigStringLength-location);
        foundRange = [plainBigString rangeOfString:littleString options:NSCaseInsensitiveSearch range:searchRange];
		
		//Bold and color this match
        if (foundRange.location != NSNotFound) {
			if (outRange->location == NSNotFound) *outRange = foundRange;

			if (!attributeDictionary) {
				attributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSFont boldSystemFontOfSize:14], NSFontAttributeName,
					[NSColor yellowColor], NSBackgroundColorAttributeName,
					nil];
			}
			[bigString addAttributes:attributeDictionary
							   range:foundRange];
			[matches addObject:[NSValue valueWithRange:foundRange]];
        }

        location = NSMaxRange(foundRange);
    }
}

/* Show or hide the bar that contains the next/previous buttons for navigating search results
 * This needs to be run on the main thread hence it's not a BOOL
 */
- (void)setNavBarHidden:(NSNumber *)hide
{
	NSAssert([NSThread isMainThread], @"This needs to be called on the main thread.");
	NSSize contentSize = [textView_content enclosingScrollView].frame.size;

	//show
	if (![hide boolValue] && [view_FindNavigator isHidden])
		contentSize.height -= view_FindNavigator.frame.size.height;
	//hide
	else if ([hide boolValue] && ![view_FindNavigator isHidden])
		contentSize.height += view_FindNavigator.frame.size.height;

	[[textView_content enclosingScrollView] setFrameSize:contentSize];
	[view_FindNavigator setHidden:[hide boolValue]];
}

- (IBAction)selectNextPreviousOccurrence:(id)sender;
{
	NSInteger selectedSegment = [sender selectedSegment];
	switch (selectedSegment) {
		case 0: //previous
			currentMatch--;
			break;
		case 1: //next
			currentMatch++;
			break;
	}
	[self hilightNextPrevious];
}

- (void)hilightNextPrevious
{
	if (currentMatch < 0 || [matches count] == 0) {
		[textView_content scrollRangeToVisible:NSMakeRange(0,0)];
		return;
	}

	//loop around matches in the displayed log
	if (currentMatch > [matches count])
		currentMatch = 1;
	else if (currentMatch == 0)
		currentMatch = [matches count];

	NSRange scrollTo = [[matches objectAtIndex:currentMatch-1] rangeValue];

	[textView_content scrollRangeToVisible:scrollTo];
	[textView_content setSelectedRange:scrollTo];

	[textField_findCount setStringValue:[NSString stringWithFormat:@"%d/%d", currentMatch, [matches count]]];
}

//Sorting --------------------------------------------------------------------------------------------------------------
#pragma mark Sorting
- (void)resortLogs
{
	NSString *identifier = [selectedColumn identifier];

    //Resort the data
	[resultsLock lock];
    if ([identifier isEqualToString:@"To"]) {
		[currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareToReverse:) : @selector(compareTo:))];
		
    } else if ([identifier isEqualToString:@"From"]) {
        [currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareFromReverse:) : @selector(compareFrom:))];
		
    } else if ([identifier isEqualToString:@"Date"]) {
        [currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareDateReverse:) : @selector(compareDate:))];
		
    } else if ([identifier isEqualToString:@"Rank"]) {
	    [currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareRankReverse:) : @selector(compareRank:))];

	} else if ([identifier isEqualToString:@"Service"]) {
	    [currentSearchResults sortUsingSelector:(sortDirection ? @selector(compareServiceReverse:) : @selector(compareService:))];
	}
	
    [resultsLock unlock];

    //Reload the data
    [tableView_results reloadData];

    //Reapply the selection
    [self selectDisplayedLog];
}

//Sorts the selected log array and adjusts the selected column
- (void)sortCurrentSearchResultsForTableColumn:(NSTableColumn *)tableColumn direction:(BOOL)direction
{
    //If there already was a sorted column, remove the indicator image from it.
    if (selectedColumn && selectedColumn != tableColumn) {
        [tableView_results setIndicatorImage:nil inTableColumn:selectedColumn];
    }
    
    //Set the indicator image in the newly selected column
    [tableView_results setIndicatorImage:[NSImage imageNamed:(direction ? @"NSDescendingSortIndicator" : @"NSAscendingSortIndicator")]
                           inTableColumn:tableColumn];
    
    //Set the highlighted table column.
    [tableView_results setHighlightedTableColumn:tableColumn];
    [selectedColumn release]; selectedColumn = [tableColumn retain];
    sortDirection = direction;
	
	[self resortLogs];
}

//Searching ------------------------------------------------------------------------------------------------------------
#pragma mark Searching
//(Jag)Change search string
- (void)controlTextDidChange:(NSNotification *)notification
{
    if (searchMode != LOG_SEARCH_CONTENT) {
		[self updateSearch:nil];
    }
}

//Change search string (Called by searchfield)
- (IBAction)updateSearch:(id)sender
{
    automaticSearch = NO;
    [self setSearchString:[[[searchField_logs stringValue] copy] autorelease]];
	AILog(@"updateSearch calling startSearching");
    [self startSearchingClearingCurrentResults:YES];
}

//Change search mode (Called by mode menu)
- (IBAction)selectSearchType:(id)sender
{
    automaticSearch = NO;

	//First, update the search mode to the newly selected type
    [self setSearchMode:(LogSearchMode)[sender tag]];
	
	//Then, ensure we are ready to search using the current string
	[self setSearchString:activeSearchString];

	//Now we are ready to start searching
	AILog(@"selectSearchType calling startSearching");
    [self startSearchingClearingCurrentResults:YES];
}

//Begin a specific search
- (void)setSearchString:(NSString *)inString mode:(LogSearchMode)inMode
{
    automaticSearch = YES;
	//Apply the search mode first since the behavior of setSearchString changes depending on the current mode
    [self setSearchMode:inMode];
    [self setSearchString:inString];

	AILog(@"setSearchString:mode: calling startSearching");
    [self startSearchingClearingCurrentResults:YES];
}

//Begin the current search
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults
{
    NSDictionary    *searchDict;

	if (suppressSearchRequests) return;
	AILog(@"Starting a search for %@",activeSearchString);

    //Once all searches have exited, we can start a new one
	if (clearCurrentResults) {
		[resultsLock lock];
		//Stop any existing searches inside of resultsLock so we won't get any additions results added that we don't want
		[self stopSearching];

		[currentSearchResults release]; currentSearchResults = [[NSMutableArray alloc] init];
		[resultsLock unlock];
	} else {
	    //Stop any existing searches
		[self stopSearching];
	}

	searching = YES;
	indexingUpdatesReceivedWhileSearching = 0;
    searchDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:activeSearchID], @"ID",
		[NSNumber numberWithInteger:searchMode], @"Mode",
		activeSearchString, @"String",
		nil];
    [NSThread detachNewThreadSelector:@selector(filterLogsWithSearch:) toTarget:self withObject:searchDict];
    
	//Update the table periodically while the logs load.
	[refreshResultsTimer invalidate]; [refreshResultsTimer release];
	refreshResultsTimer = [[NSTimer scheduledTimerWithTimeInterval:REFRESH_RESULTS_INTERVAL
															target:self
														  selector:@selector(refreshResults)
														  userInfo:nil
														   repeats:YES] retain];
}

//Abort any active searches
- (void)stopSearching
{
	[currentSearchLock lock];
	if (currentSearch) {
		SKSearchCancel(currentSearch);
		CFRelease(currentSearch); currentSearch = nil;
	}
	[currentSearchLock unlock];
	
	[refreshResultsTimer invalidate]; [refreshResultsTimer release]; refreshResultsTimer = nil;

	//Increase the active search ID so any existing searches stop, and then
	//wait for any active searches to finish and release the lock
	activeSearchID++;
}

//Set the active search mode (Does not invoke a search)
- (void)setSearchMode:(LogSearchMode)inMode
{
	NSTextFieldCell	*cell = [searchField_logs cell];
	
    searchMode = inMode;
	
	//Clear any filter from the table if it's the current mode, as well
	switch (searchMode) {
		case LOG_SEARCH_FROM:
			[cell setPlaceholderString:AILocalizedString(@"Search From","Placeholder for searching logs from an account")];
			break;

		case LOG_SEARCH_TO:
			[cell setPlaceholderString:AILocalizedString(@"Search To","Placeholder for searching logs with/to a contact")];
			break;
			
		case LOG_SEARCH_DATE:
			[cell setPlaceholderString:AILocalizedString(@"Search by Date","Placeholder for searching logs by date")];
			break;

		case LOG_SEARCH_CONTENT:
			[cell setPlaceholderString:AILocalizedString(@"Search Content","Placeholder for searching logs by content")];
			break;
	}

	[self updateRankColumnVisibility];
    [self buildSearchMenu];
}

- (void)updateRankColumnVisibility
{
	NSTableColumn	*resultsColumn = [tableView_results tableColumnWithIdentifier:@"Rank"];
	
	if ((searchMode == LOG_SEARCH_CONTENT) && ([activeSearchString length])) {
		//Add the resultsColumn and resize if it should be shown but is not at present
		if (!resultsColumn) {	
			NSArray			*tableColumns;

			//Set up the results column
			resultsColumn = [[[NSTableColumn alloc] initWithIdentifier:@"Rank"] autorelease];
			[[resultsColumn headerCell] setTitle:AILocalizedString(@"Rank",nil)];
			[resultsColumn setDataCell:[[[ESRankingCell alloc] init] autorelease]];
			
			//Add it to the table
			[tableView_results addTableColumn:resultsColumn];

			//Make it half again as large as the desired width from the @"Rank" header title
			[resultsColumn sizeToFit];
			[resultsColumn setWidth:([resultsColumn width] * 1.5f)];
			
			tableColumns = [tableView_results tableColumns];
			if ([tableColumns indexOfObject:resultsColumn] > 0) {
				NSTableColumn	*nextDoorNeighbor;

				//Adjust the column to the results column's left so results is now visible
				nextDoorNeighbor = [tableColumns objectAtIndex:([tableColumns indexOfObject:resultsColumn] - 1)];
				[nextDoorNeighbor setWidth:[nextDoorNeighbor width]-[resultsColumn width]];
			}
		}
	} else {
		//Remove the resultsColumn and resize if it should not be shown but is at present
		if (resultsColumn) {
			NSArray			*tableColumns;

			tableColumns = [tableView_results tableColumns];
			if ([tableColumns indexOfObject:resultsColumn] > 0) {
				NSTableColumn	*nextDoorNeighbor;

				//Adjust the column to the results column's left to take up the space again
				tableColumns = [tableView_results tableColumns];
				nextDoorNeighbor = [tableColumns objectAtIndex:([tableColumns indexOfObject:resultsColumn] - 1)];
				[nextDoorNeighbor setWidth:[nextDoorNeighbor width]+[resultsColumn width]];
			}

			//Remove it
			[tableView_results removeTableColumn:resultsColumn];
		}
	}
}

//Set the active search string (Does not invoke a search)
- (void)setSearchString:(NSString *)inString
{
    if (![[searchField_logs stringValue] isEqualToString:inString]) {
		[searchField_logs setStringValue:(inString ? inString : @"")];
    }
	
	//Use autorelease so activeSearchString can be passed back to here
	if (activeSearchString != inString) {
		[activeSearchString release];
		activeSearchString = [inString retain];
	}

	[self updateRankColumnVisibility];
}

//Build the search mode menu
- (void)buildSearchMenu
{
    NSMenu  *cellMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:SEARCH_MENU] autorelease];
    [cellMenu addItem:[self _menuItemWithTitle:FROM forSearchMode:LOG_SEARCH_FROM]];
    [cellMenu addItem:[self _menuItemWithTitle:TO forSearchMode:LOG_SEARCH_TO]];
    [cellMenu addItem:[self _menuItemWithTitle:DATE forSearchMode:LOG_SEARCH_DATE]];
    [cellMenu addItem:[self _menuItemWithTitle:CONTENT forSearchMode:LOG_SEARCH_CONTENT]];

	[[searchField_logs cell] setSearchMenuTemplate:cellMenu];
}

- (void)_willOpenForContact
{
	isOpeningForContact = YES;
}

- (void)_didOpenForContact
{
	isOpeningForContact = NO;
}

/*!
 * @brief Focus the log viewer on a particular contact
 *
 * If the contact is within a metacontact, the metacontact will be focused.
 */
- (void)filterForContact:(AIListContact *)inContact
{
	AIListContact *parentContact = [inContact parentContact];

	if (!isOpeningForContact) {
		/* Ensure the contacts list includes this contact, since only existing AIListContacts are to be used
		* (with AILogToGroup objects used if an AIListContact isn't available) but that situation may have changed
		* with regard to inContact since the log viewer opened.
		*
		* If we're opening initially, the list is guaranteed fresh.
		*/
		[self rebuildContactsList];
	}

	//If the search mode is currently the TO field, switch it to content, which is what it should now intuitively do
	if (searchMode == LOG_SEARCH_TO) {
		[self setSearchMode:LOG_SEARCH_CONTENT];
		
		//Update our search string to ensure we're configured for content searching
		[self setSearchString:activeSearchString];
	}

	//Changing the selection will start a new search
	[outlineView_contacts selectItemsInArray:[NSArray arrayWithObject:(parentContact ? (id)parentContact : (id)allContactsIdentifier)]];
	NSUInteger selectedRow = [[outlineView_contacts selectedRowIndexes] firstIndex];
	if (selectedRow != NSNotFound) {
		[outlineView_contacts scrollRowToVisible:selectedRow];
	}
}

- (void)filterForChatName:(NSString *)chatName withAccount:(AIAccount *)account
{
	if (!isOpeningForContact) {
		// See above.
		[self rebuildContactsList];
	}
	
	AILogToGroup *logToGroup = [logToGroupDict objectForKey:[[NSString stringWithFormat:@"%@.%@",
															  account.service.serviceID,
															  account.UID.safeFilenameString]
															 stringByAppendingPathComponent:chatName]];

	//Changing the selection will start a new search
	[outlineView_contacts selectItemsInArray:[NSArray arrayWithObject:(logToGroup ?: (id)allContactsIdentifier)]];
	NSUInteger selectedRow = [[outlineView_contacts selectedRowIndexes] firstIndex];
	if (selectedRow != NSNotFound) {
		[outlineView_contacts scrollRowToVisible:selectedRow];
	}
}

/*!
 * @brief Returns a menu item for the search mode menu
 */
- (NSMenuItem *)_menuItemWithTitle:(NSString *)title forSearchMode:(LogSearchMode)mode
{
    NSMenuItem  *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title 
																				 action:@selector(selectSearchType:) 
																		  keyEquivalent:@""];
    [menuItem setTag:mode];
    [menuItem setState:(mode == searchMode ? NSOnState : NSOffState)];
    
    return [menuItem autorelease];
}

#pragma mark Filtering search results

- (BOOL)chatLogMatchesDateFilter:(AIChatLog *)inChatLog
{
	BOOL matchesDateFilter;

	switch (filterDateType) {
		case AIDateTypeAfter:
			matchesDateFilter = ([[inChatLog date] timeIntervalSinceDate:filterDate] > 0);
			break;
		case AIDateTypeBefore:
			matchesDateFilter = ([[inChatLog date] timeIntervalSinceDate:filterDate] < 0);
			break;
		case AIDateTypeExactly:
			matchesDateFilter = [inChatLog isFromSameDayAsDate:filterDate];
			break;
		default:
			matchesDateFilter = YES;
			break;
	}

	return matchesDateFilter;
}


NSArray *pathComponentsForDocument(SKDocumentRef inDocument)
{
	CFURLRef	url = SKDocumentCopyURL(inDocument);
	if (!url) {
		AILogWithSignature(@"Could not get url for %p", inDocument);
		return nil;
	}

	NSString	*logPath = [(NSURL *)url path];
	if (!logPath)
		AILogWithSignature(@"Could not get path for %@", url);
	NSArray		*pathComponents = [logPath pathComponents];

	CFRelease(url);

	return pathComponents;
}


/*!
 * @brief Should a search display a document with the given information?
 */
- (BOOL)searchShouldDisplayDocument:(SKDocumentRef)inDocument pathComponents:(NSArray *)pathComponents testDate:(BOOL)testDate
{
	BOOL shouldDisplayDocument = YES;

	if ([contactIDsToFilter count]) {
		//Determine the path components if we weren't supplied them
		if (!pathComponents) pathComponents = pathComponentsForDocument(inDocument);

		NSUInteger numPathComponents = [pathComponents count];
		
		NSArray *serviceAndFromUIDArray = [[pathComponents objectAtIndex:numPathComponents-3] componentsSeparatedByString:@"."];
		NSString *serviceClass = (([serviceAndFromUIDArray count] >= 2) ? [serviceAndFromUIDArray objectAtIndex:0] : @"");

		NSString *contactName = [pathComponents objectAtIndex:(numPathComponents-2)];

		shouldDisplayDocument = [contactIDsToFilter containsObject:[[NSString stringWithFormat:@"%@.%@",serviceClass,contactName] compactedString]];
	} 
	
	if (shouldDisplayDocument && testDate && (filterDateType != AIDateTypeAnyDate)) {
		if (!pathComponents) pathComponents = pathComponentsForDocument(inDocument);

		NSUInteger	numPathComponents = [pathComponents count];
		NSString		*toPath = [NSString stringWithFormat:@"%@/%@",
			[pathComponents objectAtIndex:numPathComponents-3],
			[pathComponents objectAtIndex:numPathComponents-2]];
		NSString		*relativePath = [NSString stringWithFormat:@"%@/%@",toPath,[pathComponents objectAtIndex:numPathComponents-1]];
		AIChatLog		*theLog;
		
		theLog = [[logToGroupDict objectForKey:toPath] logAtPath:relativePath];
		
		shouldDisplayDocument = [self chatLogMatchesDateFilter:theLog];
	}

	return shouldDisplayDocument;
}

//Threaded filter/search methods ---------------------------------------------------------------------------------------
#pragma mark Threaded filter/search methods

/*!
 * @brief Perform a content search of the indexed logs
 *
 * This uses the 10.4+ asynchronous search functions.
 * Google-like search syntax (phrase, prefix/suffix, boolean, etc. searching) is automatically supported.
 */
- (void)_logContentFilter:(NSString *)searchString searchID:(NSInteger)searchID onSearchIndex:(SKIndexRef)logSearchIndex
{
	CGFloat			largestRankingValue = 0;
	SKSearchRef		thisSearch;
    Boolean			more = true;
    unsigned long			totalCount = 0;
	
	if (!logSearchIndex) {
		AILogWithSignature(@"Got a NULL logSearchIndex. This shouldn't happen!");
		return;
	}
	
	[currentSearchLock lock];
	if (currentSearch) {
		SKSearchCancel(currentSearch);
		CFRelease(currentSearch); currentSearch = NULL;
	}
	
	NSMutableString *wildcardedSearchString = [NSMutableString string];
	for (NSString *searchComponent in [searchString componentsSeparatedByString:@" "]) {
		if ([searchComponent rangeOfString:@"*"].location == NSNotFound) {
			//If the user specifies particular wildcard behavior, respect it
			[wildcardedSearchString appendFormat:@"*%@* ", searchComponent];
		} else
			[wildcardedSearchString appendFormat:@"%@ ", searchComponent];
	}
	
	thisSearch = SKSearchCreate(logSearchIndex,
								(CFStringRef)wildcardedSearchString,
								kSKSearchOptionDefault);
	currentSearch = (thisSearch ? (SKSearchRef)CFRetain(thisSearch) : NULL);
	[currentSearchLock unlock];
	
	AILogWithSignature(@"Calling flush");
	SKIndexFlush(logSearchIndex);
	AILogWithSignature(@"Done flushing. Now we can search.");
	
	//Retrieve matches as long as more are pending
    while (more && currentSearch) {
#define BATCH_NUMBER 100
        SKDocumentID	foundDocIDs[BATCH_NUMBER];
        float			foundScores[BATCH_NUMBER];
        SKDocumentRef	foundDocRefs[BATCH_NUMBER];
		
        CFIndex foundCount = 0;
        CFIndex i;
		
        more = SKSearchFindMatches (
									thisSearch,
									BATCH_NUMBER,
									foundDocIDs,
									foundScores,
									0.5, // maximum time before func returns, in seconds
									&foundCount
									);
		
        totalCount += foundCount;
		
        SKIndexCopyDocumentRefsForDocumentIDs (
											   logSearchIndex,
											   foundCount,
											   foundDocIDs,
											   foundDocRefs
											   );
        for (i = 0; ((i < foundCount) && (searchID == activeSearchID)) ; i++) {
			SKDocumentRef	document = foundDocRefs[i];
					if (!document) {
						AILogWithSignature(@"SearchKit returned NULL document for ID %ld", (long)foundDocIDs[i]);
						totalCount--;
						continue;
					}
			CFURLRef		url = SKDocumentCopyURL(document);
			if (!url) {
				AILogWithSignature(@"No URL for document %p", document);
				totalCount--;
				continue;
			}
			/*
			 * Nasty implementation note: As of 10.4.7 and all previous versions, a path longer than 1024 bytes (PATH_MAX)
			 * will cause CFURLCopyFileSystemPath() to crash [ultimately in CFGetAllocator()].  This is the case for all
			 * Cocoa applications...
			 */
			NSString *logPath = [(NSURL *)url path];
			if (!logPath) 
				AILogWithSignature(@"Could not get path for %@. ", url);
			
			NSArray	 *pathComponents = [(NSString *)logPath pathComponents];
			
			/* Handle chatlogs-as-bundles, which have an xml file inside our target .chatlog path */
			if ([[[pathComponents lastObject] pathExtension] caseInsensitiveCompare:@"xml"] == NSOrderedSame)
				pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 1)];
			
			//Don't test for the date now; we'll test once we've found the AIChatLog if we make it that far
			if ([self searchShouldDisplayDocument:document pathComponents:pathComponents testDate:NO]) {
				NSUInteger	numPathComponents = [pathComponents count];
				NSString		*toPath = [NSString stringWithFormat:@"%@/%@",
										   [pathComponents objectAtIndex:numPathComponents-3],
										   [pathComponents objectAtIndex:numPathComponents-2]];
				NSString		*path = [NSString stringWithFormat:@"%@/%@",toPath,[pathComponents objectAtIndex:numPathComponents-1]];
				AIChatLog		*theLog;
				
				/* Add the log - if our index is currently out of date (for example, a log was just deleted) 
				 * we may get a null log, so be careful.
				 */
				theLog = [[logToGroupDict objectForKey:toPath] logAtPath:path];
				if (!theLog) {
					AILog(@"_logContentFilter: %x's key %@ yields %@; logAtPath:%@ gives %@",logToGroupDict,toPath,[logToGroupDict objectForKey:toPath],path,theLog);
				}
				[resultsLock lock];
				if ((theLog != nil) &&
					(![currentSearchResults containsObjectIdenticalTo:theLog]) &&
					[self chatLogMatchesDateFilter:theLog] &&
					(searchID == activeSearchID)) {
					[theLog setRankingValueOnArbitraryScale:foundScores[i]];
					
					//SearchKit does not normalize ranking scores, so we track the largest we've found and use it as 1.0
					if (foundScores[i] > largestRankingValue) largestRankingValue = foundScores[i];
					
					[currentSearchResults addObject:theLog];
				} else {
					//Didn't get a valid log, so decrement our totalCount which is tracking how many logs we found
					totalCount--;
				}
				[resultsLock unlock];
				
			} else {
				//Didn't add this log, so decrement our totalCount which is tracking how many logs we found
				totalCount--;
			}
			
			//if (logPath) CFRelease(logPath);
			if (url) CFRelease(url);
			if (document) CFRelease(document);
        }
		
		//Scale all logs' ranking values to the largest ranking value we've seen thus far
		[resultsLock lock];
		for (i = 0; ((i < totalCount) && (searchID == activeSearchID)); i++) {
			AIChatLog	*theLog = [currentSearchResults objectAtIndex:i];
			[theLog setRankingPercentage:([theLog rankingValueOnArbitraryScale] / largestRankingValue)];
		}
		[resultsLock unlock];
		
		[self performSelectorOnMainThread:@selector(updateProgressDisplay)
							   withObject:nil
							waitUntilDone:NO];
		
		if (searchID != activeSearchID) {
			more = FALSE;
		}
    }
	
	//Ensure current search isn't released in two places simultaneously
	[currentSearchLock lock];
	if (currentSearch) {
		CFRelease(currentSearch);
		currentSearch = NULL;
	}
	[currentSearchLock unlock];
	
	if (thisSearch) CFRelease(thisSearch);
	if (logSearchIndex) CFRelease(logSearchIndex);
}

//Search the logs, filtering out any matching logs into the currentSearchResults
- (void)filterLogsWithSearch:(NSDictionary *)searchInfoDict
{
    NSAutoreleasePool       *pool = [[NSAutoreleasePool alloc] init];
    LogSearchMode                     mode = [[searchInfoDict objectForKey:@"Mode"] intValue];
    NSInteger                     searchID = [[searchInfoDict objectForKey:@"ID"] integerValue];
    NSString                *searchString = [searchInfoDict objectForKey:@"String"];

    if (searchID == activeSearchID) { //If we're still supposed to go
		searching = YES;
		AILogWithSignature(@"Search ID %i: %@", searchID, searchInfoDict);
		//Search
		if (searchString && [searchString length]) {
			switch (mode) {
				case LOG_SEARCH_FROM:
				case LOG_SEARCH_TO:
				case LOG_SEARCH_DATE:
					[self _logFilter:searchString
							searchID:searchID
								mode:mode];
					break;
				case LOG_SEARCH_CONTENT:
					[self _logContentFilter:searchString
								   searchID:searchID
							  onSearchIndex:[plugin logContentIndex]];
					break;
			}
		} else {
			[self _logFilter:nil
					searchID:searchID
						mode:mode];
		}
		
		//Refresh
		searching = NO;
		[self performSelectorOnMainThread:@selector(searchComplete) withObject:nil waitUntilDone:NO];
		AILogWithSignature(@"Search ID %i): finished", searchID);
    }
	
    //Cleanup
    [pool release];
}

//Perform a filter search based on source name, destination name, or date
- (void)_logFilter:(NSString *)searchString searchID:(NSInteger)searchID mode:(LogSearchMode)mode
{
    UInt32		lastUpdate = TickCount();
    
    NSCalendarDate	*searchStringDate = nil;
	
	if ((mode == LOG_SEARCH_DATE) && (searchString != nil)) {
		searchStringDate = [[NSDate dateWithNaturalLanguageString:searchString]  dateWithCalendarFormat:nil timeZone:nil];
	}
	
    //Walk through every 'from' group
    for (AILogFromGroup *fromGroup in [logFromGroupDict objectEnumerator]) {
		if (searchID != activeSearchID) break;
		
		//When searching in LOG_SEARCH_FROM, we only proceed into matching groups
		if ((mode != LOG_SEARCH_FROM) ||
			(!searchString) || 
			([[fromGroup fromUID] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound)) {

			//Walk through every 'to' group
			for (AILogToGroup *toGroup in [fromGroup toGroupArray]) {
				if (searchID != activeSearchID) break;

				/* When searching in LOG_SEARCH_TO, we only proceed into matching groups
				 * For all other search modes, we always proceed here so long as either:
				 *	a) We are not filtering for specific contact names or
				 *	b) The contact name matches one of the names in contactIDsToFilter
				 */
				if ((![contactIDsToFilter count] || [contactIDsToFilter containsObject:[[NSString stringWithFormat:@"%@.%@",[toGroup serviceClass],[toGroup to]] compactedString]]) &&
				   ((mode != LOG_SEARCH_TO) ||
				   (!searchString) || 
				   ([[toGroup to] rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound))) {
					
					//Walk through every log
					for (AIChatLog *theLog in [toGroup logEnumerator]) {
						if (searchID != activeSearchID) break;

						/* When searching in LOG_SEARCH_DATE, we must have matching dates
						 * For all other search modes, we always proceed here
						 */
						if ((mode != LOG_SEARCH_DATE) ||
						   (!searchString) ||
						   (searchStringDate && [theLog isFromSameDayAsDate:searchStringDate])) {

							if ([self chatLogMatchesDateFilter:theLog]) {
								//Add the log
								[resultsLock lock];
								[currentSearchResults addObject:theLog];
								[resultsLock unlock];
								
								//Update our status
								if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_SEARCH_STATUS_INTERVAL) {
									[self performSelectorOnMainThread:@selector(updateProgressDisplay)
														   withObject:nil
														waitUntilDone:NO];
									lastUpdate = TickCount();
								}
							}
						}
					}
				}
			}	    
		}
    }
}

//Search results table view --------------------------------------------------------------------------------------------
#pragma mark Search results table view
//Since this table view's source data will be accessed from within other threads, we need to lock before
//accessing it.  We also must be very sure that an incorrect row request is handled silently, since this
//can occur if the array size is changed during the reload.
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger count;
    
    [resultsLock lock];
    count = [currentSearchResults count];
    [resultsLock unlock];
    
    return count;
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString	*identifier = [tableColumn identifier];

	if ([identifier isEqualToString:@"Rank"] && row >= 0 && row < [currentSearchResults count]) {
		AIChatLog       *theLog = [currentSearchResults objectAtIndex:row];
		
		[aCell setPercentage:[theLog rankingPercentage]];
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString	*identifier = [tableColumn identifier];
    id          value = nil;
    
    [resultsLock lock];
    if (row < 0 || row >= [currentSearchResults count]) {
		if ([identifier isEqualToString:@"Service"]) {
			value = blankImage;
		} else {
			value = @"";
		}
		
	} else {
		AIChatLog       *theLog = [currentSearchResults objectAtIndex:row];

		if ([identifier isEqualToString:@"To"]) {
			// Get ListObject for to-UID
			AIListObject *listObject = [adium.contactController existingListObjectWithUniqueID:[AIListObject internalObjectIDForServiceID:[theLog serviceClass]
																																		UID:[theLog to]]];
			if (listObject) {
				//Use the longDisplayName, following the user's contact list preferences as this is presumably how she wants to view contacts' names.
				if (![listObject.displayName isEqualToString:listObject.UID]) {
					value = [NSString stringWithFormat:@"%@ (%@)", listObject.displayName, listObject.UID];
				} else {
					value = listObject.formattedUID;
				}

			} else {
				//No username available
				value = [theLog to];
			}
			
		} else if ([identifier isEqualToString:@"From"]) {
			value = [theLog from];
			
		} else if ([identifier isEqualToString:@"Date"]) {
			value = [theLog date];
			
		} else if ([identifier isEqualToString:@"Service"]) {
			NSString	*serviceClass;
			NSImage		*image;
			
			serviceClass = [theLog serviceClass];
			image = [AIServiceIcons serviceIconForService:[adium.accountController firstServiceWithServiceID:serviceClass]
													 type:AIServiceIconSmall
												direction:AIIconNormal];
			value = (image ? image : blankImage);
		}
    }
    [resultsLock unlock];
    
    return value;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(tableViewSelectionDidChangeDelayed)
											   object:nil];
	
	[self performSelector:@selector(tableViewSelectionDidChangeDelayed)
			   withObject:nil
			   afterDelay:0.05];
}

- (void)tableViewSelectionDidChangeDelayed
{
    if (!ignoreSelectionChange) {
		NSArray		*selectedLogs = nil;
		
		//Update the displayed log
		automaticSearch = NO;
		
		[resultsLock lock];
		@try {
			/* If currentSearchResults is out of sync with the data of tableView_results, this could throw an exception.
			 * Catching it is far more straightforward than preventing that possibility without breaking our re-selection of
			 * selected search results as the table view reloads when new results come in.
			 */
			selectedLogs = [tableView_results selectedItemsFromArray:currentSearchResults];
		} @catch (NSException *e) {
			
		} @finally {
			
		}
		[resultsLock unlock];
		
		if (selectedLogs)
			[self displayLogs:selectedLogs];
    }
}

//Sort the log array & reflect the new column
- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{    
    [self sortCurrentSearchResultsForTableColumn:tableColumn
                                   direction:(selectedColumn == tableColumn ? !sortDirection : sortDirection)];
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[resultsLock lock];
	NSArray *selectedLogs = [tableView_results selectedItemsFromArray:currentSearchResults];
	[resultsLock unlock];
	
	if ([selectedLogs count] > 0) {
		NSAlert *alert = [self alertForDeletionOfLogCount:[selectedLogs count]];
		[alert beginSheetModalForWindow:[self window] 
						  modalDelegate:self 
						 didEndSelector:@selector(deleteLogsAlertDidEnd:returnCode:contextInfo:) 
							contextInfo:[selectedLogs retain]];
	}
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
	NSTableColumn *dateTableColumn = [tableView_results tableColumnWithIdentifier:@"Date"];

	if (!aNotification ||
		([[aNotification userInfo] objectForKey:@"NSTableColumn"] == dateTableColumn)) {
		NSDateFormatter *dateFormatter;
		NSCell			*cell = [dateTableColumn dataCell];

		[cell setObjectValue:[NSDate date]];

		CGFloat width = [dateTableColumn width];

#define NUMBER_TIME_STYLES	2
#define NUMBER_DATE_STYLES	4
		NSDateFormatterStyle timeFormatterStyles[NUMBER_TIME_STYLES] = { NSDateFormatterShortStyle, NSDateFormatterNoStyle};
		NSDateFormatterStyle formatterStyles[NUMBER_DATE_STYLES] = { NSDateFormatterFullStyle, NSDateFormatterLongStyle, NSDateFormatterMediumStyle, NSDateFormatterShortStyle };
		CGFloat requiredWidth;

		dateFormatter = [cell formatter];
		if (!dateFormatter) {
			dateFormatter = [[[AILogDateFormatter alloc] init] autorelease];
			[cell setFormatter:dateFormatter];
		}
		
		requiredWidth = width + 1;
		for (NSInteger i = 0; (i < NUMBER_TIME_STYLES) && (requiredWidth > width); i++) {
			[dateFormatter setTimeStyle:timeFormatterStyles[i]];

			for (NSInteger j = 0; (j < NUMBER_DATE_STYLES) && (requiredWidth > width); j++) {
				[dateFormatter setDateStyle:formatterStyles[j]];
				requiredWidth = [cell cellSizeForBounds:NSMakeRect(0,0,1e6f,1e6f)].width;
				//Require a bit of space so the date looks comfortable. Very long dates relative to the current date can still overflow...
				requiredWidth += 3;
			}
		}
	}
}

- (IBAction)toggleEmoticonFiltering:(id)sender
{
	showEmoticons = !showEmoticons;
	[sender setLabel:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)];
	[sender setImage:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]];

	[self displayLogs:displayedLogArray];
}

- (IBAction)toggleTimestampFiltering:(id)sender
{
	showTimestamps = !showTimestamps;
	[sender setLabel:(showTimestamps ? HIDE_TIMESTAMPS : SHOW_TIMESTAMPS)];
	[sender setImage:[NSImage imageNamed:(showTimestamps ? IMAGE_TIMESTAMPS_ON : IMAGE_TIMESTAMPS_OFF) forClass:[self class]]];

	[self displayLogs:displayedLogArray];
}

#pragma mark Outline View Data source
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)idx ofItem:(id)item
{
	if (!item) {
		if (idx == 0) {
			return allContactsIdentifier;

		} else {
			return [toArray objectAtIndex:idx-1]; //-1 for the All item, which is index 0
		}

	} else {
		if ([item isKindOfClass:[AIMetaContact class]]) {
			return [[(AIMetaContact *)item listContactsIncludingOfflineAccounts] objectAtIndex:idx];
		}
	}
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return (!item || 
			([item isKindOfClass:[AIMetaContact class]] && ([[(AIMetaContact *)item listContactsIncludingOfflineAccounts] count] > 1)) ||
			[item isKindOfClass:[NSArray class]]);
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item) {
		return [toArray count] + 1; //+1 for the All item

	} else if ([item isKindOfClass:[AIMetaContact class]]) {
		NSUInteger count = [[(AIMetaContact *)item listContactsIncludingOfflineAccounts] count];
		if (count > 1)
			return count;
		else
			return 0;

	} else {
		return 0;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	Class itemClass = [item class];

	if (itemClass == [AIMetaContact class]) {
		return [(AIMetaContact *)item longDisplayName];
		
	} else if (itemClass == [AIListContact class]) {
		if ([(AIListContact *)item parentContact] != item) {
			//This contact is within a metacontact - always show its UID
			return [(AIListContact *)item formattedUID];
		} else {
			return [(AIListContact *)item longDisplayName];
		} 
		
	} else if (itemClass == [AILogToGroup class]) {
		return [(AILogToGroup *)item to];
		
	} else if (itemClass == [allContactsIdentifier class]) {
		NSUInteger contactCount = [toArray count];
		return [NSString stringWithFormat:AILocalizedString(@"All (%@)", nil),
			((contactCount == 1) ?
			 AILocalizedString(@"1 Contact", nil) :
			 [NSString stringWithFormat:AILocalizedString(@"%lu Contacts", nil), contactCount])];

	} else if (itemClass == [NSString class]) {
		return item;

	} else {
		NSLog(@"%@: no idea",item);
		return nil;
	}
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item isKindOfClass:[AIMetaContact class]] &&
		[[(AIMetaContact *)item listContactsIncludingOfflineAccounts] count] > 1) {
		/* If the metacontact contains a single contact, fall through (isKindOfClass:[AIListContact class]) and allow using of a service icon.
		 * If it has multiple contacts, use no icon unless a user icon is present.
		 */
		NSImage *image = [AIUserIcons listUserIconForContact:(AIListContact *)item
														size:NSMakeSize(16,16)];
		if (!image) image = [[[NSImage alloc] initWithSize:NSMakeSize(16, 16)] autorelease];

		[cell setImage:image];

	} else if ([item isKindOfClass:[AIListContact class]]) {
		NSImage	*image = [AIUserIcons listUserIconForContact:(AIListContact *)item
														size:NSMakeSize(16,16)];
		if (!image) image = [AIServiceIcons serviceIconForObject:(AIListContact *)item
															type:AIServiceIconSmall
													   direction:AIIconFlipped];
		[cell setImage:image];

	} else if ([item isKindOfClass:[AILogToGroup class]]) {
		[cell setImage:[AIServiceIcons serviceIconForService:[adium.accountController firstServiceWithServiceID:[(AILogToGroup *)item serviceClass]]
														type:AIServiceIconSmall
												   direction:AIIconNormal]];
		
	} else if ([item isKindOfClass:[allContactsIdentifier class]]) {
		if ([[outlineView arrayOfSelectedItems] containsObjectIdenticalTo:item] &&
			([[self window] isKeyWindow] && ([[self window] firstResponder] == self))) {
			if (!adiumIconHighlighted) {
				adiumIconHighlighted = [[NSImage imageNamed:@"adiumHighlight"
												   forClass:[self class]] retain];
			}

			[cell setImage:adiumIconHighlighted];

		} else {
			if (!adiumIcon) {
				adiumIcon = [[NSImage imageNamed:@"adium"
										forClass:[self class]] retain];
			}

			[cell setImage:adiumIcon];
		}

	} else if ([item isKindOfClass:[NSString class]]) {
		[cell setImage:nil];
		
	} else {
		NSLog(@"%@: no idea",item);
		[cell setImage:nil];
	}	
}

/*
 * @brief Is item supposed to have a divider below?
 *
 */
- (AIDividerPosition)outlineView:(NSOutlineView*)outlineView dividerPositionForItem:(id)item
{
	if ([item isKindOfClass:[allContactsIdentifier class]]) {
		return AIDividerPositionBelow;
	} else {
		return AIDividerPositionNone;
	}
}

- (void)outlineViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self deleteSelection:nil];
}


- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(outlineViewSelectionDidChangeDelayed)
											   object:nil];
	
	[self performSelector:@selector(outlineViewSelectionDidChangeDelayed)
			   withObject:nil
			   afterDelay:0.05];
}

- (void)outlineViewSelectionDidChangeDelayed
{
	NSArray *selectedItems = [outlineView_contacts arrayOfSelectedItems];

	[contactIDsToFilter removeAllObjects];

	if ([selectedItems count] && ![selectedItems containsObject:allContactsIdentifier]) {
		id		item;

		for (item in selectedItems) {
			if ([item isKindOfClass:[AIMetaContact class]]) {
				for (AIListContact *contact in [(AIMetaContact *)item listContactsIncludingOfflineAccounts]) {
					[contactIDsToFilter addObject:
						[[[NSString stringWithFormat:@"%@.%@", contact.service.serviceID, contact.UID] compactedString] safeFilenameString]];
				}
				
			} else if ([item isKindOfClass:[AIListContact class]]) {
				[contactIDsToFilter addObject:
					[[[NSString stringWithFormat:@"%@.%@",((AIListContact *)item).service.serviceID,((AIListContact *)item).UID] compactedString] safeFilenameString]];
				
			} else if ([item isKindOfClass:[AILogToGroup class]]) {
				[contactIDsToFilter addObject:[[NSString stringWithFormat:@"%@.%@",[(AILogToGroup *)item serviceClass],[(AILogToGroup *)item to]] compactedString]];
			}
		}
	}
	
	[self startSearchingClearingCurrentResults:YES];
}

- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent;
{
	if (outlineView == outlineView_contacts) {
		NSInteger clickedRow = [outlineView_contacts rowAtPoint:[outlineView_contacts convertPoint:[theEvent locationInWindow]
																					fromView:nil]];
		id item = [outlineView_contacts itemAtRow:clickedRow];

		//If we have a To group, see if we can make a contact out of it
		if ([item isKindOfClass:[AILogToGroup class]]) {
			if ([(AILogToGroup *)item to] && [(AILogToGroup *)item serviceClass]) {
				//We need a service with ther right service ID
				AIService *service = [adium.accountController firstServiceWithServiceID:[(AILogToGroup *)item serviceClass]];
				if (service) {
					//Next, we want an online account
					AIAccount *account = nil;
					for (account in [adium.accountController accountsCompatibleWithService:service]) {
						if (account.online) break;
					}
					
					if (account) {
						//Finally, make a contact
						item = [adium.contactController contactWithService:service
																	 account:account
																		 UID:[(AILogToGroup *)item to]];
					}
					
				}
			}
		}

		if ([item isKindOfClass:[AIListContact class]]) {
			NSArray			*locationsArray = [NSArray arrayWithObjects:
				[NSNumber numberWithInteger:Context_Contact_Message],
				[NSNumber numberWithInteger:Context_Contact_Manage],
				[NSNumber numberWithInteger:Context_Contact_Action],
				[NSNumber numberWithInteger:Context_Contact_ListAction],
				[NSNumber numberWithInteger:Context_Contact_NegativeAction],
				[NSNumber numberWithInteger:Context_Contact_Additions], nil];

			return [adium.menuController contextualMenuWithLocations:locationsArray
														 forListObject:(AIListContact *)item];
		}
	}
	
	return nil;
}

static NSInteger toArraySort(id itemA, id itemB, void *context)
{
	AILogViewerWindowController *sharedLogViewerInstance = [AILogViewerWindowController existingWindowController];
	NSString *nameA = [sharedLogViewerInstance outlineView:nil objectValueForTableColumn:nil byItem:itemA];
	NSString *nameB = [sharedLogViewerInstance outlineView:nil objectValueForTableColumn:nil byItem:itemB];
	NSComparisonResult result = [nameA caseInsensitiveCompare:nameB];
	if (result == NSOrderedSame) result = [nameA compare:nameB];

	return result;
}

#pragma mark Split View Delegate
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	//Force a minumum size for the log view
	if (splitView == splitView_logs)
		return splitView_logs.frame.size.height - 100.0f;
	else if (splitView == splitView_contacts)
		return floor(splitView_contacts.frame.size.width / 2);
	
	return proposedMax;
}

//Window Toolbar -------------------------------------------------------------------------------------------------------
#pragma mark Window Toolbar

- (void)installToolbar
{	
	[NSBundle loadNibNamed:[self dateItemNibName] owner:self];

    NSToolbar 		*toolbar = [[[NSToolbar alloc] initWithIdentifier:TOOLBAR_LOG_VIEWER] autorelease];
    NSToolbarItem	*toolbarItem;
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    toolbarItems = [[NSMutableDictionary alloc] init];

	//Delete Logs
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
                                        withIdentifier:@"delete"
                                                 label:DELETE
                                          paletteLabel:DELETE
                                               toolTip:AILocalizedString(@"Delete the selection",nil)
                                                target:self
                                       settingSelector:@selector(setImage:)
                                           itemContent:[NSImage imageNamed:@"remove" forClass:[self class]]
                                                action:@selector(deleteSelection:)
                                                  menu:nil];
	
	//Search
	[self window]; //Ensure the window is loaded, since we're pulling the search view from our nib
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:@"search"
														  label:SEARCH
												   paletteLabel:SEARCH
														toolTip:AILocalizedString(@"Search or filter logs",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:view_SearchField
														 action:@selector(updateSearch:)
														   menu:nil];
	if ([toolbarItem respondsToSelector:@selector(setVisibilityPriority:)]) {
		[toolbarItem setVisibilityPriority:(NSToolbarItemVisibilityPriorityHigh + 1)];
	}
	[toolbarItem setMinSize:NSMakeSize(130, NSHeight([view_SearchField frame]))];
	[toolbarItem setMaxSize:NSMakeSize(230, NSHeight([view_SearchField frame]))];
	[toolbarItems setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];

	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:DATE_ITEM_IDENTIFIER
														  label:AILocalizedString(@"Date", nil)
												   paletteLabel:AILocalizedString(@"Date", nil)
														toolTip:AILocalizedString(@"Filter logs by date",nil)
														 target:self
												settingSelector:@selector(setView:)
													itemContent:view_DatePicker
														 action:nil
														   menu:nil];
	if ([toolbarItem respondsToSelector:@selector(setVisibilityPriority:)]) {
		[toolbarItem setVisibilityPriority:NSToolbarItemVisibilityPriorityHigh];
	}
	[toolbarItem setMinSize:[view_DatePicker frame].size];
	[toolbarItem setMaxSize:[view_DatePicker frame].size];
	[toolbarItems setObject:toolbarItem forKey:[toolbarItem itemIdentifier]];

	//Toggle Emoticons
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"toggleemoticons"
											 label:(showEmoticons ? HIDE_EMOTICONS : SHOW_EMOTICONS)
									  paletteLabel:AILocalizedString(@"Show/Hide Emoticons",nil)
										   toolTip:AILocalizedString(@"Show or hide emoticons in logs",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:(showEmoticons ? IMAGE_EMOTICONS_ON : IMAGE_EMOTICONS_OFF) forClass:[self class]]
											action:@selector(toggleEmoticonFiltering:)
											  menu:nil];
	// Toggle Timestamps
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
																	withIdentifier:@"toggletimestamps"
																					 label:(showTimestamps ? HIDE_TIMESTAMPS : SHOW_TIMESTAMPS)
																		paletteLabel:AILocalizedString(@"Show/Hide Timestamps", nil)
																				 toolTip:AILocalizedString(@"Show or hide timestamps in logs", nil)
																				  target:self
																 settingSelector:@selector(setImage:)
																		 itemContent:[NSImage imageNamed:(showTimestamps ? IMAGE_TIMESTAMPS_ON : IMAGE_TIMESTAMPS_OFF) forClass:[self class]]
																					action:@selector(toggleTimestampFiltering:)
																						menu:nil];

	[[self window] setToolbar:toolbar];

	[self configureDateFilter];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:DATE_ITEM_IDENTIFIER, NSToolbarFlexibleSpaceItemIdentifier,
		@"delete", @"toggleemoticons", @"toggletimestamps", NSToolbarPrintItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
		@"search", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, 
			NSToolbarPrintItemIdentifier, nil]];
}

- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem *item = [[notification userInfo] objectForKey:@"item"];
	if ([[item itemIdentifier] isEqualToString:NSToolbarPrintItemIdentifier]) {
		[item setTarget:self];
		[item setAction:@selector(adiumPrint:)];
	}
}

#pragma mark Date filter

/*!
 * @brief Returns a menu item for the date type filter menu
 */
- (NSMenuItem *)_menuItemForDateType:(AIDateType)dateType dict:(NSDictionary *)dateTypeTitleDict
{
    NSMenuItem  *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[dateTypeTitleDict objectForKey:[NSNumber numberWithInteger:dateType]] 
																				 action:@selector(selectDateType:) 
																		  keyEquivalent:@""];
    [menuItem setTag:dateType];
    
    return [menuItem autorelease];
}

- (NSInteger)daysSinceStartOfWeekGivenToday:(NSCalendarDate *)today
{
	NSInteger todayDayOfWeek = [today dayOfWeek];

	//Try to look at the iCal preferences if possible
	if (!iCalFirstDayOfWeekDetermined) {
		CFPropertyListRef iCalFirstDayOfWeek = CFPreferencesCopyAppValue(CFSTR("first day of week"),CFSTR("com.apple.iCal"));
		if (iCalFirstDayOfWeek) {
			//This should return a CFNumberRef... we're using another app's prefs, so make sure.
			if (CFGetTypeID(iCalFirstDayOfWeek) == CFNumberGetTypeID()) {
				firstDayOfWeek = [(NSNumber *)iCalFirstDayOfWeek integerValue];
			}

			CFRelease(iCalFirstDayOfWeek);
		}

		//Don't check again
		iCalFirstDayOfWeekDetermined = YES;
	}

	return ((todayDayOfWeek >= firstDayOfWeek) ? (todayDayOfWeek - firstDayOfWeek) : ((todayDayOfWeek + 7) - firstDayOfWeek));
}

/*!
 * @brief Select the date type
 */
- (void)selectDateType:(id)sender
{
	[self selectedDateType:(AIDateType)[sender tag]];
	[self startSearchingClearingCurrentResults:YES];
}

#pragma mark Open Log

- (void)openLogAtPath:(NSString *)inPath
{
	AIChatLog   *chatLog = nil;
	NSString	*basePath = [AILoggerPlugin logBasePath];

	//inPath should be in a folder of the form SERVICE.ACCOUNT_NAME/CONTACT_NAME/log.extension
	NSArray		*pathComponents = [inPath pathComponents];
	NSInteger			lastIndex = [pathComponents count];
	NSString	*logName = [pathComponents objectAtIndex:--lastIndex];
	NSString	*contactName = [pathComponents objectAtIndex:--lastIndex];
	NSString	*serviceAndAccountName = [pathComponents objectAtIndex:--lastIndex];
	NSString		*relativeToGroupPath = [serviceAndAccountName stringByAppendingPathComponent:contactName];

	NSString	*serviceID = [[serviceAndAccountName componentsSeparatedByString:@"."] objectAtIndex:0];
	//Filter for logs from the contact associated with the log we're loading
	[self filterForContact:[adium.contactController contactWithService:[adium.accountController firstServiceWithServiceID:serviceID]
																 account:nil
																	 UID:contactName]];
	
	NSString *canonicalBasePath = [basePath stringByStandardizingPath];
	NSString *canonicalInPath = [inPath stringByStandardizingPath];

	if ([canonicalInPath hasPrefix:[canonicalBasePath stringByAppendingString:@"/"]]) {
		AILogToGroup	*logToGroup = [logToGroupDict objectForKey:[serviceAndAccountName stringByAppendingPathComponent:contactName]];
		
		chatLog = [logToGroup logAtPath:[relativeToGroupPath stringByAppendingPathComponent:logName]];
		
	} else {
		/* Different Adium user... this sucks. We're given a path like this:
		 *	/Users/evands/Application Support/Adium 2.0/Users/OtherUser/Logs/AIM.Tekjew/HotChick001/HotChick001 (3-30-2005).AdiumLog
		 * and we want to make it relative to our current user's logs folder, which might be
		 *  /Users/evands/Application Support/Adium 2.0/Users/Default/Logs
		 *
		 * To achieve this, add a "/.." for each directory in our current user's logs folder, then add the full path to the log.
		 */
		NSString	*fakeRelativePath = @"";
		
		//Use .. to get back to the root from the base path
		NSInteger componentsOfBasePath = [[canonicalBasePath pathComponents] count];
		for (NSInteger i = 0; i < componentsOfBasePath; i++) {
			fakeRelativePath = [fakeRelativePath stringByAppendingPathComponent:@".."];
		}
		
		//Now add the path from the root to the actual log
		fakeRelativePath = [fakeRelativePath stringByAppendingPathComponent:canonicalInPath];
		chatLog = [[[AIChatLog alloc] initWithPath:fakeRelativePath
											  from:[serviceAndAccountName substringFromIndex:([serviceID length] + 1)] //One off for the '.'
												to:contactName
									  serviceClass:serviceID] autorelease];
	}

	//Now display the requested log
	if (chatLog) {
		[self displayLog:chatLog];
	}
}

#pragma mark Printing

- (void)adiumPrint:(id)sender
{
	NSTextView			*printView;
    NSPrintOperation    *printOperation;
    NSPrintInfo			*printInfo = [NSPrintInfo sharedPrintInfo];

    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    
	printView = [[NSTextView alloc] initWithFrame:[[NSPrintInfo sharedPrintInfo] imageablePageBounds]];
    [printView setVerticallyResizable:YES];
    [printView setHorizontallyResizable:NO];
	
    [[printView textStorage] setAttributedString:[textView_content textStorage]];
	
    printOperation = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
    [printOperation runOperationModalForWindow:[self window] delegate:nil
								didRunSelector:NULL contextInfo:NULL];
	[printView release];
}

- (BOOL)validatePrintMenuItem:(NSMenuItem *)menuItem
{
	return ([displayedLogArray count] > 0);
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([[theItem itemIdentifier] isEqualToString:NSToolbarPrintItemIdentifier]) {
		return [self validatePrintMenuItem:nil];

	} else {
		return YES;
	}
}

- (void)selectCachedIndex
{
	NSInteger numberOfRows = [tableView_results numberOfRows];
	
	if (cachedSelectionIndex <  numberOfRows) {
		[tableView_results selectRowIndexes:[NSIndexSet indexSetWithIndex:cachedSelectionIndex]
					   byExtendingSelection:NO];
	} else {
		if (numberOfRows)
			[tableView_results selectRowIndexes:[NSIndexSet indexSetWithIndex:(numberOfRows-1)]
						   byExtendingSelection:NO];
	}

	if (numberOfRows) {
		[tableView_results scrollRowToVisible:[[tableView_results selectedRowIndexes] firstIndex]];
	}

	deleteOccurred = NO;
}

#pragma mark Deletion

/*!
 * @brief Get an NSAlert to request deletion of multiple logs
 */
- (NSAlert *)alertForDeletionOfLogCount:(NSUInteger)logCount
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:AILocalizedString(@"Delete Logs?",nil)];
	[alert setInformativeText:[NSString stringWithFormat:
		AILocalizedString(@"Are you sure you want to send %lu logs to the Trash?",nil), logCount]];
	[alert addButtonWithTitle:DELETE];
	[alert addButtonWithTitle:AILocalizedString(@"Cancel",nil)];
	
	return [alert autorelease];
}

/*!
 * @brief Undo the deletion of one or more AIChatLogs
 *
 * The logs will be marked for readdition to the index
 */
- (void)restoreDeletedLogs:(NSArray *)deletedLogs
{
	AIChatLog		*aLog;
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	NSString		*trashPath = [fileManager findFolderOfType:kTrashFolderType inDomain:kUserDomain createFolder:NO];

	for (aLog in deletedLogs) {
		NSString *logPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[aLog relativePath]];
		
		[fileManager createDirectoryAtPath:[logPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
		
		[fileManager moveItemAtPath:[trashPath stringByAppendingPathComponent:[logPath lastPathComponent]]
							 toPath:logPath 
							  error:NULL];
		
		[plugin markLogDirtyAtPath:logPath];
	}
	
	[self rebuildIndices];
}

- (void)deleteLogsAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode  contextInfo:(void *)contextInfo;
{
	NSArray *selectedLogs = (NSArray *)contextInfo;
	if (returnCode == NSAlertFirstButtonReturn) {
		[resultsLock lock];
		
		AIChatLog		*aLog;
		NSMutableSet	*logPaths = [NSMutableSet set];
		
		cachedSelectionIndex = [[tableView_results selectedRowIndexes] firstIndex];
		
		for (aLog in selectedLogs) {
			NSString *logPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[aLog relativePath]];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:ChatLog_WillDelete object:aLog userInfo:nil];
			AILogToGroup	*logToGroup = [logToGroupDict objectForKey:[[aLog relativePath] stringByDeletingLastPathComponent]];

			// Success will be unused in deployment builds as AILog turns to nothing
#ifdef DEBUG_BUILD
			BOOL success = [logToGroup trashLog:aLog];
			AILog(@"Trashing %@: %i",[aLog relativePath], success);
#else
			[logToGroup trashLog:aLog];
#endif
			//Clear the to group out if it no longer has anything of interest
			if ([logToGroup logCount] == 0) {
				AILogFromGroup	*logFromGroup = [logFromGroupDict objectForKey:[[[aLog relativePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent]];
				[logFromGroup removeToGroup:logToGroup];
			}

			[logPaths addObject:logPath];
			[currentSearchResults removeObjectIdenticalTo:aLog];
		}
		
		[plugin removePathsFromIndex:logPaths];
		
		[undoManager registerUndoWithTarget:self
								   selector:@selector(restoreDeletedLogs:)
									 object:selectedLogs];
		[undoManager setActionName:DELETE];
		
		[resultsLock unlock];
		[tableView_results reloadData];
		
		deleteOccurred = YES;
		
		[self rebuildContactsList];
		[self updateProgressDisplay];
	}
	[selectedLogs release];
}

/*!
 * @brief Delete logs
 *
 * If two or more logs are passed, confirmation will be requested.
 * This operation registers with the window controller's undo manager.
 *
 * @param selectedLogs An NSArray of logs to delete
 */
- (void)deleteLogs:(NSArray *)selectedLogs
{	
	if ([selectedLogs count] > 1) {
		NSAlert *alert = [self alertForDeletionOfLogCount:[selectedLogs count]];
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:self
						 didEndSelector:@selector(deleteLogsAlertDidEnd:returnCode:contextInfo:)
							contextInfo:[selectedLogs retain]];
	} else if ([selectedLogs count] == 1) {
		[self deleteLogsAlertDidEnd:nil
						 returnCode:NSAlertFirstButtonReturn
						contextInfo:[selectedLogs retain]];
	}
}

/*!
 * @brief Returns a set of all selected to groups on all accounts
 *
 * @param totalLogCount If non-NULL, will be set to the total number of logs on return
 */
- (NSArray *)allSelectedToGroups:(NSInteger *)totalLogCount
{
    NSEnumerator        *fromEnumerator;
    AILogFromGroup      *fromGroup;
	NSMutableArray		*allToGroups = [NSMutableArray array];

	if (totalLogCount) *totalLogCount = 0;

    //Walk through every 'from' group
    fromEnumerator = [logFromGroupDict objectEnumerator];
    while ((fromGroup = [fromEnumerator nextObject])) {
		NSEnumerator        *toEnumerator;
		AILogToGroup        *toGroup;

		//Walk through every 'to' group
		toEnumerator = [[fromGroup toGroupArray] objectEnumerator];
		while ((toGroup = [toEnumerator nextObject])) {
			if (![contactIDsToFilter count] || [contactIDsToFilter containsObject:[[NSString stringWithFormat:@"%@.%@",[toGroup serviceClass],[toGroup to]] compactedString]]) {
				if (totalLogCount) {
					*totalLogCount += [toGroup logCount];
				}
				
				[allToGroups addObject:toGroup];
			}
		}
	}

	return allToGroups;
}

/*!
 * @brief Undo the deletion of one or more AILogToGroups and their associated logs
 *
 * The logs will be marked for readdition to the index
 */
- (void)restoreDeletedToGroups:(NSArray *)toGroups
{
	AILogToGroup	*toGroup;
	NSFileManager	*fileManager = [NSFileManager defaultManager];
	NSString		*trashPath = [fileManager findFolderOfType:kTrashFolderType inDomain:kUserDomain createFolder:NO];
	NSString		*logBasePath = [AILoggerPlugin logBasePath];

	for (toGroup in toGroups) {
		NSString *toGroupPath = [logBasePath stringByAppendingPathComponent:[toGroup relativePath]];

		[fileManager createDirectoryAtPath:[toGroupPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
		if ([fileManager fileExistsAtPath:toGroupPath]) {
			AILog(@"Removing path %@ to make way for %@",
				  toGroupPath,[trashPath stringByAppendingPathComponent:[toGroupPath lastPathComponent]]);
			[fileManager removeItemAtPath:toGroupPath
									error:NULL];
		}
		[fileManager moveItemAtPath:[trashPath stringByAppendingPathComponent:[toGroupPath lastPathComponent]]
							 toPath:toGroupPath
							  error:NULL];
		
		NSEnumerator *logEnumerator = [toGroup logEnumerator];
		AIChatLog	 *aLog;
	
		while ((aLog = [logEnumerator nextObject])) {
			[plugin markLogDirtyAtPath:[logBasePath stringByAppendingPathComponent:[aLog relativePath]]];
		}
	}
	
	[self rebuildIndices];
}

- (void)deleteSelectedContactsFromSourceListAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	NSArray *allSelectedToGroups = (NSArray *)contextInfo;
	if (returnCode == NSAlertFirstButtonReturn) {
		AILogToGroup	*logToGroup;
		NSMutableSet	*logPaths = [NSMutableSet set];
		
		for (logToGroup in allSelectedToGroups) {
			NSEnumerator *logEnumerator;
			AIChatLog	 *aLog;
			
			logEnumerator = [logToGroup logEnumerator];
			while ((aLog = [logEnumerator nextObject])) {
				NSString *logPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[aLog relativePath]];
				[logPaths addObject:logPath];
			}
			
			AILogFromGroup	*logFromGroup = [logFromGroupDict objectForKey:[NSString stringWithFormat:@"%@.%@",[logToGroup serviceClass],[logToGroup from]]];
			[logFromGroup removeToGroup:logToGroup];
		}
		
		[plugin removePathsFromIndex:logPaths];
		
		[undoManager registerUndoWithTarget:self
								   selector:@selector(restoreDeletedToGroups:)
									 object:allSelectedToGroups];
		[undoManager setActionName:DELETE];
		
		[self rebuildIndices];
		[self updateProgressDisplay];
	}
	
	[allSelectedToGroups release];
}

/*!
 * @brief Delete entirely the logs of all contacts selected in the source list
 *
 * Confirmation by the user will be required.
 *
 * Note: A single item in the source list may have multiple associated AILogToGroups.
 */
- (void)deleteSelectedContactsFromSourceList
{
	NSInteger totalLogCount;
	NSArray *allSelectedToGroups = [self allSelectedToGroups:&totalLogCount];

	if (totalLogCount > 1) {
		NSAlert *alert = [self alertForDeletionOfLogCount:totalLogCount];
		[alert beginSheetModalForWindow:[self window]
						  modalDelegate:self
						 didEndSelector:@selector(deleteSelectedContactsFromSourceListAlertDidEnd:returnCode:contextInfo:)
							contextInfo:[allSelectedToGroups retain]];
	} else {
		[self deleteSelectedContactsFromSourceListAlertDidEnd:nil
												   returnCode:NSAlertFirstButtonReturn
												  contextInfo:[allSelectedToGroups retain]];
	}
}

/*!
 * @brief Delete the current selection
 *
 * If the contacts outline view is selected, one or more contacts' logs will be trashed.
 * If anything else is selected, the currently selected search result logs will be trashed.
 */
- (void)deleteSelection:(id)sender
{
	if ([[self window] firstResponder] == outlineView_contacts) {
		[self deleteSelectedContactsFromSourceList];
		
	} else {
		[resultsLock lock];
		NSArray *selectedLogs = [tableView_results selectedItemsFromArray:currentSearchResults];
		[resultsLock unlock];
		
		[self deleteLogs:selectedLogs];
	}
}

#pragma mark Undo
/*!
 * @brief Supply our undo manager when we are within the responder chain
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return undoManager;
}

#pragma mark Gestures
/*!
 * @brief Responds to a swipe gesture
 *
 * This is a private method added in AppKit 949.18.0.
 */
- (void)swipeWithEvent:(NSEvent *)inEvent
{
	NSTableView *targetTableView;
	NSInteger changeValue, nextSelected;

	if ([inEvent deltaY] == 0) {
		// For horizontal swipes, switch between individual logs.
		targetTableView = tableView_results;
		changeValue = [inEvent deltaX];
		// Lock the results when we're dealing with the logs tableView
		[resultsLock lock];
	} else {
		// For vertical swipes, switch between contacts.
		targetTableView = outlineView_contacts;
		changeValue = [inEvent deltaY];
	}
	
	// Swipe; +1f is left/up, -1f is right/down
	
	// Find the index of the next row to select.
	if (changeValue == -1) {
		// Going to the right.
		nextSelected = [[targetTableView selectedRowIndexes] lastIndex] + 1;
	} else {
		// Going to the left.
		nextSelected = [[targetTableView selectedRowIndexes] firstIndex] - 1;
	}
	
	// Loop around in circles.
	if (nextSelected >= [targetTableView numberOfRows]) {
		nextSelected = 0;
	} else if (nextSelected < 0) {
		nextSelected = [targetTableView numberOfRows]-1;
	}
	
	// Select either the next row or the previous row.
	[targetTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:nextSelected]
				 byExtendingSelection:NO];
	
	[targetTableView scrollRowToVisible:nextSelected];
	
	if ([inEvent deltaY] == 0)
		[resultsLock unlock];
}

#pragma mark Transcript services special-casing
NSString *handleSpecialCasesForUIDAndServiceClass(NSString *contactUID, NSString *serviceClass)
{
	/* Jabber and its specified derivative services need special handling;
	 * this is cross-contamination from ESPurpleJabberAccount.
	 */
	if ([serviceClass isEqualToString:@"Jabber"] ||
		[serviceClass isEqualToString:@"GTalk"] ||
		[serviceClass isEqualToString:@"LiveJournal"]) {
		
		if ([contactUID hasSuffix:@"@gmail.com"] ||
			[contactUID hasSuffix:@"@googlemail.com"] ||
            [contactUID hasSuffix:@"@public.talk.google.com"]) {
			serviceClass = @"GTalk";
			
		} else if ([contactUID hasSuffix:@"@livejournal.com"]){
			serviceClass = @"LiveJournal";
			
		} else {
			serviceClass = @"Jabber";
		}	
		
		/* OSCAR and its specified derivative services need special handling;
		 *  this is cross-contamination from CBPurpleOscarAccount.
		 */
	} else if ([serviceClass isEqualToString:@"AIM"] ||
			   [serviceClass isEqualToString:@"ICQ"] ||
			   [serviceClass isEqualToString:@"Mac"] ||
			   [serviceClass isEqualToString:@"MobileMe"]) {
		const char	firstCharacter = ([contactUID length] ? [contactUID characterAtIndex:0] : '\0');
		
		//Determine service based on UID
		if ([contactUID hasSuffix:@"@mac.com"]) {
			serviceClass = @"Mac";
		} else if ([contactUID hasSuffix:@"@me.com"]) {
			serviceClass = @"MobileMe";
		} else if (firstCharacter && (firstCharacter >= '0' && firstCharacter <= '9')) {
			serviceClass = @"ICQ";
		} else {
			serviceClass = @"AIM";
		}
	}
	
	return serviceClass;
}

#pragma mark Date type menu

- (void)configureDateFilter
{
	firstDayOfWeek = 0; /* Sunday */
	iCalFirstDayOfWeekDetermined = NO;
	
	[popUp_dateFilter setMenu:[self dateTypeMenu]];
	NSInteger idx = [popUp_dateFilter indexOfItemWithTag:AIDateTypeAnyDate];
	if(idx != NSNotFound)
		[popUp_dateFilter selectItemAtIndex:idx];
	[self selectedDateType:AIDateTypeAnyDate];
	
	[datePicker setDateValue:[NSDate date]];
}

- (IBAction)selectDate:(id)sender
{
	[filterDate release];
	filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];
	
	[self startSearchingClearingCurrentResults:YES];
}

- (NSMenu *)dateTypeMenu
{
	NSDictionary *dateTypeTitleDict = [NSDictionary dictionaryWithObjectsAndKeys:
									   AILocalizedString(@"Any Date", nil), [NSNumber numberWithInteger:AIDateTypeAnyDate],
									   AILocalizedString(@"Today", nil), [NSNumber numberWithInteger:AIDateTypeToday],
									   AILocalizedString(@"Since Yesterday", nil), [NSNumber numberWithInteger:AIDateTypeSinceYesterday],
									   AILocalizedString(@"This Week", nil), [NSNumber numberWithInteger:AIDateTypeThisWeek],
									   AILocalizedString(@"Within Last 2 Weeks", nil), [NSNumber numberWithInteger:AIDateTypeWithinLastTwoWeeks],
									   AILocalizedString(@"This Month", nil), [NSNumber numberWithInteger:AIDateTypeThisMonth],
									   AILocalizedString(@"Within Last 2 Months", nil), [NSNumber numberWithInteger:AIDateTypeWithinLastTwoMonths],
									   nil];
	NSMenu	*dateTypeMenu = [[NSMenu alloc] init];
	AIDateType dateType;
	
	[dateTypeMenu addItem:[self _menuItemForDateType:AIDateTypeAnyDate dict:dateTypeTitleDict]];
	[dateTypeMenu addItem:[NSMenuItem separatorItem]];
	
	for (dateType = AIDateTypeToday; dateType < AIDateTypeExactly; dateType++) {
		[dateTypeMenu addItem:[self _menuItemForDateType:dateType dict:dateTypeTitleDict]];
	}
	
	dateTypeTitleDict = [NSDictionary dictionaryWithObjectsAndKeys:
									   AILocalizedString(@"Exactly", nil), [NSNumber numberWithInteger:AIDateTypeExactly],
									   AILocalizedString(@"Before", nil), [NSNumber numberWithInteger:AIDateTypeBefore],
									   AILocalizedString(@"After", nil), [NSNumber numberWithInteger:AIDateTypeAfter],
									   nil];
	
	[dateTypeMenu addItem:[NSMenuItem separatorItem]];
	
	for (dateType = AIDateTypeExactly; dateType <= AIDateTypeAfter; dateType++) {
		[dateTypeMenu addItem:[self _menuItemForDateType:dateType dict:dateTypeTitleDict]];
	}
	
	return [dateTypeMenu autorelease];
}

/*!
 * @brief A new date type was selected
 *
 * The date picker will be hidden/revealed as appropriate.
 * This does not start a search
 */ 
- (void)selectedDateType:(AIDateType)dateType
{
	BOOL			showDatePicker = NO;
	
	NSCalendarDate	*today = [NSCalendarDate date];
	
	[filterDate release]; filterDate = nil;
	
	switch (dateType) {
		case AIDateTypeAnyDate:
			filterDateType = AIDateTypeAnyDate;
			break;
			
		case AIDateTypeToday:
			filterDateType = AIDateTypeExactly;
			filterDate = [today retain];
			break;
			
		case AIDateTypeSinceYesterday:
			filterDateType = AIDateTypeAfter;
			filterDate = [[today dateByAddingYears:0
											months:0
											  days:-1
											 hours:-[today hourOfDay]
										   minutes:-[today minuteOfHour]
										   seconds:-([today secondOfMinute] + 1)] retain];
			break;
			
		case AIDateTypeThisWeek:
			filterDateType = AIDateTypeAfter;
			filterDate = [[today dateByAddingYears:0
											months:0
											  days:-[self daysSinceStartOfWeekGivenToday:today]
											 hours:-[today hourOfDay]
										   minutes:-[today minuteOfHour]
										   seconds:-([today secondOfMinute] + 1)] retain];
			break;
			
		case AIDateTypeWithinLastTwoWeeks:
			filterDateType = AIDateTypeAfter;
			filterDate = [[today dateByAddingYears:0
											months:0
											  days:-14
											 hours:-[today hourOfDay]
										   minutes:-[today minuteOfHour]
										   seconds:-([today secondOfMinute] + 1)] retain];
			break;
			
		case AIDateTypeThisMonth:
			filterDateType = AIDateTypeAfter;
			filterDate = [[[NSCalendarDate date] dateByAddingYears:0
															months:0
															  days:-[today dayOfMonth]
															 hours:0
														   minutes:0
														   seconds:-1] retain];
			break;
			
		case AIDateTypeWithinLastTwoMonths:
			filterDateType = AIDateTypeAfter;
			filterDate = [[[NSCalendarDate date] dateByAddingYears:0
															months:-1
															  days:-[today dayOfMonth]
															 hours:0
														   minutes:0
														   seconds:-1] retain];
			break;
			
		default:
			break;
	}		
	
	switch (dateType) {
		case AIDateTypeExactly:
			filterDateType = AIDateTypeExactly;
			filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];
			showDatePicker = YES;
			break;
			
		case AIDateTypeBefore:
			filterDateType = AIDateTypeBefore;
			filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];
			showDatePicker = YES;
			break;
			
		case AIDateTypeAfter:
			filterDateType = AIDateTypeAfter;
			filterDate = [[[datePicker dateValue] dateWithCalendarFormat:nil timeZone:nil] retain];
			showDatePicker = YES;
			break;
			
		default:
			showDatePicker = NO;
			break;
	}
	
	BOOL updateSize = NO;
	if (showDatePicker && [datePicker isHidden]) {
		[datePicker setHidden:NO];
		updateSize = YES;
		
	} else if (!showDatePicker && ![datePicker isHidden]) {
		[datePicker setHidden:YES];
		updateSize = YES;
	}
	
	if (updateSize) {
		NSEnumerator *enumerator = [[[[self window] toolbar] items] objectEnumerator];
		NSToolbarItem *toolbarItem;
		while ((toolbarItem = [enumerator nextObject])) {
			if ([[toolbarItem itemIdentifier] isEqualToString:DATE_ITEM_IDENTIFIER]) {
				NSSize newSize = NSMakeSize(([datePicker isHidden] ? 180 : 290), NSHeight([view_DatePicker frame]));
				[toolbarItem setMinSize:newSize];
				[toolbarItem setMaxSize:newSize];
				break;
			}
		}		
	}
}

- (NSString *)dateItemNibName
{
	return @"LogViewerDateFilter";
}

@end
