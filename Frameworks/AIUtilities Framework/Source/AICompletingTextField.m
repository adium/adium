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

#import "AICompletingTextField.h"
#import "AIAttributedStringAdditions.h"
#import "AIStringAdditions.h"

@interface NSTextField (AITextFieldAdditions)

- (void)selectRange:(NSRange)range;

@end

@implementation NSTextField (AITextFieldAdditions)

- (void)selectRange:(NSRange)range
{
    NSText	*fieldEditor;
	
    fieldEditor = [[self window] fieldEditor:YES forObject:self];
	
    [fieldEditor setSelectedRange:range];
}

@end

/*
    A text field that auto-completes known strings
 */

@interface AICompletingTextField ()
- (id)_init;
- (NSString *)completionForString:(NSString *)inString;
@end

@implementation AICompletingTextField

//Init the field
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _init];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _init];
	}
	return self;
}

- (id)_init
{
	stringSet = nil;
	impliedCompletionDictionary = nil;
	minLength = 1;
	oldUserLength = 0;
	completeAfterSeparator = NO;

	return self;
}

- (void)dealloc
{
    [stringSet release];
	[impliedCompletionDictionary release];
	
    [super dealloc];
}

//Sets the minimum string length required before completion kicks in
- (void)setMinStringLength:(int)length
{
    minLength = length;
}

- (void)setCompletesOnlyAfterSeparator:(BOOL)split
{
	completeAfterSeparator = split;
}

//Set the strings that this field will use to auto-complete
- (void)setCompletingStrings:(NSArray *)strings
{
    [stringSet release];
    stringSet = [[NSMutableSet setWithArray:strings] retain];
	
	[impliedCompletionDictionary release]; impliedCompletionDictionary = nil;
}

//Adds a string to the existing string list
- (void)addCompletionString:(NSString *)string
{
    if (!stringSet) stringSet = [[NSMutableSet alloc] init];

    [stringSet addObject:string];
}

- (void)addCompletionString:(NSString *)string withImpliedCompletion:(id)impliedCompletion
{
	if (![string isEqualToString:impliedCompletion]) {
		if (!impliedCompletionDictionary) impliedCompletionDictionary = [[NSMutableDictionary alloc] init];
		
		[impliedCompletionDictionary setObject:impliedCompletion forKey:string];
	}
	
	[self addCompletionString:string];
}


//Private ------------------------------------------------------------------------------------------
- (void)textDidChange:(NSNotification *)notification
{
    NSString		*userValue, *lastValue, *completionValue;
    NSUInteger	userValueLength, lastValueLength;
	
    //Auto-complete
    userValue = [self stringValue];
	lastValue = userValue;
	userValueLength = [userValue length];
	lastValueLength = userValueLength;
	
	if ( completeAfterSeparator ) {
		NSArray *tempArray = [userValue componentsSeparatedByString:@","];
		lastValueLength = [[(NSString *)[tempArray objectAtIndex:([tempArray count]-1)] compactedString] length];
		lastValue = [tempArray objectAtIndex:([tempArray count]-1)];
	}
	
	//We only need to attempt an autocompletion if characters have been added - deleting shouldn't autocomplete
    if (userValueLength > oldUserLength) {
        completionValue = [self completionForString:lastValue];
    
        if (completionValue != nil && [completionValue length] > lastValueLength) {
            //Auto-complete the string - note that it retains the text that the user typed, and simply adds
            //the additional characters needed to match the completionValue
            [self setStringValue:[userValue stringByAppendingString:[completionValue substringFromIndex:lastValueLength]]];
			
            //Select the auto-completed text
            [self selectRange:NSMakeRange(userValueLength, [completionValue length] - lastValueLength)];
        }
    }

    oldUserLength = userValueLength;
	
	[super textDidChange:notification];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
    // This method helps make the text field a little smarter - as the user types, the auto-completions retain
    // the user-entered characters as they were typed (basically, retaining the case as it was entered). If
    // the user presses tab or enter, then this method is triggered and the text field tries to replace the
    // text with a (case-insensitive) matching string (basically, having the effect that the entered string's
    // case is "corrected" to match the auto-completion value). If the user *wants* to enter a string identical
    // to a completion value, but with different case, he or she can avoid this automatic case "correction" by
    // NOT hitting tab or enter, and instead just clicking the appropriate button or control they want to use.
    
    NSString        *userValue;
    
    // If the field matches an entry in stringSet (except maybe case) replace it with the correct-case string
    userValue = [self stringValue];
    
    if ([userValue length] >= minLength) {
        // Look for matching first matching string (except for case)
        for (NSString *currentString in stringSet) {
            if ([currentString compare:userValue options:NSCaseInsensitiveSearch] == 0) {
                [self setStringValue:currentString];
                break;
            }
        }
    }
    
    [super textDidEndEditing:notification];
}

