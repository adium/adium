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

#import "AILoggerPlugin.h"
#import "AIChatLog.h"
#import "AILogFromGroup.h"
#import "AILogToGroup.h"
#import "AILogViewerWindowController.h"
#import "AIXMLAppender.h"
#import <Adium/AIXMLElement.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentNotification.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListBookmark.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/NSCalendarDate+ISO8601Unparsing.h>
#import <AIUtilities/NSCalendarDate+ISO8601Parsing.h>

#import <libkern/OSAtomic.h>

#import "AILogFileUpgradeWindowController.h"

#import "AdiumSpotlightImporter.h"

#pragma mark Defines
#pragma mark -

#define LOG_INDEX_NAME				@"Logs.index"
#define KEY_LOG_INDEX_VERSION		@"Log Index Version"
#define DIRTY_LOG_SET_NAME			@"DirtyLogs.plist"
#define KEY_LOG_INDEX_VERSION		@"Log Index Version"

//Version of the log index.  Increase this number to reset everyone's index.
#define	CURRENT_LOG_VERSION			10
#define LOG_INDEX_STATUS_INTERVAL   20
#define LOG_CLEAN_SAVE_INTERVAL     2000
#define NEW_LOGFILE_TIMEOUT         600

#define LOG_VIEWER					AILocalizedString(@"Chat Transcript Viewer",nil)
#define VIEW_LOGS_WITH_CONTACT		AILocalizedString(@"View Chat Transcripts",nil)

#define	LOG_VIEWER_IDENTIFIER		@"LogViewer"

#define ENABLE_PROXIMITY_SEARCH		TRUE

#pragma mark -
#pragma mark Private Interface
#pragma mark -

//GetMetadataForFile.m
NSData *CopyDataForURL(CFStringRef contentTypeUTI, NSURL *urlToFile);
CFStringRef CopyTextContentForFileData(CFStringRef contentTypeUTI, NSURL *urlToFile, NSData *fileData);

@interface AILoggerPlugin ()
// class methods
+ (NSString *)pathForLogsLikeChat:(AIChat *)chat;
+ (NSString *)fullPathForLogOfChat:(AIChat *)chat onDate:(NSDate *)date;
+ (NSString *)nameForLogWithObject:(NSString *)object onDate:(NSDate *)date;

// Installation methods
- (void)_configureMenuItems;
- (void)_initLogIndexing;
- (void)_upgradeLogExtensions;
- (void)_upgradeLogPermissions;
- (void)_reimportLogsToSpotlightIfNeeded;

//  Action methods
- (void)showLogViewer:(id)sender;
- (void)showLogViewerToSelectedContact:(id)sender;
- (void)showLogViewerToSelectedContextContact:(id)sender;
- (void)showLogViewerForActiveChat:(id)sender;
- (void)showLogViewerForGroupChat:(id)sender;
- (void)showLogViewerAndReindex:(id)sender;
- (void)showLogNotification:(NSNotification *)inNotification;
- (void)_showLogViewerForLogAtPath:(NSString *)inPath;

// Logging
- (void)contentObjectAdded:(NSNotification *)notification;
- (void)chatOpened:(NSNotification *)notification;
- (void)chatClosed:(NSNotification *)notification;
- (void)chatWillDelete:(NSNotification *)notification;

// Logging Internals
- (AIXMLAppender *)_appenderForChat:(AIChat *)chat;
- (AIXMLAppender *)_existingAppenderForChat:(AIChat *)chat;
- (NSString *)keyForChat:(AIChat *)chat;
- (void)closeAppenderForChat:(AIChat *)chat;
- (void)finishClosingAppender:(NSString *)chatKey;

// Log Indexing
- (NSString *)_logIndexPath;
- (NSString *)_dirtyLogSetPath;
- (void)_loadDirtyLogSet;
- (void)_resetLogIndex;
- (void)_cancelClosingLogIndex;
- (void)_cleanDirtyLogs;
- (void)_dirtyAllLogs;

// Log Indexing Internals
- (void)_didCleanDirtyLogs;
- (void)_saveDirtyLogSet;
- (void)_markLogDirtyAtPath:(NSString *)path forChat:(AIChat *)chat;

// cleanup
- (void)_closeLogIndex;
- (void)_flushIndex:(SKIndexRef)inIndex;

// properties
@property(strong, readwrite) NSMutableDictionary *activeAppenders;
@property(readwrite, strong) AIHTMLDecoder       *xhtmlDecoder;
@property(readwrite, strong) NSDictionary        *statusTranslation;
@property(strong,readwrite) NSMutableSet        *dirtyLogSet;
@property(assign,readwrite) BOOL                 logHTML;
@property(assign,readwrite) BOOL                 indexingAllowed;
@property(assign,readwrite) BOOL                 loggingEnabled;
@property(assign,readwrite) BOOL                 canCloseIndex;
@property(assign,readwrite) BOOL                 canSaveDirtyLogSet;
@property(assign,readwrite) BOOL                 indexIsFlushing;
@property(assign,readwrite) BOOL                 isIndexing;
@property(assign,readwrite) SInt64               logsToIndex;
@property(assign,readwrite) SInt64               logsIndexed;
@end

#pragma mark Private Function Prototypes
NSCalendarDate* getDateFromPath(NSString *path);
NSComparisonResult sortPaths(NSString *path1, NSString *path2, void *context);

#pragma mark -
#pragma mark Static Globals
#pragma mark -
//The base directory of all logs
static NSString     *logBasePath = nil;
//If the usual Logs folder path refers to an alias file, this is that path, and logBasePath is the destination of the alias; otherwise, this is nil and logBasePath is the usual Logs folder path.
static NSString     *logBaseAliasPath = nil;

#pragma mark Dispatch
static dispatch_queue_t     defaultDispatchQueue;

static dispatch_queue_t     dirtyLogSetMutationQueue;
static dispatch_queue_t     searchIndexQueue;
static dispatch_queue_t     activeAppendersMutationQueue;
static dispatch_queue_t     addToSearchKitQueue;

static dispatch_queue_t     ioQueue;

static dispatch_group_t     logIndexingGroup;
static dispatch_group_t     closingIndexGroup;
static dispatch_group_t     logAppendingGroup;
static dispatch_group_t		loggerPluginGroup;

static dispatch_semaphore_t jobSemaphore;
static dispatch_semaphore_t logLoadingPrefetchSemaphore; //limit prefetching log data to N-1 ahead

@implementation AILoggerPlugin
@synthesize dirtyLogSet, indexingAllowed, loggingEnabled, logsToIndex, logsIndexed, canCloseIndex, canSaveDirtyLogSet, activeAppenders, logHTML, xhtmlDecoder, statusTranslation, isIndexing, indexIsFlushing;

