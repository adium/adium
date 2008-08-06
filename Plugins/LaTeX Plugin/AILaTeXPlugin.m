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
#import <Adium/AITextAttachmentExtension.h>

#import <AIUtilities/AITigerCompatibility.h>
#import <AIUtilities/AIImageAdditions.h>

#import "AILaTeXPlugin.h"

@interface AILaTeXPlugin (PRIVATE)
+ (NSMutableAttributedString *)attributedStringWithImage:(NSImage *)img textEquivalent:(NSString *)textEquivalent;
+ (NSImage *)imageFromLaTeX:(NSString *)bodyLaTeX color:(NSColor *)color;
+ (NSString *)getPathForProgram:(NSString *)progname;
@end

/*!
 * @class AILaTeXPlugin
 * @brief Filter plugin which converts $$xxx$$ or \[xxx\], where xxx is a LaTeX expression, to LaTeX
 */
@implementation AILaTeXPlugin

- (void)installPlugin
{
	// only filter messages as we display them; do not transform the messages actually sent
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterOutgoing];
	[[adium contentController] registerContentFilter:self ofType:AIFilterMessageDisplay direction:AIFilterIncoming];
}

- (void)uninstallPlugin
{
	[[adium contentController] unregisterContentFilter:self];
}

/*!
 * @brief Applies the LaTeX filters to the given string
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{	
	// it doesn't seem possible to rescale the images in Mac OS X 10.4, but it does change the box size leaving lots of
	// white space around the image, so we only want to rescale images in Mac OS X 10.5 or higher
	BOOL rescale = (floor(NSAppKitVersionNumber) > 824 /* NSAppKitVersionNumber10_4 */);
	
	NSMutableAttributedString *newMessage = [[[NSMutableAttributedString alloc] init] autorelease];
	
	NSScanner *stringScanner = [[NSScanner alloc] initWithString:[inAttributedString string]];
	[stringScanner setCharactersToBeSkipped:[[[NSCharacterSet alloc] init] autorelease]];
		
	while ([stringScanner isAtEnd] == NO) {
		NSUInteger doubleDollar = [[inAttributedString string] rangeOfString:@"$$" options:NSLiteralSearch range:NSMakeRange([stringScanner scanLocation], [inAttributedString length] - [stringScanner scanLocation])].location;
		NSUInteger slashBracket = [[inAttributedString string] rangeOfString:@"\\[" options:NSLiteralSearch range:NSMakeRange([stringScanner scanLocation], [inAttributedString length] - [stringScanner scanLocation])].location;
		
		// If there's nothing else, just slap it on the end of newMessage
		if (doubleDollar == NSNotFound && slashBracket == NSNotFound) {
			[newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange([stringScanner scanLocation], [inAttributedString length] - [stringScanner scanLocation])]];
			break;
		}
		
		// Read in the contents between the markers
		NSString *innerLaTeX = nil;
		NSUInteger i = 0;
		
		if (doubleDollar < slashBracket) {
			// Grab the stuff leading up to the LaTeX
			i = [stringScanner scanLocation];
			if ([stringScanner scanUpToString:@"$$" intoString:nil]) {
				[newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange(i, [stringScanner scanLocation] - i)]];
			}
			
			// Make sure we have a close tag
			if ([[inAttributedString string] rangeOfString:@"$$" options:NSLiteralSearch range:NSMakeRange(doubleDollar + 2, [inAttributedString length] - doubleDollar - 2)].location == NSNotFound) {
				[newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange([stringScanner scanLocation], 2)]];
				[stringScanner scanString:@"$$" intoString:nil];
				continue;
			}
			
			// Grab the inner LaTeX code
			[stringScanner scanString:@"$$" intoString:nil];
			i = [stringScanner scanLocation];
			if ([stringScanner scanUpToString:@"$$" intoString:&innerLaTeX]) {
				[stringScanner scanString:@"$$" intoString:nil];
			}
			
		} else {
			// Grab the stuff leading up to the LaTeX
			i = [stringScanner scanLocation];
			if ([stringScanner scanUpToString:@"\\[" intoString:nil]) {
				[newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange(i, [stringScanner scanLocation] - i)]];
			}
			
			// Make sure we have a close tag
			if ([[inAttributedString string] rangeOfString:@"\\]" options:NSLiteralSearch range:NSMakeRange(slashBracket + 2, [inAttributedString length] - slashBracket - 2)].location == NSNotFound) {
				[newMessage appendAttributedString:[inAttributedString attributedSubstringFromRange:NSMakeRange([stringScanner scanLocation], 2)]];
				[stringScanner scanString:@"\\[" intoString:nil];
				continue;
			}
			
			// Grab the inner LaTeX code
			[stringScanner scanString:@"\\[" intoString:nil];
			i = [stringScanner scanLocation];
			if ([stringScanner scanUpToString:@"\\]" intoString:&innerLaTeX]) {
				[stringScanner scanString:@"\\]" intoString:nil];
			}
		}
		
		if (innerLaTeX) {			
			// Get the color from our attributed string
			NSColor *color = [inAttributedString attribute:NSForegroundColorAttributeName atIndex:i effectiveRange:NULL];

			// create image from LaTeX
			NSImage *tempImage = [[self class] imageFromLaTeX:[NSString stringWithFormat:@"$ %@ $", innerLaTeX] color:color];
			if (tempImage != nil) {
				// rescale the image on Mac OS X 10.5 and higher to try to match the size of the surrounding text
				if (rescale) {
					NSSize imgSize = [tempImage size];
					float scalefactor = ([[inAttributedString attribute:NSFontAttributeName atIndex:i effectiveRange:NULL] pointSize] / 12.0) * 1.3; // 1.3 chosen to fit the author's aesthetics
					imgSize.width *= scalefactor;
					imgSize.height *= scalefactor;
					[tempImage setSize:imgSize];
				}
				
				[newMessage appendAttributedString:[[self class] attributedStringWithImage:tempImage textEquivalent:innerLaTeX]];
			}
		}
	}
	
	[stringScanner release];

	return newMessage;

}

