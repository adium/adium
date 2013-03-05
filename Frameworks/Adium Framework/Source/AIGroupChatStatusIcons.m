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

#import "AIGroupChatStatusIcons.h"

#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIBundleAdditions.h>

@interface AIGroupChatStatusIcons()
+ (NSURL *)currentPackURL;
- (NSString *)keyForFlags:(AIGroupChatFlags)flags;
- (NSImage *)imageForKey:(NSString *)key;
- (NSColor *)colorForKey:(NSString *)key;
@end

@implementation AIGroupChatStatusIcons

static AIGroupChatStatusIcons *sharedIconsInstance = nil;

/*!
 * @brief Shared set of icons
 *
 * The singleton which will return our group chat icons. It handles updating its pack on changes
 * on its own, and creates its singleton as necessary.
 */
+ (AIGroupChatStatusIcons *)sharedIcons
{
	if (!sharedIconsInstance) {
		sharedIconsInstance = [[self alloc] initWithURL:[self currentPackURL]];
	}
	
	return sharedIconsInstance;
}

/*!
 * @brief Initialize
 */
- (id)initWithURL:(NSURL *)inURL
{
	if ((self = [super initWithURL:inURL])) {
		[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
		iconInfo = [xtraBundle objectForInfoDictionaryKey:KEY_ICONS_DICT];
		colorInfo = [xtraBundle objectForInfoDictionaryKey:KEY_COLORS_DICT];
		
		icons = [[NSMutableDictionary alloc] init];
		colors = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
	sharedIconsInstance = nil;
	[icons release]; [colors release];
	[iconInfo release]; [colorInfo release];
	
	[adium.preferenceController unregisterPreferenceObserver:self];
	[super dealloc];
}

#pragma mark Image Retrieval

/*!
 * @brief Returns an image of the highest level of flag
 *
 * Only the highest level of icon is returned in a group. To individually get all
 * icons for a user, you will have to request multiple flags individually.
 *
 * @param flags An integer composed of AIGroupChatFlags
 * @returns An image representing the highest flag present in the flags.
 */
- (NSImage *)imageForFlag:(AIGroupChatFlags)flags
{
	NSString *key = [self keyForFlags:flags];
	NSImage *image = [icons objectForKey:key];
	
	// If we don't have it already saved, try to get the image from the pack.
	if (!image) {
		image = [self imageForKey:key];

		if (image) {
			// The image was in the pack; store it.
			[icons setObject:image forKey:key];
		} else {
			// The image wasn't in the pack; return the "none" image.
			image = [self imageForKey:NONE];
		}
	}
	
	return image;
}

/*!
 * @brief The image for a given key
 *
 * Retrieves an image from the bundle's resources of a given name.
 *
 * @param The key in the dictionary of the bundle's icons to retrieve
 * @returns The image from the bundle.
 */
- (NSImage *)imageForKey:(NSString *)key
{
	if (!iconInfo || ![iconInfo objectForKey:key]) {
		return nil;
	}
	
	return [xtraBundle AI_imageForResource:[iconInfo objectForKey:key]];
}

#pragma mark Color retrieval

/*!
 * @brief Returns the color of the highest level of flag
 *
 * The color is used when drawing the name of the contact in the user list.
 * It should match or be similar to the icon color, but this is not a requirement.
 *
 * @param flags An integer composed of AIGroupChatFlags
 * @returns A color representing the highest flag present in the flags.
 */
- (NSColor *)colorForFlag:(AIGroupChatFlags)flags
{
	NSString	*key = [self keyForFlags:flags];
	NSColor		*color = [colors objectForKey:key];
	
	if (!color) {
		color = [self colorForKey:key];
		
		if (color) {
			[colors setObject:color forKey:key];
		} else {
			color = [self colorForKey:NONE];
		}
	}
	
	return color;
}

/*!
 * @brief The color ofr a given key
 *
 * Retrieve's the color from the Colors dictionary of the bundle's Info
 *
 * @param key The key in the dictionary of the bundle's colors to retrieve
 * @returns The color from the bundle
 */
- (NSColor *)colorForKey:(NSString *)key
{
	if (!colorInfo || ![colorInfo objectForKey:key]) {
		return nil;
	}
	
	return [[colorInfo objectForKey:key] representedColor];
}

#pragma mark Flags -> Keys

/*!
 * @brief The key for a given set of flags
 *
 * @param flags An integer composed of AIGroupChatFlags
 * @returns The key for use in the dictionary for storing information of this type.
 */
- (NSString *)keyForFlags:(AIGroupChatFlags)flags
{
	if ((flags & AIGroupChatFounder) == AIGroupChatFounder)
		return FOUNDER;
	
	if ((flags & AIGroupChatOp) == AIGroupChatOp)
		return OP;
	
	if ((flags & AIGroupChatHalfOp) == AIGroupChatHalfOp)
		return HOP;
	
	if ((flags & AIGroupChatVoice) == AIGroupChatVoice)
		return VOICE;
	
	return NONE;
}

#pragma mark Preferences/Loading

/*!
 * @brief The current pack
 *
 * @returns The path to the current pack URL
 */
+ (NSURL *)currentPackURL
{
	NSString *packName = nil, *path = nil;
	
	packName = [adium.preferenceController preferenceForKey:KEY_GROUP_CHAT_STATUS_ICONS
													  group:PREF_GROUP_APPEARANCE
													 object:nil];
	
	// Get the path of the pack if found.
	if (packName) {
		path = [adium pathOfPackWithName:packName
							   extension:EXTENSION_GROUP_CHAT_STATUS_ICONS
					  resourceFolderName:RESOURCE_GROUP_CHAT_STATUS_ICONS];
	}
	
	// If the pack is not found, get the default one.
	if (!path || !packName) {
		packName = [adium.preferenceController defaultPreferenceForKey:KEY_GROUP_CHAT_STATUS_ICONS
																 group:PREF_GROUP_APPEARANCE
																object:nil];
		path = [adium pathOfPackWithName:packName
							   extension:EXTENSION_GROUP_CHAT_STATUS_ICONS
					  resourceFolderName:RESOURCE_GROUP_CHAT_STATUS_ICONS];
	}

	return [NSURL fileURLWithPath:path];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		if ([key isEqualToString:KEY_GROUP_CHAT_STATUS_ICONS]) {
			// We're going to be killing ourself off, so retain until the end.
			[self retain];
			
			// Create a new shared controller.
			[sharedIconsInstance release]; sharedIconsInstance = nil;
			[AIGroupChatStatusIcons sharedIcons];
			
			// Suicide. :'(
			[self release];
		}
	}
}

@end