#pragma mark -
#pragma mark Public Methods
#pragma mark -
#pragma mark Overridden AIPlugin Methods
- (void)installPlugin
{
	userTriggeredReindex = NO;
	self.indexingAllowed = YES;
	self.canCloseIndex = YES;
	self.loggingEnabled = NO;
	self.canSaveDirtyLogSet = YES;
	self.isIndexing = NO;
	self.indexIsFlushing = NO;
	logIndex = nil;
	self.activeAppenders = [NSMutableDictionary dictionary];
	self.dirtyLogSet = [NSMutableSet set];
	
	defaultDispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	
	dirtyLogSetMutationQueue = dispatch_queue_create("im.adium.AILoggerPlugin.dirtyLogSetMutationQueue", 0);
	searchIndexQueue = dispatch_queue_create("im.adium.AILoggerPlugin.searchIndexFlushingQueue", 0);
	activeAppendersMutationQueue = dispatch_queue_create("im.adium.AILoggerPlugin.activeAppendersMutationQueue", 0);
    addToSearchKitQueue = dispatch_queue_create("im.adium.AILoggerPlugin.searchIndexAddingQueue", 0);
    
	logIndexingGroup = dispatch_group_create();
	closingIndexGroup = dispatch_group_create();
	logAppendingGroup = dispatch_group_create();
	loggerPluginGroup = dispatch_group_create();
	
	ioQueue = dispatch_queue_create("im.adium.AILoggerPlugin.ioQueue", 0);
	
	NSUInteger cpuCount = [[NSProcessInfo processInfo] activeProcessorCount];	
	jobSemaphore = dispatch_semaphore_create(3 * cpuCount);
    logLoadingPrefetchSemaphore = dispatch_semaphore_create(3 * cpuCount + 1); //prefetch one log
	
	
	self.xhtmlDecoder = [[AIHTMLDecoder alloc] initWithHeaders:NO
													   fontTags:YES
												  closeFontTags:YES
													  colorTags:YES
													  styleTags:YES
												 encodeNonASCII:YES
												   encodeSpaces:NO
											  attachmentsAsText:NO
									  onlyIncludeOutgoingImages:NO
												 simpleTagsOnly:NO
												 bodyBackground:NO
											allowJavascriptURLs:YES];
	
	[self.xhtmlDecoder setGeneratesStrictXHTML:YES];
	
	self.statusTranslation = [NSDictionary dictionaryWithObjectsAndKeys:
							  @"away",@"away",
							  @"online",@"return_away",
							  @"online",@"online",
							  @"offline",@"offline",
							  @"idle",@"idle",
							  @"available",@"return_idle",
							  @"away",@"away_message",
							  nil];
	
	//Setup our preferences
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed: LOGGING_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_LOGGING];
	
	[self _configureMenuItems];
	
	// Create logs dir
	static dispatch_once_t setLogBasePath;
	dispatch_once(&setLogBasePath, ^{
		logBasePath = [[[adium.loginController userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
	});
	
	[[NSFileManager defaultManager] createDirectoryAtPath:logBasePath withIntermediateDirectories:YES attributes:nil error:NULL];
	
	//Observe preference changes
	[adium.preferenceController addObserver:self
								 forKeyPath:PREF_KEYPATH_LOGGER_ENABLE
									options:NSKeyValueObservingOptionNew
									context:NULL];
	[self observeValueForKeyPath:PREF_KEYPATH_LOGGER_ENABLE
						ofObject:adium.preferenceController
						  change:nil
						 context:NULL];
	
	//Toolbar item
	NSToolbarItem	*toolbarItem;
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:LOG_VIEWER_IDENTIFIER
														  label:AILocalizedString(@"Transcripts",nil)
												   paletteLabel:AILocalizedString(@"View Chat Transcripts",nil)
														toolTip:AILocalizedString(@"View previous conversations with this contact or chat",nil)
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"msg-log-viewer" forClass:[self class] loadLazily:YES]
														 action:@selector(showLogViewerForActiveChat:)
														   menu:nil];
	[adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
	
	
	//Init index searching
	[self _initLogIndexing];
	
	[self _upgradeLogExtensions];
	[self _upgradeLogPermissions];
	
	[self _reimportLogsToSpotlightIfNeeded];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showLogNotification:)
												 name:AIShowLogAtPathNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showLogViewerAndReindex:)
												 name:AIShowLogViewerAndReindexNotification
											   object:nil];
}

- (void)uninstallPlugin
{
	[self cancelIndexing];
	[self _closeLogIndex];
	dispatch_group_wait(closingIndexGroup, DISPATCH_TIME_FOREVER);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController removeObserver:self forKeyPath:PREF_KEYPATH_LOGGER_ENABLE];
}

- (void)dealloc
{
	dispatch_group_wait(logIndexingGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_wait(closingIndexGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_wait(logAppendingGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_wait(loggerPluginGroup, DISPATCH_TIME_FOREVER);
	
	dispatch_release(dirtyLogSetMutationQueue); dirtyLogSetMutationQueue = nil;
	dispatch_release(searchIndexQueue); searchIndexQueue = nil;
	dispatch_release(activeAppendersMutationQueue); activeAppendersMutationQueue = nil;
	dispatch_release(logIndexingGroup); logIndexingGroup = nil;
	dispatch_release(closingIndexGroup); closingIndexGroup = nil;
	dispatch_release(addToSearchKitQueue); addToSearchKitQueue = nil;
	dispatch_release(logAppendingGroup); logAppendingGroup = nil;
	dispatch_release(ioQueue); ioQueue = nil;
	dispatch_release(jobSemaphore); jobSemaphore = nil;
	dispatch_release(loggerPluginGroup); loggerPluginGroup = nil;
}
#pragma mark AILoggerPlugin Plubic Methods
//Paths
+ (NSString *)logBasePath
{
	static dispatch_once_t didResolveLogBaseAlias;
	dispatch_once(&didResolveLogBaseAlias, ^{
		FSRef ref;
		Boolean isDir = true;
		
		OSStatus err = FSPathMakeRef((UInt8 *)[logBasePath UTF8String], &ref, &isDir);
		if (noErr != err) {
			NSLog(@"Warning: Couldn't obtain FSRef for transcripts folder: %s (%ld)", GetMacOSStatusCommentString(err), (long)err);
		} else if (!isDir) {
			Boolean wasAliased_nobodyCares;
			err = FSResolveAliasFile(&ref, /*resolveAliasChains*/ true, &isDir, &wasAliased_nobodyCares);
			if (noErr != err) {
				NSLog(@"Warning: Couldn't resolve alias to transcripts folder: %s (%ld)", GetMacOSStatusCommentString(err), (long)err);
			} else {
				NSURL *logBaseURL = (__bridge_transfer NSURL *)(CFURLCreateFromFSRef(kCFAllocatorDefault, &ref));
				logBaseAliasPath = logBasePath;
				logBasePath = [[logBaseURL path] copy];
			}
		}
	});
	return logBasePath;
}

+ (NSString *)relativePathForLogWithObject:(NSString *)object onAccount:(AIAccount *)account
{
	return [NSString stringWithFormat:@"%@.%@/%@", account.service.serviceID, [account.UID safeFilenameString], object];
}

//Message History
+ (NSArray *)sortedArrayOfLogFilesForChat:(AIChat *)chat
{
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self pathForLogsLikeChat:chat] error:NULL];
	NSMutableArray *dates = [NSMutableArray arrayWithCapacity:files.count];
	for (NSString *path in files) {
		id date = getDateFromPath(path);
		[dates addObject:date ?: [NSNull null]];
	}
	
	NSDictionary *cache = [NSDictionary dictionaryWithObjects:dates forKeys:files];
	
	return (files ? [files sortedArrayUsingFunction:&sortPaths context:(__bridge void *)(cache)] : nil);
}

//Log indexing
- (void)prepareLogContentSearching
{
	__block __typeof__(self) bself = self;
	dispatch_async(defaultDispatchQueue, ^{
		/* Load the index and start indexing to make it current
		 * If we're going to need to re-index all our logs from scratch, it will make
		 * things faster if we start with a fresh log index as well.
		 */
		BOOL reindex = ![[NSFileManager defaultManager] fileExistsAtPath:[bself _dirtyLogSetPath]];
		
		if(reindex)
			[bself _resetLogIndex];
		
		if (!userTriggeredReindex) {
			if (reindex)
				[bself _dirtyAllLogs];
			else
				[bself _cleanDirtyLogs];
		}
	});
}

- (void)cleanUpLogContentSearching
{
	__block __typeof__(self) bself = self;
	
	[self cancelIndexing];
	
	dispatch_group_async(loggerPluginGroup, defaultDispatchQueue, ^{
		[bself _closeLogIndex];
	});
}

- (SKIndexRef)logContentIndex
{
	/* We shouldn't have to lock here except in createLogIndex.  However, a 'window period' exists after an SKIndex has been closed via SKIndexClose()
	 * in which an attempt to load the index from disk returns NULL (presumably because it's still being written-to asynchronously).  We therefore lock
	 * around the full access to make the process reliable.  The documentation says that SKIndex is thread-safe, but that seems to assume that you keep
	 * a single instance of SKIndex open at all times... which is a major memory hit for a large index of a significant number of logs. We only keep the index
	 * open as long as the transcript viewer window is open.
	 */
	[self _cancelClosingLogIndex];
	__block __typeof__(self) bself = self;
    dispatch_sync(searchIndexQueue, ^{
		@autoreleasepool {
			if (!logIndex) {
				SKIndexRef _index = nil;
				NSString  *logIndexPath = [bself _logIndexPath];
				NSURL     *logIndexURL = [NSURL fileURLWithPath:logIndexPath];
				
				if ([[NSFileManager defaultManager] fileExistsAtPath:logIndexPath]) {
					_index = SKIndexOpenWithURL((__bridge CFURLRef)logIndexURL, (CFStringRef)@"Content", true);
					AILogWithSignature(@"Opened index %p from %@",_index,logIndexURL);
					
					if (!_index) {
						//It appears our index was somehow corrupt, since it exists but it could not be opened. Remove it so we can create a new one.
						AILogWithSignature(@"*** Warning: The Chat Transcript searching index at %@ was corrupt. Removing it and starting fresh; transcripts will be re-indexed automatically.",
										   logIndexPath);
						[[NSFileManager defaultManager] removeItemAtPath:logIndexPath error:NULL];
					}
				}
				
				if (!_index) {
					NSDictionary *textAnalysisProperties;
					
					textAnalysisProperties = [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger:0], kSKMaximumTerms,
											  [NSNumber numberWithInteger:2], kSKMinTermLength,
#if ENABLE_PROXIMITY_SEARCH
											  kCFBooleanTrue, kSKProximityIndexing,
#endif
											  nil];
					
					//Create the index if one doesn't exist or it couldn't be opened.
					[[NSFileManager defaultManager] createDirectoryAtPath:[logIndexPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
					
					_index = SKIndexCreateWithURL((__bridge CFURLRef)logIndexURL,
												  (CFStringRef)@"Content",
												  kSKIndexInverted,
												  (__bridge CFDictionaryRef)textAnalysisProperties);
					
					if (_index) {
						AILogWithSignature(@"Created a new log index %p at %@ with textAnalysisProperties %@. Will reindex all logs.",_index,logIndexURL,textAnalysisProperties);
						//Clear the dirty log set in case it was loaded (this can happen if the user mucks with the cache directory)
						[[NSFileManager defaultManager] removeItemAtPath:[bself _dirtyLogSetPath] error:NULL];
						dispatch_sync(dirtyLogSetMutationQueue, ^{
							[bself->dirtyLogSet removeAllObjects];
						});
						[bself _flushIndex:_index];
					} else {
						AILogWithSignature(@"AILoggerPlugin warning: SKIndexCreateWithURL(%@, %@, %lu, %@) returned NULL", logIndexURL, @"Content", (unsigned long)kSKIndexInverted, textAnalysisProperties);
					}
				}
				bself->logIndex = _index;
			}
			if (logIndex) CFRetain(logIndex);
		}
    });
	return logIndex;
}

- (void)markLogDirtyAtPath:(NSString *)path
{
	if (!path) return;
	
	__block __typeof__(self) bself = self;
	dispatch_sync(dirtyLogSetMutationQueue, ^{
		if (path && ![bself.dirtyLogSet containsObject:path]) {
			[bself.dirtyLogSet addObject:path];
		}
	});
}

- (void)cancelIndexing
{
	if (logsToIndex) {
		__block __typeof__(self) bself = self;
		dispatch_group_async(loggerPluginGroup, defaultDispatchQueue, ^{
			bself.indexingAllowed = NO;
			dispatch_group_wait(logIndexingGroup, DISPATCH_TIME_FOREVER);
			bself.logsToIndex = 0;
			bself.indexingAllowed = YES;
			AILogWithSignature(@"Canceling indexing operations.");
		});
	}
}

- (void)removePathsFromIndex:(NSSet *)paths
{
	__block __typeof__(self) bself = self;
	dispatch_group_async(loggerPluginGroup, defaultDispatchQueue, ^{
		@autoreleasepool {
			SKIndexRef logSearchIndex = [bself logContentIndex];
			
			if (!logSearchIndex) {
				AILogWithSignature(@"AILoggerPlugin warning: logSearchIndex is NULL, but we wanted to remove documents.");
				return;
			}
			
			for (NSString *logPath in paths) {
				SKDocumentRef document = SKDocumentCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:logPath]);
				if (document) {
					SKIndexRemoveDocument(logSearchIndex, document);
					CFRelease(document);
				}
			}
			
			CFRelease(logSearchIndex);
		}
	});
}

