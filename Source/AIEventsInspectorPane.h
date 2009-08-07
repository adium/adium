//
//  AIEventsInspectorPane.h
//  Adium
//
//  Created by Elliott Harris on 1/17/08.
//
#import "AIContactInfoContentController.h"

@class ESContactAlertsViewController;

@interface AIEventsInspectorPane : NSObject <AIContentInspectorPane> {
	AIListObject						*displayedObject;
	
	IBOutlet NSView								*inspectorContentView;
	IBOutlet ESContactAlertsViewController		*alertsController;
	//Other IBOutlets here
}

-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

@end
