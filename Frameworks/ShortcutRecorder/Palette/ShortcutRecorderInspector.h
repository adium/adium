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

#import <InterfaceBuilder/InterfaceBuilder.h>
#import "SRRecorderControl.h"

@interface ShortcutRecorderInspector : IBInspector
{
	IBOutlet NSButton *allowedModifiersCommandCheckBox;
	IBOutlet NSButton *allowedModifiersOptionCheckBox;
	IBOutlet NSButton *allowedModifiersShiftCheckBox;
	IBOutlet NSButton *allowedModifiersControlCheckBox;
	
	IBOutlet NSButton *requiredModifiersCommandCheckBox;
	IBOutlet NSButton *requiredModifiersOptionCheckBox;
	IBOutlet NSButton *requiredModifiersShiftCheckBox;
	IBOutlet NSButton *requiredModifiersControlCheckBox;

	IBOutlet NSTextField *autoSaveNameTextField;
	IBOutlet SRRecorderControl *initialShortcutRecorder;
	
	IBOutlet NSButton *enabledButton;
	IBOutlet NSButton *hiddenButton;
}
@end