#pragma mark -
#pragma mark Private Methods
#pragma mark -
#pragma mark Private Functions

NSCalendarDate* getDateFromPath(NSString *path)
{
	NSRange openParenRange, closeParenRange;
	
	if ([path hasSuffix:@".chatlog"] && (openParenRange = [path rangeOfString:@"(" options:NSBackwardsSearch]).location != NSNotFound) {
		openParenRange = NSMakeRange(openParenRange.location, [path length] - openParenRange.location);
		if ((closeParenRange = [path rangeOfString:@")" options:0 range:openParenRange]).location != NSNotFound) {
			//Add and subtract one to remove the parenthesis
			NSString *dateString = [path substringWithRange:NSMakeRange(openParenRange.location + 1, (closeParenRange.location - openParenRange.location))];
			NSCalendarDate *date = [NSCalendarDate calendarDateWithString:dateString timeSeparator:'.'];
			return date;
		}
	}
	return nil;
}

NSComparisonResult sortPaths(NSString *path1, NSString *path2, void *context)
{
	NSDictionary *cache = (__bridge NSDictionary *)context;
	id date1 = [cache objectForKey:path1];
	id date2 = [cache objectForKey:path2];
	NSNull *n = [NSNull null];
	if (date1 == n)
		date1 = nil;
	if (date2 == n)
		date2 = nil;
	
	if(!date1 && !date2)
		return NSOrderedSame;
	else if (date1 && date2)
		return [date2 compare:date1];
	else
		return date2 ? NSOrderedDescending : NSOrderedAscending;
}

#pragma mark Private Class Methods
+ (NSString *)pathForLogsLikeChat:(AIChat *)chat
{
	NSString	*objectUID = chat.name;
	AIAccount	*account = chat.account;
	
	if (!objectUID) objectUID = chat.listObject.UID;
	objectUID = [objectUID safeFilenameString];
	
	return [[self logBasePath] stringByAppendingPathComponent:[self relativePathForLogWithObject:objectUID onAccount:account]];
}

+ (NSString *)fullPathForLogOfChat:(AIChat *)chat onDate:(NSDate *)date
{
	NSString	*objectUID = chat.name;
	AIAccount	*account = chat.account;
	
	if (!objectUID) objectUID = chat.listObject.UID;
	objectUID = [objectUID safeFilenameString];
	
	NSString	*absolutePath = [[self logBasePath] stringByAppendingPathComponent:[self relativePathForLogWithObject:objectUID onAccount:account]];
	
	NSString	*name = [self nameForLogWithObject:objectUID onDate:date];
	NSString	*fullPath = [[absolutePath stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"chatlog"]]
							 stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"xml"]];
	
	return fullPath;
}

+ (NSString *)nameForLogWithObject:(NSString *)object onDate:(NSDate *)date
{
	NSParameterAssert(date != nil);
	NSParameterAssert(object != nil);
	NSString    *dateString = [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil];
	
	NSAssert2(dateString != nil, @"Date string was invalid for the chatlog for %@ on %@", object, date);
	
	return [NSString stringWithFormat:@"%@ (%@)", object, dateString];
}

