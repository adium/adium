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
	
	[textField_UID setStringValue:[NSString stringWithFormat:AILocalizedString(@"Fingerprint for %@:", "used for OTR, %@ is a name"), [fingerprintDict objectForKey:@"UID"]]];
	[textField_fingerprint setStringValue:[fingerprintDict objectForKey:@"FingerprintString"]];
	
	Fingerprint *fingerprint = [[fingerprintDict objectForKey:@"FingerprintValue"] pointerValue];
	
	if (otrl_context_is_fingerprint_trusted(fingerprint)) {
		[button_trust selectItemAtIndex:1];
	} else {
		[button_trust selectItemAtIndex:0];
	}
	
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
	[imageView_lock setImage:[NSImage imageNamed:@"lock-locked" forClass:[adium class]]];	
	
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

- (IBAction)okay:(id)sender
{
	Fingerprint *fingerprint = [[fingerprintDict objectForKey:@"FingerprintValue"] pointerValue];
	
	if ([button_trust indexOfSelectedItem] == 1 && !otrl_context_is_fingerprint_trusted(fingerprint)) {
		otrl_context_set_trust(fingerprint, "verified");
	} else if ([button_trust indexOfSelectedItem] == 0 && otrl_context_is_fingerprint_trusted(fingerprint)) {
		otrl_context_set_trust(fingerprint, "");
	}
	
	otrg_ui_update_fingerprint();
	
	[self closeWindow:sender];
}

- (IBAction)cancel:(id)sender
{
	[self closeWindow:sender];
}


@end
