/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIPrettyView.h"
#import <AIUtilities/AIBezierPathAdditions.h>
#import <WebKit/DOMCSSStyleDeclaration.h>
#import "ESWebView.h"

@implementation AIPrettyView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	
    ESWebView *webView = [[[messageView contentView] subviews] objectAtIndex:0];
    DOMElement *box = [[webView mainFrameDocument] getElementById:@"inputBox"];
    
    if (box) {
        
        double width = box.offsetWidth;
        double height = box.offsetHeight;
        double originX = 1 + box.offsetLeft;
        
        DOMElement *el = box;
        
        double originY = 0;
        
        while (el) {
            originY += el.offsetTop;
            
            el = [el offsetParent];
        }
        
        originY = (1 + [[webView mainFrame] frameView].frame.size.height - originY) - height;
        
        [[self enclosingScrollView] setFrame:NSMakeRect(originX, originY, width, height)];
        
        NSLog(@"Setting frame: %@", NSStringFromRect(NSMakeRect(originX, originY, width, height)));
    }
    
    NSBezierPath *bp = [NSBezierPath bezierPath];
	[bp setLineWidth:2.0];
	
	[bp moveToPoint:NSMakePoint(0, self.frame.size.height)];
	[bp lineToPoint:NSMakePoint(0, 0)];
	[bp lineToPoint:NSMakePoint(self.frame.size.width, 0)];
	[bp lineToPoint:NSMakePoint(self.frame.size.width, self.frame.size.height)];
	
	[[NSColor colorWithCalibratedWhite:0.745 alpha:1.0] setStroke];
	
	[bp stroke];
	
	bp = [NSBezierPath bezierPath];
	[bp setLineWidth:2.0];
	
	[bp moveToPoint:NSMakePoint(0, self.frame.size.height)];
	[bp lineToPoint:NSMakePoint(self.frame.size.width, self.frame.size.height)];
	
	[[NSColor colorWithCalibratedWhite:0.557 alpha:1.0] setStroke];
	
	[bp stroke];
}

- (void)mouseDown:(NSEvent *)event
{
	[[entryField window] makeFirstResponder:entryField];
}


@end