#pragma mark Private Instace Methods
#pragma mark Installation Methods
- (void)_configureMenuItems
{
	logViewerMenuItem = [[NSMenuItem alloc]
						  initWithTitle:LOG_VIEWER 
						  target:self
						  action:@selector(showLogViewer:)
						  keyEquivalent:@"L"];
	[adium.menuController addMenuItem:logViewerMenuItem
						   toLocation:LOC_Window_Auxiliary];
	
	viewContactLogsMenuItem = [[NSMenuItem alloc]
								initWithTitle:VIEW_LOGS_WITH_CONTACT
								target:self
								action:@selector(showLogViewerToSelectedContact:)
								keyEquivalent:@"l"];
	
	[adium.menuController addMenuItem:viewContactLogsMenuItem
						   toLocation:LOC_Contact_Info];
	
	viewContactLogsContextMenuItem = [[NSMenuItem alloc]
									   initWithTitle:VIEW_LOGS_WITH_CONTACT
									   target:self
									   action:@selector(showLogViewerToSelectedContextContact:) 
									   keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:viewContactLogsContextMenuItem
									 toLocation:Context_Contact_Manage];
	
	viewGroupLogsContextMenuItem = [[NSMenuItem alloc]
									 initWithTitle:VIEW_LOGS_WITH_CONTACT
									 target:self
									 action:@selector(showLogViewerForGroupChat:) 
									 keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:viewGroupLogsContextMenuItem
									 toLocation:Context_GroupChat_Manage];
}

// Enable/Disable our view log menus
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{	
    if (menuItem == viewContactLogsMenuItem) {
        AIListObject *selectedObject = adium.interfaceController.selectedListObject;
		return adium.interfaceController.activeChat || (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]);
    } else if (menuItem == viewContactLogsContextMenuItem) {
        AIListObject *selectedObject = adium.menuController.currentContextMenuObject;
		return !adium.interfaceController.activeChat.isGroupChat || (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]);
    }
	
    return YES;
}

- (void)_initLogIndexing
{
	[self _loadDirtyLogSet];
}

- (void)_upgradeLogExtensions
{
	if (![[adium.preferenceController preferenceForKey:@"Log Extensions Updated" group:PREF_GROUP_LOGGING] boolValue]) {
		/* This could all be a simple NSDirectoryEnumerator call on basePath, but we wouldn't be able to show progress,
		 * and this could take a bit.
		 */
		
		NSMutableSet	*pathsToContactFolders = [NSMutableSet set];
		for (NSString *accountFolderName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[self class] logBasePath] error:NULL]) {
			NSString		*contactBasePath = [logBasePath stringByAppendingPathComponent:accountFolderName];
			
			for (NSString *contactFolderName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contactBasePath error:NULL]) {
				[pathsToContactFolders addObject:[contactBasePath stringByAppendingPathComponent:contactFolderName]];
			}
		}
		
		NSUInteger		contactsToProcess = [pathsToContactFolders count];
		NSUInteger		processed = 0;
		
		if (contactsToProcess) {
			
			AILogFileUpgradeWindowController *upgradeWindowController = [[AILogFileUpgradeWindowController alloc] initWithWindowNibName:@"LogFileUpgrade"];
			[[upgradeWindowController window] makeKeyAndOrderFront:nil];
			
			for (NSString *pathToContactFolder in pathsToContactFolders) {
				for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToContactFolder error:NULL]) {
					if (([[file pathExtension] isEqualToString:@"html"]) ||
						([[file pathExtension] isEqualToString:@"adiumLog"]) ||
						(([[file pathExtension] isEqualToString:@"bak"]) && ([file hasSuffix:@".html.bak"] || 
																			 [file hasSuffix:@".adiumLog.bak"]))) {
						NSString *fullFile = [pathToContactFolder stringByAppendingPathComponent:file];
						NSString *newFile = [[fullFile stringByDeletingPathExtension] stringByAppendingPathExtension:@"AdiumHTMLLog"];
						
						NSError *err;
						[[NSFileManager defaultManager] moveItemAtPath:fullFile
																toPath:newFile
																 error:&err];
						if (err)
							AILogWithSignature(@"%@", [err localizedDescription]);
					}
				}
				
				processed++;
				[upgradeWindowController setProgress:(processed*100.0)/contactsToProcess];
			}
			
			[upgradeWindowController close];
		}
		
		[adium.preferenceController setPreference:[NSNumber numberWithBool:YES]
										   forKey:@"Log Extensions Updated"
											group:PREF_GROUP_LOGGING];
	}
}

- (void)_upgradeLogPermissions
{
	if ([[adium.preferenceController preferenceForKey:@"Log Permissions Updated" group:PREF_GROUP_LOGGING] boolValue])
		return;
	
	/* This is based off of -upgradeLogExtensions. Refer to that. */
	NSMutableSet	*pathsToContactFolders = [NSMutableSet set];
	for (NSString *accountFolderName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[self class] logBasePath] error:NULL]) {
		//??? isn't this just going to be the same as accountFolderName?
		NSString		*contactBasePath = [[[self class] logBasePath] stringByAppendingPathComponent:accountFolderName];
		
		// Set permissions to prohibit access from other users
		[[NSFileManager defaultManager] setAttributes:
		 [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0700UL]
									 forKey:NSFilePosixPermissions]
										 ofItemAtPath:contactBasePath
												error:NULL];
		
		for (NSString *contactFolderName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contactBasePath error:NULL]) {
			NSString	*contactFolderPath = [contactBasePath stringByAppendingPathComponent:contactFolderName];
			
			// Set permissions to prohibit access from other users
			[[NSFileManager defaultManager] setAttributes:
			 [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0700UL]
										 forKey:NSFilePosixPermissions]
											 ofItemAtPath:contactFolderPath
													error:NULL];
			
			// We'll traverse the contact directories themselves next
			[pathsToContactFolders addObject:contactFolderPath];
		}
	}
	
	NSUInteger		contactsToProcess = [pathsToContactFolders count];
	NSUInteger		processed = 0;
	
	if (contactsToProcess) {		
		AILogFileUpgradeWindowController *upgradeWindowController = [[AILogFileUpgradeWindowController alloc] initWithWindowNibName:@"LogFileUpgrade"];
		[[upgradeWindowController window] makeKeyAndOrderFront:nil];
		
		for (NSString *pathToContactFolder in pathsToContactFolders) {			
			for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToContactFolder error:NULL]) {
				NSString	*fullFile = [pathToContactFolder stringByAppendingPathComponent:file];
				BOOL		isDir;
				
				// Some chat logs are bundles
				[[NSFileManager defaultManager] fileExistsAtPath:fullFile isDirectory:&isDir];
				
				if (!isDir) {
					[[NSFileManager defaultManager] setAttributes:
					 [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0600UL]
												 forKey:NSFilePosixPermissions]
													 ofItemAtPath:fullFile
															error:NULL];
					
				} else {
					[[NSFileManager defaultManager] setAttributes:
					 [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0700UL]
												 forKey:NSFilePosixPermissions] 
													 ofItemAtPath:fullFile 
															error:NULL];
					
					// We have to enumerate this directory, too, only not as deep					
					for (NSString *contentFile in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullFile error:NULL]) {
						[[NSFileManager defaultManager] setAttributes:
						 [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0600UL]
													 forKey:NSFilePosixPermissions]
														 ofItemAtPath:contentFile
																error:NULL];
					}
					
				}
				
			}
			
			processed++;
			[upgradeWindowController setProgress:(processed*100.0)/contactsToProcess];
		}
		
		[upgradeWindowController close];
	}
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:YES]
									   forKey:@"Log Permissions Updated"
										group:PREF_GROUP_LOGGING];
}

/*!
 * @brief Instruct spotlight to reimport logs
 *
 * Adium 1.0.2 and earlier had a bug which made spotlight import not work properly.
 * New logs are properly indexed, but previously created logs are not. On first launch of Adium 1.1,
 * Adium will tell Spotlight to reimport those old logs.
 *
 * We also reindex in Adium 1.3.3 to help capture logs in Mac OS X 10.5.6 which indexes logs in our default location.
 */
