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

#import "AIWebKitMessageViewController.h"
#import "AIWebKitMessageViewStyle.h"
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebKitMessageViewPreferences.h"
#import "AIWebKitDelegate.h"
#import "ESFileTransferRequestPromptController.h"
#import "ESWebView.h"
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIFileTransferControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIGroupChat.h>
#import <Adium/AIContentTopic.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIContentEvent.h>
#import <Adium/AIEmoticon.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <AIUtilities/AIPasteboardAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/JVMarkedScroller.h>
#import <objc/objc-runtime.h>

#define KEY_WEBKIT_CHATS_USING_CACHED_ICON @"WebKit:Chats Using Cached Icon"

#define USE_FASTER_BUT_BUGGY_WEBKIT_PREFERENCE_CHANGE_HANDLING FALSE

#define TEMPORARY_FILE_PREFIX	@"TEMP"

@interface AIWebKitMessageViewController ()
- (id)initForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin;
- (void)_initWebView;
- (void)_primeWebViewAndReprocessContent:(BOOL)reprocessContent;
- (void)_updateWebViewForCurrentPreferences;
- (void)_updateVariantWithoutPrimingView;
- (void)processQueuedContent;
- (void)_processContentObject:(AIContentObject *)content willAddMoreContentObjects:(BOOL)willAddMoreContentObjects;
- (void)_appendContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects replaceLastContent:(BOOL)replaceLastContent;
- (void)_setDocumentReady;

- (NSString *)_webKitBackgroundImagePathForUniqueID:(NSInteger)uniqueID;
- (NSString *)_webKitUserIconPathForObject:(AIListObject *)inObject;
- (void)releaseCurrentWebKitUserIconForObject:(AIListObject *)inObject;
- (void)releaseAllCachedIcons;
- (void)updateUserIconForObject:(AIListObject *)inObject;
- (void)userIconForObjectDidChange:(AIListObject *)inObject;
- (void)updateServiceIcon;
- (void)updateTopic;

- (void)participatingListObjectsChanged:(NSNotification *)notification;
- (void)sourceOrDestinationChanged:(NSNotification *)notification;
- (BOOL)shouldHandleDragWithPasteboard:(NSPasteboard *)pasteboard;
- (void)enqueueContentObject:(AIContentObject *)contentObject;
- (void)debugLog:(NSString *)message;
- (void)processQueuedContent;
- (NSString *)webviewSource;
- (void) setIsGroupChat:(BOOL) flag;

- (void)setupMarkedScroller;
- (JVMarkedScroller *)markedScroller;
- (NSNumber *)currentOffsetHeight;
- (void)markCurrentLocation;

- (void)contentObjectAdded:(NSNotification *)notification;
- (void)chatDidFinishAddingUntrackedContent:(NSNotification *)notification;
- (void)customEmoticonUpdated:(NSNotification *)inNotification;
- (void)listObjectAttributesChanged:(NSNotification *)notification;
- (BOOL)zoomImage:(DOMHTMLImageElement *)img;
@end

static NSArray *draggedTypes = nil;

@implementation AIWebKitMessageViewController

+ (AIWebKitMessageViewController *)messageDisplayControllerForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin
{
    return [[[self alloc] initForChat:inChat withPlugin:inPlugin] autorelease];
}

- (id)initForChat:(AIChat *)inChat withPlugin:(AIWebKitMessageViewPlugin *)inPlugin
{
    //init
    if ((self = [super init])) {
		[self _initWebView];
		
		delegateProxy = [AIWebKitDelegate sharedWebKitDelegate];
		
		chat = [inChat retain];
		plugin = [inPlugin retain];
		contentQueue = [[NSMutableArray alloc] init];
		objectIconPathDict = [[NSMutableDictionary alloc] init];
		objectsWithUserIconsArray = [[NSMutableArray alloc] init];
		shouldReflectPreferenceChanges = NO;
		storedContentObjects = nil;
		/* If we receive content before gaining focus, we'll want to know the first content received is the first to be
		 * classed as such.
		 */
		nextMessageFocus = YES;
		nextMessageRegainedFocus = YES;
		
		//Observe preference changes.
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY];
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES];
		
		//Set ourselves up initially.
		[self _updateWebViewForCurrentPreferences];
		
		//Observe participants list changes
		[[NSNotificationCenter defaultCenter] addObserver:self 
									   selector:@selector(participatingListObjectsChanged:)
										   name:Chat_ParticipatingListObjectsChanged 
										 object:inChat];

		//Observe source/destination changes
		[[NSNotificationCenter defaultCenter] addObserver:self 
									   selector:@selector(sourceOrDestinationChanged:)
										   name:Chat_SourceChanged 
										 object:inChat];
		[[NSNotificationCenter defaultCenter] addObserver:self 
									   selector:@selector(sourceOrDestinationChanged:)
										   name:Chat_DestinationChanged 
										 object:inChat];
		
		//Observe content additons
		[[NSNotificationCenter defaultCenter] addObserver:self 
									   selector:@selector(contentObjectAdded:)
										   name:Content_ContentObjectAdded 
										 object:inChat];
		[[NSNotificationCenter defaultCenter] addObserver:self 
									   selector:@selector(chatDidFinishAddingUntrackedContent:)
										   name:Content_ChatDidFinishAddingUntrackedContent 
										 object:inChat];

		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(customEmoticonUpdated:)
										   name:@"AICustomEmoticonUpdated"
										 object:inChat];
	}
	
    return self;
}

- (void)messageViewIsClosing
{
	[webView stopLoading:nil];
	
	//Stop observing the webview, since it may attempt callbacks shortly after we dealloc
	[delegateProxy removeDelegate:self];
	
	/* The windowScriptObject retained self when we set it as the client in -[AIWebKitMessageViewController _initWebView]...
	 * Unfortunately, (as of 10.4.9) it won't actually release self until the webView deallocates.  We'll do removeWebScriptKey:
	 * now in case that works properly later, and do the release of webView here rather than in dealloc to work around the bug.
	 */
	[[webView windowScriptObject] removeWebScriptKey:@"client"];

	//Release the web view
	[webView release]; webView = nil;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[self releaseAllCachedIcons];

	[plugin release]; plugin = nil;
	[objectsWithUserIconsArray release]; objectsWithUserIconsArray = nil;
	[objectIconPathDict release]; objectIconPathDict = nil;

	//Stop any delayed requests and remove all observers
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//Clean up style/variant info
	[messageStyle release]; messageStyle = nil;
	[activeStyle release]; activeStyle = nil;
	[preferenceGroup release]; preferenceGroup = nil;
	
	//Cleanup content processing
	[contentQueue release]; contentQueue = nil;
	[storedContentObjects release]; storedContentObjects = nil;
	[previousContent release]; previousContent = nil;

	//Release the chat
	[chat release]; chat = nil;
	
	//Release the marked scroller
	[self.markedScroller release];

	[super dealloc];
}

- (void)setShouldReflectPreferenceChanges:(BOOL)inValue
{
	shouldReflectPreferenceChanges = inValue;

	//We'll want to start storing content objects if we're needing to reflect preference changes
	if (shouldReflectPreferenceChanges) {
		if (!storedContentObjects) {
			storedContentObjects = [[NSMutableArray alloc] init];
		}
	} else {
		[storedContentObjects release]; storedContentObjects = nil;
	}
}

- (void)adiumPrint:(id)sender
{	
	WebPreferences* prefs = [webView preferences];
	[prefs setShouldPrintBackgrounds:YES];

	[[[[webView mainFrame] frameView] documentView] print:sender];
}

//WebView --------------------------------------------------------------------------------------------------
#pragma mark WebView

@synthesize messageStyle, messageView = webView;

- (NSView *)messageScrollView
{
	return [[webView mainFrame] frameView];
}

