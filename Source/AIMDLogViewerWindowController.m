//
//  AIMDLogViewerWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/1/06.
//

#import "AIMDLogViewerWindowController.h"
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AILogFromGroup.h"
#import "AIChatLog.h"
#import <Adium/AIContactControllerProtocol.h>

@implementation AIMDLogViewerWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		currentSearchLock = [[NSLock alloc] init];
	}
	return self;
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[tableView_results setAutosaveName:@"LogViewerResults"];
	[tableView_results setAutosaveTableColumns:YES];
}

/*!
 * @brief Perform a content search of the indexed logs
 *
 * This uses the 10.4+ asynchronous search functions.
 * Google-like search syntax (phrase, prefix/suffix, boolean, etc. searching) is automatically supported.
 */
- (void)_logContentFilter:(NSString *)searchString searchID:(int)searchID onSearchIndex:(SKIndexRef)logSearchIndex
{
	float			largestRankingValue = 0;
	SKSearchRef		thisSearch;
    Boolean			more = true;
    UInt32			totalCount = 0;

	[currentSearchLock lock];
	if (currentSearch) {
		SKSearchCancel(currentSearch);
		CFRelease(currentSearch); currentSearch = NULL;
	}

	thisSearch = SKSearchCreate(logSearchIndex,
								(CFStringRef)searchString,
								kSKSearchOptionDefault);
	currentSearch = (thisSearch ? (SKSearchRef)CFRetain(thisSearch) : NULL);
	[currentSearchLock unlock];

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
			CFURLRef		url = SKDocumentCopyURL(document);
			/*
			 * Nasty implementation note: As of 10.4.7 and all previous versions, a path longer than 1024 bytes (PATH_MAX)
			 * will cause CFURLCopyFileSystemPath() to crash [ultimately in CFGetAllocator()].  This is the case for all
			 * Cocoa applications...
			 */
			CFStringRef		logPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
			NSArray			*pathComponents = [(NSString *)logPath pathComponents];

			/* Handle chatlogs-as-bundles, which have an xml file inside our target .chatlog path */
			if ([[[pathComponents lastObject] pathExtension] caseInsensitiveCompare:@"xml"] == NSOrderedSame)
				pathComponents = [pathComponents subarrayWithRange:NSMakeRange(0, [pathComponents count] - 1)];

			//Don't test for the date now; we'll test once we've found the AIChatLog if we make it that far
			if ([self searchShouldDisplayDocument:document pathComponents:pathComponents testDate:NO]) {
				unsigned int	numPathComponents = [pathComponents count];
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
			
			if (logPath) CFRelease(logPath);
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
}

- (void)stopSearching
{	
	[currentSearchLock lock];
	if (currentSearch) {
		SKSearchCancel(currentSearch);
		CFRelease(currentSearch); currentSearch = nil;
	}
	[currentSearchLock unlock];

	[super stopSearching];
}

#pragma mark Date type menu

- (void)configureDateFilter
{
	[super configureDateFilter];
	
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
	NSMenu		*dateTypeMenu = [super dateTypeMenu];
	AIDateType	dateType;
	NSDictionary *dateTypeTitleDict = [NSDictionary dictionaryWithObjectsAndKeys:
		AILocalizedString(@"Exactly", nil), [NSNumber numberWithInt:AIDateTypeExactly],
		AILocalizedString(@"Before", nil), [NSNumber numberWithInt:AIDateTypeBefore],
		AILocalizedString(@"After", nil), [NSNumber numberWithInt:AIDateTypeAfter],
		nil];

	[dateTypeMenu addItem:[NSMenuItem separatorItem]];		

	for (dateType = AIDateTypeExactly; dateType <= AIDateTypeAfter; dateType++) {
		[dateTypeMenu addItem:[self _menuItemForDateType:dateType dict:dateTypeTitleDict]];
	}

	return dateTypeMenu;
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

	[super selectedDateType:dateType];

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

- (void)dealloc
{
	[filterDate release]; filterDate = nil;
	[currentSearchLock release]; currentSearchLock = nil;

	[super dealloc];
}

@end
