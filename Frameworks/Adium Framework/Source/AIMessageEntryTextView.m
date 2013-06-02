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

#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMessageEntryTextView.h>
#import <Adium/AITextAttachmentExtension.h>

#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentContext.h>

#import <Adium/AIMessageViewEmoticonsController.h>

#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIPasteboardAdditions.h>

#import <FriBidi/NSString-FBAdditions.h>


#define MAX_HISTORY					25	// Number of messages to remember in history
#define ENTRY_TEXTVIEW_PADDING		6	// Padding for auto-sizing

#define KEY_DISABLE_TYPING_NOTIFICATIONS		@"Disable Typing Notifications"

#define KEY_SPELL_CHECKING						@"Spell Checking Enabled"
#define KEY_GRAMMAR_CHECKING					@"Grammar Checking Enabled"
#define	PREF_GROUP_DUAL_WINDOW_INTERFACE		@"Dual Window Interface"

#define KEY_SUBSTITUTION_DASH					@"Smart Dash Substitutions"
#define KEY_SUBSTITUTION_DATA_DETECTORS			@"Smart Data Detectors Substitutions"
#define KEY_SUBSTITUTION_REPLACEMENT			@"Text Replacement Substitutions"
#define KEY_SUBSTITUTION_SPELLING				@"Spelling Substitutions"
#define KEY_SUBSTITUTION_COPY_PASTE				@"Smart Copy Paste Substitutions"
#define KEY_SUBSTITUTION_QUOTE					@"Smart Quote Substitutions"
#define KEY_SUBSTITUTION_LINK					@"Smart Links Substitutions"

#define INDICATOR_RIGHT_PADDING					2	// Padding between right side of the message view and the rightmost indicator

#define PREF_GROUP_CHARACTER_COUNTER			@"Character Counter"
#define KEY_CHARACTER_COUNTER_ENABLED			@"Character Counter Enabled"
#define KEY_MAX_NUMBER_OF_CHARACTERS			@"Maximum Number Of Characters"

#define FILES_AND_IMAGES_TYPES [NSArray arrayWithObjects: \
	NSFilenamesPboardType, AIiTunesTrackPboardType, NSTIFFPboardType, NSPDFPboardType, nil]

#define PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY [NSArray arrayWithObjects: \
	NSRTFPboardType, NSStringPboardType, nil]

#pragma mark -

/**
 * @class AISimpleTextView
 * @brief Just draws an attributed string. That's it.
 * 
 * No really, it's dead simple. It just draws an attributed string in its bounds (which you set). That's it.
 * It's totally not even useful.
 */

@implementation  AISimpleTextView

@synthesize string;

- (void)drawRect:(NSRect)rect 
{
	[string drawInRect:[self bounds]];
}

@end

#pragma mark -

@interface AIMessageEntryTextView ()

- (void)_setPushIndicatorVisible:(BOOL)visible;
- (void)positionPushIndicator;
- (void)_resetCacheAndPostSizeChanged;

- (NSAttributedString *)attributedStringWithAITextAttachmentExtensionsFromRTFDData:(NSData *)data;
- (NSAttributedString *)attributedStringWithTextAttachmentExtension:(AITextAttachmentExtension *)attachment;
- (void)addAttachmentOfPath:(NSString *)inPath;
- (void)addAttachmentOfImage:(NSImage *)inImage;
- (void)addAttachmentsFromPasteboard:(NSPasteboard *)pasteboard;

- (void)setCharacterCounterVisible:(BOOL)visible;
- (void)setCharacterCounterMaximum:(NSInteger)inMaxCharacters;
- (void)setCharacterCounterPrefix:(NSString *)prefix;
- (void)updateCharacterCounter;
- (void)positionCharacterCounter;

- (void)positionIndicators:(NSNotification *)notification;

- (void)frameDidChange:(NSNotification *)notification;
- (void)toggleMessageSending:(NSNotification *)not;
- (void)contentObjectAdded:(NSNotification *)notification;

- (void)updateEmoticonsMenuButton;

@end

#pragma mark -

@interface NSMutableAttributedString (AIMessageEntryTextViewAdditions)

- (void)convertForPasteWithTraitsUsingAttributes:(NSDictionary *)inAttributes;

@end

#pragma mark - AIMessageEntryTextView

@implementation AIMessageEntryTextView

- (void)_initMessageEntryTextView
{
	associatedView = nil;
	chat = nil;
	pushIndicator = nil;
	pushPopEnabled = YES;
	historyEnabled = YES;
	clearOnEscape = NO;
	homeToStartOfLine = YES;
	resizing = NO;
	enableTypingNotifications = NO;
	historyArray = [[NSMutableArray alloc] initWithObjects:@"", nil];
	pushArray = [[NSMutableArray alloc] init];
	currentHistoryLocation = 0;
	[self setDrawsBackground:YES];
	_desiredSizeCached = NSMakeSize(0,0);
	characterCounter = nil;
	characterCounterPrefix = nil;
	maxCharacters = 0;
	savedTextColor = nil;
	hasEmoticonsMenu = NO;

	if ([self respondsToSelector:@selector(setAllowsUndo:)]) {
		[self setAllowsUndo:YES];
	}
    
	if ([self respondsToSelector:@selector(setAllowsDocumentBackgroundColorChange:)]) {
		[self setAllowsDocumentBackgroundColorChange:YES];
	}
	
	[self setImportsGraphics:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(textDidChange:)
												 name:NSTextDidChangeNotification 
											   object:self];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(frameDidChange:) 
												 name:NSViewFrameDidChangeNotification 
											   object:self];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(toggleMessageSending:)
                                                 name:@"AIChatDidChangeCanSendMessagesNotification"
                                               object:chat];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentObjectAdded:)
                                                 name:Content_ContentObjectAdded
                                               object:nil];

	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_DUAL_WINDOW_INTERFACE];	
	
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
}

// Init the text view
- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
	if ((self = [super initWithFrame:frameRect textContainer:aTextContainer])) {
		[self _initMessageEntryTextView];
	}
	
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) {
		[self _initMessageEntryTextView];
	}
	
	return self;
}

- (void)dealloc
{
	if(chat.isGroupChat) {
		[chat removeObserver:self forKeyPath:@"Character Counter Max"];
		[chat removeObserver:self forKeyPath:@"Character Counter Prefix"];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];

    historyArray = nil;
    pushArray = nil;
}

- (void) setDelegate:(id<AIMessageEntryTextViewDelegate>)del
{
	super.delegate = del;
}

- (id<AIMessageEntryTextViewDelegate>)delegate
{
	return (id<AIMessageEntryTextViewDelegate>)super.delegate;
}

