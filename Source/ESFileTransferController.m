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

#import "ESFileTransferController.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "ESFileTransferPreferences.h"
#import "ESFileTransferProgressWindowController.h"
#import "ESFileTransferRequestPromptController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListGroup.h>
#import "ESFileTransfer.h"
#import <Adium/AIWindowController.h>

#define SEND_FILE					AILocalizedString(@"Send File",nil)
#define SEND_FILE_WITH_ELLIPSIS		[SEND_FILE stringByAppendingEllipsis]
#define CONTACT						AILocalizedString(@"Contact",nil)

#define	SEND_FILE_IDENTIFIER		@"SendFile"

#define	FILE_TRANSFER_DEFAULT_PREFS	@"FileTransferPrefs"

#define SAFE_FILE_EXTENSIONS_SET	[NSSet setWithObjects:@"jpg",@"jpeg",@"gif",@"png",@"tif",@"tiff",@"psd",@"pdf",@"txt",@"rtf",@"html",@"htm",@"swf",@"mp3",@"wma",@"wmv",@"ogg",@"ogm",@"mov",@"mpg",@"mpeg",@"m1v",@"m2v",@"mp4",@"avi",@"vob",@"avi",@"asx",@"asf",@"pls",@"m3u",@"rmp",@"aif",@"aiff",@"aifc",@"wav",@"wave",@"m4a",@"m4p",@"m4b",@"dmg",@"udif",@"ndif",@"dart",@"sparseimage",@"cdr",@"dvdr",@"iso",@"img",@"toast",@"rar",@"sit",@"sitx",@"bin",@"hqx",@"zip",@"gz",@"tgz",@"tar",@"bz",@"bz2",@"tbz",@"z",@"taz",@"uu",@"uue",@"colloquytranscript",@"torrent",@"AdiumIcon",@"AdiumSoundset",@"AdiumEmoticon",@"AdiumMessageStyle",nil]

static ESFileTransferPreferences *preferences;

@interface ESFileTransferController ()
- (void)requestForSendingFileToListContact:(AIListContact *)listContact forWindow:(NSWindow *)theWindow;
- (void)configureFileTransferProgressWindow;
- (void)showProgressWindow:(id)sender;
- (void)showProgressWindowIfNotOpen:(id)sender;
- (void)_finishReceiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer localFilename:(NSString *)localFilename;
- (BOOL)shouldOpenCompleteFileTransfer:(ESFileTransfer *)fileTransfer;
- (IBAction)contextualMenuSendFile:(id)sender;
- (IBAction)sendFileToSelectedContact:(id)sender;
@end

@implementation ESFileTransferController

//init
- (id)init
{
	if ((self = [super init])) {
		fileTransferArray = [[NSMutableArray alloc] init];
		safeFileExtensions = nil;
	}
	
	return self;
}

- (void)controllerDidLoad
{
    //Add our get info contextual menu item
    menuItem_sendFileContext = [[NSMenuItem alloc] initWithTitle:SEND_FILE_WITH_ELLIPSIS
														  target:self action:@selector(contextualMenuSendFile:)
												   keyEquivalent:@""];
	[adium.menuController addContextualMenuItem:menuItem_sendFileContext toLocation:Context_Contact_Action];
	
	//Register the events we generate
	NSObject <AIContactAlertsController> *contactAlertsController = adium.contactAlertsController;
	[contactAlertsController registerEventID:FILE_TRANSFER_REQUEST withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_WAITING_REMOTE withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_BEGAN withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_CANCELLED withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_COMPLETE withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:YES];
	[contactAlertsController registerEventID:FILE_TRANSFER_FAILED withHandler:self inGroup:AIFileTransferEventHandlerGroup globalOnly:NO];

    //Install the Send File menu item
	menuItem_sendFile = [[NSMenuItem alloc] initWithTitle:SEND_FILE_WITH_ELLIPSIS
												   target:self action:@selector(sendFileToSelectedContact:)
											keyEquivalent:@"F"];
	[menuItem_sendFile setKeyEquivalentModifierMask:(NSCommandKeyMask | NSShiftKeyMask)];
	[adium.menuController addMenuItem:menuItem_sendFile toLocation:LOC_Contact_Action];
	
	//Add our "Send File" toolbar item
	NSToolbarItem	*toolbarItem;
    toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SEND_FILE_IDENTIFIER
														  label:SEND_FILE
												   paletteLabel:SEND_FILE
														toolTip:AILocalizedString(@"Send a file","Tooltip for the Send File toolbar item")
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:[NSImage imageNamed:@"msg-send-file" forClass:[self class] loadLazily:YES]
														 action:@selector(sendFileToSelectedContact:)
														   menu:nil];
    [adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"ListObject"];
	
    //Register our default preferences
    [adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:FILE_TRANSFER_DEFAULT_PREFS
																		forClass:[self class]] 
										  forGroup:PREF_GROUP_FILE_TRANSFER];
    
    //Observe pref changes
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_FILE_TRANSFER];
	preferences = [(ESFileTransferPreferences *)[ESFileTransferPreferences preferencePane] retain];
	
	//Set up the file transfer progress window
	[self configureFileTransferProgressWindow];
}

