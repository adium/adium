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
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import "ESApplescriptabilityController.h"
#import "GBApplescriptFiltersPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/MVMenuButton.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIHTMLDecoder.h>

#define TITLE_INSERT_SCRIPT		AILocalizedString(@"Insert Script",nil)
#define SCRIPT_BUNDLE_EXTENSION	@"AdiumScripts"
#define SCRIPTS_PATH_NAME		@"Scripts"
#define SCRIPT_EXTENSION		@"scpt"
#define	SCRIPT_IDENTIFIER		@"InsertScript"

#define SCRIPT_TIMEOUT			30

@interface GBApplescriptFiltersPlugin ()
- (NSArray *)_argumentsFromString:(NSString *)inString forScript:(NSMutableDictionary *)scriptDict;
- (void)buildScriptMenu;
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu;
- (void)registerToolbarItem;
- (void)xtrasChanged:(NSNotification *)notification;
- (IBAction)selectScript:(id)sender;
- (void)applescriptDidRun:(id)userInfo resultString:(NSString *)resultString;
- (IBAction)dummyTarget:(id)sender;

- (void)_replaceKeyword:(NSString *)keyword
			 withScript:(NSMutableDictionary *)infoDict
			   inString:(NSString *)inString
	 inAttributedString:(NSMutableAttributedString *)attributedString
				context:(id)context
			   uniqueID:(unsigned long long)uniqueID;

- (void)_executeScript:(NSMutableDictionary *)infoDict 
		 withArguments:(NSArray *)arguments
		 forAttributedString:(NSMutableAttributedString *)attributedString
		  keywordRange:(NSRange)keywordRange
			   context:(id)context
			  uniqueID:(unsigned long long)uniqueID;
@end

NSInteger _scriptTitleSort(id scriptA, id scriptB, void *context);
NSInteger _scriptKeywordLengthSort(id scriptA, id scriptB, void *context);

/*!
 * @class GBApplescriptFiltersPlugin
 * @brief Filter component to allow .AdiumScripts applescript-based filters for outgoing messages
 */
@implementation GBApplescriptFiltersPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	//User scripts
	[adium createResourcePathForName:@"Scripts"];
	
	//We have an array of scripts for building the menu, and a dictionary of scripts used for the actual substition
	scriptArray = nil;
	flatScriptArray = nil;
	
	//Prepare our script menu item (which will have the Scripts menu as its submenu)
	scriptMenuItem = [[NSMenuItem alloc] initWithTitle:TITLE_INSERT_SCRIPT 
												target:self
												action:@selector(dummyTarget:)
										 keyEquivalent:@""];

	//Perform substitutions on outgoing content; we may be slow, so register as a delayed content filter
	[adium.contentController registerDelayedContentFilter:self 
													 ofType:AIFilterContent
												  direction:AIFilterOutgoing];
	
	//Observe for installation of new scripts
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:AIXtrasDidChangeNotification
									 object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toolbarWillAddItem:)
												 name:NSToolbarWillAddItemNotification
											   object:nil];
	//Start building the script menu
	scriptMenu = nil;
	[self buildScriptMenu]; //this also sets the submenu for the menu item.
	
	[adium.menuController addMenuItem:scriptMenuItem toLocation:LOC_Edit_Additions];
	
	contextualScriptMenuItem = [scriptMenuItem copy];
	[adium.menuController addContextualMenuItem:contextualScriptMenuItem toLocation:Context_TextView_Edit];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	scriptArray = nil;
    flatScriptArray = nil;
	scriptMenuItem = nil;
	contextualScriptMenuItem = nil;
	
}

/*!
 * @brief Xtras changes
 *
 * If the scripts xtras changed, rebuild our menus.
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:@"AdiumScripts"] == NSOrderedSame) {
		[self buildScriptMenu];
				
		[self registerToolbarItem];
		
		//Update our toolbar item's menu
		//[self toolbarWillAddItem:nil];
	}
}


//Script Loading -------------------------------------------------------------------------------------------------------
#pragma mark Script Loading
/*!
 * @brief Load our scripts
 *
 * This will clear out and then load from available scripts (external and internal) into flatScriptArray and scriptArray.
 */
