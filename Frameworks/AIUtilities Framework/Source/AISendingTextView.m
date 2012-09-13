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

#import "AISendingTextView.h"
#import "AIStringAdditions.h"

//What's going on in here?
//
//When the system is busy and things slow down, characters are grouped, but keys are not.  This causes problems,
//since using the regular method of catching returns will not work.  The first return will come in, the current
//text will be sent, and then the other returns will come in (and nothing will happen since there's no text in the
//text view).  After the returns are processed, THEN the rest of the text will be inserted as a clump into the text
//view.  To the user this looks like their return was 'missed', since it gets inserted into the text view, and doesn't
//trigger a send.
//
//This fix watches for returns in the insertText method.  However, since it's impossible to distinguish a return from
//an enter by the characters inserted (both insert CR, ASCII 10), it also watches and remembers the keys being pressed with
//interpretKeyEvents... When insertText sees a CR, it checks to see what key was pressed to generate that CR, and makes
//a decision to send or not.  Since the sending occurs from within insertText, the returns are processed in the correct
//order with the text, and the problem is eliminated.
//

@interface AISendingTextView ()
- (void)_initSendingTextView;
@end

@implementation AISendingTextView
//Init the text view
- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
	if ((self = [super initWithFrame:frameRect textContainer:aTextContainer])) {
		[self _initSendingTextView];
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		[self _initSendingTextView];
	}
	
	return self;
}

- (void)_initSendingTextView
{
	returnArray = [[NSMutableArray alloc] init];
	nextIsReturn = NO;
	nextIsEnter = NO;
	optionPressedWithNext = NO;
	target = nil;
	selector = nil;
	sendingEnabled = YES;
}

//If true we will invoke selector on target when a send key is pressed
@synthesize sendingEnabled;

- (void)setTarget:(id)inTarget action:(SEL)inSelector
{
    target = inTarget;
    selector = inSelector;
}

//Send messages on a command-return
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	NSString *charactersIgnoringModifiers = [theEvent charactersIgnoringModifiers];
    if (([charactersIgnoringModifiers length] && [charactersIgnoringModifiers characterAtIndex:0] == '\r') &&
		sendingEnabled) {
		[self sendContent:nil];
		return YES;
	} else {
		return NO;
	}
}

// special characters only work at the end of a string of input
- (void)insertText:(id)aString
{
	BOOL 		insertText = YES;
	NSString	*theString = nil;
	
	if ([aString isKindOfClass:[NSString class]]) {
        theString = aString;
    } else if ([aString isKindOfClass:[NSAttributedString class]]) {
        theString = [aString string];
    }
	
	if ((sendingEnabled) && nextIsReturn &&
		([theString hasSuffix:@"\n"] && !optionPressedWithNext)) {
		
		//Make sure we insert any applicable text first
		if ([theString length] > 1) {
			NSRange range = NSMakeRange(0, [theString length]-1);
			if ([aString isKindOfClass:[NSString class]]) {
				[super insertText:[aString substringWithRange:range]];
			} else if ([aString isKindOfClass:[NSAttributedString class]]) {
				[super insertText:[aString attributedSubstringFromRange:range]];
			}
		}
		
		//Now send
		[self sendContent:nil]; //Send the content
		insertText = NO;
	}

	if (insertText) [super insertText:aString];
}

- (void)interpretKeyEvents:(NSArray *)eventArray
{
	NSUInteger 	idx = 0;
	NSUInteger	numEvents = [eventArray count];

    while (idx < numEvents) {
		NSEvent		*theEvent = [eventArray objectAtIndex:idx];
		
        if ([theEvent type] == NSKeyDown) {
			unichar lastChar = [[theEvent charactersIgnoringModifiers] lastCharacter];
            if (lastChar == NSCarriageReturnCharacter || lastChar == NSEnterCharacter) {
				nextIsReturn = YES;

				optionPressedWithNext = ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
            }
        }
		
		idx++;
    }
	
    [super interpretKeyEvents:eventArray];
}

//'Send' our content
- (IBAction)sendContent:(id)sender
{
    [target performSelector:selector withObject:self];
}

@end