- (void)keyDown:(NSEvent *)inEvent
{
	NSString *charactersIgnoringModifiers = [inEvent charactersIgnoringModifiers];

	if ([charactersIgnoringModifiers length]) {
		unichar		 inChar = [charactersIgnoringModifiers characterAtIndex:0];
		NSUInteger flags = [inEvent modifierFlags];
		
		// We have to test ctrl before option, because otherwise we'd miss ctrl-option-* events
		if (pushPopEnabled && (flags & NSControlKeyMask) && !(flags & NSShiftKeyMask)) {
			if (inChar == NSUpArrowFunctionKey) {
				[self popContent];
			} else if (inChar == NSDownArrowFunctionKey) {
				[self pushContent];
			} else if (inChar == 's') {
				[self swapContent];
			} else {
				[super keyDown:inEvent];
			}
		} else if (historyEnabled && (flags & NSAlternateKeyMask) && !(flags & NSShiftKeyMask)) {
			if (inChar == NSUpArrowFunctionKey) {
				[self historyUp];
			} else if (inChar == NSDownArrowFunctionKey) {
				[self historyDown];
			} else {
				[super keyDown:inEvent];
			}
		} else if (associatedView && (flags & NSCommandKeyMask) && !(flags & NSShiftKeyMask)) {
			if ((inChar == NSUpArrowFunctionKey || inChar == NSDownArrowFunctionKey) ||
			   (inChar == NSHomeFunctionKey || inChar == NSEndFunctionKey) ||
			   (inChar == NSPageUpFunctionKey || inChar == NSPageDownFunctionKey)) {
				
                // Pass the associatedView a keyDown event equivalent equal to inEvent except without the modifier flags
				[associatedView keyDown:[NSEvent keyEventWithType:[inEvent type]
														 location:[inEvent locationInWindow]
													modifierFlags:0
														timestamp:[inEvent timestamp]
													 windowNumber:[inEvent windowNumber]
														  context:[inEvent context]
													   characters:[inEvent characters]
									  charactersIgnoringModifiers:charactersIgnoringModifiers
														isARepeat:[inEvent isARepeat]
														  keyCode:[inEvent keyCode]]];
			} else {
				[super keyDown:inEvent];
			}
		} else if (associatedView && (inChar == NSPageUpFunctionKey || inChar == NSPageDownFunctionKey)) {
			[associatedView keyDown:inEvent];	
		} else if (inChar == NSHomeFunctionKey || inChar == NSEndFunctionKey) {
			if (homeToStartOfLine) {
				NSRange	newRange;
				
				if (flags & NSShiftKeyMask) {
					// With shift, select to the beginning/end of the line
					NSRange	selectedRange = [self selectedRange];
					if (inChar == NSHomeFunctionKey) {
						// Home: from 0 to the current location
						newRange.location = 0;
						newRange.length = selectedRange.location;
					} else {
						// End: from current location to the end
						newRange.location = selectedRange.location;
						newRange.length = [[self string] length] - newRange.location;
					}
					
				} else {
					newRange.location = ((inChar == NSHomeFunctionKey) ? 0 : [[self string] length]);
					newRange.length = 0;
				}

				[self setSelectedRange:newRange];
        } else {
				// If !homeToStartOfLine, pass the keypress to our associated view.
				if (associatedView) {
					[associatedView keyDown:inEvent];
				} else {
					[super keyDown:inEvent];					
				}
			}
		} else if (inChar == NSTabCharacter) {
			if ([self.delegate respondsToSelector:@selector(textViewShouldTabComplete:)] &&
				[self.delegate textViewShouldTabComplete:self]) {
				[self complete:nil];
			} else {
				[super keyDown:inEvent];				
			} 

		} else if (inChar == NSEnterCharacter || inChar == NSCarriageReturnCharacter) {
			//Make shift+enter work the same as option+enter
			if (flags & NSShiftKeyMask) {
				[super insertLineBreak:self];
			} else {
				[super keyDown:inEvent];
			}
			
		} else {
			[super keyDown:inEvent];
		}
	} else {
		[super keyDown:inEvent];
	}
}

- (void)scrollWheel:(NSEvent *)anEvent
{
	[self.enclosingScrollView scrollWheel:anEvent];
}

// Text changed
- (void)textDidChange:(NSNotification *)notification
{
	// Update typing status
	if (enableTypingNotifications) {
		[adium.contentController userIsTypingContentForChat:chat hasEnteredText:[[self textStorage] length] > 0];
	}

	// Hide any existing contact list tooltip when we begin typing
	[adium.interfaceController showTooltipForListObject:nil atScreenPoint:NSZeroPoint onWindow:nil];

    // Reset cache and resize
	[self _resetCacheAndPostSizeChanged]; 
	
	// Update the character counter
	if (characterCounter) {
		[self updateCharacterCounter];
	}
}

/*!
 * @brief Clear any link attribute in the current typing attributes
 *
 * Any link attribute is removed. All other typing attributes are unchanged.
 */
- (void)clearLinkAttribute
{
	NSDictionary *typingAttributes = [self typingAttributes];

	if ([typingAttributes objectForKey:NSLinkAttributeName]) {
		NSMutableDictionary *newTypingAttributes = [typingAttributes mutableCopy];

		[newTypingAttributes removeObjectForKey:NSLinkAttributeName];
		[self setTypingAttributes:newTypingAttributes];
	}
}

/*!
 * @brief The user pressed escape: clear our text view in response
 */
- (void)cancelOperation:(id)sender
{
	if (clearOnEscape) {
		NSUndoManager	*undoManager = [self undoManager];
		[undoManager registerUndoWithTarget:self
								   selector:@selector(setAttributedString:)
									 object:[[self textStorage] copy]];
		[undoManager setActionName:AILocalizedString(@"Clear", nil)];

		[self setString:@""];
		[self clearLinkAttribute];		
	}

	if ([self.delegate respondsToSelector:@selector(textViewDidCancel:)]) {
		[self.delegate textViewDidCancel:self];
	}
}

#pragma mark - Configure

@synthesize clearOnEscape, homeToStartOfLine, associatedView;

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if ((!object || (object == chat.account)) &&
		[group isEqualToString:GROUP_ACCOUNT_STATUS] &&
		(!key || [key isEqualToString:KEY_DISABLE_TYPING_NOTIFICATIONS])) {
		enableTypingNotifications = ![[chat.account preferenceForKey:KEY_DISABLE_TYPING_NOTIFICATIONS
                                                               group:GROUP_ACCOUNT_STATUS] boolValue];
	}
	
	if (!object && [group isEqualToString:PREF_GROUP_DUAL_WINDOW_INTERFACE]) {
		if (!key || [key isEqualToString:KEY_GRAMMAR_CHECKING]) {
			[self setGrammarCheckingEnabled:[[prefDict objectForKey:KEY_GRAMMAR_CHECKING] boolValue]];
		}

		if (!key || [key isEqualToString:KEY_SPELL_CHECKING]) {
			[self setContinuousSpellCheckingEnabled:[[prefDict objectForKey:KEY_SPELL_CHECKING] boolValue]];
		}
		
		if (!key || [key isEqualToString:KEY_SUBSTITUTION_DASH]) {
				[self setAutomaticDashSubstitutionEnabled:[[prefDict objectForKey:KEY_SUBSTITUTION_DASH] boolValue]];
		}
		
		if (!key || [key isEqualToString:KEY_SUBSTITUTION_DATA_DETECTORS]) {
				[self setAutomaticDataDetectionEnabled:[[prefDict objectForKey:KEY_SUBSTITUTION_DATA_DETECTORS] boolValue]];
		}
		
		if (!key || [key isEqualToString:KEY_SUBSTITUTION_REPLACEMENT]) {
				[self setAutomaticTextReplacementEnabled:[[prefDict objectForKey:KEY_SUBSTITUTION_REPLACEMENT] boolValue]];
		}
		
		if (!key || [key isEqualToString:KEY_SUBSTITUTION_SPELLING]) {
				[self setAutomaticSpellingCorrectionEnabled:[[prefDict objectForKey:KEY_SUBSTITUTION_SPELLING] boolValue]];
		}
		
		if (!key || [key isEqualToString:KEY_SUBSTITUTION_COPY_PASTE]) {
			[self setSmartInsertDeleteEnabled:[[prefDict objectForKey:KEY_SUBSTITUTION_COPY_PASTE] boolValue]];
		}
		
		if (!key || [key isEqualToString:KEY_SUBSTITUTION_QUOTE]) {
			[self setAutomaticQuoteSubstitutionEnabled:[[prefDict objectForKey:KEY_SUBSTITUTION_QUOTE] boolValue]];
		}
		
		if (!key || [key isEqualToString:KEY_SUBSTITUTION_LINK]) {
			[self setAutomaticLinkDetectionEnabled:[[prefDict objectForKey:KEY_SUBSTITUTION_LINK] boolValue]];
		}
	}
}

#pragma mark - Adium Text Entry

/*!
 * @brief Toggle whether message sending is enabled based on a notification. The notification object is the AIChat of the appropriate message entry view
 */
- (void)toggleMessageSending:(NSNotification *)not
{
	// XXX - We really should query the AIChat about this, but AIChat's "can't send" is really designed for handling offline, not banned.
    // Bringing up the offline messaging dialog when banned would make no sense.
	[self setSendingEnabled:[[[not userInfo] objectForKey:@"TypingEnabled"] boolValue]];
}

/*!
 * @brief Are we available for sending?
 */
- (BOOL)availableForSending
{
	return self.sendingEnabled;
}

