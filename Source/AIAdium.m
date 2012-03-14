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

#import "AIAdium.h"
#import "AIURLHandlerPlugin.h"
#import "AIAccountController.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AICoreComponentLoader.h"
#import "AICorePluginLoader.h"
//#import "AICrashController.h"
#import "AIDockController.h"
#import "AIEmoticonController.h"
//#import "AIExceptionController.h"
#import "AIInterfaceController.h"
#import "AILoginController.h"
#import "AIMenuController.h"
#import "AIPreferenceController.h"
#import "AISoundController.h"
#import "AIStatusController.h"
#import "AIToolbarController.h"
#import "ESApplescriptabilityController.h"
#import "ESContactAlertsController.h"
#import "ESFileTransferController.h"
#import "LNAboutBoxController.h"
#import "AIXtrasManager.h"
#import "AdiumSetupWizard.h"
#import "ESTextAndButtonsWindowController.h"
#import "AIAppearancePreferences.h"
#import <Adium/AIPathUtilities.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AISharedWriterQueue.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import "AIAddressBookController.h"
#import <Adium/AIContactHidingController.h>
#import <Sparkle/Sparkle.h>
#import "ESAddressBookIntegrationAdvancedPreferences.h"
#import <Adium/AdiumAuthorization.h>
#import <sys/sysctl.h>
#import "ESDebugController.h"

#define ADIUM_TRAC_PAGE						@"http://trac.adium.im/"
#define ADIUM_CONTRIBUTE_PAGE				@"http://trac.adium.im/wiki/Development"
#define ADIUM_DONATE_PAGE					@"http://adium.im/donate"
#define ADIUM_REPORT_BUG_PAGE				@"http://trac.adium.im/wiki/ReportingBugs"
#define ADIUM_FORUM_PAGE					AILocalizedString(@"http://forum.adium.im/","Adium forums page. Localized only if a translated version exists.")
#define ADIUM_FEEDBACK_PAGE					@"mailto:feedback@adium.im"

#if defined(BETA_RELEASE)
#define ADIUM_VERSION_HISTORY_PAGE			@"http://beta.adium.im"
#else
#define ADIUM_VERSION_HISTORY_PAGE			@"http://trac.adium.im/wiki/AdiumVersionHistory"
#endif

//Portable Adium prefs key
#define PORTABLE_ADIUM_KEY					@"Preference Folder Location"

#define ALWAYS_RUN_SETUP_WIZARD FALSE

static NSString	*prefsCategory;

@interface AIAdium ()
- (void)completeLogin;
- (void)openAppropriatePreferencesIfNeeded;
- (void)deleteTemporaryFiles;

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;
- (void)systemTimeZoneDidChange:(NSNotification *)inNotification;
- (void)confirmQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed;
- (void)fileTransferQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed;
- (void)openChatQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed;
- (void)unreadQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed;
@end

@implementation AIAdium

- (id)init
{
	if ((self = [super init])) {
		setSharedAdium(self);
	}

	return self;
}

#pragma mark Core Controllers
@synthesize accountController, chatController, contactController, contentController, dockController, emoticonController, interfaceController, loginController, menuController, preferenceController, soundController, statusController, toolbarController, contactAlertsController, fileTransferController, applescriptabilityController, debugController;

#pragma mark Loaders

@synthesize componentLoader, pluginLoader;

#pragma mark Notifications
//This is a compatibility alias to avoid breaking older plugins. It used to return a separate notification center
- (NSNotificationCenter *)notificationCenter
{
    return [NSNotificationCenter defaultCenter];
}

#pragma mark Startup and Shutdown
//Adium is almost done launching, init
- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	completedApplicationLoad = NO;
	advancedPrefsName = nil;
	prefsCategory = nil;
	queuedURLEvents = nil;
	
	//Load the crash reporter
/*
#ifdef CRASH_REPORTER
#warning Crash reporter enabled.
    [AICrashController enableCrashCatching];
    [AIExceptionController enableExceptionCatching];
#endif
 */
    //Ignore SIGPIPE, which is a harmless error signal
    //sent when write() or similar function calls fail due to a broken pipe in the network connection
    signal(SIGPIPE, SIG_IGN);
	
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self 
												   andSelector:@selector(handleURLEvent:withReplyEvent:)
												 forEventClass:kInternetEventClass
													andEventID:kAEGetURL];
}

- (void)handleURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	if (!completedApplicationLoad) {
		if (!queuedURLEvents) {
			queuedURLEvents = [[NSMutableArray alloc] init];
		}
		[queuedURLEvents addObject:[[event descriptorAtIndex:1] stringValue]];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:AIURLHandleNotification object:[[event descriptorAtIndex:1] stringValue]];
	}
}

//Adium has finished launching
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	//Begin loading and initing the components
	loginController = [[AILoginController alloc] init];
    
    //Begin Login
    [loginController requestUserNotifyingTarget:self selector:@selector(completeLogin)];
}

//Forward a re-open message to the interface controller
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    return [interfaceController handleReopenWithVisibleWindows:flag];
}

