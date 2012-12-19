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

#import "AIEmoticonController.h"
#import "AIEmoticon.h"
#import "AIEmoticonPack.h"
#import "AIEmoticonPreferences.h"
#import <Adium/AIContentObject.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AICharacterSetAdditions.h>
#import <Adium/AIContentEvent.h>

#define EMOTICON_DEFAULT_PREFS				@"EmoticonDefaults"
#define EMOTICONS_PATH_NAME					@"Emoticons"

//We support loading .AdiumEmoticonset, .emoticonPack, and .emoticons
#define ADIUM_EMOTICON_SET_PATH_EXTENSION   @"AdiumEmoticonset"
#define EMOTICON_PACK_PATH_EXTENSION		@"emoticonPack"
#define PROTEUS_EMOTICON_SET_PATH_EXTENSION @"emoticons"

@interface AIEmoticonController ()
- (NSDictionary *)emoticonIndex;
- (NSCharacterSet *)emoticonHintCharacterSet;
- (NSCharacterSet *)emoticonStartCharacterSet;
- (void)resetActiveEmoticons;
- (void)resetAvailableEmoticons;
- (NSMutableAttributedString *)_convertEmoticonsInMessage:(NSAttributedString *)inMessage context:(id)context;
- (AIEmoticon *) _bestReplacementFromEmoticons:(NSArray *)candidateEmoticons
							   withEquivalents:(NSArray *)candidateEmoticonTextEquivalents
									   context:(NSString *)serviceClassContext
									equivalent:(NSString **)replacementString
							  equivalentLength:(NSInteger *)textLength;
- (void)_buildCharacterSetsAndIndexEmoticons;
- (void)_saveActiveEmoticonPacks;
- (void)_saveEmoticonPackOrdering;
- (NSString *)_keyForPack:(AIEmoticonPack *)inPack;
- (void)_sortArrayOfEmoticonPacks:(NSMutableArray *)packArray;
@end

NSInteger packSortFunction(id packA, id packB, void *packOrderingArray);

@implementation AIEmoticonController

#define EMOTICONS_THEMABLE_PREFS      @"Emoticon Themable Prefs"

//init
- (id)init
{
	if ((self = [super init])) {
		observingContent = NO;
		_availableEmoticonPacks = nil;
		_activeEmoticonPacks = nil;
		_activeEmoticons = nil;
		_emoticonHintCharacterSet = nil;
		_emoticonStartCharacterSet = nil;
		_emoticonIndexDict = nil;
	}
	
	return self;
}

- (void)controllerDidLoad
{
    //Create the custom emoticons directory
    [adium createResourcePathForName:EMOTICONS_PATH_NAME];
    
    //Setup Preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:@"EmoticonDefaults" 
																		forClass:[self class]]
										  forGroup:PREF_GROUP_EMOTICONS];
    
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_EMOTICONS];
	
	//Observe for installation of new emoticon sets
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:AIXtrasDidChangeNotification
									 object:nil];
}

