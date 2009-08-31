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

static void *createStructure(CFXMLParserRef parser, CFXMLNodeRef node, void *context);
static void addChild(CFXMLParserRef parser, void *parent, void *child, void *context);
static void endStructure(CFXMLParserRef parser, void *xmlType, void *context);

@implementation AIXMLChatlogConverter

+ (NSAttributedString *)readFile:(NSString *)filePath withOptions:(NSDictionary *)options
{
	AIXMLChatlogConverter *converter = [[AIXMLChatlogConverter alloc] init];
	NSAttributedString *ret = [[converter readFile:filePath withOptions:options] retain];
	[converter release];
	return [ret autorelease];
}

- (id)init
{
	if ((self = [super init])) {
	
		state = XML_STATE_NONE;
		
		inputFileString = nil;
		sender = nil;
		mySN = nil;
		myDisplayName = nil;
		date = nil;
		parser = NULL;
		status = nil;
		
		dateFormatter = [[NSDateFormatter localizedDateFormatterShowingSeconds:YES showingAMorPM:YES] retain];
		
		newlineAttributedString = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];

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
			
		if ([[adium.preferenceController preferenceForKey:KEY_WEBKIT_USE_NAME_FORMAT
													  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] boolValue]) {
			nameFormat = [[adium.preferenceController preferenceForKey:KEY_WEBKIT_NAME_FORMAT
																   group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY] integerValue];
		} else {
			nameFormat = AIDefaultName;
		}
	}

	return self;
}

- (void)dealloc
{
	[dateFormatter release];
	[newlineAttributedString release];
	[inputFileString release];
	[eventTranslate release];
	[sender release];
	[senderAlias release];
	[mySN release];
	[myDisplayName release];
	[service release];
	[date release];
	[status release];
	[output release];
	[statusLookup release];
	[htmlDecoder release];
	[super dealloc];
}

- (NSAttributedString *)readFile:(NSString *)filePath withOptions:(NSDictionary *)options
{
	NSData *inputData = [NSData dataWithContentsOfFile:filePath]; 
	inputFileString = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding]; 
	NSURL *url = [[NSURL alloc] initFileURLWithPath:filePath];
	output = [[NSMutableAttributedString alloc] init];
	
	htmlDecoder = [[AIHTMLDecoder alloc] init];
	[htmlDecoder setBaseURL:[filePath stringByDeletingLastPathComponent]];
	
	showTimestamps = [[options objectForKey:@"showTimestamps"] boolValue];
	showEmoticons = [[options objectForKey:@"showEmoticons"] boolValue];

	CFXMLParserCallBacks callbacks = {
		0,
		createStructure,
		addChild,
		endStructure,
		NULL,
		NULL
	};
	CFXMLParserContext context = {
		0,
		self,
		CFRetain,
		CFRelease,
		NULL
	};
	parser = CFXMLParserCreate(NULL, (CFDataRef)inputData, NULL, kCFXMLParserSkipMetaData | kCFXMLParserSkipWhitespace, kCFXMLNodeCurrentVersion, &callbacks, &context);
	if (!CFXMLParserParse(parser)) {
		NSLog(@"%@: Parser %@ for inputFileString %@ returned false.",
			  [self class], parser, inputFileString);
		[output release];
		output = nil;
	}
	CFRelease(parser);
	parser = nil;
	[url release];
	return output;
}

