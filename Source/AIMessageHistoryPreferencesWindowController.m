//
//  AIMessageHistoryPreferencesWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 4/6/07.
//

#import "AIMessageHistoryPreferencesWindowController.h"

typedef enum {
AIMessageHistory_Always = 0,
AIMessageHistory_HaveTalkedInInterval,
AIMessageHistory_HaveNotTalkedInInterval
} AIMessageHistoryDisplayPref;

@interface AIMessageHistoryPreferencesWindowController ()
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation AIMessageHistoryPreferencesWindowController
/*!
 * @brief Configure message history preferences
 *
 * @param parentWindow A window on which to show the message history preferences window as a sheet.  If nil, account editing takes place in an independent window.
 */
+ (void)configureMessageHistoryPreferencesOnWindow:(id)parentWindow
{
	AIMessageHistoryPreferencesWindowController	*controller;
	
	controller = [[self alloc] initWithWindowNibName:@"MessageHistoryConfiguration"];

	if (parentWindow) {
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[controller showWindow:nil];
	}
}

- (void)windowDidLoad
{
	//Observe preference changes
	[adium.preferenceController addObserver:self
								   forKeyPath:@"Message Context Display.Display Mode"
									  options:NSKeyValueObservingOptionNew
									  context:NULL];
	[self observeValueForKeyPath:@"Message Context Display.Display Mode"
						ofObject:adium.preferenceController
						  change:nil
						 context:NULL];
	
	[super windowDidLoad];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	BOOL enableTalkedControls = NO;
	BOOL enableNotTalkedControls = NO;
	
	switch ([[adium.preferenceController preferenceForKey:@"Display Mode" group:@"Message Context Display"] integerValue]) {
		case AIMessageHistory_Always:
			break;
		
		case AIMessageHistory_HaveTalkedInInterval:
			enableTalkedControls = YES;
			break;
		case AIMessageHistory_HaveNotTalkedInInterval:
			enableNotTalkedControls = YES;
			break;
	}
	
	[textField_haveTalkedDays setEnabled:enableTalkedControls];
	[stepper_haveTalkedDays setEnabled:enableTalkedControls];
	[popUp_haveTalkedUnits setEnabled:enableTalkedControls];

	[textField_haveNotTalkedDays setEnabled:enableNotTalkedControls];
	[stepper_haveNotTalkedDays setEnabled:enableNotTalkedControls];	
	[popUp_haveNotTalkedUnits setEnabled:enableNotTalkedControls];
}

/*!
 * @brief Window is closing
 */
- (void)windowWillClose:(id)sender
{
	[adium.preferenceController removeObserver:self forKeyPath:@"Message Context Display.Display Mode"];

	[super windowWillClose:sender];
	[self autorelease];
}

/*!
 * @brief Called as the user list edit sheet closes, dismisses the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
}

@end
