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

#import <Adium/AIListObject.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIAccountControllerProtocol.h>

static NSMutableDictionary	*serviceIcons[NUMBER_OF_SERVICE_ICON_TYPES][NUMBER_OF_ICON_DIRECTIONS];

static NSString				*serviceIconBasePath = nil;
static NSDictionary			*serviceIconNames[NUMBER_OF_SERVICE_ICON_TYPES];

@interface AIServiceIcons ()
+ (NSImage *)defaultServiceIconForType:(AIServiceIconType)type serviceID:(NSString *)serviceID;
@end

@implementation AIServiceIcons

+ (void)initialize
{
	if (self == [AIServiceIcons class]) {
		int i, j;

		//Allocate our service icon cache
		for (i = 0; i < NUMBER_OF_SERVICE_ICON_TYPES; i++) {
			for (j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++) {
				serviceIcons[i][j] = [[NSMutableDictionary alloc] init];
			}
		}
	}
}

//Retrive the correct service icon for a contact
+ (NSImage *)serviceIconForObject:(AIListObject *)inObject type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [self serviceIconForService:inObject.service type:iconType direction:iconDirection];
}

//Retrieve the correct service icon for a service
+ (NSImage *)serviceIconForService:(AIService *)service type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSImage	*serviceIcon = [self serviceIconForServiceID:service.serviceID type:iconType direction:iconDirection];

	if (!serviceIcon && service) {
		//If the icon pack doesn't supply a service icon, query the service itself
		serviceIcon = [service defaultServiceIconOfType:iconType];

		if (serviceIcon) {
			if (iconDirection == AIIconFlipped) [serviceIcon setFlipped:YES];
			[serviceIcons[iconType][iconDirection] setObject:serviceIcon forKey:service.serviceID];
		}
	}
	return serviceIcon;
}

+ (NSString *)pathForServiceIconForServiceID:(NSString *)serviceID type:(AIServiceIconType)iconType
{
	NSString *iconName = [serviceIconNames[iconType] objectForKey:serviceID];
	
	if (iconName) {
		return [serviceIconBasePath stringByAppendingPathComponent:iconName];
	} else {
		AIService *service = [adium.accountController firstServiceWithServiceID:serviceID];
		if (service) {
			return [service pathForDefaultServiceIconOfType:iconType];
		} else {
			return nil;
		}
	}
}

//Retrieve the correct service icon for a service by ID
+ (NSImage *)serviceIconForServiceID:(NSString *)serviceID type:(AIServiceIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSImage				*serviceIcon;

	//Retrieve the service icon from our cache
	serviceIcon = [serviceIcons[iconType][iconDirection] objectForKey:serviceID];

	//Load the service icon if necessary
	if (!serviceIcon) {
		NSString	*path = [self pathForServiceIconForServiceID:serviceID type:iconType];

		if (path) {
			serviceIcon = [[NSImage alloc] initWithContentsOfFile:path];
		} else {
			AIService *service = [adium.accountController firstServiceWithServiceID:serviceID];
			if (service) {
				serviceIcon = [service defaultServiceIconOfType:iconType];
			}
		}

		if (serviceIcon) {
			if (iconDirection == AIIconFlipped) [serviceIcon setFlipped:YES];
			[serviceIcons[iconType][iconDirection] setObject:serviceIcon forKey:serviceID];
		} else {
			//Attempt to load the default service icon
			serviceIcon = [self defaultServiceIconForType:iconType serviceID:serviceID];
			if (serviceIcon) {
				//Cache the default service icon (until the pack is changed) so we have it immediately next time
				if (iconDirection == AIIconFlipped) [serviceIcon setFlipped:YES];
				[serviceIcons[iconType][iconDirection] setObject:serviceIcon forKey:serviceID];
			}
		}
	}

	return serviceIcon;
}

//Set the active service icon pack
+ (BOOL)setActiveServiceIconsFromPath:(NSString *)inPath
{
	NSDictionary	*serviceIconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];

	if (serviceIconDict && [[serviceIconDict objectForKey:@"AdiumSetVersion"] intValue] == 1) {
		serviceIconBasePath = inPath;

		serviceIconNames[AIServiceIconSmall] = [serviceIconDict objectForKey:@"Interface-Small"];

		serviceIconNames[AIServiceIconLarge] = [serviceIconDict objectForKey:@"Interface-Large"];

		serviceIconNames[AIServiceIconList] = [serviceIconDict objectForKey:@"List"];

		//Clear out the service icon cache
		int i, j;

		for (i = 0; i < NUMBER_OF_SERVICE_ICON_TYPES; i++) {
			for (j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++) {
				[serviceIcons[i][j] removeAllObjects];
			}
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:AIServiceIconSetDidChangeNotification
																		   object:nil];

		return YES;
	}

	return NO;
}

