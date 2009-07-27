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


#define PATH_LOGS                       @"/Logs"
#define LOGGING_DEFAULT_PREFS           @"LoggingDefaults"

#define PREF_GROUP_LOGGING              @"Logging"
#define KEY_LOGGER_ENABLE               @"Enable Logging"

#define PREF_KEYPATH_LOGGER_ENABLE		PREF_GROUP_LOGGING @"." KEY_LOGGER_ENABLE

#define XML_LOGGING_NAMESPACE		@"http://purl.org/net/ulf/ns/0.4-02"

@class AIAccount, AIHTMLDecoder, AIChat, AILoggerPreferences;

@interface AILoggerPlugin : AIPlugin {
    AILoggerPreferences                 *preferences;
    
    //Current logging settings
    BOOL				observingContent;
    BOOL				logHTML;

	NSMutableDictionary					*activeAppenders;
	NSMutableDictionary					*appenderCloseTimers;
	
	AIHTMLDecoder						*xhtmlDecoder;
	NSDictionary						*statusTranslation;
	
    //Log viewer menu items
    NSMenuItem                          *logViewerMenuItem;
    NSMenuItem                          *viewContactLogsMenuItem;
    NSMenuItem                          *viewContactLogsContextMenuItem;
	NSMenuItem							*viewGroupLogsContextMenuItem;

    //Log content search index
	BOOL				logIndexingEnabled; //Does this system use log indexing?
    SKIndexRef			index_Content;	

    //Dirty all information (First build of the dirty cache)
    BOOL				stopIndexingThreads;    //Set to YES to abort a dirty all or clean
    BOOL				suspendDirtyArraySave;  //YES to prevent saving of the dirty index	
	BOOL				isFlushingIndex;
    NSLock				*indexingThreadLock;	//Locked by the plugin when a dirty all or clean thread is running

	//Locked by the plugin while the index is being modified
	NSConditionLock		*logWritingLock;
	//Locked by the plugin while the index is being closed
    NSConditionLock		*logClosingLock;
	
    //Array of dirty logs / Logs that need re-indexing.  (Locked access)
    NSMutableArray		*dirtyLogArray;
    NSLock				*dirtyLogLock;
    
    //Indexing progress
    NSInteger					logsToIndex;
    NSInteger					logsIndexed;
	NSInteger					logIndexingPauses;
    
}

//Paths
+ (NSString *)logBasePath;
+ (NSString *)relativePathForLogWithObject:(NSString *)object onAccount:(AIAccount *)account;

//Message History
+ (NSArray *)sortedArrayOfLogFilesForChat:(AIChat *)chat;

//Log viewer
- (void)showLogViewerAndReindex:(id)sender;
- (void)showLogViewerToSelectedContact:(id)sender;
- (void)showLogViewerToSelectedContextContact:(id)sender;

//Log indexing
- (void)initLogIndexing;
- (void)prepareLogContentSearching;
- (void)cleanUpLogContentSearching;
- (SKIndexRef)logContentIndex;
- (void)markLogDirtyAtPath:(NSString *)path forChat:(AIChat *)chat;
- (void)markLogDirtyAtPath:(NSString *)path;
- (BOOL)getIndexingProgress:(NSUInteger *)complete outOf:(NSUInteger *)total;

- (void)stopIndexingThreads;
- (void)dirtyAllLogs;
- (void)cleanDirtyLogs;
- (void)pauseIndexing;
- (void)resumeIndexing;

- (void)removePathsFromIndex:(NSSet *)paths;

@end