- (void)startedElement:(NSString *)name info:(const CFXMLElementInfo *)info
{
	NSDictionary *attributes = (NSDictionary *)info->attributes;
	
	switch(state){
		case XML_STATE_NONE:
			if([name isEqualToString:@"chat"])
			{
				[mySN release];
				mySN = [[attributes objectForKey:@"account"] retain];
				
				[service release];
				service = [[attributes objectForKey:@"service"] retain];
				
				[myDisplayName release];
				myDisplayName = nil;
				
				for (AIAccount *account in adium.accountController.accounts) {
					if ([[account.UID compactedString] isEqualToString:[mySN compactedString]] &&
						[account.service.serviceID isEqualToString:service]) {
						myDisplayName = [account.displayName retain];
						break;
					}
				}

				state = XML_STATE_CHAT;
			}
			break;
		case XML_STATE_CHAT:
			if([name isEqualToString:@"message"])
			{
				[sender release];
				[senderAlias release];
				[date release];
				
				NSString *dateStr = [attributes objectForKey:@"time"];
				if(dateStr != nil)
					date = [[NSCalendarDate calendarDateWithString:dateStr] retain];
				else
					date = nil;
				sender = [[attributes objectForKey:@"sender"] retain];
				senderAlias = [[attributes objectForKey:@"alias"] retain];
				autoResponse = [[attributes objectForKey:@"auto"] isEqualToString:@"true"];

				//Mark the location of the message...  We can copy it directly.  Anyone know why it is off by 1?
				messageStart = CFXMLParserGetLocation(parser) - 1;
				
				state = XML_STATE_MESSAGE;
			}
			else if([name isEqualToString:@"event"])
			{
				//Mark the location of the message...  We can copy it directly.  Anyone know why it is off by 1?
				messageStart = CFXMLParserGetLocation(parser) - 1;

				state = XML_STATE_EVENT_MESSAGE;
			}
			else if([name isEqualToString:@"status"])
			{
				[status release];
				[date release];
				
				NSString *dateStr = [attributes objectForKey:@"time"];
				if(dateStr != nil)
					date = [[NSCalendarDate calendarDateWithString:dateStr] retain];
				else
					date = nil;
				
				status = [[attributes objectForKey:@"type"] retain];

				//Mark the location of the message...  We can copy it directly.  Anyone know why it is off by 1?
				messageStart = CFXMLParserGetLocation(parser) - 1;

				state = XML_STATE_STATUS_MESSAGE;
			}
			break;
		case XML_STATE_MESSAGE:
		case XML_STATE_EVENT_MESSAGE:
		case XML_STATE_STATUS_MESSAGE:
			break;
	}
}

