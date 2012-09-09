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
// Thanks to GrowlTunes from the Growl project for demonstrating how to receive notifications when 
// the iTunes track changes.

#import "ESiTunesPlugin.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import "AIStatusController.h"
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/MVMenuButton.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIStatus.h>
#import <WebKit/WebKit.h>

#define STRING_TRIGGERS_MENU		AILocalizedString(@"Insert iTunes Token", "Label used for edit and contextual menus of iTunes triggers")
#define STRING_TRIGGERS_TOOLBAR		AILocalizedString(@"iTunes","Label for iTunes toolbar menu item.")
#define STRING_ALBUM				AILocalizedString(@"Album", "Album of current song")
#define STRING_ARTIST				AILocalizedString(@"Artist", "Artist of current song")
#define STRING_COMPOSER				AILocalizedString(@"Composer", "Composer of current song")
#define STRING_GENRE				AILocalizedString(@"Genre", "Genre of current song")
#define STRING_STATUS				AILocalizedString(@"Player State", "Playing-status of current song (e.g. paused, playing)")
#define STRING_TRACK				AILocalizedString(@"Track", "Track name of current song")
#define STRING_YEAR					AILocalizedString(@"Year", "Year of current song")
#define	STRING_STORE_URL			AILocalizedString(@"iTunes Music Store Link", "iTUnes Music Store link for current song")
#define STRING_MUSIC				AILocalizedString(@"Listening Status", "Listening status string (*is listening to XXX by YYY)")
#define STRING_CURRENT_TRACK		AILocalizedString(@"iTunes Status", "Current track information (Track - Artist)")

#pragma mark -

#define ITUNES_MINIMUM_VERSION		4.6f
#define ITUNES_STATUS_ID			-8000
#define ITUNES_ITMS_SEARCH_URL		@"itms://itunes.com/link?"

#pragma mark -

#define	KEY_ITUNES_PLAYING			@"Playing"
#define	KEY_ITUNES_PAUSED			@"Paused"
#define	KEY_ITUNES_STOPPED			@"Stopped"

#pragma mark -

@interface ESiTunesPlugin ()
- (NSMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)action representedObject:(id)representedObject kind:(KGiTunesPluginMenuItemKind)itemKind;
- (void)createiTunesCurrentTrackStatusState;
- (void)updateiTunesCurrentTrackFormat;
- (void)createiTunesToolbarItemWithPath:(NSString *)path;
- (void)createiTunesToolbarItemMenuItems:(NSMenu *)iTunesMenu;
- (NSMenu *)createTriggerMenu;
- (void)insertTriggerMenu;
- (void)insertStringIntoMessageEntryView:(NSString *)inString;
- (void)insertAttributedStringIntoMessageEntryView:(NSAttributedString *)inString;
- (void)loadiTunesCurrentInfoViaApplescript;

- (void)insertFilteredString:(id)sender;
- (void)filterAndInsertString:(NSString *)inString;
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context;
- (CGFloat)filterPriority;

- (void)fireUpdateiTunesInfo;
- (void)iTunesUpdate:(NSNotification *)aNotification;
- (void)currentTrackFormatDidChange:(NSNotification *)aNotification;
- (void)insertUnfilteredString:(id)sender;
- (void)insertiTMSLink;
- (void)gatherSelection;
- (void)bringiTunesToFront;
@end

/*!
 * @class ESiTunesPlugin
 * @brief Fiiltering component to provide triggers which are replaced by information from the current iTunes track
 */
@implementation ESiTunesPlugin

#pragma mark -
#pragma mark Accessor Methods

/*!
 * @brief Is iTunes stopped?
 */
- (BOOL)iTunesIsStopped
{
	//Get the info if we don't already have it
	if (!iTunesCurrentInfo) [self loadiTunesCurrentInfoViaApplescript];

	return iTunesIsStopped;
}

/*!
 * @brief Set if iTunes is stopped
 */
- (void)setiTunesIsStopped:(BOOL)yesOrNo
{
	iTunesIsStopped = yesOrNo;
}

/*!
* @brief Is iTunes paused?
 */
- (BOOL)iTunesIsPaused
{
	//Get the info if we don't already have it
	if (!iTunesCurrentInfo) [self loadiTunesCurrentInfoViaApplescript];
	
	return iTunesIsPaused;
}