// Set our string, preserving the selected range
- (void)setAttributedString:(NSAttributedString *)inAttributedString
{
    NSUInteger			length = [inAttributedString length];
    NSRange 	oldRange = [self selectedRange];

    // Change our string
    [[self textStorage] setAttributedString:inAttributedString];

    // Restore the old selected range
    if (oldRange.location < length) {
        if (oldRange.location + oldRange.length <= length) {
            [self setSelectedRange:oldRange];
        } else {
            [self setSelectedRange:NSMakeRange(oldRange.location, length - oldRange.location)];       
        }
    }

    // Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
}

// Set our string (plain text)
- (void)setString:(NSString *)string
{
    [super setString:string];

    // Notify everyone that our text changed
    [[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:self];
}

// Set our typing format
- (void)setTypingAttributes:(NSDictionary *)attrs
{
	[super setTypingAttributes:attrs];

	[self setInsertionPointColor:[[attrs objectForKey:NSBackgroundColorAttributeName] contrastingColor]];
}

#pragma mark - Pasting

- (BOOL)handlePasteAsRichText
{
	NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
	BOOL		 handledPaste = NO;
	
	// Types is ordered by the preference for handling of the data; enumerating it lets us allow the sending application's hints to be followed.
	for (NSString *type in generalPasteboard.types) {
		if ([type isEqualToString:NSRTFDPboardType]) {
			NSData *data = [generalPasteboard dataForType:NSRTFDPboardType];
			[self insertText:[self attributedStringWithAITextAttachmentExtensionsFromRTFDData:data]];
			handledPaste = YES;
			
		} else if ([PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY containsObject:type]) {
			// When we hit a type we should let the superclass handle, break without doing anything
			break;
			
		} else if ([FILES_AND_IMAGES_TYPES containsObject:type]) {
			[self addAttachmentsFromPasteboard:generalPasteboard];
			handledPaste = YES;
		}
		
		if (handledPaste) break;
		
	}
	
	return handledPaste;
}

// Paste as rich text without altering our typing attributes
- (void)pasteAsRichText:(id)sender
{
	NSDictionary	*attributes = [[self typingAttributes] copy];

	if (![self handlePasteAsRichText]) {
		[self paste:sender];
	}

	if (attributes) {
		[self setTypingAttributes:attributes];
	}

	[self scrollRangeToVisible:[self selectedRange]];
}

- (void)pasteAsPlainTextWithTraits:(id)sender
{
	NSDictionary	*attributes = [[self typingAttributes] copy];
	
	NSPasteboard	*generalPasteboard = [NSPasteboard generalPasteboard];
	NSString		*type;

	NSArray *supportedTypes =
		[NSArray arrayWithObjects:NSURLPboardType, NSRTFDPboardType, NSRTFPboardType, NSHTMLPboardType, NSStringPboardType, 
			NSFilenamesPboardType, NSTIFFPboardType, NSPDFPboardType, nil];

	type = [[NSPasteboard generalPasteboard] availableTypeFromArray:supportedTypes];
	
	if ([type isEqualToString:NSRTFPboardType] ||
		[type isEqualToString:NSRTFDPboardType] ||
		[type isEqualToString:NSHTMLPboardType] ||
		[type isEqualToString:NSStringPboardType]) {
		NSData *data;
		
		@try {
			data = [generalPasteboard dataForType:type];
		} @catch (NSException *localException) {
			data = nil;
		}
		
		// Failed. Try again with the string type.
		if (!data && ![type isEqualToString:NSStringPboardType]) {
			if ([[[NSPasteboard generalPasteboard] types] containsObject:NSStringPboardType]) {
				type = NSStringPboardType;
				@try {
					data = [generalPasteboard dataForType:type];
				} @catch (NSException *localException) {
					data = nil;
				}
			}
		}
		
		if (!data) {
			// We still didn't get valid data... maybe super can handle it
			@try {
				[self paste:sender];
			} @catch (NSException *localException) {
				NSBeep();
				return;
			}
		}
		
		NSMutableAttributedString *attributedString;
		
		if ([type isEqualToString:NSStringPboardType]) {
			NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			attributedString = [[NSMutableAttributedString alloc] initWithString:string
																	  attributes:[self typingAttributes]];
			
		} else {
			@try {
				if ([type isEqualToString:NSRTFPboardType]) {
					attributedString = [[NSMutableAttributedString alloc] initWithRTF:data
																   documentAttributes:NULL];
				} else if ([type isEqualToString:NSRTFDPboardType]) {
					attributedString = [[NSMutableAttributedString alloc] initWithRTFD:data
																	documentAttributes:NULL];
				} else /* NSHTMLPboardType */ {
					attributedString = [[NSMutableAttributedString alloc] initWithHTML:data
																	documentAttributes:NULL];
				}
			} @catch (NSException *localException) {
				// Error while reading the RTF or HTML data, which can happen. Fall back on plain text
				if ([[[NSPasteboard generalPasteboard] types] containsObject:NSStringPboardType]) {
					data = [generalPasteboard dataForType:NSStringPboardType];
					NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
					attributedString = [[NSMutableAttributedString alloc] initWithString:string
																			  attributes:[self typingAttributes]];
				} else {
					attributedString = nil;
				}
			}

			if (!attributedString) {
				NSBeep();
				return;
			}

			[attributedString convertForPasteWithTraitsUsingAttributes:[self typingAttributes]];
		}
		
		NSRange			selectedRange = [self selectedRange];
		NSTextStorage	*textStorage = [self textStorage];
		
		// Prepare the undo operation
		NSUndoManager	*undoManager = [self undoManager];
		[[undoManager prepareWithInvocationTarget:textStorage]
				replaceCharactersInRange:NSMakeRange(selectedRange.location, [attributedString length])
					withAttributedString:[textStorage attributedSubstringFromRange:selectedRange]];
		[undoManager setActionName:AILocalizedString(@"Paste", nil)];
		
		// Perform the paste
		[textStorage replaceCharactersInRange:selectedRange
						 withAttributedString:attributedString];
		// Align our text properly (only need to if the first character was changed)
		if (selectedRange.location == 0)
			[self setBaseWritingDirection:[[textStorage string] baseWritingDirection]];
		// Notify that we changed our text
		[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
															object:self];

	} else if ([FILES_AND_IMAGES_TYPES containsObject:type] ||
			   [type isEqualToString:NSURLPboardType]) {
		if (![self handlePasteAsRichText]) {
			[self paste:sender];
		}

	} else {		
		// If we didn't handle it yet, let super try to deal with it
		[self paste:sender];
	}

	if (attributes) {
		[self setTypingAttributes:attributes];
	}

	[self scrollRangeToVisible:[self selectedRange]];
}

#pragma mark - Deletion

- (void)deleteBackward:(id)sender
{
	// Perform the delete
	[super deleteBackward:sender];
	
	// If we are now an empty string, and we still have a link active, clear the link
	if ([[self textStorage] length] == 0) {
		[self clearLinkAttribute];
	}
}

#pragma mark - Contact menu

// Set and return the selected chat (to auto-configure the contact menu)
- (void)setChat:(AIChat *)inChat
{
    if (chat != inChat) {
		if(chat.isGroupChat) {
			[chat removeObserver:self forKeyPath:@"Character Counter Max"];
			[chat removeObserver:self forKeyPath:@"Character Counter Prefix"];
		}
		
        chat = inChat;	
		
		// We only need to update our observation state for group chats.
		if(chat.isGroupChat) {
			[chat addObserver:self
				   forKeyPath:@"Character Counter Max"
					  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial)
					  context:NULL];
			
			[chat addObserver:self
				   forKeyPath:@"Character Counter Prefix"
					  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial)
					  context:NULL];
		}
		
		// Observe preferences changes for typing enable/disable
		[adium.preferenceController registerPreferenceObserver:self forGroup:GROUP_ACCOUNT_STATUS];
    }
	
	// Set up the character counter for this chat's list object.
	// This is done regardless of a chat changing because destination changes need to trigger this.
	if(!chat.isGroupChat) {
		[self setCharacterCounterMaximum:[chat.listObject integerValueForProperty:@"Character Counter Max"]];
		[self setCharacterCounterVisible:([chat.listObject valueForProperty:@"Character Counter Max"] != nil)];
		[self setCharacterCounterPrefix:[chat.listObject valueForProperty:@"Character Counter Prefix"]];
		
		[self updateCharacterCounter];
	}
}
- (AIChat *)chat{
    return chat;
}

