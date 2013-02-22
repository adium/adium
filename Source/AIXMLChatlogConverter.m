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

#import "AIXMLChatlogConverter.h"
#import "AIStandardListWindowController.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/NSCalendarDate+ISO8601Parsing.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define PREF_GROUP_WEBKIT_MESSAGE_DISPLAY		@"WebKit Message Display"
#define KEY_WEBKIT_USE_NAME_FORMAT				@"Use Custom Name Format"
#define KEY_WEBKIT_NAME_FORMAT					@"Name Format"

@interface NSMutableString (XMLMethods)
- (void)stripInvalidCharacters;
@end

@implementation NSMutableString (XMLMethods)

//Strip invalid XML characters
- (void)stripInvalidCharacters
{
    static NSCharacterSet *invalidXMLCharacterSet;
    
    if (invalidXMLCharacterSet == nil)
    {
        // First, create a character set containing all valid UTF8 characters.
        NSMutableCharacterSet *xmlCharacterSet = [[NSMutableCharacterSet alloc] init];        
        [xmlCharacterSet addCharactersInRange:NSMakeRange(0x9, 1)];       
        [xmlCharacterSet addCharactersInRange:NSMakeRange(0xA, 1)];        
        [xmlCharacterSet addCharactersInRange:NSMakeRange(0xD, 1)];        
        [xmlCharacterSet addCharactersInRange:NSMakeRange(0x20, 0xD7FF - 0x20)];
        [xmlCharacterSet addCharactersInRange:NSMakeRange(0xE000, 0xFFFD - 0xE000)];        
        [xmlCharacterSet addCharactersInRange:NSMakeRange(0x10000, 0x10FFFF - 0x10000)];        
        // Then create and retain an inverted set, which will thus contain all invalid XML characters.        
        invalidXMLCharacterSet = [[xmlCharacterSet invertedSet] retain];        
        [xmlCharacterSet release];        
    }
    
    // Are there any invalid characters in this string?    
    NSRange range = [self rangeOfCharacterFromSet:invalidXMLCharacterSet];
    
    // Otherwise go through and remove any illegal XML characters from a copy of the string.
    while (range.length > 0)
    {        
        [self deleteCharactersInRange:range];
        range = [self rangeOfCharacterFromSet:invalidXMLCharacterSet                 
                                      options:0                 
                                        range:NSMakeRange(range.location,[self length]-range.location)];        
    }    
}

@end

@interface NSXMLElement (AIAttributeDict)
- (NSDictionary *)AIAttributesAsDictionary;
@end

@implementation NSXMLElement (AIAttributeDict)

- (NSDictionary *)AIAttributesAsDictionary 
{
    NSArray *attrArray = [self attributes];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    for (NSXMLNode *attr in attrArray) {
        [attributes setObject:attr forKey:[attr name]];
    }
    return attributes;
}

@end

@interface AIXMLChatlogConverter()
- (NSAttributedString *)readData:(NSData *)xmlData withOptions:(NSDictionary *)options retrying:(BOOL)reentrancyFlag;
@end

@implementation AIXMLChatlogConverter

+ (NSAttributedString *)readFile:(NSString *)filePath withOptions:(NSDictionary *)options
{
	static AIXMLChatlogConverter *converter;
    if (!converter) {
        converter = [[AIXMLChatlogConverter alloc] init];
	}
    NSData *xmlData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:filePath]];
    [converter->htmlDecoder setBaseURL:[filePath stringByDeletingLastPathComponent]];
    NSAttributedString *result = nil;
    @try {
        result = [converter readData:xmlData withOptions:options retrying:NO];
    } @catch (NSException *e) {
        NSLog(@"Error \"%@\" parsing log file at %@.", e, filePath);
        return [[[NSAttributedString alloc] initWithString:AILocalizedString(@"Sorry, there was an error parsing this transcript. It may be corrupt.", nil)] autorelease];
    }
    return result;
}

- (id)init
{
	if ((self = [super init])) {
        if (!newlineAttributedString) {
            newlineAttributedString = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];
        }
        
        htmlDecoder = [[AIHTMLDecoder alloc] init];

		statusLookup = [[NSDictionary alloc] initWithObjectsAndKeys:
			AILocalizedString(@"Online", nil), @"online",
			AILocalizedString(@"Idle", nil), @"idle",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_OFFLINE], @"offline",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY], @"away",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE], @"available",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BUSY], @"busy",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AT_HOME], @"notAtHome",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_PHONE], @"onThePhone",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_VACATION], @"onVacation",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND], @"doNotDisturb",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY], @"extendedAway",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_BRB], @"beRightBack",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AVAILABLE], @"notAvailable",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_AT_DESK], @"notAtMyDesk",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_NOT_IN_OFFICE], @"notInTheOffice",
			[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_STEPPED_OUT], @"steppedOut",
			nil];			
	}

	return self;
}

