//
//  AILaTeXProcessor.m
//  Adium
//
//  Created by Evan Schoenberg on 10/21/08.
//  Copyright 2008 Adium X. All rights reserved.
//

#import "AILaTeXProcessor.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AITextAttachmentExtension.h>
#import <AIUtilities/AIImageAdditions.h>

@interface AILaTeXProcessor ()
+ (NSString *)getPathForProgram:(NSString *)progname;
- (void)begin;
- (void)procesLaTeX;
- (void)didFinishProcessingLaTeXString;
- (void)appendImageFromLatex:(NSString *)bodyLaTeX color:(NSColor *)color;
- (NSAttributedString *)attributedStringWithImage:(NSImage *)img textEquivalent:(NSString *)textEquivalent;

@property (nonatomic, retain) NSMutableAttributedString *newMessage;
@property (nonatomic, retain) NSAttributedString *originalAttributedString;
@property (nonatomic, assign) id context;
@property unsigned long long uniqueID;
@property (nonatomic, retain) NSScanner *scanner;

@property (nonatomic, retain) NSString *currentFileRoot;
@property (nonatomic, retain) NSString *currentLaTeX;
@property (nonatomic, retain) NSImage *currentImage;
@property float currentScaleFactor;
@end

@implementation AILaTeXProcessor

@synthesize newMessage, originalAttributedString, context, uniqueID, scanner;
@synthesize currentFileRoot, currentLaTeX, currentImage, currentScaleFactor;

static NSString *latexcmd, *dvipscmd, *pspdfcmd;

+ (void)initialize
{
	if (self == [AILaTeXProcessor class]) {
		// get program paths
		srandom([NSDate timeIntervalSinceReferenceDate]);

		latexcmd = [[[self class] getPathForProgram:@"latex"] retain];
		dvipscmd = [[[self class] getPathForProgram:@"dvips"] retain];
		pspdfcmd = [[[self class] getPathForProgram:@"pstopdf"] retain];
		if (!pspdfcmd)
			pspdfcmd = [[[self class] getPathForProgram:@"ps2pdf"] retain];
		NSLog(@"Got programs: %@ %@ %@", latexcmd, dvipscmd, pspdfcmd);
	}
}
	
+ (BOOL)latexIsInstalled
{
	return (latexcmd && dvipscmd && pspdfcmd);
}

+ (void)processString:(NSAttributedString *)inAttributedString context:(id)inContext uniqueID:(unsigned long long)inUniqueID
{
	if (![[self class] latexIsInstalled])
		NSLog(@"ERROR: NO LATEX");
	
	/* Will release itself when done */
	AILaTeXProcessor *processor = [[AILaTeXProcessor alloc] init];
	processor.originalAttributedString = inAttributedString;
	processor.context = inContext;
	processor.uniqueID = inUniqueID;
	[processor begin];
}

#pragma mark -

- (void)finishedProcessing
{
	NSLog(@"Finished with %@", self.newMessage);
	[adium.contentController delayedFilterDidFinish:self.newMessage uniqueID:self.uniqueID];
	[self release];
}

#pragma mark -

- (void)begin
{
	self.newMessage = [[[NSMutableAttributedString alloc] init] autorelease];
	self.scanner = [[[NSScanner alloc] initWithString:self.originalAttributedString.string] autorelease];
	[self.scanner setCharactersToBeSkipped:[[[NSCharacterSet alloc] init] autorelease]];

	[self procesLaTeX];
}

