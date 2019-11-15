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

#import <Adium/AIToolbar.h>
#import <objc/objc-class.h>

/*!
 * @class AIToolbar
 *
 * AIToolbar swizzles NSToolbar's -dealloc to fix what I consider a bug in Apple's implementation: 
 * NSToolbarDidRemoveItemNotification is not sent for the toolbar's items when the toolbar closes.
 *
 * AIToolbar sends this notification for each item so observers can balance any action taken via
 * the NSToolbarWillAddItemNotification notification.
 *
 * Unfortunately, it also posts the notification when the customization sheet closes, unpaired with an added
 * message, so watch out for that.
 */
@interface NSToolbar (AIPrivate)
- (void)_postWillDeallocToolbarNotifications;
- (void)deallocWithNotifications;
@end

@implementation AIToolbar
/* 
 * @brief Load
 *
 * Install ourself to intercept dealloc calls so we can post as items will be 'removed' by closing
 */
+ (void)load
{
	//Anything you can do, I can do better...
	method_exchangeImplementations(class_getInstanceMethod([NSToolbar class], @selector(dealloc)), class_getInstanceMethod(self, @selector(deallocWithNotifications)));
}

/*!
 * @brief Called before the toolbar deallocs
 */
- (void)deallocWithNotifications
{
	NSNotificationCenter	*defaultCenter = [NSNotificationCenter defaultCenter];

	/* Before proceeding, set our delegate to nil so we don't attempt to message it (it most likely
	 * is a window controller which will have already dealloced by the time we get here... braaaains.)
	 */
	[self setDelegate:nil];

	for(NSToolbarItem *item in [self items]) {
		[defaultCenter postNotificationName:NSToolbarDidRemoveItemNotification
									 object:self
								   userInfo:[NSDictionary dictionaryWithObject:item
																		forKey:@"item"]];
	}

	//call the unswizzled implementation now that we're done with our additions
    static void (*_deallocWithNotifications_method_invoke)(id, Method) = (void (*)(id, Method)) method_invoke;
	_deallocWithNotifications_method_invoke(self, class_getInstanceMethod([AIToolbar class], @selector(deallocWithNotifications)));
}

@end
