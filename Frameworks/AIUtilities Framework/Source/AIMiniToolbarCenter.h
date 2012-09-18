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

#define MINI_TOOLBAR_ITEM_DRAGTYPE	@"AIMiniToolbarItem"
#define MINI_TOOLBAR_TYPE		@"AIMiniToolbarType"
#define MINI_TOOLBAR_SOURCE		@"AIMiniToolbarSource"

#define AIMiniToolbar_ItemsChanged	@"AIMiniToolbar_ItemsChanged"
#define AIMiniToolbar_RefreshItem	@"AIMiniToolbar_RefreshItem"

@class AIMiniToolbarItem, AIMiniToolbar, AIMiniToolbarCustomizeController;

@interface AIMiniToolbarCenter : NSObject {

    NSMutableDictionary			*toolbarDict;
    NSMutableDictionary			*itemDict;

    AIMiniToolbarCustomizeController	*customizeController;
    NSString				*customizeIdentifier;
}

+ (id)defaultCenter;
- (NSArray *)itemsForToolbar:(NSString *)inType;
- (void)setItems:(NSArray *)inItems forToolbar:(NSString *)inType;
- (void)registerItem:(AIMiniToolbarItem *)inItem;
- (AIMiniToolbarItem *)itemWithIdentifier:(NSString *)inIdentifier;
- (NSArray *)allItems;

- (IBAction)customizeToolbar:(AIMiniToolbar *)toolbar;
- (BOOL)customizing:(AIMiniToolbar *)toolbar;
- (IBAction)endCustomization:(AIMiniToolbar *)toolbar;
- (void)customizationDidEnd:(AIMiniToolbar *)inToolbar;

@end
