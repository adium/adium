//
//  AIContactListNameButton.h
//  Adium
//
//  Created by Evan Schoenberg on 2/23/06.
//

#import "AIHoveringPopUpButton.h"

@interface AIContactListNameButton : AIHoveringPopUpButton <NSTextFieldDelegate> {
	NSTextField	*textField_editor;
	id			editTarget;
	SEL			editSelector;
	id			editUserInfo;
}

- (void)editNameStartingWithString:(NSString *)startingString notifyingTarget:(id)inTarget selector:(SEL)inSelector userInfo:(id)inUserInfo;

@end