/*!
 * @brief Set if iTunes is paused
 */
- (void)setiTunesIsPaused:(BOOL)yesOrNo
{
  iTunesIsPaused = yesOrNo;
}


/*!
 * @brief Get current iTunes info dictionary
 */
- (NSDictionary *)iTunesCurrentInfo
{
	return iTunesCurrentInfo;
}

/*!
 * @brief Store local copy of iTunes information
 * 
 * Retains new information, requests immediate content update and lets the plugin know what iTunes is doing.
 */
- (void)setiTunesCurrentInfo:(NSDictionary *)newInfo
{
 	if (newInfo != iTunesCurrentInfo) {
 		NSMutableDictionary *mutableNewInfo = [newInfo mutableCopy];

		//If we get a stream title, use that as the track name
		if ([mutableNewInfo objectForKey:KEY_ITUNES_STREAM_TITLE] && [(NSString *)[mutableNewInfo objectForKey:KEY_ITUNES_STREAM_TITLE] length])
			[mutableNewInfo setObject:[mutableNewInfo objectForKey:KEY_ITUNES_STREAM_TITLE]
							   forKey:KEY_ITUNES_NAME];

		for (NSString *key in newInfo) {
			//Some versions of iTunes may send numbers as numbers rather than strings. Change these to numbers for our use.
			id value = [newInfo objectForKey:key];
			if (![value isKindOfClass:[NSString class]]) {
				if ([value respondsToSelector:@selector(stringValue)]) {
					[mutableNewInfo setObject:[value stringValue]
									   forKey:key];
				} else {
					//A future version might send some other data entirely.  Drop it rather than having non-strings in the dict.
					[mutableNewInfo removeObjectForKey:key];
				}
			}
		}

		iTunesCurrentInfo = mutableNewInfo;
 		[self setiTunesIsStopped:[[iTunesCurrentInfo objectForKey:KEY_ITUNES_PLAYER_STATE]
								  isEqualToString:KEY_ITUNES_STOPPED]];
 		[self setiTunesIsPaused:[[iTunesCurrentInfo objectForKey:KEY_ITUNES_PLAYER_STATE]
								 isEqualToString:KEY_ITUNES_PAUSED]];

        //Cancel any requests we had to fire updates.
        [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(fireUpdateiTunesInfo) object:nil];
        //fire an iTunes update in three seconds.
        [self performSelector:@selector(fireUpdateiTunesInfo) withObject:nil afterDelay:3.0];
 	}
}

- (void)fireUpdateiTunesInfo
{
	/* First, note that the track changed; code elsewhere cares, promise. */
	[[NSNotificationCenter defaultCenter] postNotificationName:Adium_iTunesTrackChangedNotification object:iTunesCurrentInfo];

	/* Next, update any dynamic content which includes iTunes triggers, including the Now Playing status itself */
	[[NSNotificationCenter defaultCenter] postNotificationName:Adium_RequestImmediateDynamicContentUpdate object:nil];
}

#pragma mark -
#pragma mark Plugin Methods

/*!
 * @brief Install
 */
- (void)installPlugin
{
	NSString		*itunesPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.iTunes"];

	iTunesCurrentInfo = nil;

	//Only install our items if a copy of iTunes which meets the minimum requirements is found
	if ([[[NSBundle bundleWithPath:itunesPath] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] doubleValue] > ITUNES_MINIMUM_VERSION) {		
		//Perform substitutions on outgoing content
		[adium.contentController registerContentFilter:self
												ofType:AIFilterContent
											 direction:AIFilterOutgoing];	
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(iTunesUpdate:)
																name:@"com.apple.iTunes.playerInfo"
															  object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(currentTrackFormatDidChange:)
													 name:Adium_CurrentTrackFormatChangedNotification
												   object:nil];
		
		substitutionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			KEY_ITUNES_ALBUM, TRIGGER_ALBUM,
			KEY_ITUNES_ARTIST, TRIGGER_ARTIST,
			KEY_ITUNES_COMPOSER, TRIGGER_COMPOSER,
			KEY_ITUNES_GENRE, TRIGGER_GENRE,
			KEY_ITUNES_PLAYER_STATE, TRIGGER_STATUS,
			KEY_ITUNES_NAME, TRIGGER_TRACK,
			KEY_ITUNES_YEAR, TRIGGER_YEAR,
			KEY_ITUNES_STORE_URL, TRIGGER_STORE_URL,
			nil];
		
		//Update the format for "Current iTunes Track"
		[self updateiTunesCurrentTrackFormat];
		
		//Create the "Current iTunes Track" status item
		[self createiTunesCurrentTrackStatusState];
		
		//Create the toolbar item
		[self createiTunesToolbarItemWithPath:itunesPath];
		
		//Create the Edit > Insert and contextual menus
		[self insertTriggerMenu];
	}
}

