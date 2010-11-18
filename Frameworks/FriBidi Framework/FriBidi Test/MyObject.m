#import "MyObject.h"
#import <FriBidi/NSString-FBAdditions.h>

@implementation MyObject

- (IBAction)calculate:(id)sender
{
	NSWritingDirection dir = [[inputField stringValue] baseWritingDirection];
	
	if (dir == NSWritingDirectionNatural)
		dir = [NSParagraphStyle defaultWritingDirectionForLanguage:nil];
	
	if (dir == NSWritingDirectionLeftToRight)
		[directionField setStringValue:@"LTR"];
	else if (dir == NSWritingDirectionRightToLeft)
		[directionField setStringValue:@"RTL"];
}

@end
