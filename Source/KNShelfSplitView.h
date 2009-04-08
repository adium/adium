/*

BSD License

Copyright (c) 2006, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/



@interface KNShelfSplitView : NSView {
	IBOutlet NSView *			shelfView;
	IBOutlet NSView *			contentView;
	IBOutlet id					delegate;
	IBOutlet id					target;
	SEL							action;
	
	NSString *					autosaveName;
	NSImage *					actionButtonImage;
	NSImage *					contextButtonImage;
	NSColor *					shelfBackgroundColor;
	CGFloat						currentShelfWidth;
	CGFloat						prevShelfWidthBeforeDoubleClick;
	BOOL						isShelfVisible;
	NSMenu *					contextButtonMenu;
	
	NSRect						controlRect;
	BOOL						shouldDrawActionButton;
	NSRect						actionButtonRect;
	BOOL						shouldDrawContextButton;
	NSRect						contextButtonRect;
	NSRect						resizeThumbRect;
	NSRect						resizeBarRect;
	NSInteger							activeControlPart;
	BOOL						shouldHilite;
	
	BOOL						delegateHasValidateWidth;
	BOOL						delegateHasContextMenu;
	
	BOOL						drawLine;
	BOOL						shelfOnRight;
	
	NSString	*stringValue;
	NSAttributedString *attributedStringValue;
	CGFloat		stringHeight;
	
	NSImage		*background;
	NSSize		backgroundSize;
}

-(IBAction)toggleShelf:(id)sender;

-(id)initWithFrame:(NSRect)aFrame shelfView:(NSView *)aShelfView contentView:(NSView *)aContentView;

-(void)setDelegate:(id)aDelegate;
-(id)delegate;
-(void)setTarget:(id)aTarget;
-(id)target;
-(void)setAction:(SEL)aSelector;
-(SEL)action;

-(void)setShelfView:(NSView *)aView;
-(NSView *)shelfView;
-(void)setContentView:(NSView *)aView;
-(NSView *)contentView;

-(void)setShelfOnRight:(BOOL)inRight;
-(BOOL)shelfOnRight;

-(void)setDrawShelfLine:(BOOL)inDraw;
-(BOOL)drawShelfLine;

-(void)setShelfWidth:(CGFloat)aWidth;
-(CGFloat)shelfWidth;

-(BOOL)isShelfVisible;
-(void)setShelfIsVisible:(BOOL)visible;

-(void)setAutosaveName:(NSString *)aName;
-(NSString *)autosaveName;


-(void)setActionButtonImage:(NSImage *)anImage;
-(NSImage *)actionButtonImage;
-(void)setContextButtonImage:(NSImage *)anImage;
-(NSImage *)contextButtonImage;
-(void)setShelfBackgroundColor:(NSColor *)aColor;
-(NSColor *)shelfBackgroundColor;


-(void)recalculateSizes;
-(void)drawControlBackgroundInRect:(NSRect)aRect active:(BOOL)isActive;

- (void)setResizeThumbStringValue:(NSString *)inString;


@end

@interface NSObject (KNShelfSplitViewDelegate)
// These are all optional.
-(CGFloat)shelfSplitView:(KNShelfSplitView *)shelfSplitView validateWidth:(CGFloat)proposedWidth;
-(void)splitViewDidHaveResizeDoubleClick:(KNShelfSplitView *)shelfSplitView;
-(NSMenu *)contextMenuForShelfSplitView:(KNShelfSplitView *)shelfSplitView;
@end