- (void)endedElement:(NSString *)name empty:(BOOL)empty
{
	switch(state)
	{
		case XML_STATE_EVENT_MESSAGE:
			state = XML_STATE_CHAT;
			break;

		case XML_STATE_MESSAGE:
			if([name isEqualToString:@"message"])
			{
				CFIndex end = CFXMLParserGetLocation(parser);
				NSString *message = nil;
				if (!empty) {
					/* Need to unescape & now so that we'll do link detection properly when decoding the HTML. See #6850.
					 * We'll let HTML decoding handle the other entities.
					 *
					 * 11 = 10 for </message> and 1 for the index being off
					 */
					NSMutableString *mutableMessage = [[inputFileString substringWithRange:NSMakeRange(messageStart, end - messageStart - 11)] mutableCopy];
					[mutableMessage replaceOccurrencesOfString:@"&amp;"
													withString:@"&"
													   options:NSLiteralSearch
														 range:NSMakeRange(0, [mutableMessage length])];
					// Escape anchor tags
					[mutableMessage replaceOccurrencesOfString:@"#"
													withString:@"&#x23;"
													   options:NSLiteralSearch
														 range:NSMakeRange(0, [mutableMessage length])];
					message = [mutableMessage autorelease];
				}
				NSString *shownSender = (senderAlias ? senderAlias : sender);
				NSString *cssClass;
				NSString *displayName = nil, *longDisplayName = nil;
				
				if ([mySN isEqualToString:sender]) {
					//Find an account if one exists, and use its name
					displayName = (myDisplayName ? myDisplayName : sender);
					cssClass = @"send";
				} else {
					AIListObject *listObject = [adium.contactController existingListObjectWithUniqueID:[AIListObject internalObjectIDForServiceID:service UID:sender]];

					cssClass = @"receive";
					displayName = listObject.displayName;
					longDisplayName = [listObject longDisplayName];
				}

				if (displayName && ![displayName isEqualToString:sender]) {
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
				
				NSString *timestampStr = [dateFormatter stringFromDate:date];
				
				BOOL sentMessage = [mySN isEqualToString:sender];
				[output appendAttributedString:[htmlDecoder decodeHTML:[NSString stringWithFormat:
										 @"<div class=\"%@\">%@<span class=\"sender\">%@%@:</span></div> ",
										 (sentMessage ? @"send" : @"receive"),
										 (showTimestamps ? [NSString stringWithFormat:@"<span class=\"timestamp\">%@</span> ", timestampStr] : @""),
										 shownSender, (autoResponse ? AILocalizedString(@" (Autoreply)", nil) : @"")]]];
				
				NSAttributedString *attributedMessage = [htmlDecoder decodeHTML:message];
				if (showEmoticons) {
					attributedMessage = [adium.contentController filterAttributedString:attributedMessage
																		  usingFilterType:AIFilterMessageDisplay
																				direction:(sentMessage ? AIFilterOutgoing : AIFilterIncoming)
																				  context:nil];				
				}
				[output appendAttributedString:attributedMessage];
				[output appendAttributedString:newlineAttributedString];

				state = XML_STATE_CHAT;
			}
			break;
		case XML_STATE_STATUS_MESSAGE:
			if([name isEqualToString:@"status"])
			{
				CFIndex end = CFXMLParserGetLocation(parser);
				NSString *message = nil;
				if(!empty)
					message = [inputFileString substringWithRange:NSMakeRange(messageStart, end - messageStart - 10)];  // 9 for </status> and 1 for the index being off
								
				NSString *displayMessage = nil;
				//Note: I am diverging from what the AILoggerPlugin logs in this case.  It can't handle every case we can have here
				if([message length])
				{
					if([statusLookup objectForKey:status])
						displayMessage = [NSString stringWithFormat:AILocalizedString(@"Changed status to %@: %@", nil), [statusLookup objectForKey:status], message];
					else
						displayMessage = [NSString stringWithFormat:AILocalizedString(@"%@", nil), message];
				}
				else if([status length] && [statusLookup objectForKey:status])
					displayMessage = [NSString stringWithFormat:AILocalizedString(@"Changed status to %@", nil), [statusLookup objectForKey:status]];

				if([displayMessage length])
					[output appendAttributedString:[htmlDecoder decodeHTML:[NSString stringWithFormat:@"<div class=\"status\">%@ (%@)</div>\n",
																			displayMessage,
																			[dateFormatter stringFromDate:date]]]];
					state = XML_STATE_CHAT;
			}			
		case XML_STATE_CHAT:
			if([name isEqualToString:@"chat"])
				state = XML_STATE_NONE;
			break;
		case XML_STATE_NONE:
			break;
	}
}

typedef struct{
	NSString	*name;
	BOOL		empty;
} element;

void *createStructure(CFXMLParserRef parser, CFXMLNodeRef node, void *context)
{
	element *ret = NULL;
	
    // Use the dataTypeID to determine what to print.
    switch (CFXMLNodeGetTypeCode(node)) {
        case kCFXMLNodeTypeDocument:
            break;
        case kCFXMLNodeTypeElement:
		{
			NSString *name = [NSString stringWithString:(NSString *)CFXMLNodeGetString(node)];
			const CFXMLElementInfo *info = CFXMLNodeGetInfoPtr(node);
			[(AIXMLChatlogConverter *)context startedElement:name info:info];
			ret = (element *)malloc(sizeof(element));
			ret->name = [name retain];
			ret->empty = info->isEmpty;
			break;
		}
        case kCFXMLNodeTypeProcessingInstruction:
        case kCFXMLNodeTypeComment:
        case kCFXMLNodeTypeText:
        case kCFXMLNodeTypeCDATASection:
        case kCFXMLNodeTypeEntityReference:
        case kCFXMLNodeTypeDocumentType:
        case kCFXMLNodeTypeWhitespace:
        default:
			break;
	}
	
    // Return the data string for use by the addChild and 
    // endStructure callbacks.
    return (void *) ret;
}

void addChild(CFXMLParserRef parser, void *parent, void *child, void *context)
{
}

void endStructure(CFXMLParserRef parser, void *xmlType, void *context)
{
	NSString *name = nil;
	BOOL empty = NO;
	if(xmlType != NULL)
	{
		name = [NSString stringWithString:((element *)xmlType)->name];
		empty = ((element *)xmlType)->empty;
	}
	[(AIXMLChatlogConverter *)context endedElement:name empty:empty];
	if(xmlType != NULL)
	{
		[((element *)xmlType)->name release];
		free(xmlType);
	}
}

@end
