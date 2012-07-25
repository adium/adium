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

#import <Adium/AIChat.h>
#import <Adium/AIContentTyping.h>
#import <Adium/AIListObject.h>
#import <Adium/AIStatusIcons.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIBundleAdditions.h>

@implementation AIStatusIcons

static NSMutableDictionary	*statusIcons[NUMBER_OF_STATUS_ICON_TYPES][NUMBER_OF_ICON_DIRECTIONS];

static NSString				*statusIconBasePath = nil;
static NSDictionary			*statusIconNames[NUMBER_OF_STATUS_ICON_TYPES];

static NSString *statusNameForChat(AIChat *inChat);

static BOOL					statusIconsReady = NO;

+ (void)initialize
{
	if (self == [AIStatusIcons class]) {
		//Allocate our status icon cache
		for (unsigned i = 0; i < NUMBER_OF_STATUS_ICON_TYPES; i++) {
			for (unsigned j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++) {
				statusIcons[i][j] = [[NSMutableDictionary alloc] init];
			}
		}
	}
}

//Retrieve the correct status icon for a given list object
+ (NSImage *)statusIconForListObject:(AIListObject *)listObject type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusName:[self statusNameForListObject:listObject]
									   statusType:listObject.statusType
										 iconType:iconType
										direction:iconDirection];
}

+ (NSImage *)statusIconForUnknownStatusWithIconType:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	return [AIStatusIcons statusIconForStatusName:@"Unknown"
									   statusType:AIAvailableStatusType
										 iconType:iconType
										direction:iconDirection];	
}

//Retrieve the correct status icon for a given chat
+ (NSImage *)statusIconForChat:(AIChat *)chat type:(AIStatusIconType)iconType direction:(AIIconDirection)iconDirection
{
	NSString	*statusName = statusNameForChat(chat);
	
	if (statusName) {
		return [AIStatusIcons statusIconForStatusName:statusName
										   statusType:AIAvailableStatusType
											 iconType:iconType
											direction:iconDirection];
	} else {
		return nil;
	}
}

/* Copied from AIStatusController... this is called with a nil statusName frequently, so avoid making lots of extra method calls. */
NSString *defaultNameForStatusType(AIStatusType statusType)
{
	switch (statusType) {
		case AIAvailableStatusType:
			return STATUS_NAME_AVAILABLE;
			break;
		case AIAwayStatusType:
			return STATUS_NAME_AWAY;
			break;
		case AIInvisibleStatusType:
			return STATUS_NAME_INVISIBLE;
			break;
		case AIOfflineStatusType:
			return STATUS_NAME_OFFLINE;
			break;
		default:
			return STATUS_NAME_OFFLINE;
			break;
	}
}
							 
//Retrieve the correct status icon for the internal status ID
+ (NSImage *)statusIconForStatusName:(NSString *)statusName
						  statusType:(AIStatusType)statusType
							iconType:(AIStatusIconType)iconType
						   direction:(AIIconDirection)iconDirection
{
	NSImage				*statusIcon = nil;

	//If not passed a statusName, find a default
	if (!statusName) statusName = defaultNameForStatusType(statusType);
	
	//Retrieve the service icon from our cache
	statusIcon = [statusIcons[iconType][iconDirection] objectForKey:statusName];

	//Load the status icon if necessary
	if (!statusIcon && statusIconsReady) {
		NSString	*fileName;
		
		//Look for a file name with this status name in the active pack
		fileName = [statusIconNames[iconType] objectForKey:statusName];
		if (fileName) {
			NSString	*path = [statusIconBasePath stringByAppendingPathComponent:fileName];
			
			if (path) {
				statusIcon = [[NSImage alloc] initByReferencingFile:path];
				
				if(![statusIcon isValid]) {
					AILog(@"\"%@\" cannot be found.",path);
					[statusIcon release];
					statusIcon = [[NSImage alloc] initWithSize:NSMakeSize(8,8)];
				}
		
				
				if (statusIcon) {
					if (iconDirection == AIIconFlipped) [statusIcon setFlipped:YES];
					[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusName];
					
				}
				
				[statusIcon release];
			}
		} else {
			if ([statusName isEqualToString:@"Blocked"]) {
				//We want a blocked icon but the status set does not give us one
				statusIcon = [NSImage imageNamed:@"DefaultBlockedStatusIcon" forClass:[self class] loadLazily:YES];
				
				if (statusIcon) {
					if (iconDirection == AIIconFlipped) [statusIcon setFlipped:YES];
					[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusName];
				}				
			}

			if (!statusIcon) {
				NSString	*defaultStatusName = defaultNameForStatusType(statusType);
				
				if (![defaultStatusName isEqualToString:statusName]) {
					/* If the pack doesn't provide an icon for this specific status name, fall back on and then cache the default. */
					if ((statusIcon = [self statusIconForStatusName:defaultStatusName
														 statusType:statusType
														   iconType:iconType
														  direction:iconDirection])) {
						[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusName];
					}
					
				} else {
					if (statusType == AIInvisibleStatusType) {
						/* If we get here with an invisible status type, fall back on AIAwayStatusType */
						if ((statusIcon = [self statusIconForStatusName:nil
															 statusType:AIAwayStatusType
															   iconType:iconType
															  direction:iconDirection])) {
							[statusIcons[iconType][iconDirection] setObject:statusIcon forKey:statusName];
						}
						
					} else {
						NSString	*errorMessage;
						
						errorMessage = [NSString stringWithFormat:
							AILocalizedString(@"The active status icon pack \"%@\" installed at \"%@\" is invalid.  It is missing the required status icon \"%@\".  If you received this pack from xtras.adium.im, please contact its author. Your status icon setting will be restored to the default.", nil),
							[[statusIconBasePath lastPathComponent] stringByDeletingPathExtension],
							statusIconBasePath,
							defaultStatusName];
						
						NSRunCriticalAlertPanel(AILocalizedString(@"Invalid status icon pack", nil),errorMessage,nil,nil,nil);
						
						//Post a notification so someone, somewhere can fix us :)
						[[NSNotificationCenter defaultCenter] postNotificationName:AIStatusIconSetInvalidSetNotification
																						   object:nil];
				}
			}
			}
		}
	}
	
	return statusIcon;
}