// Return the selected list object (to auto-configure the contact menu)
- (AIListContact *)listObject
{
	return chat.listObject;
}

- (AIListContact *)preferredListObject
{
	return [chat preferredListObject];
}

#pragma mark - Auto-sizing

// Returns our desired size
- (NSSize)desiredSize
{
    if (_desiredSizeCached.width == 0) {
        CGFloat 		textHeight;
        if ([[self textStorage] length] != 0) {
            // If there is text in this view, let the container tell us its height

			// Force glyph generation.  We must do this or usedRectForTextContainer might only return a rect for a portion of our text.
            [[self layoutManager] glyphRangeForTextContainer:[self textContainer]];            

            textHeight = [[self layoutManager] usedRectForTextContainer:[self textContainer]].size.height;
        } else {
            // Otherwise, we use the current typing attributes to guess what the height of a line should be
			textHeight = [NSAttributedString stringHeightForAttributes:[self typingAttributes]];
        }

		/* When we called glyphRangeForTextContainer, we may have triggered re-entry via
		 *		-[self setFrame:] --> -[self frameDidChange:] --> -[self _resetCacheAndPostSizeChanged]
		 * in which case the second entry through the loop (the future relative to our conversation in this comment) got the correct desired size.
		 * In the present, an *old* value is in textHeight.  We don't want to use that. Jumping gigawatts!
		 */
		if (_desiredSizeCached.width == 0) {
			_desiredSizeCached = NSMakeSize([self frame].size.width, textHeight + ENTRY_TEXTVIEW_PADDING);
		}
    }

    return _desiredSizeCached;
}

- (void)frameDidChange:(NSNotification *)notification
{
    // Reset the desired size cache when our frame changes
	// resetCacheAndPostSizeChanged can get us right back to here, resulting in an infinite loop if we're not careful
	if (!resizing) {
		resizing = YES;
		[self _resetCacheAndPostSizeChanged];
		resizing = NO;
	}
}

//Reset the desired size cache and post a size changed notification.  Call after the text's dimensions change
- (void)_resetCacheAndPostSizeChanged
{
	//Reset the size cache
	_desiredSizeCached = NSMakeSize(0,0);

	//Post notification if size changed
	if ([self desiredSize].height != lastPostedSize.height) {
		lastPostedSize = [self desiredSize];
		[[NSNotificationCenter defaultCenter] postNotificationName:AIViewDesiredSizeDidChangeNotification object:self];
	}
}

#pragma mark - Paging

// Page up or down in the message view
- (void)scrollPageUp:(id)sender
{
    if (associatedView && [associatedView respondsToSelector:@selector(pageUp:)]) {
		[associatedView pageUp:nil];
    } else {
		[super scrollPageUp:sender];
	}
}

- (void)scrollPageDown:(id)sender
{
    if (associatedView && [associatedView respondsToSelector:@selector(pageDown:)]) {
		[associatedView pageDown:nil];
    } else {
		[super scrollPageDown:sender];
	}
}

#pragma mark - History

@synthesize historyEnabled;

// Move up through the history
- (void)historyUp
{
    if (currentHistoryLocation == 0) {
		// Store current message
        [historyArray replaceObjectAtIndex:0 withObject:[[self textStorage] copy]];
    }
	
    if (currentHistoryLocation < [historyArray count]-1) {
        // Move up
        currentHistoryLocation++;
		
        // Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
    }
}

// Move down through history
- (void)historyDown
{
    if (currentHistoryLocation > 0) {
        // Move down
        currentHistoryLocation--;
		
        // Display history
        [self setAttributedString:[historyArray objectAtIndex:currentHistoryLocation]];
	}
}

// Update history when content is sent
- (IBAction)sendContent:(id)sender
{
	NSAttributedString	*textStorage = [self textStorage];
	
	// Add to history if there is text being sent
	[historyArray insertObject:[textStorage copy] atIndex:1];
	if ([historyArray count] > MAX_HISTORY) {
		[historyArray removeLastObject];
	}

	currentHistoryLocation = 0; // Move back to bottom of history

	// Send the content
	[super sendContent:sender];
	
	// Clear the undo/redo stack as it makes no sense to carry between sends (the history is for that)
	[[self undoManager] removeAllActions];
}

// Populate the history with messages from the message history
- (void)contentObjectAdded:(NSNotification *)notification
{
	AIContentObject *content = [notification.userInfo objectForKey:@"AIContentObject"];

	if (self.chat == content.chat && ([content.type isEqualToString:CONTENT_CONTEXT_TYPE]) && content.isOutgoing) {
		//Populate the history with messages from us
		[historyArray insertObject:content.message atIndex:1];
		if (historyArray.count > MAX_HISTORY) {
			[historyArray removeLastObject];
		}
	}
}

#pragma mark - Push and Pop

// Enable/Disable push-pop
- (void)setPushPopEnabled:(BOOL)inBool
{
	pushPopEnabled = inBool;
}

// Push out of the message entry field
- (void)pushContent
{
	if ([[self textStorage] length] != 0 && pushPopEnabled) {
		[pushArray addObject:[[self textStorage] copy]];
		[self setString:@""];
		[self _setPushIndicatorVisible:YES];
	}
}

// Pop into the message entry field
- (void)popContent
{
    if ([pushArray count] && pushPopEnabled) {
        [self setAttributedString:[pushArray lastObject]];
        [self setSelectedRange:NSMakeRange([[self textStorage] length], 0)]; // selection to end
        [pushArray removeLastObject];
        
        if ([pushArray count] == 0) {
            [self _setPushIndicatorVisible:NO];
        }
    }
}

// Swap current content
- (void)swapContent
{
	if (pushPopEnabled) {
		NSAttributedString *tempMessage = [[self textStorage] copy];
				
		if ([pushArray count]) {
			[self popContent];
		} else {
			[self setString:@""];
		}
		
		if (tempMessage && [tempMessage length] != 0) {
			[pushArray addObject:tempMessage];
			[self _setPushIndicatorVisible:YES];
		}
	}
}

// Push indicator
- (void)_setPushIndicatorVisible:(BOOL)visible
{
	static NSImage *pushIndicatorImage = nil;
	
	if (!pushIndicatorImage) pushIndicatorImage = [NSImage imageNamed:@"stackImage" forClass:[self class]];

    if (visible && !pushIndicatorVisible) {
        pushIndicatorVisible = visible;
		
        // Push text over to make room for indicator
        NSSize size = [self frame].size;
        size.width -= ([pushIndicatorImage size].width);
        [self setFrameSize:size];
				
		// Make the indicator and set its action. It is a button with no border.
		pushIndicator = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, [pushIndicatorImage size].width, [pushIndicatorImage size].height)]; 
		[pushIndicator setButtonType:NSMomentaryPushButton];
        [pushIndicator setAutoresizingMask:(NSViewMinXMargin)];
        [pushIndicator setImage:pushIndicatorImage];
        [pushIndicator setImagePosition:NSImageOnly];
		[pushIndicator setBezelStyle:NSRegularSquareBezelStyle];
		[pushIndicator setBordered:NO];
        [[self superview] addSubview:pushIndicator];
		[pushIndicator setTarget:self];
		[pushIndicator setAction:@selector(popContent)];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewFrameDidChangeNotification object:[self superview]];
		
        [self positionPushIndicator]; // Set the indicators initial position
		
		// Reposition the emoticons menu button
		if ([self hasEmoticonsMenu]) {
			[self updateEmoticonsMenuButton];
		}
    } else if (!visible && pushIndicatorVisible) {
        pushIndicatorVisible = visible;

        // Push text back
        NSSize size = [self frame].size;
        size.width += [pushIndicatorImage size].width;
        [self setFrameSize:size];

		// Unsubcribe, if necessary.
		if (!characterCounter && ![self hasEmoticonsMenu]) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[self superview]];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self superview]];
		}
        
		// Remove indicator
        [pushIndicator removeFromSuperview];
        pushIndicator = nil;
		
		[self positionPushIndicator];
		
		// Reposition the emoticons menu button
		if ([self hasEmoticonsMenu]) {
			[self updateEmoticonsMenuButton];
		}
    }
}

