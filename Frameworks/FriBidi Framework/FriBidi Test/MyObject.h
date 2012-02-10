/* MyObject */

#import <Cocoa/Cocoa.h>

@interface MyObject : NSObject
{
    IBOutlet NSTextField *directionField;
    IBOutlet NSTextField *inputField;
}
- (IBAction)calculate:(id)sender;
@end
