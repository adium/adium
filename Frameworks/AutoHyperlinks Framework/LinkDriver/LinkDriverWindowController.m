//
//  LinkDriverWindowController.m
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 5/15/08.
//

#import "LinkDriverWindowController.h"

#define	SCANNER_KEY @"linkScanner"
#define VIEW_KEY @"linkView"

@implementation LinkDriverWindowController
-(void) performLinkification:(NSTextView *)inView
{
	@autoreleasepool {
		AHHyperlinkScanner	*scanner = [AHHyperlinkScanner hyperlinkScannerWithAttributedString:[inView textStorage]];
		[[inView textStorage] setAttributedString:[scanner linkifiedString]];
	}
}

-(IBAction) linkifyTextView:(id)sender {
	[NSThread	detachNewThreadSelector:@selector(performLinkification:)
							   toTarget:self
							 withObject:linkifyView];
	[NSThread	detachNewThreadSelector:@selector(performLinkification:)
							   toTarget:self
							 withObject:otherView];
}
@end