/*!
 * @brief Apply preference changes to our webview
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	// First time won't occur because preferenceGroup is not yet set. Don't run on the assumption that it is, end early.
	if (!preferenceGroup)
		return;
	
	if ([group isEqualToString:preferenceGroup]) {
#if USE_FASTER_BUT_BUGGY_WEBKIT_PREFERENCE_CHANGE_HANDLING
		NSString		*variantKey = [plugin styleSpecificKey:@"Variant" forStyle:activeStyle];
		//Variant changes we can apply immediately.  All other changes require us to reload the view
		if (!firstTime && [key isEqualToString:variantKey]) {
			messageStyle.activeVariant = [prefDict objectForKey:variantKey];
			[self _updateVariantWithoutPrimingView];
			
		} else if (shouldReflectPreferenceChanges) {
			//Ignore changes related to our background image cache.  These keys are used for storage only and aren't
			//something we need to update in response to.  All other display changes we update our view for.
			if (![key isEqualToString:@"BackgroundCacheUniqueID"] &&
			    ![key isEqualToString:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]] &&
				![key isEqualToString:KEY_CURRENT_WEBKIT_STYLE_PATH]) {
				[self _updateWebViewForCurrentPreferences];
			}
		}
#else
		if (shouldReflectPreferenceChanges) {
			//Ignore changes related to our background image cache.  These keys are used for storage only and aren't
			//something we need to update in response to.  All other display changes we update our view for.
			if (![key isEqualToString:@"BackgroundCacheUniqueID"] &&
			    ![key isEqualToString:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]] &&
				(![key isEqualToString:KEY_CURRENT_WEBKIT_STYLE_PATH] || shouldReflectPreferenceChanges)) {
				if (!isUpdatingWebViewForCurrentPreferences) {
					[self _updateWebViewForCurrentPreferences];
				}
			}
		}
#endif
	}
	
	if (([group isEqualToString:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES] && shouldReflectPreferenceChanges)) {
		//If the background image changes, wipe the cache and update for the new image
		[adium.preferenceController setPreference:nil
											 forKey:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]
											  group:preferenceGroup];	
		if (!isUpdatingWebViewForCurrentPreferences) {
			[self _updateWebViewForCurrentPreferences];
		}
	}	
}

/*!
 * @brief Initialiaze the web view
 */
- (void)_initWebView
{
	//Create our webview
	webView = [[ESWebView alloc] initWithFrame:NSMakeRect(0,0,100,100) //Arbitrary frame
									 frameName:nil
									 groupName:nil];
	[webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[delegateProxy addDelegate:self forView:webView];
	[webView setMaintainsBackForwardList:NO];

	if (!draggedTypes) {
		draggedTypes = [[NSArray alloc] initWithObjects:
			NSFilenamesPboardType,
			AIiTunesTrackPboardType,
			NSTIFFPboardType,
			NSPDFPboardType,
			NSHTMLPboardType,
			NSFileContentsPboardType,
			NSRTFPboardType,
			NSStringPboardType,
			NSPostScriptPboardType,
			nil];
	}
	[webView registerForDraggedTypes:draggedTypes];
}

/*!
 * @brief Updates our webview to the current preferences, priming the view
 */
- (void)_updateWebViewForCurrentPreferences
{
	static dispatch_queue_t webViewUpdateQueue = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		webViewUpdateQueue = dispatch_queue_create("im.adium.AIWebKitMessageViewController.webViewUpdateQueue", 0);
	});
	
	isUpdatingWebViewForCurrentPreferences = YES;
	dispatch_sync(webViewUpdateQueue, ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//Cleanup first
		[messageStyle autorelease]; messageStyle = nil;
		[activeStyle release]; activeStyle = nil;
		
		//Load the message style
		messageStyle = [[plugin currentMessageStyleForChat:chat] retain];
		activeStyle = [[[messageStyle bundle] bundleIdentifier] retain];
		preferenceGroup = [[plugin preferenceGroupForChat:chat] retain];
		
		[webView setPreferencesIdentifier:[NSString stringWithFormat:@"%@-%@",
										   activeStyle, preferenceGroup]];
		
		//Get the prefered variant (or the default if a prefered is not available)
		NSString *activeVariant;
		activeVariant = [adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"Variant" forStyle:activeStyle]
															   group:preferenceGroup];
		if (!activeVariant || ![[messageStyle availableVariants] containsObject:activeVariant])
			activeVariant = [messageStyle defaultVariant];
		if (!activeVariant || ![[messageStyle availableVariants] containsObject:activeVariant]) {
			/* If the message style doesn't specify a default variant, choose the first one.
			 * Note: Old styles (styleVersion < 3) will always report a variant for defaultVariant.
			 */
			NSArray *availableVariants = [messageStyle availableVariants];
			if ([availableVariants count]) {
				activeVariant = [availableVariants objectAtIndex:0];
			}
		}
		messageStyle.activeVariant = activeVariant;
		
		NSDictionary *prefDict = [adium.preferenceController preferencesForGroup:preferenceGroup];
		
		//Update message style behavior: XXX move this somewhere not per-chat
		[messageStyle setShowUserIcons:[[prefDict objectForKey:KEY_WEBKIT_SHOW_USER_ICONS] boolValue]];
		[messageStyle setShowHeader:[[prefDict objectForKey:KEY_WEBKIT_SHOW_HEADER] boolValue]];
		[messageStyle setUseCustomNameFormat:[[prefDict objectForKey:KEY_WEBKIT_USE_NAME_FORMAT] boolValue]];
		[messageStyle setNameFormat:[[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] intValue]];
		[messageStyle setDateFormat:[prefDict objectForKey:KEY_WEBKIT_TIME_STAMP_FORMAT]];
		[messageStyle setShowIncomingMessageColors:[[prefDict objectForKey:KEY_WEBKIT_SHOW_MESSAGE_COLORS] boolValue]];
		[messageStyle setShowIncomingMessageFonts:[[prefDict objectForKey:KEY_WEBKIT_SHOW_MESSAGE_FONTS] boolValue]];
		
		//Custom background image
		//Webkit wants to load these from disk, but we have it stuffed in a plist.  So we'll write it out as an image
		//into the cache and have webkit fetch from there.
		NSString	*cachePath = nil;
		if ([[adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"UseCustomBackground" forStyle:activeStyle]
													group:preferenceGroup] boolValue]) {
			cachePath = [adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]
															   group:preferenceGroup];
			if (!cachePath || ![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
				NSData	*backgroundImage = [adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"Background" forStyle:activeStyle]
																				 group:PREF_GROUP_WEBKIT_BACKGROUND_IMAGES];
				
				if (backgroundImage) {
					//Generate a unique cache ID for this image
					NSInteger	uniqueID = [[adium.preferenceController preferenceForKey:@"BackgroundCacheUniqueID"
																				 group:preferenceGroup] integerValue] + 1;
					[adium.preferenceController setPreference:[NSNumber numberWithInteger:uniqueID]
													   forKey:@"BackgroundCacheUniqueID"
														group:preferenceGroup];
					
					//Cache the image under that unique ID
					//Since we prefix the filename with TEMP, Adium will automatically clean it up on quit
					cachePath = [self _webKitBackgroundImagePathForUniqueID:uniqueID];
					[backgroundImage writeToFile:cachePath atomically:YES];
					
					//Remember where we cached it
					[adium.preferenceController setPreference:cachePath
													   forKey:[plugin styleSpecificKey:@"BackgroundCachePath" forStyle:activeStyle]
														group:preferenceGroup];
				} else {
					cachePath = @""; //No custom image found
				}
			}
			
			[messageStyle setCustomBackgroundColor:[[adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"BackgroundColor" forStyle:activeStyle]
																						   group:preferenceGroup] representedColor]];
		} else {
			[messageStyle setCustomBackgroundColor:nil];
		}
		
		[messageStyle setCustomBackgroundPath:cachePath];
		[messageStyle setCustomBackgroundType:[[adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"BackgroundType" forStyle:activeStyle]
																					  group:preferenceGroup] intValue]];
		
		BOOL isBackgroundTransparent = [[self messageStyle] isBackgroundTransparent];
		[webView setTransparent:isBackgroundTransparent];
		NSWindow *win = [webView window];
		if(win)
			[win setOpaque:!isBackgroundTransparent];
		
		//Update webview font settings
		NSString	*fontFamily = [adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"FontFamily" forStyle:activeStyle]
																	  group:preferenceGroup];
		[webView setFontFamily:(fontFamily ? fontFamily : [messageStyle defaultFontFamily])];
		
		NSNumber	*fontSize = [adium.preferenceController preferenceForKey:[plugin styleSpecificKey:@"FontSize" forStyle:activeStyle]
																	group:preferenceGroup];
		[[webView preferences] setDefaultFontSize:[(fontSize ? fontSize : [messageStyle defaultFontSize]) intValue]];
		
		NSNumber	*minSize = [adium.preferenceController preferenceForKey:KEY_WEBKIT_MIN_FONT_SIZE
																   group:preferenceGroup];
		[[webView preferences] setMinimumFontSize:(minSize ? [minSize intValue] : 1)];
		[[webView preferences] setMinimumLogicalFontSize:(minSize ? [minSize intValue] : 1)];
		
		//Update our icons before doing any loading
		[self sourceOrDestinationChanged:nil];
		
		//Prime the webview with the new style/variant and settings, and re-insert all our content back into the view
		[self _primeWebViewAndReprocessContent:YES];
		[pool release];
		isUpdatingWebViewForCurrentPreferences = NO;
	});
}

