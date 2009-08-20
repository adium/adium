//
//  RBSplitViewPalette.h version 1.1.4
//  RBSplitView
//
//  Created by Rainer Brockerhoff on 24/09/2004.
//  Copyright 2004-2006 Rainer Brockerhoff.
//	Some Rights Reserved under the Creative Commons Attribution License, version 2.5, and/or the MIT License.
//

#import <InterfaceBuilder/InterfaceBuilder.h>
#import "RBSplitView.h"

// This is the main palette class.

@interface RBSplitViewPalette : IBPalette {
	IBOutlet NSImageView* splitImage;
	RBSplitView* splitView;
}
@end

// This class implements the RBSplitSubview attribute inspector.

@interface RBSplitSubviewInspector : IBInspector {
    IBOutlet NSButton* collapseButton;
    IBOutlet NSButton* adjustButton;
    IBOutlet NSForm* identifierValue;
    IBOutlet NSForm* minimumValue;
    IBOutlet NSForm* maximumValue;
    IBOutlet NSStepper* positionStepper;
    IBOutlet NSForm* positionValue;
    IBOutlet NSForm* tagValue;
	IBOutlet NSButton* currentMinButton;
	IBOutlet NSButton* currentMaxButton;
}
- (void)setSubview:(NSView*)subview withUndo:(NSUndoManager*)undo frame:(NSRect)frame andAutoresizingMask:(unsigned int)autoresizingMask;
@end

// This class implements the RBSplitSubview size inspector.

@interface RBSplitSubviewSizeInspector : IBInspector {
	IBOutlet NSForm* sizeValue;
	IBOutlet NSTextField* sizeLimits;
	IBOutlet NSButton* collapsedButton;
}
@end

// This class implements the RBSplitView attribute inspector.

@interface RBSplitViewInspector : IBInspector {
    IBOutlet NSForm* autosaveName;
    IBOutlet NSColorWell* backgroundWell;
    IBOutlet NSPopUpButton* dividerImage;
    IBOutlet NSTextField* dividerSize;
    IBOutlet NSButton* hiddenButton;
	IBOutlet NSButton* coupledButton;
	IBOutlet NSButton* useButton;
	IBOutlet NSForm* identifier;
    IBOutlet NSMatrix* orientation;
    IBOutlet NSForm* subviewCount;
    IBOutlet NSStepper* subviewStepper;
    IBOutlet NSForm* tagValue;
	IBOutlet NSTabView* tabView;
    IBOutlet NSButton* collapseButton;
    IBOutlet NSForm* identifierValue;
    IBOutlet NSForm* minimumValue;
    IBOutlet NSForm* maximumValue;
    IBOutlet NSStepper* positionStepper;
    IBOutlet NSForm* positionValue;
    IBOutlet NSForm* thicknessValue;
}
@end

// This category adds some functionality to RBSplitSubview to support Interface Builder stuff.

@interface RBSplitSubview (RBSSIBAdditions)
- (void)setIsCollapsed:(BOOL)status;
- (RBSplitView*)ibSplitView;
- (void)ibResetObjectInEditor:(NSView<IBEditors>*)viewEditor;
@end

// This category adds some functionality to RBSplitView to support Interface Builder stuff.

@interface RBSplitView (RBSVIBAdditions)
- (void)ibSetNumberOfSubviews:(unsigned)count;
- (BOOL)ibHandleMouseDown:(NSEvent*)theEvent in:(NSView<IBEditors>*)viewEditor;
- (void)ibRestoreState:(NSString*)string in:(NSView<IBEditors>*)viewEditor;
@end
