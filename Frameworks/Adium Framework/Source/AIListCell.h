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

@class AIListObject, AIListOutlineView, AIAdium;

#define DROP_HIGHLIGHT_WIDTH_MARGIN 5.0
#define DROP_HIGHLIGHT_HEIGHT_MARGIN 1.0

@interface AIListCell : NSCell {
	AIListOutlineView	*controlView;
    AIListObject		*listObject;
    BOOL				isGroup;
	
	NSTextAlignment		textAlignment;
	int					labelFontHeight;
	
	int					topSpacing;
	int					bottomSpacing;
	int					topPadding;
	int					bottomPadding;

	int					leftPadding;
	int					rightPadding;
	int					leftSpacing;
	int					rightSpacing;
	
	int					indentation;

	NSColor				*textColor;
	NSColor				*invertedTextColor;
	
	NSFont				*font;
	
	BOOL				useAliasesAsRequested;
}

- (void)setListObject:(AIListObject *)inObject;
- (BOOL)isGroup;
- (void)setControlView:(AIListOutlineView *)inControlView;

//Display options 
- (void)setFont:(NSFont *)inFont;
- (NSFont *)font;
- (void)setTextAlignment:(NSTextAlignment)inAlignment;
- (NSTextAlignment)textAlignment;
- (void)setTextColor:(NSColor *)inColor;
- (NSColor *)textColor;
- (void)setInvertedTextColor:(NSColor *)inColor;
- (NSColor *)invertedTextColor;

//Cell sizing and padding
- (NSSize)cellSize;
- (int)cellWidth;
- (void)setSplitVerticalSpacing:(int)inSpacing;
- (void)setTopSpacing:(int)inSpacing;
- (int)topSpacing;
- (void)setBottomSpacing:(int)inSpacing;
- (int)bottomSpacing;
- (void)setLeftSpacing:(int)inSpacing;
- (int)leftSpacing;
- (void)setRightSpacing:(int)inSpacing;
- (int)rightSpacing;
- (void)setSplitVerticalPadding:(int)inPadding;
- (void)setTopPadding:(int)inPadding;
- (void)setBottomPadding:(int)inPadding;
- (int)topPadding;
- (int)bottomPadding;
- (void)setLeftPadding:(int)inPadding;
- (int)leftPadding;
- (void)setRightPadding:(int)inPadding;
- (int)rightPadding;

- (void)setIndentation:(int)inIndentation;
- (int)indentation;

//Drawing
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)_drawHighlightWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawSelectionWithFrame:(NSRect)rect;
- (void)drawBackgroundWithFrame:(NSRect)rect;
- (void)drawContentWithFrame:(NSRect)rect;
- (void)drawDropHighlightWithFrame:(NSRect)rect;
- (NSRect)drawDisplayNameWithFrame:(NSRect)inRect;
- (NSString *)labelString;
- (NSDictionary *)labelAttributes;
- (NSDictionary *)additionalLabelAttributes;
- (NSColor *)textColor;
- (BOOL)cellIsSelected;
- (BOOL)drawGridBehindCell;
- (NSColor *)backgroundColor;

- (BOOL)shouldShowAlias;

//Control over whether the cell will respect aliases and long display names
- (void)setUseAliasesAsRequested:(BOOL)flag;

@end
