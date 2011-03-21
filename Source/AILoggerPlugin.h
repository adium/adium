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


#define PATH_LOGS                     @"/Logs"
#define LOGGING_DEFAULT_PREFS         @"LoggingDefaults"

#define PREF_GROUP_LOGGING            @"Logging"
#define KEY_LOGGER_SECURE_CHATS			@"LogSecureChats"
#define KEY_LOGGER_CERTAIN_ACCOUNTS		@"LogCertainAccounts"
#define KEY_LOGGER_ENABLE               @"Enable Logging"
#define KEY_LOGGER_OBJECT_DISABLE       @"Disable Object Logging"

#define PREF_KEYPATH_LOGGER_ENABLE    PREF_GROUP_LOGGING @"." KEY_LOGGER_ENABLE

#define XML_LOGGING_NAMESPACE         @"http://purl.org/net/ulf/ns/0.4-02"

@class AIAccount, AIHTMLDecoder, AIChat;

@interface AILoggerPlugin : AIPlugin {
	
	//Log viewer menu items
	NSMenuItem          *logViewerMenuItem;
	NSMenuItem          *viewContactLogsMenuItem;
	NSMenuItem          *viewContactLogsContextMenuItem;
	NSMenuItem          *viewGroupLogsContextMenuItem;
	
	// Logging
	SKIndexRef           logIndex;
	NSMutableDictionary *activeAppenders;
	AIHTMLDecoder       *xhtmlDecoder;
	NSDictionary        *statusTranslation;
	BOOL                 logHTML;
	
	// Log Indexing
	NSMutableSet        *dirtyLogSet;
	BOOL                 indexingAllowed;
	BOOL                 loggingEnabled;
	BOOL                 canCloseIndex;
	BOOL                 canSaveDirtyLogSet;
	BOOL                 userTriggeredReindex;
	UInt64               logsToIndex;
	UInt64               logsIndexed;
}
@property(assign) SKIndexRef           logIndex;
@property(retain) NSMutableDictionary *activeAppenders;
@property(retain) AIHTMLDecoder       *xhtmlDecoder;
@property(retain) NSDictionary        *statusTranslation;
@property(retain) NSMutableSet        *dirtyLogSet;
@property(assign) BOOL                 logHTML;
@property(assign) BOOL                 indexingAllowed;
@property(assign) BOOL                 loggingEnabled;
@property(assign) BOOL                 canCloseIndex;
@property(assign) BOOL                 canSaveDirtyLogSet;
@property(assign) UInt64               logsToIndex;
@property(assign) UInt64               logsIndexed;



//Paths
+ (NSString *)logBasePath;
+ (NSString *)relativePathForLogWithObject:(NSString *)object onAccount:(AIAccount *)account;

//Message History
+ (NSArray *)sortedArrayOfLogFilesForChat:(AIChat *)chat;

//Log indexing
- (void)prepareLogContentSearching;
- (void)cleanUpLogContentSearching;
- (SKIndexRef)logContentIndex;
- (void)markLogDirtyAtPath:(NSString *)path;
- (BOOL)getIndexingProgress:(NSUInteger *)complete outOf:(NSUInteger *)total;

- (void)cancelIndexing;

- (void)removePathsFromIndex:(NSSet *)paths;

@end

