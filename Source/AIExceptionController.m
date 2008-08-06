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

#import "AICrashReporter.h"
#import "AIExceptionController.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <ExceptionHandling/NSExceptionHandler.h>
#include <unistd.h>

/*!
 * @class AIExceptionController
 * @brief Catches application exceptions and forwards them to the crash reporter application
 *
 * Once configured, sets itself as the NSExceptionHandler delegate to decode the stack traces
 * generated via NSExceptionHandler, write them to a file, and launch the crash reporter.
 */
@implementation AIExceptionController

//Enable exception catching for the crash reporter
static BOOL catchExceptions = NO;

//These exceptions can be safely ignored.
static NSSet *safeExceptionReasons = nil, *safeExceptionNames = nil;

+ (void)enableExceptionCatching
{
    //Log and Handle all exceptions
	NSExceptionHandler *exceptionHandler = [NSExceptionHandler defaultExceptionHandler];
    [exceptionHandler setExceptionHandlingMask:(NSHandleUncaughtExceptionMask |
												NSHandleUncaughtSystemExceptionMask | 
												NSHandleUncaughtRuntimeErrorMask |
												NSHandleTopLevelExceptionMask /*|
												NSHandleOtherExceptionMask*/)];
	[exceptionHandler setDelegate:self];

	catchExceptions = YES;

	//Remove any existing exception logs
    [[NSFileManager defaultManager] trashFileAtPath:EXCEPTIONS_PATH];

	//Set up exceptions to except
	//More of these (matched by substring) can be found in -raise
	if (!safeExceptionReasons) {
		safeExceptionReasons = [[NSSet alloc] initWithObjects:
			@"_sharedInstance is invalid.", //Address book framework is weird sometimes
			@"No text was found", //ICeCoffEE is an APE haxie which would crash us whenever a user pasted, or something like that
			@"No URL is selected", //ICeCoffEE also crashes us when clicking links. How obnoxious. Release software should not use NSAssert like this.
#warning Error 1000 is kCGErrorFirst. This special case was added in r5425, so long ago that it's possible that this was really supposed to be 1007, and has been fixed since then.
			@"Error (1000) creating CGSWindow", //This looks like an odd NSImage error... it occurs sporadically, seems harmless, and doesn't appear avoidable
			@"Error (1007) creating CGSWindow", //kCGErrorRangeCheck: Raised by NSImage when we create one that's bigger than a window can hold. See <http://www.cocoabuilder.com/archive/message/cocoa/2004/2/5/96193>.
			@"Access invalid attribute location 0 (length 0)", //The undo manager can throw this one when restoring a large amount of attributed text... doesn't appear avoidable
			@"Invalid parameter not satisfying: (index >= 0) && (index < (_itemArray ? CFArrayGetCount(_itemArray) : 0))", //A couple AppKit methods, particularly NSSpellChecker, seem to expect this exception to be happily thrown in the normal course of operation. Lovely. Also needed for FontSight compatibility.
			@"Invalid parameter not satisfying: (index >= 0) && (index <= (_itemArray ? CFArrayGetCount(_itemArray) : 0))", //Like the above, but <= instead of <
			@"Invalid parameter not satisfying: entry", //NSOutlineView throws this, particularly if it gets clicked while reloading or the computer sleeps while reloading
			@"Invalid parameter not satisfying: aString != nil", //The Find command can throw this, as can other AppKit methods
			nil];
	}
	if (!safeExceptionNames) {
		safeExceptionNames = [[NSSet alloc] initWithObjects:
			@"GIFReadingException", //GIF reader sucks
			@"NSPortTimeoutException", //Harmless - it timed out for a reason
			@"NSInvalidReceivePortException", //Same story as NSPortTimeoutException
			@"NSAccessibilityException", //Harmless - one day we should figure out how we aren't accessible, but not today
			@"NSImageCacheException", //NSImage is silly
			@"NSArchiverArchiveInconsistency", //Odd system hacks can lead to this one
			@"NSUnknownKeyException", //No reason to crash on invalid Applescript syntax
			@"NSObjectInaccessibleException", //We don't use DO, but spell checking does; AppleScript execution requires multiple run loops, and the HIToolbox can get confused and try to spellcheck in the applescript thread. Silly Apple.
			@"NSCharacterConversionException", //We can't help it if a character can't be converted...
			@"NSRTFException", //Better to ignore than to crash
			nil];
	}
}