// Reposition the push indicator into lower right corner
- (void)positionPushIndicator
{
    NSRect visRect = [[self superview] bounds];
    NSRect indFrame = [pushIndicator frame];
	CGFloat counterPadding = characterCounter ? NSWidth([characterCounter frame]) : 0;
	[pushIndicator setFrameOrigin:NSMakePoint(NSMaxX(visRect) - NSWidth(indFrame) - INDICATOR_RIGHT_PADDING - counterPadding, 
											  NSMidY([self frame]) - NSHeight(indFrame)/2)];
    [[self enclosingScrollView] setNeedsDisplay:YES];
}

#pragma mark - Indicators Positioning

/**
 * @brief Dispatch for both indicators to observe bounds & frame changes of their superview
 *
 * Stupid that this is necessary, but you can only remove an entire object from a notification center's observer list,
 * not on a per-method basis.
 * Updates emoticons menu button also.
 */
- (void)positionIndicators:(NSNotification *)notification
{
	if (pushIndicatorVisible) {
		[self positionPushIndicator];
    }
    
	if (characterCounter) {
		[self positionCharacterCounter];
    }
	
	// Update emoticons menu button
	if ([self hasEmoticonsMenu]) {
		[self updateEmoticonsMenuButton];	
	}
}

#pragma mark - Character Counter

/**
 * @brief Makes the character counter for this view visible.
 */
- (void)setCharacterCounterVisible:(BOOL)visible
{
	if (visible && !characterCounter) {
		characterCounter = [[AISimpleTextView alloc] initWithFrame:NSZeroRect];
		[characterCounter setAutoresizingMask:(NSViewMinXMargin|NSViewWidthSizable)];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:) name:NSViewFrameDidChangeNotification object:[self superview]];		

		[self updateCharacterCounter];
		[[self superview] addSubview:characterCounter];
		
	} else if (!visible && characterCounter) {	
		[characterCounter removeFromSuperview];
		
		// Make sure to resize this view back to the right size.
		NSSize size = [self frame].size;
        size.width += NSWidth([characterCounter frame]);
        [self setFrameSize:size];

		// Unsubscribe, if necessary.
		if (!pushIndicatorVisible && ![self hasEmoticonsMenu]) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[self superview]];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self superview]];
		}

		characterCounter = nil;
		
		// Reposition the push indicator, if necessary.
		if (pushIndicatorVisible) {
			[self positionPushIndicator];
        }
		
		// Reposition the emoticons menu button
		if ([self hasEmoticonsMenu]) {
			[self updateEmoticonsMenuButton];
		}
		
		[[self enclosingScrollView] setNeedsDisplay:YES];
	}
}

/*!
 * @brief Set the prefix for the character count.
 */
- (void)setCharacterCounterPrefix:(NSString *)prefix
{
	if(prefix != characterCounterPrefix) {
		characterCounterPrefix = prefix;
	}
}

/**
 * @brief Set the number of characters the character counter should count down from.
 */
- (void)setCharacterCounterMaximum:(NSInteger)inMaxCharacters
{
	maxCharacters = inMaxCharacters;
	
	if (characterCounter) {
		[self updateCharacterCounter];
    }
}

/**
 * @brief Update the character counter and resize this view to make space if the counter's bounds change.
 */
- (void)updateCharacterCounter
{
	NSRect visRect = [[self superview] bounds];
	
	NSString *inputString = [self.chat.account encodedAttributedString:[self textStorage] forListObject:self.chat.listObject];
	NSInteger currentCount = (maxCharacters - [inputString length]);

	if(maxCharacters && currentCount < 0) {
		savedTextColor = [self textColor];
		
		[self setBackgroundColor:[NSColor colorWithCalibratedHue:0.983f
													  saturation:0.43f
													  brightness:0.99f
														   alpha:1.0f]];
		
		[self.enclosingScrollView setBackgroundColor:[NSColor colorWithCalibratedHue:0.983f
																		  saturation:0.43f
																		  brightness:0.99f
																			   alpha:1.0f]];
	} else {
		if (savedTextColor) {
			[self setTextColor:savedTextColor];
			savedTextColor = nil;
		}
		
		[self setBackgroundColor:[NSColor controlBackgroundColor]];
		[self.enclosingScrollView setBackgroundColor:[NSColor controlBackgroundColor]];
	}
	
	NSString *counterText = [NSString stringWithFormat:@"%ld", currentCount];
	
	if (characterCounterPrefix) {
		counterText = [NSString stringWithFormat:@"%@%@", characterCounterPrefix, counterText];
	}
	
	NSAttributedString *label = [[NSAttributedString alloc] initWithString:counterText
																attributes:[adium.contentController defaultFormattingAttributes]];
	[characterCounter setString:label];
	[characterCounter setFrameSize:label.size];

	// Reposition the character counter.
	[self positionCharacterCounter];
	
	// Shift the text entry view over as necessary.
	CGFloat indent = 0;
	
	if (pushIndicatorVisible || characterCounter || [self hasEmoticonsMenu]) {
		CGFloat pushIndicatorX = pushIndicator ? NSMinX([pushIndicator frame]) : NSMaxX([self bounds]);
		CGFloat characterCounterX = characterCounter ? NSMinX([characterCounter frame]) : NSMaxX([self bounds]);
		CGFloat emoticonsMenuButtonX = [self emoticonsMenuButton] ? NSMinX([[self emoticonsMenuButton] frame]) : NSMaxX([self bounds]);
		indent = NSWidth(visRect) - AIfmin(pushIndicatorX, AIfmin(characterCounterX, emoticonsMenuButtonX));
	}

	[self setFrameSize:NSMakeSize(NSWidth(visRect) - indent, NSHeight([self frame]))];
	
	// Reposition the push indicator if necessary.
	if (pushIndicatorVisible)
		[self positionPushIndicator];
	
	// Reposition the emoticons menu button
	if ([self hasEmoticonsMenu]) {
		[self updateEmoticonsMenuButton];
	}
		
	[[self enclosingScrollView] setNeedsDisplay:YES];
}

/**
 * @brief Keeps the character counter in the bottom right corner.
 */
- (void)positionCharacterCounter
{
	NSRect visRect = [[self superview] bounds];
	NSSize counterSize = characterCounter.string.size;
	
	// NSMaxY([self frame]) is necessary because visRect's height changes after you start typing. No idea why.
	[characterCounter setFrameOrigin:NSMakePoint(NSMaxX(visRect) - counterSize.width - INDICATOR_RIGHT_PADDING,
												 NSMidY([self frame]) - (counterSize.height)/2)];
	[characterCounter setFrameSize:counterSize];
	[[self enclosingScrollView] setNeedsDisplay:YES];
}

#pragma mark - List Object Observer / Chat KVO

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ((inObject == chat.listObject) &&
		(!inModifiedKeys || [inModifiedKeys containsObject:@"Character Counter Max"] || [inModifiedKeys containsObject:@"Character Counter Prefix"])) {
		[self setCharacterCounterMaximum:[inObject integerValueForProperty:@"Character Counter Max"]];
		[self setCharacterCounterVisible:([inObject valueForProperty:@"Character Counter Max"] != nil)];
		[self setCharacterCounterPrefix:[inObject valueForProperty:@"Character Counter Prefix"]];
		
		[self updateCharacterCounter];
	}

	return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(object == chat && ([keyPath isEqualToString:@"Character Counter Max"] || [keyPath isEqualToString:@"Character Counter Prefix"])) {
		[self setCharacterCounterMaximum:[chat integerValueForProperty:@"Character Counter Max"]];
		[self setCharacterCounterVisible:([chat valueForProperty:@"Character Counter Max"] != nil)];
		[self setCharacterCounterPrefix:[chat valueForProperty:@"Character Counter Prefix"]];
		
		[self updateCharacterCounter];
	}
}

