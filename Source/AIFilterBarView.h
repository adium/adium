//
//  AIFilterBarView.h
//  Adium
//
//  Created by Zachary West on 2009-04-02.
//

@interface AIFilterBarView : NSView {
	NSColor *backgroundColor;
	BOOL	backgroundIsRounded;
	
	BOOL drawBackground;
}

@property (readwrite, nonatomic, retain) NSColor *backgroundColor;
@property (readwrite, nonatomic) BOOL backgroundIsRounded;
@property (readwrite, nonatomic) BOOL drawBackground;

@end