- (void)procesLaTeX
{
	NSAttributedString *inAttributedString = self.originalAttributedString;
	NSScanner		   *stringScanner = self.scanner;

	while ([stringScanner isAtEnd] == NO) {
		NSUInteger doubleDollar = [inAttributedString.string rangeOfString:@"$$" options:NSLiteralSearch range:NSMakeRange(stringScanner.scanLocation,
																																	  inAttributedString.length - stringScanner.scanLocation)].location;
		NSUInteger slashBracket = [inAttributedString.string rangeOfString:@"\\[" options:NSLiteralSearch range:NSMakeRange(stringScanner.scanLocation,
																																	   inAttributedString.length - stringScanner.scanLocation)].location;
		// If there's nothing else, just slap it on the end of newMessage
		if (doubleDollar == NSNotFound && slashBracket == NSNotFound) {
			[self.newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange(stringScanner.scanLocation,
																											inAttributedString.length - stringScanner.scanLocation)]];
			[self finishedProcessing];
			break;
		}
		
		// Read in the contents between the markers
		NSString *innerLaTeX = nil;
		NSUInteger i = 0;
		
		if (doubleDollar < slashBracket) {
			// Grab the stuff leading up to the LaTeX
			i = stringScanner.scanLocation;
			if ([stringScanner scanUpToString:@"$$" intoString:nil]) {
				[self.newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange(i, stringScanner.scanLocation - i)]];
			}
			
			// Make sure we have a close tag
			if ([[inAttributedString string] rangeOfString:@"$$" options:NSLiteralSearch range:NSMakeRange(doubleDollar + 2, inAttributedString.length - doubleDollar - 2)].location == NSNotFound) {
				//We don't have a close tag :(
				NSLog(@"No close tag :(");

				[self.newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange(stringScanner.scanLocation, 2)]];
				[stringScanner scanString:@"$$" intoString:nil];
				continue;
			}
			
			// Grab the inner LaTeX code
			[stringScanner scanString:@"$$" intoString:nil];
			i = stringScanner.scanLocation;
			if ([stringScanner scanUpToString:@"$$" intoString:&innerLaTeX]) {
				[stringScanner scanString:@"$$" intoString:nil];
			}
			
		} else {
			// Grab the stuff leading up to the LaTeX
			i = stringScanner.scanLocation;
			if ([stringScanner scanUpToString:@"\\[" intoString:nil]) {
				[self.newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange(i, stringScanner.scanLocation - i)]];
			}
			
			// Make sure we have a close tag
			if ([[inAttributedString string] rangeOfString:@"\\]" options:NSLiteralSearch range:NSMakeRange(slashBracket + 2, inAttributedString.length - slashBracket - 2)].location == NSNotFound) {
				//We don't have a close tag :(
				[self.newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange(stringScanner.scanLocation, 2)]];
				[stringScanner scanString:@"\\[" intoString:nil];
				continue;
			}
			
			// Grab the inner LaTeX code
			[stringScanner scanString:@"\\[" intoString:nil];
			i = stringScanner.scanLocation;
			if ([stringScanner scanUpToString:@"\\]" intoString:&innerLaTeX]) {
				[stringScanner scanString:@"\\]" intoString:nil];
			}
		}
		
		NSLog(@"inner is %@", innerLaTeX);
		if (innerLaTeX) {			
			// Get the color from our attributed string
			NSColor *color = [inAttributedString attribute:NSForegroundColorAttributeName atIndex:i effectiveRange:NULL];

			// create image from LaTeX
			NSLog(@"Begin processing");
			self.currentScaleFactor = ([[self.originalAttributedString attribute:NSFontAttributeName atIndex:i effectiveRange:NULL] pointSize] / 12.0) * 1.3; // 1.3 chosen to fit the author's aesthetics
			self.currentLaTeX = innerLaTeX;
			[self appendImageFromLatex:[NSString stringWithFormat:@"$ %@ $", innerLaTeX] color:color];

			//Stop for now; we'll resume processing once the image has been appended
			break;
		}
	}
}	

- (NSString *)filepath
{
	return [NSTemporaryDirectory() stringByAppendingPathComponent:self.currentFileRoot];
}
- (NSString *)fileOfType:(NSString *)type
{
	return [self.filepath stringByAppendingPathComponent:[self.currentFileRoot stringByAppendingPathExtension:type]];
}

