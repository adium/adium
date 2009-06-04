//
//  RAFBlockEditorPlugin.h
//  Adium
//
//  Created by Augie Fackler on 5/26/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIMenuControllerProtocol.h>
#import "RAFBlockEditorWindowController.h"

@interface RAFBlockEditorPlugin : AIPlugin {
	NSMenuItem  *blockEditorMenuItem;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (IBAction)showEditor:(id)sender;

@end
