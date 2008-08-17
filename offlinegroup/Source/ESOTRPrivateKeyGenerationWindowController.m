//
//  ESOTRPrivateKeyGenerationWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESOTRPrivateKeyGenerationWindowController.h"
#import <AIUtilities/AIStringAdditions.h>

@interface ESOTRPrivateKeyGenerationWindowController ()
- (id)initWithWindowNibName:(NSString *)windowNibName forIdentifier:(NSString *)inIdentifier;
@end

@implementation ESOTRPrivateKeyGenerationWindowController

static NSMutableDictionary	*keyGenerationControllerDict = nil;

+ (void)mainThreadStartedGeneratingForIdentifier:(NSString *)inIdentifier
{
	if (!keyGenerationControllerDict) keyGenerationControllerDict = [[NSMutableDictionary alloc] init];
	
	if (![keyGenerationControllerDict objectForKey:inIdentifier]) {
		ESOTRPrivateKeyGenerationWindowController	*controller;
		
		if ((controller = [[self alloc] initWithWindowNibName:@"OTRPrivateKeyGenerationWindow" 
												forIdentifier:inIdentifier])) {
			[controller showWindow:nil];
			[[controller window] makeKeyAndOrderFront:nil];
			
			[keyGenerationControllerDict setObject:controller
											forKey:inIdentifier];
		}
	}
}

/*!
* @brief We started generating a private key.
 *
 * Create a window controller for inIdentifier and tell it to display.
 * Has no effect if a window is already open for inIdentifier.
 */
+ (void)startedGeneratingForIdentifier:(NSString *)inIdentifier
{
	[self performSelectorOnMainThread:@selector(mainThreadStartedGeneratingForIdentifier:)
						   withObject:inIdentifier
						waitUntilDone:NO];
}

/*!
 * @brief Initialize
 */
- (id)initWithWindowNibName:(NSString *)windowNibName forIdentifier:(NSString *)inIdentifier
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		identifier = [inIdentifier retain];
	}

	return self;
}

/*!
 * @brief Window loaded
 *
 * Start our spinning progress indicator and set up our window
 */
- (void)windowDidLoad
{
	[super windowDidLoad];

	[[self window] setTitle:[AILocalizedString(@"Please wait",nil) stringByAppendingEllipsis]];
	[[self window] center];

	[progressIndicator startAnimation:nil];
	[textField_message setStringValue:
		[NSString stringWithFormat:AILocalizedString(@"Generating private encryption key for %@",nil),identifier]];
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[identifier release];
	[super dealloc];
}

+ (void)mainThreadFinishedGeneratingForIdentifier:(NSString *)inIdentifier
{	
	ESOTRPrivateKeyGenerationWindowController	*controller;

	controller = [keyGenerationControllerDict objectForKey:inIdentifier];
	[controller closeWindow:nil];
	
	[keyGenerationControllerDict removeObjectForKey:inIdentifier];
}

/*!
 * @brief Finished generating a private key
 *
 * Closes the window assosiated with inIdentifier, if it is open.
 */
+ (void)finishedGeneratingForIdentifier:(NSString *)inIdentifier
{
	[self performSelectorOnMainThread:@selector(mainThreadFinishedGeneratingForIdentifier:)
						   withObject:inIdentifier
						waitUntilDone:NO];
}

@end