//Called by the login controller when a user has been selected, continue logging in
- (void)completeLogin
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	/* Init the controllers.
	 * Menu and interface controllers are created by MainMenu.nib when it loads.
	 */
	preferenceController = [[AIPreferenceController alloc] init];
	toolbarController = [[AIToolbarController alloc] init];
	debugController = [[ESDebugController alloc] init];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AIEnableDebugLogging"])
		AIEnableDebugLogging();
	contactAlertsController = [[ESContactAlertsController alloc] init];
	soundController = [[AISoundController alloc] init];
	emoticonController = [[AIEmoticonController alloc] init];
	accountController = [[AIAccountController alloc] init];
	contactController = [[AIContactController alloc] init];
	[AIContactHidingController sharedController];
	[AdiumAuthorization start];
	chatController = [[AIChatController alloc] init];
	contentController = [[AIContentController alloc] init];
	dockController = [[AIDockController alloc] init];
	fileTransferController = [[ESFileTransferController alloc] init];
	applescriptabilityController = [[ESApplescriptabilityController alloc] init];
	statusController = [[AIStatusController alloc] init];
	
	//Finish setting up the preference controller before the components and plugins load so they can read prefs 
	[preferenceController controllerDidLoad];
	[debugController controllerDidLoad];
	[pool release];

	//Plugins and components should always init last, since they rely on everything else.
	pool = [[NSAutoreleasePool alloc] init];
	componentLoader = [[AICoreComponentLoader alloc] init];
	pluginLoader = [[AICorePluginLoader alloc] init];
	[pool release];

	//Finish initing
	pool = [[NSAutoreleasePool alloc] init];
	[menuController controllerDidLoad];			//Loaded by nib
	[accountController controllerDidLoad];		//** Before contactController so accounts and services are available for contact creation
	
	[AIAddressBookController startAddressBookIntegration];//** Before contactController so AB contacts are available
	[ESAddressBookIntegrationAdvancedPreferences preferencePane];
	
	[contactController controllerDidLoad];		//** Before interfaceController so the contact list is available to the interface
	[interfaceController controllerDidLoad];	//Loaded by nib
	[pool release];

	pool = [[NSAutoreleasePool alloc] init];
	[toolbarController controllerDidLoad];
	[contactAlertsController controllerDidLoad];
	[soundController controllerDidLoad];
	[emoticonController controllerDidLoad];
	[chatController controllerDidLoad];
	[contentController controllerDidLoad];
	[dockController controllerDidLoad];
	[fileTransferController controllerDidLoad];
	[pool release];

	pool = [[NSAutoreleasePool alloc] init];
	[applescriptabilityController controllerDidLoad];
	[statusController controllerDidLoad];

	//Open the preferences if we were unable to because application:openFile: was called before we got here
	[self openAppropriatePreferencesIfNeeded];

	//If no accounts are setup, run the setup wizard
	if (accountController.accounts.count == 0 || ALWAYS_RUN_SETUP_WIZARD) {
		[AdiumSetupWizard runWizard];
	}

	//Process any delayed URL events 
	if (queuedURLEvents) {
		for (NSString *eventString in queuedURLEvents) {
			[[NSNotificationCenter defaultCenter] postNotificationName:AIURLHandleNotification object:eventString];
		}
		[queuedURLEvents release]; queuedURLEvents = nil;
	}
	
	//If we were asked to open a log at launch, do it now
	if (queuedLogPathToShow) {
		[[NSNotificationCenter defaultCenter] postNotificationName:AIShowLogAtPathNotification
												 object:queuedLogPathToShow];
		[queuedLogPathToShow release];
	}
	
	completedApplicationLoad = YES;
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(systemTimeZoneDidChange:)
															name:@"NSSystemTimeZoneDidChangeDistributedNotification"
														  object:nil];
	
	//Broadcast our presence
	connection = [[NSConnection alloc] init];
	[connection setRootObject:self];
	[connection registerName:@"com.adiumX.adiumX"];

	[[AIContactObserverManager sharedManager] delayListObjectNotifications];
	[[NSNotificationCenter defaultCenter] postNotificationName:AIApplicationDidFinishLoadingNotification object:nil];
	[[NSDistributedNotificationCenter defaultCenter]  postNotificationName:AIApplicationDidFinishLoadingNotification object:nil];
	[[AIContactObserverManager sharedManager] endListObjectNotificationsDelay];

	[pool release];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if (![[preferenceController preferenceForKey:@"Confirm Quit"
										   group:@"Confirmations"] boolValue]) {
		return NSTerminateNow;
	}
		
	AIQuitConfirmationType		confirmationType = [[preferenceController preferenceForKey:@"Confirm Quit Type"
																							group:@"Confirmations"] intValue];
	BOOL confirmUnreadMessages	= ![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for Unread Messages"
																	group:@"Confirmations"] boolValue];
	BOOL confirmFileTransfers	= ![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for File Transfers"
																	group:@"Confirmations"] boolValue];
	BOOL confirmOpenChats		= ![[preferenceController preferenceForKey:@"Suppress Quit Confirmation for Open Chats"
																	group:@"Confirmations"] boolValue];
	
	NSString	*questionToAsk = [NSString string];
	SEL			questionSelector = nil;

	NSApplicationTerminateReply allowQuit = NSTerminateNow;
	
	switch (confirmationType) {
		case AIQuitConfirmAlways:
			questionSelector = @selector(confirmQuitQuestion:userInfo:suppression:);
			
			allowQuit = NSTerminateLater;
			break;
			
		case AIQuitConfirmSelective:
			if ([chatController unviewedContentCount] > 0 && confirmUnreadMessages) {
				questionToAsk = (([chatController unviewedContentCount] > 1) ? [NSString stringWithFormat:AILocalizedString(@"You have %d unread messages.",@"Quit Confirmation"), [chatController unviewedContentCount]] : AILocalizedString(@"You have an unread message.",@"Quit Confirmation"));
				questionSelector = @selector(unreadQuitQuestion:userInfo:suppression:);
				allowQuit = NSTerminateLater;
			} else if ([fileTransferController activeTransferCount] > 0 && confirmFileTransfers) {
				questionToAsk = (([fileTransferController activeTransferCount] > 1) ? [NSString stringWithFormat:AILocalizedString(@"You have %d file transfers in progress.",@"Quit Confirmation"), [fileTransferController activeTransferCount]] : AILocalizedString(@"You have a file transfer in progress.",@"Quit Confirmation"));
				questionSelector = @selector(fileTransferQuitQuestion:userInfo:suppression:);
				allowQuit = NSTerminateLater;
			} else if ([[chatController openChats] count] > 0 && confirmOpenChats) {
				questionToAsk = (([[chatController openChats] count] > 1) ? [NSString stringWithFormat:AILocalizedString(@"You have %d open chats.",@"Quit Confirmation"), [[chatController openChats] count]] : AILocalizedString(@"You have an open chat.",@"Quit Confirmation"));
				questionSelector = @selector(openChatQuitQuestion:userInfo:suppression:);
				allowQuit = NSTerminateLater;
			}

			break;
	}
	
	if (allowQuit == NSTerminateLater) {
		[self.interfaceController displayQuestion:AILocalizedString(@"Confirm Quit", nil)
									withDescription:[questionToAsk stringByAppendingFormat:@"%@%@",
														([questionToAsk length] > 0 ? @"\n" : @""),
														AILocalizedString(@"Are you sure you want to quit Adium?",@"Quit Confirmation")]
									withWindowTitle:nil
									  defaultButton:AILocalizedString(@"Quit", nil)
									alternateButton:AILocalizedString(@"Cancel", nil)
										otherButton:nil
										 suppression:AILocalizedString(@"Don't ask again", nil)
											 target:self
										   selector:questionSelector
										   userInfo:nil];
	}

	return allowQuit;
}