- (void)dealloc
{
	[statusLookup release];
	[htmlDecoder release];
	[super dealloc];
}

- (NSAttributedString *)readData:(NSData *)xmlData withOptions:(NSDictionary *)options retrying:(BOOL)reentrancyFlag
{
    if (!xmlData) {
        return [[[NSAttributedString alloc] initWithString:@""] autorelease];
    }
    AINameFormat nameFormat;
    if ([[adium.preferenceController preferenceForKey:KEY_WEBKIT_USE_NAME_FORMAT
                                                group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] boolValue]) {
        nameFormat = [[adium.preferenceController preferenceForKey:KEY_WEBKIT_NAME_FORMAT
                                                             group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] intValue];
    } else {
        nameFormat = AIDefaultName;
    }
    NSMutableAttributedString *output = [[[NSMutableAttributedString alloc] init] autorelease];
    
    NSError *err=nil;
	NSXMLDocument *xmlDoc = [[[NSXMLDocument alloc] initWithData:xmlData
                                                         options:NSXMLNodePreserveCDATA
                                                           error:&err] autorelease];    
	
	if (!xmlDoc)
	{    
        goto ohno;
    }
    
    BOOL showTimestamps = [[options objectForKey:@"showTimestamps"] boolValue];
	BOOL showEmoticons = [[options objectForKey:@"showEmoticons"] boolValue];
    
    NSXMLElement *chatElement = [[xmlDoc nodesForXPath:@"//chat" error:&err] lastObject];
    
    NSDictionary *chatAttributes = [chatElement AIAttributesAsDictionary];
    NSString *mySN = [[chatAttributes objectForKey:@"account"] stringValue];
    NSString *service = [[chatAttributes objectForKey:@"service"] stringValue];
    
    NSString *myDisplayName = nil;
    
    for (AIAccount *account in adium.accountController.accounts) {
        if ([[account.UID compactedString] isEqualToString:[mySN compactedString]] &&
            [account.service.serviceID isEqualToString:service]) {
            myDisplayName = [[account.displayName retain] autorelease];
            break;
        }
    }    
        
    NSArray *elements = [xmlDoc nodesForXPath:@"//message | //action | //status" error:&err];
    if (!elements) {
        goto ohno;
    }
    
    for (NSXMLElement *element in elements) {
        NSString *type = [element name];
     
        NSDictionary *attributes = [element AIAttributesAsDictionary];
        
        if ([type isEqualToString:@"message"] || [type isEqualToString:@"action"]) {
            NSString *senderAlias = [[attributes objectForKey:@"alias"] stringValue];
            NSString *dateStr = [[attributes objectForKey:@"time"] stringValue];
            NSDate *date = dateStr ? [NSCalendarDate calendarDateWithString:dateStr] : nil;
            NSString *sender = [[attributes objectForKey:@"sender"] stringValue];
            NSString *shownSender = (senderAlias ? senderAlias : sender);
            BOOL autoResponse = [[[attributes objectForKey:@"auto"] stringValue] isEqualToString:@"true"];

            NSMutableString *messageXML = [NSMutableString string];
            for (NSXMLNode *node in [element children]) {
                [messageXML appendString:[node XMLString]];
            }
    
            NSString *displayName = nil, *longDisplayName = nil;
            
            BOOL sentMessage = [mySN isEqualToString:sender];

            
            if (sentMessage) {
                //Find an account if one exists, and use its name
                displayName = (myDisplayName ? myDisplayName : sender);
            } else {
				__block AIListObject *listObject;
				
				dispatch_sync(dispatch_get_main_queue(), ^{
					listObject = [adium.contactController existingListObjectWithUniqueID:[AIListObject internalObjectIDForServiceID:service UID:sender]];
				});
                
                displayName = listObject.displayName;
                longDisplayName = [listObject longDisplayName];
            }
                
            if (displayName && !sentMessage) {
                switch (nameFormat) {
                    case AIDefaultName:
                        shownSender = (longDisplayName ? longDisplayName : displayName);
                        break;
                        
                    case AIDisplayName:
                        shownSender = displayName;
                        break;
                        
                    case AIDisplayName_ScreenName:
                        shownSender = [NSString stringWithFormat:@"%@ (%@)",displayName,sender];
                        break;
                        
                    case AIScreenName_DisplayName:
                        shownSender = [NSString stringWithFormat:@"%@ (%@)",sender,displayName];
                        break;
                        
                    case AIScreenName:
                        shownSender = sender;
                        break;	
                }
            }
				
            __block NSString *timestampStr = nil;
			
			[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:YES perform:^(NSDateFormatter *dateFormatter){
				timestampStr = [[dateFormatter stringFromDate:date] retain];
			}];
			
				
            [output appendAttributedString:[htmlDecoder decodeHTML:[NSString stringWithFormat:
                                                                    @"<div class=\"%@\">%@<span class=\"sender\">%@%@:</span></div> ",
                                                                    (sentMessage ? @"send" : @"receive"),
                                                                    (showTimestamps ? [NSString stringWithFormat:@"<span class=\"timestamp\">%@</span> ", timestampStr] : @""),
                                                                    shownSender, (autoResponse ? AILocalizedString(@" (Autoreply)", nil) : @"")]]];
			[timestampStr release];
			
            NSAttributedString *attributedMessage = [htmlDecoder decodeHTML:messageXML];
            if (showEmoticons) {
                attributedMessage = [adium.contentController filterAttributedString:attributedMessage
                                                                    usingFilterType:AIFilterMessageDisplay
                                                                          direction:(sentMessage ? AIFilterOutgoing : AIFilterIncoming)
                                                                            context:nil];				
            }
			
			if ([type isEqualToString:@"action"]) {
				NSMutableAttributedString *ourAttributedString = [[attributedMessage mutableCopy] autorelease];
				[ourAttributedString replaceCharactersInRange:NSMakeRange(0, 0) withString:@"*"];
				[ourAttributedString replaceCharactersInRange:NSMakeRange([ourAttributedString length], 0) withString:@"*"];
				[output appendAttributedString:ourAttributedString];
			} else {
				[output appendAttributedString:attributedMessage];
			}
			
            [output appendAttributedString:newlineAttributedString];
        } else if ([type isEqualToString:@"status"]) {
            NSString *dateStr = [[attributes objectForKey:@"time"] stringValue];
            NSDate *date = dateStr ? [NSCalendarDate calendarDateWithString:dateStr] : nil;
            NSString *status = [[attributes objectForKey:@"type"] stringValue];
            
            NSMutableString *messageXML = [NSMutableString string];
            for (NSXMLNode *node in [element children]) {
                [messageXML appendString:[node XMLString]];
            }            
            
            NSString *displayMessage = nil;
            //Note: I am diverging from what the AILoggerPlugin logs in this case.  It can't handle every case we can have here
            if([messageXML length]) {
                if([statusLookup objectForKey:status]) {
                    displayMessage = [NSString stringWithFormat:AILocalizedString(@"Changed status to %@: %@", nil), [statusLookup objectForKey:status], messageXML];
                } else {
                    displayMessage = [NSString stringWithFormat:AILocalizedString(@"%@", nil), messageXML];
                }
            } else if([status length] && [statusLookup objectForKey:status]) {
                displayMessage = [NSString stringWithFormat:AILocalizedString(@"Changed status to %@", nil), [statusLookup objectForKey:status]];
            }
            
			__block NSString *timestampStr = nil;
			
			[NSDateFormatter withLocalizedDateFormatterShowingSeconds:YES showingAMorPM:YES perform:^(NSDateFormatter *dateFormatter){
				timestampStr = [[dateFormatter stringFromDate:date] retain];
			}];
			
            if([displayMessage length]) {
                [output appendAttributedString:[htmlDecoder decodeHTML:[NSString stringWithFormat:@"<div class=\"status\">%@ (%@)</div>\n",
                                                                        displayMessage,
                                                                        timestampStr]]];
            }
			[timestampStr release];
        }
    }
    
    return output;
    
ohno:
    if (!reentrancyFlag) {
        NSMutableString *xmlString = [NSMutableString stringWithUTF8String:[xmlData bytes]];
        [xmlString stripInvalidCharacters];
        return [self readData:[xmlString dataUsingEncoding:NSUTF8StringEncoding] withOptions:options retrying:YES];
    }
    @throw [NSException exceptionWithName:@"Log File Parsing Error" reason:[err description] userInfo:nil];
}

@end
