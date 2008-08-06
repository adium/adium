//
//  AICustomSocialNetworkingStatusWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 6/7/08.
//  Copyright 2008 Adium X. All rights reserved.
//

#import "AICustomSocialNetworkingStatusWindowController.h"

@implementation AICustomSocialNetworkingStatusWindowController

static	AICustomSocialNetworkingStatusWindowController	*sharedController = nil;

+ (void)showCustomSocialNetworkingStatusWindowWithInitialMessage:(NSAttributedString *)inMessage forAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget
{
	if (!sharedController) {
		sharedController = [[self alloc] initWithWindowNibName:@"SocialNetworkingCustomStatus"];
	}

	//Ensure the window has loaded
	[sharedController window];

	[sharedController setAccount:inAccount];
	[sharedController setMessage:inMessage];
	[sharedController setTarget:inTarget];

	[sharedController showWindow:nil];
	[[sharedController window] makeKeyAndOrderFront:nil];
}

- (void)windowDidLoad
{
	[label_socialNetworkingStatus setLocalizedString:AILocalizedString(@"Social Networking Status:", nil)];
	[button_okay setLocalizedString:AILocalizedString(@"OK", nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];
	[[self window] setTitle:AILocalizedString(@"Social Networking Status", nil)];

	[super windowDidLoad];
}
- (void)dealloc
{
	[account release];
	[target release];
	
	[super dealloc];
}

- (void)setAccount:(AIAccount *)inAccount
{
	if (inAccount != account) {
		[account release];
		account = [inAccount retain];
	}	
}

- (void)setTarget:(id)inTarget
{
	if (inTarget != target) {
		[target release];
		target = [inTarget retain];
	}	
}

- (void)setMessage:(NSAttributedString *)inMessage
{
	[[textview_message textStorage] setAttributedString:(inMessage ? inMessage : [[[NSAttributedString alloc] initWithString:@""] autorelease])];
}

- (IBAction)okay:(id)sender
{
	[target setSocialNetworkingStatus:[[[textview_message textStorage] copy] autorelease]
						   forAccount:account];

	[self closeWindow:nil];
}

/*!
 * @brief Cancel
 *
 * Close the editor without saving changes.
 */
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

- (void)textViewDidCancel:(NSTextView *)inTextView
{
	[self cancel:inTextView];
}

/*!
 * @brief If escape or return are pressed inside one of our text views, pass the action on to our buttons
 */
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	NSButton *equivalentButton = nil;

	if (aSelector == @selector(cancelOperation:)) {
		equivalentButton = button_cancel;
		
	} else if ((aSelector == @selector(insertNewline:)) || (aSelector == @selector(insertNewlineIgnoringFieldEditor:))) {
		equivalentButton = button_okay;
	}

	if (equivalentButton) {
		[equivalentButton performClick:aTextView];
		return YES;
		
	} else {
		return NO;
	}
}

/*!
 * @brief Called before the window is closed
 *
 * As our window is closing, we auto-release this window controller instance.  This allows our editor to function
 * independently without needing a separate object to retain and release it.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[sharedController autorelease]; sharedController = nil;
}


@end