- (void)_reimportLogsToSpotlightIfNeeded
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"Adium 1.3.3:Reimported Spotlight Logs"]) {
		@try {
			NSArray *arguments;
			
			arguments = [NSArray arrayWithObjects:
						 @"-r",
						 [[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Library"]
						   stringByAppendingPathComponent:@"Spotlight"] stringByAppendingPathComponent:[@"AdiumSpotlightImporter" stringByAppendingPathExtension:@"mdimporter"]],
						 nil];
			[NSTask launchedTaskWithLaunchPath:@"/usr/bin/mdimport"	arguments:arguments];
		}
		@catch (NSException *e) {
			NSLog(@"Exception caught while reimporting Spotlight logs: %@", e);
		}
		
		[[NSUserDefaults standardUserDefaults] setBool:YES
												forKey:@"Adium 1.3.3:Reimported Spotlight Logs"];
	}
}

#pragma mark KeyValueObserving
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	BOOL	newLogValue;
	self.logHTML = YES;
	
	//Start/Stop logging
	newLogValue = [[object valueForKeyPath:keyPath] boolValue];
	if (newLogValue != self.loggingEnabled) {
		self.loggingEnabled = newLogValue;
		
		if (!self.loggingEnabled) { //Stop Logging
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];
			
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_DidOpen object:nil];			
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_WillClose object:nil];
			
		} else { //Start Logging
			[[NSNotificationCenter defaultCenter] addObserver:self 
													 selector:@selector(contentObjectAdded:) 
														 name:Content_ContentObjectAdded 
													   object:nil];
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(chatOpened:)
														 name:Chat_DidOpen
													   object:nil];
			
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(chatClosed:)
														 name:Chat_WillClose
													   object:nil];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(chatWillDelete:)
														 name:ChatLog_WillDelete
													   object:nil];
		}
	}
}

#pragma mark Action Methods
/*!
 * @brief Show the log viewer for no contact
 *
 * Invoked from the Window menu
 */
- (void)showLogViewer:(id)sender
{
	[AILogViewerWindowController openForContact:nil  
										 plugin:self];
}

/*!
 * @brief Show the log viewer, displaying only the selected contact's logs
 *
 * Invoked from the Contact menu
 */
- (void)showLogViewerToSelectedContact:(id)sender
{
	BOOL openForSelectedObject = YES;
	
	if (sender == viewContactLogsMenuItem) {
		AIChat *activeChat = adium.interfaceController.activeChat;
		
		if (activeChat.isGroupChat) {
			[AILogViewerWindowController openForChatName:activeChat.name withAccount:activeChat.account plugin:self];
			openForSelectedObject = NO;
		}
	}
	
	if (openForSelectedObject) {
		AIListObject   *selectedObject = adium.interfaceController.selectedListObject;
		
		if ([selectedObject isKindOfClass:[AIListBookmark class]]) {
			[AILogViewerWindowController openForChatName:((AIListBookmark *)selectedObject).name
											 withAccount:((AIListBookmark *)selectedObject).account
												  plugin:self];
		} else {
			[AILogViewerWindowController openForContact:([selectedObject isKindOfClass:[AIListContact class]] ?
														 (AIListContact *)selectedObject : 
														 nil)  
												 plugin:self];
		}
	}
}

/*!
 * @brief Show the log viewer, displaying only the selected contact's logs
 *
 * Invoked from a contextual menu
 */
- (void)showLogViewerToSelectedContextContact:(id)sender
{
	AIListObject* object = adium.menuController.currentContextMenuObject;
	
	AILogViewerWindowController *windowController = nil;
	
	if ([object isKindOfClass:[AIListBookmark class]]) {
		windowController = [AILogViewerWindowController openForChatName:((AIListBookmark *)object).name
															withAccount:((AIListBookmark *)object).account
																 plugin:self];
		
	} else if ([object isKindOfClass:[AIListContact class]]) {
		windowController = [AILogViewerWindowController openForContact:(AIListContact *)object plugin:self];
	}
	
	if (windowController) {
		[NSApp activateIgnoringOtherApps:YES];
		[[windowController window] makeKeyAndOrderFront:nil];
	}
}

/*!
 * @brief Show the log viewer for the active chat
 *
 * This is called when a chat is definitely in focus, i.e. the toolbar item.
 */
- (void)showLogViewerForActiveChat:(id)sender
{
	AIChat *activeChat = adium.interfaceController.activeChat;
	
	if(activeChat.isGroupChat) {
		[AILogViewerWindowController openForChatName:activeChat.name
										 withAccount:activeChat.account plugin:self];
	} else {
		[AILogViewerWindowController openForContact:activeChat.listObject
											 plugin:self];
	}
}

/*!
 * @brief Show the log viewer with the menu context chat
 *
 * Opens the log window for a specific AIChat which the context menu is currently referencing.
 * This is called by the group chat's context menu to open its logs.
 */
- (void)showLogViewerForGroupChat:(id)sender
{
	AIChat *contextChat = adium.menuController.currentContextMenuChat;
	
	[NSApp activateIgnoringOtherApps:YES];
	
	[AILogViewerWindowController openForChatName:contextChat.name
									 withAccount:contextChat.account
										  plugin:self];
}

- (void)showLogViewerAndReindex:(id)sender
{
	userTriggeredReindex = YES;
	[self showLogViewer:nil];
	[self _dirtyAllLogs];
	userTriggeredReindex = NO;
}

- (void)showLogNotification:(NSNotification *)inNotification
{
	[self _showLogViewerForLogAtPath:[inNotification object]];
}

- (void)_showLogViewerForLogAtPath:(NSString *)inPath
{
	[AILogViewerWindowController openLogAtPath:inPath plugin:self];
}

