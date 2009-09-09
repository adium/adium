//
//  ESOTRFingerprintDetailsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 5/11/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESOTRFingerprintDetailsWindowController.h"
#import "AdiumOTREncryption.h"
#import <Adium/AIAccount.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIImageAdditions.h>

/* libotr headers */
#import <libotr/proto.h>
#import <libotr/context.h>
#import <libotr/message.h>

@interface ESOTRFingerprintDetailsWindowController ()
- (id)initWithWindowNibName:(NSString *)windowNibName forFingerprintDict:(NSDictionary *)inFingerprintDict;
- (void)setFingerprintDict:(NSDictionary *)inFingerprintDict;
@end

@implementation ESOTRFingerprintDetailsWindowController

static ESOTRFingerprintDetailsWindowController	*sharedController = nil;

+ (void)showDetailsForFingerprintDict:(NSDictionary *)inFingerprintDict
{
	if (sharedController) {
		[sharedController setFingerprintDict:inFingerprintDict];

	} else {
		sharedController = [[self alloc] initWithWindowNibName:@"OTRFingerprintDetailsWindow" 
											forFingerprintDict:inFingerprintDict];
	}
		
	[sharedController showWindow:nil];
	[[sharedController window] makeKeyAndOrderFront:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName forFingerprintDict:(NSDictionary *)inFingerprintDict
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		[self setFingerprintDict:inFingerprintDict];
	}
	
	return self;
}

- (void)dealloc
{
	[fingerprintDict release];
	
	[super dealloc];
}

- (void)configureWindow
{
	AIAccount	*account = [fingerprintDict objectForKey:@"AIAccount"];
	
	//Ensure the window is loaded
	[self window];
	
	[textField_UID setStringValue:[fingerprintDict objectForKey:@"UID"]];
	[textField_fingerprint setStringValue:[fingerprintDict objectForKey:@"FingerprintString"]];
	
	[imageView_service setImage:[AIServiceIcons serviceIconForObject:account
																type:AIServiceIconLarge
														   direction:AIIconNormal]];	
}

- (void)setFingerprintDict:(NSDictionary *)inFingerprintDict
{
	if (inFingerprintDict != fingerprintDict) {
		[fingerprintDict release];
		fingerprintDict = [inFingerprintDict retain];
		
		[self configureWindow];
	}
}

- (void)windowDidLoad
{
	[imageView_lock setImage:[NSImage imageNamed:@"Lock_Locked State" forClass:[adium class]]];	
	
	[[self window] setTitle:AILocalizedString(@"OTR Fingerprint",nil)];
	[button_OK setLocalizedString:AILocalizedString(@"OK",nil)];
	
	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	[sharedController autorelease]; sharedController = nil;
}

/*!
* @brief Auto-saving window frame key
 *
 * This is the string used for saving this window's frame.  It should be unique to this window.
 */
- (NSString *)adiumFrameAutosaveName
{
	return @"OTR Fingerprint Details Window";
}

@end
