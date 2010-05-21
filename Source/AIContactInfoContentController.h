//
//  AIContactInfoContentController.h
//  Adium
//
//  Created by Elliott Harris on 1/13/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import <AddressBook/ABPeoplePickerView.h>

@class AIListObject;

@protocol AIContentInspectorPane
-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;
@end

@interface AIContactInfoContentController : NSObject {
	NSArray		*loadedPanes;
}

+ (AIContactInfoContentController *)defaultInfoContentController;
- (id)initWithContentPanes:(NSArray *)contentPanes;

+ (NSArray *)defaultPanes;

- (NSArray *)loadedPanes;
- (void)loadContentPanes:(NSArray *)contentPanes;

//Segmented Control action
-(IBAction)segmentSelected:(id)sender;

@end