#pragma mark Logging
//Log any content that is sent or received
- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentMessage 	*content = [[notification userInfo] objectForKey:@"AIContentObject"];
	if ([content postProcessContent]) {
		AIChat				*chat = [notification object];
		
		if (![chat shouldLog]) return;	
		
		__block __typeof__(self) bself = self;
		dispatch_group_async(logAppendingGroup, dispatch_get_main_queue(), ^{
			@autoreleasepool {
				BOOL			dirty = NO;
				NSString		*contentType = [content type];
				NSString		*date = [[[content date] dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString];
				
				if ([contentType isEqualToString:CONTENT_MESSAGE_TYPE] ||
					[contentType isEqualToString:CONTENT_CONTEXT_TYPE]) {
					NSMutableArray *attributeKeys = [NSMutableArray arrayWithObjects:@"sender", @"time", nil];
					NSMutableArray *attributeValues = [NSMutableArray arrayWithObjects:[[content source] UID], date, nil];
					AIXMLAppender  *appender = [self _appenderForChat:chat];
					if ([content isAutoreply]) {
						[attributeKeys addObject:@"auto"];
						[attributeValues addObject:@"true"];
					}
					
					NSString *displayName;
					if (chat.isGroupChat)
						displayName = [(AIGroupChat *)chat displayNameForContact:content.source];
					else
						displayName = content.source.displayName;
					
					if (![[[content source] UID] isEqualToString:displayName]) {
						[attributeKeys addObject:@"alias"];
						[attributeValues addObject:displayName];
					}
					
					AIXMLElement *messageElement;
					if ([[content displayClasses] containsObject:@"action"]) {
						messageElement = [[AIXMLElement alloc] initWithName:@"action"];
					} else {
						messageElement = [[AIXMLElement alloc] initWithName:@"message"];
					}
					
					[messageElement addEscapedObject:[xhtmlDecoder encodeHTML:[content message]
																   imagesPath:[appender.path stringByDeletingLastPathComponent]]];
					
					[messageElement setAttributeNames:attributeKeys values:attributeValues];
					
					[appender appendElement:messageElement];
					
					dirty = YES;
				} else {
					//XXX: Yucky hack. This is here because we get status and event updates for metas, not for individual contacts. Or something like that.
					AIListObject	*retardedMetaObject = [content source];
					AIListObject	*actualObject = nil;
					
					if (content.source) {
						for(AIListContact *participatingListObject in chat) {
							if ([participatingListObject parentContact] == retardedMetaObject) {
								actualObject = participatingListObject;
								break;
							}
						}
					}
					
					//If we can't find it for some reason, we probably shouldn't attempt logging, unless source was nil.
					if ([contentType isEqualToString:CONTENT_STATUS_TYPE] && actualObject) {
						NSString *translatedStatus = [statusTranslation objectForKey:[(AIContentStatus *)content status]];
						if (translatedStatus == nil) {
							AILogWithSignature(@"AILogger: Don't know how to translate status: %@", [(AIContentStatus *)content status]);
						} else {
							NSMutableArray *attributeKeys = [NSMutableArray arrayWithObjects:@"type", @"sender", @"time", nil];
							NSMutableArray *attributeValues = [NSMutableArray arrayWithObjects:
															   translatedStatus,
															   actualObject.UID,
															   date,
															   nil];
							
							if (![actualObject.UID isEqualToString:actualObject.displayName]) {
								[attributeKeys addObject:@"alias"];
								[attributeValues addObject:actualObject.displayName];
							}
							
							AIXMLElement *statusElement = [[AIXMLElement alloc] initWithName:@"status"];
							
							[statusElement addEscapedObject:([(AIContentStatus *)content loggedMessage] ?
															 [xhtmlDecoder encodeHTML:[(AIContentStatus *)content loggedMessage] imagesPath:nil] :
															 @"")];
							
							[statusElement setAttributeNames:attributeKeys values:attributeValues];
							
							[[bself _appenderForChat:chat] appendElement:statusElement];
							
							dirty = YES;
						}
						
					} else if ([contentType isEqualToString:CONTENT_EVENT_TYPE] ||
							   [contentType isEqualToString:CONTENT_NOTIFICATION_TYPE]) {
						NSMutableArray *attributeKeys = nil, *attributeValues = nil;
						if (content.source) {
							attributeKeys = [NSMutableArray arrayWithObjects:@"type", @"sender", @"time", nil];
							attributeValues = [NSMutableArray arrayWithObjects:
											   [(AIContentEvent *)content eventType], [[content source] UID], date, nil];
						} else {
							attributeKeys = [NSMutableArray arrayWithObjects:@"type", @"time", nil];
							attributeValues = [NSMutableArray arrayWithObjects:
											   [(AIContentEvent *)content eventType], date, nil];
						}
						
						AIXMLAppender  *appender = [self _appenderForChat:chat];
						
						if (content.source && ![[[content source] UID] isEqualToString:[[content source] displayName]]) {
							[attributeKeys addObject:@"alias"];
							[attributeValues addObject:[[content source] displayName]];
						}
						
						AIXMLElement *statusElement = [[AIXMLElement alloc] initWithName:@"status"];
						
						[statusElement addEscapedObject:[xhtmlDecoder encodeHTML:[content message]
																	  imagesPath:[[appender path] stringByDeletingLastPathComponent]]];
						
						[statusElement setAttributeNames:attributeKeys values:attributeValues];
						
						[appender appendElement:statusElement];
						dirty = YES;
					}
				}
				//Don't create a new one if not needed
				AIXMLAppender *appender = [self _existingAppenderForChat:chat];
				if (dirty && appender)
					[bself _markLogDirtyAtPath:[appender path] forChat:chat];
			}
		});
	}
}

- (void)chatOpened:(NSNotification *)notification
{
	AIChat	*chat = [notification object];
	
	if (![chat shouldLog]) return;	
	
	//Try reusing the appender object
	AIXMLAppender *appender = [self _existingAppenderForChat:chat];
	
	//If there is an appender, add the windowOpened event
	if (appender) {
		/* Ensure a timeout isn't set for closing the appender, since we're now using it.
		 * This gives us the desired behavior - if chat #2 opens before the timeout on the
		 * log file, then we want to keep the log continuous until the user has closed the
		 * window. 
		 */
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(finishClosingAppender:) 
												   object:[self keyForChat:chat]];
		
		// Print the windowOpened event in the log
		AIXMLElement *eventElement = [[AIXMLElement alloc] initWithName:@"event"];
		
		[eventElement setAttributeNames:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
								 values:[NSArray arrayWithObjects:@"windowOpened", chat.account.UID, [[[NSDate date] dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString], nil]];
		
		[appender appendElement:eventElement];
		
		[self _markLogDirtyAtPath:[appender path] forChat:chat];
	}
}

- (void)chatClosed:(NSNotification *)notification
{
	AIChat	*chat = [notification object];
	
	if (![chat shouldLog]) return;	
	
	//Use this method so we don't create a new appender for chat close events
	AIXMLAppender *appender = [self _existingAppenderForChat:chat];
	
	//If there is an appender, add the windowClose event
	if (appender) {
		AIXMLElement *eventElement = [[AIXMLElement alloc] initWithName:@"event"];
		
		[eventElement setAttributeNames:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
								 values:[NSArray arrayWithObjects:@"windowClosed", chat.account.UID, [[[NSDate date] dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString], nil]];
		
		
		[appender appendElement:eventElement];
		[self closeAppenderForChat:chat];
		
		[self _markLogDirtyAtPath:[appender path] forChat:chat];
	}
}

//Ugly method. Shouldn't this notification post an AIChat, not an AIChatLog?
- (void)chatWillDelete:(NSNotification *)notification
{
	AIChatLog *chatLog = [notification object];
	NSString *chatID = [NSString stringWithFormat:@"%@.%@-%@", [chatLog serviceClass], [chatLog from], [chatLog to]];
	AIXMLAppender *appender = [activeAppenders objectForKey:chatID];
	
	if (appender) {
		if ([[appender path] hasSuffix:[chatLog relativePath]]) {
			[NSObject cancelPreviousPerformRequestsWithTarget:self
													 selector:@selector(finishClosingAppender:) 
													   object:chatID];
			[self finishClosingAppender:chatID];
		}
	}
}

#pragma mark Logging Internals
- (AIXMLAppender *)_appenderForChat:(AIChat *)chat
{
	//Check if there is already an appender for this chat
	AIXMLAppender	*appender = [self _existingAppenderForChat:chat];
	
	if (appender) {
		//Ensure a timeout isn't set for closing the appender, since we're now using it
		[NSObject cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(finishClosingAppender:) 
												   object:[self keyForChat:chat]];
	} else {
		//If there isn't already an appender, create a new one and add it to the dictionary
		NSDate			*chatDate = [chat dateOpened];
		NSString		*fullPath = [AILoggerPlugin fullPathForLogOfChat:chat onDate:chatDate];
		
		AIXMLElement *rootElement = [[AIXMLElement alloc] initWithName:@"chat"];
		
		[rootElement setAttributeNames:[NSArray arrayWithObjects:@"xmlns", @"account", @"service", @"adiumversion", @"buildid", nil]
								values:[NSArray arrayWithObjects:
										XML_LOGGING_NAMESPACE,
										chat.account.UID,
										chat.account.service.serviceID,
										[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
										[[NSBundle mainBundle] objectForInfoDictionaryKey:@"AIBuildIdentifier"],
										nil]];
		
		appender = [AIXMLAppender documentWithPath:fullPath rootElement:rootElement];
		
		//Add the window opened event now
		AIXMLElement *eventElement = [[AIXMLElement alloc] initWithName:@"event"];
		
		[eventElement setAttributeNames:[NSArray arrayWithObjects:@"type", @"sender", @"time", nil]
								 values:[NSArray arrayWithObjects:@"windowOpened", chat.account.UID, [[[NSDate date] dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString], nil]];
		
		[appender appendElement:eventElement];
		
		[activeAppenders setObject:appender forKey:[self keyForChat:chat]];
		
		[self _markLogDirtyAtPath:[appender path] forChat:chat];
	}
	
	return appender;
}

- (AIXMLAppender *)_existingAppenderForChat:(AIChat *)chat
{
	//Look up the key for this chat and use it to try to retrieve the appender
	return [activeAppenders objectForKey:[self keyForChat:chat]];	
}

- (NSString *)keyForChat:(AIChat *)chat
{
	AIAccount *account = chat.account;
	NSString *chatID = (chat.isGroupChat ? [chat identifier] : chat.listObject.UID);
	
	return [NSString stringWithFormat:@"%@.%@-%@", account.service.serviceID, account.UID, chatID];
}

- (void)closeAppenderForChat:(AIChat *)chat
{
	//Create a new timer to fire after the timeout period, which will close the appender
	NSString *chatKey = [self keyForChat:chat];
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(finishClosingAppender:) 
											   object:chatKey];
	[self performSelector:@selector(finishClosingAppender:) 
			   withObject:chatKey
			   afterDelay:NEW_LOGFILE_TIMEOUT];
}

- (void)finishClosingAppender:(NSString *)chatKey
{
	//Remove the appender, closing its file descriptor upon dealloc
	[activeAppenders removeObjectForKey:chatKey];
}

#pragma mark Log Indexing
- (NSString *)_logIndexPath
{
	return [[adium cachesPath] stringByAppendingPathComponent:LOG_INDEX_NAME];
}

- (NSString *)_dirtyLogSetPath
{
	return [[adium cachesPath] stringByAppendingPathComponent:DIRTY_LOG_SET_NAME];
}

- (void)_loadDirtyLogSet
{
	if ([self.dirtyLogSet count] == 0) {
		NSInteger logVersion = [[adium.preferenceController
								 preferenceForKey:KEY_LOG_INDEX_VERSION
								 group:PREF_GROUP_LOGGING] integerValue];
		
		//If the log version has changed, we reset the index and don't load the dirty set (So all the logs are marked dirty)
		if (logVersion >= CURRENT_LOG_VERSION) {
			__block __typeof__(self) bself = self;
			dispatch_sync(dirtyLogSetMutationQueue, ^{
				[bself.dirtyLogSet addObjectsFromArray:[NSArray arrayWithContentsOfFile:[bself _dirtyLogSetPath]]];
				AILogWithSignature(@"Loaded dirty log set with %li logs",[bself.dirtyLogSet count]);
			});      
		} else {
			AILogWithSignature(@"**** Log version upgrade. Resetting");
			[self _resetLogIndex];
			[adium.preferenceController setPreference:[NSNumber numberWithInteger:CURRENT_LOG_VERSION]
											   forKey:KEY_LOG_INDEX_VERSION
												group:PREF_GROUP_LOGGING];
		}
	}
}

- (void)_resetLogIndex
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self _logIndexPath]]) {
		[[NSFileManager defaultManager] removeItemAtPath:[self _logIndexPath] error:NULL];
	}	
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self _dirtyLogSetPath]]) {
		[[NSFileManager defaultManager] removeItemAtPath:[self _dirtyLogSetPath] error:NULL];
	}
}

