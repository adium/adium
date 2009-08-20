//
//  AIColorPickerSliders.m
//  Adium
//
//  Created by Evan Schoenberg on 9/25/05.
//

#import <Adium/AIColorPickerSliders.h>
#import <objc/objc-class.h>

/*!
 * @class AIColorPickerSliders
 * @brief Poses as NSColorPickerSliders to remove the key equivalents from its sliderModePopUp NSPopUpButton's menu
 *
 * In 10.3 through 10.5 (at least), sliderModePopUp provides 4 menu items, each of which corresponds to a particular slider mode
 * and is associated with a shortcut, command-1 through command-4.  Adium uses command-1 through command-4 to switch
 * to the first through fourth open chats. Without this class, after the color picker is opened and the slider view
 * is displayed, the next time Adium reconfigures shortcut keys it will be unable to use these 4 as the color picker
 * not only uses them but continues to use them for the rest of the application session.
 *
 * They are not stolen away as soon as the panel is opened, but rather the next time Adium reconfigures which occurs
 * whenever chats are opened, closed, or reorganized. Therefore, as long as we remove the key equivalents before this
 * happens, Adium can continue to use the shortcuts.
 */
@implementation AIColorPickerSliders

/* 
* @brief Load
 *
 * Install ourself to intercept _setupProfileUI and thereby remove key equivalents for the menu items
 */
+ (void)load
{
	//Anything you can do, I can do better...
	method_exchangeImplementations(class_getInstanceMethod([NSColorPickerSliders class], @selector(_setupProfileUI)), class_getInstanceMethod(self, @selector(_setupProfileUI)));
}

/*!
 * @brief Called to finish setting up the UI
 *
 * sliderModePopUp's menu is populated sometime before this but after initWithPickerMask:colorPanel:
 * We want to remove the key equivalents on that menu.
 */
- (void)_setupProfileUI
{
	//Must be sure to the original implementation
	method_invoke(self, class_getInstanceMethod([AIColorPickerSliders class], @selector(_setupProfileUI)));

	if (sliderModePopUp && [sliderModePopUp isKindOfClass:[NSPopUpButton class]]) {
		NSMenu			*menu = [sliderModePopUp menu];
		NSMenuItem		*menuItem;
		NSEnumerator	*enumerator;

		enumerator = [[menu itemArray] objectEnumerator];
		while ((menuItem = [enumerator nextObject])) {
			//Remove the key equivalent
			[menuItem setKeyEquivalent:@""];
		}
	}
}

@end
