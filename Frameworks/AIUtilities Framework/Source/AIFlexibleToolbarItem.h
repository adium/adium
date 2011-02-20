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

@class AIFlexibleToolbarItem;

/*!
 * @class AIFlexibleToolbarItem
 * @brief Toolbar item with a validation delegate
 *
 * Normally, an NSToolbarItem does not validate if it has a custom view. <tt>AIFlexibleToolbarItem</tt> sends its delegate validate methods regardless of its configuration, allowing validation when using custom views.  Adium uses this, for example, to change the image on a toolbar button when conditions change in its window.
 *
 * @see <tt><a href="category_n_s_object(_e_s_flexible_toolbar_item_delegate).html">NSObject(AIFlexibleToolbarItemDelegate)</a></tt>
 */
@interface AIFlexibleToolbarItem : NSToolbarItem {
	id	validationDelegate;
}

/*!
 * @brief Set the validation delegate
 *
 * Set the validation delegate, which must implement the methods in <tt>AIFlexibleToolbarItemDelegate</tt> and will receive validation messages.
 * @param inDelegate The delegate
 */
- (void)setValidationDelegate:(id)inDelegate;

@end

/*!
 * @protocol AIFlexibleToolbarItemDelegate
 * @brief Required protocol for an AIFlexibleToolbarItem's validation delegate
 *
 * The delegate is sent - (void)validateFlexibleToolbarItem:(AIFlexibleToolbarItem *)toolbarItem, which must be efficient
 */
@protocol AIFlexibleToolbarItemDelegate
/*!
 * @brief Sent when the toolbar item is validated
 *
 * @param toolbarItem The toolbar item
 */
- (void)validateFlexibleToolbarItem:(AIFlexibleToolbarItem *)toolbarItem;
@end

