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

#import "AIMessageEntryScrollView.h"
#import "ESWebView.h"

@implementation AIMessageEntryScrollView

- (id)init
{
    self = [super init];
    if (self) {
        [[self contentView] setDrawsBackground:NO];
        [[self contentView] setBackgroundColor:[NSColor clearColor]];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)move
{
    ESWebView *webView = [[[messageView contentView] subviews] objectAtIndex:0];
    DOMElement *box = [[webView mainFrameDocument] getElementById:@"inputBox"];
    
    if (box) {
        
        double width = box.offsetWidth;
        double height = (box.offsetHeight < 20 ? 20 : box.offsetHeight);
        double originX = 1 + box.offsetLeft;
        
        DOMElement *el = box;
        
        double originY = 0;
        
        while (el) {
            originY += el.offsetTop;
            
            el = [el offsetParent];
        }
        
        originY = (1 + [[webView mainFrame] frameView].frame.size.height - originY) - height;
        
        [self setFrame:NSMakeRect(originX, originY, width, height)];
        
        NSLog(@"Setting frame: %@", NSStringFromRect(NSMakeRect(originX, originY, width, height)));
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSLog(@"drawRect");
    [self move];
    [super drawRect:dirtyRect];
    
    NSBezierPath *bp = [NSBezierPath bezierPathWithRect:self.bounds];
    [[self backgroundColor] setFill];
    [bp fill];
    
    bp = [NSBezierPath bezierPath];
    
    NSShadow *internalShadow = [[NSShadow alloc] init];
    [internalShadow setShadowColor:[NSColor lightGrayColor]];
    [internalShadow setShadowBlurRadius:2.0];
    [internalShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    
    [internalShadow set];
    
	[bp setLineWidth:2.0];
	
	[bp moveToPoint:NSMakePoint(self.bounds.origin.x, self.bounds.origin.x + self.bounds.size.height)];
	[bp lineToPoint:NSMakePoint(self.bounds.origin.x, self.bounds.origin.y)];
	[bp lineToPoint:NSMakePoint(self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y)];
	[bp lineToPoint:NSMakePoint(self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y + self.bounds.size.height)];
	
	[[NSColor lightGrayColor] setStroke];
    
	[bp stroke];
	
	bp = [NSBezierPath bezierPath];
	[bp setLineWidth:2.0];
	
	[bp moveToPoint:NSMakePoint(self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height)];
	[bp lineToPoint:NSMakePoint(self.bounds.origin.x + self.bounds.size.width, self.bounds.origin.y + self.bounds.size.height)];
	
	[[NSColor lightGrayColor] setStroke];
	
	[bp stroke];
}

@end