/*!
 * @brief Uninstall
 */
- (void)uninstallPlugin
{
	[adium.contentController unregisterContentFilter:self];
}

#pragma mark -
#pragma mark AppleScript + iTunes methods

/*!
 * @brief Get current iTunes track info
 *
 * Execute an applescript located in the resources folder that obtains current iTunes track info and assembles the dictionary
 */
- (void)loadiTunesCurrentInfoViaApplescript
{
	/*
	 * 1. get a url pointing to the script in the resources folder
 	 * 2. prepare the script for execution
	 * 3. get results and create the dictionary based off it
	 */
	
	//get the path
	NSString				*path = [[NSBundle mainBundle] pathForResource:@"CurrentTunes" ofType:@"scpt"];
	NSURL					*pathURL = [NSURL fileURLWithPath:path];
	
	//create the script complete with an error dictionary
	NSDictionary			*errors = [NSDictionary dictionary];
	NSAppleScript			*playingScript = [[NSAppleScript alloc] initWithContentsOfURL:pathURL error:&errors];
	
	//execute the script and get the results as a string
    NSAppleEventDescriptor	*result = [playingScript executeAndReturnError:&errors];
	NSString				*concatenatediTunesData = [result stringValue];

	//if the player was playing when the script was executed
	if (concatenatediTunesData && ![concatenatediTunesData isEqualToString:@"None"]) {
		
		//get the expected number of entries in the dictionary
		NSUInteger infoCount = [substitutionDict count];
		//get the values for the current iTunes song from the string
		NSArray * iTunesValues = [concatenatediTunesData componentsSeparatedByString:@",$!$,"];
		
		//if the two are properly matched (which they always will be, but just in case)
		if ([iTunesValues count] == infoCount) {
			//create the dictionary
			[self setiTunesCurrentInfo:[NSDictionary dictionaryWithObjects:iTunesValues
																   forKeys:[NSArray arrayWithObjects:
																			KEY_ITUNES_ALBUM,
																			KEY_ITUNES_ARTIST,
																			KEY_ITUNES_COMPOSER,
																			KEY_ITUNES_GENRE,
																			KEY_ITUNES_PLAYER_STATE,
																			KEY_ITUNES_NAME,
																			KEY_ITUNES_YEAR,
																			KEY_ITUNES_STORE_URL,
																			nil]]];
		} else {
			NSLog(@"iTunesValues was %@ (%lu items), but I was expecting %lu. Perhaps CurrentTunes is not updated to match ESiTunesPlugin?",
				  iTunesValues, (unsigned long)[iTunesValues count], (unsigned long)infoCount);
		}
		
	} else {
		//create a dictionary saying that iTunes is stopped
		[self setiTunesCurrentInfo:[NSDictionary dictionaryWithObjectsAndKeys:KEY_ITUNES_STOPPED, KEY_ITUNES_PLAYER_STATE, nil]];
	}
	
}

#pragma mark -
#pragma mark Status item creation

/*!
 * @brief Create an available status state
 *
 * Create a Status which uses the current iTunes track data as it's message
 */
