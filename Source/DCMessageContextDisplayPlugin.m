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
#import "DCMessageContextDisplayPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIService.h>

//#import "SMSQLiteLoggerPlugin.h"
//#import "AICoreComponentLoader.h"

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
#import <AIUtilities/NSCalendarDate+ISO8601Parsing.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIHTMLDecoder.h>

#define RESTORED_CHAT_CONTEXT_LINE_NUMBER 50

/**
 * @class DCMessageContextDisplayPlugin
 * @brief Component to display in-window message history
 *
 * The amount of history, and criteria of when to display history, are determined in the Advanced->Message History preferences.
 */
@interface DCMessageContextDisplayPlugin ()
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
- (void)old_preferencesChangedForGroup:(NSString *)group key:(NSString *)key
								object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime;
- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate;
- (NSArray *)contextForChat:(AIChat *)chat;
@end

@implementation DCMessageContextDisplayPlugin

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
		
	//Obtain the default preferences and use them - Adium 1.1 experiment to see if people use these prefs
	[self old_preferencesChangedForGroup:PREF_GROUP_CONTEXT_DISPLAY
								 key:nil
							  object:nil
					  preferenceDict:[NSDictionary dictionaryNamed:CONTEXT_DISPLAY_DEFAULTS
														  forClass:[self class]]
						   firstTime:YES];
	
	//Observe preference changes for whether or not to display message history
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_CONTEXT_DISPLAY];
}

/**
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
								object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!object) {		
		shouldDisplay = [[prefDict objectForKey:KEY_DISPLAY_CONTEXT] boolValue];
		linesToDisplay = [[prefDict objectForKey:KEY_DISPLAY_LINES] integerValue];

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
 * @brief Preferences for when to display history changed
 *
 * Only change our preferences in response to global preference notifications; specific objects use this group as well.
 */
- (void)old_preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (!object) {
		haveTalkedDays = [[prefDict objectForKey:KEY_HAVE_TALKED_DAYS] integerValue];
		haveNotTalkedDays = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_DAYS] integerValue];
		displayMode = [[prefDict objectForKey:KEY_DISPLAY_MODE] integerValue];
		
		haveTalkedUnits = [[prefDict objectForKey:KEY_HAVE_TALKED_UNITS] integerValue];
		haveNotTalkedUnits = [[prefDict objectForKey:KEY_HAVE_NOT_TALKED_UNITS] integerValue];		
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
		//Check if the history fits the date restrictions
		
		//The most recent message is what determines whether we have "chatted in the last X days", "not chatted in the last X days", etc.
		NSCalendarDate *mostRecentMessage = [[(AIContentContext *)[context lastObject] date] dateWithCalendarFormat:nil timeZone:nil];
		if ([self contextShouldBeDisplayed:mostRecentMessage]) {
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
}

/**
 * @brief Does a specified date match our criteria for display?
 *
 * The date passed should be the date of the _most recent_ stored message history item
 *
 * @result YES if the mesage history should be displayed
 */
- (BOOL)contextShouldBeDisplayed:(NSCalendarDate *)inDate
{
	BOOL dateIsGood = YES;
	NSInteger thresholdDays = 0;
	NSInteger thresholdHours = 0;
	
	if (displayMode != MODE_ALWAYS) {
		
		if (displayMode == MODE_HAVE_TALKED) {
			if (haveTalkedUnits == UNIT_DAYS)
				thresholdDays = haveTalkedDays;
			
			else if (haveTalkedUnits == UNIT_HOURS)
				thresholdHours = haveTalkedDays;
			
		} else if (displayMode == MODE_HAVE_NOT_TALKED) {
			if ( haveTalkedUnits == UNIT_DAYS )
				thresholdDays = haveNotTalkedDays;
			else if (haveTalkedUnits == UNIT_HOURS)
				thresholdHours = haveNotTalkedDays;
		}
		
		// Take the most recent message's date, add our limits to it
		// See if the new date is earlier or later than today's date
		NSCalendarDate *newDate = [inDate dateByAddingYears:0 months:0 days:thresholdDays hours:thresholdHours minutes:0 seconds:0];

		NSComparisonResult comparison = [newDate compare:[NSDate date]];
		
		if (((displayMode == MODE_HAVE_TALKED) && (comparison == NSOrderedAscending)) ||
			((displayMode == MODE_HAVE_NOT_TALKED) && (comparison == NSOrderedDescending)) ) {
			dateIsGood = NO;
		}
	}
	
	return dateIsGood;
}

