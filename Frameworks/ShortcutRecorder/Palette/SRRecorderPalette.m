//
//  SRRecorderPalette.m
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer

#import "SRRecorderPalette.h"

@implementation SRRecorderPalette

- (void)finishInstantiate
{	
	[super finishInstantiate];
}

@end

@implementation SRRecorderControl (SRRecorderInspector)

- (NSString *)inspectorClassName
{
    return @"SRRecorderInspector";
}

@end

@implementation SRRecorderControl (SRRecorderIBAdditions)

- (NSSize)minimumFrameSizeFromKnobPosition:(IBKnobPosition)position
{
	return NSMakeSize(SRMinWidth, SRMaxHeight); // Limit width and height
}

- (NSSize)maximumFrameSizeFromKnobPosition:(IBKnobPosition)knobPosition
{
	return NSMakeSize(IB_BIG_SIZE, SRMaxHeight); // Allow maximum width but limit height
}

- (BOOL)allowsAltDragging
{
	return NO; // Since current cell implementation seems to be buggy
}

@end

@implementation SRRecorderCell (SRRecorderCellIBAdditions)

- (void)_saveKeyCombo
{
	// We don't want to save in IB...
}

- (void)_loadKeyCombo
{
	// ...and neither load the combo.
}

@end