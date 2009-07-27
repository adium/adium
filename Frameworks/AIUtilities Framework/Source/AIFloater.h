//
//  AIFloater.h
//  Adium
//
//  Created by Evan Schoenberg on Wed Oct 08 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @class AIFloater
 * @brief A programtically movable, fadable <tt>NSImage</tt> display class
 *
 * <tt>AIFloater</tt> allows for the display of an <tt>NSImage</tt>, including an animating one, anywhere on the screen.  The image can be easily moved programatically and will fade into and out of view as requested. 
 */
@interface AIFloater : NSObject {
    NSImageView			*staticView;
    NSPanel				*panel;
    BOOL                windowIsVisible;
    NSViewAnimation     *fadeAnimation;
    float               maxOpacity;
}

/*!
 * @brief Create an <tt>AIFloater</tt>.  
 *
 * It will handle releasing itself when closed; it need not be retained by the caller.
 */
+ (id)floaterWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask;

/*!
 * Position the float at a specified point
 */
- (void)moveFloaterToPoint:(NSPoint)inPoint;

/*!
 * Close the floater.  This will also release it.
 */
- (IBAction)close:(id)sender;

/*!
 * @brief Set the image the floater displays.
 *
 * This <tt>NSImage</tt> will be displayed at its full size, animating if appropriate.
 *
 * @param inImage The image to display
 */
- (void)setImage:(NSImage *)inImage;

/*!
 * Return the image the floater displays
 *
 * @result The image
 */
- (NSImage *)image;

/*!
 * @brief Set the visibility of the image, optionally animating in/out of view
 *
 * @param inVisible YES if the image should be shown on screen; NO if it should not
 * @param animate If YES and inVisibile is the opposite of the current visibility, the image will fade into/out of view by changing its opacity over time towards its maximum (to fade in) or towards 0 (to fade out).
 */
- (void)setVisible:(BOOL)inVisible animate:(BOOL)animate;

/*!
 * @brief Set the maximum opacity of the floater
 *
 * The floater will never exceed this opacity; it will be shown at it when visible and will fade to/from it if animating into/out of view.
 *
 * @param inMaxOpacity The maximum opacity
 */
- (void)setMaxOpacity:(float)inMaxOpacity;

//- (void)endFloater;

@end
