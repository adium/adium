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

#import "GBFireLogImporter.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AILoginControllerProtocol.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/NSCalendarDate+ISO8601Unparsing.h>

#define PATH_LOGS                       @"/Logs"
#define XML_MARKER @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"

@interface GBFireLogImporter ()
- (void)askBeforeImport;
- (void)importFireLogs;
@end

@implementation GBFireLogImporter

+ (void)importLogs
{
	GBFireLogImporter *importer = [[GBFireLogImporter alloc] init];
	[importer askBeforeImport];
	[importer release];
}

- (id)init
{
	self = [super init];
	if(self == nil)
		return nil;
	
	[NSBundle loadNibNamed:@"FireLogImporter" owner:self];
	
	return self;
}

- (void)askBeforeImport
{
	[adium.interfaceController displayQuestion:AILocalizedString(@"Import Fire Logs?",nil)
							   withDescription:AILocalizedString(@"For some older log formats, the importer cannot properly determine which account was used for conversation.  In such cases, the importer will guess which account to use based upon the order of the accounts.  Before importing Fire's logs, arrange your account order within the Preferences.",nil)
							   withWindowTitle:nil
								 defaultButton:AILocalizedString(@"Import", nil)
							   alternateButton:AILocalizedString(@"Cancel", nil)
								   otherButton:nil
								   suppression:nil
										target:self
									  selector:@selector(importQuestionResponse:userInfo:)
									  userInfo:nil];
}

- (void)importQuestionResponse:(NSNumber *)response userInfo:(id)info
{
	if([response integerValue] == AITextAndButtonsDefaultReturn)
		[NSThread detachNewThreadSelector:@selector(importFireLogs) toTarget:self withObject:nil];
}

NSString *quotes[] = {
	@"\"I have gotten into the habit of recording important meetings\"",
	@"\"One never knows when an inconvenient truth will fall between the cracks and vanish\"",
	@"- Londo Mollari"
};

