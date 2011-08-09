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

#define RELATIVE_PATH_TO_CRASH_REPORTER	 @"/Contents/Resources/Adium Crash Reporter.app"
#define EXCEPTIONS_PATH					[@"~/Library/Logs/CrashReporter/Adium.exception.log" stringByExpandingTildeInPath]
#define CRASHES_PATH					[[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@.crash.log", \
										[[NSProcessInfo processInfo] processName]] stringByExpandingTildeInPath]

@class AIAutoScrollView, AITextViewWithPlaceholder, SUStatusChecker;
@protocol SUStatusCheckerDelegate;

@interface AICrashReporter : NSObject <SUStatusCheckerDelegate> {
	IBOutlet	NSWindow                    *window_MainWindow;
	IBOutlet	NSTextField                 *textField_emailAddress;
	IBOutlet	NSTextField                 *textField_accountIM;
	IBOutlet	NSTextField                 *textField_description;
	
	IBOutlet	AIAutoScrollView			*scrollView_details;
	IBOutlet	AITextViewWithPlaceholder   *textView_details;

	IBOutlet	NSProgressIndicator         *progress_sending;
	IBOutlet	NSButton					*button_close;
	
	IBOutlet	NSPanel                     *panel_privacySheet;
	IBOutlet	NSTextView                  *textView_crashLog;
    
	NSString                                *crashLog;		//Current crash log
    
	NSDate									*buildDate;
	NSString                                *buildNumber, *buildUser;
	NSAppleScript                           *slayerScript;

    NSString                                *adiumPath;
	SUStatusChecker							*statusChecker;
	
	BOOL									sentCrashLog;
}

- (void)awakeFromNib;

- (IBAction)showPrivacyDetails:(id)sender;
- (IBAction)closePrivacyDetails:(id)sender;

- (BOOL)reportCrashForLogAtPath:(NSString *)inPath;
- (void)sendReport:(NSDictionary *)crashReport;
- (IBAction)send:(id)sender;

- (void)_loadBuildInformation;

@end