- (void)createiTunesCurrentTrackStatusState
{
	//create an iTunes status of state "Available" with default available status settings
	AIStatus		   *currentiTunesStatusState = [AIStatus statusOfType:AIAvailableStatusType];
	
	//set status attributes
	NSAttributedString *trackAndArtist = [NSAttributedString stringWithString:TRIGGER_CURRENT_TRACK];
	[currentiTunesStatusState setStatusMessage:trackAndArtist];
	[currentiTunesStatusState setTitle:STRING_CURRENT_TRACK];
	[currentiTunesStatusState setMutabilityType:AISecondaryLockedStatusState];
	[currentiTunesStatusState setUniqueStatusID:[NSNumber numberWithInteger:ITUNES_STATUS_ID]];
	[currentiTunesStatusState setSpecialStatusType:AINowPlayingSpecialStatusType];

	//give it to the AIStatusController
	[adium.statusController addStatusState:currentiTunesStatusState];
}

- (void)updateiTunesCurrentTrackFormat
{
	NSDictionary	*slashMusicDict = nil;
	NSDictionary	*conditionalArtistTrackDict = nil;
	NSString		*currentITunesTrackFormat = nil;
	
	slashMusicDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					  [NSString stringWithFormat:AILocalizedString(@"*is listening to %@ by %@*","Phrase sent in response to %_music.  The first %%@ is the track; the second %%@ is the artist."), TRIGGER_TRACK, TRIGGER_ARTIST],
					  KEY_ITUNES_PLAYING,
					  AILocalizedString(@"*is listening to nothing*","Phrase sent in response to %_music when nothing is playing."),
					  KEY_ITUNES_STOPPED,
					  nil];
	
	/* Provide flexibility with the %_iTunes substitution. By default, just store @"" for this key.
	 * But still not hardcoded to a particular format. This is done so that a default installation 
	 * doesn't have its format broken if the locale switches...
	 * since the format specifiers are themselves localized.
	 */
	currentITunesTrackFormat = [adium.preferenceController preferenceForKey:KEY_ITUNES_TRACK_FORMAT
																	  group:PREF_GROUP_STATUS_PREFERENCES];
	if (!currentITunesTrackFormat) {
		[adium.preferenceController setPreference:@""
										   forKey:KEY_ITUNES_TRACK_FORMAT
											group:PREF_GROUP_STATUS_PREFERENCES];
		currentITunesTrackFormat = @"";
	}
	
	if (![currentITunesTrackFormat length]) {
		currentITunesTrackFormat  = [NSString stringWithFormat:@"%@ - %@", TRIGGER_TRACK, TRIGGER_ARTIST];
	}
	
	conditionalArtistTrackDict = [[NSDictionary alloc] initWithObjectsAndKeys:
								  currentITunesTrackFormat,
								  KEY_ITUNES_PLAYING,
								  @"",
								  KEY_ITUNES_STOPPED,
								  nil];
	
	phraseSubstitutionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							  slashMusicDict,
							  TRIGGER_MUSIC,
							  conditionalArtistTrackDict,
							  TRIGGER_CURRENT_TRACK,
							  nil];

    [self fireUpdateiTunesInfo];
}

#pragma mark -
#pragma mark Filter Protocol methods

/*!
 * @brief Filter and insert current iTunes song display into message entry
 *
 * Toolbar method. Take the trigger and filter it with real values
 *
 * @param sender An NSMenuItem whose representedObject is the appropriate trigger to filter
 */
- (void)insertFilteredString:(id)sender
{
	[self filterAndInsertString:[sender representedObject]];	
}

/*!
 * @brief Filter messages for keywords to replace
 *
 * Replace any iTunes triggers with the appropriate information
 */