/*!
 * @brief Updates our webview to the currently active varient without refreshing the view
 */
- (void)_updateVariantWithoutPrimingView
{
	//We can only change the variant if the web view is ready.  If it's not ready we wait a bit and try again.
	if (webViewIsReady) {
		[webView stringByEvaluatingJavaScriptFromString:[messageStyle scriptForChangingVariant]];			
	} else {
		[self performSelector:@selector(_updateVariantWithoutPrimingView) withObject:nil afterDelay:NEW_CONTENT_RETRY_DELAY];
	}
}

/*!
 *	@brief Clears the view from displayed messages
 *
 *	Implements the method defined in protocol AIMessageDisplayController
 */
- (void)clearView
{
	[self _primeWebViewAndReprocessContent:NO];
	[self.markedScroller removeAllMarks];
	[previousContent release];
	previousContent = nil;
	nextMessageFocus = NO;
	nextMessageRegainedFocus = NO;
	[chat clearUnviewedContentCount];
}

/*!
 * @brief Primes our webview to the currently active style and variant
 *
 * The webview won't be ready right away, so we flag it as not ready and set ourself as the frame load delegate so
 * it will let us know when it's good to go.  If reprocessContent is NO, all content in the view will be lost.
 */
- (void)_primeWebViewAndReprocessContent:(BOOL)reprocessContent
{
	webViewIsReady = NO;

	//Hack: this will re-set us for all the delegates, but that shouldn't matter
	[delegateProxy addDelegate:self forView:webView];
	
	// We need to pass a local URL to allow LocalStorage from the WebView.
	// The hostname-part determines the namespace, which we seperate per style.
	// The path-part may not end in a /, as directories don't get local permissions.
	NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"adium://%@/adium", [messageStyle.bundle bundleIdentifier]]];
	[[webView mainFrame] loadHTMLString:[messageStyle baseTemplateForChat:chat] baseURL:baseURL];

	if(chat.isGroupChat && ((AIGroupChat *)chat).supportsTopic) {
		// Force a topic update, so we set our topic appropriately.
		[self updateTopic];
	}
	
	if (reprocessContent) {
		NSArray	*currentContentQueue;
		
		//Keep the array of objects waiting to be added, if necessary, to append them after our currently displayed ones
		currentContentQueue = ([contentQueue count] ?
							   [contentQueue copy] :
							   nil);

		//Start from an empty content queue
		[contentQueue removeAllObjects];

		//Add our stored content objects to the content queue
		[contentQueue addObjectsFromArray:storedContentObjects];
		[storedContentObjects removeAllObjects];

		//Add the old content queue back in if necessary
		if (currentContentQueue) {
			[contentQueue addObjectsFromArray:currentContentQueue];
			[currentContentQueue release];
		}

		//We're still holding onto the previousContent from before, which is no longer accurate. Release it.
		[previousContent release]; previousContent = nil;
	}
}

/*!
 * @brief Sets the class 'groupchat' on the #Chat element, to allow styles to modify their appearance based on whether we're in a groupchat
 *
 * If/when we support transforming chats to/from groupchats we'll need to observe that and call this as appropriate
 */
- (void) setIsGroupChat:(BOOL) flag
{
	DOMHTMLElement *chatElement = (DOMHTMLElement *)[[webView mainFrameDocument] getElementById:@"Chat"];
	NSMutableString *chatClassName = [[[chatElement className] mutableCopy] autorelease];
	if (flag == NO)
		[chatClassName replaceOccurrencesOfString:@" groupchat"
									   withString:@""
										  options:NSLiteralSearch
											range:NSMakeRange(0, [chatClassName length])];
	else
		[chatClassName appendString:@" groupchat"];
	[chatElement setClassName:chatClassName];
}

// Set document is ready (DOM ready)
- (void)_setDocumentReady
{
	documentIsReady = YES;
}

//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content
/*!
 * @brief Append new content to our processing queue
 */
- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentObject	*contentObject = [[notification userInfo] objectForKey:@"AIContentObject"];
	[self enqueueContentObject:contentObject];
}

- (void)enqueueContentObject:(AIContentObject *)contentObject
{
	[contentQueue addObject:contentObject];
	
	/* Immediately update our display if the content requires it.
	* This is NO, for example, when we receive an entire block of message history content so that we can avoid scrolling
	* after each one.
	*/
	if ([contentObject displayContentImmediately]) {
		[self processQueuedContent];
	}
}

/*!
 * @brief Our chat finished adding untracked content
 */
- (void)chatDidFinishAddingUntrackedContent:(NSNotification *)notification
{
	[self processQueuedContent];	
}

/*!
 * @brief Append new content to our processing queueProcess any content in the queuee
 */
- (void)processQueuedContent
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		/* If the webview isn't ready, assume we have at least one piece of content left to display */
		NSUInteger	contentQueueCount = 1;
		NSUInteger	objectsAdded = 0;
		
		if (webViewIsReady && documentIsReady) {
			contentQueueCount = contentQueue.count;
			
			while (contentQueueCount > 0) {
				BOOL willAddMoreContent = (contentQueueCount > 1);
				
				//Display the content
				AIContentObject *content = [contentQueue objectAtIndex:0];
				[self _processContentObject:content 
				  willAddMoreContentObjects:willAddMoreContent];
				
				//If we are going to reflect preference changes, store this content object
				if (shouldReflectPreferenceChanges) {
					[storedContentObjects addObject:content];
				}
				
				//Remove the content we just displayed from the queue
				[contentQueue removeObjectAtIndex:0];
				objectsAdded++;
				contentQueueCount--;
			}
		}
		
		/* If we added two or more objects, we may want to scroll to the bottom now, having not done it as each object
		 * was added.
		 */
		if (objectsAdded > 1) {
			NSString	*scrollToBottomScript = [messageStyle scriptForScrollingAfterAddingMultipleContentObjects];
			
			if (scrollToBottomScript) {
				[webView stringByEvaluatingJavaScriptFromString:scrollToBottomScript];
			}
		}
		
		//If there is still content to process (the webview wasn't ready), we'll try again after a brief delay
		if (contentQueueCount) {
			double delayInSeconds = NEW_CONTENT_RETRY_DELAY;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				[self processQueuedContent];
			});
		}
		[pool release];
	});
}

/*!
 * @brief Process and then append a content object
 */