- (void)controllerWillClose
{
	[adium.contentController unregisterContentFilter:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Flush our cached active emoticons
	[self resetActiveEmoticons];
	
	//Enable/Disable logging
	BOOL    emoticonsEnabled = ([[self activeEmoticons] count] != 0);
	if (observingContent != emoticonsEnabled) {
		if (emoticonsEnabled) {
			[adium.contentController registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterIncoming];
			[adium.contentController registerContentFilter:self ofType:AIFilterDisplay direction:AIFilterOutgoing];
			[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
			[adium.contentController registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
			[adium.contentController registerContentFilter:self ofType:AIFilterTooltips direction:AIFilterIncoming];

		} else {
			[adium.contentController unregisterContentFilter:self];
		}
		observingContent = emoticonsEnabled;
	}
}


//Content filter -------------------------------------------------------------------------------------------------------
#pragma mark Content filter
//Filter a content object before display, inserting graphical emoticons
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString   *replacementMessage = nil;
		// We want to filter some status event messages (e.g. changes in status messages), but not fileTransfer messages.
		// Filenames, afterall, should not have emoticons in them.
    if (inAttributedString &&
				!([context isKindOfClass:[AIContentEvent class]] &&
					[[(AIContentEvent *)context type] rangeOfString:@"fileTransfer"].location == NSNotFound)) {
        /* First, we do a quick scan of the message for any characters that might end up being emoticons
         * This avoids having to do the slower, more complicated scan for the majority of messages.
		 *
		 * We also look for emoticons if this messsage is for a chat and it has one or more custom emoticons
		 */
        if (([[inAttributedString string] rangeOfCharacterFromSet:[self emoticonHintCharacterSet]].location != NSNotFound) ||
			([context isKindOfClass:[AIContentObject class]] && ([[(AIContentObject *)context chat] customEmoticons]))){
            //If an emoticon character was found, we do a more thorough scan
            replacementMessage = [self _convertEmoticonsInMessage:inAttributedString context:context];
        }
    }
    return (replacementMessage ? replacementMessage : inAttributedString);
}

//Do emoticons after the default filters
- (CGFloat)filterPriority
{
	return LOW_FILTER_PRIORITY;
}

/*!
 * @brief Perform a single emoticon replacement
 *
 * This method may call itself recursively to perform additional adjacent emoticon replacements
 *
 * @result The location in messageString of the beginning of the emoticon replaced, or NSNotFound if no replacement was made
 */
- (NSUInteger)replaceAnEmoticonStartingAtLocation:(NSUInteger *)currentLocation
										 fromString:(NSString *)messageString
								messageStringLength:(NSUInteger)messageStringLength
						   originalAttributedString:(NSAttributedString *)originalAttributedString
										 intoString:(NSMutableAttributedString **)newMessage
								   replacementCount:(NSUInteger *)replacementCount
								 callingRecursively:(BOOL)callingRecursively
								serviceClassContext:(id)serviceClassContext
						  emoticonStartCharacterSet:(NSCharacterSet *)emoticonStartCharacterSet
									  emoticonIndex:(NSDictionary *)emoticonIndex
										  isMessage:(BOOL)isMessage
{
	NSUInteger	originalEmoticonLocation = NSNotFound;

	//Find the next occurence of a suspected emoticon
	*currentLocation = [messageString rangeOfCharacterFromSet:emoticonStartCharacterSet
													  options:NSLiteralSearch
														range:NSMakeRange(*currentLocation, 
																		  messageStringLength - *currentLocation)].location;
	if (*currentLocation != NSNotFound) {
		//Use paired arrays so multiple emoticons can qualify for the same text equivalent
		NSMutableArray  *candidateEmoticons = nil;
		NSMutableArray  *candidateEmoticonTextEquivalents = nil;		
		unichar         currentCharacter = [messageString characterAtIndex:*currentLocation];
		NSString        *currentCharacterString = [NSString stringWithFormat:@"%C", currentCharacter];

		//Check for the presence of all emoticons starting with this character
		for (AIEmoticon *emoticon in [emoticonIndex objectForKey:currentCharacterString]) {			
			for (NSString *text in [emoticon textEquivalents]) {
				NSInteger     textLength = [text length];
				
				if (textLength != 0) { //Invalid emoticon files may let empty text equivalents sneak in
									   //If there is not enough room in the string for this text, we can skip it
					if (*currentLocation + textLength <= messageStringLength) {
						if ([messageString compare:text
										   options:NSLiteralSearch
											 range:NSMakeRange(*currentLocation, textLength)] == NSOrderedSame) {
							//Ignore emoticons within links
							if ([originalAttributedString attribute:NSLinkAttributeName
															atIndex:*currentLocation
													 effectiveRange:nil] == nil) {
								if (!candidateEmoticons) {
									candidateEmoticons = [[NSMutableArray alloc] init];
									candidateEmoticonTextEquivalents = [[NSMutableArray alloc] init];
								}
								
								[candidateEmoticons addObject:emoticon];
								[candidateEmoticonTextEquivalents addObject:text];
							}
						}
					}
				}
			}
		}

		BOOL currentLocationNeedsUpdate = YES;

		if ([candidateEmoticons count]) {
			NSString					*replacementString;
			NSMutableAttributedString   *replacement;
			NSInteger					textLength;
			NSRange						emoticonRangeInNewMessage;

			originalEmoticonLocation = *currentLocation;

			//Use the most appropriate, longest string of those which could be used for the emoticon text we found here
			AIEmoticon *emoticon = [self _bestReplacementFromEmoticons:candidateEmoticons
										   withEquivalents:candidateEmoticonTextEquivalents
												   context:serviceClassContext
												equivalent:&replacementString
										  equivalentLength:&textLength];
			emoticonRangeInNewMessage = NSMakeRange(*currentLocation - *replacementCount, textLength);
			
			/* We want to show this emoticon if there is:
			 *		It begins or ends the string
			 *		It is bordered by spaces or line breaks or quotes on both sides
			 *		It is bordered by a period on the left and a space or line break or quote the right
			 *		It is bordered by emoticons on both sides or by an emoticon on the left and a period, space, or line break on the right
			 */
			BOOL	acceptable = NO;
			if ((messageStringLength == ((originalEmoticonLocation + textLength))) || //Ends the string
				(originalEmoticonLocation == 0)) { //Begins the string
				acceptable = YES;
			}
			if (!acceptable) {
				/* Bordered by spaces or line breaks or quotes, or by a period on the left and a space or a line break or quote on the right
				 * If we're being called recursively, we have a potential emoticon to our left;  we only need to check the right.
				 * This is also true if we're not being called recursively but there's an NSAttachmentAttribute to our left.
				 *		That will happen if, for example, the string is ":):) ". The first emoticon is at the start of the line and
				 *		so is immediately acceptable. The second should be acceptable because it is to the right of an emoticon and
				 *		the left of a space.
				 */
				char	previousCharacter = [messageString characterAtIndex:(originalEmoticonLocation - 1)] ;
				char	nextCharacter = [messageString characterAtIndex:(originalEmoticonLocation + textLength)] ;

				if ((callingRecursively || (previousCharacter == ' ') || (previousCharacter == '\t') ||
					 (previousCharacter == '\n') || (previousCharacter == '\r') || (previousCharacter == '.') || (previousCharacter == '?') || (previousCharacter == '!') ||
					 (previousCharacter == '\"') || (previousCharacter == '\'') ||
					 (previousCharacter == '(') || (previousCharacter == '*') ||
					 (*newMessage && [*newMessage attribute:NSAttachmentAttributeName
													atIndex:(emoticonRangeInNewMessage.location - 1) 
											 effectiveRange:NULL])) &&

					((nextCharacter == ' ') || (nextCharacter == '\t') || (nextCharacter == '\n') || (nextCharacter == '\r') ||
					 (nextCharacter == '.') || (nextCharacter == ',') || (nextCharacter == '?') || (nextCharacter == '!') ||
					 (nextCharacter == ')') || (nextCharacter == '*') ||
					 (nextCharacter == '\"') || (nextCharacter == '\''))) {
					acceptable = YES;
				}
			}
			if (!acceptable) {
				/* If the emoticon would end the string except for whitespace, newlines, or punctionation at the end, or it begins the string after removing
				 * whitespace, newlines, or punctuation at the beginning, it is acceptable even if the previous conditions weren't met.
				 */
				NSCharacterSet *endingTrimSet = nil;
				static NSMutableDictionary *endingSetDict = nil;
				if(!endingSetDict) {
					endingSetDict = [[NSMutableDictionary alloc] initWithCapacity:10];
				}
				if (!(endingTrimSet = [endingSetDict objectForKey:replacementString])) {
					NSMutableCharacterSet *tempSet = [[NSCharacterSet punctuationCharacterSet] mutableCopy];
					[tempSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
					[tempSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
					//remove any characters *in* the replacement string from the trimming set
					[tempSet removeCharactersInString:replacementString];
					[endingSetDict setObject:[tempSet immutableCopy] forKey:replacementString];
					endingTrimSet = [endingSetDict objectForKey:replacementString];
				}

				NSString	*trimmedString = [messageString stringByTrimmingCharactersInSet:endingTrimSet];
				NSUInteger trimmedLength = [trimmedString length];
				if (trimmedLength == (originalEmoticonLocation + textLength)) {
					// Replace at end of string
					acceptable = YES;
				} else if ([trimmedString characterAtIndex:0] == [replacementString characterAtIndex:0]) {
					// Replace at start of string
					acceptable = YES;					
				}
			}
			if (!acceptable) {
				/* If we still haven't determined it to be acceptable, look ahead.
				 * If we do a replacement adjacent to this emoticon, we can do this one, too.
				 */
				NSUInteger newCurrentLocation = *currentLocation;
				NSUInteger nextEmoticonLocation;
						
				/* Call ourself recursively, starting just after the end of the current emoticon candidate
				 * If the return value is not NSNotFound, an emoticon was found and replaced ahead of us. Discontinuous searching for the win.
				 */
				newCurrentLocation += textLength;
				nextEmoticonLocation = [self replaceAnEmoticonStartingAtLocation:&newCurrentLocation
																	  fromString:messageString
															 messageStringLength:messageStringLength
														originalAttributedString:originalAttributedString
																	  intoString:newMessage
																replacementCount:replacementCount
															  callingRecursively:YES
															 serviceClassContext:serviceClassContext
													   emoticonStartCharacterSet:emoticonStartCharacterSet
																   emoticonIndex:emoticonIndex
																	   isMessage:isMessage];
				if (nextEmoticonLocation != NSNotFound) {
					if (nextEmoticonLocation == (*currentLocation + textLength)) {
						/* The next emoticon is immediately after the candidate we're looking at right now. That means
						* our current candidate is in fact an emoticon (since it borders another emoticon).
						*/
						acceptable = YES;
					}
					
					currentLocationNeedsUpdate = NO;
					*currentLocation = newCurrentLocation;
				} else {
					/* If there isn't a next emoticon, we can skip ahead to the end of the string. */			
					*currentLocation = messageStringLength;
					currentLocationNeedsUpdate = NO;
				}
			}

			if (acceptable) {
				replacement = [emoticon attributedStringWithTextEquivalent:replacementString attachImages:!isMessage];
				
				NSDictionary *originalAttributes = [originalAttributedString attributesAtIndex:originalEmoticonLocation
																				effectiveRange:nil];
				
				originalAttributes = [originalAttributes dictionaryWithDifferenceWithSetOfKeys:[NSSet setWithObject:NSAttachmentAttributeName]];
				
				//grab the original attributes, to ensure that the background is not lost in a message consisting only of an emoticon
				[replacement addAttributes:originalAttributes
									 range:NSMakeRange(0,1)];
				
				//insert the emoticon
				if (!(*newMessage)) *newMessage = [originalAttributedString mutableCopy];
				[*newMessage replaceCharactersInRange:emoticonRangeInNewMessage
								 withAttributedString:replacement];
				
				//Update where we are in the original and replacement messages
				*replacementCount += textLength-1;
				
				if (currentLocationNeedsUpdate)
					*currentLocation += textLength-1;
			} else {
				//Didn't find an acceptable emoticon, so we should return NSNotFound
				originalEmoticonLocation = NSNotFound;
			}			
		}

		//Always increment the loop
		if (currentLocationNeedsUpdate) {
			*currentLocation += 1;
		}
	}

	return originalEmoticonLocation;
}

//Insert graphical emoticons into a string
- (NSAttributedString *)_convertEmoticonsInMessage:(NSAttributedString *)inMessage context:(id)context
{
    NSString                    *messageString = [inMessage string];
    NSMutableAttributedString   *newMessage = nil; //We avoid creating a new string unless necessary
	NSString					*serviceClassContext = nil;
    NSUInteger					currentLocation = 0, messageStringLength;
	NSCharacterSet				*emoticonStartCharacterSet = self.emoticonStartCharacterSet;
	NSDictionary				*emoticonIndex = self.emoticonIndex;
	//we can avoid loading images if the emoticon is headed for the wkmv, since it will just load from the original path anyway
	BOOL						isMessage = NO;  

	//Determine our service class context
	if ([context isKindOfClass:[AIContentObject class]]) {
		isMessage = YES;
		serviceClassContext = ((AIContentObject *)context).destination.service.serviceClass;
		//If there's no destination, try to use the source for context
		if (!serviceClassContext) {
			serviceClassContext = ((AIContentObject *)context).source.service.serviceClass;
		}
		
		//Expand our emoticon information to include any custom emoticons in this chat
		NSSet *customEmoticons = ((AIContentObject *)context).chat.customEmoticons;
		if (customEmoticons && !((AIContentObject *)context).isOutgoing) {
			/* XXX Note that we only display custom emoticons for incoming messages; we can not set our own custom emotcions
			 * at this time
			 */
			NSMutableCharacterSet	*newEmoticonStartCharacterSet = [emoticonStartCharacterSet mutableCopy];
			NSMutableDictionary		*newEmoticonIndex = [emoticonIndex mutableCopy];

			AIEmoticon	 *emoticon;
			
			for (emoticon in customEmoticons) {
				for (NSString *textEquivalent in emoticon.textEquivalents) {
					if (textEquivalent.length) {
						NSMutableArray	*subIndex;
						NSString		*firstCharacterString;

						firstCharacterString = [NSString stringWithFormat:@"%C",[textEquivalent characterAtIndex:0]];

						//'First characters' set
						[newEmoticonStartCharacterSet addCharactersInString:firstCharacterString];
						
						// -- Index --
						//Get the index according to this emoticon's first character
						if ((subIndex = [newEmoticonIndex objectForKey:firstCharacterString])) {
							subIndex = [subIndex mutableCopy];
						} else {
							subIndex = [[NSMutableArray alloc] init];
						}
						
						[newEmoticonIndex setObject:subIndex forKey:firstCharacterString];
						
						//Place the emoticon into that index (If it isn't already in there)
						if (![subIndex containsObject:emoticon]) {
							[subIndex addObject:emoticon];
						}
					}
				}
			}
			
			//Use our new index and character set for processing emoticons in this message
			emoticonIndex = newEmoticonIndex;
			emoticonStartCharacterSet = newEmoticonStartCharacterSet;
		}

	} else if ([context isKindOfClass:[AIListContact class]]) {
		serviceClassContext = [[[adium.accountController preferredAccountForSendingContentType:CONTENT_MESSAGE_TYPE
																					   toContact:(AIListContact *)context] service] serviceClass];
	} else if ([context isKindOfClass:[AIListObject class]] && [context respondsToSelector:@selector(service)]) {
		serviceClassContext = ((AIListObject *)context).service.serviceClass;
	}
	
    //Number of characters we've replaced so far (used to calcluate placement in the destination string)
	NSUInteger	replacementCount = 0; 

	messageStringLength = [messageString length];
    while (currentLocation != NSNotFound && currentLocation < messageStringLength) {
		[self replaceAnEmoticonStartingAtLocation:&currentLocation
									   fromString:messageString
							  messageStringLength:messageStringLength
						 originalAttributedString:inMessage
									   intoString:&newMessage
								 replacementCount:&replacementCount
							   callingRecursively:NO
							  serviceClassContext:serviceClassContext
						emoticonStartCharacterSet:emoticonStartCharacterSet
									emoticonIndex:emoticonIndex
										isMessage:isMessage];
    }

    return (newMessage ? newMessage : inMessage);
}

- (AIEmoticon *) _bestReplacementFromEmoticons:(NSArray *)candidateEmoticons
							   withEquivalents:(NSArray *)candidateEmoticonTextEquivalents
									   context:(NSString *)serviceClassContext
									equivalent:(NSString **)replacementString
							  equivalentLength:(NSInteger *)textLength
{
	NSUInteger	i = 0;
	NSUInteger	bestIndex = 0, bestLength = 0;
	NSUInteger	bestServiceAppropriateIndex = 0, bestServiceAppropriateLength = 0;
	NSString	*serviceAppropriateReplacementString = nil;
	NSUInteger	count;
	
	count = [candidateEmoticonTextEquivalents count];
	while (i < count) {
		NSString	*thisString = [candidateEmoticonTextEquivalents objectAtIndex:i];
		NSUInteger thisLength = [thisString length];
		if (thisLength > bestLength) {
			bestLength = thisLength;
			bestIndex = i;
			*replacementString = thisString;
		}

		//If we are using service appropriate emoticons, check if this is on the right service and, if so, compare.
		if (thisLength > bestServiceAppropriateLength) {
			AIEmoticon	*thisEmoticon = [candidateEmoticons objectAtIndex:i];
			if ([thisEmoticon isAppropriateForServiceClass:serviceClassContext]) {
				bestServiceAppropriateLength = thisLength;
				bestServiceAppropriateIndex = i;
				serviceAppropriateReplacementString = thisString;
			}
		}
		
		i++;
	}

	/* Did we get a service appropriate replacement? If so, use that rather than the current replacementString if it
	 * differs. */
	if (serviceAppropriateReplacementString && (serviceAppropriateReplacementString != *replacementString)) {
		bestLength = bestServiceAppropriateLength;
		bestIndex = bestServiceAppropriateIndex;
		*replacementString = serviceAppropriateReplacementString;
	}

	//Return the length by reference
	*textLength = bestLength;

	//Return the AIEmoticon we found to be best
    return [candidateEmoticons objectAtIndex:bestIndex];
}

//Active emoticons -----------------------------------------------------------------------------------------------------
#pragma mark Active emoticons
//Returns an array of the currently active emoticons
- (NSArray *)activeEmoticons
{
    if (!_activeEmoticons) {
        _activeEmoticons = [[NSMutableArray alloc] init];
		
        //Grap the emoticons from each active pack
        for (AIEmoticonPack *emoticonPack in [self activeEmoticonPacks]) {
            [_activeEmoticons addObjectsFromArray:[emoticonPack emoticons]];
        }
    }
	
    //
    return _activeEmoticons;
}

//Returns all active emoticons, categoriezed by starting character, using a dictionary, with each value containing an array of characters
- (NSDictionary *)emoticonIndex
{
    if (!_emoticonIndexDict) [self _buildCharacterSetsAndIndexEmoticons];
    return _emoticonIndexDict;
}


//Disabled emoticons ---------------------------------------------------------------------------------------------------
#pragma mark Disabled emoticons
//Enabled or disable a specific emoticon
- (void)setEmoticon:(AIEmoticon *)inEmoticon inPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled
{
    NSString                *packKey = [self _keyForPack:inPack];
    NSMutableDictionary     *packDict = [[adium.preferenceController preferenceForKey:packKey
																				  group:PREF_GROUP_EMOTICONS] mutableCopy];
    NSMutableArray          *disabledArray = [[packDict objectForKey:KEY_EMOTICON_DISABLED] mutableCopy];
	
    if (!packDict) packDict = [[NSMutableDictionary alloc] init];
    if (!disabledArray) disabledArray = [[NSMutableArray alloc] init];
    
    //Enable/Disable the emoticon
    if (enabled) {
        [disabledArray removeObject:[inEmoticon name]];
    } else {
        [disabledArray addObject:[inEmoticon name]];
    }
    
    //Update the pack (This should really be done from the prefs changed method, but it works here as well)
    [inPack setDisabledEmoticons:disabledArray];
    
    //Save changes
    [packDict setObject:disabledArray forKey:KEY_EMOTICON_DISABLED];

    [adium.preferenceController setPreference:packDict forKey:packKey group:PREF_GROUP_EMOTICONS];
}

//Returns the disabled emoticons in a pack
- (NSArray *)disabledEmoticonsInPack:(AIEmoticonPack *)inPack
{
    NSDictionary    *packDict = [adium.preferenceController preferenceForKey:[self _keyForPack:inPack]
																		 group:PREF_GROUP_EMOTICONS];
    
    return [packDict objectForKey:KEY_EMOTICON_DISABLED];
}


//Active emoticon packs ------------------------------------------------------------------------------------------------
#pragma mark Active emoticon packs
//Returns an array of the currently active emoticon packs
- (NSArray *)activeEmoticonPacks
{
    if (!_activeEmoticonPacks) {
        NSArray         *activePackNames;
        NSString        *packName;
        
        //
        _activeEmoticonPacks = [[NSMutableArray alloc] init];
        
        //Get the names of our active packs
        activePackNames = [adium.preferenceController preferenceForKey:KEY_EMOTICON_ACTIVE_PACKS
																   group:PREF_GROUP_EMOTICONS];
        //Use the names to build an array of the desired emoticon packs
        for (packName in activePackNames) {
            AIEmoticonPack  *emoticonPack = [self emoticonPackWithName:packName];
            
            if (emoticonPack) {
                [_activeEmoticonPacks addObject:emoticonPack];
				[emoticonPack setIsEnabled:YES];
            }
        }
		
		//Sort as per the saved ordering
		[self _sortArrayOfEmoticonPacks:_activeEmoticonPacks];
    }

    return _activeEmoticonPacks;
}

- (void)setEmoticonPack:(AIEmoticonPack *)inPack enabled:(BOOL)enabled
{
	if (enabled) {
		[_activeEmoticonPacks addObject:inPack];	
		[inPack setIsEnabled:YES];
		
		//Sort the active emoticon packs as per the saved ordering
		[self _sortArrayOfEmoticonPacks:_activeEmoticonPacks];
	} else {
		[_activeEmoticonPacks removeObject:inPack];
		[inPack setIsEnabled:NO];
	}
	
	//Save
	[self _saveActiveEmoticonPacks];
}

//Save the active emoticon packs to preferences
- (void)_saveActiveEmoticonPacks
{
    NSMutableArray  *nameArray = [NSMutableArray array];
    
	for (AIEmoticonPack *emoticonPack in [self activeEmoticonPacks]) {
        [nameArray addObject:emoticonPack.name];
    }
    
    [adium.preferenceController setPreference:nameArray forKey:KEY_EMOTICON_ACTIVE_PACKS group:PREF_GROUP_EMOTICONS];
}


//Available emoticon packs ---------------------------------------------------------------------------------------------
#pragma mark Available emoticon packs
//Returns an array of the available emoticon packs
- (NSArray *)availableEmoticonPacks
{
    if (!_availableEmoticonPacks) {
        _availableEmoticonPacks = [[NSMutableArray alloc] init];
        
		//Load emoticon packs		
		for (NSString *path in [adium allResourcesForName:EMOTICONS_PATH_NAME
										   withExtensions:[NSArray arrayWithObjects:
														   EMOTICON_PACK_PATH_EXTENSION,
														   ADIUM_EMOTICON_SET_PATH_EXTENSION,
														   PROTEUS_EMOTICON_SET_PATH_EXTENSION,
														   nil]]) {
			AIEmoticonPack  *pack = [AIEmoticonPack emoticonPackFromPath:path];
			
			if (pack.emoticons.count) {
				[_availableEmoticonPacks addObject:pack];
				[pack setDisabledEmoticons:[self disabledEmoticonsInPack:pack]];
			}
		}
		
		//Sort as per the saved ordering
		[self _sortArrayOfEmoticonPacks:_availableEmoticonPacks];

		//Build the list of active packs
		[self activeEmoticonPacks];
    }
    
    return _availableEmoticonPacks;
}

//Returns the emoticon pack by name
- (AIEmoticonPack *)emoticonPackWithName:(NSString *)inName
{
    for (AIEmoticonPack *emoticonPack in self.availableEmoticonPacks) {
        if ([emoticonPack.name isEqualToString:inName]) return emoticonPack;
    }
	
    return nil;
}

- (void)xtrasChanged:(NSNotification *)notification
{
	if (notification == nil || [[notification object] caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame) {
		[self resetAvailableEmoticons];
		[prefs emoticonXtrasDidChange];
	}
}


//Pack ordering --------------------------------------------------------------------------------------------------------
#pragma mark Pack ordering
//Re-arrange an emoticon pack
- (void)moveEmoticonPacks:(NSArray *)inPacks toIndex:(NSUInteger)idx
{        
    //Remove each pack
    for (AIEmoticonPack *pack in inPacks) {
        if ([_availableEmoticonPacks indexOfObject:pack] < idx) idx--;
        [_availableEmoticonPacks removeObject:pack];
    }
	
    //Add back the packs in their new location
    for (AIEmoticonPack *pack in inPacks) {
        [_availableEmoticonPacks insertObject:pack atIndex:idx];
        idx++;
    }
	
    //Save our new ordering
    [self _saveEmoticonPackOrdering];
}

- (void)_saveEmoticonPackOrdering
{
    NSMutableArray		*nameArray = [NSMutableArray array];
    
    for (AIEmoticonPack *pack in self.availableEmoticonPacks) {
        [nameArray addObject:pack.name];
    }
    
	//Changing a preference will clear out our premade _activeEmoticonPacks array
    [adium.preferenceController setPreference:nameArray forKey:KEY_EMOTICON_PACK_ORDERING group:PREF_GROUP_EMOTICONS];	
}

- (void)_sortArrayOfEmoticonPacks:(NSMutableArray *)packArray
{
	//Load the saved ordering and sort the active array based on it
	NSArray *packOrderingArray = [adium.preferenceController preferenceForKey:KEY_EMOTICON_PACK_ORDERING 
																		  group:PREF_GROUP_EMOTICONS];
	//It's most likely quicker to create an empty array here than to do nil checks each time through the sort function
	if (!packOrderingArray)
		packOrderingArray = [NSArray array];
	[packArray sortUsingFunction:packSortFunction context:(__bridge void *)packOrderingArray];
}

NSInteger packSortFunction(id packA, id packB, void *packOrderingArray)
{
	NSInteger packAIndex = [(__bridge NSArray *)packOrderingArray indexOfObject:[packA name]];
	NSInteger packBIndex = [(__bridge NSArray *)packOrderingArray indexOfObject:[packB name]];
	
	BOOL notFoundA = (packAIndex == NSNotFound);
	BOOL notFoundB = (packBIndex == NSNotFound);
	
	//Packs which aren't in the ordering index sort to the bottom
	if (notFoundA && notFoundB) {
		return ([[packA name] compare:[packB name]]);
		
	} else if (notFoundA) {
		return (NSOrderedDescending);
		
	} else if (notFoundB) {
		return (NSOrderedAscending);
		
	} else if (packAIndex > packBIndex) {
		return NSOrderedDescending;
		
	} else {
		return NSOrderedAscending;
		
	}
}


//Character hints for efficiency ---------------------------------------------------------------------------------------
#pragma mark Character hints for efficiency
//Returns a characterset containing characters that hint at the presence of an emoticon
- (NSCharacterSet *)emoticonHintCharacterSet
{
    if (!_emoticonHintCharacterSet) [self _buildCharacterSetsAndIndexEmoticons];
    return _emoticonHintCharacterSet;
}

//Returns a characterset containing all the characters that may start an emoticon
- (NSCharacterSet *)emoticonStartCharacterSet
{
    if (!_emoticonStartCharacterSet) [self _buildCharacterSetsAndIndexEmoticons];
    return _emoticonStartCharacterSet;
}

//For optimization, we build a list of characters that could possibly be an emoticon and will require additional scanning.
//We also build a dictionary categorizing the emoticons by their first character to quicken lookups.
- (void)_buildCharacterSetsAndIndexEmoticons
{    
    //Start with a fresh character set, and a fresh index
	NSMutableCharacterSet	*tmpEmoticonHintCharacterSet = [[NSMutableCharacterSet alloc] init];
	NSMutableCharacterSet	*tmpEmoticonStartCharacterSet = [[NSMutableCharacterSet alloc] init];

	_emoticonIndexDict = [[NSMutableDictionary alloc] init];
    
    //Process all the text equivalents of each active emoticon
    for (AIEmoticon *emoticon in self.activeEmoticons) {
        if (emoticon.isEnabled) {			
            for (NSString *text in emoticon.textEquivalents) {
                NSMutableArray  *subIndex;
                unichar         firstCharacter;
                NSString        *firstCharacterString;
                
                if ([text length] != 0) { //Invalid emoticon files may let empty text equivalents sneak in
                    firstCharacter = [text characterAtIndex:0];
                    firstCharacterString = [NSString stringWithFormat:@"%C",firstCharacter];
                    
                    // -- Emoticon Hint Character Set --
                    //If any letter in this text equivalent already exists in the quick scan character set, we can skip it
                    if ([text rangeOfCharacterFromSet:tmpEmoticonHintCharacterSet].location == NSNotFound) {
                        //Potential for optimization!: Favor punctuation characters ( :();- ) over letters (especially vowels).                
                        [tmpEmoticonHintCharacterSet addCharactersInString:firstCharacterString];
                    }
                    
                    // -- Emoticon Start Character Set --
                    //First letter of this emoticon goes in the start set
                    if (![tmpEmoticonStartCharacterSet characterIsMember:firstCharacter]) {
                        [tmpEmoticonStartCharacterSet addCharactersInString:firstCharacterString];
                    }
                    
                    // -- Index --
                    //Get the index according to this emoticon's first character
                    if (!(subIndex = [_emoticonIndexDict objectForKey:firstCharacterString])) {
                        subIndex = [[NSMutableArray alloc] init];
                        [_emoticonIndexDict setObject:subIndex forKey:firstCharacterString];
                    }
                    
                    //Place the emoticon into that index (If it isn't already in there)
                    if (![subIndex containsObject:emoticon]) {
						//Keep emoticons in order from largest to smallest.  This prevents icons that contain other
						//icons from being masked by the smaller icons they contain.
						//This cannot work unless the emoticon equivelents are broken down.
						/*
						for (int i = 0;i < [subIndex count]; i++) {
							if ([subIndex objectAtIndex:i] equivelentLength] < ourLength]) break;
						}*/
                        
						//Instead of adding the emoticon, add all of its equivalents... ?
						
						[subIndex addObject:emoticon];
                    }
                }
            }
            
        }
    }

	_emoticonHintCharacterSet = [tmpEmoticonHintCharacterSet immutableCopy];

    _emoticonStartCharacterSet = [tmpEmoticonStartCharacterSet immutableCopy];

	//After building all the subIndexes, sort them by length here
}


//Cache flushing -------------------------------------------------------------------------------------------------------
#pragma mark Cache flushing
//Flush any cached emoticon images (and image attachment strings)
- (void)flushEmoticonImageCache
{    
	for (AIEmoticonPack *pack in self.availableEmoticonPacks) {
        [pack flushEmoticonImageCache];
    }
}

//Reset the active emoticons cache
- (void)resetActiveEmoticons
{
    _activeEmoticonPacks = nil;
    
    _activeEmoticons = nil;
    
    _emoticonHintCharacterSet = nil;
    _emoticonStartCharacterSet = nil;
    _emoticonIndexDict = nil;
}

//Reset the available emoticons cache
- (void)resetAvailableEmoticons
{
    _availableEmoticonPacks = nil;
    [self resetActiveEmoticons];
}


//Private --------------------------------------------------------------------------------------------------------------
#pragma mark Private
- (NSString *)_keyForPack:(AIEmoticonPack *)inPack
{
	return [NSString stringWithFormat:@"Pack:%@",[inPack name]];
}

@end
