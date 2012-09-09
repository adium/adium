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

#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIWebKitMessageViewController.h"
#import "AIWebKitMessageViewPlugin.h"
#import "ESWebKitMessageViewPreferences.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIBundleAdditions.h>
#import "AIWebkitMessageViewStyle.h"
#import <Adium/AIChat.h>
#import <AIUtilities/AIStringAdditions.h>

#define NEW_CONTENT_RETRY_DELAY					0.01
#define MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT @"Message Styles"

@interface AIWebKitMessageViewPlugin ()
- (void) resetStylesForType:(AIWebkitStyleType)styleType;
- (void) xtrasChanged:(NSNotification *)notification;
- (void)clearHardcodedBuiltInStylePaths;
- (void)performAdium14PreferenceUpdates;
@end

@implementation AIWebKitMessageViewPlugin

/*!
 * @brief Install plugin
 */
- (void)installPlugin
{
	styleDictionary = nil;
	[adium createResourcePathForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT];
	
	/* If this isn't done, Bad Things happen, so check it each launch (cheap!) in case the user reverted to a 
	 * pre-Adium 1.4 version. This check can be removed ~Adium 1.6.
	 */
	[self clearHardcodedBuiltInStylePaths];
	
	[self performAdium14PreferenceUpdates];
	
	//Setup our preferences
	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];

	[adium.preferenceController registerDefaults:[NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]]
										forGroup:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY];

	preferences = (ESWebKitMessageViewPreferences *)[ESWebKitMessageViewPreferences preferencePaneForPlugin:self];

	//Observe for installation of new styles
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:AIXtrasDidChangeNotification
									 object:nil];

	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY];

	//Register ourself as a message view plugin
	[adium.interfaceController registerMessageDisplayPlugin:self];
}

- (void) uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	[adium.interfaceController unregisterMessageDisplayPlugin:self];
	[adium.preferenceController removePreferencePane:preferences];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	styleDictionary = nil;
	preferences = nil;
	currentRegularStyle = nil;
	currentGroupStyle = nil;
	lastStyleLoadDate = nil;
	[super uninstallPlugin];
}

- (id <AIMessageDisplayController>)messageDisplayControllerForChat:(AIChat *)inChat
{
    return [AIWebKitMessageViewController messageDisplayControllerForChat:inChat withPlugin:self];
}

- (void)preferencesChangedForGroup:(NSString *)group
							   key:(NSString *)key
							object:(AIListObject *)object
					preferenceDict:(NSDictionary *)prefDict
						 firstTime:(BOOL)firstTime
{
	if([key isEqualToString:KEY_WEBKIT_STYLE]) {
		if([group isEqualToString:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY]) {
			[self resetStylesForType:AIWebkitRegularChat];
		} else {
			[self resetStylesForType:AIWebkitGroupChat];
		}
	}

	if ([group isEqualToString:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY]) {
		useRegularForGroupChat = [[prefDict objectForKey:KEY_WEBKIT_USE_REGULAR_PREFERENCES] boolValue];
	}
}

- (NSDictionary *)availableMessageStyles
{
	if (!styleDictionary) {
		NSArray			*stylesArray = [adium allResourcesForName:MESSAGE_STYLES_SUBFOLDER_OF_APP_SUPPORT
												   withExtensions:@"AdiumMessageStyle"];
		NSBundle		*style;
		NSString		*resourcePath;

		//Clear the current dictionary of styles and ready a new mutable dictionary
		styleDictionary = [[NSMutableDictionary alloc] init];

		//Get all resource paths to search
		for (resourcePath in stylesArray) {
			if ((style = [NSBundle bundleWithPath:resourcePath])) {
				NSString	*styleIdentifier = [style bundleIdentifier];
				if (styleIdentifier && [styleIdentifier length]) {
					[styleDictionary setObject:style forKey:styleIdentifier];
				}
			}
		}

		NSAssert([styleDictionary count] > 0, @"No message styles available"); //Abort if we have no message styles
	}

	return [NSDictionary dictionaryWithDictionary:styleDictionary]; //returning mutable private variables == nuh uh
}

- (NSBundle *)defaultMessageStyleBundleBasedOnFailedIdentifier:(NSString *)identifier
{
	NSDictionary *styles = [self availableMessageStyles];
	NSBundle	 *defaultMessageStyleBundle = nil;

	if (!defaultMessageStyleBundle) {
		defaultMessageStyleBundle = [styles objectForKey:KEY_WEBKIT_STYLE];
	}

	if (!defaultMessageStyleBundle) {
		defaultMessageStyleBundle = [[styles allValues] lastObject];
	}

	return defaultMessageStyleBundle;
}