- (void)controllerWillClose
{
    [adium.preferenceController unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	[super dealloc];
	
	[safeFileExtensions release]; safeFileExtensions = nil;
	[fileTransferArray release]; fileTransferArray = nil;
}

#pragma mark Access to file transfer objects
- (ESFileTransfer *)newFileTransferWithContact:(AIListContact *)inContact forAccount:(AIAccount *)inAccount type:(AIFileTransferType)t
{
	ESFileTransfer *fileTransfer;
	
	fileTransfer = [ESFileTransfer fileTransferWithContact:inContact
												forAccount:inAccount
													  type:t];
	[fileTransferArray addObject:fileTransfer];
	[fileTransfer setStatus:Not_Started_FileTransfer];

	//Wait until the next run loop to inform observers of the new file transfer object;
	//this way the code which requested a new ESFileTransfer has time to configure it before we
	//dispaly information to the user
	[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotificationName:object:)
									 withObject:FileTransfer_NewFileTransfer 
									 withObject:fileTransfer
									 afterDelay:0];

	return fileTransfer;
}

- (NSUInteger)activeTransferCount
{
	NSUInteger count = 0;
	ESFileTransfer *t;

	for (t in fileTransferArray) {
		AIFileTransferStatus status = [t status];

		if ((status == Unknown_Status_FileTransfer) ||
			(status == Not_Started_FileTransfer) ||
			(status == Checksumming_Filetransfer) ||
			(status == Waiting_on_Remote_User_FileTransfer) ||
			(status == Connecting_FileTransfer) ||
			(status == Accepted_FileTransfer) ||
			(status == In_Progress_FileTransfer))
			count++;
	}
	return count;
}


- (NSArray *)fileTransferArray
{
	return fileTransferArray;
}

//Remove a file transfer from our array.
- (void)_removeFileTransfer:(ESFileTransfer *)fileTransfer
{
	[fileTransferArray removeObject:fileTransfer];
}

#pragma mark Sending and receiving
//Sent by an account when it gets a request for us to receive a file; prompt the user for a save location
- (void)receiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer
{
	AIListContact		*listContact = [fileTransfer contact];
	NSString			*localFilename = nil;

	[fileTransfer setFileTransferType:Incoming_FileTransfer];

	[adium.contactAlertsController generateEvent:FILE_TRANSFER_REQUEST
									 forListObject:listContact
										  userInfo:fileTransfer
					  previouslyPerformedActionIDs:nil];

	if ((autoAcceptType == AutoAccept_All) ||
	   ((autoAcceptType == AutoAccept_FromContactList) && [listContact isIntentionallyNotAStranger])) {
		NSString	*preferredDownloadFolder = [adium.preferenceController userPreferredDownloadFolder];
		NSString	*remoteFilename = [fileTransfer remoteFilename];

		//If the incoming file would become hidden, prefix it with an underscore so it is visible.
		if ([remoteFilename hasPrefix:@"."]) remoteFilename = [@"_" stringByAppendingString:remoteFilename ];

		//If we should autoaccept, determine the local filename and proceed to accept the request.
		localFilename = [preferredDownloadFolder stringByAppendingPathComponent:remoteFilename];
		
		[self _finishReceiveRequestForFileTransfer:fileTransfer
									 localFilename:[[NSFileManager defaultManager] uniquePathForPath:localFilename]];
			
	} else {
		//Prompt to accept/deny
		[ESFileTransferRequestPromptController displayPromptForFileTransfer:fileTransfer
															notifyingTarget:self
																   selector:@selector(_finishReceiveRequestForFileTransfer:localFilename:)];
	}
}

