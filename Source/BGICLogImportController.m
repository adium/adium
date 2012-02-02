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

#import "BGICLogImportController.h"
#import "AIXMLAppender.h"
#import "AILoggerPlugin.h"
#import "AICoreComponentLoader.h"
#import <Adium/AIXMLElement.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/NSCalendarDate+ISO8601Unparsing.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

// InstantMessage and other iChat transcript classes are from Spiny Software's Logorrhea, used with permission.
#import "InstantMessage.h"
#import "Presentity.h"

//#define LOG_TO_TEST
#define TEST_LOGGING_LOCATION [@"~/Desktop/testLog" stringByExpandingTildeInPath]

@implementation BGICLogImportController

/* an iChat log importer needs to be set up with a destination pair, specified as @"service.account" to match current representation(s) in PATH_LOGS */
-(id)initWithDestination:(NSString *)newSAPair
{
	self = [super init];
	if(self)
		importServiceAccountPair = [newSAPair copy];
	return self;
}

-(BOOL)createNewLogForPath:(NSString *)fullPath 
{
	AIHTMLDecoder *xhtmlDecoder = [[AIHTMLDecoder alloc] initWithHeaders:NO
																fontTags:YES
														   closeFontTags:YES
															   colorTags:YES
															   styleTags:YES
														  encodeNonASCII:YES
															encodeSpaces:NO
													   attachmentsAsText:YES
											   onlyIncludeOutgoingImages:NO
														  simpleTagsOnly:NO
														  bodyBackground:NO
													 allowJavascriptURLs:YES];
	[xhtmlDecoder setGeneratesStrictXHTML:YES];
	[xhtmlDecoder setUsesAttachmentTextEquivalents:NO];
	
	// read the raw file into an array for working against, two different formats have been employed by iChat, based on available classes
	fullPath = [[NSFileManager defaultManager] pathByResolvingAlias:fullPath];

	NSArray *rawChat;
	
	@try 
	{
		rawChat =  ([[fullPath pathExtension] isEqual:@"ichat"] ?
					[NSKeyedUnarchiver unarchiveObjectWithFile:fullPath] :
					[NSUnarchiver unarchiveObjectWithFile:fullPath]);
	}
	@catch (NSException *releaseException)
	{
		NSLog(@"Could not open iChat log at %@: %@", fullPath, releaseException);
		rawChat = nil;
	}
	
	if (!rawChat) return NO;

	NSString *preceedingPath = nil;
	
#ifndef LOG_TO_TEST
	preceedingPath = [[[adium.loginController userDirectory] stringByAppendingPathComponent:PATH_LOGS] stringByExpandingTildeInPath];
#else
	preceedingPath = TEST_LOGGING_LOCATION;
#endif
	
	/*
	[rawChat objectAtIndex:0],
		TEST_ACCOUNT, // this has to be matched somehow, I can't see a way offhand through as iChat stores the originating party 
	*/
	NSString *parentPath = [preceedingPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", 
		importServiceAccountPair, // see commented code above for a brittle methodology
		[[[rawChat objectAtIndex:3] objectAtIndex:0] senderID] // this is improperly brittle and imprecise
		]];
	
	// create a new xml parser for logs
	NSString	  *documentPath = [parentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%@).chatlog",
																			  [[[rawChat objectAtIndex:3] objectAtIndex:0] senderID],
																			  [[[[rawChat objectAtIndex:2] objectAtIndex:0] date] dateWithCalendarFormat:@"%Y-%m-%dT%H.%M.%S%z"
																																				timeZone:nil]]];

	AIXMLElement *rootElement = [[AIXMLElement alloc] initWithName:@"chat"];
	
	[rootElement setAttributeNames:[NSArray arrayWithObjects:@"xmlns", @"account", @"service", nil]
							values:[NSArray arrayWithObjects:XML_LOGGING_NAMESPACE, [[[rawChat objectAtIndex:3] objectAtIndex:0] senderID], [rawChat objectAtIndex:0], nil]];
	
	AIXMLAppender *appender = [AIXMLAppender documentWithPath:documentPath rootElement:rootElement];
	NSString	  *imagesPath = [appender.path stringByDeletingLastPathComponent];
	
	// sequentially add the messages from the iChat transcript sans attributed text features
	for(NSInteger i = 0; i < [[rawChat objectAtIndex:2] count]; i++)
	{
		NSMutableArray *attributeKeys = [NSMutableArray arrayWithObjects:@"sender", @"time", nil];
		NSMutableArray *attributeValues = [NSMutableArray arrayWithObjects:
			([[(InstantMessage *)[[rawChat objectAtIndex:2] objectAtIndex:i] sender] senderID] != nil ? [[(InstantMessage *)[[rawChat objectAtIndex:2] objectAtIndex:i] sender] senderID] : @""), 
			[[[(InstantMessage *)[[rawChat objectAtIndex:2] objectAtIndex:i] date] dateWithCalendarFormat:nil timeZone:nil] ISO8601DateString], 
			nil];
		
		NSMutableString *chatContents = [[xhtmlDecoder encodeHTML:[[[rawChat objectAtIndex:2] objectAtIndex:i] text] imagesPath:imagesPath] mutableCopy];
		
		NSString *elementName = ![[[(InstantMessage *)[[rawChat objectAtIndex:2] objectAtIndex:i] sender] senderID] isEqual:@""] ? @"message" : @"event";
		
		AIXMLElement *elm = [[AIXMLElement alloc] initWithName:elementName];
		
		[elm addEscapedObject:chatContents];
		
		if ([attributeValues count] == 2) {
			[elm setAttributeNames:attributeKeys
							values:attributeValues];
		}
		
		[appender appendElement:elm];
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
		[(AILoggerPlugin *)[[adium componentLoader] pluginWithClassName:@"AILoggerPlugin"] markLogDirtyAtPath:documentPath];
		return YES;

	} else {
		return NO;
	}
}

@end
