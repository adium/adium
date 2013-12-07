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

/*!
 * @class AICoreComponentLoader
 * @brief Core - Component Loader
 *
 * Loads integrated plugins.  Component classes to load are determined by CoreComponents.plist
 */

#import "AICoreComponentLoader.h"

//#define COMPONENT_LOAD_TIMING
#ifdef COMPONENT_LOAD_TIMING
NSTimeInterval aggregateComponentLoadingTime = 0.0;
#endif

@interface AICoreComponentLoader ()
- (void)loadComponents;
@end

@implementation AICoreComponentLoader

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		components = [[NSMutableDictionary alloc] init];
		
		[self loadComponents];
	}

	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[components release];
	[super dealloc];
}

#pragma mark -

/*!
 * @brief Load integrated components
 */
- (void)loadComponents
{
	//Fetch the list of components to load
	NSArray *componentClassNames = [NSArray arrayWithObjects: 
		@"AIAccountListPreferencesPlugin",
		@"AIAccountMenuAccessPlugin",
		@"AIAliasSupportPlugin",
		@"AIAppearancePreferencesPlugin",
		@"AIAutoLinkingPlugin",
		@"AIAutoReplyPlugin",
		@"AIChatConsolidationPlugin",
		@"AIChatCyclingPlugin",
		@"AIContactAwayPlugin",
		@"AIContactIdlePlugin",
		@"AIContactInfoWindowPlugin",
		@"AIContactListEditorPlugin",
		@"AIContactOnlineSincePlugin",
		@"AIContactSortSelectionPlugin",
		@"AIContactStatusColoringPlugin",
		@"AIDockNameOverlay",
		@"AIContactStatusEventsPlugin",
		@"AIDockAccountStatusPlugin",
		@"AIDockBehaviorPlugin",
		@"AIDualWindowInterfacePlugin",
		@"AIEventSoundsPlugin",
		@"AIExtendedStatusPlugin",
		@"AILoggerPlugin",
		@"AIMessageAliasPlugin",
		@"AINewMessagePanelPlugin",
		@"AINudgeBuzzHandlerPlugin",
		@"AIContactVisibilityControlPlugin",
		@"AISCLViewPlugin",
		@"AIStandardToolbarItemsPlugin",
		@"AIStateMenuPlugin",
		@"AIStatusChangedMessagesPlugin",
		@"AITabStatusIconsPlugin",
		@"BGContactNotesPlugin",
		@"BGEmoticonMenuPlugin",
		@"CBActionSupportPlugin",
		@"CBContactCountingDisplayPlugin",
		@"CBContactLastSeenPlugin",
		@"CBStatusMenuItemPlugin",
		@"DCInviteToChatPlugin",
		@"DCJoinChatPanelPlugin",
		@"DCMessageContextDisplayPlugin",
		@"AIAddBookmarkPlugin",
		@"ESAccountEvents",
		@"ESAccountNetworkConnectivityPlugin",
		@"ESAnnouncerPlugin",
		@"ESApplescriptContactAlertPlugin",
		@"ESBlockingPlugin",
		@"ESContactClientPlugin",
		@"ESContactServersideDisplayName",
		@"ESFileTransferMessagesPlugin",
		@"AIListObjectContentsPlugin",
		@"ESOpenMessageWindowContactAlertPlugin",
		@"ESSendMessageContactAlertPlugin",
		@"ESUserIconHandlingPlugin",
		@"ErrorMessageHandlerPlugin",
		@"GBApplescriptFiltersPlugin",
		@"SAContactOnlineForPlugin",
		@"SHLinkManagementPlugin",
		@"ESGlobalEventsPreferencesPlugin",
		@"ESGeneralPreferencesPlugin",
		@"NEHGrowlPlugin",
		@"ESSecureMessagingPlugin",
		@"ESStatusPreferencesPlugin",
		@"AIAutomaticStatus",
		@"ESAwayStatusWindowPlugin",
		@"RAFBlockEditorPlugin",
		@"SMContactListShowBehaviorPlugin",
		@"ESiTunesPlugin",
		@"ESProfilePreferencesPlugin",
		@"OWSpellingPerContactPlugin",
		@"GBQuestionHandlerPlugin",
		@"AINulRemovalPlugin",
		@"AIDefaultFontRemovalPlugin",
		@"AIAdvancedPreferencesPlugin",
		@"GBImportPlugin",
		@"AIMentionEventPlugin",
		@"AITwitterIMPlugin",
		@"AITwitterPlugin",
//		@"AILaconicaPlugin",
		@"AITwitterURLHandler",
		@"AITwitterActionsHTMLFilter",
		@"AIURLShortenerPlugin",
		@"AIGroupChatStatusTooltipPlugin",
		@"AIRealNameTooltip",
		@"AIUserHostTooltip",
		@"AIUnreadMessagesTooltip",
		@"AIIRCChannelLinker",
		@"AIURLHandlerPlugin",
		@"AIJumpControlPlugin",
		@"AIWebKitMessageViewPlugin",
		@"AWBonjourPlugin",
		@"CBPurpleServicePlugin",
		@"AIImageUploaderPlugin",
		@"AITwitterStatusFollowup",
		@"AIDoNothingContactAlertPlugin",
		nil
	];
	//Load each component
	for (NSString *className in componentClassNames) {
			
#ifdef COMPONENT_LOAD_TIMING
		NSDate *start = [NSDate date];
#endif
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		Class class;

		if (className && (class = NSClassFromString(className))) {
			id <AIPlugin>	object = [[class alloc] init];

			NSAssert1(object, @"Failed to load %@", className);

			[object installPlugin];

			[components setObject:object forKey:className];
			[object release];
		} else {
			NSAssert1(NO, @"Failed to load %@", className);
		}
		[pool release];
#ifdef COMPONENT_LOAD_TIMING
		NSTimeInterval t = -[start timeIntervalSinceNow];
		aggregateComponentLoadingTime += t;
		AILog(@"Loaded component: %@ in %f seconds", className, t);
#endif
	}
#ifdef COMPONENT_LOAD_TIMING
	AILog(@"Total time spent loading components: %f", aggregateComponentLoadingTime);
#endif
}

- (void)controllerDidLoad
{
}

/*!
 * @brief Close integreated components
 */
- (void)controllerWillClose
{
	for (id <AIPlugin> plugin in [components objectEnumerator]) {
		[[NSNotificationCenter defaultCenter] removeObserver:plugin];
		[plugin uninstallPlugin];
	}
}

#pragma mark -

/*!
 * @brief Retrieve a component plugin by its class name
 */
- (id <AIPlugin>)pluginWithClassName:(NSString *)className {
	return [components objectForKey:className];
}

@end