/*!
 * @brief Finish the receive request process
 *
 * Called by either ESFileTransferRequestPromptController or self, this method is the last step in accepting or
 * refusing a request to be sent a file.
 *
 * @param fileTransfer The file transfer in question
 * @param localFilename Full path at which to save the file.  If anything exists at this path it will be overwritten without further confirmation.  Pass nil to deny the transfer.
 */
- (void)_finishReceiveRequestForFileTransfer:(ESFileTransfer *)fileTransfer localFilename:(NSString *)localFilename
{	
	if([fileTransfer isStopped]) //if it's been canceled while we were busy asking the user stuff, ignore it
		return;
	if (localFilename) {
		[fileTransfer setLocalFilename:localFilename];
		[fileTransfer setStatus:Accepted_FileTransfer];

		[(AIAccount<AIAccount_Files> *)fileTransfer.account acceptFileTransferRequest:fileTransfer];
		
		if (showProgressWindow) {
			[self showProgressWindowIfNotOpen:nil];
		}
		
	} else {
		[(AIAccount<AIAccount_Files> *)fileTransfer.account rejectFileReceiveRequest:fileTransfer];
		[fileTransfer setStatus:Cancelled_Local_FileTransfer];
	}	
}

- (NSOpenPanel *)sendFilePanelForListContact:(AIListContact *)listContact
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:[NSString stringWithFormat:AILocalizedString(@"Send File to %@",nil),listContact.displayName]];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setPrompt:AILocalizedStringFromTable(@"Send", @"Buttons", nil)];

    return openPanel;
}

//Prompt the user for the file to send via an Open File dialogue
- (void)requestForSendingFileToListContact:(AIListContact *)listContact
{
	[self requestForSendingFileToListContact:listContact forWindow:nil];
}

- (void)requestForSendingFileToListContact:(AIListContact *)listContact forWindow:(NSWindow *)theWindow
{
	NSOpenPanel *openPanel = [self sendFilePanelForListContact:listContact];
	id handler = ^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			for (NSURL *url in openPanel.URLs) {
				[self sendFile:url.path toListContact:listContact];
			}
		}
	};
	if (theWindow) {
		[openPanel beginSheetModalForWindow:theWindow completionHandler:handler];
	} else {
		[openPanel beginWithCompletionHandler:handler];
	}
}

- (NSString *)pathToArchiveOfFolder:(NSString *)inPath
{
	NSString		*pathToArchive = nil;
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSString		*tmpDir;

	//Desired folder: /private/tmp/$UID/`uuidgen`
	tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	if (tmpDir) {
		NSString	*launchPath = [[[@"/" stringByAppendingPathComponent:@"usr"] stringByAppendingPathComponent:@"bin"] stringByAppendingPathComponent:@"zip"];

		//Proceed only if /usr/bin/zip exists
		if ([defaultManager fileExistsAtPath:launchPath]) {
			NSString	*folderName = [inPath lastPathComponent];
			NSArray		*arguments;
			NSTask		*zipTask = nil;
			
			BOOL		success = YES;

			//Ensure our temporary directory exists [it never will the first time this method is called]
			[defaultManager createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:NULL];

			pathToArchive = [[NSFileManager defaultManager] uniquePathForPath:[tmpDir stringByAppendingPathComponent:[folderName stringByAppendingPathExtension:@"zip"]]];

			arguments = [NSArray arrayWithObjects:
				@"-r", //we'll want to store recursively
				@"-1", //use the fastest level of compression that isn't storage; the user can compress manually to do better
				@"-y", //store symbolic links as such instead of resolving the link
				@"-q", //shhh!
				pathToArchive,   //output to our destination name
				folderName, //store the folder
				nil];
			AILog(@"-[ESFileTransferController pathToArchiveOfFolder:]: Will launch %@ with arguments %@ in directory %@",
				  launchPath, arguments, [inPath stringByDeletingLastPathComponent]);
			@try
			{
				zipTask = [[NSTask alloc] init];
				[zipTask setLaunchPath:launchPath];
				[zipTask setArguments:arguments];
				[zipTask setCurrentDirectoryPath:[inPath stringByDeletingLastPathComponent]];
				[zipTask launch];
				[zipTask waitUntilExit];
			} 
			@catch (id exc) {
				success = NO;
			}

			if (success) {
				success = (([zipTask terminationStatus] == -1) || ([zipTask terminationStatus] == 0));
			}

			if (!success) pathToArchive = nil;
			AILog(@"-[ESFileTransferController pathToArchiveOfFolder:]: Success %i (%i), so pathToArchive is %@",
				  success, [zipTask terminationStatus], pathToArchive);
			[zipTask release];
		}
	}

	return pathToArchive;
}