//Give all the controllers a chance to close down
- (void)applicationWillTerminate:(NSNotification *)notification
{
	//Take no action if we didn't complete the application load
	if (!completedApplicationLoad) return;
	
	[connection release]; connection = nil;

	isQuitting = YES;

	[[NSNotificationCenter defaultCenter] postNotificationName:AIAppWillTerminateNotification object:nil];

	//Close the preference window before we shut down the plugins that compose it
	[preferenceController closePreferenceWindow:nil];

	//Close the controllers in reverse order
	[pluginLoader controllerWillClose]; 				//** First because plugins rely on all the controllers
	[componentLoader controllerWillClose];				//** First because components rely on all the controllers
	[statusController controllerWillClose];				//** Before accountController so account states are saved before being set to offline
	[chatController controllerWillClose];				//** Before interfaceController so chats can be correctly closed
	[contactAlertsController controllerWillClose];
	[fileTransferController controllerWillClose];
	[dockController controllerWillClose];
	[interfaceController controllerWillClose];
	[contentController controllerWillClose];
	[contactController controllerWillClose];
	[AIAddressBookController stopAddressBookIntegration];
	[accountController controllerWillClose];
	[emoticonController controllerWillClose];
	[soundController controllerWillClose];
	[menuController controllerWillClose];
	[applescriptabilityController controllerWillClose];
	[debugController controllerWillClose];
	[toolbarController controllerWillClose];
	
	[AISharedWriterQueue waitUntilAllOperationsAreFinished];
	[preferenceController controllerWillClose];			//** Last since other controllers may want to write preferences as they close
	
	[self deleteTemporaryFiles];
}

- (void)deleteTemporaryFiles
{
	[[NSFileManager defaultManager] removeFilesInDirectory:[self cachesPath]
												withPrefix:@"TEMP"
											 movingToTrash:NO];
}

@synthesize isQuitting;

#pragma mark Menu Item Hooks

- (IBAction)showAboutBox:(id)sender
{
    [[LNAboutBoxController aboutBoxController] showWindow:nil];
}

- (IBAction)reportABug:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_REPORT_BUG_PAGE]];
}
- (IBAction)showVersionHistory:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_VERSION_HISTORY_PAGE]];
}
- (IBAction)sendFeedback:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FEEDBACK_PAGE]];
}
- (IBAction)showForums:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_FORUM_PAGE]];
}
- (IBAction)showXtras:(id)sender{
	[[AIXtrasManager sharedManager] showXtras];
}

- (IBAction)contibutingToAdium:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_CONTRIBUTE_PAGE]];
}
- (IBAction)donate:(id)sender
{
	/* This should be reimplemented as an in-app webview */
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_DONATE_PAGE]];
}

- (void)unreadQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed
{
	if ([suppressed boolValue]){
		//Don't Ask Again
		[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
											forKey:@"Suppress Quit Confirmation for Unread Messages"
											 group:@"Confirmations"];
	}
	
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			//Should we ask about File Transfers here?????
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
			break;
	}
}

- (void)openChatQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed
{
	if ([suppressed boolValue]){
		//Don't Ask Again
		[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
											forKey:@"Suppress Quit Confirmation for Open Chats"
											 group:@"Confirmations"];
	}
	
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			//Should we ask about File Transfers here?????
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
			break;
	}
}

- (void)fileTransferQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed
{
	if ([suppressed boolValue]){
		//Don't Ask Again
		[[self preferenceController] setPreference:[NSNumber numberWithBool:YES]
											forKey:@"Suppress Quit Confirmation for File Transfers"
											 group:@"Confirmations"];
	}
	
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
			break;
	}
}

- (void)confirmQuitQuestion:(NSNumber *)number userInfo:(id)info suppression:(NSNumber *)suppressed
{
	if ([suppressed boolValue]){
		//Don't Ask Again
		[[self preferenceController] setPreference:[NSNumber numberWithBool:NO]
											forKey:@"Confirm Quit"
											 group:@"Confirmations"];
	}
	
	AITextAndButtonsReturnCode result = [number intValue];
	switch(result)
	{
		case AITextAndButtonsDefaultReturn:
			//Quit
			[NSApp replyToApplicationShouldTerminate:NSTerminateNow];
			break;
		default:
			//Cancel
			[NSApp replyToApplicationShouldTerminate:NSTerminateCancel];
			break;
	}
}


//Last call to perform actions before the app shuffles off its mortal coil and joins the bleeding choir invisible
- (IBAction)confirmQuit:(id)sender
{
	/* We may have received a message or begun a file transfer while the menu was open, if this is reached via a menu item.
	 * Wait one last run loop before beginning to quit so that activity can be registered, since menus run in
	 * a different run loop mode, NSEventTrackingRunLoopMode.
	 */
	[NSObject cancelPreviousPerformRequestsWithTarget:NSApp
											 selector:@selector(terminate:)
											   object:nil];
	[NSApp performSelector:@selector(terminate:)
			   withObject:nil
			   afterDelay:0];
}

