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

#import <AIUtilities/AITextViewWithPlaceholder.h>

/*!
 * @class AISendingTextView
 * @brief NSTextView which fixes issues with return and enter under high system load
 *
 * <p>When the system is busy and things slow down, characters are grouped, but keys are not.  This causes problems, since using the regular method of catching returns will not work.  The first return will come in, the current text will be sent, and then the other returns will come in (and nothing will happen since there's no text in the text view).  After the returns are processed, THEN the rest of the text will be inserted as a clump into the text view.  To the user this looks like their return was 'missed', since it gets inserted into the text view, and doesn't trigger a send.</p>
 * <p>This fix watches for returns in the insertText method.  However, since it's impossible to distinguish a return from an enter by the characters inserted (both insert /r, 10), it also watches and remembers the keys being pressed with interpretKeyEvents... When insertText sees a /r, it checks to see what key was pressed to generate that /r, and makes a decision to send or not.  Since the sending occurs from within insertText, the returns are processed in the correct order with the text, and the problem is illiminated.</p>
 */

@interface AISendingTextView : AITextViewWithPlaceholder {
	NSMutableArray	*returnArray;

	id				target;
	SEL			selector;
	BOOL			sendingEnabled;

	BOOL			nextIsReturn;
	BOOL			nextIsEnter;
	BOOL			optionPressedWithNext;
}

/*!
 * @brief Whether send keys trigger the set action
 *
 * Set if send keys trigger the set action. If YES, we will invoke action on target when a send key is pressed.
 * @see setTarget:action:
 */
@property (readwrite, nonatomic) BOOL sendingEnabled;

/*!
 * @brief Set the target and action to message when a send occurs
 *
 * When a send occurs, <b>inTarget</b> will be sent <b>inSelector</b>, which should take one argument which will be the sender.
 * @param inTarget The target
 * @param inSelector The selector to perform on <b>inTarget</b>
 */
- (void)setTarget:(id)inTarget action:(SEL)inSelector;

@end

@interface AISendingTextView (PRIVATE_AISendingTextViewAndSubclasses)
- (IBAction)sendContent:(id)sender;
@end