//Initiate sending a file at a specified path to listContact
- (void)sendFile:(NSString *)inPath toListContact:(AIListContact *)listContact
{
	AIAccount		*account;
	
	if ((account = [adium.accountController preferredAccountForSendingContentType:CONTENT_FILE_TRANSFER_TYPE
																		  toContact:listContact]) &&
		[account conformsToProtocol:@protocol(AIAccount_Files)]) {
		NSFileManager	*defaultManager = [NSFileManager defaultManager];
		BOOL			isDir;
		
		//Resolve any alias we're passed if necessary
		inPath = [defaultManager pathByResolvingAlias:inPath];

		if ([defaultManager fileExistsAtPath:inPath isDirectory:&isDir]) {
			//If we get a directory and the account we're sending from doesn't support folder transfers
			if (isDir &&
				![(AIAccount<AIAccount_Files> *)account canSendFolders]) {
				inPath = [self pathToArchiveOfFolder:inPath];
			}
			
			if (inPath) {
				long fileSize = [[[defaultManager attributesOfItemAtPath:inPath
                                                                   error:NULL] objectForKey:NSFileSize] longValue];
				if (fileSize > 0) {
					ESFileTransfer	*fileTransfer;

					//Set up a fileTransfer object
					fileTransfer = [self newFileTransferWithContact:listContact
														 forAccount:account
															   type:Outgoing_FileTransfer];
					
					[fileTransfer setLocalFilename:inPath];
					[fileTransfer setSize:fileSize];
					
					//The fileTransfer object should now have everything the account needs to begin transferring
					[(AIAccount<AIAccount_Files> *)account beginSendOfFileTransfer:fileTransfer];
					
					if (showProgressWindow) {
						[self showProgressWindowIfNotOpen:nil];
					}
				} else {
					//XXX Show a warning message rather than just beeping
					NSBeep();
				}
			}
		}
	}
}