- (void)_processContentObject:(AIContentObject *)content willAddMoreContentObjects:(BOOL)willAddMoreContentObjects
{
	AIContentEvent	*dateSeparator = nil;
	BOOL			replaceLastContent = NO;

	/*
	 If the day has changed since our last message (or if there was no previous message and 
	 we are about to display context), insert a date line.
	 */
	if ((!previousContent && [content isKindOfClass:[AIContentContext class]]) ||
	   (![content isFromSameDayAsContent:previousContent])) {
		
		__block NSString *dateMessage;
		[NSDateFormatter withLocalizedDateFormatterPerform:^(NSDateFormatter *dateFormatter){
			dateMessage = [[dateFormatter stringFromDate:content.date] retain];
		}];
		[dateMessage autorelease];
		
		dateSeparator = [AIContentEvent statusInChat:content.chat
										  withSource:content.chat.listObject
										 destination:content.chat.account
												date:content.date
											 message:[[[NSAttributedString alloc] initWithString:dateMessage
																					  attributes:[adium.contentController defaultFormattingAttributes]] autorelease]
											withType:@"date_separator"];

		if ([content isKindOfClass:[AIContentContext class]])
			[dateSeparator addDisplayClass:@"history"];

		//Add the date header
		[self _appendContent:dateSeparator 
					 similar:NO
			willAddMoreContentObjects:YES
		  replaceLastContent:NO];
		[previousContent release]; previousContent = [dateSeparator retain];
	}
	
	BOOL similar = (previousContent && [content isSimilarToContent:previousContent] && ![content isKindOfClass:[ESFileTransfer class]]);
	if ([previousContent isKindOfClass:[AIContentStatus class]] && [content isKindOfClass:[AIContentStatus class]] &&
		[[(AIContentStatus *)previousContent coalescingKey] isEqualToString:[(AIContentStatus *)content coalescingKey]]) {
		similar = NO;
		replaceLastContent = YES;
	}

	if ([content.type isEqualToString:CONTENT_TOPIC_TYPE]) {
		DOMHTMLElement *topicElement = (DOMHTMLElement *)[[webView mainFrameDocument] getElementById:@"topic"];
		
		if (((AIContentTopic *)content).actuallyBlank) {
			content.message = [NSAttributedString stringWithString:@""];
		}
		
		[topicElement setTitle:content.message.string];
		
		[topicElement setInnerHTML:[messageStyle completedTemplateForContent:content similar:similar]];
	} else {
		// Mark the current location (the start of this element) if it's a mention.
		if (content.trackContent && [content.displayClasses containsObject:@"mention"]) {
			[self markCurrentLocation];
		}
		
		if (content.postProcessContent && adium.interfaceController.activeChat != content.chat) {
			if (nextMessageFocus) {
				[self.markedScroller addMarkAt:[self.currentOffsetHeight integerValue] withIdentifier:@"focus" withColor:[NSColor redColor]];
				
				// Add a class for "first content to lose focus" if this is a group chat
				if (content.chat.isGroupChat)
					[content addDisplayClass:@"firstFocus"];
				
				nextMessageFocus = NO;
				nextMessageRegainedFocus = YES;
			}

			// Add a class for "this content received while out of focus"
			if (content.chat.isGroupChat) {
				[content addDisplayClass:@"focus"];
				[content addDisplayClass:@"lastFocus"];
				
				// if there's something else already lastFocus, then unset it
				DOMNodeList *nodeList = [webView.mainFrameDocument querySelectorAll:@".lastFocus"];
				DOMHTMLElement *node = nil; NSMutableArray *classes = nil;
				for (unsigned i = 0; i < nodeList.length; i++)
				{
					node = (DOMHTMLElement *)[nodeList item:i];
					classes = [[node.className componentsSeparatedByString:@" "] mutableCopy];
					
					[classes removeObject:@"lastFocus"];
					
					node.className = [classes componentsJoinedByString:@" "];
					
					[classes release];
				}
			}
		}
		
		/* Only if the message is a group chat message that should be postprocessed, and it's in the active chat
		 * with something already focussed (!nextMessageFocus) and nothing already regainedFocussed
		 * (nextMessageRegainedFocus), _then_ this message will be regainedFocus.
		 */
		if (content.postProcessContent && content.chat.isGroupChat && adium.interfaceController.activeChat == content.chat
			&& !nextMessageFocus && nextMessageRegainedFocus) {
			
			nextMessageRegainedFocus = NO;
			[content addDisplayClass:@"regainedFocus"];
		}
		
		//Add the content object
		[self _appendContent:content 
					 similar:similar
   willAddMoreContentObjects:willAddMoreContentObjects
		  replaceLastContent:replaceLastContent];
	}

	[previousContent release]; previousContent = [content retain];
}

/*!
 * @brief Append a content object
 */
- (void)_appendContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects replaceLastContent:(BOOL)replaceLastContent
{
	[webView stringByEvaluatingJavaScriptFromString:[messageStyle scriptForAppendingContent:content
																					similar:contentIsSimilar
																  willAddMoreContentObjects:willAddMoreContentObjects
																		 replaceLastContent:replaceLastContent]];

	NSAccessibilityPostNotification(webView, NSAccessibilityValueChangedNotification);
}

#pragma mark Topics
/*!
 * @brief Force a topic update.
 *
 * We have to filter this ourself because, if the topic is blank, the content controller will never show it to us.
 */
- (void)updateTopic
{
	NSAttributedString *topic = [NSAttributedString stringWithString:([chat valueForProperty:KEY_TOPIC] ?: @"")];
	
	AIContentTopic *contentTopic = [AIContentTopic topicInChat:chat
													withSource:[(AIGroupChat *)chat contactForNick:[chat valueForProperty:KEY_TOPIC_SETTER]]
													sourceNick:[chat valueForProperty:KEY_TOPIC_SETTER]
												   destination:nil
														  date:[NSDate date]
													   message:topic];
	
	// In case this topic is blank, we have to filter this ourself; the content controller will drop it.
	contentTopic.message = [adium.contentController filterAttributedString:topic usingFilterType:AIFilterDisplay direction:AIFilterIncoming context:contentTopic];
	
	[self enqueueContentObject:contentTopic];
}

//WebView Delegates ----------------------------------------------------------------------------------------------------
#pragma mark Webview delegates

- (void)webViewIsReady{
	webViewIsReady = YES;
	[self setupMarkedScroller];
	[self setIsGroupChat:chat.isGroupChat];
	[self processQueuedContent];
	
	// force the window to redisplay, otherwise the shadow will not draw properly with transparent message views 
	NSWindow *win = [webView window];
	[win invalidateShadow];
	[win display];
}

- (void)openImage:(id)sender
{
	NSURL	*imageURL = [sender representedObject];
	[[NSWorkspace sharedWorkspace] openFile:[imageURL path]];
}

- (void)saveImageAs:(id)sender
{
	NSURL		*imageURL = [sender representedObject];
	NSString	*path = [imageURL path];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.nameFieldStringValue = [path lastPathComponent];
	[savePanel beginSheetModalForWindow:[webView window] completionHandler:^(NSInteger result) {
		if (result ==  NSFileHandlingPanelOKButton) {
			[[NSFileManager defaultManager] copyItemAtURL:imageURL
													toURL:savePanel.URL
													error:nil];
		}
	}];
}

/*!
 * @brief Search the selected text with DDG, similar to the Search with Google option that's included by default.
 */
- (void)searchDDG
{
	DOMRange *range = [webView selectedDOMRange];
	NSString *query = [[range toString] stringByAddingPercentEscapesForAllCharacters];
	
	if (query && query.length > 0) {
		NSURL *ddgURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://duckduckgo.com/?q=%@&t=adium", query]];
		[[NSWorkspace sharedWorkspace] openURL:ddgURL];
	}
}

