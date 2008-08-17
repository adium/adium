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
-(IBAction) linkifyTextView:(id)sender {
	[NSThread	detachNewThreadSelector:@selector(performLinkification:)
							   toTarget:self
							 withObject:linkifyView];
	[NSThread	detachNewThreadSelector:@selector(performLinkification:)
							   toTarget:self
							 withObject:otherView];
}

-(void) performLinkification:(NSTextView *)inView
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	AHHyperlinkScanner	*scanner = [AHHyperlinkScanner hyperlinkScannerWithAttributedString:[inView textStorage]];
	[[inView textStorage] setAttributedString:[scanner linkifiedString]];
	[pool release];
}
@end