- (void)loadScripts
{
	//
	scriptArray = [[NSMutableArray alloc] init];
	flatScriptArray = [[NSMutableArray alloc] init];
	
	// Load scripts
	for (NSString *filePath in [adium allResourcesForName:@"Scripts" withExtensions:SCRIPT_BUNDLE_EXTENSION]) {
		NSBundle		*scriptBundle;

		if ((scriptBundle = [NSBundle bundleWithPath:filePath])) {
			NSString		*scriptsSetName;
			NSDictionary	*infoDict = [NSDictionary dictionaryWithContentsOfFile:[[scriptBundle bundlePath] stringByAppendingPathComponent:@"Info.plist"]];
			if (!infoDict) infoDict= [scriptBundle infoDictionary];

			NSDictionary	*localizedInfoDict = [scriptBundle localizedInfoDictionary];

			//Get the name of the set these scripts will go into
			scriptsSetName = [localizedInfoDict objectForKey:@"Set"];
			if (!scriptsSetName) scriptsSetName = [infoDict objectForKey:@"Set"];

			//Now enumerate each script the bundle claims as its own
			for (NSDictionary *scriptDict in [infoDict objectForKey:@"Scripts"]) {
				NSString		*scriptFileName, *scriptFilePath, *keyword, *title;
				NSArray			*arguments;
				NSNumber		*prefixOnlyNumber;
				
				if ((scriptFileName = [scriptDict objectForKey:@"File"]) &&
					(scriptFilePath = [scriptBundle pathForResource:scriptFileName
															 ofType:SCRIPT_EXTENSION])) {
					
					keyword = [scriptDict objectForKey:@"Keyword"];
					title = [scriptDict objectForKey:@"Title"];

					//The keywords titles are keyed by their English version in the localized info dict
					NSString *localizedKeyword = [localizedInfoDict objectForKey:keyword];
					if (localizedKeyword) keyword = localizedKeyword;

					NSString *localizedTitle = [localizedInfoDict objectForKey:title];
					if (localizedTitle) title = localizedTitle;

					if (keyword && [keyword length] && title && [title length]) {
						NSMutableDictionary	*newInfoDict;
						
						arguments = [[scriptDict objectForKey:@"Arguments"] componentsSeparatedByString:@","];
						
						//Assume "Prefix Only" is NO unless told otherwise or the keyword starts with '/'
						prefixOnlyNumber = [scriptDict objectForKey:@"Prefix Only"];
						if (!prefixOnlyNumber) {
							prefixOnlyNumber = [NSNumber numberWithBool:[keyword hasPrefix:@"/"]];
						}

						newInfoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							scriptFilePath, @"Path", keyword, @"Keyword", title, @"Title", 
							prefixOnlyNumber, @"PrefixOnly", nil];
						
						//The bundle may not be part of (or for defining) a set of scripts
						if (scriptsSetName) {
							[newInfoDict setObject:scriptsSetName forKey:@"Set"];
						}
						//Arguments may be nil
						if (arguments) {
							[newInfoDict setObject:arguments forKey:@"Arguments"];
						}
						
						//Place the entry in our script arrays
						[scriptArray addObject:newInfoDict];
						[flatScriptArray addObject:newInfoDict];
						
						//Scripts must always be updated via polling
						[adium.contentController registerFilterStringWhichRequiresPolling:keyword];
					}
				}
			}
		} else {
			NSLog(@"Warning: Could not load Adium script bundle at %@",filePath);
		}
	}
}


//Script Menu ----------------------------------------------------------------------------------------------------------
#pragma mark Script Menu
/*!
 * @brief Build the script menu
 *
 * Loads the scrpts as necessary, sorts them, then builds menus for the menu bar, the contextual menu,
 * and the toolbar item.
 */
