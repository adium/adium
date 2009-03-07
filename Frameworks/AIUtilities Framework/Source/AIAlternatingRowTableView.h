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

/*!
 * @class AIAlternatingRowTableView
 * @brief An <tt>NSTableView</tt> subclass supporting gradient selection and notification of a delete keypress.
 *
 * The name is currently AIAlternatingRowTableView for Adium legacy regions. This class should be renamed.
 *
 */
@interface AIAlternatingRowTableView : NSTableView {
	BOOL	acceptsFirstMouse;
	BOOL	drawsGradientSelection;
}

@property (readwrite, nonatomic) BOOL acceptsFirstMouse;

@property (readwrite, nonatomic) BOOL drawsGradientSelection;

@end

@interface NSObject (AITableViewDelegateDeleteSupport)
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView;
@end


@interface NSObject (AITableViewDelegateMenuSupport)
- (NSMenu *)tableView:(NSTableView *)inTableView menuForEvent:(NSEvent *)theEvent;
@end
