//
//  AISendingTextView.m
//  Adium
//
//  Created by Adam Iser on Thu Mar 25 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

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
	sendOnReturn = YES;
	nextIsReturn = NO;
	sendOnEnter = YES;
	nextIsEnter = NO;
	optionPressedWithNext = NO;
	target = nil;
	selector = nil;
	sendingEnabled = YES;
}

- (void)dealloc
{
	[returnArray release];
	
	[super dealloc];
}

//If true we will invoke selector on target when a send key is pressed
@synthesize sendingEnabled;

@synthesize sendOnReturn;
@synthesize sendOnEnter;

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
	
	if ((sendingEnabled) &&
		((nextIsReturn && sendOnReturn) || (nextIsEnter && sendOnEnter)) &&
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
	NSUInteger 	index = 0;
	NSUInteger	numEvents = [eventArray count];

    while (index < numEvents) {
		NSEvent		*theEvent = [eventArray objectAtIndex:index];
		
        if ([theEvent type] == NSKeyDown) {
			unichar lastChar = [[theEvent charactersIgnoringModifiers] lastCharacter];
            if (lastChar == NSCarriageReturnCharacter) {
                nextIsEnter = NO;
				nextIsReturn = YES;

				optionPressedWithNext = ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
				
            } else if (lastChar == NSEnterCharacter) {
                nextIsReturn = NO;
                nextIsEnter = YES;
				
                optionPressedWithNext = ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
            }
        }
		
		index++;
    }
	
    [super interpretKeyEvents:eventArray];
}

//'Send' our content
- (IBAction)sendContent:(id)sender
{
    [target performSelector:selector withObject:self];
}

@end