#define	PREVIEW_MENU_IMAGE_SIZE		13
#define	PREVIEW_MENU_IMAGE_MARGIN	2

+ (NSImage *)previewMenuImageForIconPackAtPath:(NSString *)inPath
{
	NSImage			*image;
	NSDictionary	*iconDict;

	image = [[NSImage alloc] initWithSize:NSMakeSize((PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN) * 4,
													 PREVIEW_MENU_IMAGE_SIZE)];

	iconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];

	if (iconDict && [[iconDict objectForKey:@"AdiumSetVersion"] intValue] == 1) {
		NSDictionary	*previewIconNames = [iconDict objectForKey:@"List"];
		int				xOrigin = 0;

		[image lockFocus];
		for (NSString *iconID in [NSArray arrayWithObjects:@"AIM",@"Jabber",@"MSN",@"Yahoo!",nil]) {
			NSString	*anIconPath = [inPath stringByAppendingPathComponent:[previewIconNames objectForKey:iconID]];
			NSImage		*anIcon;

			if ((anIcon = [[NSImage alloc] initWithContentsOfFile:anIconPath])) {
				NSSize	anIconSize = [anIcon size];
				NSRect	targetRect = NSMakeRect(xOrigin, 0, PREVIEW_MENU_IMAGE_SIZE, PREVIEW_MENU_IMAGE_SIZE);

				if (anIconSize.width < targetRect.size.width) {
					CGFloat difference = (targetRect.size.width - anIconSize.width)/2;

					targetRect.size.width -= difference;
					targetRect.origin.x += difference;
				}

				if (anIconSize.height < targetRect.size.height) {
					CGFloat difference = (targetRect.size.height - anIconSize.height)/2;

					targetRect.size.height -= difference;
					targetRect.origin.y += difference;
				}

				[anIcon drawInRect:targetRect
							fromRect:NSMakeRect(0,0,anIconSize.width,anIconSize.height)
						   operation:NSCompositeCopy
							fraction:1.0f];

				//Shift right in preparation for next image
				xOrigin += PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN;
			}
		}
		[image unlockFocus];
	}

	return image;
}

#pragma mark Default loading

#define PREF_GROUP_APPEARANCE		@"Appearance"
#define	KEY_SERVICE_ICON_PACK		@"Service Icon Pack"

+ (NSImage *)defaultServiceIconForType:(AIServiceIconType)type serviceID:(NSString *)serviceID
{
	NSString			*defaultName, *defaultPath;
	NSDictionary		*serviceIconDict;
	NSImage				*defaultServiceIcon = nil;
	
	defaultName = [adium.preferenceController defaultPreferenceForKey:KEY_SERVICE_ICON_PACK
																   group:PREF_GROUP_APPEARANCE
																  object:nil];
	defaultPath = [adium pathOfPackWithName:defaultName
								  extension:@"AdiumServiceIcons"
						 resourceFolderName:@"Service Icons"];
	
	serviceIconDict = [NSDictionary dictionaryWithContentsOfFile:[defaultPath stringByAppendingPathComponent:@"Icons.plist"]];
	if (serviceIconDict && [[serviceIconDict objectForKey:@"AdiumSetVersion"] intValue] == 1) {
		NSString	*nameKey = nil;

		switch (type) {
			case AIServiceIconSmall:
				nameKey = @"Interface-Small";
				break;
			case AIServiceIconLarge:
				nameKey = @"Interface-Large";
				break;
			case AIServiceIconList:
				nameKey = @"List";
				break;
		}
		
		if (nameKey) {
			NSDictionary	*defaultServiceIconNames;
			NSString		*thisServiceIconImageName;
	
			defaultServiceIconNames = [serviceIconDict objectForKey:nameKey];
			if ((thisServiceIconImageName = [defaultServiceIconNames objectForKey:serviceID])) {
				NSString		*iconPath = [defaultPath stringByAppendingPathComponent:thisServiceIconImageName];
				
				defaultServiceIcon = [[NSImage alloc] initWithContentsOfFile:iconPath];
			}
		}
	}
	
	return defaultServiceIcon;
}

@end
