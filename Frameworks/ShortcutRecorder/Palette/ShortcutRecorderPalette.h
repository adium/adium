//
//  ShortcutRecorderPalette.h
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
#import "SRRecorderCell.h"

@interface ShortcutRecorderPalette : IBPalette
{
	IBOutlet SRRecorderControl *shortcutRecorder;
}
@end

@interface SRRecorderControl (SRRecorderPaletteInspector)
- (NSString *)inspectorClassName;
@end

@interface SRRecorderControl (SRRecorderIBAdditions)
@end

@interface SRRecorderCell (SRRecorderCellIBAdditions)
@end