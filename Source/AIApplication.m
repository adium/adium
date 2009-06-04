//
//  AIApplication.m
//  Adium
//
//  Created by Evan Schoenberg on 7/6/06.
//

#import "AIApplication.h"
#import <Adium/AIDockControllerProtocol.h>
#import "AIMessageWindow.h"
#import "AIURLHandlerPlugin.h"
#import "AIAccountControllerProtocol.h"
#import "AIUtilities/AIArrayAdditions.h"
#import "AIInterfaceControllerProtocol.h"
#import "AIStatus.h"
#import "AIStatusGroup.h"
#import "AIStatusControllerProtocol.h"
#import "AIChatControllerProtocol.h"
#import "AIContactControllerProtocol.h"
#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>

@implementation AIApplication
/*!
 * @brief Intercept applicationIconImage so we can return a base application icon
 *
 * The base application icon doesn't have any badges, labels, or animation states.
 */
- (NSImage *)applicationIconImage
{
	return [adium.dockController baseApplicationIconImage] ?: [super applicationIconImage];
}

- (NSArray *)services
{
	return adium.accountController.services;
}

- (NSArray *)orderedWindows
{
	//build a list of the windows, in order
	return [super windows];
}

- (void)setOrderedWindows:(NSArray *)ow
{
	//for some reason, when I call make new window at end, this method is called
	NSLog(@"setOrderedWindows: %@\n%@",[self orderedWindows],ow);
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create window. At least, not like that."];
}

- (void)insertInOrderedWindows:(NSWindow *)w
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create window. At least, not like that."];
}
- (void)insertObject:(NSWindow *)w inOrderedWindowsAtIndex:(NSUInteger)index
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create window. At least, not like that."];
}
- (NSArray *)chatWindows
{
	NSArray *windows = [self orderedWindows];
	NSMutableArray *chatWindows = [[[NSMutableArray alloc] init] autorelease];
	for (NSInteger i=0;i<[windows count];i++)
		if ([[windows objectAtIndex:i] isKindOfClass:[AIMessageWindow class]])
			[chatWindows addObject:[windows objectAtIndex:i]];
	return chatWindows;
}
- (AIMessageWindow *)valueInChatWindowsWithUniqueID:(NSNumber *)uniqueID
{
	for (NSWindow *window in [self orderedWindows])
		if ([window isKindOfClass:[AIMessageWindow class]])
			if ([window hash] == [uniqueID unsignedIntValue])
				return (AIMessageWindow *)window;
	return nil;
}
- (NSArray *)chats
{
	return [adium.chatController.openChats allObjects];
}
- (NSArray *)accounts
{
	return adium.accountController.accounts;
}
- (NSArray *)contacts
{
	return adium.contactController.allContacts;
}
- (void)insertObject:(AIListObject *)contact inContactsAtIndex:(NSInteger)index
{
	//Intentially unimplemented. This should never be called (contacts are created a different way), but is required for KVC-compliance.
}
- (void)removeObjectFromContactsAtIndex:(NSInteger)index
{
	AIListObject *object = [self.contacts objectAtIndex:index];
	
	for (AIListGroup *group in object.groups) {
		[object removeFromGroup:group];
	}
}

- (NSArray *)statuses
{
	return [adium.statusController.flatStatusSet allObjects];
}
- (NSArray *)contactGroups
{
	return adium.contactController.allGroups;
}