- (NSAttributedString *)filterAttributedString:(NSAttributedString *)inAttributedString context:(id)context
{
    NSMutableAttributedString	*filteredMessage = nil;
	NSString					*stringMessage;
	
	//get the attributed string as a regular string so we can do string processing
	if ((stringMessage = [inAttributedString string])) {
		BOOL			addStoreLinkAsSubtext = NO;
		
		/* Replace the phrases with the string containing the triggers.
		 * For example, /music will become *is listening to %_track by %_artist*.
		 * This will then become the actual track information in the next while().
		 */
		for (NSString *trigger in phraseSubstitutionDict) {
			//search for phrase in the string that needs to be filtered
			if (([stringMessage rangeOfString:trigger options:(NSLiteralSearch | NSCaseInsensitiveSearch)].location != NSNotFound)) {
				NSDictionary	*replacementDict;
				NSString		*replacement;
				
				//get the format for the current trigger
				replacementDict = [phraseSubstitutionDict objectForKey:trigger];
				
				//replacement of phrase should reflect iTunes player state
				if (![self iTunesIsStopped] && ![self iTunesIsPaused]) {
					replacement = [replacementDict objectForKey:KEY_ITUNES_PLAYING];

					/* If the trigger is the trigger used for the Current iTunes Track status, we'll want to add a subtext of the store link
					 * so account code can send it out later on.
					 */
					if ([trigger isEqualToString:TRIGGER_CURRENT_TRACK]) {
						addStoreLinkAsSubtext = YES;
					}
					
				} else {
					replacement = [replacementDict objectForKey:KEY_ITUNES_STOPPED];					
				}
				
				//create a attributedstring if it hasn't been created already
				if (!filteredMessage) filteredMessage = [inAttributedString mutableCopy];
				
				//Perform the replacement
				[filteredMessage replaceOccurrencesOfString:trigger
												 withString:replacement
													options:(NSLiteralSearch | NSCaseInsensitiveSearch)
													  range:NSMakeRange(0, [filteredMessage length])];
			}
		}
		
		if (filteredMessage) {
			//Update our string for the simple trigger replacement process so we can replace the %_ tokens
			stringMessage = [filteredMessage string];
		}
		
		//Substitute simple triggers as appropriate
		for (NSString *trigger in substitutionDict) {
			//Find if the current trigger is in the string
			if (([stringMessage rangeOfString:trigger options:(NSLiteralSearch | NSCaseInsensitiveSearch)].location != NSNotFound)) {
				//Get the info if we don't already have it
				if (!iTunesCurrentInfo) [self loadiTunesCurrentInfoViaApplescript];
				
				NSString *replacement = [iTunesCurrentInfo objectForKey:[substitutionDict objectForKey:trigger]];
				if (replacement == nil) {
					//If no replacement is found, replace the trigger with an empty string
					replacement = @"";
				}
				
				//if a mutable attributed string for the string to be filtered doesn't exist, create it. 
				if (filteredMessage == nil) {
					filteredMessage = [inAttributedString mutableCopy];	
				}
				
				//Replace the current trigger with the value we found above
				[filteredMessage replaceOccurrencesOfString:trigger
												 withString:replacement
													options:(NSLiteralSearch | NSCaseInsensitiveSearch)
													  range:NSMakeRange(0, [filteredMessage length])];
			}
		}
		
		if (addStoreLinkAsSubtext && filteredMessage) {
			NSString *storeLinkForSubtext = [iTunesCurrentInfo objectForKey:[substitutionDict objectForKey:TRIGGER_STORE_URL]];
			if (storeLinkForSubtext) {
				[filteredMessage addAttribute:@"AIMessageSubtext"
										value:storeLinkForSubtext
										range:NSMakeRange(0, [filteredMessage length])];
			}
		}
	}
	
	//Give back the processed string
	return (filteredMessage ? filteredMessage : inAttributedString);
}

/*!
 * @brief Filter priority
 *
 * Filter at default priority
 */
- (CGFloat)filterPriority
{
	return DEFAULT_FILTER_PRIORITY;
}

#pragma mark -
#pragma mark Notification Selector

/*!
 * @brief The iTunes song changed
 *
 * The accessor method caches the information and then requst an immediate update to dynamic content
 */
- (void)iTunesUpdate:(NSNotification *)aNotification
{
	@autoreleasepool {
		
		NSDictionary *newInfo = [aNotification userInfo];
		[self setiTunesCurrentInfo:newInfo];
		
	}
}

/*!
 * @brief The CurrentTrack format changed
 */
- (void)currentTrackFormatDidChange:(NSNotification *)aNotification
{
	[self updateiTunesCurrentTrackFormat];
}


#pragma mark -
#pragma mark Toolbar Item Methods

/*!
 * @brief Create the toolbar item
 *
 * Create toolbar item and it's menu
 */
