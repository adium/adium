//
//  AIInfoInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/16/08.
//  Copyright 2008 The Adium Team. All rights reserved.
//

#import "AIContactInfoContentController.h"
#import <Adium/AIContactObserverManager.h>

@class AIContactInfoImageViewWithImagePicker, AIDelayedTextField;

@interface AIInfoInspectorPane : NSObject <AIContentInspectorPane, AIListObjectObserver> {	
	
	AIListObject											*displayedObject;
	IBOutlet NSView									*inspectorContentView;

	IBOutlet AIContactInfoImageViewWithImagePicker	*userIcon;
	IBOutlet NSImageView							*statusImage;
	IBOutlet NSImageView							*serviceImage;
	
	IBOutlet NSTextField							*aliasLabel;
	IBOutlet AIDelayedTextField						*contactAlias;
	
	IBOutlet NSTextField							*accountName;
	
	IBOutlet NSTextView								*profileView;
	
	IBOutlet NSProgressIndicator					*profileProgress;
}

//Methods from AIContentInspectorPane protocol defined in AIContactInfoInspectorController.h
-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

- (IBAction)setAlias:(id)sender;

//Method from AIListObjectObserver protocol defined in AIContactControllerProtocol.h
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;

@end
