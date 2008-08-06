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

#import <AIUtilities/AISendingTextView.h>
#import <Adium/AIAdiumProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>

@class AIListContact, AIAccount, AIChat;

@interface AISimpleTextView : NSView {
	NSAttributedString *string;
}
- (void)setString:(NSAttributedString *)inString;
@end


@interface AIMessageEntryTextView : AISendingTextView <AITextEntryView, AIListObjectObserver> {
    AIChat				*chat;
    
    BOOL                 clearOnEscape;
	BOOL				 historyEnabled;
    BOOL                 pushPopEnabled;
	BOOL				 homeToStartOfLine;
	BOOL				 enableTypingNotifications;

    NSMutableArray		*historyArray;
    int                  currentHistoryLocation;

    NSMutableArray		*pushArray;
    BOOL                 pushIndicatorVisible;
    NSButton			*pushIndicator;
    NSMenu              *pushMenu;
    NSDictionary		*defaultTypingAttributes;
	
    NSSize               lastPostedSize;
    NSSize               _desiredSizeCached;
	BOOL				 resizing;
    
    NSView              *associatedView;
	
	AISimpleTextView	*characterCounter;
	int					maxCharacters;
}

//Configure
- (void)setClearOnEscape:(BOOL)inBool;
- (void)setHomeToStartOfLine:(BOOL)inBool;
- (void)setAssociatedView:(NSView *)inView;
- (NSView *)associatedView;

//Adium Text Entry
- (void)setAttributedString:(NSAttributedString *)inAttributedString;
- (void)setString:(NSString *)string;
- (void)setTypingAttributes:(NSDictionary *)attrs;
- (void)pasteAsRichText:(id)sender;
- (NSSize)desiredSize;

//Context
- (void)setChat:(AIChat *)inChat;
- (AIChat *)chat;
- (AIListContact *)listObject;

//Paging
- (void)scrollPageUp:(id)sender;
- (void)scrollPageDown:(id)sender;

//History
- (void)setHistoryEnabled:(BOOL)inHistoryEnabled;
- (void)historyUp;
- (void)historyDown;

//Push and Pop
- (void)setPushPopEnabled:(BOOL)inBool;
- (void)pushContent;
- (void)popContent;
- (void)swapContent;

@end

@interface NSObject (AIMessageEntryTextViewDelegate)
/*!
 * @brief Should the tab key trigger an autocomplete?
 *
 * Implementation is optional.
 */
- (BOOL)textViewShouldTabComplete:(NSTextView *)inTextView;

- (void)textViewDidCancel:(NSTextView *)inTextView;
@end