- (void)createiTunesToolbarItemWithPath:(NSString *)iTunesPath
{
	NSMenu		  *menu = [[NSMenu alloc] init];
	MVMenuButton  *button = [[MVMenuButton alloc] initWithFrame:NSMakeRect(0,0,32,32)];

	//configure the popup button and its menu

	[button setImage:[[NSWorkspace sharedWorkspace] iconForFile:iTunesPath]];
	[self createiTunesToolbarItemMenuItems:menu];

	NSToolbarItem * iTunesItem = [AIToolbarUtilities toolbarItemWithIdentifier:KEY_TRIGGERS_TOOLBAR
																		 label:STRING_TRIGGERS_TOOLBAR
																  paletteLabel:STRING_TRIGGERS_TOOLBAR
																	   toolTip:AILocalizedString(@"Insert current iTunes track information.","Label for iTunes toolbar menu item.")
																		target:self
															   settingSelector:@selector(setView:)
																   itemContent:button
																		action:NULL
																		  menu:nil];
	//configure the toolbar and button for use
	[[iTunesItem view] setMenu:menu];
	[iTunesItem setMinSize:NSMakeSize(32,32)];
	[iTunesItem setMaxSize:NSMakeSize(32,32)];
	[button setToolbarItem:iTunesItem];
	
	//Add menu to toolbar item (for text mode)
	NSMenuItem	*mItem = [[NSMenuItem alloc] init];
	[mItem setSubmenu:menu];
	[mItem setTitle:STRING_TRIGGERS_TOOLBAR];
	[iTunesItem setMenuFormRepresentation:mItem];
	
	//give it to adium to use
	[adium.toolbarController registerToolbarItem:iTunesItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief Create the toolbar item's menu
 *
 * Populate a menu with menu items that will insert appropriate values of the currently playing iTunes song.
 */

- (void)createiTunesToolbarItemMenuItems:(NSMenu *)iTunesMenu
{	

	
	//submenu of actions related to a track
	NSMenuItem *submenuRoot = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Track Information","Submenu for iTunes toolbar item menu for inserting current track information.")
														 action:NULL
												  keyEquivalent:@""];
	[iTunesMenu addItem:submenuRoot];
	[iTunesMenu setSubmenu:[self createTriggerMenu] forItem:submenuRoot];
	[iTunesMenu addItem:[NSMenuItem separatorItem]];

	//this isn't implemented yet, need some advice on this one
	[iTunesMenu addItem:[self menuItemWithTitle:[AILocalizedString(@"Search Selection in Music Store","iTunes toolbar menu item title to search selection in iTMS.") stringByAppendingEllipsis]
										 action:@selector(gatherSelection)
							  representedObject:nil
										   kind:RESPONDER_IS_WEBVIEW]];
	[iTunesMenu addItem:[NSMenuItem separatorItem]];

	[iTunesMenu addItem:[self menuItemWithTitle:[AILocalizedString(@"Bring iTunes to Front","iTunes toolbar menu item title to make iTunes frontmost app.") stringByAppendingEllipsis]
										 action:@selector(bringiTunesToFront)
							  representedObject:nil
										   kind:ALWAYS_ENABLED]];
}

/*!
 * @brief Create a menu item
 *
 * create a menu item targeting this plugin. Determine if it should disable itself when firstResponder != [textView class].
 */
- (NSMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)action representedObject:(id)representedObject kind:(KGiTunesPluginMenuItemKind)itemKind
{
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
	[item setTarget:self];
	[item setTag:itemKind];
	[item setRepresentedObject:representedObject];
	[item setEnabled:YES];

	return item;
}

#pragma mark -
#pragma mark Toolbar Item actions

/*!
 * @brief Insert current song iTMS link
 *
 * Get the URL from the iTunesCurrentInfo dict or create a URL if one can't be found.
 */
- (void)insertiTMSLink
{
	NSMutableString		*url = [[NSMutableString alloc] init];
	NSString			*urlLabel = nil;

	//get current information
	NSString			*artist = [iTunesCurrentInfo objectForKey:[substitutionDict objectForKey:TRIGGER_ARTIST]];
	NSString			*trackName = [iTunesCurrentInfo objectForKey:[substitutionDict objectForKey:TRIGGER_TRACK]];
	
	//see if we have a URL for us
	NSString			*storeURL = [iTunesCurrentInfo objectForKey:[substitutionDict objectForKey:TRIGGER_STORE_URL]];
	if ([storeURL length]) {
		[url appendString:storeURL];
	}
	
	//if we have no url data from the iTunes notification to begin with - probably because we got the info using the applescript
	if (![url length]) {
		
		//if iTunes is playing or paused something
		if (![self iTunesIsStopped] || ![self iTunesIsPaused]) {
			[url appendString:ITUNES_ITMS_SEARCH_URL];
			
			//if there is a name given to this song put it in the url
			if ([trackName length]) {
				[url appendFormat:@"n=%@", [trackName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			} else {
				trackName = @"";
			}
			
			//if there is a name and an artist, we'll use both to refine our search
			if ([artist length] && [trackName length]) {
				//[url appendFormat:@"?artistTerm=%@", [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				[url appendFormat:@"&an=%@", [artist stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				
			} else if ([artist length]) {
				//no proper track name but we have a decent artist name to include in the url
				//[url appendFormat:@"artistTerm=%@", [trackName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
				[url appendFormat:@"an=%@", [trackName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			} else {
				artist = @"";
			}
		}
	}
	
	//if something has been added to our search request, create a lovely label for it
	if (![url isEqualToString:ITUNES_ITMS_SEARCH_URL] && [url length]) {
		urlLabel = [[NSString alloc] initWithFormat:@"%@ - %@", trackName, artist];
	} else {
		url = nil;
	}
	
	//if we have a url, give it to the user as a nice, formatted <a> tag
	if (url) {
		NSAttributedString *attributedLink = [[NSAttributedString alloc] initWithAttributedString:[AIHTMLDecoder decodeHTML:[NSString stringWithFormat:@"<A HREF=\"%@\">%@</A>", url, urlLabel]]];
		[self insertAttributedStringIntoMessageEntryView:attributedLink];
	} else {
		//the artist name and or the track name is literally @""
		NSBeep();
	}
}

/*!
 * @brief Search iTMS for inputtted data
 *
 * Build the necessary url and execute it
 */
- (void)searchMusicStoreWithSelection:(NSString *)selectedText
{
	//Create a general search request
	NSString *url = [NSString stringWithFormat:@"itms://phobos.apple.com/WebObjects/MZSearch.woa/wa/search?term=%@", [selectedText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}


/*!
 * @brief Get the selection from the webmessageview
 *
 * Get the selected text in the messageview and run it thru the iTMS
 */
- (void)gatherSelection
{
	id responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	[self searchMusicStoreWithSelection:[responder selectedString]];
}

/*!
 * @brief Bring iTunes to foreground
 */
- (void)bringiTunesToFront
{
	[[NSWorkspace sharedWorkspace] launchApplication:@"iTunes"];
}

#pragma mark -
#pragma mark Edit/Contextual menu item actions

/*!
 * @brief Insert triggers into message entry
 *
 * Used in the "Edit" and contextual menus.
 * @param sender An NSMenuItem whose representedObject is the appropriate trigger to insert
 */
- (void)insertUnfilteredString:(id)sender
{
	[self insertStringIntoMessageEntryView:[sender representedObject]];
}

#pragma mark -
#pragma mark Text Insertion methods

/*!
 * @brief Filter and Insert plain string
 *
 * Converts the string to an attributed string and filters it, then inserting it into the message entry view
 * Used by all the toolbar item actions.
 */
- (void)filterAndInsertString:(NSString *)inString
{
	id responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	if (responder && [responder isKindOfClass:[NSTextView class]]) {
		NSAttributedString *attributedResult = [[NSAttributedString alloc] initWithString:inString
																			   attributes:[(NSTextView *)responder typingAttributes]];
		NSAttributedString *filteredString = [self filterAttributedString:attributedResult context:nil];
		
		if (filteredString && [filteredString length] > 0) {
			[self insertAttributedStringIntoMessageEntryView:filteredString];
		}
	}
}

/*!
 * @brief Insert raw string into message view
 *
 * Converts the string to an attributed string and inserts it into the message entry view.
 * Used with the insertUnfiltered... methods which are used by edit and contextual menus.
 */
- (void)insertStringIntoMessageEntryView:(NSString *)inString
{
	id responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	if (responder && [responder isKindOfClass:[NSTextView class]]) {
		NSAttributedString *attributedResult = [[NSAttributedString alloc] initWithString:inString 
																			   attributes:[(NSTextView *)responder typingAttributes]];
		[self insertAttributedStringIntoMessageEntryView:attributedResult];
	}
}

/*!
 * @brief Insert attributed string into message view
 *
 * Inserts an attributed string it into the message entry view.
 * Don't check to see if the responder is of class NSTextView because the validateMenuItem method checks.
 */

- (void)insertAttributedStringIntoMessageEntryView:(NSAttributedString *)inString
{
	NSResponder *textView = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	[textView insertText:inString];
	
	if (![inString length]) {
		NSBeep();
	}
}

#pragma mark -
#pragma mark Edit/Contextual menu methods

/*!
 * @brief Create Edit and Contextual menus of iTunes triggers
 *
 * Build the menus for the iTunes triggers that autodisables when a first responder isn't a textView
 */

- (NSMenu *)createTriggerMenu
{
	NSMenu *triggersMenu = [[NSMenu alloc] init];

	[triggersMenu addItem:[self menuItemWithTitle:STRING_CURRENT_TRACK 
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_CURRENT_TRACK
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_MUSIC
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_MUSIC
											 kind:AUTODISABLES]];

	[triggersMenu addItem:[NSMenuItem separatorItem]];
	
	[triggersMenu addItem:[self menuItemWithTitle:STRING_TRACK
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_TRACK
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_ARTIST
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_ARTIST
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_COMPOSER
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_COMPOSER
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_ALBUM
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_ALBUM
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_GENRE
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_GENRE
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_YEAR
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_YEAR
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_STATUS
										   action:@selector(insertUnfilteredString:)
								representedObject:TRIGGER_STATUS
											 kind:AUTODISABLES]];
	[triggersMenu addItem:[self menuItemWithTitle:STRING_STORE_URL
										   action:@selector(insertiTMSLink)
								representedObject:TRIGGER_STORE_URL
											 kind:AUTODISABLES]];
	
	return triggersMenu;
}

/*!
 * @brief Create Edit and Contextual menus of iTunes triggers
 *
 * Users can then insert %_&lt;token name&gt; into any text view
 */
- (void)insertTriggerMenu
{
	NSMenuItem	*menuItem = [[NSMenuItem alloc] initWithTitle:STRING_TRIGGERS_MENU target:self action:NULL keyEquivalent:@""];
	NSMenu		*menuOfTriggers = [self createTriggerMenu];
	
	[menuItem setSubmenu:menuOfTriggers];
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Edit_Additions];
	
	menuItem = [[NSMenuItem alloc] initWithTitle:STRING_TRIGGERS_MENU target:self action:NULL keyEquivalent:@""];
	[menuItem setSubmenu:[menuOfTriggers copy]];
	[adium.menuController addContextualMenuItem:menuItem toLocation:Context_TextView_Edit];
}

/*!
 * @brief Configure accessibility of menu items
 *
 * Depending on whether the responder is a textview and if it should be enabled when itunes isn't playing
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSResponder					*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	KGiTunesPluginMenuItemKind	tag = (KGiTunesPluginMenuItemKind)[menuItem tag];
	BOOL						enable;

	//we only insert things into textviews
	if (responder && [responder isKindOfClass:[NSTextView class]]) {
		
		//some menu items are only enabled if itunes is playing something
		if ((([self iTunesIsStopped] || [self iTunesIsPaused]) && (tag == ENABLED_IF_ITUNES_PLAYING)) || (tag == RESPONDER_IS_WEBVIEW)) {
			enable = NO;
		} else {
			enable = [(NSTextView *)responder isEditable];
		}

	} else if (tag == RESPONDER_IS_WEBVIEW) {
		
		if ([responder respondsToSelector:@selector(selectedString)]) {
			NSString	*selectedString = [(id)responder selectedString];
			
			if (selectedString && [selectedString length]) {
				enable = YES;
			} else {
				enable = NO;
			}

		} else {
			enable = NO;			
		}
		
	} else {
		// enable it if it is always supposed to be on, disable if otherwise
		enable = (tag == ALWAYS_ENABLED);
	}
	
	return enable;
}


#pragma mark -
#pragma mark Deallocation

- (void)dealloc
{
	//Remove self from notifications list
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	//Release class variables
	
}

@end