/*!
 * @brief Append our own menu items to the webview's contextual menus
 */
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	NSMutableArray *webViewMenuItems = [[defaultMenuItems mutableCopy] autorelease];
	AIListContact	*chatListObject = chat.listObject.parentContact;
	NSMenuItem		*menuItem;

	//Remove default items we don't want
	if (webViewMenuItems) {

		for (menuItem in defaultMenuItems) {
			NSInteger tag = [menuItem tag];
			if ((tag == WebMenuItemTagOpenLinkInNewWindow) ||
				(tag == WebMenuItemTagDownloadLinkToDisk) ||
				(tag == WebMenuItemTagOpenImageInNewWindow) ||
				(tag == WebMenuItemTagDownloadImageToDisk) ||
				(tag == WebMenuItemTagOpenFrameInNewWindow) ||
				(tag == WebMenuItemTagStop) ||
				(tag == WebMenuItemTagReload)) {
				[webViewMenuItems removeObjectIdenticalTo:menuItem];
			} else {
				//This isn't as nice; there's no tag available. Use the localization from WebKit/WebCore, where it seems to be for some other people (#16101), to look at the title.
				if ([[menuItem title] isEqualToString:NSLocalizedStringFromTableInBundle(@"Open Link", nil, [NSBundle bundleForClass:[WebView class]], nil)] ||
					[[menuItem title] isEqualToString:NSLocalizedStringFromTableInBundle(@"Open Link", nil, [NSBundle bundleWithIdentifier:@"com.apple.WebCore"], nil)])
					[webViewMenuItems removeObjectIdenticalTo:menuItem];
			}
		}
	}
	
	NSURL	*imageURL;
	if ((imageURL = [element objectForKey:WebElementImageURLKey])) {
		//This is an image		
		if (!webViewMenuItems) {
			webViewMenuItems = [NSMutableArray array];
		}
		
		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Open Image", nil)
											  target:self
											  action:@selector(openImage:)
									   keyEquivalent:@""
								   representedObject:imageURL];
		[webViewMenuItems addObject:menuItem];
		[menuItem release];
		menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Save Image As", nil) stringByAppendingEllipsis]
											  target:self
											  action:@selector(saveImageAs:)
									   keyEquivalent:@""
								   representedObject:imageURL];
		[webViewMenuItems addObject:menuItem];
		[menuItem release];		
		
		/*
		NSString *imgClass = [img className];
		//being very careful to only get user icons... a better way would be to put a class "usericon" on the img, but I haven't worked out how to do that, so we test for the name of the person in the src, and that it's not an emoticon or direct connect image.
		if([[img getAttribute:@"src"] rangeOfString:internalObjectID].location != NSNotFound &&
		   [imgClass rangeOfString:@"emoticon"].location == NSNotFound &&
		   [imgClass rangeOfString:@"fullSizeImage"].location == NSNotFound &&
		   [imgClass rangeOfString:@"scaledToFitImage"].location == NSNotFound)
		 */
			
	}

	if (webViewMenuItems) {		
		//Add a separator item if items already exist in webViewMenuItems
		if ([webViewMenuItems count]) {
			// If the first item is a separator item, remove it.
			if ([[webViewMenuItems objectAtIndex:0] isSeparatorItem]) {
				[webViewMenuItems removeObjectAtIndex:0];
			}
			
			[webViewMenuItems addObject:[NSMenuItem separatorItem]];
		}
	} else {
		webViewMenuItems = [NSMutableArray array];
	}

	NSMenu *originalMenu = nil;
	
	if (chatListObject) {
		NSArray *locations;
		if ([chatListObject isIntentionallyNotAStranger]) {
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInteger:Context_Contact_Manage],
				[NSNumber numberWithInteger:Context_Contact_Action],
				[NSNumber numberWithInteger:Context_Contact_NegativeAction],
				[NSNumber numberWithInteger:Context_Contact_ChatAction],
				[NSNumber numberWithInteger:Context_Contact_Additions], nil];
		} else {
			locations = [NSArray arrayWithObjects:
				[NSNumber numberWithInteger:Context_Contact_Manage],
				[NSNumber numberWithInteger:Context_Contact_Action],
				[NSNumber numberWithInteger:Context_Contact_NegativeAction],
				[NSNumber numberWithInteger:Context_Contact_ChatAction],
				[NSNumber numberWithInteger:Context_Contact_Stranger_ChatAction],
				[NSNumber numberWithInteger:Context_Contact_Additions], nil];
		}
		
		originalMenu = [adium.menuController contextualMenuWithLocations:locations
														   forListObject:chatListObject
																  inChat:chat];
	} else if(chat.isGroupChat) {
		originalMenu = [adium.menuController contextualMenuWithLocations:[NSArray arrayWithObjects:
																		  [NSNumber numberWithInteger:Context_GroupChat_Manage],
																		  [NSNumber numberWithInteger:Context_GroupChat_Action], nil]
																 forChat:chat];
	}
	
	[webViewMenuItems addObjectsFromArray:originalMenu.itemArray];
	[originalMenu removeAllItems];

	if (webViewMenuItems.count > 0 && ![[webViewMenuItems objectAtIndex:webViewMenuItems.count-1] isSeparatorItem])
		[webViewMenuItems addObject:[NSMenuItem separatorItem]];

	//Present an option to clear the display
	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Clear Display", "Clears the display window for the currently open message window")
										  target:self
										  action:@selector(clearView)
								   keyEquivalent:@""];
	[webViewMenuItems addObject:menuItem];
	[menuItem release];
	
	for (NSMenuItem *searchItem in defaultMenuItems) {
		if ([searchItem tag] == WebMenuItemTagSearchWeb) {
			menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Search with DuckDuckGo", nil)
												  target:self
												  action:@selector(searchDDG)
										   keyEquivalent:@""];
			[webViewMenuItems insertObject:menuItem atIndex:[webViewMenuItems indexOfObject:searchItem] + 1];
			[menuItem release];
		}
	}
	
	return webViewMenuItems;
}

/*!
 * @brief Add ourself to the window script object bridge when it's safe to do so. Also injects custom javascript.
 */
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [[webView windowScriptObject] setValue:self forKey:@"client"];
	
	// Add an event listener for DOM ready and notify back our controller
	[[webView windowScriptObject] evaluateWebScript:@"document.addEventListener(\"DOMContentLoaded\", function() {window.client.$_setDocumentReady()}, false);"];
}

//Dragging delegate ----------------------------------------------------------------------------------------------------
#pragma mark Dragging delegate
/*!
 * @brief If possible, return the first NSTextView in the message view's responder chain
 *
 * This is used for drag and drop behavior.
 */
- (NSTextView *)textView
{
	id	responder = [webView nextResponder];
	
	//Walkin the responder chain looking for an NSTextView
	while (responder &&
		  ![responder isKindOfClass:[NSTextView class]]) {
		responder = [responder nextResponder];
	}
	
	return responder;
}

/*!
 * @brief Dragging entered
 */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];

	return ([pasteboard availableTypeFromArray:draggedTypes] ?
		   NSDragOperationCopy :
		   NSDragOperationNone);
}

/*!
* @brief Dragging updated
 */
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [self draggingEntered:sender];
}

/*!
 * @brief Handle a drag onto the webview
 * 
 * If we're getting a non-image file, we can handle it immediately.  Otherwise, the drag is the textView's problem.
 */
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	BOOL			success = NO;
	
	if ([self shouldHandleDragWithPasteboard:pasteboard]) {
		
		//Not an image but it is a file - send it immediately as a file transfer
		NSArray			*files = [pasteboard propertyListForType:NSFilenamesPboardType];
		NSString		*path;
		for (path in files) {
			AIListObject *listObject = chat.listObject;
			if (listObject) {
				[adium.fileTransferController sendFile:path toListContact:(AIListContact *)listObject];
			}
		}
		success = YES;
		
	} else {
		NSTextView *textView = [self textView];
		if (textView) {
			[[webView window] makeFirstResponder:textView]; //Make it first responder
			success = [textView performDragOperation:sender];
		}
	}
	
	return success;
}

/*!
 * @brief Pass on the prepareForDragOperation if it's not one we're handling in this class
 */
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	BOOL	success = YES;
	
	if (![self shouldHandleDragWithPasteboard:pasteboard]) {	
		NSTextView *textView = [self textView];
		if (textView) {
			success = [textView prepareForDragOperation:sender];
		}
	}
	
	return success;
}
	
/*!
 * @brief Pass on the concludeDragOperation if it's not one we're handling in this class
 */
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	
	if (![self shouldHandleDragWithPasteboard:pasteboard]) {
		NSTextView *textView = [self textView];
		if (textView) {
			[textView concludeDragOperation:sender];
		}
	}
}

/*!
 * @brief Handle drags of content we recognize
 */
