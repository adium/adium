/*
 *  AIAdiumProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 9/10/06.
 */


@class AICoreComponentLoader, AICorePluginLoader;

typedef enum {
	AIQuitConfirmAlways = 0,
	AIQuitConfirmSelective
} AIQuitConfirmationType;

@protocol AIAccountController, AIChatController, AIContactAlertsController, AIDebugController, AIEmoticonController,
		  AIPreferenceController, AIMenuController, AIApplescriptabilityController, AIStatusController,
		  AIContentController, AIToolbarController, AISoundController, AIDockController,
		  AIFileTransferController, AILoginController, AIInterfaceController, AIContactController;

@protocol AIAdium <NSObject>
- (NSObject <AIAccountController> *)accountController;
- (NSObject <AIChatController> *)chatController;
- (NSObject <AIContactController> *)contactController;
- (NSObject <AIContentController> *)contentController;
- (NSObject <AIDockController> *)dockController;
- (NSObject <AIEmoticonController> *)emoticonController;
- (NSObject <AIInterfaceController> *)interfaceController;
- (NSObject <AILoginController> *)loginController;
- (NSObject <AIMenuController> *)menuController;
- (NSObject <AIPreferenceController> *)preferenceController;
- (NSObject <AISoundController> *)soundController;
- (NSObject <AIStatusController> *)statusController;
- (NSObject <AIToolbarController> *)toolbarController;
- (NSObject <AIContactAlertsController> *)contactAlertsController;
- (NSObject <AIFileTransferController> *)fileTransferController;

#ifdef DEBUG_BUILD
- (NSObject <AIDebugController> *)debugController;
#endif

- (NSObject <AIApplescriptabilityController> *)applescriptabilityController;

- (NSNotificationCenter *)notificationCenter;
- (AICoreComponentLoader *)componentLoader;
- (AICorePluginLoader *)pluginLoader;

- (NSString *)applicationSupportDirectory;
- (NSString *)createResourcePathForName:(NSString *)name;
- (NSArray *)resourcePathsForName:(NSString *)name;
- (NSArray *)allResourcesForName:(NSString *)name withExtensions:(id)extensions;
- (NSString *)pathOfPackWithName:(NSString *)name extension:(NSString *)extension resourceFolderName:(NSString *)folderName;
- (NSString *)cachesPath;

- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB;

- (BOOL)isQuitting;

@end

//Adium events
#define KEY_EVENT_DISPLAY_NAME		@"DisplayName"
#define KEY_EVENT_NOTIFICATION		@"Notification"

//Adium Notifications
#define CONTACT_STATUS_ONLINE_YES			@"Contact_StatusOnlineYes"	// Contact signs on
#define CONTACT_STATUS_ONLINE_NO			@"Contact_StatusOnlineNo"	// Contact signs off
#define CONTACT_STATUS_AWAY_YES				@"Contact_StatusAwayYes"
#define CONTACT_STATUS_AWAY_NO				@"Contact_StatusAwayNo"
#define CONTACT_STATUS_IDLE_YES				@"Contact_StatusIdleYes"
#define CONTACT_STATUS_IDLE_NO				@"Contact_StatusIdleNo"
#define CONTACT_STATUS_MESSAGE				@"Contact_StatusMessage"
#define CONTACT_SEEN_ONLINE_YES				@"Contact_SeenOnlineYes"
#define CONTACT_SEEN_ONLINE_NO				@"Contact_SeenOnlineNo"
#define CONTENT_MESSAGE_SENT				@"Content_MessageSent"
#define CONTENT_MESSAGE_RECEIVED			@"Content_MessageReceived"
#define CONTENT_MESSAGE_RECEIVED_GROUP		@"Content_MessageReceivedGroup"
#define CONTENT_MESSAGE_RECEIVED_FIRST		@"Content_MessageReceivedFirst"
#define CONTENT_MESSAGE_RECEIVED_BACKGROUND	@"Content_MessageReceivedBackground"
#define CONTENT_MESSAGE_RECEIVED_BACKGROUND_GROUP		@"Content_MessageReceivedBackgroundGroup"
#define CONTENT_NUDGE_BUZZ_OCCURED			@"Content_NudgeBuzzOccured"
#define CONTENT_CONTACT_JOINED_CHAT			@"Content_ContactJoinedChat"
#define CONTENT_CONTACT_LEFT_CHAT			@"Content_ContactLeftChat"
#define CONTENT_GROUP_CHAT_INVITE			@"Content_GroupChatInvite"
#define CONTENT_GROUP_CHAT_MENTION			@"Content_GroupChatMention"
#define INTERFACE_ERROR_MESSAGE				@"Interface_ErrorMessageReceived"

/* Note: The account connected/disconnected events are aggregated for many accounts connecting simultaneously.
 * Use a list object observer (see AIContactController) if you are concerned about specific account connectivity changes.
 */
#define ACCOUNT_CONNECTED					@"Account_Connected"
#define ACCOUNT_DISCONNECTED				@"Account_Disconnected"

#define	ACCOUNT_RECEIVED_EMAIL				@"Account_NewMailReceived"
#define FILE_TRANSFER_REQUEST				@"FileTransfer_Request"
#define FILE_TRANSFER_CHECKSUMMING			@"FileTransfer_Checksumming"
#define FILE_TRANSFER_WAITING_REMOTE		@"File_Transfer_WaitingRemote"
#define FILE_TRANSFER_BEGAN					@"FileTransfer_Began"
#define FILE_TRANSFER_CANCELLED				@"FileTransfer_Cancelled"
#define FILE_TRANSFER_FAILED				@"FileTransfer_Failed"
#define FILE_TRANSFER_COMPLETE				@"FileTransfer_Complete"

#define AIXtrasDidChangeNotification				@"AIXtrasDidChange"
#define AIApplicationDidFinishLoadingNotification	@"AIApplicationDidFinishLoading"
#define AIAppWillTerminateNotification				@"AIAppWillTerminate"
#define AIShowLogAtPathNotification					@"AIShowLogAtPath"
#define AINetworkDidChangeNotification				@"AINetworkDidChange"
