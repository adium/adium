/* AINewBookmarkWindowController */

#import <Adium/AIWindowController.h>

@class AIChat, AIListGroup;

@interface AINewBookmarkWindowController : AIWindowController {
    IBOutlet NSPopUpButton	*popUp_group;
    IBOutlet NSTextField	*textField_name;
	
	IBOutlet NSTextField	*label_name;
	IBOutlet NSTextField	*label_group;
	IBOutlet NSButton		*button_add;
	IBOutlet NSButton		*button_cancel;
	
	id			target;
	AIChat		*chat;
}

+ (AINewBookmarkWindowController *)promptForNewBookmarkForChat:(AIChat *)inChat
													  onWindow:(NSWindow*)parentWindow
											   notifyingTarget:(id)inTarget;

- (IBAction)add:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@interface NSObject (AINewBookmarkWindowControllerTarget)
- (void)createBookmarkForChat:(AIChat *)chat withName:(NSString *)name inGroup:(AIListGroup *)group;
@end