/* 1 */
- (void)latexDidFinish:(NSNotification *)notification
{
	NSTask *task = [notification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self
												 name:NSTaskDidTerminateNotification
											   object:task];
	[task release]; /* Alloc in imageFromLaTeX: */

	if (![[NSFileManager defaultManager] fileExistsAtPath:[self fileOfType:@"dvi"]]) {
		NSLog(@"No dvi :(");
		[self didFinishProcessingLaTeXString];
		return;
	}

	// convert DVI to PS
	task = [[NSTask alloc] init]; /* Release when finished */
	[task setCurrentDirectoryPath:self.filepath];
	[task setLaunchPath:dvipscmd];
	[task setArguments:[NSArray arrayWithObjects:@"-E", @"-o", [self fileOfType:@"ps"], [self fileOfType:@"dvi"], nil]];
	[task launch];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dviDidFinish:)
												 name:NSTaskDidTerminateNotification
											   object:task];
}

/* 2 */
- (void)dviDidFinish:(NSNotification *)notification
{
	NSTask *task = [notification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSTaskDidTerminateNotification
												  object:task];
	[task release]; /* Alloc in latexDidFinish: */

	if (![[NSFileManager defaultManager] fileExistsAtPath:[self fileOfType:@"ps"]]) {
		NSLog(@"No ps :(");
		[self didFinishProcessingLaTeXString];
		return;
	}

	// convert PS to PDF
	task = [[NSTask alloc] init];  /* Release when finished */
	[task setCurrentDirectoryPath:self.filepath];
	[task setLaunchPath:pspdfcmd];
	[task setArguments:[NSArray arrayWithObjects:[self fileOfType:@"ps"], nil]];
	[task launch];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(psDidFinish:)
												 name:NSTaskDidTerminateNotification
											   object:task];
}

/* 3 */
- (void)psDidFinish:(NSNotification *)notification
{
	NSTask *task = [notification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSTaskDidTerminateNotification
												  object:task];
	[task release]; /* Alloc in dviDidFinish: */

	if (![[NSFileManager defaultManager] fileExistsAtPath:[self fileOfType:@"pdf"]]) {
		NSLog(@"No pdf :(");
		[self didFinishProcessingLaTeXString];
		return;
	}

	//Load image
	self.currentImage = [[[NSImage alloc] initWithContentsOfFile:[self fileOfType:@"pdf"]] autorelease];
	[self didFinishProcessingLaTeXString];
}

/*!
 * @brief Finished processing one LaTeX string (which may be part of the larger message or may be the whole message)
 *
 * self.currentImage will be set to an image if we were succesful. It will be nil otherwise.
 */
- (void)didFinishProcessingLaTeXString
{
	NSLog(@"%@: Did finish with %@ (%@) for %@",
		  self,
		  self.currentImage, [self fileOfType:@"pdf"], self.currentLaTeX);
	if (self.currentImage) {
		NSSize imgSize = self.currentImage.size;
		imgSize.width *= self.currentScaleFactor;
		imgSize.height *= self.currentScaleFactor;
		[self.currentImage setSize:imgSize];
		
		[self.newMessage appendAttributedString:[self attributedStringWithImage:self.currentImage
																 textEquivalent:self.currentLaTeX]];
		NSLog(@"Now have %@", self.newMessage);
	}

	// clear temporary files
	[[NSFileManager defaultManager] removeFileAtPath:self.filepath handler:nil];
	self.currentImage = nil;	
	self.currentFileRoot = nil;
	self.currentLaTeX = nil;

	//Return to processing
	[self procesLaTeX];
}

/*!
 * @brief Returns an attributed string containing the image corresponding to the given LaTeX commands
 */
