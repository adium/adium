//
//  AIMessageWindow.m
//  Adium
//
//  Created by Evan Schoenberg on 12/26/05.
//

#import "AIMessageWindow.h"
#import "AIClickThroughThemeDocumentButton.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import "AIMessageWindowController.h"
#import "AIInterfaceControllerProtocol.h"

/*!
 * @class AIMessageWindow
 * @brief This AIDockingWindow subclass serves message windows.
 */
@implementation AIMessageWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if (!(self = [super initWithContentRect:contentRect styleMask:styleMask backing:bufferingType defer:deferCreation]))
		return nil;

	return self;
}

- (NSScriptObjectSpecifier *)objectSpecifier
{
	NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	return [[[NSUniqueIDSpecifier alloc]
			initWithContainerClassDescription:containerClassDesc
			containerSpecifier:nil key:@"chatWindows"
			uniqueID:[NSNumber numberWithUnsignedInteger:[self hash]]] autorelease];
}

- (NSArray *)chats
{
	return [(AIMessageWindowController *)[self windowController] containedChats];
}

- (id)handleCloseScriptCommand:(NSCloseCommand *)command
{
	[self performClose:nil];

	return nil;
}

@end
