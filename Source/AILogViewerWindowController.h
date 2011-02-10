//
//  AILogViewerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/24/06.
//

#import <Adium/AIWindowController.h>
#import <AIUtilities/AIDividedAlternatingRowOutlineView.h>
#import <AIUtilities/AILeopardCompatibility.h>

@class AIChatLog, AILoggerPlugin;

#define LOG_SEARCH_STATUS_INTERVAL		20	//1/60ths of a second to wait before refreshing search status

#define LOG_CONTENT_SEARCH_MAX_RESULTS	10000	//Max results allowed from a search
#define LOG_RESULT_CLUMP_SIZE			10	//Number of logs to fetch at a time

#define SEARCH_MENU						AILocalizedString(@"Search Menu",nil)
#define FROM							AILocalizedString(@"From",nil)
#define TO								AILocalizedString(@"To",nil)

#define ACCOUNT							AILocalizedString(@"Account",nil)
#define DESTINATION						AILocalizedString(@"Destination",nil)

#define DATE							AILocalizedString(@"Date",nil)
#define CONTENT							AILocalizedString(@"Content",nil)
#define DELETE							AILocalizedString(@"Delete",nil)
#define DELETEALL						AILocalizedString(@"Delete All",nil)
#define SEARCH							AILocalizedString(@"Search",nil)

#define	KEY_LOG_VIEWER_EMOTICONS			@"Log Viewer Emoticons"
#define	KEY_LOG_VIEWER_TIMESTAMPS			@"Log Viewer Timestamps"
#define KEY_LOG_VIEWER_SELECTED_COLUMN		@"Log Viewer Selected Column Identifier"
#define	LOG_VIEWER_DID_CREATE_LOG_ARRAYS	@"LogViewerDidCreateLogArrays"
#define	LOG_VIEWER_DID_UPDATE_LOG_ARRAYS	@"LogViewerDidUpdateLogArrays"

#define DATE_ITEM_IDENTIFIER			@"date"

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

@class AIListContact, AISplitView, KNShelfSplitView, AIChat, AIAccount;

@interface AILogViewerWindowController : AIWindowController <NSToolbarDelegate> {
	AILoggerPlugin				*plugin;

	IBOutlet	AIDividedAlternatingRowOutlineView	*outlineView_contacts;

	IBOutlet	NSSplitView		*splitView_contacts;
	IBOutlet	NSSplitView		*splitView_logs;
	IBOutlet	NSTableView		*tableView_results;
	IBOutlet	NSTextView		*textView_content;

	IBOutlet    NSView			*view_SearchField;
	IBOutlet    NSButton		*button_deleteLogs;

	IBOutlet	NSView			*view_DatePicker;
	IBOutlet	NSPopUpButton	*popUp_dateFilter;

	IBOutlet	NSTextField			*textField_resultCount;
	IBOutlet	NSProgressIndicator	*progressIndicator;
	IBOutlet	NSTextField			*textField_progress;

	IBOutlet	NSSearchField	*searchField_logs;

	IBOutlet	NSDatePicker	*datePicker;

	IBOutlet	NSView			*view_FindNavigator;
	IBOutlet	NSTextField		*textField_findCount;
	IBOutlet	NSSegmentedControl	*segment_previousNext;

	//Array of selected / displayed logs.  (Locked access)
	NSMutableArray		*currentSearchResults;	//Array of filtered/resulting logs
	NSRecursiveLock		*resultsLock;			//Lock before touching the array
	NSArray				*displayedLogArray;		//Currently selected/displayed log(s)

	LogSearchMode		searchMode;				//Currently selected search mode

	NSTableColumn		*selectedColumn;		//Selected/active sort column

	//Search information
	NSInteger					activeSearchID;			//ID of the active search thread, all other threads should quit
	NSLock				*searchingLock;			//Locked when a search is in progress
	BOOL				searching;				//YES if a search is in progress
	NSString			*activeSearchString;	//Current search string
	BOOL				suppressSearchRequests;
	BOOL				isOpeningForContact;
	NSInteger					indexingUpdatesReceivedWhileSearching; //Number of times indexing has updated during the current search
	NSMutableArray		*matches;
	NSInteger			currentMatch;

	BOOL				sortDirection;			//Direction to sort

	NSTimer				*refreshResultsTimer;
	NSInteger					searchIDToReattemptWhenComplete;

	NSString			*filterForAccountName;	//Account name to restrictively match content searches
	NSMutableSet		*contactIDsToFilter;

	AIDateType			filterDateType;
	NSCalendarDate		*filterDate;
	NSInteger					firstDayOfWeek;
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

	NSMutableArray		*fromArray;				//Array of account names
	NSMutableArray		*fromServiceArray;		//Array of services for accounts
	NSMutableArray		*toArray;				//Array of contacts
	NSMutableArray		*toServiceArray;		//Array of services for accounts
	NSDateFormatter		*headerDateFormatter;	//Format for dates displayed in the content text view

	NSInteger					sameSelection;
	BOOL				useSame;

	NSInteger					cachedSelectionIndex;
	BOOL				deleteOccurred;			// YES only if a delete occurs, allowing the table to preserve selection after a search begins

	NSString			*horizontalRule;

	NSUndoManager		*undoManager;

	NSNumber			*allContactsIdentifier;
	//Old
	BOOL showEmoticons;
	BOOL showTimestamps;

	SKSearchRef currentSearch;
	NSLock		*currentSearchLock;
	
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
- (void)installToolbar;

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
