//
//  AISendingTextView.h
//  Adium
//
//  Created by Adam Iser on Thu Mar 25 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

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
	BOOL			insertingText;

	id				target;
	SEL			selector;
	BOOL			sendingEnabled;

	BOOL			sendOnEnter;
	BOOL			sendOnReturn;

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
 * @brief Whether Return triggers a send
 *
 * Set if Return triggers a send. If it does, the send will be performed instead of a newline being inserted.
 */
@property (readwrite, nonatomic) BOOL sendOnReturn;

/*!
 * @brief Whether Enter triggers a send
 *
 * Set if Enter triggers a send. If it does, the send will be performed instead of a newline being inserted.
 * @param inBool YES if Enter triggers a send.
 */
@property (readwrite, nonatomic) BOOL sendOnEnter;

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
