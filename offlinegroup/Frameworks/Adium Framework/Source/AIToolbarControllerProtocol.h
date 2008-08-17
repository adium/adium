/*
 *  AIToolbarControllerProtocol.h
 *  Adium
 *
 *  Created by Evan Schoenberg on 7/31/06.
 *
 */

#import <Adium/AIControllerProtocol.h>

@protocol AIToolbarController <AIController>
- (void)registerToolbarItem:(NSToolbarItem *)item forToolbarType:(NSString *)type;
- (void)unregisterToolbarItem:(NSToolbarItem *)item forToolbarType:(NSString *)type;
- (NSDictionary *)toolbarItemsForToolbarTypes:(NSArray *)types;
@end
