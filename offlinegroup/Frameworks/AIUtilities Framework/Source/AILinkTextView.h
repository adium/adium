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

@class AILinkTrackingController, NSTextView;

/*!
 * @class AILinkTextView
 * @brief A text view that supports link tracking and clicking
 *
 * A text view that supports link tracking (displaying the system link cursor when hovering over a link, and optionally showing a tooltip when the link's display text differs from the URL to which it links) and clicking
 */
@interface AILinkTextView : NSTextView {
    AILinkTrackingController		*linkTrackingController;
}

/*!
 * @brief Set if links should show a tooltip when hovered
 *
 * Set if links should show a tooltip when hovered if applicable.  A link will only show a tooltip if the displayed text ("Adium") differs from the link itself ("www.adiumx.com").
 * @param inShowTooltip YES if tooltips should be shown.
 */
- (void)setShowTooltip:(BOOL)inShowTooltip;

@end