#pragma mark Other
//If Adium was launched by double-clicking an associated file, we get this call after willFinishLaunching but before
//didFinishLaunching
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSString			*extension = [filename pathExtension];
    NSString			*destination = nil;
	NSString			*errorMessage = nil;
    NSString			*fileDescription = nil, *prefsButton = nil;
	BOOL				success = NO, requiresRestart = NO;
	NSInteger					buttonPressed;
	
	if (([extension caseInsensitiveCompare:@"AdiumLog"] == NSOrderedSame) ||
		([extension caseInsensitiveCompare:@"AdiumHtmlLog"] == NSOrderedSame) ||
		([extension caseInsensitiveCompare:@"chatlog"] == NSOrderedSame)) {
		if (completedApplicationLoad) {
			//Request display of the log immediately if Adium is ready
			[[NSNotificationCenter defaultCenter] postNotificationName:AIShowLogAtPathNotification
													 object:filename];
		} else {
			//Queue the request until Adium is done launching if Adium is not ready
			[queuedLogPathToShow release]; queuedLogPathToShow = [filename retain];
		}
		
		//Don't continue to the xtras installation code. Return YES because we handled the open.
		return YES;
	}	
	
	/* Installation of Xtras below this point */

	[prefsCategory release]; prefsCategory = nil;
    [advancedPrefsName release]; advancedPrefsName = nil;

    /* Specify a file extension and a human-readable description of what the files of this type do
	 * We reassign the extension so that regardless of its original case we end up with the case we want; this allows installation of
	 * xtras to proceed properly on case-sensitive file systems.
	 */
    if ([extension caseInsensitiveCompare:@"AdiumPlugin"] == NSOrderedSame) {
        destination = [AISearchPathForDirectories(AIPluginsDirectory) objectAtIndex:0];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);
		extension = @"AdiumPlugin";

    } else if ([extension caseInsensitiveCompare:@"AdiumLibpurplePlugin"] == NSOrderedSame) {
        destination = [AISearchPathForDirectories(AIPluginsDirectory) objectAtIndex:0];
        //Plugins haven't been loaded yet if the application isn't done loading, so only request a restart if it has finished loading already 
        requiresRestart = completedApplicationLoad;
        fileDescription = AILocalizedString(@"Adium plugin",nil);
		extension = @"AdiumLibpurplePlugin";

	} else if ([extension caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIDockIconsDirectory) objectAtIndex:0];
        fileDescription = AILocalizedString(@"dock icon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumIcon";

	} else if ([extension caseInsensitiveCompare:@"AdiumSoundset"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AISoundsDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"sound set",nil);
		prefsButton = AILocalizedString(@"Open Event Prefs",nil);
		prefsCategory = @"Events";
		extension = @"AdiumSoundset";

	} else if ([extension caseInsensitiveCompare:@"AdiumEmoticonset"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIEmoticonsDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"emoticon set",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumEmoticonset";

	} else if ([extension caseInsensitiveCompare:@"AdiumScripts"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIScriptsDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"AppleScript set",nil);
		extension = @"AdiumScripts";

	} else if ([extension caseInsensitiveCompare:@"AdiumMessageStyle"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIMessageStylesDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"message style",nil);
		prefsButton = AILocalizedString(@"Open Message Prefs",nil);
		prefsCategory = @"Messages";
		extension = @"AdiumMessageStyle";

	} else if ([extension caseInsensitiveCompare:@"ListLayout"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIContactListDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"contact list layout",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"ListLayout";

	} else if ([extension caseInsensitiveCompare:@"ListTheme"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIContactListDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"contact list theme",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"ListTheme";

	} else if ([extension caseInsensitiveCompare:@"AdiumServiceIcons"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIServiceIconsDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"service icons",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumServiceIcons";

	} else if ([extension caseInsensitiveCompare:@"AdiumMenuBarIcons"] == NSOrderedSame) {
		destination = [AISearchPathForDirectories(AIMenuBarIconsDirectory) objectAtIndex:0];
		fileDescription = AILocalizedString(@"menu bar icons",nil);
		prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
		prefsCategory = @"Appearance";
		extension = @"AdiumMenuBarIcons";

	} else if ([extension caseInsensitiveCompare:@"AdiumStatusIcons"] == NSOrderedSame) {
		NSString	*packName = [[filename lastPathComponent] stringByDeletingPathExtension];
/*
 //Can't do this because the preferenceController isn't ready yet
 NSString	*defaultPackName = [[self preferenceController] defaultPreferenceForKey:@"Status Icon Pack"
																			  group:@"Appearance"
																			 object:nil];
*/
		NSString	*defaultPackName = @"Gems";

		if (![packName isEqualToString:defaultPackName]) {
			destination = [AISearchPathForDirectories(AIStatusIconsDirectory) objectAtIndex:0];
			fileDescription = AILocalizedString(@"status icons",nil);
			prefsButton = AILocalizedString(@"Open Appearance Prefs",nil);
			prefsCategory = @"Appearance";
			extension = @"AdiumStatusIcons";

		} else {
			errorMessage = [NSString stringWithFormat:AILocalizedString(@"%@ is the name of the default status icon pack; this pack therefore can not be installed.",nil),
				packName];
		}
	}

    if (destination) {
        NSString    *destinationFilePath;
		destinationFilePath = [destination stringByAppendingPathComponent:[[filename lastPathComponent] stringByDeletingPathExtension]];
		destinationFilePath = [destinationFilePath stringByAppendingPathExtension:extension];

        NSString	*alertTitle = nil;
        NSString	*alertMsg = nil;
		NSString	*format;
		
		if ([filename caseInsensitiveCompare:destinationFilePath] == NSOrderedSame) {
			// Don't copy the file if it's already in the right place!!
			alertTitle= AILocalizedString(@"Installation Successful","Title of installation successful window");
			
			format = AILocalizedString(@"Installation of the %@ %@ was successful because the file was already in the correct location.",
									   "Installation introduction, like 'Installation of the message style Fiat was successful...'.");
			
			alertMsg = [NSString stringWithFormat:format,
				fileDescription,
				[[filename lastPathComponent] stringByDeletingPathExtension]];
			
		} else {
			//Trash the old file if one exists (since we know it isn't ourself)
			[[NSFileManager defaultManager] trashFileAtPath:destinationFilePath];
			
			//Ensure the directory exists

			[[NSFileManager defaultManager] createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:NULL];
			
			//Perform the copy and display an alert informing the user of its success or failure
			if ([[NSFileManager defaultManager] copyItemAtPath:filename 
												  toPath:destinationFilePath 
												 error:NULL]) {
				
				alertTitle = AILocalizedString(@"Installation Successful","Title of installation successful window");
				alertMsg = [NSString stringWithFormat:AILocalizedString(@"Installation of the %@ %@ was successful.",
																		   "Installation sentence, like 'Installation of the message style Fiat was successful.'."),
					fileDescription,
					[[filename lastPathComponent] stringByDeletingPathExtension]];
				
				if (requiresRestart) {
					alertMsg = [alertMsg stringByAppendingString:AILocalizedString(@" Please restart Adium.",nil)];
				}
				
				success = YES;
			} else {
				alertTitle = AILocalizedString(@"Installation Failed","Title of installation failed window");
				alertMsg = [NSString stringWithFormat:AILocalizedString(@"Installation of the %@ %@ was unsuccessful.",
																		"Installation failed sentence, like 'Installation of the message style Fiat was unsuccessful.'."),
					fileDescription,
					[[filename lastPathComponent] stringByDeletingPathExtension]];
			}
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:AIXtrasDidChangeNotification
												 object:[[filename lastPathComponent] pathExtension]];
		
        buttonPressed = NSRunInformationalAlertPanel(alertTitle,alertMsg,nil,prefsButton,nil);
		
		// User clicked the "open prefs" button
		if (buttonPressed == NSAlertAlternateReturn) {
			//If we're done loading the app, open the prefs now; if not, it'll be done once the load is finished
			//so the controllers and plugins have had a chance to initialize
			if (completedApplicationLoad) {
				[self openAppropriatePreferencesIfNeeded];
			}
		} else {
			//If the user didn't press the "open prefs" button, clear the pref opening information
			[prefsCategory release]; prefsCategory = nil;
			[advancedPrefsName release]; advancedPrefsName = nil;
		}
		
    } else {
		if (!errorMessage) {
			errorMessage = AILocalizedString(@"An error occurred while installing the X(tra).",nil);
		}
		
		NSRunAlertPanel(AILocalizedString(@"Installation Failed","Title of installation failed window"),
						errorMessage,
						nil,nil,nil);
	}

    return success;
}

- (BOOL)application:(NSApplication *)theApplication openTempFile:(NSString *)filename
{
	BOOL success;
	
	success = [self application:theApplication openFile:filename];
	[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
	
	return success;
}

- (void)openAppropriatePreferencesIfNeeded
{
	if (prefsCategory) {
		[preferenceController openPreferencesToCategoryWithIdentifier:prefsCategory];
		
		[prefsCategory release]; prefsCategory = nil;
	}
}

/*!
 * @brief Returns the location of Adium's preference folder
 * 
 * This may be specified in our bundle's info dictionary keyed as PORTABLE_ADIUM_KEY
 * or, by default, be within the system's 'application support' directory.
 */
- (NSString *)applicationSupportDirectory
{
	//Path to the preferences folder
	static NSString *_preferencesFolderPath = nil;
	
    //Determine the preferences path if neccessary
	if (!_preferencesFolderPath) {
		_preferencesFolderPath = [[[[[NSBundle mainBundle] infoDictionary] objectForKey:PORTABLE_ADIUM_KEY] stringByExpandingTildeInPath] retain];
		if (!_preferencesFolderPath)
			_preferencesFolderPath = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Adium 2.0"] retain];
	}
	
	return _preferencesFolderPath;
}

/*!
 * @brief Create a resource folder in the Library/Application\ Support/Adium\ 2.0 folder.
 *
 * Pass it the name of the folder (e.g. @"Scripts").
 * If it is found to already in a library folder, return that pathname, using the same order of preference as
 * -[AIAdium resourcePathsForName:]. Otherwise, create it in the user library and return the pathname to it.
 */
- (NSString *)createResourcePathForName:(NSString *)name
{
    NSString		*targetPath;    //This is the subfolder for the user domain (i.e. ~/L/AS/Adium\ 2.0).
    NSFileManager	*defaultManager;
    NSArray			*existingResourcePaths;

	defaultManager = [NSFileManager defaultManager];
	existingResourcePaths = [self resourcePathsForName:name];
	targetPath = [[self applicationSupportDirectory] stringByAppendingPathComponent:name];	
	
    /*
	 If the targetPath doesn't exist, create it, as this method was called to ensure that it exists
	 for creating files in the user domain.
	 */
    if ([existingResourcePaths indexOfObject:targetPath] == NSNotFound) {
		
		//XXX seems like we could use the error argument to do this with less guesswork
        if (![defaultManager createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			BOOL error;

			//If the directory could not be created, there may be a file in the way. Death to file.
			error = ![defaultManager trashFileAtPath:targetPath];

			if (!error) error = ![defaultManager createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:NULL];

			if (error) {
				targetPath = nil;
				
				NSInteger result = NSRunCriticalAlertPanel([NSString stringWithFormat:AILocalizedString(@"Could not create the %@ folder.",nil), name],
												 AILocalizedString(@"Try running Repair Permissions from Disk Utility.",nil),
												 AILocalizedString(@"OK",nil), 
												 AILocalizedString(@"Launch Disk Utility",nil), 
												 nil);
				if (result == NSAlertAlternateReturn) {
					[[NSWorkspace sharedWorkspace] launchApplication:@"Disk Utility"];
				}
			}
		}
    } else {
        targetPath = [existingResourcePaths objectAtIndex:0];
    }

    return targetPath;
}

/*!
 * @brief Return zero or more resource pathnames to an filename 
 *
 * Searches in the Application Support folders and the Resources/ folder of the Adium.app bundle.
 * Only those pathnames that exist are returned.  The Adium bundle's resource path will be the last item in the array,
 * so precedence is given to the user and system Application Support folders.
 * 
 * Pass nil to receive an array of paths to existing Adium Application Support folders (plus the Resouces folder).
 *
 * Example: If you call[adium resourcePathsForName:@"Scripts"], and there's a
 * Scripts folder in ~/Library/Application Support/Adium\ 2.0 and in /Library/Application Support/Adium\ 2.0, but not
 * in /System/Library/ApplicationSupport/Adium\ 2.0 or /Network/Library/Application Support/Adium\ 2.0.
 * The array you get back will be { @"/Users/username/Library/Application Support/Adium 2.0/Scripts",
 * @"/Library/Application Support/Adium 2.0/Scripts" }.
 *
 * @param name The full name (including extension as appropriate) of the resource for which to search
 */
- (NSArray *)resourcePathsForName:(NSString *)name
{
	NSMutableArray  *pathArray = [NSMutableArray arrayWithCapacity:4];
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	BOOL			isDir;
			
	NSString *adiumFolderName = [@"Application Support" stringByAppendingPathComponent:@"Adium 2.0"];
	if (name)
		adiumFolderName = [adiumFolderName stringByAppendingPathComponent:name];

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);

	//Copy each discovered path into the pathArray after adding our subfolder path
	for (NSString *path in librarySearchPaths) {
		NSString	*fullPath = [path stringByAppendingPathComponent:adiumFolderName];
		if ([defaultManager fileExistsAtPath:fullPath isDirectory:&isDir] && isDir) {
			[pathArray addObject:fullPath];
		}
	}
	
	/* Check our application support directory directly. It may have been covered by the NSSearchPathForDirectoriesInDomains() search,
	 * or it may be distinct via the Portable Adium preference.
	 */
	NSString *path = [self applicationSupportDirectory];
	if (name)
		path = [path stringByAppendingPathComponent:name];
	if (![pathArray containsObject:path] &&
		([defaultManager fileExistsAtPath:path isDirectory:&isDir]) &&
		(isDir)) {
		//Our application support directory should always be first
		if ([pathArray count]) {
			[pathArray insertObject:path atIndex:0];
		} else {
			[pathArray addObject:path];			
		}
	}

	//Add the path to the resource in Adium's bundle
	if (name) {
		path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:name] stringByExpandingTildeInPath];
		if (([defaultManager fileExistsAtPath:path isDirectory:&isDir]) &&
		   (isDir)) {
			[pathArray addObject:path];
		}
	}
    
	return pathArray;
}


/*!
 * @brief Returns an array of the paths to all of the resources for a given name, filtering out those without a certain extension
 * @param name The full name (including extension as appropriate) of the resource for which to search
 * @param extensions The extension(s) of the resources for which to search, either an NSString or an NSArray
 */
- (NSArray *)allResourcesForName:(NSString *)name withExtensions:(id)extensions
{
	NSMutableArray *resources = [NSMutableArray array];
	BOOL extensionsArray = [extensions isKindOfClass:[NSArray class]];
	
	// Get every path that can contain these resources
	
	for (NSString *resourceDir in [self resourcePathsForName:name]) {
		for (NSString *resourcePath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourceDir error:NULL]) {
			// Add each resource to the array
			if (extensionsArray) {
				for (NSString *extension in extensions) {
					if ([resourcePath.pathExtension caseInsensitiveCompare:extension] == NSOrderedSame)
						[resources addObject:[resourceDir stringByAppendingPathComponent:resourcePath]];
				}
			} else {
				if ([resourcePath.pathExtension caseInsensitiveCompare:extensions] == NSOrderedSame)
					[resources addObject:[resourceDir stringByAppendingPathComponent:resourcePath]];
			}
		}
	}

	return resources;
}

/*!
 * @brief Return the path to be used for caching files for this user.
 *
 * @result A cached, tilde-expanded full path.
 */
- (NSString *)cachesPath
{
	static NSString *cachesPath = nil;

	if (!cachesPath) {
		NSString		*generalAdiumCachesPath;
		NSFileManager	*defaultManager = NSFileManager.defaultManager;

		generalAdiumCachesPath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Caches"] stringByAppendingPathComponent:@"Adium"];
		cachesPath = [[generalAdiumCachesPath stringByAppendingPathComponent:self.loginController.currentUser] retain];

		//Ensure our cache path exists
		if ([defaultManager createDirectoryAtPath:cachesPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			//If we have to make directories, try to move old cache files into the new directory
			BOOL			isDir;

			for (NSString *filename in [defaultManager contentsOfDirectoryAtPath:generalAdiumCachesPath error:NULL]) {
				NSString	*fullPath = [generalAdiumCachesPath stringByAppendingPathComponent:filename];
				
				if (([defaultManager fileExistsAtPath:fullPath isDirectory:&isDir]) &&
				   (!isDir)) {
					[defaultManager moveItemAtPath:fullPath
									  toPath:[cachesPath stringByAppendingPathComponent:filename]
									 error:NULL];
				}
			}
		}
	}
	
	return cachesPath;
}

- (NSString *)pathOfPackWithName:(NSString *)name extension:(NSString *)extension resourceFolderName:(NSString *)folderName
{
	NSFileManager	*fileManager = [NSFileManager defaultManager];
    NSString		*packFileName = [name stringByAppendingPathExtension:extension];

	//Search all our resource paths for the requested pack
    for (NSString *resourcePath in [self resourcePathsForName:folderName]) {
		NSString *packPath = [resourcePath stringByAppendingPathComponent:packFileName];
		if ([fileManager fileExistsAtPath:packPath]) return [packPath stringByExpandingTildeInPath];
	}

    return nil;	
}

- (void)systemTimeZoneDidChange:(NSNotification *)inNotification
{
	[NSTimeZone resetSystemTimeZone];
}

- (NSApplication *)application
{
	return [NSApplication sharedApplication];
}

#pragma mark Scripting
- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	BOOL handleKey = NO;
	
	if ([key isEqualToString:@"applescriptabilityController"] || 
	   [key isEqualToString:@"interfaceController"] ) {
		handleKey = YES;
		
	}
	
	return handleKey;
}

#pragma mark Sparkle Delegate Methods

#define NIGHTLY_UPDATE_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"key", @"nightly", @"value", nil]
#define BETA_UPDATE_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"key", @"beta", @"value", nil]
#define RELEASE_UPDATE_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"type", @"key", @"release", @"value", nil]

//Nightlies should update to other nightlies
#if defined(NIGHTLY_RELEASE)
#define UPDATE_TYPE_DICT NIGHTLY_UPDATE_DICT
//For a beta release, always use the beta appcast
#elif defined(BETA_RELEASE)
#define UPDATE_TYPE_DICT BETA_UPDATE_DICT
//For a release, use the beta appcast if AIAlwaysUpdateToBetas is enabled; otherwise, use the release appcast
#else
#define UPDATE_TYPE_DICT ([[NSUserDefaults standardUserDefaults] boolForKey:@"AIAlwaysUpdateToBetas"] ? BETA_UPDATE_DICT : RELEASE_UPDATE_DICT)
#endif

//The first generation ended with 1.0.5 and 1.1. Our Sparkle Plus up to that point had a bug that left it unable to properly handle the sparkle:minimumSystemVersion element.
//The second generation began with 1.0.6 and 1.1.1, with a Sparkle Plus that can handle that element.
#define UPDATE_GENERATION_DICT [NSDictionary dictionaryWithObjectsAndKeys:@"generation", @"key", @"2", @"value", nil]

/* This method gives the delegate the opportunity to customize the information that will
 * be included with update checks.  Add or remove items from the dictionary as desired.
 * Each entry in profileInfo is an NSDictionary with the following keys:
 *		key: 		The key to be used  when reporting data to the server
 *		value:		Value to be used when reporting data to the server
 */
- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendProfileInfo
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	//Sparkle 1.5 has a different defaults key, do a one time migration of the value
	if ([defaults boolForKey:@"SUIncludeProfile"]) {
		[defaults setBool:YES forKey:@"SUSendProfileInfo"];
		sendProfileInfo = YES;
		[defaults setBool:NO forKey:@"SUIncludeProfile"]; //make sure this only runs once
	}

	//If we're not sending profile information, or if it hasn't been long enough since the last profile submission, return just the type of update we're looking for and the generation number.
	NSMutableArray *profileInfo = [NSMutableArray array];

	[profileInfo addObject:UPDATE_GENERATION_DICT];
	[profileInfo addObject:UPDATE_TYPE_DICT];
#ifdef NIGHTLY_RELEASE
	NSString *buildId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AIBuildIdentifier"];
    NSString *nightlyRepo = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AINightlyRepo"];
    NSString *nightlyBranch = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AINightlyBranch"];
	[profileInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"revision", @"key", @"Revision", @"visibleKey", buildId, @"value", buildId, @"visibleValue", nil]];
    [profileInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"repo", @"key", nightlyRepo, @"value", nil]];
    [profileInfo addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"branch", @"key", nightlyBranch, @"value", nil]];
