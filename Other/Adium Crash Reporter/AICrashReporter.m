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
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <sys/sysctl.h>

#define CRASH_REPORT_URL			@"https://sdk.hockeyapp.net/"
#define HOCKEY_APP_ID				@"a703119f260a58377333db4a07fecadb"

#define AUTOMATICALLY_SEND_CRASHES	@"Automatically Send Crash Reports"
#define LAST_CRASH_DATE				@"lastKnownCrashDate"
#define CRASH_LOG_DIRECTORY			[@"~/Library/Logs/DiagnosticReports" stringByStandardizingPath]

#define UNABLE_TO_SEND				AILocalizedString(@"Unable to send crash report",nil)

@implementation AICrashReporter
@synthesize crashLog;

+ (void)checkForCrash
{
	//Don't do anything if we're not allowed to
	if ([[adium.preferenceController preferenceForKey:KEY_CONFIRM_SEND_CRASH
												group:PREF_GROUP_CONFIRMATIONS] boolValue])
		return;
	
	AICrashReporter *reporter = [[AICrashReporter alloc] init];
	[reporter _checkForCrash];
}

- (void)_checkForCrash
{
	// get a list of files beginning with 'Adium' from the crash reporter folder
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
	NSArray *files = [fm contentsOfDirectoryAtPath:CRASH_LOG_DIRECTORY error:nil];
	NSArray *filteredFiles = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] 'Adium'"]];
	
	NSDate *mostRecentCrashDate = [NSDate distantPast];
	// Enumerate crash files to find most recent crash report
	for (NSString *file in filteredFiles) {
		NSDate *date = [[fm attributesOfItemAtPath:[CRASH_LOG_DIRECTORY stringByAppendingPathComponent:file] error:nil] objectForKey:NSFileCreationDate];
		if ([date compare:mostRecentCrashDate] == NSOrderedDescending) {
			mostRecentCrashDate = date;
			[self setCrashLog:file];
		}
	}
	
	// obtain the last known crash date from the prefs
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastKnownCrashDate = [defaults objectForKey:LAST_CRASH_DATE];
	
	// check to see if Adium crashed since the last crash (there's a newer crash report)
	if (self.crashLog && (!lastKnownCrashDate || [mostRecentCrashDate compare:lastKnownCrashDate] == NSOrderedDescending)) {
		if ([[defaults objectForKey:AUTOMATICALLY_SEND_CRASHES] boolValue]) {
			[self sendReport];
		} else {
			NSAttributedString *message = [[NSAttributedString alloc] initWithString:AILocalizedString(@"Please take a moment to send us this crash report.  It will help make Adium as stable and reliable as possible.\n\nIt is recommended that you run the latest version of Adium available, please check that you are up to date.", nil)];
			ESTextAndButtonsWindowController *crashAlert;
			crashAlert = [[ESTextAndButtonsWindowController alloc] initWithTitle:AILocalizedString(@"Send Crash Report", nil)
																   defaultButton:AILocalizedString(@"Send Report", @"Button to send a crash report")
																 alternateButton:AILocalizedString(@"Cancel", nil)
																	 otherButton:AILocalizedString(@"Always Send", @"Button for automatically sending all future crash reports")
																	 suppression:AILocalizedString(@"Don't ask again", nil)
															   withMessageHeader:AILocalizedString(@"Adium quit unexpectedly", nil)
																	  andMessage:message
																		   image:[NSImage imageNamed:@"crashDuck"]
																		  target:self
																		userInfo:nil];
			[crashAlert showOnWindow:nil];
		}
		
		// save last crash date
		[defaults setObject:mostRecentCrashDate forKey:LAST_CRASH_DATE];
	}
}

- (void)dealloc
{
	[crashLog release];
	[super dealloc];
}

- (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode suppression:(BOOL)suppression userInfo:(id)userInfo
{
	if (suppression) {
		//Don't Ask Again
		[adium.preferenceController setPreference:[NSNumber numberWithBool:YES]
										   forKey:KEY_CONFIRM_SEND_CRASH
											group:PREF_GROUP_CONFIRMATIONS];
	}
	
	switch(returnCode) {
		case AITextAndButtonsOtherReturn:
			//Always Send
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:AUTOMATICALLY_SEND_CRASHES];
		case AITextAndButtonsDefaultReturn:
			//Send
			[self sendReport];
			break;
		default:
			//Cancel
			break;
	}
	
	return YES;
}

#pragma mark Report sending
/*!
 * @brief Send a crash report to the crash reporter web site
 */
