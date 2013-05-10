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
			
			/* Contrary to most other NSWindowControllers, this doesn't need it to release itself
			 * in -windowWillClose, as it's in keyGenerationControllerDict.
			 */
			[controller autorelease];
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
