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

#import <Adium/AIContentControllerProtocol.h>
#import "DCMessageContextDisplayPlugin.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AIService.h>

//Old school
#import <Adium/AIListContact.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIAccountControllerProtocol.h>

//omg crawsslinkz
#import "AILoggerPlugin.h"

//LMX
#import <LMX/LMXParser.h>
#import <Adium/AIXMLElement.h>
#import <AIUtilities/AIStringAdditions.h>
#import "unistd.h"
#import <AIUtilities/ISO8601DateFormatter.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIHTMLDecoder.h>

#define RESTORED_CHAT_CONTEXT_LINE_NUMBER 50

static DCMessageContextDisplayPlugin *sharedInstance = nil;

/**
 * @class DCMessageContextDisplayPlugin
 * @brief Component to display in-window message history
 *
 * The amount of history, and criteria of when to display history, are determined in the Advanced->Message History preferences.
 */
@interface DCMessageContextDisplayPlugin ()
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
- (NSArray *)contextForChat:(AIChat *)chat;
- (void)addContextDisplayToWindow:(NSNotification *)notification;
+ (DCMessageContextDisplayPlugin *)sharedInstance;
@end

@implementation DCMessageContextDisplayPlugin

+ (DCMessageContextDisplayPlugin *)sharedInstance
{
	return sharedInstance;
}

/**
 * @brief Install
 */
- (void)installPlugin
{
	isObserving = NO;
	
	//Setup our preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:CONTEXT_DISPLAY_DEFAULTS
																	  forClass:[self class]] 
										forGroup:PREF_GROUP_CONTEXT_DISPLAY];
	
	//Observe preference changes for whether or not to display message history
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTEXT_DISPLAY];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LOGGING];
	
	sharedInstance = self;
	formatter = [[ISO8601DateFormatter alloc] init];
}

/**
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[formatter release];
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
								object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!object) {
		if ([group isEqualToString:PREF_GROUP_LOGGING]) {
			shouldDisplay = [[prefDict objectForKey:KEY_LOGGER_ENABLE] boolValue]
				&& [[adium.preferenceController preferenceForKey:KEY_DISPLAY_CONTEXT
														   group:PREF_GROUP_CONTEXT_DISPLAY] boolValue];
		} else if ([group isEqualToString:PREF_GROUP_CONTEXT_DISPLAY]) {
			shouldDisplay = [[prefDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue]
				&& [[adium.preferenceController preferenceForKey:KEY_LOGGER_ENABLE
														  group:PREF_GROUP_LOGGING] boolValue];
			linesToDisplay = [[prefDict objectForKey:KEY_DISPLAY_LINES] integerValue];
		}
		
		if (shouldDisplay && linesToDisplay > 0 && !isObserving) {
			//Observe new message windows only if we aren't already observing them
			isObserving = YES;
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(addContextDisplayToWindow:)
														 name:Chat_DidOpen 
													   object:nil];
			
		} else if (isObserving && (!shouldDisplay || linesToDisplay <= 0)) {
			//Remove observer
			isObserving = NO;
			[[NSNotificationCenter defaultCenter] removeObserver:self name:Chat_DidOpen object:nil];
			
		}
	}
}

/**
 * @brief Retrieve and display in-window message history
 *
 * Called in response to the Chat_DidOpen notification
 */
- (void)addContextDisplayToWindow:(NSNotification *)notification
{
	AIChat	*chat = (AIChat *)[notification object];
	
	NSArray	*context = [self contextForChat:chat];

	if (context && [context count] > 0 && shouldDisplay) {
		AIContentContext	*contextMessage;

		for(contextMessage in context) {
			/* Don't display immediately, so the message view can aggregate multiple message history items.
			 * As required, we post Content_ChatDidFinishAddingUntrackedContent when finished adding. */
			[contextMessage setDisplayContentImmediately:NO];
		
			[adium.contentController displayContentObject:contextMessage
										usingContentFilters:YES
												immediately:YES];
		}

		//We finished adding untracked content
		[[NSNotificationCenter defaultCenter] postNotificationName:Content_ChatDidFinishAddingUntrackedContent
												  object:chat];
	}
}
/*!
 * @brief Retrieve the message history for a particular chat
 *
 * Asks AILoggerPlugin for the path to the right file, and then uses LMX to parse that file backwards.
 */