- (void)sendReport
{
    NSString *reportString = [NSString stringWithContentsOfFile:[CRASH_LOG_DIRECTORY stringByAppendingPathComponent:self.crashLog]
													   encoding:NSUTF8StringEncoding error:nil];
	
	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithRootElement:[NSXMLElement elementWithName:@"crashes"]];
	NSXMLElement *crash = [NSXMLElement elementWithName:@"crash"];
	[crash addChild:[NSXMLElement elementWithName:@"applicationname" stringValue:[self applicationName]]];
	[crash addChild:[NSXMLElement elementWithName:@"bundleidentifier" stringValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]]];
	[crash addChild:[NSXMLElement elementWithName:@"systemversion" stringValue:[self OSVersion]]];
	[crash addChild:[NSXMLElement elementWithName:@"senderversion" stringValue:[self applicationVersion]]];
	[crash addChild:[NSXMLElement elementWithName:@"version" stringValue:[self applicationVersion]]];
	[crash addChild:[NSXMLElement elementWithName:@"platform" stringValue:[self modelVersion]]];
	[crash addChild:[NSXMLElement elementWithName:@"log" stringValue:reportString]];
	[[doc rootElement] addChild:crash];
	
	NSMutableURLRequest *request = nil;
	NSString *boundary = @"----FOO";
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@api/2/apps/%@/crashes?sdk=%@&sdk_version=%@&feedbackEnabled=no",
									   CRASH_REPORT_URL,
									   [HOCKEY_APP_ID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
									   @"Adium",
									   @"1.0"
									   ]];
	request = [NSMutableURLRequest requestWithURL:url];
	
	[request setValue:@"Adium" forHTTPHeaderField:@"User-Agent"];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[request setTimeoutInterval:15];
	[request setHTTPMethod:@"POST"];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[request setValue:contentType forHTTPHeaderField:@"Content-type"];
	
	NSMutableData *postBody =  [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Disposition: form-data; name=\"xml\"; filename=\"crash.xml\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[[NSString stringWithFormat:@"Content-Type: text/xml\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];

	[postBody appendData:[doc XMLData]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	[doc release];
	
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	//Check for success and offer to try once more if there was an error sending
	if ([response statusCode] != 201) {
		NSString *reason = [NSString stringWithFormat:@"%lu: %@\n%@", response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], [error localizedDescription] ?: @""];
		if (NSRunAlertPanel(UNABLE_TO_SEND,
						reason,
						AILocalizedString(@"Try Again", nil),
						AILocalizedString(@"Close", nil),
							nil) == NSAlertDefaultReturn) {
			[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
			if ([response statusCode] != 201) {
				reason = [NSString stringWithFormat:@"%lu: %@\n%@", response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode], [error localizedDescription] ?: @""];
				NSRunAlertPanel(UNABLE_TO_SEND, reason, nil, nil, nil);
			}
		}
	}
}

#pragma mark - System/Application Information

- (NSString *) applicationName {
	NSString *applicationName = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleExecutable"];
	
	if (!applicationName)
		applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleExecutable"];
	
	return applicationName;
}


- (NSString*) applicationVersionString {
	NSString* string = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleShortVersionString"];
	
	if (!string)
		string = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleShortVersionString"];
	
	return string;
}

- (NSString *) applicationVersion {
	NSString* string = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleVersion"];
	
	if (!string)
		string = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleVersion"];
	
	return string;
}

- (NSString *) OSVersion {
	SInt32 versionMajor, versionMinor, versionBugFix;
	if (Gestalt(gestaltSystemVersionMajor, &versionMajor) != noErr) versionMajor = 0;
	if (Gestalt(gestaltSystemVersionMinor, &versionMinor) != noErr)  versionMinor= 0;
	if (Gestalt(gestaltSystemVersionBugFix, &versionBugFix) != noErr) versionBugFix = 0;
	
	return [NSString stringWithFormat:@"%i.%i.%i", versionMajor, versionMinor, versionBugFix];
}

- (NSString *) modelVersion {
	NSString * modelString  = nil;
	int        modelInfo[2] = { CTL_HW, HW_MODEL };
	size_t     modelSize;
	
	if (sysctl(modelInfo,
			   2,
			   NULL,
			   &modelSize,
			   NULL, 0) == 0) {
		void * modelData = malloc(modelSize);
		
		if (modelData) {
			if (sysctl(modelInfo,
					   2,
					   modelData,
					   &modelSize,
					   NULL, 0) == 0) {
				modelString = [NSString stringWithUTF8String:modelData];
			}
			
			free(modelData);
		}
	}
	
	return modelString;
}

@end