#pragma mark - Contextual Menus

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu			*contextualMenu = nil;
	
	NSArray			*itemsArray = nil;
	BOOL			addedOurLinkItems = NO;

	if ((contextualMenu = [super menuForEvent:theEvent])) {
		contextualMenu = [contextualMenu copy];

		NSMenuItem	*editLinkItem = nil;
		
        for (NSMenuItem *menuItem in contextualMenu.itemArray) {
			if ([[menuItem title] rangeOfString:AILocalizedString(@"Edit Link", nil)].location != NSNotFound) {
				editLinkItem = menuItem;
				break;
			}
		}

		if (editLinkItem) {
			// There was an Edit Link item.  Remove it, and add out own link editing items in its place.
			NSInteger editIndex = [contextualMenu indexOfItem:editLinkItem];
			[contextualMenu removeItem:editLinkItem];
			
			NSMenu  *linkItemsMenu = [adium.menuController contextualMenuWithLocations:[NSArray arrayWithObject:
				[NSNumber numberWithInt:Context_TextView_LinkEditing]]];
			
			for (NSMenuItem *menuItem in linkItemsMenu.itemArray) {
				[contextualMenu insertItem:[menuItem copy] atIndex:editIndex++];
			}
			
			addedOurLinkItems = YES;
		}
	} else {
		contextualMenu = [[NSMenu alloc] init];
	}

	// Retrieve the items which should be added to the bottom of the default menu
	NSArray	*locationArray = (addedOurLinkItems ?
							  [NSArray arrayWithObject:[NSNumber numberWithInt:Context_TextView_Edit]] :
							  [NSArray arrayWithObjects:[NSNumber numberWithInt:Context_TextView_LinkEditing], 
								  [NSNumber numberWithInt:Context_TextView_Edit], nil]);
	NSMenu  *adiumMenu = [adium.menuController contextualMenuWithLocations:locationArray];
	itemsArray = [adiumMenu itemArray];
	
	if ([itemsArray count] > 0) {
		[contextualMenu addItem:[NSMenuItem separatorItem]];
		NSInteger i = [contextualMenu numberOfItems];
        
		for (NSMenuItem *menuItem in itemsArray) {
			// We're going to be copying; call menu needs update now since it won't be called later.
			NSMenu	*submenu = [menuItem submenu];
			NSMenuItem	*menuItemCopy = [menuItem copy];

			if (submenu && [submenu respondsToSelector:@selector(delegate)]) {
				[[menuItemCopy submenu] setDelegate:[submenu delegate]];
			}

			[contextualMenu insertItem:menuItemCopy atIndex:i++];
		}
	}
	
    return contextualMenu;
}

#pragma mark - Drag and drop

/*An NSTextView which has setImportsGraphics:YES as of 10.5 gets the following drag types by default:
 "NeXT RTFD pasteboard type",
 "NeXT Rich Text Format v1.0 pasteboard type",
 "Apple HTML pasteboard type",
 NSFilenamesPboardType,
 "CorePasteboardFlavorType 0x6D6F6F76",
 "Apple PDF pasteboard type",
 "NeXT TIFF v4.0 pasteboard type",
 "Apple PICT pasteboard type",
 "NeXT Encapsulated PostScript v1.2 pasteboard type",
 "Apple PNG pasteboard type",
 WebURLsWithTitlesPboardType,
 "CorePasteboardFlavorType 0x75726C20",
 "Apple URL pasteboard type",
 NSStringPboardType,
 "NSColor pasteboard type",
 "NeXT font pasteboard type",
 "NeXT ruler pasteboard type",
*/

- (NSArray *)acceptableDragTypes;
{
    NSMutableArray *dragTypes;
    
    dragTypes = [NSMutableArray arrayWithArray:[super acceptableDragTypes]];
	[dragTypes addObject:AIiTunesTrackPboardType];

    return dragTypes;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];

	if ([pasteboard availableTypeFromArray:FILES_AND_IMAGES_TYPES])
		return NSDragOperationCopy;
	else 
		return [super draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	
	if ([pasteboard availableTypeFromArray:FILES_AND_IMAGES_TYPES])
		return NSDragOperationCopy;
	else 
		return [super draggingUpdated:sender];
}

// We don't need to prepare for the types we are handling in performDragOperation: below
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	NSString 		*type = [pasteboard availableTypeFromArray:FILES_AND_IMAGES_TYPES];
	NSString		*superclassType = [pasteboard availableTypeFromArray:PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY];
	BOOL			allowDragOperation;

	if (type && !superclassType) {		
		// XXX - This shouldn't let you insert into a view for which the delegate says NO to some sort of check.
		allowDragOperation = YES;
	} else {
		allowDragOperation = [super prepareForDragOperation:sender];
	}
	
	return (allowDragOperation);
}

// No conclusion is needed for the types we are handling in performDragOperation: below
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	NSString 		*type = [pasteboard availableTypeFromArray:FILES_AND_IMAGES_TYPES];
	NSString		*superclassType = [pasteboard availableTypeFromArray:PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY];
	
	
	
	if (!type || superclassType) {
		[super concludeDragOperation:sender];
	}
}

- (void)addAttachmentsFromPasteboard:(NSPasteboard *)pasteboard
{
	NSString *availableType;
	if ((availableType = [pasteboard availableTypeFromArray:[NSArray arrayWithObjects:NSFilenamesPboardType, AIiTunesTrackPboardType, nil]])) {
		// The pasteboard points to one or more files on disc.  Use them directly.
		NSArray	*files = nil;

		if ([availableType isEqualToString:NSFilenamesPboardType]) {
			files = [pasteboard propertyListForType:NSFilenamesPboardType];
			
		} else if ([availableType isEqualToString:AIiTunesTrackPboardType]) {
			files = [pasteboard filesFromITunesDragPasteboard];
		}
		
		NSString *path;
        
		for (path in files) {
			[self addAttachmentOfPath:path];
		}
	} else {
		// The pasteboard contains image data with no corresponding file.
		NSImage	*image = [[NSImage alloc] initWithPasteboard:pasteboard];
		[self addAttachmentOfImage:image];
	}	
}

// The textView's method of inserting into the view is insufficient; we can do better.
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard	*pasteboard = [sender draggingPasteboard];
	BOOL			success = NO;

	NSString *myType = [[pasteboard types] firstObjectCommonWithArray:FILES_AND_IMAGES_TYPES];
	NSString *superclassType = [[pasteboard types] firstObjectCommonWithArray:PASS_TO_SUPERCLASS_DRAG_TYPE_ARRAY];
	
	if (myType && !superclassType) {
		[self addAttachmentsFromPasteboard:pasteboard];
		
		success = YES;		
	} else {
		success = [super performDragOperation:sender];
		
	}

	return success;
}

#pragma mark - Spell Checking

/*!
 * @brief Spell checking was toggled
 *
 * Set our preference, as we toggle spell checking globally when it is changed locally
 */
- (void)toggleContinuousSpellChecking:(id)sender
{
	[super toggleContinuousSpellChecking:sender];

	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isContinuousSpellCheckingEnabled]]
                                       forKey:KEY_SPELL_CHECKING
                                        group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Grammar checking was toggled
 *
 * Set our preference, as we toggle grammar checking globally when it is changed locally
 */
- (void)toggleGrammarChecking:(id)sender
{
	[super toggleGrammarChecking:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isGrammarCheckingEnabled]]
                                       forKey:KEY_GRAMMAR_CHECKING
                                        group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

#pragma mark - Substitutions

/*!
 * @brief Dash substitution was toggled
 */
- (void)toggleAutomaticDashSubstitution:(id)sender
{
	[super toggleAutomaticDashSubstitution:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isAutomaticDashSubstitutionEnabled]]
									   forKey:KEY_SUBSTITUTION_DASH
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Data Detector substitution was toggled
 */
- (void)toggleAutomaticDataDetection:(id)sender
{
	[super toggleAutomaticDataDetection:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isAutomaticDataDetectionEnabled]]
									   forKey:KEY_SUBSTITUTION_DATA_DETECTORS
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Text Replacement substitution was toggled
 */
- (void)toggleAutomaticTextReplacement:(id)sender
{
	[super toggleAutomaticTextReplacement:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isAutomaticTextReplacementEnabled]]
									   forKey:KEY_SUBSTITUTION_REPLACEMENT
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Spelling replacement substitution was toggled
 */
