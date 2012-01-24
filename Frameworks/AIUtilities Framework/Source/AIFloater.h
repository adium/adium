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

#import <Foundation/Foundation.h>

/*!
 * @class AIFloater
 * @brief A programtically movable, fadable <tt>NSImage</tt> display class
 *
 * <tt>AIFloater</tt> allows for the display of an <tt>NSImage</tt>, including an animating one, anywhere on the screen.
 * The image can be easily moved programatically and will fade into and out of view as requested. 
 */
@interface AIFloater : NSObject {
    NSImageView		*staticView;
    NSPanel			*panel;
    BOOL			windowIsVisible;
    NSViewAnimation	*fadeAnimation;
    CGFloat			maxOpacity;
}

/*!
 * @brief Create an <tt>AIFloater</tt>.  
 *
 * It will handle releasing itself when closed; it need not be retained by the caller.
 */
+ (id)newFloaterWithImage:(NSImage *)inImage styleMask:(unsigned int)styleMask;

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
- (void)setMaxOpacity:(CGFloat)inMaxOpacity;

//- (void)endFloater;

@end
