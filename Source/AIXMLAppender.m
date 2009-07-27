/*
 * AIXMLAppender.m
 *
 * Created by Colin Barrett on 12/23/05.
 *
 * This class is explicitly released under the BSD license with the following modification:
 * It may be used without reproduction of its copyright notice within The Adium Project.
 *
 * This class was created for use in the Adium project, which is released under the GPL.
 * The release of this specific class (AIXMLAppender) under BSD in no way changes the licensing of any other portion
 * of the Adium project.
 *
 ****
 Copyright (c) 2005, 2006 Colin Barrett
 Copyright (c) 2008 The Adium Team
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
 in the documentation and/or other materials provided with the distribution.
 Neither the name of Adium nor the names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* TODO:
- Better error handling
- Possible support for "healing" a damaged XML file?
- Possibly refactor the initializeDocument... and appendElement... methods to return a BOOL and/or RBR an error code of some kind to indicate success or failure.
- Instead of just testing for ' ' in -rootElementNameForFileAtPath:, use NSCharacterSet and be more general.
*/

/*****
 IMPORTANT NOTE if we ever switch back to NSOperationQueue:
 
 The invariant that no two operations from the same AIXMLAppender are executing concurrently is extremely important. The writer queue should never allow more than one operation at a time 
 *****/

#import "AIXMLAppender.h"
#import <Adium/AIXMLElement.h>
#import <AIUtilities/AISharedWriterQueue.h>
#define BSD_LICENSE_ONLY 1
#import <AIUtilities/AIStringAdditions.h>
#import <sys/stat.h>
#import <unistd.h>

#define XML_APPENDER_BLOCK_SIZE 4096

#define XML_MARKER @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
enum {
	xmlMarkerLength = 21,
	failedUtf8BomLength = 6
};


@interface AIXMLAppender()
- (void)writeData:(NSData *)data seekBackLength:(NSInteger)seekBackLength;
- (NSString *)rootElementNameForFileAtPath:(NSString *)path;
@property (readwrite, retain, nonatomic) NSFileHandle *fileHandle;
@property (readwrite) BOOL initialized;
@property (readwrite, copy, nonatomic) AIXMLElement *rootElement;
@property (readwrite, copy, nonatomic) NSString *path;
@end

@interface AIAppendXMLOperation : RAOperation
{
	NSData *data;
	NSInteger seekBackLength;
	AIXMLAppender *appender;
}
- (AIAppendXMLOperation *)initWithData:(NSData *)d 
						seekBackLength:(NSInteger)s 
							  appender:(AIXMLAppender *)a;

- (void) prepareFileHandle;
@end

@implementation AIAppendXMLOperation
- (AIAppendXMLOperation *)initWithData:(NSData *)d 
						seekBackLength:(NSInteger)s 
							  appender:(AIXMLAppender *)a
{
	if ((self = [super init]))
	{
		data = [d retain];
		seekBackLength = s;
		appender = [a retain];
	}
	
	return self;
}

- (void) dealloc
{
	[data release];
	[appender release];
	[super dealloc];
}