- (void)importFireLogs
{
	NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
	[window orderFront:self];
	[progressIndicator startAnimation:nil];
	[textField_quote setStringValue:quotes[0]];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *inputLogDir = [[[fm userApplicationSupportFolder] stringByAppendingPathComponent:@"Fire"] stringByAppendingPathComponent:@"Sessions"];
	BOOL isDir = NO;
	
	if(![fm fileExistsAtPath:inputLogDir isDirectory:&isDir] || !isDir) {
		//Nothing to read
		[outerPool release];
		return;
	}
	
	NSArray *subPaths = [fm subpathsAtPath:inputLogDir];
	NSString *outputBasePath = [[[adium.loginController userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
	
	NSArray *accounts = adium.accountController.accounts;
	NSInteger current;
	NSMutableDictionary *defaultScreenname = [NSMutableDictionary dictionary];
	for(current = [accounts count] - 1; current >= 0; current--)
	{
		AIAccount *acct = [accounts objectAtIndex:current];
		[defaultScreenname setObject:acct.UID forKey:acct.service.serviceID];
	}
	
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:NO];
	NSInteger total = [subPaths count], currentQuote = 0;
	for(current = 0; current < total; current++)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];  //A lot of temporary memory is used here
		[progressIndicator setDoubleValue:(double)current/(double)total];
		NSInteger nextQuote = current*sizeof(quotes)/sizeof(NSString *)/total;
		if(nextQuote != currentQuote)
		{
			currentQuote = nextQuote;
			[textField_quote setStringValue:quotes[currentQuote]];
		}
		NSString *logPath = [subPaths objectAtIndex:current];
		NSString *fullInputPath = [inputLogDir stringByAppendingPathComponent:logPath];
		if(![fm fileExistsAtPath:fullInputPath isDirectory:&isDir] || isDir)
		{
			//ignore directories
			[pool release];
			continue;
		}
		NSString *extension = [logPath pathExtension];
		NSArray *pathComponents = [logPath pathComponents];
		if([pathComponents count] != 2)
		{
			//Incorrect directory structure, likely a .DS_Store or something like that
			[pool release];
			continue;
		}
		
		NSString *userAndService = [pathComponents objectAtIndex:[pathComponents count] - 2];
		NSRange range = [userAndService rangeOfString:@"-" options:NSBackwardsSearch];
		if (range.location == NSNotFound) {
			NSLog(@"Warning: [%@ importFireLogs] could not find '-'.", self);
			//Incorrect directory structure
			[pool release];
			continue;			
		}
		NSString *user = [userAndService substringToIndex:range.location];
		NSString *service = [userAndService substringFromIndex:range.location + 1];
		NSDate *date = [NSDate dateWithNaturalLanguageString:[[pathComponents lastObject] stringByDeletingPathExtension]];
				
		if([extension isEqualToString:@"session"])
		{
			NSString *account = [defaultScreenname objectForKey:service];
			if(account == nil)
				account = @"Fire";
			NSString *outputFileDir = [[outputBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", service, account]] stringByAppendingPathComponent:user];
			NSString *outputFile = [outputFileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@).adiumLog", user, [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil]]];
			[fm createDirectoryAtPath:outputFileDir withIntermediateDirectories:YES attributes:nil error:NULL];
			[fm copyPath:fullInputPath toPath:outputFile handler:self];
		}
		else if([extension isEqualToString:@"session2"])
		{
			NSString *account = [defaultScreenname objectForKey:service];
			if(account == nil)
				account = @"Fire";
			NSString *outputFileDir = [[outputBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", service, account]] stringByAppendingPathComponent:user];
			NSString *outputFile = [outputFileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@).AdiumHTMLLog", user, [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil]]];
			[fm createDirectoryAtPath:outputFileDir withIntermediateDirectories:YES attributes:nil error:NULL];
			[fm copyPath:fullInputPath toPath:outputFile handler:self];
		}
		else if([extension isEqualToString:@"xhtml"])
		{
			NSString *outputFile = [outputBasePath stringByAppendingPathComponent:@"tempLogImport"];
			[fm createDirectoryAtPath:outputBasePath withIntermediateDirectories:YES attributes:nil error:NULL];
			GBFireXMLLogImporter *xmlLog = [[GBFireXMLLogImporter alloc] init];
			NSString *account = nil;
			if([xmlLog readFile:fullInputPath toFile:outputFile account:&account])
			{
				if(account == nil)
					account = [defaultScreenname objectForKey:service];
				if(account == nil)
					account = @"Fire";

				NSString *realOutputFileDir = [[outputBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", service, account]] stringByAppendingPathComponent:user];
				NSString *realOutputFile = [realOutputFileDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@).chatlog", user, [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z" timeZone:nil locale:nil]]];
				[fm createDirectoryAtPath:realOutputFileDir withIntermediateDirectories:YES attributes:nil error:NULL];
				[fm movePath:outputFile toPath:realOutputFile handler:self];
			}
			[xmlLog release];
		}
		[pool release];
	}
	[window close];
	[outerPool release];
}

@end

static void *createStructure(CFXMLParserRef parser, CFXMLNodeRef node, void *context);
static void addChild(CFXMLParserRef parser, void *parent, void *child, void *context);
static void endStructure(CFXMLParserRef parser, void *xmlType, void *context);
static Boolean errorStructure (CFXMLParserRef parser, CFXMLParserStatusCode error, void *info);

@implementation GBFireXMLLogImporter

- (id)init
{
	self = [super init];
	if(self == nil)
		return nil;
	
	state = XML_STATE_NONE;
	
	inputFileString = nil;
	outputFileHandle = nil;
	sender = nil;
	mySN = nil;
	date = nil;
	parser = NULL;
	encryption = nil;
	
	eventTranslate = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"userJoined", @"memberJoined",
		@"userParted", @"memberParted",
		@"userFormattedIdChanged", @"newNickname",
		@"channelTopicChanged", @"topicChanged",
		@"userPermissions/Promoted", @"memberPromoted",
		@"userPermissions/Demoted", @"memberDemoted",
		@"userPermissions/Voiced", @"memberVoiced",
		@"userPermissions/Devoiced", @"memberDevoiced",
		@"userKicked", @"memberKicked",
		nil];
		
	return self;
}

- (BOOL)readFile:(NSString *)inFile toFile:(NSString *)outFile account:(NSString * *)account;
{
	AILog(@"%@: readFile:%@ toFile:%@",NSStringFromClass([self class]), inFile, outFile);

	BOOL success = YES;
	NSData *inputData = [NSData dataWithContentsOfFile:inFile];
	inputFileString = [[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding];
	NSInteger outfd = open([outFile fileSystemRepresentation], O_CREAT | O_WRONLY, 0644);
	outputFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:outfd closeOnDealloc:YES];
	
	CFXMLParserCallBacks callbacks = {
		0,
		createStructure,
		addChild,
		endStructure,
		NULL,
		errorStructure
	};
	CFXMLParserContext context = {
		0,
		self,
		CFRetain,
		CFRelease,
		NULL
	};
	NSMutableString *newStr = [NSMutableString stringWithContentsOfFile:inFile usedEncoding:nil error:NULL];
	NSInteger endOffset = [newStr rangeOfString:@">" options:NSBackwardsSearch].location;
	NSInteger startOffset = [newStr rangeOfString:@"<" options:NSBackwardsSearch].location;
	if((endOffset == NSNotFound || endOffset < startOffset) && startOffset != NSNotFound)
	{
		//Broken XML can crash the importer, attempt a repair, but most likely the parse will fail
		[newStr appendString:@">"];
		AILog(@"Fire log import: %@ has broken XML, you should fix this and re-import it", inFile);
		NSLog(@"Fire log import: %@ has broken XML, you should fix this and re-import it", inFile);
	}
	NSData *data = [newStr dataUsingEncoding:NSUTF8StringEncoding];
	parser = CFXMLParserCreate(NULL, (CFDataRef)data, NULL,kCFXMLParserSkipMetaData | kCFXMLParserSkipWhitespace, kCFXMLNodeCurrentVersion, &callbacks, &context);
	if (!CFXMLParserParse(parser)) {
		NSLog(@"Fire log import: Parse of %@ failed", inFile);
		AILog(@"Fire log import: Parse of %@ failed", inFile);
		success = NO;
	}
	CFRelease(parser);
	parser = nil;
	[outputFileHandle closeFile];
	
	*account = [[mySN retain] autorelease];
	return success;
}

- (void)dealloc
{
	[inputFileString release];
	[outputFileHandle release];
	[eventTranslate release];
	[sender release];
	[htmlMessage release];
	[mySN release];
	[date release];
	[encryption release];
	[super dealloc];
}

- (void)startedElement:(NSString *)name info:(const CFXMLElementInfo *)info
{
	NSDictionary *attributes = (NSDictionary *)info->attributes;
	
	switch(state){
		case XML_STATE_NONE:
			if([name isEqualToString:@"envelope"])
			{
				[sender release];
				sender = nil;
				state = XML_STATE_ENVELOPE;
			}
			else if([name isEqualToString:@"event"])
			{
				[date release];
				
				NSString *dateStr = [attributes objectForKey:@"occurred"];
				if(dateStr != nil)
					date = [[NSCalendarDate dateWithString:dateStr] retain];
				else
					date = nil;
				
				[eventName release];
				NSString *eventStr = [attributes objectForKey:@"name"];
				if(eventStr != nil)
					eventName = [[NSString alloc] initWithString:eventStr];
				else
					eventName = nil;
				[sender release];
				sender = nil;
				[htmlMessage release];
				htmlMessage = nil;
				state = XML_STATE_EVENT;
			}
			else if([name isEqualToString:@"log"])
			{
				NSString *service = [attributes objectForKey:@"service"];
				NSString *account = [attributes objectForKey:@"accountName"];
				if(account != nil)
				{
					NSRange range = [account rangeOfString:@"-"];
					if(range.location != NSNotFound)
					{
						mySN = [[account substringFromIndex:range.location + 1] retain];
						range = [mySN rangeOfString:@"@"];
						NSRange revRange = [mySN rangeOfString:@"@" options:NSBackwardsSearch];
						if ((revRange.location != range.location) && (revRange.location != NSNotFound))
						{
							NSString *oldMySN = mySN;
							mySN = [[mySN substringToIndex:revRange.location] retain];
							[oldMySN release];
						}
					}
				}
				NSMutableString *chatTag = [NSMutableString stringWithFormat:@"%@\n<chat", XML_MARKER];
				[chatTag appendString:@" xmlns=\"http://purl.org/net/ulf/ns/0.4-02\""];
				if(mySN != nil)
					[chatTag appendFormat:@" account=\"%@\"", mySN];
				if(service != nil)
					[chatTag appendFormat:@" service=\"%@\"", service];
				[chatTag appendString:@">\n"];
				[outputFileHandle writeData:[chatTag dataUsingEncoding:NSUTF8StringEncoding]];
			}
			break;
		case XML_STATE_ENVELOPE:
			if ([name isEqualToString:@"message"])
			{
				[date release];
				
				NSString *dateStr = [attributes objectForKey:@"received"];
				if(dateStr != nil)
					date = [[NSCalendarDate dateWithString:dateStr] retain];
				else
					date = nil;
				
				//Mark the location of the message...  We can copy it directly.  Anyone know why it is off by 1?
				messageStart = CFXMLParserGetLocation(parser) - 1;
				
				if([attributes objectForKey:@"action"] != nil)
					actionMessage = YES;
				else
					actionMessage = NO;
				
				if([attributes objectForKey:@"away"] != nil)
					autoResponse = YES;
				else
					autoResponse = NO;
				[encryption release];
				encryption = [[attributes objectForKey:@"security"] retain];
				
				state = XML_STATE_MESSAGE;
			}
			else if([name isEqualToString:@"sender"])
			{
				[sender release];
				
				NSString *nickname = [attributes objectForKey:@"nickname"];
				NSString *selfSender = [attributes objectForKey:@"self"];
				if(nickname != nil)
					sender = [nickname retain];
				else if ([selfSender isEqualToString:@"yes"])
					sender = [mySN retain];
				else
					sender = nil;
				state = XML_STATE_SENDER;
			}
			break;
		case XML_STATE_SENDER:
		case XML_STATE_MESSAGE:
		case XML_STATE_EVENT:
			if([name isEqualToString:@"Message"])
			{
				state = XML_STATE_EVENT_ATTRIBUTED_MESSAGE;
			}
			if([name isEqualToString:@"message"])
			{
				//Mark the location of the message...  same as above
				messageStart = CFXMLParserGetLocation(parser) - 1;
				state = XML_STATE_EVENT_MESSAGE;
			}
			if([name isEqualToString:@"nickname"])
			{
				state = XML_STATE_EVENT_NICKNAME;
			}
		case XML_STATE_EVENT_ATTRIBUTED_MESSAGE:
		case XML_STATE_EVENT_MESSAGE:
		case XML_STATE_EVENT_NICKNAME:
			break;
	}
}

- (void)endedElement:(NSString *)name empty:(BOOL)empty
{
	switch(state)
	{
		case XML_STATE_ENVELOPE:
			if([name isEqualToString:@"envelope"])
				state = XML_STATE_NONE;
			break;
		case XML_STATE_SENDER:
			if([name isEqualToString:@"sender"])
				state = XML_STATE_ENVELOPE;
			break;
		case XML_STATE_MESSAGE:
			if([name isEqualToString:@"message"])
			{
				CFIndex end = CFXMLParserGetLocation(parser);
				NSString *message = nil;
				if(!empty)
					message = [inputFileString substringWithRange:NSMakeRange(messageStart, end - messageStart - 11)];  // 10 for </message> and 1 for the index being off 

				//Common logging format
				NSMutableString *outMessage = [NSMutableString stringWithString:@"<message"];
				if(actionMessage)
				{
					[outMessage appendString:@" type=\"action\""];
					
					//Hmm...  there is a bug in Fire's logging format that logs action messages like <span>username </span>message
					NSInteger cutIndex = 0;
					NSInteger index = [message rangeOfString:@"<span>"].location;
					if(index == 0)
					{
						NSInteger endIndex = [message rangeOfString:@"</span>"].location;
						if(sender == nil)
							sender = [[message substringWithRange:NSMakeRange(6, endIndex-7)] retain];  //6 is length of <span>.  7 is length of <span> plus trailing space
						index = cutIndex = endIndex + 7;  //7 is length of </span>
					}
					else
						index = 0;
					while([message characterAtIndex:index] == '<')
					{
						NSRange searchRange = NSMakeRange(index, [message length] - index);
						NSRange range = [message rangeOfString:@">" options:0 range:searchRange];
						index = range.location + 1;
					}
					NSString *newMessage = nil;
					if(message)
						newMessage = [[NSString alloc] initWithFormat:@"%@/me %@", [message substringWithRange:NSMakeRange(cutIndex, index-cutIndex)], [message substringFromIndex:index]];
					else
						newMessage = [[NSString alloc] initWithString:@"/me "];
					message = [newMessage autorelease];
				}
				if(autoResponse)
					[outMessage appendString:@" auto=\"yes\""];
				if(sender != nil)
					[outMessage appendFormat:@" sender=\"%@\"", sender];
				if(date != nil)
					[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
				if([encryption length])
					[outMessage appendFormat:@" encryption=\"%@\"", encryption];
				if([message length])
					[outMessage appendFormat:@">%@</message>\n", message];
				else
					[outMessage appendString:@"/>\n"];
				[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				state = XML_STATE_ENVELOPE;
			}
			break;
		case XML_STATE_EVENT:
			if([name isEqualToString:@"event"])
				state = XML_STATE_NONE;
			break;
		case XML_STATE_EVENT_ATTRIBUTED_MESSAGE:
			if([name isEqualToString:@"Message"])
				state = XML_STATE_EVENT;
			break;
		case XML_STATE_EVENT_MESSAGE:
			if([name isEqualToString:@"message"])
			{
				CFIndex end = CFXMLParserGetLocation(parser);
				NSString *message = nil;
				if(!empty)
					message = [inputFileString substringWithRange:NSMakeRange(messageStart, end - messageStart - 11)];  // 10 for </message> and 1 for the index being off 

				if([eventName isEqualToString:@"loggedOff"] || [eventName isEqualToString:@"memberParted"])
				{
					NSMutableString *outMessage = [NSMutableString stringWithString:@"<status type=\"offline\""];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					[outMessage appendString:@"/>"];
					[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				}
				else if([eventName isEqualToString:@"loggedOn"] || [eventName isEqualToString:@"memberJoined"])
				{
					NSMutableString *outMessage = [NSMutableString stringWithString:@"<status type=\"online\""];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					[outMessage appendString:@"/>"];
					[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				}
				else if([eventName isEqualToString:@"StatusChanged"])
				{
					//now we have to parse all these
					NSString *type = nil;
					NSInteger parseMessageIndex = 0;
					BOOL idle = NO;
					if(message != nil)
					{
						if((parseMessageIndex = [message rangeOfString:@"changed status to Idle"].location) != NSNotFound)
						{
							type = @"online";
							idle = YES;
						}
						else if((parseMessageIndex = [message rangeOfString:@"status to Available"].location) != NSNotFound)
							type = @"online";
						else if((parseMessageIndex = [message rangeOfString:@"status to Away"].location) != NSNotFound)
							type = @"away";
						else if((parseMessageIndex = [message rangeOfString:@"status to Busy"].location) != NSNotFound)
							type = @"busy";
						else if((parseMessageIndex = [message rangeOfString:@"status to Not at Home"].location) != NSNotFound)
							type = @"notAtHome";
						else if((parseMessageIndex = [message rangeOfString:@"status to On the Phone"].location) != NSNotFound)
							type = @"onThePhone";
						else if((parseMessageIndex = [message rangeOfString:@"status to On Vacation"].location) != NSNotFound)
							type = @"onVacation";
						else if((parseMessageIndex = [message rangeOfString:@"status to Do Not Disturb"].location) != NSNotFound)
							type = @"doNotDisturb";
						else if((parseMessageIndex = [message rangeOfString:@"status to Extended Away"].location) != NSNotFound)
							type = @"extendedAway";
						else if((parseMessageIndex = [message rangeOfString:@"status to Be Right Back"].location) != NSNotFound)
							type = @"beRightBack";
						else if((parseMessageIndex = [message rangeOfString:@"status to Be NA"].location) != NSNotFound)
							type = @"notAvailable";
						else if((parseMessageIndex = [message rangeOfString:@"status to Be Not at Home"].location) != NSNotFound)
							type = @"notAtHome";
						else if((parseMessageIndex = [message rangeOfString:@"status to Not at my Desk"].location) != NSNotFound)
							type = @"notAtMyDesk";
						else if((parseMessageIndex = [message rangeOfString:@"status to Not in the Office"].location) != NSNotFound)
							type = @"notInTheOffice";
						else if((parseMessageIndex = [message rangeOfString:@"status to Stepped Out"].location) != NSNotFound)
							type = @"steppedOut";
						else
							NSLog(@"Unknown type %@", message);
					}
					//if the type is unknown, we can't do anything, drop it!
					if(type != nil)
					{
						NSInteger colonIndex = [message rangeOfString:@":" options:0 range:NSMakeRange(parseMessageIndex, [message length] - parseMessageIndex)].location;
						
						NSMutableString *outMessage = [NSMutableString stringWithFormat:@"<status type=\"%@\"", type];
						if(sender != nil)
							[outMessage appendFormat:@" sender=\"%@\"", sender];
						if(date != nil)
							[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
						if(idle)
							[outMessage appendString:@" idleTime=\"10\""];

						NSString *subStr = nil;
						if(colonIndex != NSNotFound && [message length] > colonIndex + 2)
							//Eliminate the "has changed status to: " from the string
							subStr = [message substringFromIndex:colonIndex + 2];
						if(![subStr hasPrefix:@"<span"] && [subStr hasSuffix:@"</span>"])
							//Eliminate the "</span>" at the end if it doesn't start with "<span"
							subStr = [subStr substringToIndex:[subStr length] - 7];
						if([htmlMessage length])
							//Prefer the attributed message
							[outMessage appendFormat:@">%@</status>\n", htmlMessage];
						else if([subStr length])
							[outMessage appendFormat:@">%@</status>\n", subStr];
						else
							[outMessage appendString:@"/>\n"];
						[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
					}
				}
				else if([eventName isEqualToString:@"topicChanged"] ||
						[eventName isEqualToString:@"memberJoined"] ||
						[eventName isEqualToString:@"memberParted"] ||
						[eventName isEqualToString:@"memberPromoted"] ||
						[eventName isEqualToString:@"memberDemoted"] ||
						[eventName isEqualToString:@"memberVoiced"] ||
						[eventName isEqualToString:@"memberDevoiced"] ||
						[eventName isEqualToString:@"memberKicked"] ||
						[eventName isEqualToString:@"newNickname"])
				{
					NSMutableString *outMessage = [NSMutableString stringWithFormat:@"<status type=\"%@\"", [eventTranslate objectForKey:eventName]];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					
					if([message length])
						[outMessage appendFormat:@">%@</status>\n", message];
					else
						[outMessage appendString:@"/>\n"];
					[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				}
				else if(eventName == nil)
				{
					//Generic message
					NSMutableString *outMessage = [NSMutableString stringWithFormat:@"<event type=\"service\"", eventName];
					if(sender != nil)
						[outMessage appendFormat:@" sender=\"%@\"", sender];
					if(date != nil)
						[outMessage appendFormat:@" time=\"%@\"", [date ISO8601DateString]];
					
					if([message length])
						[outMessage appendFormat:@">%@</event>\n", message];
					else
						[outMessage appendString:@"/>\n"];
					[outputFileHandle writeData:[outMessage dataUsingEncoding:NSUTF8StringEncoding]];
				}
				else
				{
					//Need to translate these
					NSLog(@"Got an Event %@ at %@: %@",
						  eventName,
						  date,
						  message);
				}
				state = XML_STATE_EVENT;
			}
			break;
		case XML_STATE_EVENT_NICKNAME:
			state = XML_STATE_EVENT;
			break;
		case XML_STATE_NONE:
			if([name isEqualToString:@"log"])
				[outputFileHandle writeData:[[NSString stringWithString:@"\n</chat>"] dataUsingEncoding:NSUTF8StringEncoding]];
			break;
	}
}

typedef struct{
	NSString	*name;
	BOOL		empty;
} element;

- (void)text:(NSString *)text
{
	switch(state)
	{
		case XML_STATE_SENDER:
			if(sender == nil)
				sender = [text retain];
			break;
		case XML_STATE_EVENT_NICKNAME:
			if(sender == nil)
				sender = [text retain];
			break;
		case XML_STATE_EVENT_ATTRIBUTED_MESSAGE:
			if(htmlMessage == nil)
				htmlMessage = [text mutableCopy];
			else
				[htmlMessage appendString:text];
			break;
		case XML_STATE_NONE:
		case XML_STATE_ENVELOPE:
		case XML_STATE_MESSAGE:
		case XML_STATE_EVENT:
		case XML_STATE_EVENT_MESSAGE:
			break;
	}
}

@end

static void *createStructure(CFXMLParserRef parser, CFXMLNodeRef node, void *context)
{
	element *ret = nil;
	
    // Use the dataTypeID to determine what to print.
    switch (CFXMLNodeGetTypeCode(node)) {
        case kCFXMLNodeTypeDocument:
            break;
        case kCFXMLNodeTypeElement:
		{
			NSString *name = [NSString stringWithString:(NSString *)CFXMLNodeGetString(node)];
			const CFXMLElementInfo *info = CFXMLNodeGetInfoPtr(node);
			[(GBFireXMLLogImporter *)context startedElement:name info:info];
			ret = (element *)malloc(sizeof(element));
			ret->name = [name retain];
			ret->empty = info->isEmpty;
			break;
		}
        case kCFXMLNodeTypeProcessingInstruction:
        case kCFXMLNodeTypeComment:
			break;
        case kCFXMLNodeTypeEntityReference:
		{
			unichar entity = 0;
			CFXMLEntityReferenceInfo *entityInfo = (CFXMLEntityReferenceInfo *)CFXMLNodeGetInfoPtr(node);
			NSString *dataString = (NSString *)CFXMLNodeGetString(node);
			if(entityInfo->entityType == kCFXMLEntityTypeCharacter)
			{
				if([dataString characterAtIndex:0] == '#')
				{
					BOOL hex = 0;
					if([dataString characterAtIndex:1] == 'x')
						hex = 1;
					
					NSInteger i;
					for(i = hex + 1; i < [dataString length]; i++)
					{
						if(hex)
						{
							unichar encodedDigit = [dataString characterAtIndex:i];
							if(encodedDigit <= '9' && encodedDigit >= '0')
								entity = entity * 16 + (encodedDigit - '0');
							else if(encodedDigit <= 'F' && encodedDigit >= 'A')
								entity = entity * 16 + (encodedDigit - 'A' + 10);
							else if(encodedDigit <= 'f' && encodedDigit >= 'a')
								entity = entity * 16 + (encodedDigit - 'a' + 10);
						}
						else
						{
							entity = entity * 10 + ([dataString characterAtIndex:i] - '0');
						}
					}
				}
			}
			else if(entityInfo->entityType == kCFXMLEntityTypeParsedInternal)
			{
				if ([dataString isEqualToString:@"lt"])
					entity = 0x3C;
				else if ([dataString isEqualToString:@"gt"])
					entity = 0x3E;
				else if ([dataString isEqualToString:@"quot"])
					entity = 0x22;
				else if ([dataString isEqualToString:@"amp"])
					entity = 0x26;
				else if ([dataString isEqualToString:@"apos"])
					entity = 0x27;
				else if ([dataString isEqualToString:@"ldquo"])
					entity = 0x201c;
				else if ([dataString isEqualToString:@"rdquo"])
					entity = 0x201d;
			}
			[(GBFireXMLLogImporter *)context text:[[[NSString alloc] initWithCharacters:&entity length:1] autorelease]];
            break;
		}
        case kCFXMLNodeTypeText:
			[(GBFireXMLLogImporter *)context text:[NSString stringWithString:(NSString *)CFXMLNodeGetString(node)]];
            break;
        case kCFXMLNodeTypeCDATASection:
        case kCFXMLNodeTypeDocumentType:
        case kCFXMLNodeTypeWhitespace:
        default:
			break;
	}
	
    // Return the data string for use by the addChild and 
    // endStructure callbacks.
    return (void *) ret;
}

static void addChild(CFXMLParserRef parser, void *parent, void *child, void *context)
{
}

static void endStructure(CFXMLParserRef parser, void *xmlType, void *context)
{
	NSString *name = nil;
	BOOL empty = NO;
	if(xmlType != NULL)
	{
		name = [NSString stringWithString:((element *)xmlType)->name];
		empty = ((element *)xmlType)->empty;
	}
	[(GBFireXMLLogImporter *)context endedElement:name empty:empty];
	if(xmlType != NULL)
	{
		[((element *)xmlType)->name release];
		free(xmlType);
	}
}

static Boolean errorStructure (CFXMLParserRef parser, CFXMLParserStatusCode error, void *info)
{
	return NO;
}