- (NSArray *)contextForChat:(AIChat *)chat
{
	NSInteger linesLeftToFind = 0;

	if ([chat boolValueForProperty:@"Restored Chat"] && linesToDisplay < RESTORED_CHAT_CONTEXT_LINE_NUMBER) {
		linesLeftToFind = MAX(linesLeftToFind, RESTORED_CHAT_CONTEXT_LINE_NUMBER);
	} else {
		linesLeftToFind = linesToDisplay;		
	}
	
	return [self contextForChat:chat lines:linesLeftToFind alsoStatus:NO];
}

- (NSArray *)contextForChat:(AIChat *)chat lines:(NSInteger)linesLeftToFind alsoStatus:(BOOL)alsoStatus
{
	//If there's no log there, there's no message history. Bail out.
	NSArray *logPaths = [AILoggerPlugin sortedArrayOfLogFilesForChat:chat];
	
	if(!logPaths || linesLeftToFind == 0) return nil;
	
	NSString *logObjectUID = chat.name;
	if (!logObjectUID) logObjectUID = chat.listObject.UID;
	logObjectUID = [logObjectUID safeFilenameString];
	
	AIHTMLDecoder *decoder = [AIHTMLDecoder decoder];
	
	NSString *baseLogPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:
							 [AILoggerPlugin relativePathForLogWithObject:logObjectUID onAccount:chat.account]];	

	
	//Initialize a place to store found messages
	NSMutableArray *outerFoundContentContexts = [NSMutableArray arrayWithCapacity:linesLeftToFind]; 

	//Iterate over the elements of the log path array.
	for (NSString *logPath in logPaths) {
		if (linesLeftToFind <= 0)
			break;
		//If it's not a .chatlog, ignore it.
		if (![logPath hasSuffix:@".chatlog"])
			continue;
				
		//Stick the base path on to the beginning
		logPath = [baseLogPath stringByAppendingPathComponent:logPath];

		//By default, the xmlFilePath is the chat log file/bundle... if we find that the chatlog is a bundle, we'll use the xml file inside.
		NSString *xmlFilePath = logPath;

		BOOL isDir;
		if ([[NSFileManager defaultManager] fileExistsAtPath:logPath isDirectory:&isDir]) {
			/* If we have a chatLog bundle, we want to get the text content for the xml file inside */
			NSString *baseURL;
			if (isDir) {
				baseURL = logPath;
				xmlFilePath = [logPath stringByAppendingPathComponent:
							   [[[logPath lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"]];
			} else {
				baseURL = nil;
			}
			[decoder setBaseURL:baseURL];
		}

		//Initialize the found messages array and element stack for us-as-delegate
		NSMutableArray *foundMessages = [NSMutableArray arrayWithCapacity:linesLeftToFind];
		NSMutableArray *elementStack = [NSMutableArray array];

		//Create the parser and set ourselves as the delegate
		LMXParser *parser = [LMXParser parser];
		[parser setDelegate:self];

		//Set up info needed by elementStarted to create content objects.
		NSMutableDictionary *contextInfo = nil;
		{
			//Get the service name from the path name
			NSString *serviceName = [[[[[logPath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] lastPathComponent] componentsSeparatedByString:@"."] objectAtIndex:0U];

			AIListObject *account = chat.account;
			NSString	 *accountID = [NSString stringWithFormat:@"%@.%@", account.service.serviceID, account.UID];

			contextInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						   serviceName, @"Service name",
						   account, @"Account",
						   accountID, @"Account ID",
						   chat, @"Chat",
						   decoder, @"AIHTMLDecoder",
						   [NSValue valueWithPointer:&linesLeftToFind], @"LinesLeftToFindValue",
						   foundMessages, @"FoundMessages",
						   elementStack, @"ElementStack",
                           [NSNumber numberWithBool:alsoStatus], @"AlsoAllowStatus",
						   nil];
			[parser setContextInfo:(void *)contextInfo];
		}

		//Open up the file we need to read from, and seek to the end (this is a *backwards* parser, after all :)
		NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:xmlFilePath];
		[file seekToEndOfFile];
		
		//Set up some more doohickeys and then start the parse loop
		NSInteger readSize = 4 * getpagesize(); //Read 4 pages at a time.
		NSMutableData *chunk = [NSMutableData dataWithLength:readSize];
		int fd = [file fileDescriptor];
		off_t offset = [file offsetInFile];
		enum LMXParseResult result = LMXParsedIncomplete;

		// These set of file's autorelease pool.
		NSAutoreleasePool *parsingAutoreleasePool = [[NSAutoreleasePool alloc] init];
		
		@try {
			do {
				// The location we're going to read for *this* set of reads.
				off_t readOffset = offset - readSize;
				
				if (readOffset < 0) {
					// Decrease it by the amount we're over.
					readSize += (NSInteger)readOffset;
					// Start from the beginning.
					readOffset = 0;
				}
				
				if (chunk.length != readSize) {
					// In case we short-read last time, or we're reading a smaller amount this time.
					[chunk setLength:readSize];				
				}
				
				char *buf = [chunk mutableBytes];
				
				//Seek to it and read greedily until we hit readSize or run out of file.
				NSInteger idx = 0;
				ssize_t amountRead = 0;
				for (amountRead = 0; idx < readSize; idx += amountRead) { 
					amountRead = pread(fd, buf + idx, readSize, readOffset + idx); 
					if (amountRead <= 0) break;
				}
				
				if (idx != readSize) {
					// If we short read, we don't want to read unknown buffer contents.
					[chunk setLength:idx];
				}
				
				// Adjust the real offset
				offset -= idx;
				
				//Parse
				result = [parser parseChunk:chunk];
				
				//Continue to parse as long as we need more elements, we have data to read, and LMX doesn't think we're done.
			} while ([foundMessages count] < linesLeftToFind && offset > 0 && result != LMXParsedCompletely);

		} @catch (id theException) {
			AILogWithSignature(@"Error \"%@\" while parsing %@; foundMessages at that point was %@, and the chunk to be parsed was %@",
							   theException, logPath, 
							   foundMessages, chunk);

		} @finally {
			//Drain our autorelease pool.
			[parsingAutoreleasePool release];
			
			//Be a good citizen and close the file
			[file closeFile];
			
			//Add our locals to the outer array; we're probably looping again.
			AILog(@"Context: %li messages from %@: %@", foundMessages.count, [xmlFilePath lastPathComponent], foundMessages);
			[outerFoundContentContexts replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:foundMessages];
			linesLeftToFind -= [outerFoundContentContexts count];
		}
	}
	
	if (linesLeftToFind > 0) {
		AILogWithSignature(@"Unable to find %ld logs for %@; we needed %ld more", linesToDisplay, chat, linesLeftToFind);
	}
	
	return outerFoundContentContexts;
}

#pragma mark LMX delegate

- (void)parser:(LMXParser *)parser elementEnded:(NSString *)elementName
{
	NSMutableDictionary *contextInfo = [parser contextInfo];
	NSMutableArray *elementStack = [contextInfo objectForKey:@"ElementStack"];
	
	if ([elementName isEqualToString:@"message"] || [elementName isEqualToString:@"action"] ||
		([[contextInfo valueForKey:@"AlsoAllowStatus"] boolValue] && [elementName isEqualToString:@"status"])) {
		[elementStack insertObject:[AIXMLElement elementWithName:elementName] atIndex:0U];
	}
	else if ([elementStack count]) {
		AIXMLElement *element = [AIXMLElement elementWithName:elementName];
		[(AIXMLElement *)[elementStack objectAtIndex:0U] insertObject:element atIndex:0U];
		[elementStack insertObject:element atIndex:0U];
	}
}

- (void)parser:(LMXParser *)parser foundCharacters:(NSString *)string
{
	NSMutableDictionary *contextInfo = [parser contextInfo];
	NSMutableArray *elementStack = [contextInfo objectForKey:@"ElementStack"];
	
	if ([elementStack count])
		[(AIXMLElement *)[elementStack objectAtIndex:0U] insertObject:string atIndex:0U];
}

- (void)parser:(LMXParser *)parser elementStarted:(NSString *)elementName attributes:(NSDictionary *)inAttributes
{
	NSMutableDictionary *contextInfo = [parser contextInfo];
	NSMutableArray *elementStack = [contextInfo objectForKey:@"ElementStack"];
	
	if ([elementStack count]) {
		AIXMLElement *element = [elementStack objectAtIndex:0U];
		if (inAttributes) {
			[element setAttributeNames:[inAttributes allKeys] values:[inAttributes allValues]];
		}
		
		NSMutableArray	*foundMessages = [contextInfo objectForKey:@"FoundMessages"];
		NSInteger	 *linesLeftToFind = [[contextInfo objectForKey:@"LinesLeftToFindValue"] pointerValue];
		
		if ([elementName isEqualToString:@"message"] || [elementName isEqualToString:@"action"]) {
			//A message element has started!
			//This means that we have all of this message now, and therefore can create a single content object from the AIXMLElement tree and then throw away that tree.
			//This saves memory when a message element contains many elements (since each one is represented by an AIXMLElement sub-tree in the AIXMLElement tree, as opposed to a simple NSAttributeRun in the NSAttributedString of the content object).

			NSString     *serviceName = [contextInfo objectForKey:@"Service name"];
			AIListObject *account     = [contextInfo objectForKey:@"Account"];
			NSString     *accountID   = [contextInfo objectForKey:@"Account ID"];
			AIChat       *chat        = [contextInfo objectForKey:@"Chat"];
			
			//Set up some doohickers.
			NSDictionary	*attributes = [element attributes];
			NSString		*timeString = [attributes objectForKey:@"time"];
			//Create the context object
			if (timeString) {
				NSDate *timeVal = [formatter dateFromString:timeString];

				NSString		*autoreplyAttribute = [attributes objectForKey:@"auto"];
				NSString		*sender = [NSString stringWithFormat:@"%@.%@", serviceName, [attributes objectForKey:@"sender"]];
				BOOL			sentByMe = ([sender isEqualToString:accountID]);
				
				/*don't fade the messages if they're within the last 5 minutes
				 *since that will be resuming a conversation, not starting a new one.
				 *Why the class trickery? Less code duplication, clearer what is actually different between the two cases.
				 */
				Class messageClass = (-[timeVal timeIntervalSinceNow] > 300.0) ? [AIContentContext class] : [AIContentMessage class];
				
				AIListContact *listContact = nil;
				
				if (chat.isGroupChat) {
					listContact = [chat.account contactWithUID:[attributes objectForKey:@"sender"]];
				} else {
					listContact = chat.listObject;
				}
				
				AIContentMessage *message = [messageClass messageInChat:chat 
															 withSource:(sentByMe ? account : listContact)
															 sourceNick:[attributes objectForKey:@"alias"] ? : [attributes objectForKey:@"sender"]
															destination:(sentByMe ? (chat.isGroupChat ? nil : chat.listObject) : account)
																   date:timeVal
																message:[[contextInfo objectForKey:@"AIHTMLDecoder"] decodeHTML:[element contentsAsXMLString]]
															  autoreply:(autoreplyAttribute && [autoreplyAttribute caseInsensitiveCompare:@"true"] == NSOrderedSame)];
				
				//Properly style /me-type messages
				if ([elementName isEqualToString:@"action"])
					[message addDisplayClass:@"action"];
				
				//Don't log this object
				[message setPostProcessContent:NO];
				[message setTrackContent:NO];
				
				//Add it to the array (in front, since we're working backwards, and we want the array in forward order)
				[foundMessages insertObject:message atIndex:0];
			} else {
				NSLog(@"Null message context display time for %@",element);
			}
		} else if ([[contextInfo valueForKey:@"AlsoAllowStatus"] boolValue] && [elementName isEqualToString:@"status"]) {
            
			AIChat          *chat = [contextInfo objectForKey:@"Chat"];
			
			NSDictionary	*attributes = [element attributes];
			NSString		*timeString = [attributes objectForKey:@"time"];
			
			if (timeString) {
				NSDate *timeVal = [formatter dateFromString:timeString];
                
                AIContentStatus *status = [[AIContentStatus alloc] initWithChat:chat source:nil destination:nil date:timeVal];
                
                [foundMessages insertObject:status atIndex:0];
                [status release];
            }
        }
		
		[elementStack removeObjectAtIndex:0U];
		if ([foundMessages count] == *linesLeftToFind) {
			if ([elementStack count]) [elementStack removeAllObjects];
			[parser abortParsing];
		}
	}
}

@end
