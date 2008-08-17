//
//  AIEmbossedTextField.m
//  Adium
//
//  Created by Colin Barrett on Fri Jul 11 2003.
//

#import "AIEmbossedTextField.h"
#import "AIWindowAdditions.h"

@implementation AIEmbossedTextField

- (void)drawRect:(NSRect)inRect
{
	if ([[self window] isTextured]) {
		NSFont			*font = [NSFont boldSystemFontOfSize:[[self font] pointSize]];
		NSRect			 bounds = [self bounds];
		NSDictionary	*attributes;
		NSColor			*textColor;

		//Disable sub-pixel rendering.  It looks horrible with embossed text
		CGContextSetShouldSmoothFonts([[NSGraphicsContext currentContext] graphicsPort], 0);
    
		//
		textColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.4];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			textColor, NSForegroundColorAttributeName,
			font, NSFontAttributeName, nil];

		[[self stringValue] drawInRect:NSOffsetRect(bounds, +2, +1) withAttributes:attributes];

		textColor = [NSColor colorWithCalibratedWhite:0.16 alpha:1.0];
		attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			textColor, NSForegroundColorAttributeName,
			font, NSFontAttributeName,
			nil];

		[[self stringValue] drawInRect:NSOffsetRect(bounds, +2, 0) withAttributes:attributes];
	} else {
		[super drawRect:inRect];
	}
}

@end
