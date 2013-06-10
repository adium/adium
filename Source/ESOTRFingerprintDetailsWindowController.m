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

#import "ESOTRFingerprintDetailsWindowController.h"
#import "AdiumOTREncryption.h"
#import <Adium/AIAccount.h>
#import <Adium/AIServiceIcons.h>
#import <AIUtilities/AIImageAdditions.h>

/* libotr headers */

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
		fingerprintDict = inFingerprintDict;
		
		[self configureWindow];
	}
}

- (void)windowDidLoad
{
	[imageView_lock setImage:[NSImage imageNamed:@"lock-locked" forClass:[adium class]]];	
	
	[[self window] setTitle:AILocalizedString(@"OTR Fingerprint",nil)];
	[button_OK setStringValue:AILocalizedString(@"OK",nil)];
	
	[super windowDidLoad];
}

- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	sharedController = nil;
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