- (void)appendImageFromLatex:(NSString *)bodyLaTeX color:(NSColor *)color 
{	
	//Construct filenames and temporary directory
	self.currentFileRoot = [NSString stringWithFormat:@"AdiumLaTeXPlugin.%i", random()];

	if (![[NSFileManager defaultManager] createDirectoryAtPath:self.filepath attributes:nil]) {
		[self didFinishProcessingLaTeXString];
		return;
	}
	
	// construct LaTeX file
	NSMutableString* preamble = [[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]]
																				  pathForResource:@"preamble"
																				  ofType:@"tex"]] autorelease];
	[preamble replaceOccurrencesOfString:@"%%content%%"
							  withString:bodyLaTeX
								 options:NSCaseInsensitiveSearch
								   range:NSMakeRange(0, preamble.length)];
	if (color != nil) {
		NSColor *rgbColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		[preamble replaceOccurrencesOfString:@"%%color%%"
								  withString:[NSString stringWithFormat:@"\\color[rgb]{%f, %f, %f}", [rgbColor redComponent], [rgbColor greenComponent], [rgbColor blueComponent]]
									 options:NSCaseInsensitiveSearch
									   range:NSMakeRange(0, [preamble length])];
	}
	if (![preamble writeToFile:[self fileOfType:@"tex"] atomically:NO encoding:NSASCIIStringEncoding error:NULL]) {
		[self didFinishProcessingLaTeXString];
		return;
	}
	
	// apply LaTeX to get a DVI file
	NSTask *task = [[NSTask alloc] init]; /* Release when finished */
	[task setCurrentDirectoryPath:self.filepath];
	[task setLaunchPath:latexcmd];
	[task setArguments:[NSArray arrayWithObjects:[self fileOfType:@"tex"], nil]];
	[task launch];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(latexDidFinish:)
												 name:NSTaskDidTerminateNotification
											   object:task];	
}

/*!
 * @brief Returns an attributed string containing the image
 */
- (NSAttributedString *)attributedStringWithImage:(NSImage *)img textEquivalent:(NSString *)textEquivalent
{
    NSTextAttachmentCell		*cell = [[NSTextAttachmentCell alloc] initImageCell:img];
    AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
    NSAttributedString			*attachString;
    
    [attachment setAttachmentCell:cell];
    [attachment setShouldSaveImageForLogging:NO];
	[attachment setString:textEquivalent];
	[attachment setHasAlternate:YES];
	
	// this section is a hack so that the image can have alternate text corresponding to the LaTeX command
	// but the filename of the image on the filesystem is not the LaTeX command, because things like $$1/x$$ 
	// break it then
	NSString *gus = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:gus];
	NSString *filename = [gus stringByAppendingPathExtension:@"png"];
	[[NSFileManager defaultManager] createDirectoryAtPath:tmpDir attributes:nil];
	[attachment setPath:[tmpDir stringByAppendingPathComponent:filename]];
	[[img PNGRepresentation] writeToFile:[tmpDir stringByAppendingPathComponent:filename] atomically:NO];
	
	[attachment setImage:img];
    attachString = [NSAttributedString attributedStringWithAttachment:attachment];

    [cell release];
    [attachment release];
	
    return attachString;
}

#pragma mark -

- (void)dealloc
{
	self.newMessage = nil;
	self.originalAttributedString = nil;
	self.context = nil;
	self.scanner = nil;

	self.currentImage = nil;	
	self.currentFileRoot = nil;
	self.currentLaTeX = nil;
	
	[super dealloc];
}

#pragma mark -

/*!
 * @brief Returns a string containing the path for the given program (which is found by using the bash command which)
 */
+ (NSString *)getPathForProgram:(NSString *)progname
{
	NSTask *task;
	NSData *d;
	
	// assemble the bash command "which progname"
	task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/bin/bash"];
	[task setArguments:[NSArray arrayWithObjects:@"--login", @"-c", [NSString stringWithFormat:@"which %@", progname], nil]];
	[task setStandardOutput:[NSPipe pipe]];
	[task launch];
	[task waitUntilExit];
	
	// read the output of the shell
	d = [[[task standardOutput] fileHandleForReading] availableData];
	if ((d != nil) && [d length]) {
		return [[[[NSString alloc] initWithData:d
									   encoding:NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
	
	return nil;
	
}


@end
