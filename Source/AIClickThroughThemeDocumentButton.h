//
//  AIClickThroughThemeDocumentButton.h
//  Adium
//
//  Created by Evan Schoenberg on 12/26/05.
//

#import "NSThemeDocumentButton.h"

@interface AIClickThroughThemeDocumentButton : NSThemeDocumentButton {
    NSPoint originalMouseLocation;
	NSRect	windowFrame;
	BOOL	inLeftMouseEvent;
}

@end
