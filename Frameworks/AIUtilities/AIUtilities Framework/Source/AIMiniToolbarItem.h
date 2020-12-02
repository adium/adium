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

@class AIMiniToolbarItem;

@protocol AIMiniToolbarItemDelegate
- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects;
@end

@interface AIMiniToolbarItem : NSObject {
    NSObject<AIMiniToolbarItemDelegate>	*delegate;

    NSString		*identifier;
    NSString		*paletteLabel;
    NSString		*toolTip;

    BOOL		enabled;
    NSImage		*image;
    id			target;
    SEL			action;
    NSView		*view;
    
    
    NSDictionary	*objects;
    
    BOOL		allowsDuplicatesInToolbar;
    BOOL		flexibleWidth;

}

- (id)initWithIdentifier:(NSString *)inIdentifier;
- (NSString *)identifier;
- (void)setPaletteLabel:(NSString *)inPaletteLabel;
- (NSString *)paletteLabel;
- (void)setToolTip:(NSString *)inToolTip;
- (NSString *)toolTip;
- (void)setTarget:(id)inTarget;
- (id)target;
- (void)setAction:(SEL)inAction;
- (SEL)action;
- (void)setEnabled:(BOOL)inEnabled;
- (BOOL)isEnabled;
- (void)setImage:(NSImage *)inImage;
- (NSImage *)image;
- (void)setAllowsDuplicatesInToolbar:(BOOL)inValue;
- (BOOL)allowsDuplicatesInToolbar;
- (void)setView:(NSView *)inView;
- (NSView *)view;
- (void)setDelegate:(id <AIMiniToolbarItemDelegate>)inDelegate;
- (id <AIMiniToolbarItemDelegate>)delegate;
- (void)setFlexibleWidth:(BOOL)inflexibleWidth;
- (BOOL)flexibleWidth;

- (BOOL)configureForObjects:(NSDictionary *)inObjects;
- (NSDictionary *)configurationObjects;

@end