//Menu or context menu item for sending a file was selected - possible only when a listContact is selected
- (IBAction)sendFileToSelectedContact:(id)sender
{
	//Get the "selected" list object (contact list or message window)
	AIListObject	*selectedObject;
	AIListContact   *listContact = nil;
	
	selectedObject = adium.interfaceController.selectedListObject;
	if ([selectedObject isKindOfClass:[AIListContact class]]) {
		listContact = [adium.contactController preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}
	
	if (listContact) {
		if (![sender isKindOfClass:[NSToolbarItem class]] || !listContact) {
			[self requestForSendingFileToListContact:listContact];
		} else {
			AIChat *theChat = [adium.chatController existingChatWithContact:listContact];
			NSWindow *theWindow = [adium.interfaceController windowForChat:theChat];
			[self requestForSendingFileToListContact:listContact forWindow:theWindow];
		}
	}
}
//Prompt for a new contact with the current tab's name
- (IBAction)contextualMenuSendFile:(id)sender
{
	AIListObject	*selectedObject = adium.menuController.currentContextMenuObject;
	AIListContact   *listContact = [adium.contactController preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																			  forListContact:(AIListContact *)selectedObject];
	
	[NSApp activateIgnoringOtherApps:YES];
	[self requestForSendingFileToListContact:listContact];
}

#pragma mark Status updates
- (void)fileTransfer:(ESFileTransfer *)fileTransfer didSetStatus:(AIFileTransferStatus)status
{
	switch (status) {
		case Checksumming_Filetransfer:
			[adium.contactAlertsController generateEvent:FILE_TRANSFER_CHECKSUMMING
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			
			if (showProgressWindow) {
				[self showProgressWindowIfNotOpen:nil];
			}	
			break;
		case Waiting_on_Remote_User_FileTransfer:
			[adium.contactAlertsController generateEvent:FILE_TRANSFER_WAITING_REMOTE
											 forListObject:[fileTransfer contact]
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			
			if (showProgressWindow) {
				[self showProgressWindowIfNotOpen:nil];
			}
				
				break;
		case Accepted_FileTransfer:
			[adium.contactAlertsController generateEvent:FILE_TRANSFER_BEGAN
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];

			if (showProgressWindow) {
				[self showProgressWindowIfNotOpen:nil];
			}
			
			break;
		case Complete_FileTransfer:
			[adium.contactAlertsController generateEvent:FILE_TRANSFER_COMPLETE
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			
			//The file is complete; if we are supposed to automatically open safe files and this is one, open it
			if ([self shouldOpenCompleteFileTransfer:fileTransfer]) { 
				[fileTransfer openFile];
			}
			
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DownloadFileFinished"
																		   object:fileTransfer.localFilename];
			
			break;
		case Cancelled_Remote_FileTransfer:
			[adium.contactAlertsController generateEvent:FILE_TRANSFER_CANCELLED
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			break;
		case Failed_FileTransfer:
			[adium.contactAlertsController generateEvent:FILE_TRANSFER_FAILED
											 forListObject:[fileTransfer contact] 
												  userInfo:fileTransfer
							  previouslyPerformedActionIDs:nil];
			break;
		default:
			break;
	}
}

- (BOOL)shouldOpenCompleteFileTransfer:(ESFileTransfer *)fileTransfer
{
	BOOL	shouldOpen = NO;
	
	if (autoOpenSafe &&
	   ([fileTransfer fileTransferType] == Incoming_FileTransfer)) {
		
		if (!safeFileExtensions) safeFileExtensions = [SAFE_FILE_EXTENSIONS_SET retain];		

		shouldOpen = [safeFileExtensions containsObject:[[[fileTransfer localFilename] pathExtension] lowercaseString]];
	}

	return shouldOpen;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	AIListContact   *listContact = nil;
	
    if (menuItem == menuItem_sendFile) {
        AIListObject	*selectedObject = adium.interfaceController.selectedListObject;
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]) {
			listContact = [adium.contactController preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
		
		return listContact != nil;
		
	} else if (menuItem == menuItem_sendFileContext) {
		AIListObject	*selectedObject = adium.menuController.currentContextMenuObject;
		if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]) {
			listContact = [adium.contactController preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																	 forListContact:(AIListContact *)selectedObject];
		}
		
		return listContact != nil;
		
    } else if (menuItem == menuItem_showFileTransferProgress) {
		return YES;
	}

    return YES;
}

/*
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	AIListContact   *listContact = nil;
	
	AIListObject	*selectedObject = adium.interfaceController.selectedListObject;
	if (selectedObject && [selectedObject isKindOfClass:[AIListContact class]]) {
		listContact = [adium.contactController preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																 forListContact:(AIListContact *)selectedObject];
	}

    return listContact != nil;
}
*/
#pragma mark File transfer progress window
- (void)configureFileTransferProgressWindow
{
	//Add the File Transfer Progress window menuItem
	menuItem_showFileTransferProgress = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"File Transfers",nil)
																   target:self 
																   action:@selector(showProgressWindow:)
															keyEquivalent:@"l"];
	[menuItem_showFileTransferProgress setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
	[adium.menuController addMenuItem:menuItem_showFileTransferProgress toLocation:LOC_Window_Auxiliary];
}

//Show the file transfer progress window
- (void)showProgressWindow:(id)sender
{
	[ESFileTransferProgressWindowController showFileTransferProgressWindow];
}

- (void)showProgressWindowIfNotOpen:(id)sender
{
	[ESFileTransferProgressWindowController showFileTransferProgressWindowIfNotOpen];	
}

#pragma mark Preferences
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	autoAcceptType = [[prefDict objectForKey:KEY_FT_AUTO_ACCEPT] intValue];
	autoOpenSafe = [[prefDict objectForKey:KEY_FT_AUTO_OPEN_SAFE] boolValue];
	
	//If we created a safe file extensions set and no longer need it, desroy it
	if (!autoOpenSafe && safeFileExtensions) {
		[safeFileExtensions release]; safeFileExtensions = nil;
	}
	
	showProgressWindow = [[prefDict objectForKey:KEY_FT_SHOW_PROGRESS_WINDOW] boolValue];
}