- (BOOL)shouldHandleDragWithPasteboard:(NSPasteboard *)pasteboard
{
	/*
	return (![pasteboard availableTypeFromArray:[NSArray arrayWithObjects:NSTIFFPboardType,NSPDFPboardType,nil]] &&
			[pasteboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]);
	 */
	return NO;
}


//User Icon masking --------------------------------------------------------------------------------------------------
//We allow messaage styles to specify masks for user icons.  This could be user to round the corners of user icons 
//or other related effects.
#pragma mark User icon masking
/*!
 * @brief Update icon masks when participating list objects change
 *
 * We want to observe attributesChanged: notifications for all objects which are participating in our chat.
 * When the list changes, remove the observers we had in place before and add observers for each object in the list
 * so we never observe for contacts not in the chat.
 */
- (void)participatingListObjectsChanged:(NSNotification *)notification
{
	NSArray			*participatingListObjects = [chat containedObjects];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:ListObject_AttributesChanged
										object:nil];
	
	for (AIListObject *listObject in participatingListObjects) {
		//Update the mask for any user which just entered the chat
		if (![objectsWithUserIconsArray containsObjectIdenticalTo:listObject]) {
			[self updateUserIconForObject:listObject];
		}
		
		//In the future, watch for changes on the parent object, since that's the icon we display
		if ([listObject isKindOfClass:[AIListContact class]]) {
			[[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(listObjectAttributesChanged:) 
											   name:ListObject_AttributesChanged
											 object:[(AIListContact *)listObject parentContact]];
		}
	}
	
	//Also observe our account
	if (chat.account) {
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(listObjectAttributesChanged:) 
										   name:ListObject_AttributesChanged
										 object:chat.account];
	}

	//Remove the cache for any object no longer in the chat
	for (AIListObject *listObject in [[objectsWithUserIconsArray copy] autorelease]) {
		if ((![listObject isKindOfClass:[AIMetaContact class]] || (![participatingListObjects firstObjectCommonWithArray:[(AIMetaContact *)listObject containedObjects]])) &&
			(![listObject isKindOfClass:[AIListContact class]] || ![participatingListObjects containsObjectIdenticalTo:(AIListContact *)listObject]) &&
			!(listObject == chat.account)) {
			[self releaseCurrentWebKitUserIconForObject:listObject];
		}
	}
}

/*!
 * @brief Update icon masks when source or destination changes
 */
- (void)sourceOrDestinationChanged:(NSNotification *)notification
{
	//Update the participating contacts
	[self participatingListObjectsChanged:nil];
	
	//And update the source account
	[self updateUserIconForObject:chat.account];
	
	[self updateServiceIcon];
}

/*!
 * @brief Update the icon when a list object's icon attributes change
 */
- (void)listObjectAttributesChanged:(NSNotification *)notification
{
    AIListObject	*inObject = [notification object];
    NSSet			*keys = [[notification userInfo] objectForKey:@"Keys"];
	
	if ([keys containsObject:KEY_USER_ICON]) {
		if (inObject) {
			AIListObject	*actualObject = nil;
			AILogWithSignature(@"%@'s icon changed", inObject);
			if (chat.account == inObject) {
				//The account is the object actually in the chat
				actualObject = inObject;
			} else {
				/*
				 * We are notified of a change to the metacontact's icon. Find the contact inside the chat which we will
				 * be displaying as changed.
				 */
				
				for (AIListContact *participatingListObject in [chat containedObjects]) {
					if ([participatingListObject parentContact] == inObject) {
						actualObject = participatingListObject;
						break;
					}
				}
			}

			if (actualObject) {
				[self userIconForObjectDidChange:actualObject];
			}

		} else {
			AILogWithSignature(@"nil object's icon changed");
			//We don't know what changed, if anything, that is relevant to our chat. Update source and destination icons.
			[self sourceOrDestinationChanged:nil];
		}
	}
}

- (void)userIconForObjectDidChange:(AIListObject *)inObject
{
	AIListObject	*iconSourceObject = ([inObject isKindOfClass:[AIListContact class]] ?
										 [(AIListContact *)inObject parentContact] :
										 inObject);
	NSString		*currentIconPath = [objectIconPathDict objectForKey:iconSourceObject.internalObjectID];
	if (currentIconPath) {
		NSString	*objectsKnownIconPath = [iconSourceObject valueForProperty:KEY_WEBKIT_USER_ICON];
		if (objectsKnownIconPath &&
			[currentIconPath isEqualToString:objectsKnownIconPath]) {
			//We're the first one to get to this object!  We get to delete the old path and remove the reference to it
			[[NSFileManager defaultManager] removeItemAtPath:currentIconPath error:NULL];
			[iconSourceObject setValue:nil
						   forProperty:KEY_WEBKIT_USER_ICON
								notify:NotifyNever];
		} else {
			/* Some other instance beat us to the punch. The object's KEY_WEBKIT_USER_ICON is right, since it doesn't match our
			 * internally tracked path.
			 */
		}
	}
	
	[self updateUserIconForObject:iconSourceObject];
}

/*!
 * @brief Remove all references to *this* chat using cached icons for an object
 *
 * If this is the last chat utilizing the cached icon, it will be deleted.
 *
 * @param inObject The object
 */
- (void)releaseCurrentWebKitUserIconForObject:(AIListObject *)inObject
{
	AIListObject	*iconSourceObject = ([inObject isKindOfClass:[AIListContact class]] ?
										 [(AIListContact *)inObject parentContact] :
										 inObject);
	NSString		*path;
	
	NSInteger chatsUsingCachedIcon = [iconSourceObject integerValueForProperty:KEY_WEBKIT_CHATS_USING_CACHED_ICON];
	chatsUsingCachedIcon--;
	[iconSourceObject setValue:[NSNumber numberWithInteger:chatsUsingCachedIcon]
					   forProperty:KEY_WEBKIT_CHATS_USING_CACHED_ICON
					   notify:NotifyNever];
	[objectsWithUserIconsArray removeObjectIdenticalTo:iconSourceObject];

	if ((chatsUsingCachedIcon <= 0) &&
		(path = [iconSourceObject valueForProperty:KEY_WEBKIT_USER_ICON])) {
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
		[iconSourceObject setValue:nil
								   forProperty:KEY_WEBKIT_USER_ICON
								   notify:NotifyNever];
	}

	[objectIconPathDict removeObjectForKey:iconSourceObject.internalObjectID];
}

/*!
 * @brief Remove all references to *this* chat using cached icons for all involved objects
 */
- (void)releaseAllCachedIcons
{
	for (AIListObject *listObject in [[objectsWithUserIconsArray copy] autorelease]) {
		[self releaseCurrentWebKitUserIconForObject:listObject];
	}
}

/*!
 * @brief Generate an updated masked user icon for the passed list object
 */