- (void)toggleAutomaticSpellingCorrection:(id)sender
{
	[super toggleAutomaticSpellingCorrection:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isAutomaticSpellingCorrectionEnabled]]
									   forKey:KEY_SUBSTITUTION_SPELLING
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Smart insert delete was toggled
 */
- (void)toggleSmartInsertDelete:(id)sender
{
	[super toggleSmartInsertDelete:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self smartInsertDeleteEnabled]]
									   forKey:KEY_SUBSTITUTION_COPY_PASTE
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Smart quote substitution was toggled
 */
- (void)toggleAutomaticQuoteSubstitution:(id)sender
{
	[super toggleAutomaticQuoteSubstitution:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isAutomaticQuoteSubstitutionEnabled]]
									   forKey:KEY_SUBSTITUTION_QUOTE
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

/*!
 * @brief Smart link substitution was toggled
 */
- (void)toggleAutomaticLinkDetection:(id)sender
{
	[super toggleAutomaticLinkDetection:sender];
	
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[self isAutomaticLinkDetectionEnabled]]
									   forKey:KEY_SUBSTITUTION_LINK
										group:PREF_GROUP_DUAL_WINDOW_INTERFACE];
}

#pragma mark - Autocompleting

- (NSRange)rangeForUserCompletion
{
	NSRange completionRange = [super rangeForUserCompletion];
	
	if ([self.delegate respondsToSelector:@selector(textView:rangeForCompletion:)]) {
		completionRange = [self.delegate textView:self rangeForCompletion:completionRange];
	}
	
	return completionRange;
}

#pragma mark - Writing Direction

- (void)toggleBaseWritingDirection:(id)sender
{
	if ([self baseWritingDirection] == NSWritingDirectionRightToLeft) {
		[self setBaseWritingDirection:NSWritingDirectionLeftToRight];
	} else {
		[self setBaseWritingDirection:NSWritingDirectionRightToLeft];			
	}
	
	// Apply it immediately
	[self setBaseWritingDirection:[self baseWritingDirection]
							range:NSMakeRange(0, [[self textStorage] length])];
}

#pragma mark - Attachments

/*!
 * @brief Add an attachment of the file at inPath at the current insertion point
 *
 * @param inPath The full path, whose contents will not be loaded into memory at this time
 */
- (void)addAttachmentOfPath:(NSString *)inPath
{
	if ([[inPath pathExtension] caseInsensitiveCompare:@"textClipping"] == NSOrderedSame) {
		inPath = [inPath stringByAppendingString:@"/..namedfork/rsrc"];

		NSData *data = [NSData dataWithContentsOfFile:inPath];
		
        if (data) {
			data = [data subdataWithRange:NSMakeRange(260, [data length] - 260)];
			
			NSAttributedString *clipping = [[NSAttributedString alloc] initWithRTF:data documentAttributes:nil];
			
            if (clipping) {
				NSDictionary *attributes = [[self typingAttributes] copy];
				
				[self insertText:clipping];

				if (attributes) {
					[self setTypingAttributes:attributes];
				}
			}
		}
	} else {
		AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
		[attachment setPath:inPath];
		[attachment setString:[inPath lastPathComponent]];
		[attachment setShouldSaveImageForLogging:YES];
		
		// Insert an attributed string into the text at the current insertion point
		[self insertText:[self attributedStringWithTextAttachmentExtension:attachment]];
	}
}

/*!
 * @brief Add an attachment of inImage at the current insertion point
 */
- (void)addAttachmentOfImage:(NSImage *)inImage
{
	AITextAttachmentExtension   *attachment = [[AITextAttachmentExtension alloc] init];
	
	[attachment setImage:inImage];
	[attachment setShouldSaveImageForLogging:YES];
	
	// Insert an attributed string into the text at the current insertion point
	[self insertText:[self attributedStringWithTextAttachmentExtension:attachment]];
	
}

/*!
 * @brief Generate an NSAttributedString which contains attachment and displays it using attachment's iconImage
 */
- (NSAttributedString *)attributedStringWithTextAttachmentExtension:(AITextAttachmentExtension *)attachment
{
	NSTextAttachmentCell		*cell = [[NSTextAttachmentCell alloc] initImageCell:[attachment iconImage]];
	
	[attachment setHasAlternate:NO];
	[attachment setAttachmentCell:cell];
	
	return [NSAttributedString attributedStringWithAttachment:attachment];
}

/*!
 * @brief Given RTFD data, return an NSAttributedString whose attachments are all AITextAttachmentExtension objects
 */
- (NSAttributedString *)attributedStringWithAITextAttachmentExtensionsFromRTFDData:(NSData *)data
{
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithRTFD:data
																				documentAttributes:NULL];
	if ([attributedString length] && [attributedString containsAttachments]) {
		NSUInteger							currentLocation = 0;
		NSRange						attachmentRange;
		
		NSString					*attachmentCharacterString = [NSString stringWithFormat:@"%C",(unichar)NSAttachmentCharacter];
		
		// Find each attachment
		attachmentRange = [[attributedString string] rangeOfString:attachmentCharacterString
														   options:0 
															 range:NSMakeRange(currentLocation,
																			   [attributedString length])];
		while (attachmentRange.length != 0) {
			// Found an attachment in at attachmentRange.location
			NSTextAttachment	*attachment = [attributedString attribute:NSAttachmentAttributeName
																  atIndex:attachmentRange.location
														   effectiveRange:nil];

			// If it's not already an AITextAttachmentExtension, make it into one
			if (![attachment isKindOfClass:[AITextAttachmentExtension class]]) {
				NSAttributedString	*replacement;
				NSFileWrapper		*fileWrapper = [attachment fileWrapper];
				NSString			*destinationPath;
				NSString			*preferredName = [fileWrapper preferredFilename];
				
				// Get a unique folder within our temporary directory
				destinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
				[[NSFileManager defaultManager] createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:NULL];
				destinationPath = [destinationPath stringByAppendingPathComponent:preferredName];
				
				// Write the file out to it
				[fileWrapper writeToFile:destinationPath
							  atomically:NO
						 updateFilenames:NO];
				
				// Now create an AITextAttachmentExtension pointing to it
				AITextAttachmentExtension   *textAttachment = [[AITextAttachmentExtension alloc] init];
				[textAttachment setPath:destinationPath];
				[textAttachment setString:preferredName];
				[textAttachment setShouldSaveImageForLogging:YES];

				// Insert an attributed string into the text at the current insertion point
				replacement = [self attributedStringWithTextAttachmentExtension:textAttachment];
				
				// Remove the NSTextAttachment, replacing it the AITextAttachmentExtension
				[attributedString replaceCharactersInRange:attachmentRange
									  withAttributedString:replacement];
				
				attachmentRange.length = [replacement length];					
			} 
			
			currentLocation = attachmentRange.location + attachmentRange.length;
			
			
			// Find the next attachment
			attachmentRange = [[attributedString string] rangeOfString:attachmentCharacterString
															   options:0
																 range:NSMakeRange(currentLocation,
																				   [attributedString length] - currentLocation)];
		}
	}

	return attributedString;
}

- (void)changeDocumentBackgroundColor:(id)sender
{
	NSColor	*backgroundColor = [sender color];
	NSRange	selectedRange = [self selectedRange];

	[[self textStorage] addAttribute:NSBackgroundColorAttributeName
							   value:backgroundColor
							   range:selectedRange];
	[[self textStorage] addAttribute:AIBodyColorAttributeName
							   value:backgroundColor
							   range:selectedRange];

	NSMutableDictionary *typingAttributes = [[self typingAttributes] mutableCopy];
	[typingAttributes setObject:backgroundColor forKey:AIBodyColorAttributeName];
	[typingAttributes setObject:backgroundColor forKey:NSBackgroundColorAttributeName];
	[self setTypingAttributes:typingAttributes];

	[[self textStorage] edited:NSTextStorageEditedAttributes
						 range:selectedRange
				changeInLength:0];
}

- (void)insertText:(id)aString
{
	[super insertText:aString];
	// Auto set the writing direction based on our content
	[self setBaseWritingDirection:[[[self textStorage] string] baseWritingDirection]];
}

#pragma mark - Emoticons Menu