//Returns the known completion for a string segment
- (NSString *)completionForString:(NSString *)inString
{
	NSMutableArray  *possibleCompletions = [[NSMutableArray alloc] init];
	NSString		*compString = inString;
    NSUInteger		length;
    NSRange			range;

	// Find only the last item in the list, if we are to autocomplete only after separators
	if ( completeAfterSeparator ) {
		NSArray *tempArray = [inString componentsSeparatedByString:@","];
		compString = [(NSString *)[tempArray objectAtIndex:([tempArray count]-1)] compactedString];
	}
	
    //Setup
    length = [compString length];
    range = NSMakeRange(0, length);
	
    if (length >= minLength) {
        //Check each auto-complete string for a match, add each match to array of possible competions
        for (NSString *autoString in stringSet) {
            if (([autoString length] > length) && [autoString compare:compString options:NSCaseInsensitiveSearch range:range] == 0) {
				[possibleCompletions addObject:autoString];
            }
        }
    }

	NSArray *sortedArray = [possibleCompletions sortedArrayUsingSelector:@selector(compareLength:)];
	
	[possibleCompletions release];
	
	if ([sortedArray count] > 0){
		return [sortedArray objectAtIndex:0];
		//When the AICompletingTextfield is modified to be able to provide multiple choices of completions, the entire array can be used later.
		//return sortedArray;
	}
	
	return nil;
}

- (id)impliedValueForString:(NSString *)aString
{
	id impliedValue = nil;

	if (aString) {
		/* Check if aString implies a different completion; ensure that this new completion is not itself
		* a potential completion (if it is, we assume the user's manually entered stringValue to be the intended value)
		*/
		NSString *impliedCompletion = (NSString *)[impliedCompletionDictionary objectForKey:aString];
		
		NSString *impliedCompletionOfImpliedCompletion = (NSString *)[impliedCompletionDictionary objectForKey:impliedCompletion];
		
		/* If we got an implied completion, and using that implied completion wouldn't get us into a loop with other
		 * completions (leading to unpredicatable behavior as far as the user would be concerned), return the implied
		 * completion
		 */
		if (impliedCompletion &&
			(!impliedCompletionOfImpliedCompletion || [impliedCompletionOfImpliedCompletion isEqual:impliedCompletion])) {
			impliedValue = impliedCompletion;
		}
	}
	
	return (impliedValue ? impliedValue : (id)aString);	
	
}

//Return a string which may be the actual aString or may be some other string implied by it
- (NSString *)impliedStringValueForString:(NSString *)aString
{
	NSString *returnString;
	id		 possibleImpliedString = [self impliedValueForString:aString];
	
	if (possibleImpliedString && [possibleImpliedString isKindOfClass:[NSString class]]) {
		returnString = possibleImpliedString;
	} else {
		returnString = aString;
	}
	
	return returnString;
}

//Return a string which may be the actual contents of the text field, or some other string implied by it
- (NSString *)impliedStringValue
{
	return [self impliedStringValueForString:[self stringValue]];
}

- (id)impliedValue
{
	return [self impliedValueForString:[self stringValue]];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	
}

@end