- (void)buildScriptMenu
{
	[self loadScripts];
	
	//Sort the scripts
	[scriptArray sortUsingFunction:_scriptTitleSort context:nil];
	[flatScriptArray sortUsingFunction:_scriptKeywordLengthSort context:nil];
	
	//Build the menu
	scriptMenu = [[NSMenu alloc] initWithTitle:TITLE_INSERT_SCRIPT];
	[self _appendScripts:scriptArray toMenu:scriptMenu];
	[scriptMenuItem setSubmenu:scriptMenu];
	[contextualScriptMenuItem setSubmenu:[scriptMenu copy]];
		
	[self registerToolbarItem];
}

/*!
 * @brief Sort first by set, then by title within sets
 */
NSInteger _scriptTitleSort(id scriptA, id scriptB, void *context) {
	NSComparisonResult result;
	
	NSString	*setA = [scriptA objectForKey:@"Set"];
	NSString	*setB = [scriptB objectForKey:@"Set"];
	
	if (setA && setB) {
		
		//If both are within sets, sort by set; if they are within the same set, sort by title
		if ((result = [setA caseInsensitiveCompare:setB]) == NSOrderedSame) {
			result = [(NSString *)[scriptA objectForKey:@"Title"] caseInsensitiveCompare:[scriptB objectForKey:@"Title"]];
		}
	} else {
		//Sort by title if neither is in a set; otherwise sort the one in a set to the top
		
		if (!setA && !setB) {
			result = [(NSString *)[scriptA objectForKey:@"Title"] caseInsensitiveCompare:[scriptB objectForKey:@"Title"]];
		
		} else if (!setA) {
			result = NSOrderedDescending;
		} else {
			result = NSOrderedAscending;
		}
	}
	
	return result;
}

/*!
 * @brief Sort by descending length so the longest keywords are at the beginning of the array
 */
NSInteger _scriptKeywordLengthSort(id scriptA, id scriptB, void *context)
{
	NSComparisonResult result;
	
	NSUInteger lengthA = [(NSString *)[scriptA objectForKey:@"Keyword"] length];
	NSUInteger lengthB = [(NSString *)[scriptB objectForKey:@"Keyword"] length];
	if (lengthA > lengthB) {
		result = NSOrderedAscending;
	} else if (lengthA < lengthB) {
		result = NSOrderedDescending;
	} else {
		result = NSOrderedSame;
	}
	
	return result;
}

/*!
 * @brief Append an array of scripts to a menu
 *
 * @param scripts The scripts, each of which is represented by an NSDictionary instance
 * @param menu The menu to which to add the scripts
 */
- (void)_appendScripts:(NSArray *)scripts toMenu:(NSMenu *)menu
{
	NSDictionary	*appendDict;
	NSString		*lastSet = nil;
	NSString		*set;
	NSInteger		indentationLevel;
	
	for (appendDict in scripts) {
		NSString	*title;
		NSMenuItem	*item;
		
		if ((set = [appendDict objectForKey:@"Set"])) {
			indentationLevel = 1;
			
			if (![set isEqualToString:lastSet]) {
				//We have a new set of scripts; create a section header for them
				item = [[NSMenuItem alloc] initWithTitle:set
																			 target:nil
																			 action:nil
																	  keyEquivalent:@""];
				if ([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:0];
				[menu addItem:item];
				
				lastSet = set;
			}
		} else {
			//Scripts not in sets need not be indented
			indentationLevel = 0;
			lastSet = nil;
		}
	
		if ([appendDict objectForKey:@"Title"]) {
			title = [NSString stringWithFormat:@"%@ (%@)", [appendDict objectForKey:@"Title"], [appendDict objectForKey:@"Keyword"]];
		} else {
			title = [appendDict objectForKey:@"Keyword"];
		}
		
		item = [[NSMenuItem alloc] initWithTitle:title
																	 target:self
																	 action:@selector(selectScript:)
															  keyEquivalent:@""];
		
		[item setRepresentedObject:appendDict];
		if ([item respondsToSelector:@selector(setIndentationLevel:)]) [item setIndentationLevel:indentationLevel];
		[menu addItem:item];
	}
	
}

/*!
 * @brief Insert a script's keyword into the text entry area
 *
 * This will be called by an NSMenuItem when it is clicked.
 */
- (IBAction)selectScript:(id)sender
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
	//Append our string into the responder if possible
	if (responder && [responder isKindOfClass:[NSTextView class]]) {
		NSArray		*arguments = [[sender representedObject] objectForKey:@"Arguments"];
		NSString	*replacementText = [[sender representedObject] objectForKey:@"Keyword"];
		
		[(NSTextView *)responder insertText:replacementText];
		
		//Append arg list to replacement string, to show the user what they can pass
		if (arguments) {
			NSDictionary		*originalTypingAttributes = [(NSTextView *)responder typingAttributes];
			NSMutableDictionary *italicizedTypingAttributes = [originalTypingAttributes mutableCopy];
			NSString			*anArgument;
			BOOL				insertedFirst = NO;
			
			[italicizedTypingAttributes setObject:[[NSFontManager sharedFontManager] convertFont:[originalTypingAttributes objectForKey:NSFontAttributeName]
																					 toHaveTrait:NSItalicFontMask]
										   forKey:NSFontAttributeName];
			
			[(NSTextView *)responder insertText:@"{"];
			
			//Will that be a five minute argument or the full half hour?
			for (anArgument in arguments) {
				//Insert a comma after each argument past the first
				if (insertedFirst) {
					[(NSTextView *)responder insertText:@","];					
				} else {
					insertedFirst = YES;
				}
				
				//Turn on the italics version, insert the argument, then go back to normal for either the comma or the ending
				[(NSTextView *)responder setTypingAttributes:italicizedTypingAttributes];
				[(NSTextView *)responder insertText:anArgument];
				[(NSTextView *)responder setTypingAttributes:originalTypingAttributes];
			}

			[(NSTextView *)responder insertText:@"}"];
		}
	}
}