- (NSBundle *)messageStyleBundleWithIdentifier:(NSString *)identifier
{
	NSDictionary	*styles = [self availableMessageStyles];
	NSBundle		*bundle = [styles objectForKey:identifier];

	//If the style isn't available, use our default.  Or, failing that, any available style
	if (!bundle) {
		bundle = [self defaultMessageStyleBundleBasedOnFailedIdentifier:identifier];
	}

	return bundle;
}

- (AIWebkitMessageViewStyle *) currentMessageStyleForChat:(AIChat *)chat
{
	NSString *loadFromGroup = nil;
	AIWebkitMessageViewStyle * __strong *thisStyle = nil;

	if (!chat.isGroupChat || useRegularForGroupChat) {
		if (!currentRegularStyle) {
			loadFromGroup = PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY;
		}

		thisStyle = &currentRegularStyle;
	} else if (chat.isGroupChat) {
		if (!currentGroupStyle) {
			loadFromGroup = PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY;
		}

		thisStyle = &currentGroupStyle;
	}

	if(loadFromGroup && thisStyle) {
		id<AIPreferenceController> prefs = adium.preferenceController;

		/* We use the path directly, if possible, to avoid a relatively expensive search through multiple folders */
		*thisStyle = [AIWebkitMessageViewStyle messageViewStyleFromPath:[prefs preferenceForKey:KEY_CURRENT_WEBKIT_STYLE_PATH
																							group:loadFromGroup]];
		if(!*thisStyle) {
			/* If the path isn't cached yet, load the style and then store the path */
			*thisStyle = [AIWebkitMessageViewStyle messageViewStyleFromBundle:
                          [self messageStyleBundleWithIdentifier:[prefs preferenceForKey:KEY_WEBKIT_STYLE
                                                                                   group:loadFromGroup]]];
            if (*thisStyle) {
                [prefs setPreference:[[[*thisStyle bundle] bundlePath] stringByCollapsingBundlePath]
                              forKey:KEY_CURRENT_WEBKIT_STYLE_PATH
                               group:loadFromGroup];
            } else {
                /* If the style failed to load, clear our preference to fall back to the default */
                /* XXX An error message could potentially be displayed here */
                [prefs setPreference:nil forKey:KEY_WEBKIT_STYLE group:loadFromGroup];
                
                *thisStyle = [AIWebkitMessageViewStyle messageViewStyleFromBundle:
                              [self messageStyleBundleWithIdentifier:[prefs preferenceForKey:KEY_WEBKIT_STYLE
                                                                                       group:loadFromGroup]]];
            }
		}
	}

	if (thisStyle) {
		NSDictionary *fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:[[*thisStyle bundle] bundlePath]
																		  error:NULL];
		NSDate *modDate = [fileAttrs objectForKey:NSFileModificationDate];
		if (lastStyleLoadDate && [modDate timeIntervalSinceDate:lastStyleLoadDate] > 0) {
			[currentGroupStyle reloadStyle];
			[currentRegularStyle reloadStyle];
		}
		lastStyleLoadDate = [NSDate date];
	} else {
		lastStyleLoadDate = nil;
	}

	return (thisStyle ? *thisStyle : nil);
}

- (void) resetStylesForType:(AIWebkitStyleType)styleType
{
	styleDictionary = nil;

	switch (styleType) {
		case AIWebkitRegularChat:
		{
			currentRegularStyle = nil;

			[adium.preferenceController setPreference:nil
											   forKey:KEY_CURRENT_WEBKIT_STYLE_PATH
												group:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];
			break;
		}
		case AIWebkitGroupChat:
		{
			currentGroupStyle = nil;

			[adium.preferenceController setPreference:nil
											   forKey:KEY_CURRENT_WEBKIT_STYLE_PATH
												group:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY];
		}
	}
}

/*!
 * @brief Rebuild our list of available styles when the installed xtras change
 */
- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:@"AdiumMessageStyle"] == NSOrderedSame) {
		[self resetStylesForType:AIWebkitRegularChat];
		[self resetStylesForType:AIWebkitGroupChat];
		[preferences messageStyleXtrasDidChange];
	}
}

/*!
 * @brief The preference group this chat should use.
 */
- (NSString *)preferenceGroupForChat:(AIChat *)chat
{
	if (useRegularForGroupChat || !chat.isGroupChat) {
		return PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY;
	} else {
		return PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY;
	}
}

