//
//  AIObjectSelectionPopUpButton.h
//  AIUtilities.framework
//
//  Created by Adam Iser on 6/17/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define OBJECT_SELECTION_CUSTOM_TITLE		AILocalizedStringFromTableInBundle(@"Custom...", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)

@interface AIObjectSelectionPopUpButton : NSPopUpButton {
	NSArray		*availableValues;
	id			customValue;
	NSMenuItem	*customMenuItem;
}

- (void)setPresetValues:(NSArray *)inValues;
- (void)setObjectValue:(id)inValue;
- (id)objectValue;
- (void)setCustomValue:(id)inValue;
- (id)customValue;

//For subclasses
- (void)_initObjectSelectionPopUpButton;
- (BOOL)value:(id)valueA isEqualTo:(id)valueB;
- (void)updateMenuItem:(NSMenuItem *)menuItem forValue:(id)inValue;

@end
