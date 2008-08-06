//
//  ShortcutRecorderInspector.h
//  ShortcutRecorder
//
//  Copyright 2006 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//
//  Revisions:
//      2006-03-19 Created.

#import "ShortcutRecorderInspector.h"
#import "SRRecorderControl.h"

@implementation ShortcutRecorderInspector

- (id)init
{
    self = [super init];
	
    [NSBundle loadNibNamed:@"ShortcutRecorderInspector" owner:self];
	
    return self;
}

- (void)ok:(id)sender
{
	SRRecorderControl *recorder = (SRRecorderControl *)[self object];
	unsigned int allowedFlags = 0, requiredFlags = 0;
	
	// Undo support - TO COME
	//[self beginUndoGrouping];
    //[self noteAttributesWillChangeForObject: recorder];
	
	// Set allowed flags
	if ([allowedModifiersCommandCheckBox state]) allowedFlags += NSCommandKeyMask;
	if ([allowedModifiersOptionCheckBox state]) allowedFlags += NSAlternateKeyMask;
	if ([allowedModifiersControlCheckBox state]) allowedFlags += NSControlKeyMask;
	if ([allowedModifiersShiftCheckBox state]) allowedFlags += NSShiftKeyMask;
	[recorder setAllowedFlags: allowedFlags];
	[initialShortcutRecorder setAllowedFlags: allowedFlags];

	// Set required flags	
	if ([requiredModifiersCommandCheckBox state]) requiredFlags += NSCommandKeyMask;
	if ([requiredModifiersOptionCheckBox state]) requiredFlags += NSAlternateKeyMask;
	if ([requiredModifiersControlCheckBox state]) requiredFlags += NSControlKeyMask;
	if ([requiredModifiersShiftCheckBox state]) requiredFlags += NSShiftKeyMask;
	[recorder setRequiredFlags: requiredFlags];
	[initialShortcutRecorder setRequiredFlags: requiredFlags];

	// Set autosave name
	[recorder setAutosaveName: [autoSaveNameTextField stringValue]];
	
	// Set initial combo
	[recorder setKeyCombo: [initialShortcutRecorder keyCombo]];
	
	[recorder setEnabled: [enabledButton state]];
	[recorder setHidden: [hiddenButton state]];
	
    [super ok: sender];
}

- (void)revert:(id)sender
{
	SRRecorderControl *recorder = (SRRecorderControl *)[self object];
	unsigned int allowedFlags = [recorder allowedFlags], requiredFlags = [recorder requiredFlags];
	
	// Set allowed checkbox values
	[allowedModifiersCommandCheckBox setState: (allowedFlags & NSCommandKeyMask) ? NSOnState : NSOffState];
	[allowedModifiersOptionCheckBox setState: (allowedFlags & NSAlternateKeyMask) ? NSOnState : NSOffState];
	[allowedModifiersControlCheckBox setState: (allowedFlags & NSControlKeyMask) ? NSOnState : NSOffState];
	[allowedModifiersShiftCheckBox setState: (allowedFlags & NSShiftKeyMask) ? NSOnState : NSOffState];
	
	// Set required checkbox values
	[requiredModifiersCommandCheckBox setState: (requiredFlags & NSCommandKeyMask) ? NSOnState : NSOffState];
	[requiredModifiersOptionCheckBox setState: (requiredFlags & NSAlternateKeyMask) ? NSOnState : NSOffState];
	[requiredModifiersControlCheckBox setState: (requiredFlags & NSControlKeyMask) ? NSOnState : NSOffState];
	[requiredModifiersShiftCheckBox setState: (requiredFlags & NSShiftKeyMask) ? NSOnState : NSOffState];
    
	// Set autosave name
	if ([[recorder autosaveName] length]) [autoSaveNameTextField setStringValue: [recorder autosaveName]];
	else [autoSaveNameTextField setStringValue: @""];

	// Set initial keycombo
	[initialShortcutRecorder setKeyCombo: [recorder keyCombo]];
	
	[enabledButton setState: [recorder isEnabled]];
	[hiddenButton setState: [recorder isHidden]];
	
	[super revert: sender];
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	if (aRecorder == initialShortcutRecorder)
	{
		SRRecorderControl *recorder = (SRRecorderControl *)[self object];
		[recorder setKeyCombo: [initialShortcutRecorder keyCombo]];
		
		[[self inspectedDocument] drawObject: recorder];
	}
}

@end