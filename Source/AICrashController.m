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

/*
 Catches application crashes and forwards them to the crash reporter application
 */

#import "AICrashController.h"
#import "AICrashReporter.h"
#import <AIUtilities/AIFileManagerAdditions.h>

void CrashHandler_Signal(NSInteger i);

//Enable crash catching for the crash reporter
static AICrashController *sharedCrashController = nil;

@implementation AICrashController

+ (void)enableCrashCatching
{
	if (!sharedCrashController) {
		sharedCrashController = [[AICrashController alloc] init];
	}
}

//Init
- (id)init
{
	if ((self = [super init])) {
		//Remove any existing crash logs
		[[NSFileManager defaultManager] trashFileAtPath:[[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@.crash.log", \
			[[NSProcessInfo processInfo] processName]] stringByExpandingTildeInPath]];

		//Install custom handlers which properly terminate this application if one is received
		signal(SIGILL,  CrashHandler_Signal);	/* 4:   illegal instruction (not reset when caught) */
		signal(SIGTRAP, CrashHandler_Signal);	/* 5:   trace trap (not reset when caught) */
		signal(SIGEMT,  CrashHandler_Signal);	/* 7:   EMT instruction */
		signal(SIGFPE,  CrashHandler_Signal);	/* 8:   floating point exception */
		signal(SIGBUS,  CrashHandler_Signal);	/* 10:  bus error */
		signal(SIGSEGV, CrashHandler_Signal);	/* 11:  segmentation violation */
		signal(SIGSYS,  CrashHandler_Signal);	/* 12:  bad argument to system call */
		signal(SIGXCPU, CrashHandler_Signal);	/* 24:  exceeded CPU time limit */
		signal(SIGXFSZ, CrashHandler_Signal);	/* 25:  exceeded file size limit */

		//I think SIGABRT is an exception... we should ignore it.
		signal(SIGABRT, SIG_IGN);
	}

	return self;
}

@end

//When a signal occurs, load the crash reporter and close this application
void CrashHandler_Signal(NSInteger i)
{
	NSString	*bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString	*crashReporterPath = [bundlePath stringByAppendingPathComponent:RELATIVE_PATH_TO_CRASH_REPORTER];

	[[NSWorkspace sharedWorkspace] openFile:bundlePath withApplication:crashReporterPath];

	exit(-1);
}