// mask is NSHandle<exception type>Mask, exception's userInfo has stack trace for key NSStackTraceKey
+ (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(NSUInteger)aMask
{
	BOOL		shouldLaunchCrashReporter = YES;
	if (catchExceptions) {
		NSString	*theReason = [exception reason];
		NSString	*theName   = [exception name];
		NSString	*backtrace = nil;

		//Ignore various known harmless or unavoidable exceptions (From the system or system hacks)
		if ((!theReason) || //Harmless
			[safeExceptionReasons containsObject:theReason] || 
			[theReason rangeOfString:@"NSRunStorage, _NSBlockNumberForIndex()"].location != NSNotFound || //NSLayoutManager throws this for fun in a purely-AppKit stack trace
			[theReason rangeOfString:@"Broken pipe"].location != NSNotFound || //libezv throws broken pipes as NSFileHandleOperationException with this in the reason; I'd rather we watched for "broken pipe" than ignore all file handle errors
			[theReason rangeOfString:@"incomprehensible archive"].location != NSNotFound || //NSKeyedUnarchiver can get confused and throw this; it's out of our control
			[theReason rangeOfString:@"-whiteComponent not defined"].location != NSNotFound || //Random NSColor exception for certain coded color values
			[theReason rangeOfString:@"Failed to get fache"].location != NSNotFound || //Thrown by NSFontManager when availableFontFamilies is called if it runs into a corrupt font
			[theReason rangeOfString:@"NSWindow: -_newFirstResponderAfterResigining"].location != NSNotFound || //NSAssert within system code, harmless
			[theReason rangeOfString:@"-patternImage not defined"].location != NSNotFound || //Painters Color Picker throws an exception during the normal course of operation.  Don't you hate that?
			[theReason rangeOfString:@"Failed to set font"].location != NSNotFound || //Corrupt fonts
			[theReason rangeOfString:@"Delete invalid attribute range"].location != NSNotFound || //NSAttributedString's initWithCoder can throw this
			[theReason rangeOfString:@"NSMutableRLEArray objectAtIndex:effectiveRange:: Out of bounds"].location != NSNotFound || //-[NSLayoutManager textContainerForGlyphAtIndex:effectiveRange:] as of 10.4 can throw this
			[theReason rangeOfString:@"TSMProcessRawKeyCode failed"].location != NSNotFound || //May be raised by -[NSEvent charactersIgnoringModifiers]
			[theReason rangeOfString:@"Invalid PMPrintSettings in print info"].location != NSNotFound || //Invalid saved print settings can make the print dialogue throw this
			[theReason rangeOfString:@"-[NSConcreteTextStorage attribute:atIndex:effectiveRange:]: Range or index out of bounds"].location != NSNotFound || //Can't find the source of this, but it seems to happen randomly and not provide a stack trace.
			[theReason rangeOfString:@"SketchUpColor"].location != NSNotFound || //NSColorSwatch addition which can yield an exception
			[theReason rangeOfString:@"-[NSConcreteFileHandle dealloc]: Bad file descriptor"].location != NSNotFound || // NSFileHandle on an invalid file descriptor should log but not crash
			(!theName) || //Harmless
			[theName rangeOfString:@"RSS"].location != NSNotFound || //Sparkle's RSS handling whines sometimes, but we don't care.
		   [safeExceptionNames containsObject:theName])
		{
			shouldLaunchCrashReporter = NO;
		}
		
		//Check the stack trace for a third set of known offenders
		if (shouldLaunchCrashReporter) {
			backtrace = [exception decodedExceptionStackTrace];
		}
		if (!backtrace ||
			[backtrace rangeOfString:@"-[NSFontPanel setPanelFont:isMultiple:] (in AppKit)"].location != NSNotFound || //NSFontPanel likes to create exceptions
			[backtrace rangeOfString:@"-[NSScrollView(NSScrollViewAccessibility) accessibilityChildrenAttribute]"].location != NSNotFound || //Perhaps we aren't implementing an accessibility method properly? No idea what though :(
			[backtrace rangeOfString:@"-[WebBridge objectLoadedFromCacheWithURL:response:data:]"].location != NSNotFound || //WebBridge throws this randomly it seems
			[backtrace rangeOfString:@"-[NSTextView(NSSharing) _preflightSpellChecker:]"].location != NSNotFound || //Systemwide spell checker gets corrupted on some systems; other apps just end up logging to console, and we should do the same.
			[backtrace rangeOfString:@"-[NSFontManager(NSFontManagerCollectionAdditions) _collectionsChanged:]"].location != NSNotFound || //Deleting an empty collection in 10.4.3 (and possibly other versions) throws an NSRangeException with this in the backtrace.
			[backtrace rangeOfString:@"[NSSpellChecker sharedSpellChecker]"].location != NSNotFound //The spell checker screws up and starts throwing an exception on every word on many people's systems.
		   )
		{
			   shouldLaunchCrashReporter = NO;
		}

		if (shouldLaunchCrashReporter) {
			NSString	*bundlePath = [[NSBundle mainBundle] bundlePath];
			NSString	*crashReporterPath = [bundlePath stringByAppendingPathComponent:RELATIVE_PATH_TO_CRASH_REPORTER];
			NSString	*versionString = [[NSProcessInfo processInfo] operatingSystemVersionString];
			NSString	*preferredLocalization = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];
	
			NSLog(@"Launching the Adium Crash Reporter because an exception of type %@ occurred:\n%@", theName,theReason);

			//Pass the exception to the crash reporter and close this application
			[[NSString stringWithFormat:@"OS Version:\t%@\nLanguage:\t%@\nException:\t%@\nReason:\t%@\nStack trace:\n%@",
				versionString,preferredLocalization,theName,theReason,backtrace] writeToFile:EXCEPTIONS_PATH atomically:YES];

			[[NSWorkspace sharedWorkspace] openFile:bundlePath withApplication:crashReporterPath];

			exit(-1);
		} else {
			/*
			NSLog(@"The following unhandled exception was ignored: %@ (%@)\nStack trace:\n%@",
				  theName,
				  theReason,
				  (backtrace ? backtrace : @"(Unavailable)"));
			AILog(@"The following unhandled exception was ignored: %@ (%@)\nStack trace:\n%@",
				  theName,
				  theReason,
				  (backtrace ? backtrace : @"(Unavailable)"));
			 */
		}
	}

	return shouldLaunchCrashReporter;
}

