//AIBorderlessWindow.h based largely off sample code in CustomWindow.m from Apple's "RoundTransparentWindow" sample project.

#import <AIUtilities/AIDockingWindow.h>

@interface AIBorderlessWindow : NSWindow
{
    //This point is used in dragging to mark the initial click location
    NSPoint originalMouseLocation;

	NSRect	windowFrame;

	BOOL	docked;
	BOOL	inLeftMouseEvent;
	BOOL	moveable;
}

- (void)setMoveable:(BOOL)inMoveable;

@end