- (void)setIsActive:(BOOL)val
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
}
- (void)scriptingGoOnline:(NSScriptCommand *)c
{
	//tell every account to go online
	[[self accounts] makeObjectsPerformSelector:@selector(scriptingGoOnline:) withObject:c];
}
- (void)scriptingGoAvailable:(NSScriptCommand *)c
{
	//tell every account to go available
	[[self accounts] makeObjectsPerformSelector:@selector(scriptingGoAvailable:) withObject:c];
}
- (void)scriptingGoOffline:(NSScriptCommand *)c
{
	//tell every account to go offline
	[[self accounts] makeObjectsPerformSelector:@selector(scriptingGoOffline:) withObject:c];
}
- (void)scriptingGoAway:(NSScriptCommand *)c
{
	//tell every account to go away
	[[self accounts] makeObjectsPerformSelector:@selector(scriptingGoAway:) withObject:c];
}
- (void)scriptingGoInvisible:(NSScriptCommand *)c
{
	//tell every account to go invisible
	[[self accounts] makeObjectsPerformSelector:@selector(scriptingGoInvisible:) withObject:c];
}
/**
 * @brief Returns the active chat.
 * In actuality, this returns the most recently active chat, which will return a chat even if all chat windows are closed.
 * For some reason [AIInterfaceController activeChat] doesn't work like I would have expected it to.
 */
- (AIChat *)activeChat
{
	return [adium.interfaceController mostRecentActiveChat];
}

#pragma mark Status

- (id)makeStatusWithProperties:(NSDictionary *)keyDictionary
{
	//ready the arguments!
	AIStatusTypeApplescript type;
	NSDictionary *properties = [keyDictionary objectForKey:@"KeyDictionary"];
	if (!properties || ![properties objectForKey:@"statusTypeApplescript"])
		type = AIAvailableStatusTypeAS;
	else
		type = [[properties objectForKey:@"statusTypeApplescript"] unsignedIntegerValue];
	
	AIStatusType realType;
	switch (type) {
		case AIAvailableStatusTypeAS:
			realType = AIAvailableStatusType;
			break;
		case AIAwayStatusTypeAS:
			realType = AIAwayStatusType;
			break;
		case AIInvisibleStatusTypeAS:
			realType = AIInvisibleStatusType;
			break;
		case AIOfflineStatusTypeAS:
		default:
			realType = AIOfflineStatusType;
			break;
	}
	
	AIStatus *status = [AIStatus statusOfType:realType];
	if ([properties objectForKey:@"scriptingTitle"])
		[status setTitle:[properties objectForKey:@"scriptingTitle"]];
	if ([properties objectForKey:@"scriptingMessage"]) {
		if ([[properties objectForKey:@"scriptingMessage"] isKindOfClass:[NSString class]])
			[status setStatusMessageString:[properties objectForKey:@"scriptingMessage"]];
		else
			[status setStatusMessage:[properties objectForKey:@"scriptingMessage"]];
	}
	if ([properties objectForKey:@"scriptingAutoreply"]) {
		if ([[properties objectForKey:@"scriptingAutoreply"] isKindOfClass:[NSString class]])
			[status setAutoReplyString:[properties objectForKey:@"scriptingAutoreply"]];
		else
			[status setAutoReply:[properties objectForKey:@"scriptingAutoreply"]];
	}
	
	if ([keyDictionary objectForKey:@"Location"]) {
		NSPositionalSpecifier *location = [keyDictionary objectForKey:@"Location"];
		NSUInteger index = [location insertionIndex];
		[[adium.statusController rootStateGroup] addStatusItem:status atIndex:index];
	} else {
		[adium.statusController addStatusState:status];
	}
	
	return status;
}
- (AIStatus *)valueInStatusesWithUniqueID:(id)uniqueID
{
	return [adium.statusController statusStateWithUniqueStatusID:uniqueID];
}
- (AIStatus *)globalStatus
{
	return adium.statusController.activeStatusState;
}
- (void)setGlobalStatus:(AIStatus *)inGlobalStatus
{
	return [adium.statusController setActiveStatusState:inGlobalStatus];	
}

- (id)scriptingGetURL:(NSScriptCommand *)command
{
	NSString *url = [command directParameter];
	[[NSNotificationCenter defaultCenter] postNotificationName:AIURLHandleNotification object:url];
	return nil;
}

#pragma mark Debugging
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"*** setValue:%@ forUndefinedKey:%@ ***", value, key);
	[super setValue:value forUndefinedKey:key];
}

@end