@end

@implementation NSException (AIExceptionControllerAdditions)
//Decode the stack trace within [self userInfo] and return it
- (NSString *)decodedExceptionStackTrace
{
	NSDictionary    *dict = [self userInfo];
	NSString        *stackTrace = nil;

	//Turn the nonsense of memory addresses into a human-readable backtrace complete with line numbers
	if (dict && (stackTrace = [dict objectForKey:NSStackTraceKey])) {
		NSMutableString		*processedStackTrace;
		NSString			*str;
		
		/*We use several command line apps to decode our exception:
		 *	* atos -p PID addresses...: converts addresses (hex numbers) to symbol names that we can read.
		 *	* tail -n +3: strip the first three lines.
		 *	* head -n +NUM: reduces to the first NUM lines. we pass NUM as the number of addresses minus 4.
		 *	* c++filt: de-mangles C++ names.
		 *		example, before:
		 *			__ZNK12CApplication23CreateClipboardTextViewERsR12CViewManager (in TextWrangler)
		 *		example, after:
		 *			CApplication::CreateClipboardTextView(short&, CViewManager&) const (in TextWrangler)
		 *	* cat -n: adds line numbers. fairly meaningless, but fun.
		 */
#warning 64BIT: Check formatting arguments
		str = [NSString stringWithFormat:@"%s -p %d %@ | tail -n +3 | head -n +%d | %s | cat -n",
			[[[[NSBundle mainBundle] pathForResource:@"atos" ofType:nil] stringByEscapingForShell] fileSystemRepresentation], //atos arg 0
			[[NSProcessInfo processInfo] processIdentifier], //atos arg 2 (argument to -p)
			stackTrace, //atos arg 3..inf
			([[stackTrace componentsSeparatedByString:@"  "] count] - 4), //head arg 3
			[[[[NSBundle mainBundle] pathForResource:@"c++filt" ofType:nil] stringByEscapingForShell] fileSystemRepresentation]]; //c++filt arg 0	

		FILE *file = popen( [str UTF8String], "r" );
		NSMutableData *data = [[NSMutableData alloc] init];

		if (file) {
			NSZone	*zone = [self zone];

			size_t	 bufferSize = getpagesize();
			char	*buffer = NSZoneMalloc(zone, bufferSize);
			if (!buffer) {
				buffer = alloca(bufferSize = 512);
				zone = NULL;
			}

			size_t	 amountRead;

			while ((amountRead = fread(buffer, sizeof(char), bufferSize, file))) {
				[data appendBytes:buffer length:amountRead];
			}

			if (zone) NSZoneFree(zone, buffer);

			pclose(file);
		}

		//we use ISO 8859-1 because it preserves all bytes. UTF-8 doesn't (beacuse
		//	certain sequences of bytes may get added together or cause the string to be rejected).
		//and it shouldn't matter; we shouldn't be getting high-ASCII in the backtrace anyway. :)
		processedStackTrace = [[[NSMutableString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
		[data release];
		
		//Clear out a useless string inserted into some stack traces as of 10.4 to improve crashlog readability
		[processedStackTrace replaceOccurrencesOfString:@"task_start_peeking: can't suspend failed  (ipc/send) invalid destination port"
											 withString:@""
												options:NSLiteralSearch
												  range:NSMakeRange(0, [processedStackTrace length])];
		
		return processedStackTrace;
	}
	
	//If we are unable to decode the stack trace, return the best we have
	return stackTrace;
}

@end
