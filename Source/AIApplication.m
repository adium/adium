//
//  AIApplication.m
//  Adium
//
//  Created by Evan Schoenberg on 7/6/06.
//

#import "AIApplication.h"
#import <Adium/AIDockControllerProtocol.h>
#import <Adium/AIAdiumProtocol.h>
#import "AIMessageWindow.h"
#import "AIAccountControllerProtocol.h"
#import "AIUtilities/AIArrayAdditions.h"
#import "AIInterfaceControllerProtocol.h"
#import "AIStatus.h"
#import "AIStatusGroup.h"
#import "AIStatusControllerProtocol.h"
#import "AIChatControllerProtocol.h"
#import "AIContactControllerProtocol.h"
#import "AdiumURLHandling.h"

@implementation AIApplication
/*!
 * @brief Intercept applicationIconImage so we can return a base application icon
 *
 * The base application icon doesn't have any badges, labels, or animation states.
 */
- (NSImage *)applicationIconImage
{
	NSImage *applicationIconImage = [[adium dockController] baseApplicationIconImage];

	return (applicationIconImage ? applicationIconImage : [super applicationIconImage]);
}

- (NSArray *)services
{
	return [[adium accountController] services];
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
- (void)insertObject:(NSWindow *)w inOrderedWindowsAtIndex:(unsigned int)index
{
	[[NSScriptCommand currentCommand] setScriptErrorNumber:errOSACantAssign];
	[[NSScriptCommand currentCommand] setScriptErrorString:@"Can't create window. At least, not like that."];
}
- (NSArray *)chatWindows
{
	NSArray *windows = [self orderedWindows];
	NSMutableArray *chatWindows = [[[NSMutableArray alloc] init] autorelease];
	for (int i=0;i<[windows count];i++)
		if ([[windows objectAtIndex:i] isKindOfClass:[AIMessageWindow class]])
			[chatWindows addObject:[windows objectAtIndex:i]];
	return chatWindows;
}
- (NSArray *)chats
{
	return [[[adium chatController] openChats] allObjects];
}
- (NSArray *)accounts
{
	return [[adium accountController] accounts];
}
- (NSArray *)contacts
{
	return [[adium contactController] allContacts];
}
- (void)insertObject:(AIListObject *)contact inContactsAtIndex:(int)index
{
	//Intentially unimplemented. This should never be called (contacts are created a different way), but is required for KVC-compliance.
}
- (void)removeObjectFromContactsAtIndex:(int)index
{
	[[adium contactController] removeListObjects:[NSArray arrayWithObject:[[self contacts] objectAtIndex:index]]];
}

- (NSArray *)statuses
{
	return [[[adium statusController] flatStatusSet] allObjects];
}
- (NSArray *)contactGroups
{
	return [[adium contactController] allGroups];
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
	return [[adium interfaceController] mostRecentActiveChat];
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
		type = [[properties objectForKey:@"statusTypeApplescript"] unsignedIntValue];
	
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
		unsigned int index = [location insertionIndex];
		[[[adium statusController] rootStateGroup] addStatusItem:status atIndex:index];
	} else {
		[[adium statusController] addStatusState:status];
	}
	
	return status;
}
- (void)insertObject:(AIStatus *)status inStatusesAtIndex:(unsigned int)i
{
	[self insertInStatuses:status atIndex:i];
}
- (void)removeObjectFromStatusesAtIndex:(unsigned int)i
{
	[self removeFromStatusesAtIndex:i];
}
- (void)replaceObjectInStatusesAtIndex:(unsigned int)i withObject:(AIStatus *)status
{
	[self replaceInStatuses:status atIndex:i];
}
- (void)insertInStatuses:(AIStatus *)status
{
	[[adium statusController] addStatusState:status];
}
- (void)insertInStatuses:(AIStatus *)status atIndex:(unsigned int)i
{
	[[[adium statusController] rootStateGroup] addStatusItem:status atIndex:i];
}
- (void)removeFromStatusesAtIndex:(unsigned int)i
{
	[[[adium statusController] rootStateGroup] removeStatusItem:[[self statuses] objectAtIndex:i]];
}
- (void)replaceInStatuses:(AIStatus *)status atIndex:(unsigned int)i
{
	NSLog(@"%s NOT IMPLEMENTED",__PRETTY_FUNCTION__);
}
- (AIStatus *)valueInStatusesWithUniqueID:(id)uniqueID
{
	return [[adium statusController] statusStateWithUniqueStatusID:uniqueID];
}
- (AIStatus *)globalStatus
{
	return [[adium statusController] activeStatusState];
}
- (void)setGlobalStatus:(AIStatus *)inGlobalStatus
{
	return [[adium statusController] setActiveStatusState:inGlobalStatus];	
}

- (id)scriptingGetURL:(NSScriptCommand *)command
{
	NSString *url = [command directParameter];
	[AdiumURLHandling handleURLEvent:url];
	return nil;
}

#pragma mark Debugging
- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"*** setValue:%@ forUndefinedKey:%@ ***", value, key);
	[super setValue:value forUndefinedKey:key];
}

@end