- (void)updateUserIconForObject:(AIListObject *)inObject
{
	AIListObject		*iconSourceObject = ([inObject isKindOfClass:[AIListContact class]] ?
											 [(AIListContact *)inObject parentContact] :
											 inObject);
	NSImage				*userIcon;
	NSString			*oldWebKitUserIconPath = nil;
	NSString			*webKitUserIconPath = nil;
	NSImage				*webKitUserIcon;
	
	/*
	 * We probably already have a userIcon waiting for us, the active display icon; use that
	 * rather than loading one from disk.
	 */
	if (!(userIcon = [iconSourceObject userIcon])) {
		//If that's not the case, try using the UserIconPath
		NSString *userIconPath = [iconSourceObject valueForProperty:@"UserIconPath"];
		if (userIconPath)
			userIcon = [[[NSImage alloc] initWithContentsOfFile:userIconPath] autorelease];
	}

	if (userIcon) {
		if ([messageStyle userIconMask]) {
			//Apply the mask if the style has one
			AILogWithSignature(@"Masking %@'s icon", inObject);
			//XXX Using multiple styles at once, one of which has a user icon mask, would lead to odd behavior
			webKitUserIcon = [[[messageStyle userIconMask] copy] autorelease];
			[webKitUserIcon lockFocus];
			[userIcon drawInRect:NSMakeRect(0,0,[webKitUserIcon size].width,[webKitUserIcon size].height)
						fromRect:NSMakeRect(0,0,[userIcon size].width,[userIcon size].height)
					   operation:NSCompositeSourceIn
						fraction:1.0f];
			[webKitUserIcon unlockFocus];
		} else {
			//Otherwise, just use the icon as-is
			webKitUserIcon = userIcon;
		}

		oldWebKitUserIconPath = [objectIconPathDict objectForKey:iconSourceObject.internalObjectID];		
		webKitUserIconPath = [iconSourceObject valueForProperty:KEY_WEBKIT_USER_ICON];
		if (!webKitUserIconPath) {
			/* If the image doesn't know a path to use, write it out and set it.
			 *
			 * Writing the icon out is necessary for webkit to be able to use it; it also guarantees that there won't be
			 * any animation, which is good since animation in the message view is slow and annoying.
			 *
			 * Only write out the icon if the object doesn't already have one
			 */				
			webKitUserIconPath = [self _webKitUserIconPathForObject:iconSourceObject];
			if ([[webKitUserIcon PNGRepresentation] writeToFile:webKitUserIconPath
													 atomically:YES]) {
				[iconSourceObject setValue:webKitUserIconPath
										   forProperty:KEY_WEBKIT_USER_ICON
										   notify:NO];
			} else {
				AILogWithSignature(@"Warning: Could not write out icon to %@", webKitUserIconPath);
			}
		}

		
		AILogWithSignature(@"%@'s oldWebKitUserIconPath %@, webKitUserIconPath now %@", inObject, oldWebKitUserIconPath, webKitUserIconPath);

		//Make sure it's known that this user has been handled
		if (![objectsWithUserIconsArray containsObjectIdenticalTo:iconSourceObject]) {
			[objectsWithUserIconsArray addObject:iconSourceObject];

			//Keep track of this chat using the icon
			[iconSourceObject setValue:[NSNumber numberWithInteger:([iconSourceObject integerValueForProperty:KEY_WEBKIT_CHATS_USING_CACHED_ICON] + 1)]
									   forProperty:KEY_WEBKIT_CHATS_USING_CACHED_ICON
									   notify:NotifyNever];
		}
		
		if (!webKitUserIconPath) webKitUserIconPath = @"";

		/* We previously updated existing images with the below code.  There's a bug somewhere, and it results
		 * in images being replaced with unknown-image question marks sometimes... though new images work fine.
		 */
#if 0
		if ([webView mainFrameDocument]) {
			//Update existing images if the webView has loaded and has a main frame
			if (oldWebKitUserIconPath &&
				![oldWebKitUserIconPath isEqualToString:webKitUserIconPath]) {
				
				DOMNodeList  *images = [[webView mainFrameDocument] getElementsByTagName:@"img"];
				NSUInteger imagesCount = [images length];

				webKitUserIconPath = [[webKitUserIconPath copy] autorelease];

				for (unsigned i = 0; i < imagesCount; i++) {
					DOMHTMLImageElement *img = (DOMHTMLImageElement *)[images item:i];
					NSString *currentSrc = [img getAttribute:@"src"];
					if (currentSrc && ([currentSrc rangeOfString:oldWebKitUserIconPath].location != NSNotFound)) {
						[img setSrc:webKitUserIconPath];
					}
				}
			}
			
			[objectIconPathDict setObject:webKitUserIconPath
								   forKey:iconSourceObject.internalObjectID];
		} else {
			/* Otherwise, try to again in a moment. We've already done the heavy lifting
			 * such as writing out the icon, so it's cheap to recurse.
			 */			
			[self performSelector:@selector(updateUserIconForObject:)
					   withObject:inObject
					   afterDelay:1];
		}
#else
	[objectIconPathDict setObject:webKitUserIconPath
						   forKey:iconSourceObject.internalObjectID];
#endif
    }
}

- (void)updateServiceIcon
{
	DOMDocument *doc = [webView mainFrameDocument];
	DOMNodeList  *serviceIconImages = [doc getElementsByClassName:@"serviceIcon"];
	NSUInteger imagesCount = [serviceIconImages length];
	
	NSString *serviceIconPath = [AIServiceIcons pathForServiceIconForServiceID:chat.account.service.serviceID 
																type:AIServiceIconLarge];
	
	for (unsigned i = 0; i < imagesCount; i++) {
		DOMHTMLImageElement *img = (DOMHTMLImageElement *)[serviceIconImages item:i];
		[img setSrc:serviceIconPath];
	}	
}

- (void)customEmoticonUpdated:(NSNotification *)inNotification
{
	DOMNodeList  *images = [[webView mainFrameDocument] getElementsByTagName:@"img"];
	NSUInteger imagesCount = [images length];

	if (imagesCount > 0) {
		AIEmoticon	*emoticon = [[inNotification userInfo] objectForKey:@"AIEmoticon"];
		NSString	*textEquivalent = [[emoticon textEquivalents] objectAtIndex:0];
		NSString	*path = [emoticon path];
		NSSize		emoticonSize = [[emoticon image] size];
		BOOL		updatedImage = NO;
		path = [[NSURL fileURLWithPath:path] absoluteString];
		for (unsigned i = 0; i < imagesCount; i++) {
			DOMHTMLImageElement *img = (DOMHTMLImageElement *)[images item:i];
			
			if ([[img className] isEqualToString:@"emoticon"] &&
				[[img getAttribute:@"alt"] isEqualToString:textEquivalent]) {
				[img setSrc:path];
				[img setWidth:(int)emoticonSize.width];
				[img setHeight:(int)emoticonSize.height];
				updatedImage = YES;
			}
		}
		NSNumber *shouldScroll = [[webView windowScriptObject] callWebScriptMethod:@"nearBottom"
																	 withArguments:nil];
		if (!shouldScroll) shouldScroll = [NSNumber numberWithBool:NO];

		if (updatedImage) [[webView windowScriptObject] callWebScriptMethod:@"alignChat" 
															  withArguments:[NSArray arrayWithObject:shouldScroll]];
	}
}

/*!
 * @brief Returns the path the background image given a unique ID
 */
- (NSString *)_webKitBackgroundImagePathForUniqueID:(NSInteger)uniqueID
{
	NSString	*filename = [NSString stringWithFormat:@"%@-WebkitBGImage-%ld.png", TEMPORARY_FILE_PREFIX, (long)uniqueID];
	return [[adium cachesPath] stringByAppendingPathComponent:filename];
}

/*!
 * @brief Returns the path to the list object's masked user icon
 */
- (NSString *)_webKitUserIconPathForObject:(AIListObject *)inObject
{
	NSString	*filename = [NSString stringWithFormat:@"%@-%@%@.png", TEMPORARY_FILE_PREFIX, inObject.internalObjectID, [NSString randomStringOfLength:5]];
	return [[adium cachesPath] stringByAppendingPathComponent:filename];
}

#pragma mark File Transfer

- (void)handleAction:(NSString *)action forFileTransfer:(NSString *)fileTransferID
{
	ESFileTransfer *fileTransfer = [ESFileTransfer existingFileTransferWithID:fileTransferID];
	ESFileTransferRequestPromptController *tc = [fileTransfer fileTransferRequestPromptController];

	if (tc) {
		AIFileTransferAction a;
		if ([action isEqualToString:@"SaveAs"])
			a = AISaveFileAs;
		else if ([action isEqualToString:@"Cancel"]) 
			a = AICancel;
		else
			a = AISaveFile;
		
		[tc handleFileTransferAction:a];
	}
}

#pragma mark Topic editing
- (void)editingDidComplete:(DOMRange *)range
{
	DOMNode *node = range.startContainer;
	DOMHTMLElement *topicEdit = (DOMHTMLElement *)[[webView mainFrameDocument] getElementById:@"topicEdit"];
	
	NSString *topicChange = nil;
		
	if (node == topicEdit || node.parentNode == topicEdit) {
		topicChange = [[AIHTMLDecoder decodeHTML:[topicEdit innerHTML]] string];		
		
		NSTextView *textView = [self textView];
		if (textView) {
			[[webView window] makeFirstResponder:textView]; //Make it first responder
		}
		
		// Update the topic div in case the user doesn't have permission to change it.
		[self updateTopic];
		
		// Tell the chat to set the topic.
		[(AIGroupChat *)chat setTopic:topicChange];
	}
}