#pragma mark AIEventHandler

- (NSString *)shortDescriptionForEventID:(NSString *)eventID
{
	NSString *description;

	if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
		description = AILocalizedString(@"File transfer fails",nil);
	} else {
		description = @"";
	}
	
	return description;
}

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
		description = AILocalizedString(@"File transfer requested",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CHECKSUMMING]) {
		description = AILocalizedString(@"File is checksummed before sending",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_WAITING_REMOTE]) {
		description = AILocalizedString(@"File transfer being offered to other side",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
		description = AILocalizedString(@"File transfer begins",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
		description = AILocalizedString(@"File transfer cancelled by the other side",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
		description = AILocalizedString(@"File transfer completed successfully",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
		description = AILocalizedString(@"File transfer failed",nil);
	} else {		
		description = @"";	
	}
	
	return description;
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
//XXX-fix this for the above comment.
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
		description = @"File Transfer Request";
	} else if ([eventID isEqualToString:FILE_TRANSFER_CHECKSUMMING]) {
		description = @"File Checksumming for Sending";
	} else if ([eventID isEqualToString:FILE_TRANSFER_WAITING_REMOTE]) {
		description = @"File Transfer Being Offered to Remote User";
	}  else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
		description = @"File Transfer Began";
	} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
		//Canceled, not Cancelled as we use elsewhere in Adium, for historical reasons. Both are valid spellings.
		description = @"File Transfer Canceled Remotely";
	} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
		description = @"File Transfer Complete";
	} else if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
		description = @"File transfer failed";
	} else {		
		description = @"";	
	}
	
	return description;
}

- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject
{	
	NSString	*description;
	
	if (listObject) {
		NSString *format;
		
		if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
			format = AILocalizedString(@"When a file transfer with %@ fails",nil);	
		} else {
			format = nil;	
		}
		
		if (format) {
			NSString *name;
			name = ([listObject isKindOfClass:[AIListGroup class]] ?
					[NSString stringWithFormat:AILocalizedString(@"a member of %@",nil),listObject.displayName] :
					listObject.displayName);
			
			description = [NSString stringWithFormat:format, name];

		} else {
			description = @"";
		}
		
	} else {
		if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
			description = AILocalizedString(@"When a file transfer is requested",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_CHECKSUMMING]) {
			description = AILocalizedString(@"When a file is checksummed prior to sending",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_WAITING_REMOTE]) {
			description = AILocalizedString(@"When a file transfer is offered to a remote user",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
			description = AILocalizedString(@"When a file transfer begins",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
			description = AILocalizedString(@"When a file transfer is cancelled remotely",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
			description = AILocalizedString(@"When a file transfer is completed successfully",nil);
		} else if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
			description = AILocalizedString(@"When a file transfer fails",nil);
		} else {
			description = @"";	
		}
	}

	return description;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString		*description = nil;
	NSString		*displayName, *displayFilename;
	ESFileTransfer	*fileTransfer;

	NSParameterAssert([userInfo isKindOfClass:[ESFileTransfer class]]);
	fileTransfer = (ESFileTransfer *)userInfo;
	
	displayName = listObject.displayName;
	displayFilename = [fileTransfer displayFilename];
	
	if (includeSubject) {
		NSString	*format = nil;
		
		if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
			//Should only happen for an incoming transfer
			format = AILocalizedString(@"%@ requests to send you %@","A person is wanting to send you a file. The first %@ is a name; the second %@ is the filename of the file being sent.");
			
		} else if ([eventID isEqualToString:FILE_TRANSFER_WAITING_REMOTE]) {
			//Should only happen for outgoing file transfers
			format = AILocalizedString(@"Offering to send %@ to %@","You are offering to send a file to a remote user. The first %@ is the filename of the file being sent; the second %@ is the recipient of the file being sent.");
		
		} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"%@ began sending you %@","A person began sending you a file. The first %@ is a name; the second %@ is the filename of the file being sent.");
			} else {
				format = AILocalizedString(@"%@ began receiving %@","A person began receiving a file from you. The first %@ is the recipient of the file; the second %@ is the filename of the file being sent.");
			}
		} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
			format = AILocalizedString(@"%@ cancelled the transfer of %@","The other contact cancelled a file transfer in progress. The first %@ is the recipient of the file; the second %@ is the filename of the file being sent.");
		} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"%@ sent you %@","First placeholder is a name; second is a filename");
			} else {
				format = AILocalizedString(@"%@ received %@","First placeholder is a name; second is a filename");
			}
		} else if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"%@'s transfer of %@ failed","First placeholder is a name; second is a filename");

			} else {
				format = AILocalizedString(@"Your transfer to %@ of %@ failed","First placeholder is a name; second is a filename");				
			}
		}
		
		if (format) {
			description = [NSString stringWithFormat:format,displayName,displayFilename];
		}
	} else {
		NSString	*format = nil;
		
		if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
			//Should only happen for an incoming transfer
			format = AILocalizedString(@"requests to send you %@","%@ is a filename of a file being sent");
			
		}else if ([eventID isEqualToString:FILE_TRANSFER_WAITING_REMOTE]) {
			//Should only happen for an outgoing transfer
			format = AILocalizedString(@"offers to send %@","%@ is a filename of a file being sent");
		
		} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"began sending you %@","%@ is a filename of a file being sent");
			} else {
				format = AILocalizedString(@"began receiving %@","%@ is a filename of a file being sent");
			}
		} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
			format = AILocalizedString(@"cancelled the transfer of %@","%@ is a filename of a file being sent");
		} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"sent you %@","%@ is a filename of a file being sent");
			} else {
				format = AILocalizedString(@"received %@","%@ is a filename of a file being sent");
			}
		} else if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
			if ([fileTransfer fileTransferType] == Incoming_FileTransfer) {
				format = AILocalizedString(@"failed to send you %@","%@ is a filename of a file being sent");
			} else {
				format = AILocalizedString(@"failed to receive %@","%@ is a filename of a file being sent");
			}
		}

		if (format) {
			description = [NSString stringWithFormat:format,displayFilename];
		}		
	}

	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	if (!eventImage) eventImage = [[NSImage imageNamed:@"pref-file-transfer" forClass:[self class]] retain];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	NSString *format = nil;
	
	if ([eventID isEqualToString:FILE_TRANSFER_REQUEST]) {
		format = AILocalizedString(@"%u incoming file transfers",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CHECKSUMMING]) {
		format = AILocalizedString(@"%u files being checksummed prior to sending",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_WAITING_REMOTE]) {
		format = AILocalizedString(@"%u files offered to send",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_BEGAN]) {
		format = AILocalizedString(@"%u files began transferring",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_CANCELLED]) {
		format = AILocalizedString(@"%u files cancelled remotely",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_COMPLETE]) {
		format = AILocalizedString(@"%u files completed successfully",nil);
	} else if ([eventID isEqualToString:FILE_TRANSFER_FAILED]) {
		format = AILocalizedString(@"%u file transfers failed",nil);
	}	
	
	return format ? [NSString stringWithFormat:format, count] : @"";
}

#pragma mark Strings for sizes