#endif

	if (sendProfileInfo) {		
		NSString *value = ([defaults boolForKey:@"AIHasSentSparkleProfileInfo"]) ? @"no" : @"yes";

		NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys:
			@"FirstSubmission", @"key", 
			value, @"value",
			nil];

		[profileInfo addObject:entry];

		[defaults setBool:YES forKey:@"AIHasSentSparkleProfileInfo"];

		/*************** Include info about what IM services are used ************/
		NSMutableString *accountInfo = [NSMutableString string];
		NSCountedSet *condensedAccountInfo = [NSCountedSet set];
		for (AIAccount *account in adium.accountController.accounts) {
			NSString *serviceID = account.service.serviceID;
			[accountInfo appendFormat:@"%@, ", serviceID];
			if([serviceID isEqualToString:@"Yahoo! Japan"]) 
				serviceID = @"YJ";
			[condensedAccountInfo addObject:[NSString stringWithFormat:@"%@", [serviceID substringToIndex:2]]]; 
		}

		NSMutableString *accountInfoString = [NSMutableString string];
		for (value in [[condensedAccountInfo allObjects] sortedArrayUsingSelector:@selector(compare:)])
			[accountInfoString appendFormat:@"%@%lu", value, [condensedAccountInfo countForObject:value]];

		entry = [NSDictionary dictionaryWithObjectsAndKeys:
			@"IMServices", @"key", 
			accountInfoString, @"value",
			nil];
		[profileInfo addObject:entry];
		
		/** Temporary: get a combined type/bitness value **/
		// CPU type (decoder info for values found here is in mach/machine.h)
		int sysctlvalue = 0;
		unsigned long length = sizeof(sysctlvalue);
		int error = sysctlbyname("hw.cputype", &sysctlvalue, &length, NULL, 0);
		int cpuType = -1;
		if (error == 0) {
			cpuType = sysctlvalue;
		}
		BOOL is64bit = NO;
		error = sysctlbyname("hw.cpu64bit_capable", &sysctlvalue, &length, NULL, 0);
		if(error != 0) {
			error = sysctlbyname("hw.optional.x86_64", &sysctlvalue, &length, NULL, 0); //x86 specific
		}

		if (error == 0) {
			is64bit = sysctlvalue == 1;
			NSString *visibleCPUType;
			switch(cpuType) {
				case 7:		visibleCPUType=@"Intel";	break;
				default:	visibleCPUType=@"Unknown";	break;
			}
			visibleCPUType = [visibleCPUType stringByAppendingFormat:@"%@", is64bit ? @"64" : @"32"];
			[profileInfo addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"detailedcputype",@"Detailed CPU Type", visibleCPUType, visibleCPUType,nil] forKeys:[NSArray arrayWithObjects:@"key", @"displayKey", @"value", @"displayValue", nil]]];
		}
		
	}


	return profileInfo;
}