#pragma mark Marked Scroller
- (JVMarkedScroller *)markedScroller
{
	WebFrame *contentFrame = [webView.mainFrame findFrameNamed:@"_current"];
	NSScrollView *scrollView = contentFrame.frameView.documentView.enclosingScrollView;
	
	JVMarkedScroller *scroller = (JVMarkedScroller *)scrollView.verticalScroller;
	return ([scroller isKindOfClass:[JVMarkedScroller class]]) ? scroller : nil;
}

- (void)setupMarkedScroller
{
	WebFrame *contentFrame = [[webView mainFrame] findFrameNamed:@"_current"];
	NSScrollView *scrollView = [[[contentFrame frameView] documentView] enclosingScrollView];
	
	[scrollView setHasHorizontalScroller:NO];

	JVMarkedScroller *scroller = (JVMarkedScroller *)[scrollView verticalScroller];
	if( scroller && ! [scroller isMemberOfClass:[JVMarkedScroller class]] ) {
		NSRect scrollerFrame = [[scrollView verticalScroller] frame];
		NSScroller *oldScroller = scroller;
		scroller = [[[JVMarkedScroller alloc] initWithFrame:scrollerFrame] autorelease];
		[scroller setFloatValue:oldScroller.floatValue];
		[scroller setKnobProportion:oldScroller.knobProportion];
		[scrollView setVerticalScroller:scroller];
	}
}

- (NSNumber *)currentOffsetHeight
{
	// We use the body's height to determine our mark location.
	return [(DOMElement *)[(DOMHTMLDocument *)webView.mainFrameDocument body] valueForKey:@"scrollHeight"];
}

- (void)markCurrentLocation
{
	[self.markedScroller addMarkAt:[self.currentOffsetHeight integerValue]];
}

#define PREF_KEY_FOCUS_LINE	@"Draw Focus Lines"

- (void)markForFocusChange
{
	// We use the current Chat element's height to determine our mark location.
	[self.markedScroller removeMarkWithIdentifier:@"focus"];
	
	// The next message being inserted needs to add a mark.
	nextMessageFocus = YES;
	nextMessageRegainedFocus = NO;
	
	DOMNodeList *nodeList = [webView.mainFrameDocument querySelectorAll:@".focus"];
	DOMHTMLElement *node = nil; NSMutableArray *classes = nil;
	for (unsigned i = 0; i < nodeList.length; i++)
	{
		node = (DOMHTMLElement *)[nodeList item:i];
		classes = [[node.className componentsSeparatedByString:@" "] mutableCopy];
		
		[classes removeObject:@"focus"];
		[classes removeObject:@"firstFocus"];
		[classes removeObject:@"lastFocus"];
		
		node.className = [classes componentsJoinedByString:@" "];
		
		[classes release];
	}
	
	// Also remove .regainedFocus. By definition this should _not_ have class .focus too, so make a new list
	DOMNodeList *nodeListRegained = [webView.mainFrameDocument querySelectorAll:@".regainedFocus"];
	
	for (unsigned i = 0; i < nodeListRegained.length; i++)
	{
		node = (DOMHTMLElement *)[nodeListRegained item:i];
		classes = [[node.className componentsSeparatedByString:@" "] mutableCopy];
		
		[classes removeObject:@"regainedFocus"];
		
		node.className = [classes componentsJoinedByString:@" "];
		
		[classes release];
	}
	
}

- (void)addMark
{
	[self.markedScroller addMarkAt:[self.currentOffsetHeight integerValue] withColor:[NSColor greenColor]];
}

- (void)jumpToPreviousMark
{
	[self.markedScroller jumpToPreviousMark:nil];
}

- (BOOL)previousMarkExists
{
	return [self.markedScroller previousMarkExists];
}

- (void)jumpToNextMark
{
	[self.markedScroller jumpToNextMark:nil];	
}

- (BOOL)nextMarkExists
{
	return [self.markedScroller nextMarkExists];	
}

- (void)jumpToFocusMark
{
	[self.markedScroller jumpToFocusMark:nil];
}

- (BOOL)focusMarkExists
{
	return [self.markedScroller focusMarkExists];
}

#pragma mark JS Bridging
/*See http://developer.apple.com/documentation/AppleApplications/Conceptual/SafariJSProgTopics/Tasks/ObjCFromJavaScript.html#//apple_ref/doc/uid/30001215 for more information.
*/

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	if (
		sel_isEqual(aSelector, @selector(handleAction:forFileTransfer:)) ||
		sel_isEqual(aSelector, @selector(debugLog:)) ||
		sel_isEqual(aSelector, @selector(zoomImage:)) ||
		sel_isEqual(aSelector, @selector(_setDocumentReady))
	)
		return NO;
	
	return YES;
}

/*
 * This method returns the name to be used in the scripting environment for the selector specified by aSelector.
 * It is your responsibility to ensure that the returned name is unique to the script invoking this method.
 * If this method returns nil or you do not implement it, the default name for the selector will be constructed as follows:
 *
 * Any colon (:) in the Objective-C selector is replaced by an underscore (_).
 * Any underscore in the Objective-C selector is prefixed with a dollar sign ($).
 * Any dollar sign in the Objective-C selector is prefixed with another dollar sign.
 */
+ (NSString *)webScriptNameForSelector:(SEL)aSelector
{
	if (sel_isEqual(aSelector, @selector(handleAction:forFileTransfer:))) return @"handleFileTransfer";
	if (sel_isEqual(aSelector, @selector(debugLog:))) return @"debugLog";
	if (sel_isEqual(aSelector, @selector(zoomImage:))) return @"zoomImage";
	return @"";
}

- (BOOL)zoomImage:(DOMHTMLImageElement *)img
{
	NSMutableString *className = [[[img className] mutableCopy] autorelease];
	if ([className rangeOfString:@"fullSizeImage"].location != NSNotFound)
		[className replaceOccurrencesOfString:@"fullSizeImage"
								   withString:@"scaledToFitImage"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [className length])];
	else if ([className rangeOfString:@"scaledToFitImage"].location != NSNotFound)
		[className replaceOccurrencesOfString:@"scaledToFitImage"
								   withString:@"fullSizeImage"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [className length])];
	else 
		return NO;
	
	[img setClassName:className];
	[[webView windowScriptObject] callWebScriptMethod:@"alignChat" withArguments:[NSArray arrayWithObject:[NSNumber numberWithBool:YES]]];

	return YES;
}

- (void)debugLog:(NSString *)message { NSLog(@"%@", message); }

//gets the source of the html page, for debugging
- (NSString *)webviewSource
{
	return [(DOMHTMLHtmlElement *)[[[webView mainFrameDocument] getElementsByTagName:@"html"] item:0] outerHTML];
}

/*!
 * @brief Set the HTML content for the "Chat" area.
 */
- (void)setChatContentSource:(NSString *)source
{
	if (!webViewIsReady) {
		// If the webview isn't ready yet, wait a very short amount of time before trying again
		[self performSelector:@selector(setChatContentSource:)
				   withObject:source
				   afterDelay:0];
	} else {
		// Add the old "Chat" element to the window.
		[(DOMHTMLElement *)[[webView mainFrameDocument] getElementById:@"Chat"] setOuterHTML:source];

		NSString	*scrollToBottomScript;		
		if ((scrollToBottomScript = [messageStyle scriptForScrollingAfterAddingMultipleContentObjects])) {
			[webView stringByEvaluatingJavaScriptFromString:scrollToBottomScript];
		}
	}
}

/*!
 * @brief Get the HTML content for the "Chat" area.
 */
- (NSString *)chatContentSource
{
	return [(DOMHTMLElement *)[[webView mainFrameDocument] getElementById:@"Chat"] outerHTML];
}

/*!
 * @brief The unique name for this style of "content source"
 */
- (NSString *)contentSourceName
{
	return [[[messageStyle bundle] bundlePath] lastPathComponent];
}

@end