- (NSString *)styleSpecificKey:(NSString *)key forStyle:(NSString *)style
{
	return [NSString stringWithFormat:@"%@:%@", style, key];
}

#pragma mark -
/*!
 * @brief Clears cached style bundle pathes if they are built-in but not bundle-relative; Adium 1.4b18 and prior made these.
 */
- (void)clearHardcodedBuiltInStylePaths
{
	if ([[adium.preferenceController preferenceForKey:KEY_CURRENT_WEBKIT_STYLE_PATH
												group:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY] rangeOfString:@".app"].location != NSNotFound)
		[self resetStylesForType:AIWebkitRegularChat];

	if ([[adium.preferenceController preferenceForKey:KEY_CURRENT_WEBKIT_STYLE_PATH
												group:PREF_GROUP_WEBKIT_GROUP_MESSAGE_DISPLAY] rangeOfString:@".app"].location != NSNotFound)
		[self resetStylesForType:AIWebkitGroupChat];
}

- (void)performAdium14PreferenceUpdates
{
	if (![[adium.preferenceController preferenceForKey:@"Adium 1.4:Updated Preferences"
												 group:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY] boolValue]) {
		NSDictionary		*dict = [adium.preferenceController preferencesForGroup:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];
		NSMutableDictionary *newDict = [dict mutableCopy];
		NSMutableSet		*keysToRemove = [NSMutableSet set];
	
		NSDictionary *conversionDict = 
		[NSDictionary dictionaryWithObjectsAndKeys:
		 /* complete style changes */
		 @"im.adium.Gone Dark.style",	@"com.adiumx.eclipse.style",
		 @"im.adium.Stockholm.style",	@"com.adiumx.plastic.style",
		 @"im.adium.minimal_mod.style", @"com.adiumx.minimal_2.0.style",
		 @"im.adium.Renkoo.style",		@"com.adiumx.renkooNaked.style",
		 @"im.adium.minimal_mod.style",	@"com.adiumx.minimal.style",
		 
		 /* bundle identifier changes */
		 @"im.adium.Gone Dark.style",	@"com.adiumx.gonedark.style",
		 @"im.adium.minimal_mod.style",	@"com.adiumx.minimal_mod.style",
		 @"im.adium.Mockie.style",		@"com.adiumx.mockie.style",
		 @"im.adium.Renkoo.style",		@"com.adiumx.renkoo.style",
		 @"im.adium.Smooth Operator.style",		@"com.adiumx.smooth.operator.style",
		 @"im.adium.Stockholm.style",	@"com.adiumx.stockholm.style",
		 @"im.adium.yMous.style",		@"mathuaerknedam.yMous.style",
		 nil];
		
		/* Upgrade the style ID itself (that is, the style that Adium will be displaying) if it changed */
		NSString *upgradedStyleID = [conversionDict objectForKey:[dict objectForKey:KEY_WEBKIT_STYLE]];
		if (upgradedStyleID)
			[newDict setObject:upgradedStyleID
						forKey:KEY_WEBKIT_STYLE];
		
		/* Now update style-specific preferences, whose keys are prefixed with style names, as needed */
		for (NSString *key in [dict keyEnumerator]) {
			/* For each changed bundle, check each key */
			for (NSString *oldBundleID in [conversionDict keyEnumerator]) {
				if ([key hasPrefix:oldBundleID]) {
					NSString *newBundleID = [conversionDict objectForKey:oldBundleID];
					NSString *newKey = [newBundleID stringByAppendingString:[key substringFromIndex:oldBundleID.length]];
					
					/* Store with the new bundle ID in the key */
					[newDict setObject:[dict objectForKey:key]
								forKey:newKey];
					
					/* Remove the obsolete preference; we'll want it not in the newDict but also need to manually
					 * remove it when we're done, since AIPreferenceController's setPreferences:inGroup: is nondestructive. */
					[newDict removeObjectForKey:key];
					[keysToRemove addObject:key];
				}
			}
		}

		[adium.preferenceController setPreferences:newDict
										   inGroup:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];
		for (NSString *key in keysToRemove) {
			[adium.preferenceController setPreference:nil
											   forKey:key
												group:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];
		}

		[adium.preferenceController setPreference:[NSNumber numberWithBool:YES]
										   forKey:@"Adium 1.4:Updated Preferences"
											group:PREF_GROUP_WEBKIT_REGULAR_MESSAGE_DISPLAY];
	}
}

@end
