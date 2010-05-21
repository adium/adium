#import "AISideSplitView.h"
#import <AIUtilities/AISplitView.h>

@implementation AISideSplitView

- (CGFloat) dividerThickness
{
	return .50f;
}

- (void)drawDividerInRect:(NSRect)aRect
{
	[[NSColor colorWithCalibratedWhite:0.65f alpha:1.0f] set];
	NSRectFill(aRect);	
}	

@end
