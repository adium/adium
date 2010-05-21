#import "ESPurpleJabberAccount.h"

@class AMPurpleJabberAdHocCommand;
@protocol AMPurpleJabberAdHocServerDelegate;

@interface AMPurpleJabberAdHocServer : NSObject {
	ESPurpleJabberAccount *account;
	NSMutableDictionary *commands;
}

- (id)initWithAccount:(ESPurpleJabberAccount *)_account;
- (void)addCommand:(NSString *)node delegate:(id<AMPurpleJabberAdHocServerDelegate>)delegate name:(NSString *)name;
- (ESPurpleJabberAccount *)account;

@end

@protocol AMPurpleJabberAdHocServerDelegate <NSObject>
@optional
- (void)adHocServer:(AMPurpleJabberAdHocServer *)server executeCommand:(AMPurpleJabberAdHocCommand *)command;
@end