//Set the active status icon pack
+ (BOOL)setActiveStatusIconsFromPath:(NSString *)inPath
{
	NSBundle * xtraBundle = [NSBundle bundleWithPath:inPath];
	if(xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1))//This checks for a new-style xtra
		inPath = [xtraBundle resourcePath];
	
	NSDictionary	*statusIconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];
		
	if (statusIconDict && [[statusIconDict objectForKey:@"AdiumSetVersion"] intValue] == 1) {
		[statusIconBasePath release];
		statusIconBasePath = [inPath retain];
		
		[statusIconNames[AIStatusIconTab] release];
		statusIconNames[AIStatusIconTab] = [[statusIconDict objectForKey:@"Tabs"] retain];
		
		[statusIconNames[AIStatusIconList] release];
		statusIconNames[AIStatusIconList] = [[statusIconDict objectForKey:@"List"] retain];

		[statusIconNames[AIStatusIconMenu] release];
		statusIconNames[AIStatusIconMenu] = [statusIconNames[AIStatusIconTab] retain];

		//Clear out the status icon cache
		for (unsigned i = 0; i < NUMBER_OF_STATUS_ICON_TYPES; i++) {
			for (unsigned j = 0; j < NUMBER_OF_ICON_DIRECTIONS; j++) {
				[statusIcons[i][j] removeAllObjects];
			}
		}
		
		statusIconsReady = YES;

		[[NSNotificationCenter defaultCenter] postNotificationName:AIStatusIconSetDidChangeNotification
																		   object:nil];
		
		return YES;
	} else {
		statusIconsReady = NO;

		return NO;
	}

	return NO;
}

//Returns the state icon for the passed chat (new content, typing, ...)
static NSString *statusNameForChat(AIChat *inChat)
{
	AITypingState typingState = (AITypingState)[inChat intValueForProperty:KEY_TYPING];

	if (typingState == AITyping) {
		return @"typing";

	} else if ([inChat unviewedContentCount]) {
		return @"content";
		
	} else if (typingState == AIEnteredText) {
		return @"enteredtext";
		
	}
	
	return nil;
}

/*!
 * @brief Return the status name to use for looking up and caching this object's image
 *
 * Offline objects always use the STATUS_NAME_OFFLINE name.
 * Idle objects which are otherwise available (i.e. AIIdleStatus but not AIAwayAndIdleStatus) 
 * must explicitly be returned as @"Idle".
 *
 * If neither of those are the case, return the statusState's statusName if it exists.
 * If it doesn't, and the status is unknown, return @"Unknown".
 *
 * Finally, return nil if none of these conditions are met, indicating that the statusType's default
 * should be used.
 */
+ (NSString *)statusNameForListObject:(AIListObject *)listObject
{
	NSString		*statusName = nil;

	if (listObject.isMobile) {
		statusName = @"Mobile";
	} else if ([listObject isBlocked]) {
		statusName = @"Blocked";
	} else {
		AIStatusSummary	statusSummary = [listObject statusSummary];

		if (statusSummary == AIOfflineStatus) {
			statusName = STATUS_NAME_OFFLINE;
		} else if (statusSummary == AIIdleStatus) {
			/* Note: AIIdleStatus, but not AIAwayAndIdleStatus, which implies an away state */
			statusName = @"Idle";
		} else if (statusSummary == AIAwayAndIdleStatus) {
			statusName = @"Idle And Away";
		} else {
			statusName = listObject.statusName;
			
			if (!statusName && (statusSummary == AIUnknownStatus)) {
				statusName = @"Unknown";
			}
		}
	}
	
	return statusName;
}

#pragma mark Preview menu images

#define	PREVIEW_MENU_IMAGE_SIZE		13
#define	PREVIEW_MENU_IMAGE_MARGIN	2

+ (NSImage *)previewMenuImageForIconPackAtPath:(NSString *)inPath
{
	NSBundle * xtraBundle = [NSBundle bundleWithPath:inPath];
	if(xtraBundle && ([[xtraBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1))//This checks for a new-style xtra
		inPath = [xtraBundle resourcePath];
	
	NSImage			*image;
	NSDictionary	*iconDict;
	
	image = [[NSImage alloc] initWithSize:NSMakeSize((PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN) * 4,
															  PREVIEW_MENU_IMAGE_SIZE)];

	iconDict = [NSDictionary dictionaryWithContentsOfFile:[inPath stringByAppendingPathComponent:@"Icons.plist"]];
	
	if (iconDict && [[iconDict objectForKey:@"AdiumSetVersion"] intValue] == 1) {
		NSDictionary	*previewIconNames = [iconDict objectForKey:@"Tabs"];
		int				xOrigin = 0;

		[image lockFocus];
		for (NSString *iconID in [NSArray arrayWithObjects:
								  STATUS_NAME_AVAILABLE,
								  STATUS_NAME_AWAY,
								  @"Idle",
								  @"Offline",
								  nil]) {
			NSImage		*anIcon;
			
			if ((anIcon = [xtraBundle imageForResource:[previewIconNames objectForKey:iconID]])) {
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

	return [image autorelease];
}

@end