/*!
 * @brief Fake target to allow validateMenuItem: to be called
 */
-(IBAction)dummyTarget:(id)sender{
}

/*!
 * @brief Validate menu item
 * Disable the insertion if a text field is not active
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ((menuItem == scriptMenuItem) || (menuItem == contextualScriptMenuItem)) {
		return YES; //Always keep the submenu enabled so users can see the available scripts
	} else {
		NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if (responder && [responder isKindOfClass:[NSText class]]) {
			return [(NSText *)responder isEditable];
		} else {
			return NO;
		}
	}
}

//Message Filtering ----------------------------------------------------------------------------------------------------
#pragma mark Message Filtering
/*!
 * @brief Delayed filter messages for keywords to replace
 *
 * Will eventually replace any script keywords with the result of running the script (with arguments as appropriate).
 * @result YES if we began a delayed filtration; NO if we did not
 */
- (BOOL)delayedFilterAttributedString:(NSAttributedString *)inAttributedString context:(id)context uniqueID:(unsigned long long)uniqueID
{
	BOOL		beganProcessing = NO; 
	NSString	*stringMessage;

	if ((stringMessage = [inAttributedString string])) {
		//Replace all keywords
		for (NSMutableDictionary *infoDict in flatScriptArray) {
			NSString	*keyword = [infoDict objectForKey:@"Keyword"];
			BOOL		prefixOnly = [[infoDict objectForKey:@"PrefixOnly"] boolValue];

			if ((prefixOnly && ([stringMessage rangeOfString:keyword options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location == 0)) ||
			   (!prefixOnly && [stringMessage rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound)) {
				NSNumber	*shouldSendNumber;

				[self _replaceKeyword:keyword
						   withScript:infoDict
							 inString:stringMessage
				   inAttributedString:[inAttributedString mutableCopy]
							  context:context
							 uniqueID:uniqueID];

				shouldSendNumber = [infoDict objectForKey:@"ShouldSend"];
				if ((shouldSendNumber) &&
					(![shouldSendNumber boolValue]) &&
					([context isKindOfClass:[AIContentObject class]])) {
					[(AIContentObject *)context setSendContent:NO];
				}
				
				beganProcessing = YES;
				break;
			}
		}
	}
	
    return beganProcessing;
}

/*!
 * @brief Filter priority
 *
 * Filter earlier than the default
 */
- (CGFloat)filterPriority
{
	return HIGH_FILTER_PRIORITY;
}

/*!
 * @brief Replace one instance of a keyword within a string. This will be called once for each instance.
 */
- (void)_replaceKeyword:(NSString *)keyword
			 withScript:(NSMutableDictionary *)infoDict
			   inString:(NSString *)inString
	 inAttributedString:(NSMutableAttributedString *)attributedString
				context:(id)context
			   uniqueID:(unsigned long long)uniqueID
{
	NSScanner	*scanner;
	BOOL		foundKeyword = NO;

	//Scan for the keyword
	scanner = [NSScanner scannerWithString:inString];
	while (![scanner isAtEnd] && !foundKeyword) {
		[scanner scanUpToString:keyword intoString:nil];
		
		if (([scanner scanString:keyword intoString:nil]) &&
			([attributedString attribute:NSLinkAttributeName
								 atIndex:([scanner scanLocation]-1) /* The scanner ends up one past the keyword */
						  effectiveRange:nil] == nil)) {
			//Scan the keyword and ensure it was not found within a link
			NSInteger 		keywordStart, keywordEnd;
			NSArray 	*argArray = nil;
			NSString	*argString;
			
			//Scan arguments
			keywordStart = [scanner scanLocation] - [keyword length];
			if ([scanner scanString:@"{" intoString:nil]) {
				if ([scanner scanUpToString:@"}" intoString:&argString]) {
					argArray = [self _argumentsFromString:argString forScript:infoDict];
					[scanner scanString:@"}" intoString:nil];
				}				
			}
			keywordEnd = [scanner scanLocation];		
			
			//Run the script.
			NSRange	keywordRange = NSMakeRange(keywordStart, keywordEnd - keywordStart);
			[self _executeScript:infoDict 
				   withArguments:argArray
			 forAttributedString:attributedString
					keywordRange:keywordRange
						 context:context
						uniqueID:uniqueID];
			
			foundKeyword = YES;
		}
	}
}

/*!
 * @brief Execute the script as a separate task
 *
 * When the task is complete, we will be notified, at which point we perform the replacement for the script result
 * and pass the modified attributed string back to the content controller for use.
 */
- (void)_executeScript:(NSMutableDictionary *)infoDict 
			   withArguments:(NSArray *)arguments
		 forAttributedString:(NSMutableAttributedString *)attributedString
				keywordRange:(NSRange)keywordRange
					 context:(id)context
					uniqueID:(unsigned long long)uniqueID
{
	NSDictionary	*userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		attributedString, @"Mutable Attributed String",
		NSStringFromRange(keywordRange), @"Range",
		[NSNumber numberWithUnsignedLongLong:uniqueID], @"uniqueID",
		(context ? context : [NSNull null]), @"context",
		nil];
	
	[adium.applescriptabilityController runApplescriptAtPath:[infoDict objectForKey:@"Path"]
													  function:@"substitute"
													 arguments:arguments
											   notifyingTarget:self
													  selector:@selector(applescriptDidRun:resultString:)
													  userInfo:userInfo];
}

/*!
 * @brief A script finished running
 */
- (void)applescriptDidRun:(id)userInfo resultString:(NSString *)resultString
{
	NSMutableAttributedString	*attributedString = [userInfo objectForKey:@"Mutable Attributed String"];
	NSRange						keywordRange = NSRangeFromString([userInfo objectForKey:@"Range"]);
	unsigned long long			uniqueID = [[userInfo objectForKey:@"uniqueID"] unsignedLongLongValue];

	//If the script fails, eat the keyword
	if (!resultString) resultString = @"";

	//Replace the substring with script result
	if (NSMaxRange(keywordRange) <= [attributedString length]) {
		if (([resultString hasPrefix:@"<HTML>"])) {
			//Obtain the attributed string version of the HTML, passing our current attributes as the default ones
			NSAttributedString *attributedScriptResult = [AIHTMLDecoder decodeHTML:resultString
															 withDefaultAttributes:[attributedString attributesAtIndex:keywordRange.location
																										effectiveRange:nil]];
			[attributedString replaceCharactersInRange:keywordRange
								  withAttributedString:attributedScriptResult];
			
		} else {
			[attributedString replaceCharactersInRange:keywordRange
											withString:resultString];
		}
	}

	//Inform the content controller that we're done if we don't need to do any more filtering
	if (![self delayedFilterAttributedString:attributedString
									 context:[userInfo objectForKey:@"context"]
									uniqueID:uniqueID]) {
		[adium.contentController delayedFilterDidFinish:attributedString
												 uniqueID:uniqueID];
	}
}

/*!
 * @brief Determine the arguments for a script execution
 *
 * @param inString The string of potential arguments
 * @param scriptDict The script being executed
 *
 * @result An NSArray of NSString instances
 */
- (NSArray *)_argumentsFromString:(NSString *)inString forScript:(NSMutableDictionary *)scriptDict
{
	NSArray			*scriptArguments = [scriptDict objectForKey:@"Arguments"];
	NSMutableArray	*argArray = [NSMutableArray array];
	NSArray			*inStringComponents = [inString componentsSeparatedByString:@","];
	
	NSUInteger		i = 0;
	NSUInteger		count = (scriptArguments ? [scriptArguments count] : 0);
	NSUInteger		inStringComponentsCount = [inStringComponents count];
	
	//Add each argument of inString to argArray so long as the number of arguments is less
	//than the number of expected arguments for the script and the number of supplied arguments
	while ((i < count) && (i < inStringComponentsCount)) {
		[argArray addObject:[inStringComponents objectAtIndex:i]];
		i++;
	}
	
	//If more components were passed than were actually requested, the last argument gets the
	//remainder
	if (i < inStringComponentsCount) {
		NSRange	remainingRange;
		
		//i was incremented to end the while loop if i > 0, so subtract 1 to reexamine the last object
		remainingRange.location = ((i > 0) ? i-1 : 0);
		remainingRange.length = (inStringComponentsCount - remainingRange.location);

		if (remainingRange.location != NSNotFound) {
			NSString	*lastArgument;

			//Remove that last, incomplete argument if it was added
			if ([argArray count]) [argArray removeLastObject];

			//Create the last argument by joining all remaining comma-separated arguments with a comma
			lastArgument = [[inStringComponents subarrayWithRange:remainingRange] componentsJoinedByString:@","];

			[argArray addObject:lastArgument];
		}
	}
	
	return argArray;
}

#pragma mark Toolbar item
/*!
 * @brief Register our insert script toolbar item
 */
- (void)registerToolbarItem
{
	MVMenuButton *button;
	
	//Unregister the existing toolbar item first
	if (toolbarItem) {
		[adium.toolbarController unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		toolbarItem = nil;
	}
	
	//Register our toolbar item
	button = [[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)];
	[button setImage:[NSImage imageNamed:@"msg-insert-script" forClass:[self class] loadLazily:YES]];
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SCRIPT_IDENTIFIER
														   label:AILocalizedString(@"Scripts",nil)
													paletteLabel:TITLE_INSERT_SCRIPT
														 toolTip:AILocalizedString(@"Insert a script",nil)
														  target:self
												 settingSelector:@selector(setView:)
													 itemContent:button
														  action:@selector(selectScript:)
															menu:nil];
	[toolbarItem setMinSize:NSMakeSize(32,32)];
	[toolbarItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:toolbarItem];
    [adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief After the toolbar has added the item we can set up the submenus
 */
- (void)toolbarWillAddItem:(NSNotification *)notification
{
	NSToolbarItem	*item = [[notification userInfo] objectForKey:@"item"];
	
	if (!notification || ([[item itemIdentifier] isEqualToString:SCRIPT_IDENTIFIER])) {
		NSMenu		*menu = [[scriptMenuItem submenu] copy];
		
		//Add menu to view
		[[item view] setMenu:menu];
		
		//Add menu to toolbar item (for text mode)
		NSMenuItem	*mItem = [[NSMenuItem alloc] init];
		[mItem setSubmenu:menu];
		[mItem setTitle:[menu title]];
		[item setMenuFormRepresentation:mItem];
	}
}

@end
