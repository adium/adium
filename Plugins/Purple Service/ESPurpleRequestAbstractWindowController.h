//
//  ESPurpleRequestAbstractWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 9/22/05.
//

#import <Adium/AIWindowController.h>

@interface ESPurpleRequestAbstractWindowController : AIWindowController {
	BOOL						windowIsClosing;
}

- (void)purpleRequestClose;

@end
