//
//  SGKeyCombo.h
//  SGHotKeyCenter
//
//  Created by Justin Williams on 7/26/09.
//  Copyright 2009 Second Gear. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SGKeyCombo : NSObject {
  signed short keyCode;
  NSUInteger modifiers;
}

@property (nonatomic, assign) signed short keyCode;
@property (nonatomic, assign) NSUInteger modifiers;

+ (id)clearKeyCombo;
+ (id)keyComboWithKeyCode:(signed short)theKeyCode modifiers:(NSUInteger)theModifiers;
- (id)initWithKeyCode:(signed short)theKeyCode modifiers:(NSUInteger)theModifiers;

- (id)initWithPlistRepresentation:(id)thePlist;
- (id)plistRepresentation;

- (BOOL)isEqual:(SGKeyCombo *)theCombo;

- (BOOL)isClearCombo;
- (BOOL)isValidHotKeyCombo;

@end

@interface SGKeyCombo (UserDisplayAdditions)
- (NSString *)description;
- (NSString *)keyCodeString;
- (NSUInteger)modifierMask;
@end