static NSInteger linesLeftToFind = 0;
/*!
 * @brief Retrieve the message history for a particular chat
 *
 * Asks AILoggerPlugin for the path to the right file, and then uses LMX to parse that file backwards.
 */
- (NSArray *)contextForChat:(AIChat *)chat
{
	//If there's no log there, there's no message history. Bail out.
	NSArray *logPaths = [AILoggerPlugin sortedArrayOfLogFilesForChat:chat];
	if(!logPaths) return nil;

	AIHTMLDecoder *decoder = [AIHTMLDecoder decoder];

	NSString *logObjectUID = chat.name;
	if (!logObjectUID) logObjectUID = chat.listObject.UID;
	logObjectUID = [logObjectUID safeFilenameString];

	NSString *baseLogPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:
		[AILoggerPlugin relativePathForLogWithObject:logObjectUID onAccount:chat.account]];	

	if ([chat boolValueForProperty:@"Restored Chat"] && linesToDisplay < RESTORED_CHAT_CONTEXT_LINE_NUMBER) {
		linesLeftToFind = RESTORED_CHAT_CONTEXT_LINE_NUMBER;
	} else {
		linesLeftToFind = linesToDisplay;		
	}
			
	//Initialize a place to store found messages
	NSMutableArray *outerFoundContentContexts = [NSMutableArray arrayWithCapacity:linesLeftToFind]; 

	//Iterate over the elements of the log path array.
	NSEnumerator *pathsEnumerator = [logPaths objectEnumerator];
	NSString *logPath = nil;
	while (linesLeftToFind > 0 && (logPath = [pathsEnumerator nextObject])) {
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
		foundMessages = [NSMutableArray arrayWithCapacity:linesLeftToFind];
		elementStack = [NSMutableArray array];

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
						   nil];
			[parser setContextInfo:(void *)contextInfo];
		}

		//Open up the file we need to read from, and seek to the end (this is a *backwards* parser, after all :)
		NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:xmlFilePath];
		[file seekToEndOfFile];
		
		//Set up some more doohickeys and then start the parse loop
		NSInteger readSize = 4 * getpagesize(); //Read 4 pages at a time.
		NSMutableData *chunk = [NSMutableData dataWithLength:readSize];
		NSInteger fd = [file fileDescriptor];
		char *buf = [chunk mutableBytes];
		off_t offset = [file offsetInFile];
		enum LMXParseResult result = LMXParsedIncomplete;

		parsingAutoreleasePool = [[NSAutoreleasePool alloc] init];

		do {
			//Calculate the new offset
			offset = (offset <= readSize) ? 0 : offset - readSize;
			
			//Seek to it and read greedily until we hit readSize or run out of file.
			NSInteger idx = 0;
			for (ssize_t amountRead = 0; idx < readSize; idx += amountRead) { 
				amountRead = pread(fd, buf + idx, readSize, offset + idx); 
			   if (amountRead <= 0) break;
			}
			offset -= idx;
			
			//Parse
			result = [parser parseChunk:chunk];
			
		//Continue to parse as long as we need more elements, we have data to read, and LMX doesn't think we're done.
		} while ([foundMessages count] < linesLeftToFind && offset > 0 && result != LMXParsedCompletely);

		//Pop our autorelease pool.
		[parsingAutoreleasePool release]; parsingAutoreleasePool = nil;

		//Be a good citizen and close the file
		[file closeFile];

		//Add our locals to the outer array; we're probably looping again.
		[outerFoundContentContexts replaceObjectsInRange:NSMakeRange(0, 0) withObjectsFromArray:foundMessages];
		linesLeftToFind -= [outerFoundContentContexts count];
	}
	return outerFoundContentContexts;
}

