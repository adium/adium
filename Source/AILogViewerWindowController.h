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

#import <Adium/AIWindowController.h>

typedef enum {
    LOG_SEARCH_FROM = 0,
    LOG_SEARCH_TO,
    LOG_SEARCH_DATE,
    LOG_SEARCH_CONTENT
} LogSearchMode;

typedef enum {
	AIDateTypeAnyDate = 0,
	AIDateTypeToday,
	AIDateTypeSinceYesterday,
	AIDateTypeThisWeek,
	AIDateTypeWithinLastTwoWeeks,
	AIDateTypeThisMonth,
	AIDateTypeWithinLastTwoMonths,
	AIDateTypeExactly,
	AIDateTypeBefore,
	AIDateTypeAfter
} AIDateType;

@class AIAccount, AIChatLog, AIDividedAlternatingRowOutlineView, AIGradientView, AIListContact, AILoggerPlugin;

@interface AILogViewerWindowController : AIWindowController <NSToolbarDelegate, NSOutlineViewDelegate, NSTableViewDelegate> {
	AILoggerPlugin					*plugin;

	IBOutlet	AIDividedAlternatingRowOutlineView	*outlineView_contacts;

	IBOutlet	NSSplitView			*splitView_contacts;
	IBOutlet	NSSplitView			*splitView_logs;
	IBOutlet	NSTableView			*tableView_results;
	IBOutlet	NSTextView			*textView_content;

	IBOutlet    NSView				*view_SearchField;

	IBOutlet	NSView				*view_DatePicker;
	IBOutlet	NSPopUpButton		*popUp_dateFilter;

	IBOutlet	NSTextField			*textField_resultCount;
	IBOutlet	NSProgressIndicator	*progressIndicator;
	IBOutlet	NSTextField			*textField_progress;

	IBOutlet	NSSearchField		*searchField_logs;

	IBOutlet	NSDatePicker		*datePicker;

	IBOutlet	AIGradientView		*view_FindNavigator;
	IBOutlet	NSTextField			*textField_findCount;
	IBOutlet	NSSegmentedControl	*segment_previousNext;

	//Array of selected / displayed logs.  (Locked access)
	NSMutableArray		*currentSearchResults;	//Array of filtered/resulting logs
	NSRecursiveLock		*resultsLock;			//Lock before touching the array
	NSArray				*displayedLogArray;		//Currently selected/displayed log(s)

	LogSearchMode		searchMode;				//Currently selected search mode

	NSTableColumn		*selectedColumn;		//Selected/active sort column

	//Search information
	NSInteger			activeSearchID;			//ID of the active search thread, all other threads should quit
	BOOL				searching;				//YES if a search is in progress
	NSString			*activeSearchString;	//Current search string
	BOOL				suppressSearchRequests;
	BOOL				isOpeningForContact;
	NSInteger			indexingUpdatesReceivedWhileSearching; //Number of times indexing has updated during the current search
	NSMutableArray		*matches;
	NSInteger			currentMatch;

	BOOL				sortDirection;			//Direction to sort

	NSTimer				*refreshResultsTimer;
	NSInteger			searchIDToReattemptWhenComplete;

	NSMutableSet		*contactIDsToFilter;

	AIDateType			filterDateType;
	NSCalendarDate		*filterDate;
	NSInteger			firstDayOfWeek;
	BOOL				iCalFirstDayOfWeekDetermined;

	NSMutableDictionary	*logToGroupDict;
	NSMutableDictionary	*logFromGroupDict;

	BOOL				automaticSearch;		//YES if this search was performed automatically for the user (view ___'s logs...)
	BOOL				ignoreSelectionChange;	//Hack to prevent automatic table selection changes from clearing the automaticSearch flag
	BOOL				windowIsClosing;		//YES only if windowShouldClose: has been called, to prevent actions after that point

	NSMutableDictionary	*toolbarItems;
	NSImage				*blankImage;
	NSImage				*adiumIcon;
	NSImage				*adiumIconHighlighted;

	NSMutableArray		*toArray;				//Array of contacts

	NSInteger			cachedSelectionIndex;
	BOOL				deleteOccurred;			// YES only if a delete occurs, allowing the table to preserve selection after a search begins

	NSString			*horizontalRule;

	NSUndoManager		*undoManager;

	NSNumber			*allContactsIdentifier;
	//Old
	BOOL				showEmoticons;
	BOOL				showTimestamps;

	SKSearchRef			currentSearch;
	NSLock				*currentSearchLock;
	
	NSInvocationOperation *displayOperation;
}

+ (id)openForPlugin:(id)inPlugin;
+ (id)openForContact:(AIListContact *)inContact plugin:(id)inPlugin;
+ (id)openForChatName:(NSString *)inChatName withAccount:(AIAccount *)inAccount plugin:(id)inPlugin;
+ (id)openLogAtPath:(NSString *)inPath plugin:(id)inPlugin;
+ (id)existingWindowController;
+ (void)closeSharedInstance;

- (void)stopSearching;

- (void)displayLog:(AIChatLog *)log;

- (void)setSearchMode:(LogSearchMode)inMode;
- (void)setSearchString:(NSString *)inString;
- (IBAction)updateSearch:(id)sender;

- (IBAction)selectNextPreviousOccurrence:(id)sender;
- (void)searchComplete;
- (void)startSearchingClearingCurrentResults:(BOOL)clearCurrentResults;

- (void)resortLogs;
- (void)selectFirstLog;
- (void)selectDisplayedLog;
- (void)refreshResults;
- (void)refreshResultsSearchIsComplete:(BOOL)searchIsComplete;
- (void)updateProgressDisplay;
- (void)logIndexingProgressUpdate;

- (void)rebuildIndices;

- (BOOL)searchShouldDisplayDocument:(SKDocumentRef)inDocument pathComponents:(NSArray *)pathComponents testDate:(BOOL)testDate;
- (BOOL)chatLogMatchesDateFilter:(AIChatLog *)inChatLog;

- (void)filterLogsWithSearch:(NSDictionary *)searchInfoDict;

- (NSMenu *)dateTypeMenu;
- (NSMenuItem *)_menuItemForDateType:(AIDateType)dateType dict:(NSDictionary *)dateTypeTitleDict;
- (IBAction)selectDateType:(id)sender;
- (void)selectedDateType:(AIDateType)dateType;
- (void)configureDateFilter;

- (NSString *)dateItemNibName;

@end

NSString *handleSpecialCasesForUIDAndServiceClass(NSString *contactUID, NSString *serviceClass);