- (void) run
{
	BOOL success = YES;
	if (!appender.fileHandle)
		[self prepareFileHandle];
	
	@try {
		[appender.fileHandle writeData:data];
		
	} @catch (NSException *writingException) {
		/* NSFileHandle raises an exception if:
		 *    * the file descriptor is closed or is not valid - we should reopen the file and try again
		 *    * if the receiver represents an unconnected pipe or socket endpoint - this should never happen
		 *    * if no free space is left on the file system - this should be handled gracefully if possible.. but the user is probably in trouble.
		 *    * if any other writing error occurs - as with lack of free space.
		 */
		if (appender.initialized &&
			[[writingException name] isEqualToString:NSFileHandleOperationException] &&
			[[writingException reason] rangeOfString:@"Bad file descriptor"].location != NSNotFound) {
			
			appender.fileHandle = nil;
			
			[self prepareFileHandle];
			
			@try {
				[appender.fileHandle writeData:data];
				success = YES;
				
			} @catch (NSException *secondWritingException) {
				NSLog(@"Exception while writing %@ log file %@: %@ (%@)",
					  (appender.initialized ? @"initialized" : @"uninitialized"), appender.path, [secondWritingException name], [secondWritingException reason]);
				success = NO;
			}
			
		} else {
			NSLog(@"Exception while writing %@ log file %@: %@ (%@)",
				  (appender.initialized ? @"initialized" : @"uninitialized"), appender.path, [writingException name], [writingException reason]);
			success = NO;
		}
	}
	
	if (success) {
		[appender.fileHandle synchronizeFile];
		
		@try {
			[appender.fileHandle seekToFileOffset:([appender.fileHandle offsetInFile] - seekBackLength)];	
			
		} @catch (NSException *seekException) {
			/* -[NSFileHandler seekToFileOffset:] raises an exception if
			 *    * the message is sent to an NSFileHandle object representing a pipe or socket
			 *    * if the file descriptor is closed
			 *    * if any other error occurs in seeking.
			 */
			NSLog(@"Exception while seeking in %@ log file %@: %@ (%@)",
				  (appender.initialized ? @"initialized" : @"uninitialized"), appender.path, [seekException name], [seekException reason]);
			success = NO;
		}
	}
}

- (void)prepareFileHandle
{	
	NSFileManager *manager = [NSFileManager defaultManager];
	
	//Check if the file already exists
	if ([manager fileExistsAtPath:appender.path]) {
		//Get the root element name and set initialized
		NSString *rootElementName = [appender rootElementNameForFileAtPath:appender.path];
		if (rootElementName)
			appender.rootElement = [[[AIXMLElement alloc] initWithName:rootElementName] autorelease];
		appender.initialized = (rootElementName != nil);				
		
	} else {
		//Create each component of the path, then change into it.
		NSError *error = nil;
		if (![manager createDirectoryAtPath:[appender.path stringByDeletingLastPathComponent]
				withIntermediateDirectories:YES
								 attributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:0700UL] forKey:NSFilePosixPermissions]
									  error:&error]) {
			AILogWithSignature(@"Error creating directory at %@: %@", 
							   [appender.path stringByDeletingLastPathComponent],
							   error);
		}

		appender.initialized = NO;
	}
	
	//Open our file handle and seek if necessary
	const char *pathCString = [appender.path fileSystemRepresentation];
	NSInteger fd = open(pathCString, O_CREAT | O_WRONLY, 0600);
	if(fd == -1) {
		AILog(@"Couldn't open log file %@ (%s - length %u) for writing!",
			  appender.path, pathCString, (pathCString ? strlen(pathCString) : 0));
	} else {
		appender.fileHandle = [[[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES] autorelease];
		if (appender.initialized) {
			struct stat sb;
			fstat(fd, &sb);
			NSInteger closingTagLength = [appender.rootElement.name length] + 4; //</rootElementName>
			[appender.fileHandle seekToFileOffset:sb.st_size - closingTagLength];
		}
	}
}

@end

/*!
 * @class AIXMLAppender
 * @brief Provides multiple-write access to an XML document while maintaining wellformedness.
 *
 * Just a couple of general comments here;
 * - Despite the hackish nature of seeking backwards and overwriting, sometimes you need to cheat a little or things
 *   get a bit insane. That's what was happening, so a Grand Compromise was reached, and this is what we're doing.
 */
 
@implementation AIXMLAppender

@synthesize initialized;

@synthesize fileHandle = file;

/*!
 * @brief Create a new, autoreleased document.
 *
 * @param path Path to the file where XML document will be stored
 */
+ (id)documentWithPath:(NSString *)path rootElement:(AIXMLElement *)root
{
	return [[[self alloc] initWithPath:path rootElement:root] autorelease];
}

/*!
 * @brief Create a new document at the path \a path
 *
 * @param path 
 */
