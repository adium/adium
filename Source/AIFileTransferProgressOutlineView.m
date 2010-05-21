//
//  AIFileTransferProgressOutlineView.m
//  Adium
//
//  Created by Evan Schoenberg on 3/13/07.
//

#import "AIFileTransferProgressOutlineView.h"
#import "ESFileTransferProgressRow.h"
#import "ESFileTransferProgressView.h"

@implementation AIFileTransferProgressOutlineView
- (void)keyDown:(NSEvent *)theEvent
{
	NSString *charactersIgnoringModifiers = [theEvent charactersIgnoringModifiers];
	
	if ([charactersIgnoringModifiers length]) {
		unichar		 inChar = [charactersIgnoringModifiers characterAtIndex:0];
		
		if (inChar == NSLeftArrowFunctionKey) {
			[(ESFileTransferProgressView *)[(ESFileTransferProgressRow *)[self itemAtRow:[self selectedRow]] view] setShowsDetails:NO];
		} else if (inChar == NSRightArrowFunctionKey) {
			[(ESFileTransferProgressView *)[(ESFileTransferProgressRow *)[self itemAtRow:[self selectedRow]] view] setShowsDetails:YES];
		} else {
			[super keyDown:theEvent];
		}
	} else {
		[super keyDown:theEvent];
	}
}


@end
