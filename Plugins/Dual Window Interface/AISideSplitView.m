#import "AISideSplitView.h"
#import <AIUtilities/AISplitView.h>

@implementation AISideSplitView

- (CGFloat) dividerThickness
{
	return .50;
}

- (void)drawDividerInRect:(NSRect)aRect
{
	[[NSColor colorWithCalibratedWhite:0.65 alpha:1.] set];
	NSRectFill(aRect);	
}	

@end