- (float)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

/*!
 * @brief Returns a string containing the path for the given program (which is found by using the bash command which)
 */
+ (NSString *)getPathForProgram:(NSString *)progname {

	NSTask *task;
	NSData *d;
	
	// assemble the bash command "which progname"
	task = [[NSTask alloc] init];
	[task setLaunchPath:@"/bin/bash"];
	[task setArguments:[NSArray arrayWithObjects:@"--login", @"-c", [NSString stringWithFormat:@"which %@", progname], nil]];
	[task setStandardOutput:[NSPipe pipe]];
	[task launch];
	[task waitUntilExit];
	
	// read the output of the shell
	d = [[[task standardOutput] fileHandleForReading] availableData];
	if ((d != nil) && [d length]) {
		return [[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}

	return nil;

}

/*!
 * @brief Returns an attributed string containing the image corresponding to the given LaTeX commands
 */
+ (NSImage *)imageFromLaTeX:(NSString *)bodyLaTeX color:(NSColor *)color 
{
	
	NSImage *res = nil;
	NSTask *task = nil;

	// get program names
	NSString* latexcmd = [[self class] getPathForProgram:@"latex"];
	if (latexcmd == nil) { return nil; }
	NSString* dvipscmd = [[self class] getPathForProgram:@"dvips"];
	if (dvipscmd == nil) { return nil; }
	NSString* pspdfcmd = [[self class] getPathForProgram:@"pstopdf"];
	if (pspdfcmd == nil) {
		pspdfcmd = [[self class] getPathForProgram:@"ps2pdf"];
	}
	if (pspdfcmd == nil) { return nil; }
		
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// construct filenames and temporary directory
	srandom([NSDate timeIntervalSinceReferenceDate]);
	NSString* fileroot = [NSString stringWithFormat:@"AdiumLaTeXPlugin.%i", random()];
	NSString* filepath = [NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), fileroot];
	if (![fm createDirectoryAtPath:filepath attributes:nil]) { goto err; }
	NSString* filetex  = [NSString stringWithFormat:@"%@/%@.tex", filepath, fileroot];
	NSString* filedvi  = [NSString stringWithFormat:@"%@/%@.dvi", filepath, fileroot];
	NSString* fileps   = [NSString stringWithFormat:@"%@/%@.ps",  filepath, fileroot];
	NSString* filepdf  = [NSString stringWithFormat:@"%@/%@.pdf", filepath, fileroot];
	
	// construct LaTeX file
	NSMutableString* preamble = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"preamble" ofType:@"tex"]];
	[preamble replaceOccurrencesOfString:@"%%content%%" withString:bodyLaTeX options:NSCaseInsensitiveSearch range:NSMakeRange(0, [preamble length])];
	if (color != nil) {
		NSColor *rgbColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		[preamble replaceOccurrencesOfString:@"%%color%%" withString:[NSString stringWithFormat:@"\\color[rgb]{%f, %f, %f}", [rgbColor redComponent], [rgbColor greenComponent], [rgbColor blueComponent]] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [preamble length])];
	}
	if (![preamble writeToFile:filetex atomically:NO encoding:NSASCIIStringEncoding error:NULL]) { goto err; }
	
	// apply LaTeX to get a DVI file
	task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath:filepath];
	[task setLaunchPath:latexcmd];
	[task setArguments:[NSArray arrayWithObjects:filetex, nil]];
	[task launch];
	[task waitUntilExit];
	if (![fm fileExistsAtPath:filedvi]) { goto err; }
	
	// convert DVI to PS
	task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath:filepath];
	[task setLaunchPath:dvipscmd];
	[task setArguments:[NSArray arrayWithObjects:@"-E", @"-o", fileps, filedvi, nil]];
	[task launch];
	[task waitUntilExit];
	if (![fm fileExistsAtPath:fileps]) { goto err; }
	
	// convert PS to PDF
	task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath:filepath];
	[task setLaunchPath:pspdfcmd];
	[task setArguments:[NSArray arrayWithObjects:fileps, nil]];
	[task launch];
	[task waitUntilExit];
	if (![fm fileExistsAtPath:filepdf]) { goto err; }
	
	// load image
	res = [[NSImage alloc] initWithContentsOfFile:filepdf];
	
  err:
	
	// clear temporary files
	[fm removeFileAtPath:filepath handler:nil];
	
	return res;
	
}

/*!
 * @brief Returns an attributed string containing the image
 */
+ (NSMutableAttributedString *)attributedStringWithImage:(NSImage *)img textEquivalent:(NSString *)textEquivalent
{
    NSTextAttachmentCell		*cell = [[NSTextAttachmentCell alloc] initImageCell:img];
    AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
    NSMutableAttributedString	*attachString;
    
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
    attachString = [[[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy] autorelease];
    
    [cell release];
    [attachment release];

    return attachString;
}

@end
