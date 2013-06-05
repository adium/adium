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

/*!
 * @class AIDelayedTextField
 * @brief Text field which groups changes, triggering its action after a period without changes
 *
 * An <tt>AIDelayedTextField</tt> is identical to an NSTextField except, instead of sending its target an action only when enter is pressed or the field loses focus, it sends the action after a specified delay without changes.  This allows an intermediate behavior between changing every time the text chagnes (via the textDidChange: notification) and changing only when editing is complete.
 */
@interface AIDelayedTextField : NSTextField {
	float   delayInterval;
}

/*!
 * @brief Immediately send the action to the target.
 *
 * Immediately send the action to the target. If the field had changed but has not yet sent its action (because the delay interval has not been reached), it immediately sends the action and cancels the delayed send.  This should be sent before programatically changing the text (if the view is configuring for some new display but the changes the user made previously should saved). It should also be called before its containing view is closed so changes may be immediately applied..
 */ 
- (void)fireImmediately;

/*!
 * @brief Set the interval which must pass without changes before the action is triggered.
 *
 * Set the interval which must pass without changes before the action is triggered.  If changes are made within this interval, the timer is reset and inInterval must then pass from the time of the new edit.
 * @param inInterval The new interval (in seconds). The default value is 0.5 seconds.
 */
- (void)setDelayInterval:(float)inInterval;

/*!
 * @brief The current triggering delay interval
 *
 * The current triggering delay interval
 * @return inInterval The delay interval (in seconds).
 */
- (float)delayInterval;

@end
