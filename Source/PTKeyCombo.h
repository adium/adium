//
//  PTKeyCombo.h
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//


@interface PTKeyCombo : NSObject <NSCopying>
{
	int	mKeyCode;
	unsigned int	mModifiers;
}

+ (id)clearKeyCombo;
+ (id)keyComboWithKeyCode: (int)keyCode modifiers: (unsigned int)modifiers;
- (id)initWithKeyCode: (int)keyCode modifiers: (unsigned int)modifiers;

- (id)initWithPlistRepresentation: (id)plist;
- (id)plistRepresentation;

- (BOOL)isEqual: (PTKeyCombo*)combo;

- (int)keyCode;
- (unsigned int)modifiers;

- (BOOL)isClearCombo;
- (BOOL)isValidHotKeyCombo;

@end