- (id <SUVersionComparison>)versionComparatorForUpdater:(SUUpdater *)updater
{
    return self;
}

#pragma mark Version Comparison (Copied from SUStandardVersionComparator)

typedef enum {
    kNumberType,
    kStringType,
    kPeriodType
} SUCharacterType;

- (SUCharacterType)typeOfCharacter:(NSString *)character
{
    if ([character isEqualToString:@"."]) {
        return kPeriodType;
    } else if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[character characterAtIndex:0]]) {
        return kNumberType;
    } else {
        return kStringType;
    }	
}

- (NSArray *)splitVersionString:(NSString *)version
{
    NSString *character;
    NSMutableString *s;
    NSInteger i, n, oldType, newType;
    NSMutableArray *parts = [NSMutableArray array];
    if ([version length] == 0) {
        // Nothing to do here
        return parts;
    }
    s = [[[version substringToIndex:1] mutableCopy] autorelease];
    oldType = [self typeOfCharacter:s];
    n = [version length] - 1;
    for (i = 1; i <= n; ++i) {
        character = [version substringWithRange:NSMakeRange(i, 1)];
        newType = [self typeOfCharacter:character];
        if (oldType != newType || oldType == kPeriodType) {
            // We've reached a new segment
	    NSString *aPart = [[NSString alloc] initWithString:s];
            [parts addObject:aPart];
	    [aPart release];
            [s setString:character];
        } else {
            // Add character to string and continue
            [s appendString:character];
        }
        oldType = newType;
    }
    
    // Add the last part onto the array
    [parts addObject:[NSString stringWithString:s]];
    return parts;
}