#pragma mark LMX delegate

- (void)parser:(LMXParser *)parser elementEnded:(NSString *)elementName
{
	if ([elementName isEqualToString:@"message"]) {
		[elementStack insertObject:[AIXMLElement elementWithName:elementName] atIndex:0U];
	}
	else if ([elementStack count]) {
		AIXMLElement *element = [AIXMLElement elementWithName:elementName];
		[(AIXMLElement *)[elementStack objectAtIndex:0U] insertEscapedObject:element atIndex:0U];
		[elementStack insertObject:element atIndex:0U];
	}
}

- (void)parser:(LMXParser *)parser foundCharacters:(NSString *)string
{
	if ([elementStack count])
		[(AIXMLElement *)[elementStack objectAtIndex:0U] insertEscapedObject:string atIndex:0U];
}

- (void)parser:(LMXParser *)parser elementStarted:(NSString *)elementName attributes:(NSDictionary *)attributes
{
	if ([elementStack count]) {
		AIXMLElement *element = [elementStack objectAtIndex:0U];
		if (attributes) {
			[element setAttributeNames:[attributes allKeys] values:[attributes allValues]];
		}
		
		NSMutableDictionary *contextInfo = [parser contextInfo];

		if ([elementName isEqualToString:@"message"]) {
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
				NSCalendarDate *time = [NSCalendarDate calendarDateWithString:timeString];

				NSString		*autoreplyAttribute = [attributes objectForKey:@"auto"];
				NSString		*sender = [NSString stringWithFormat:@"%@.%@", serviceName, [attributes objectForKey:@"sender"]];
				BOOL			sentByMe = ([sender isEqualToString:accountID]);
				
				/*don't fade the messages if they're within the last 5 minutes
				 *since that will be resuming a conversation, not starting a new one.
				 *Why the class trickery? Less code duplication, clearer what is actually different between the two cases.
				 */
				Class messageClass = (-[time timeIntervalSinceNow] > 300.0) ? [AIContentContext class] : [AIContentMessage class];
				
				AIListContact *listContact = nil;
				
				if (chat.isGroupChat) {
					listContact = [chat.account contactWithUID:[attributes objectForKey:@"sender"]];
				} else {
					listContact = chat.listObject;
				}
				
				AIContentMessage *message = [messageClass messageInChat:chat 
															 withSource:(sentByMe ? account : listContact)
															destination:(sentByMe ? (chat.isGroupChat ? nil : chat.listObject) : account)
																   date:time
																message:[[contextInfo objectForKey:@"AIHTMLDecoder"] decodeHTML:[element contentsAsXMLString]]
															  autoreply:(autoreplyAttribute && [autoreplyAttribute caseInsensitiveCompare:@"true"] == NSOrderedSame)];
				
				//Don't log this object
				[message setPostProcessContent:NO];
				[message setTrackContent:NO];

				//Add it to the array (in front, since we're working backwards, and we want the array in forward order)
				[foundMessages insertObject:message atIndex:0];
			} else {
				NSLog(@"Null message context display time for %@",element);
			}
		}

		[elementStack removeObjectAtIndex:0U];
		if ([foundMessages count] == linesLeftToFind) {
			if ([elementStack count]) [elementStack removeAllObjects];
			[parser abortParsing];
		} else {
			//We're still looking for more messages in this file.
			//Pop the current autorelease pool and start a new one.
			//This frees the most recent tree of autoreleased AIXMLElements.
			[parsingAutoreleasePool release];
			parsingAutoreleasePool = [[NSAutoreleasePool alloc] init];
		}
	}
}

@end