- (id)initWithPath:(NSString *)inPath rootElement:(AIXMLElement *)root
{
	if ((self = [super init])) {
		//Set up our instance variables
		self.rootElement = root;
		self.path = inPath;
		self.initialized = NO;
		
		//Create our strings
		NSInteger closingTagLength = [self.rootElement.name length] + 3; //</rootElementName>
		NSString *initialDocument = [NSString stringWithFormat:@"%@\n%@", XML_MARKER, [rootElement XMLString]];
		
		//Write the data, and then seek backwards
		[self writeData:[initialDocument dataUsingEncoding:NSUTF8StringEncoding] seekBackLength:closingTagLength];
	}

	return self;
}

/*!
 * @brief Clean up.
 */
- (void)dealloc
{
	self.path = nil;
	self.fileHandle = nil; //This will also close the fd, since we set the closeOnDealloc flag to YES
	self.rootElement = nil;
	[super dealloc];
}

#pragma mark -

/*!
 * @brief The path to the file.
 *
 * @return The path to the file the XML document is being written to.
 */
@synthesize path;

@synthesize rootElement;

#pragma mark -

- (void)writeData:(NSData *)data seekBackLength:(NSInteger)seekBackLength
{
	AIAppendXMLOperation *op = [[[AIAppendXMLOperation alloc] initWithData:data seekBackLength:seekBackLength appender:self] autorelease];
	[AISharedWriterQueue addOperation:op];
}

/*!
 * @brief Adds a node to the document
 *
 * @param element The element to add
 */

- (void)appendElement:(AIXMLElement *)element
{
	//Create our strings
	NSString *elementString = [element XMLString];
	NSString *closingTag = [NSString stringWithFormat:@"</%@>", self.rootElement.name];
	
	if (elementString != nil) {
		//Write the data, and then seek backwards
		[self writeData:[[elementString stringByAppendingString:closingTag] dataUsingEncoding:NSUTF8StringEncoding]
		 seekBackLength:[closingTag length]];
	}
}

#pragma mark Private Methods

/*!
 * @brief Get the root element name for file
 * 
 * @return The root element name, or nil if there isn't one (possibly because the file is not valid XML)
 */
- (NSString *)rootElementNameForFileAtPath:(NSString *)inPath
{
	//Create a temporary file handle for validation, and read the marker
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:inPath];
	
	if(!handle) return nil;
	
	NSScanner *scanner = nil;
	do {
		//Read a block of arbitrary size
		NSString *block = [[[NSString alloc] initWithData:[handle readDataOfLength:XML_APPENDER_BLOCK_SIZE]
												 encoding:NSUTF8StringEncoding] autorelease];
		//If we read 0 characters, then we have reached the end of the file, so return
		if ([block length] == 0) {
			[handle closeFile];
			return nil;
		}

		scanner = [NSScanner scannerWithString:block];
		[scanner scanUpToString:@"<" intoString:nil];
	} while([scanner isAtEnd]); //If the scanner is at the end, not found in this block

	//Scn past the '<' we know is there
	[scanner scanString:@"<" intoString:nil];
	
	NSString *accumulated = [NSString string];
	NSMutableString *accumulator = [NSMutableString string];
	BOOL found = NO;
	do {
		[scanner scanUpToString:@" " intoString:&accumulated]; //very naive
		[accumulator appendString:accumulated];
		
		//If the scanner is at the end, not found in this block
		found = ![scanner isAtEnd];
		
		//If we've found the end of the element name, break
		if (found)
			break;
			
		NSString *block = [[[NSString alloc] initWithData:[handle readDataOfLength:XML_APPENDER_BLOCK_SIZE]
												 encoding:NSUTF8StringEncoding] autorelease];
		//Again, if we've reached the end of the file, we aren't initialized, so return nil
		if ([block length] == 0) {
			[handle closeFile];
			return nil;
		}

		scanner = [NSScanner scannerWithString:block];
	} while (!found);
	
	[handle closeFile];
	
	//We've obviously found the root element name, so return a nonmutable copy.
	return [NSString stringWithString:accumulator];
}

@end