- (void)_cancelClosingLogIndex
{
	__block __typeof__(self) bself = self;
	dispatch_async(defaultDispatchQueue, ^{
		bself.canCloseIndex = NO;
		dispatch_group_wait(closingIndexGroup, DISPATCH_TIME_FOREVER);
		bself.canCloseIndex = YES;
	});
}

- (void)_dirtyAllLogs
{	
	__block __typeof__(self) bself = self;
	dispatch_sync(dirtyLogSetMutationQueue, ^{
		[bself.dirtyLogSet removeAllObjects];
	});
	dispatch_group_async(loggerPluginGroup, defaultDispatchQueue, ^{
		@autoreleasepool {
			dispatch_group_wait(logIndexingGroup, DISPATCH_TIME_FOREVER);
			dispatch_group_wait(closingIndexGroup, DISPATCH_TIME_FOREVER);
			dispatch_group_wait(logAppendingGroup, DISPATCH_TIME_FOREVER);
			
			bself.canSaveDirtyLogSet = NO;
			
			//Process each from folder
			NSString *_logBasePath = [[bself class] logBasePath];
			NSArray *fromNames = [[NSFileManager defaultManager]
								  contentsOfDirectoryAtPath:_logBasePath
								  error:NULL];
			for (NSString *fromName in fromNames) {
				AILogFromGroup *fromGroup = [[AILogFromGroup alloc] initWithPath:fromName
																		 fromUID:fromName
																	serviceClass:nil];
				for (AILogToGroup *toGroup in [fromGroup toGroupArray]) {
					@autoreleasepool {
						for (AIChatLog *theLog in [toGroup logEnumerator]) {
							if (theLog != nil) {
								dispatch_sync(dirtyLogSetMutationQueue, ^{
									[bself.dirtyLogSet addObject:[_logBasePath stringByAppendingPathComponent:[theLog relativePath]]];
								});
							}
						}
					}
				}
			}
			AILogWithSignature(@"Finished dirtying all logs");
			
			bself.canSaveDirtyLogSet = YES;
			[bself _saveDirtyLogSet];
			
			if (bself.indexingAllowed &&
				[AILogViewerWindowController existingWindowController]) {
				[bself _cleanDirtyLogs];
			}
		}
	});
}

/*!
 * @brief Index all dirty logs
 *
 * Indexing will occur on a thread
 */