@synthesize emoticonsMenuButton;

/**
 * @brief Show/Hide emoticons menu
 */
- (void)setHasEmoticonsMenu:(BOOL)hasMenu
{
	if (hasMenu && emoticonsMenuButton == nil) {
		NSImage *emoticonsMenuIcon = [NSImage imageNamed:@"emoticons_menu"];
		
		emoticonsMenuButton = [[NSButton alloc] initWithFrame:NSZeroRect];
		
		[emoticonsMenuButton setFrameSize:[emoticonsMenuIcon size]];
		[emoticonsMenuButton setAutoresizingMask:NSViewMinXMargin];
        [emoticonsMenuButton setButtonType:NSMomentaryChangeButton];
        [emoticonsMenuButton setBordered:NO];
		[emoticonsMenuButton setAction:@selector(popUpEmoticonsMenu)];
		[[emoticonsMenuButton cell] setImageScaling:NSImageScaleNone];

		[emoticonsMenuButton setImage:emoticonsMenuIcon];
		
		NSImage *alternateMenuIcon = [emoticonsMenuIcon copy];
		
		// Adjust image for On/Alternate state
		[alternateMenuIcon lockFocus];
		[alternateMenuIcon drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositePlusDarker fraction:0.5f];
		[alternateMenuIcon unlockFocus];
		
		[emoticonsMenuButton setAlternateImage:alternateMenuIcon];

		// Register for notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:)
													 name:NSViewBoundsDidChangeNotification
												   object:[self superview]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(positionIndicators:)
													 name:NSViewFrameDidChangeNotification
												   object:[self superview]];		

		// Resize view to make room for the button
        NSSize size = [self frame].size;
        size.width -= ([emoticonsMenuButton frame].size.width + INDICATOR_RIGHT_PADDING);
        [self setFrameSize:size];
		
		// Reposition menu button
		[self updateEmoticonsMenuButton];

		[[self superview] addSubview:emoticonsMenuButton];

	} else if (!hasMenu && emoticonsMenuButton != nil) {	
		[emoticonsMenuButton removeFromSuperview];
		
		// Resize this view back to the right size
		NSSize size = [self frame].size;
        size.width += (NSWidth([emoticonsMenuButton frame]) + INDICATOR_RIGHT_PADDING);
        [self setFrameSize:size];
		
		// Unsubscribe, if necessary
		if (!pushIndicatorVisible && !characterCounter) {
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewBoundsDidChangeNotification object:[self superview]];
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:[self superview]];
		}
		
		emoticonsMenuButton = nil;
		
		[[self enclosingScrollView] setNeedsDisplay:YES];
	}

    hasEmoticonsMenu = hasMenu;
}

- (BOOL)hasEmoticonsMenu
{
    return hasEmoticonsMenu;
}

/**
 * @brief Update the emoticons menu button
 * 
 * Position should be fixed at bottom right corner
 */
- (void)updateEmoticonsMenuButton
{
	NSRect visibleRect = [[self superview] bounds];
	NSSize menuButtonSize = [[self emoticonsMenuButton] frame].size;
	
	CGFloat indicatorsWidth = (characterCounter && (visibleRect.size.height / 3.0f) <= menuButtonSize.height + 4.0f) ? NSWidth([characterCounter frame]) + INDICATOR_RIGHT_PADDING : 0.0f;
	indicatorsWidth += (pushIndicatorVisible && (visibleRect.size.height / 3.0f) <= menuButtonSize.height + 4.0f) ? NSWidth([pushIndicator frame]) + INDICATOR_RIGHT_PADDING : 0.0f;
	
	// NSMaxY([self frame]) is necessary because visibleRect's height changes after you start typing
	CGFloat newPositionY = (indicatorsWidth > 0.0f) ? NSMidY([self frame]) - (menuButtonSize.height / 2.0f)
													: NSMaxY([self frame]) - menuButtonSize.height - 2.0f;
	
	[[self emoticonsMenuButton] setFrameOrigin:NSMakePoint(NSMaxX(visibleRect) - menuButtonSize.width - INDICATOR_RIGHT_PADDING - indicatorsWidth, newPositionY)];
	
	[[self enclosingScrollView] setNeedsDisplay:YES];
}

/**
 * @brief Open emoticons menu
 */
- (void)popUpEmoticonsMenu
{
    if ([self hasEmoticonsMenu]) {
		NSRect menuButtonRect = [[self emoticonsMenuButton] frame];

    	[AIMessageViewEmoticonsController popUpMenuForTextView:self atPoint:NSMakePoint(menuButtonRect.origin.x + menuButtonRect.size.width - INDICATOR_RIGHT_PADDING, menuButtonRect.origin.y + menuButtonRect.size.height)];
    }
}

@end

#pragma mark -

@implementation NSMutableAttributedString (AIMessageEntryTextViewAdditions)

- (void)convertForPasteWithTraitsUsingAttributes:(NSDictionary *)typingAttributes;
{
	NSRange fullRange = NSMakeRange(0, [self length]);

	// Remove non-trait attributes
	if ([typingAttributes objectForKey:NSBackgroundColorAttributeName]) {
		[self addAttribute:NSBackgroundColorAttributeName
					 value:[typingAttributes objectForKey:NSBackgroundColorAttributeName]
					 range:fullRange];

	} else {
		[self removeAttribute:NSBackgroundColorAttributeName range:fullRange];
	}

	if ([typingAttributes objectForKey:NSForegroundColorAttributeName]) {
		[self addAttribute:NSForegroundColorAttributeName
					 value:[typingAttributes objectForKey:NSForegroundColorAttributeName]
					 range:fullRange];
		
	} else {
		[self removeAttribute:NSForegroundColorAttributeName range:fullRange];
	}

	if ([typingAttributes objectForKey:NSParagraphStyleAttributeName]) {
		[self addAttribute:NSParagraphStyleAttributeName
					 value:[typingAttributes objectForKey:NSParagraphStyleAttributeName]
					 range:fullRange];
		
	} else {
		[self removeAttribute:NSParagraphStyleAttributeName range:fullRange];
	}

	[self removeAttribute:NSBaselineOffsetAttributeName range:fullRange];
	[self removeAttribute:NSCursorAttributeName range:fullRange];
	[self removeAttribute:NSExpansionAttributeName range:fullRange];
	[self removeAttribute:NSKernAttributeName range:fullRange];
	[self removeAttribute:NSLigatureAttributeName range:fullRange];
	[self removeAttribute:NSObliquenessAttributeName range:fullRange];
	[self removeAttribute:NSShadowAttributeName range:fullRange];
	[self removeAttribute:NSStrokeWidthAttributeName range:fullRange];
	
	NSRange			searchRange = NSMakeRange(0, fullRange.length);
	NSFontManager	*fontManager = [NSFontManager sharedFontManager];
	NSFont			*myFont = [typingAttributes objectForKey:NSFontAttributeName];

	while (searchRange.location < fullRange.length) {
		NSFont *font;
		NSRange effectiveRange;
		font = [self attribute:NSFontAttributeName 
					   atIndex:searchRange.location
		 longestEffectiveRange:&effectiveRange
					   inRange:searchRange];

		if (font) {
			NSFontTraitMask thisFontTraits = [fontManager traitsOfFont:font];
			NSFontTraitMask	traits = 0;
			
			if (thisFontTraits & NSBoldFontMask) {
				traits |= NSBoldFontMask;
			} else {
				traits |= NSUnboldFontMask;				
			}

			if (thisFontTraits & NSItalicFontMask) {
				traits |= NSItalicFontMask;
			} else {
				traits |= NSUnitalicFontMask;
			}
			
			font = [fontManager fontWithFamily:[myFont familyName]
										traits:traits
										weight:[fontManager weightOfFont:myFont]
										  size:[myFont pointSize]];
			 
			if (font) {
				[self addAttribute:NSFontAttributeName
							 value:font
							 range:effectiveRange];
			}
		}

		searchRange.location = effectiveRange.location + effectiveRange.length;
		searchRange.length = fullRange.length - searchRange.location;
	}

	// Replace attachments with nothing! Absolutely nothing!
	[self convertAttachmentsToStringsUsingPlaceholder:@""];
}

@end
