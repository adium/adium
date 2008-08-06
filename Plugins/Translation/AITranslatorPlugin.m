/*
 * AITranslatorPlugin.m
 * Adium
 *
 * Adapted for Adium from:
 * TranslationController.m
 * Fire
 *
 * Created by Alan Humpherys on Sat Feb 22 2003.
 * Copyright (c) 2003 Fire Development Team and/or epicware, Inc.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "AITranslatorPlugin.h"
#import "TranslationEngine.h"
#import "AIContentController.h"
#import "AIPreferenceController.h"
#import "AIMenuController.h"
#import "AIContactController.h"
#import <Adium/AIContentObject.h>
#import <Adium/AIAdiumProtocol.h>
#import <AIUtilities/AIStringUtilities.h> 
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import "AITranslatorOptionsWindowController.h"

#define MAX_SIMULTANEOUS_TRANSLATIONS 3

@interface AITranslatorPlugin (PRIVATE)
- (void)translateMessage:(NSDictionary *)messageDict;
@end

@implementation AITranslatorPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	[[adium contentController] registerDelayedContentFilter:self ofType:AIFilterContent direction:AIFilterOutgoing];
	[[adium contentController] registerDelayedContentFilter:self ofType:AIFilterContent direction:AIFilterIncoming];
	
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																					 @"en", @"LanguageToContact",
																					 @"en", @"LanguageFromContact", nil]
										  forGroup:@"Translator"];

	//Show offline contacts menu item
	NSMenuItem *menuItem;
    menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Translation Options", nil) stringByAppendingEllipsis]
										  target:self
										  action:@selector(showTranslationOptions:)
								   keyEquivalent:@""];
	[[adium menuController] addMenuItem:menuItem toLocation:LOC_Contact_Additions];
	[menuItem release];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[messages release];
	[engine release];

	[super dealloc];
}
#pragma mark Menu item
- (void)showTranslationOptions:(id)sender
{
    AIListObject   *selectedObject = [[adium interfaceController] selectedListObject];
	[AITranslatorOptionsWindowController showOptionsForListObject:selectedObject];
}

#pragma mark Filtering
/*!
 * @brief Called to give us a chance to translate messages
 *
 * @result YES if we began a delayed filtration (translation); NO if we did not
 */
- (BOOL)delayedFilterAttributedString:(NSAttributedString *)inAttributedString context:(id)context uniqueID:(unsigned long long)uniqueID
{
	BOOL beganTranslation = NO;
	
	if ([context isKindOfClass:[AIContentObject class]]) {
		AIContentObject *contentObject = (AIContentObject *)context;
		AIListObject	*listObject;
		NSString		*from;
		NSString		*to;
		
		if ([contentObject isOutgoing]) {
			listObject = [contentObject destination];
			from = [listObject preferenceForKey:@"LanguageToContact"
										  group:@"Translator"];
			to = [listObject preferenceForKey:@"LanguageFromContact"
										group:@"Translator"];
		} else {
			listObject = [contentObject source];

			from = [listObject preferenceForKey:@"LanguageFromContact"
										  group:@"Translator"];
			to = [listObject preferenceForKey:@"LanguageToContact"
										group:@"Translator"];
		}

		if (from && to && ![from isEqualToString:to]) {
			[self translateMessage:[NSDictionary dictionaryWithObjectsAndKeys:
				[inAttributedString string],	TC_MESSAGE_KEY,
				from,	TC_FROM_KEY,
				to,	TC_TO_KEY,
				inAttributedString, @"Attributed String",
				[NSNumber numberWithUnsignedLongLong:uniqueID], @"uniqueID",
				nil]];
			
			beganTranslation = TRUE;
		}
	}
	
	return beganTranslation;
}

/*!
 * @brief Filter priority
 *
 * Filter last so other filters have already run
 */
- (float)filterPriority
{
	return LOWEST_FILTER_PRIORITY;
}

#pragma mark Translation interface
- (void)prepareTranslation
{
	messages = [[NSMutableArray alloc] init];
	engine = [[TranslationEngine alloc] init];
	numberTranslating = 0;
}

- (void)_handleNextMessage
{
	if ((numberTranslating <= MAX_SIMULTANEOUS_TRANSLATIONS) && [messages count]) {
		NSDictionary	*messageDict;
		messageDict = [messages objectAtIndex:0];
		
		[messageDict retain];
		[messages removeObject:messageDict];
		
		numberTranslating++;
		[engine translate:messageDict notifyingTarget:self];
		
		[messageDict release];
	}
}

/*!
 * @brief Translate a message
 *
 * The message will be queued if appropriate; see -[self _handleNextMessage]
 */
- (void)translateMessage:(NSDictionary *)messageDict
{
	static BOOL preparedTranslation = NO;
	if (!preparedTranslation) {
		[self prepareTranslation];
		preparedTranslation = YES;
	}
	
    [messages addObject:messageDict];
    [self _handleNextMessage];
}

@end

// The following two methods are ONLY to be called by the translationEngine
// Calling them from other locations will result in incorrect behavior
@implementation AITranslatorPlugin (engineCallbacks)

- (void)translatedString:(NSString *)translatedString forMessageDict:(NSDictionary *)messageDict
{
	AILog(@"Translated %@ for %@",translatedString, messageDict);
	//We're done translating a message...
	numberTranslating--;

	//Start translating the next message immediately (if there is one)
	[self _handleNextMessage];
	
	// Finish processing this message
	NSMutableAttributedString *attributedString = [[messageDict objectForKey:@"Attributed String"] mutableCopy];
	if (translatedString) {
		/* Only replace the text with our translated string if we got one.
		 * We replace characters to maintain the formatting applied to the start of the attributed string.
		 */
		[attributedString replaceCharactersInRange:NSMakeRange(0, [attributedString length])
										withString:translatedString];
	}

	//Notify the content controller of the newly-translated string, passing the uniqueID for the message which we were originally given
	[[adium contentController] delayedFilterDidFinish:attributedString
											 uniqueID:[[messageDict objectForKey:@"uniqueID"] unsignedLongLongValue]];
    [attributedString release];
}

/*!
 * @brief A translation error occurred
 *
 * This is the last message we will received regarding the translation.
 */
- (void)translationError:(NSString *)errorMessage forMessageDict:(NSDictionary *)messageDict
{
	AILog(@"%@",[NSString stringWithFormat:NSLocalizedString(@"Translation Error: %@\nOriginal Message: \"%@\"",@"Parameters are <error msg>,<original msg>"),errorMessage,[messageDict objectForKey:TC_MESSAGE_KEY]]);

	//Pass a the original string as a result
	[self translatedString:[messageDict objectForKey:TC_MESSAGE_KEY] forMessageDict:messageDict];
}

@end