- (NSComparisonResult)compareVersion:(NSString *)appVersion toVersion:(NSString *)appcastVersion;
{
	/*********** Adium Changes **********/
	NSRange debugRange = [appVersion rangeOfString:@"-debug"];
	if (debugRange.location != NSNotFound)
		appVersion = [appVersion substringToIndex:debugRange.location];
	
	NSRange hgOurs = [appVersion rangeOfString:@"hg"];
	NSRange hgTheirs = [appcastVersion rangeOfString:@"hg"];
	NSRange svnOurs = [appVersion rangeOfString:@"svn"];
	NSRange svnTheirs = [appcastVersion rangeOfString:@"svn"];
	
	if (hgOurs.location != NSNotFound && svnTheirs.location != NSNotFound)
		return NSOrderedDescending;
	if (hgTheirs.location != NSNotFound && svnOurs.location != NSNotFound)
		return NSOrderedAscending;
		
	/*********** End Adium Changes *******/
    
    NSArray *partsA = [self splitVersionString:appVersion];
    NSArray *partsB = [self splitVersionString:appcastVersion];
    
    NSString *partA, *partB;
    NSInteger i, n, typeA, typeB, intA, intB;
    
    n = MIN([partsA count], [partsB count]);
    for (i = 0; i < n; ++i) {
        partA = [partsA objectAtIndex:i];
        partB = [partsB objectAtIndex:i];
        
        typeA = [self typeOfCharacter:partA];
        typeB = [self typeOfCharacter:partB];
        
        // Compare types
        if (typeA == typeB) {
            // Same type; we can compare
            if (typeA == kNumberType) {
                intA = [partA intValue];
                intB = [partB intValue];
                if (intA > intB) {
                    return NSOrderedDescending;
                } else if (intA < intB) {
                    return NSOrderedAscending;
                }
            } else if (typeA == kStringType) {
                NSComparisonResult result = [partA compare:partB];
                if (result != NSOrderedSame) {
                    return result;
                }
            }
        } else {
            // Not the same type? Now we have to do some validity checking
            if (typeA != kStringType && typeB == kStringType) {
                // typeA wins
                return NSOrderedDescending;
            } else if (typeA == kStringType && typeB != kStringType) {
                // typeB wins
                return NSOrderedAscending;
            } else {
                // One is a number and the other is a period. The period is invalid
                if (typeA == kNumberType) {
                    return NSOrderedDescending;
                } else {
                    return NSOrderedAscending;
                }
            }
        }
    }
    // The versions are equal up to the point where they both still have parts
    // Lets check to see if one is larger than the other
    if ([partsA count] != [partsB count]) {
        // Yep. Lets get the next part of the larger
        // n holds the index of the part we want.
        NSString *missingPart;
        SUCharacterType missingType;
	NSComparisonResult shorterResult, largerResult;
        
        if ([partsA count] > [partsB count]) {
            missingPart = [partsA objectAtIndex:n];
            shorterResult = NSOrderedAscending;
            largerResult = NSOrderedDescending;
        } else {
            missingPart = [partsB objectAtIndex:n];
            shorterResult = NSOrderedDescending;
            largerResult = NSOrderedAscending;
        }
        
        missingType = [self typeOfCharacter:missingPart];
        // Check the type
        if (missingType == kStringType) {
            // It's a string. Shorter version wins
            return shorterResult;
        } else {
            // It's a number/period. Larger version wins
            return largerResult;
        }
    }
    
    // The 2 strings are identical
    return NSOrderedSame;
}

@end

@implementation NSObject (AdiumAccess)
- (NSObject<AIAdium> *)adium
{
	return adium;
}
@end
