#import <Adium/Adium.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import "AIWindowShaker.h"
#import "AWRippler.h"

// The event we need to hook into.
#define Chat_NudgeBuzzOccured                        @"Chat_NudgeBuzzOccured"

@implementation AIWindowShaker

// Register ourselves.
-(void)installPlugin
{
	// Register to observe a nudge or buzz event.
	[[adium notificationCenter] addObserver:self
								   selector:@selector(nudgeBuzzDidOccur:)
									   name:Chat_NudgeBuzzOccured
									 object:nil];
}

// Unregister ourselves.
-(void)uninstallPlugin
{
	[[adium notificationCenter] removeObserver:self];
}

// Called when a nudge or buzz occurs.
-(void)nudgeBuzzDidOccur:(NSNotification *)notification
{
	NSWindow        *window = [[adium interfaceController] windowForChat:[notification object]];
	AWRippler        *rippler = [[AWRippler alloc] init];

    [rippler rippleWindow:window];        
	[rippler release];
}

@end
