//
//  AINoisyTableColumn.m
//  Adium
//
//  Created by Evan Schoenberg on 7/6/06.
//

#import "AINoisyTableColumn.h"

/*!
 * @class AINoisyTableColumn
 * @brief A table column which posts NSTableViewColumnDidResizeNotification continuously as it resizes rather than when it finishes resizing
 */
@implementation AINoisyTableColumn

- (void)setWidth:(CGFloat)newWidth
{	
	CGFloat width = [self width]; 

	[super setWidth:newWidth];
	
	if (width != newWidth) {
		[[NSNotificationCenter defaultCenter] postNotificationName:NSTableViewColumnDidResizeNotification
															object:[self tableView]
														  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
															  self, @"NSTableColumn",
															  [NSNumber numberWithDouble:width], @"NSOldWidth",
															  nil]];
	}
}

@end
