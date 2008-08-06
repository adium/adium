/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

@class AIFlexibleLink;

@interface AILinkTrackingController : NSObject {
    NSView				*controlView;			//The view we're tracking links in
    NSMutableArray		*linkArray;				//Array of active flexible links

    AIFlexibleLink		*hoveredLink;			//The link currently being hovered
    NSString			*hoveredString;	
    BOOL				mouseOverLink;			//Yes if the cursor is over one of our links
    BOOL				showTooltip;			//Yes if we want to display the tooltip over a hovered link

    //The text system of the view we're tracking links for
    NSTextStorage 		*textStorage;
    NSLayoutManager		*layoutManager;
    NSTextContainer		*textContainer;
}

+ (id)linkTrackingControllerForView:(NSView *)inControlView withTextStorage:(NSTextStorage *)inTextStorage layoutManager:(NSLayoutManager *)inLayoutManager textContainer:(NSTextContainer *)inTextContainer;
+ (id)linkTrackingControllerForTextView:(NSTextView *)inTextView;
- (void)trackLinksInRect:(NSRect)visibleRect withOffset:(NSPoint)offset;
- (BOOL)handleMouseDown:(NSEvent *)theEvent withOffset:(NSPoint)offset;
- (void)setShowTooltip:(BOOL)inShowTooltip;
- (NSArray *)menuItemsForEvent:(NSEvent *)theEvent withOffset:(NSPoint)offset;

@end