- (void)_cleanDirtyLogs
{
	__block SInt64 _remainingLogs = 0;
	//Do nothing if we're paused
	if (!self.indexingAllowed) return;
	
	//Reset the cleaning progress
	__block __typeof__(self) bself = self;
	__block NSMutableSet *localLogSet = nil;
	
	dispatch_sync(dirtyLogSetMutationQueue, ^{
		localLogSet = [self.dirtyLogSet mutableCopy];
		OSAtomicCompareAndSwap64Barrier(bself->logsToIndex, [localLogSet count], (int64_t *)&(bself->logsToIndex));
		OSAtomicCompareAndSwap64Barrier(_remainingLogs, bself->logsToIndex, (int64_t *)&_remainingLogs);
	});
	
	if (self.logsToIndex == 0){
		dispatch_async(defaultDispatchQueue, ^{
			OSAtomicCompareAndSwap64Barrier(logsIndexed, 0, (int64_t*)&logsIndexed);
			[bself _didCleanDirtyLogs];
		});
		return;
	}
	
	__block SKIndexRef searchIndex = [self logContentIndex];
	
	if (!searchIndex) {
		AILogWithSignature(@"*** Warning: Could not open searchIndex in -[%@ _cleanDirtyLogs]. That shouldn't happen!", self);
		return;
	}
	
	OSAtomicCompareAndSwap64Barrier(logsIndexed, 0, (int64_t*)&logsIndexed);
	
	if (self.indexingAllowed) {
		
		self.isIndexing = YES;
		__block UInt32  lastUpdate = TickCount();
		__block SInt32  unsavedChanges = 0;
		
		AILogWithSignature(@"Cleaning %li dirty logs", [localLogSet count]);
		
		dispatch_group_async(loggerPluginGroup, searchIndexQueue, ^{
			@autoreleasepool {
				
				dispatch_group_enter(logIndexingGroup);
				
				while (_remainingLogs > 0 && bself.indexingAllowed) {
					@autoreleasepool {
						__block NSString *__logPath = nil;
						NSString  *logPath = nil;
						
						dispatch_sync(dirtyLogSetMutationQueue, ^{
							if ([localLogSet count]) {
								__logPath = [localLogSet anyObject];
								[bself.dirtyLogSet removeObject:__logPath];
								[localLogSet removeObject:__logPath];
							}
						});
						
						logPath = [__logPath copy];
						
						if (logPath) {
							NSURL *logURL = [NSURL fileURLWithPath:logPath];
							
							NSAssert(logURL != nil, @"Converting path to url failed");
							
							dispatch_semaphore_wait(logLoadingPrefetchSemaphore, DISPATCH_TIME_FOREVER);
							
							dispatch_group_async(logIndexingGroup, ioQueue, ^{
								@autoreleasepool {
									CFRetain(searchIndex);
									__block SKDocumentRef document = SKDocumentCreateWithURL((__bridge CFURLRef)logURL);
									
									if (document && bself.indexingAllowed) {
										/* We _could_ use SKIndexAddDocument() and depend on our Spotlight plugin for importing.
										 * However, this has three problems:
										 *	1. Slower, especially to start initial indexing, which is the most common use case since the log viewer
										 *	   indexes recently-modified ("dirty") logs when it opens.
										 *  2. Sometimes logs don't appear to be associated with the right URI type and therefore don't get indexed.
										 *  3. On 10.3, this means that logs' markup is indexed in addition to their text, which is undesireable.
										 */
										
										NSData *documentData = CopyDataForURL(NULL, logURL);
										
										dispatch_semaphore_wait(jobSemaphore, DISPATCH_TIME_FOREVER);
										
										dispatch_group_async(logIndexingGroup, defaultDispatchQueue, ^{
											@autoreleasepool {
												__block CFStringRef documentText = CopyTextContentForFileData(NULL, logURL, documentData);
												
												dispatch_group_async(logIndexingGroup, defaultDispatchQueue, ^{
													@autoreleasepool {
														
														CFRetain(searchIndex);
														
														if (documentText && CFStringGetLength(documentText) > 0 && bself.indexingAllowed) {
															static dispatch_queue_t skQueue = nil;
															static dispatch_once_t onceToken;
															dispatch_once(&onceToken, ^{
																skQueue = dispatch_queue_create("im.adium.AILoggerPlugin._cleanDirtyLogs.skQueue", 0);
															});
															
															CFRetain(searchIndex);
															CFRetain(document);
															CFRetain(documentText);
															
															dispatch_group_async(logIndexingGroup, skQueue, ^{
																SKIndexAddDocumentWithText(searchIndex, document, documentText, YES);
																
																OSAtomicIncrement64Barrier((int64_t *)&(bself->logsIndexed));
																OSAtomicDecrement64Barrier((int64_t *)&_remainingLogs);
																
																if (lastUpdate == 0 || TickCount() > lastUpdate + LOG_INDEX_STATUS_INTERVAL || _remainingLogs == 0) {
																	dispatch_async(dispatch_get_main_queue(), ^{
																		[[AILogViewerWindowController existingWindowController] logIndexingProgressUpdate];
																	});
																	UInt32 tick = TickCount();
																	OSAtomicCompareAndSwap32Barrier(lastUpdate, tick, (int32_t *)&lastUpdate);
																}
																
																OSAtomicIncrement32Barrier((int32_t *)&unsavedChanges);
																
																if (unsavedChanges > LOG_CLEAN_SAVE_INTERVAL) {
																	[bself _saveDirtyLogSet];
																	OSAtomicCompareAndSwap32Barrier(unsavedChanges, 0, (int32_t *)&unsavedChanges);
																}
																
																dispatch_semaphore_signal(jobSemaphore);
																
																CFRelease(searchIndex);
																CFRelease(document);
																CFRelease(documentText);
															});
															CFRelease(documentText);
														} else if (documentText) {
															CFRelease(documentText);
															
															dispatch_semaphore_signal(jobSemaphore);
														} else {
															OSAtomicIncrement64Barrier((int64_t *)&(bself->logsIndexed));
															OSAtomicDecrement64Barrier((int64_t *)&_remainingLogs);
															
															dispatch_semaphore_signal(jobSemaphore);
														}
														
														
														dispatch_semaphore_signal(logLoadingPrefetchSemaphore);
														
														CFRelease(document);
														CFRelease(searchIndex);
													}
												});
											}
										});
									} else {
										if (document) {
											CFRelease(document);
										} else {
											AILogWithSignature(@"Could not create document for %@ [%@]", logPath, logURL);
										}
										
										OSAtomicIncrement64Barrier((int64_t *)&(bself->logsIndexed));
										OSAtomicDecrement64Barrier((int64_t *)&_remainingLogs);
										
										dispatch_semaphore_signal(jobSemaphore);
										dispatch_semaphore_signal(logLoadingPrefetchSemaphore);
									}
									CFRelease(searchIndex);
								}
							});
						} else {
							break;
						}
					}
				}
				
				if (unsavedChanges) {
					[bself _saveDirtyLogSet];
				}
				
				dispatch_group_enter(closingIndexGroup);
				dispatch_group_leave(logIndexingGroup);
				
				dispatch_group_notify(logIndexingGroup, searchIndexQueue, ^{
					dispatch_async(dispatch_get_main_queue(), ^{
						[[AILogViewerWindowController existingWindowController] logIndexingProgressUpdate];
					});
					
					[bself _flushIndex:searchIndex];
					
					AILogWithSignature(@"After cleaning dirty logs, the search index has a max ID of %li and a count of %li",
									   SKIndexGetMaximumDocumentID(searchIndex),
									   SKIndexGetDocumentCount(searchIndex));
					
					CFRelease(searchIndex);
					
					[bself _didCleanDirtyLogs];
				});
				dispatch_group_leave(closingIndexGroup);
			}
		});
	} else {
		CFRelease(searchIndex);
	}
}

#pragma mark Log Indexing Internals
- (void)_didCleanDirtyLogs
{
	NSLog(@"_didCleanDirtyLogs");
	__block __typeof__(self) bself = self;
	dispatch_sync(dirtyLogSetMutationQueue, ^{
		OSAtomicCompareAndSwap64Barrier(bself->logsToIndex, [bself->dirtyLogSet count], (int64_t *)&(bself->logsToIndex));
	});
	
	self.isIndexing = NO;
	dispatch_async(dispatch_get_main_queue(), ^{
		[[AILogViewerWindowController existingWindowController] logIndexingProgressUpdate];
	});
}

- (void)_saveDirtyLogSet
{
	__block __typeof__(self) bself = self;
	dispatch_group_async(loggerPluginGroup, dirtyLogSetMutationQueue, ^{
		NSSet *_dirtySet = [bself.dirtyLogSet copy];
		AILogWithSignature(@"Saving %lu dirty logs", _dirtySet.count);
		if ([_dirtySet count] > 0 && bself.canSaveDirtyLogSet) {
			dispatch_async(ioQueue, ^{
				[[_dirtySet allObjects] writeToFile:[bself _dirtyLogSetPath]
										 atomically:NO];
			});
		}
	});
}

- (void)_markLogDirtyAtPath:(NSString *)path forChat:(AIChat *)chat
{
	NSParameterAssert(path != nil);
	NSParameterAssert(chat != nil);
	__block __typeof__(self) bself = self;
	dispatch_async(defaultDispatchQueue, ^{
		dispatch_async(dirtyLogSetMutationQueue, ^{
			if (path && ![bself.dirtyLogSet containsObject:path]) {
				[bself.dirtyLogSet addObject:path];
				dispatch_group_async(loggerPluginGroup, defaultDispatchQueue, ^{
					@autoreleasepool {
						[bself _saveDirtyLogSet];
					}
				});
			}
		});
	});
}

#pragma mark Cleanup
- (void)_closeLogIndex
{
	__block __typeof__(self) bself = self;
	dispatch_group_wait(logIndexingGroup, DISPATCH_TIME_FOREVER);
	dispatch_group_async(closingIndexGroup, searchIndexQueue, ^{
		if (bself->logIndex) {
			[bself _flushIndex:bself->logIndex];
			if (bself.canCloseIndex) {
                AILogWithSignature(@"**** %@ Releasing its index %p (%ld)", bself, bself->logIndex, CFGetRetainCount(bself->logIndex));
				SKIndexClose(bself->logIndex);
				bself->logIndex = nil;
			}
		}
	});
}

- (void)_flushIndex:(SKIndexRef)inIndex
{
	@autoreleasepool {
		if (inIndex) {
			self.indexIsFlushing = YES;
			AILogWithSignature(@"**** Flushing index %p",inIndex);
			CFRetain(inIndex);
			SKIndexFlush(inIndex);
			SKIndexCompact(inIndex);
			CFRelease(inIndex);
			AILogWithSignature(@"**** Finished flushing index %p",inIndex);
			self.indexIsFlushing = NO;
		}
	}
}

@end
