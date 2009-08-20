//
//  SRRecorderPalette.h
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer

#import <InterfaceBuilder/InterfaceBuilder.h>
#import "SRRecorderControl.h"
#import "SRRecorderCell.h"

@interface SRRecorderPalette : IBPalette
{
	IBOutlet SRRecorderControl *shortcutRecorder;
}
@end

@interface SRRecorderControl (SRRecorderInspector)
- (NSString *)inspectorClassName;
@end

@interface SRRecorderControl (SRRecorderIBAdditions)
@end

@interface SRRecorderCell (SRRecorderCellIBAdditions)
@end