#define	ZERO_BYTES			AILocalizedString(@"Zero bytes", "no file size")

- (NSString *)stringForSize:(unsigned long long)inSize
{
	NSString *ret = nil;
	
	if ( inSize == 0. ) ret = ZERO_BYTES;
	else if ( inSize > 0. && inSize < 1024. ) ret = [NSString stringWithFormat:AILocalizedString( @"%llu bytes", "file size measured in bytes" ), inSize];
	else if ( inSize >= 1024. && inSize < pow( 1024., 2. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.1f KB", "file size measured in kilobytes" ), ( inSize / 1024. )];
	else if ( inSize >= pow( 1024., 2. ) && inSize < pow( 1024., 3. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.2f MB", "file size measured in megabytes" ), ( inSize / pow( 1024., 2. ) )];
	else if ( inSize >= pow( 1024., 3. ) && inSize < pow( 1024., 4. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.3f GB", "file size measured in gigabytes" ), ( inSize / pow( 1024., 3. ) )];
	else if ( inSize >= pow( 1024., 4. ) ) ret = [NSString stringWithFormat:AILocalizedString( @"%.4f TB", "file size measured in terabytes" ), ( inSize / pow( 1024., 4. ) )];
	
	if (!ret) ret = ZERO_BYTES;
	
	return ret;
}

- (NSString *)stringForSize:(unsigned long long)inSize of:(unsigned long long)totalSize ofString:(NSString *)totalSizeString
{
	NSString *ret = nil;
	
	if ( inSize == 0. ) {
		ret = ZERO_BYTES;
	} else if ( inSize > 0. && inSize < 1024. ) {
		if ( totalSize > 0. && totalSize < 1024. ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%llu of %llu bytes", "file sizes both measured in bytes" ), inSize, totalSize];
			
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%llu bytes of %@", "file size measured in bytes out of some other measurement" ), inSize, totalSizeString];
			
		}
	} else if ( inSize >= 1024. && inSize < pow( 1024., 2. ) ) {
		if ( totalSize >= 1024. && totalSize < pow( 1024., 2. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.1f of %.1f KB", "file sizes both measured in kilobytes" ), ( inSize / 1024. ), ( totalSize / 1024. )];
			
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.1f KB of %@", "file size measured in kilobytes out of some other measurement" ), ( inSize / 1024. ), totalSizeString];
		}
	}
	else if ( inSize >= pow( 1024., 2. ) && inSize < pow( 1024., 3. ) ) {
		if ( totalSize >= pow( 1024., 2. ) && totalSize < pow( 1024., 3. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.2f of %.2f MB", "file sizes both measured in megabytes" ), ( inSize / pow( 1024., 2. ) ), ( totalSize / pow( 1024., 2. ) )];
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.2f MB of %@", "file size measured in megabytes out of some other measurement" ), ( inSize / pow( 1024., 2. ) ), totalSizeString];	
		}
	}
	else if ( inSize >= pow( 1024., 3. ) && inSize < pow( 1024., 4. ) ) {
		if ( totalSize >= pow( 1024., 3. ) && totalSize < pow( 1024., 4. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.3f of %.3f GB", "file sizes both measured in gigabytes" ), ( inSize / pow( 1024., 3. ) ), ( totalSize / pow( 1024., 3. ) )];
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.3f GB of %@", "file size measured in gigabytes out of some other measurement" ), ( inSize / pow( 1024., 3. ) ), totalSizeString];
			
		}
	}
	else if ( inSize >= pow( 1024., 4. ) ) {
		if ( totalSize >= pow( 1024., 4. ) ) {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.4f of %.4f TB", "file sizes both measured in terabytes" ), ( inSize / pow( 1024., 4. ) ),  ( totalSize / pow( 1024., 4. ) )];
		} else {
			ret = [NSString stringWithFormat:AILocalizedString( @"%.4f TB of %@", "file size measured in terabytes out of some other measurement" ), ( inSize / pow( 1024., 4. ) ), totalSizeString];			
		}
	}
	
	if (!ret) ret = ZERO_BYTES;
	
	return ret;
}

@end
