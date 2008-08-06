//
//  PTKeyCombo.m
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//

#import "PTKeyCombo.h"

@implementation PTKeyCombo

+ (id)clearKeyCombo
{
	return [self keyComboWithKeyCode: -1 modifiers:0];
}

+ (id)keyComboWithKeyCode: (int)keyCode modifiers: (unsigned int)modifiers
{
	return [[[self alloc] initWithKeyCode: keyCode modifiers: modifiers] autorelease];
}

- (id)initWithKeyCode: (int)keyCode modifiers: (unsigned int)modifiers
{
	self = [super init];
	
	if( self )
	{
		mKeyCode = keyCode;
		mModifiers = modifiers;
	}
	
	return self;
}

- (id)initWithPlistRepresentation: (id)plist
{
	int keyCode, modifiers;
	
	if( !plist || ![plist count] )
	{
		keyCode = -1;
		modifiers = 0;
	}
	else
	{
		keyCode = [[plist objectForKey: @"keyCode"] intValue];
		if( keyCode < 0 ) keyCode = -1;
	
		modifiers = [[plist objectForKey: @"modifiers"] unsignedIntValue];
	}

	return [self initWithKeyCode: keyCode modifiers: modifiers];
}

- (id)plistRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt: [self keyCode]], @"keyCode",
				[NSNumber numberWithUnsignedInt: [self modifiers]], @"modifiers",
				nil];
}

- (id)copyWithZone:(NSZone*)zone;
{
	return [self retain];
}

- (BOOL)isEqual: (PTKeyCombo*)combo
{
	return	[self keyCode] == [combo keyCode] &&
			[self modifiers] == [combo modifiers];
}

#pragma mark -

- (int)keyCode
{
	return mKeyCode;
}

- (unsigned int)modifiers
{
	return mModifiers;
}

- (BOOL)isValidHotKeyCombo
{
	return mKeyCode >= 0;
}

- (BOOL)isClearCombo
{
	return mKeyCode == -1;
}

@end
