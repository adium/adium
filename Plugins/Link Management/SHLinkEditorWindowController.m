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

#import "SHLinkEditorWindowController.h"
#import "SHAutoValidatingTextView.h"
#import <AutoHyperlinks/AHLinkLexer.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>

#define LINK_EDITOR_NIB_NAME @"LinkEditor"

@interface SHLinkEditorWindowController ()

- (void)informTargetOfLink;

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end

@interface NSObject (SHLinkEditorAdditions)

- (void)linkEditorLinkDidChange:(NSDictionary *)linkDict;

@end

@implementation SHLinkEditorWindowController

#pragma mark Init methods

- (void)showOnWindow:(NSWindow *)parentWindow
{
	if (parentWindow) {
		[NSApp beginSheet:self.window
		   modalForWindow:parentWindow
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[self showWindow:nil];
	}
}

- (id)initWithTextView:(NSTextView *)inTextView notifyingTarget:(id)inTarget

{
    if ((self = [super initWithWindowNibName:LINK_EDITOR_NIB_NAME])) {
		textView = [inTextView retain];
		target = [inTarget retain];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[textView release];
	[target release];
    [super dealloc];
}

#pragma mark Window Methods

- (void)windowDidLoad
{
	[button_insert setLocalizedString:AILocalizedString(@"Insert",nil)];
    [button_cancel setLocalizedString:AILocalizedString(@"Cancel",nil)];
	[button_removeLink setLocalizedString:AILocalizedString(@"Remove Link",nil)];	
	[label_linkText setLocalizedString:AILocalizedString(@"Link Text:","Label for the text entry area for the name when creating a link")];
	[label_URL setLocalizedString:AILocalizedString(@"URL:",nil)];

	if (textView) {
		NSRange 	selectedRange = [textView selectedRange];
		NSRange		rangeOfLinkAttribute;
		NSString    *linkText;
		id   	 	linkURL = nil;
		
		// Text is selected if the selected range is greater than 0!
		if (selectedRange.length > 0) {
			linkURL = [[textView textStorage] attribute:NSLinkAttributeName
												atIndex:selectedRange.location
										 effectiveRange:&rangeOfLinkAttribute];
		}
		
		if (linkURL) {
			// If a link exists at our selection, expand the selection to encompass that entire link
			[textView setSelectedRange:rangeOfLinkAttribute];
			selectedRange = rangeOfLinkAttribute;
		} else {
			// Fill the URL field from the pasteboard if possible
			NSPasteboard 	*pboard = [NSPasteboard generalPasteboard];
			NSString 		*availableType = [pboard availableTypeFromArray:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil]];
			
			if (availableType) {
				if ([availableType isEqualToString:NSURLPboardType]) {
					linkURL = [[NSURL URLFromPasteboard:pboard] absoluteString];

				} else { /* NSStringPboardType */
					linkURL = [pboard stringForType:NSStringPboardType];
				}
			}

			if (linkURL) {
				// Only use the pasteboard if it contains a valid URL; otherwise it most likely is not intended for us.
				if (![AHHyperlinkScanner isStringValidURI:linkURL usingStrict:NO fromIndex:0U withStatus:NULL schemeLength:NULL]) {
					linkURL = nil;
				}
			}
		}
		
		// Get the selected text
		linkText = [[textView attributedSubstringFromRange:selectedRange] string];
		
		// Place the link title and URL in our panel. Automatically select the URL.
		if (linkURL) {
			NSString	*tmpString = ([linkURL isKindOfClass:[NSString class]] ? 
									  (NSString *)linkURL : 
									  [(NSURL *)linkURL absoluteString]);
			
			tmpString = (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,
																			   (CFStringRef)tmpString,
																			   CFSTR(""));
			
			if (tmpString) {
				NSAttributedString	*initialURL;
				
				initialURL = [[NSAttributedString alloc] initWithString:tmpString];
				[[textView_URL textStorage] setAttributedString:initialURL];
				[textView_URL setSelectedRange:NSMakeRange(0,[initialURL length])];
				[initialURL release];
				
				[tmpString release];
			}

		} else if ([linkText length]) {
			// Focus the URL field so that the user can enter an URL right away.
			[[self window] makeFirstResponder:textView_URL];
		}

		if (linkText && [linkText length]) {
			[textField_linkText setStringValue:linkText];
		}
	}

    // Turn on URL validation for our textView
    [textView_URL setContinuousURLValidationEnabled:YES];
	
	[scrollView_URL setAlwaysDrawFocusRingIfFocused:YES];
}

// Window is closing
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	[self autorelease];
}

// Called as the sheet closes, dismisses the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
	[self autorelease];
}

// Cancel
- (IBAction)cancel:(id)sender
{
    [self closeWindow:sender];
}

#pragma mark AttributedString Wrangleing Methods

- (IBAction)acceptURL:(id)sender
{
	NSMutableString *urlString = [[textView_URL linkURL] mutableCopy];
	NSString		*linkString  = [textField_linkText stringValue];
	NSURL			*URL;
	
	// Pre-fix the url if necessary
	switch ([textView_URL validationStatus]) {
		case AH_URL_DEGENERATE:
			[urlString insertString:@"http://" atIndex:0];
			break;
		case AH_MAILTO_DEGENERATE:
			[urlString insertString:@"mailto:" atIndex:0];
			break;
		default:
			break;
	}

	// Insert it into the text view
	if ((URL = [NSURL URLWithString:urlString])) {
		[SHLinkEditorWindowController insertLinkTo:URL
										  withText:linkString
											inView:textView];
		// Inform our target of the new link and close up
		[self informTargetOfLink];
		[self closeWindow:nil];
		
	} else {
		// If the URL is invalid enough that we can't create an NSURL, just beep
		NSBeep();
	}

	[urlString release];
}

- (IBAction)removeURL:(id)sender
{
    if ([[textView textStorage] length] &&
       [textView selectedRange].location != NSNotFound &&
       [textView selectedRange].location != [[textView textStorage] length]) {
            NSRange selectionRange = [textView selectedRange];
            // Get range
            [[textView textStorage] attribute:NSLinkAttributeName
									  atIndex:selectionRange.location
							   effectiveRange:&selectionRange];
			// Remove the link from it
            [[textView textStorage] removeAttribute:NSLinkAttributeName range:selectionRange];
    }
    [self closeWindow:nil];
}

// Inform our target of the link currently in our panel
- (void)informTargetOfLink
{
	// We need to make sure we're getting copies of these, otherwise the fields will change them later, changing the
	// copy in our dictionary
	NSDictionary	*linkDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[[[textField_linkText stringValue] copy] autorelease], KEY_LINK_TITLE,
		[textView_URL linkURL], KEY_LINK_URL,
		nil];
	
	if ([target respondsToSelector:@selector(linkEditorLinkDidChange:)]) {
		[target performSelector:@selector(linkEditorLinkDidChange:) withObject:linkDict];
	}
}

// Insert a link into a text view
+ (void)insertLinkTo:(NSURL *)linkURL withText:(NSString *)linkTitle inView:(NSTextView *)inView
{
	//Bail if we don't have a link; use the link as the title if no title was sent
	if (!linkURL)
		return;
	if (linkTitle.length == 0)
		linkTitle = linkURL.path;
	
    NSDictionary				*typingAttributes = [inView typingAttributes];
	NSTextStorage				*textStorage = [inView textStorage];
	NSMutableAttributedString	*linkString;
	
	// Create the link string
	linkString = [[[NSMutableAttributedString alloc] initWithString:linkTitle
														 attributes:typingAttributes] autorelease];
    [linkString addAttribute:NSLinkAttributeName value:linkURL range:NSMakeRange(0,[linkString length])];
    
	// Insert it into the text view, replacing the current selection
	[[inView undoManager] beginUndoGrouping];
	[[[inView undoManager] prepareWithInvocationTarget:textStorage]
				replaceCharactersInRange:NSMakeRange([inView selectedRange].location, [linkString length])
					withAttributedString:[textStorage attributedSubstringFromRange:[inView selectedRange]]];

	[textStorage replaceCharactersInRange:[inView selectedRange] withAttributedString:linkString];

	// If this link was inserted at the end of our text view, add a space and set the formatting back to normal
	// This prevents the link attribute from bleeding into newly entered text
	if (NSMaxRange([inView selectedRange]) == [textStorage length]) {
		NSAttributedString	*tmpString = [[[NSAttributedString alloc] initWithString:@" "
																		  attributes:typingAttributes] autorelease];
		[[[inView undoManager] prepareWithInvocationTarget:textStorage]
				replaceCharactersInRange:NSMakeRange(NSMaxRange([inView selectedRange]), 1)
					withAttributedString:[[[NSAttributedString alloc] initWithString:@""
																		  attributes:typingAttributes] autorelease]];
		[textStorage appendAttributedString:tmpString];
	}
	
	// Notify that a change occurred since NSTextStorage won't do it for us
	[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
														object:inView
													  userInfo:nil];
	[[inView undoManager] setActionName:AILocalizedString(@"Add Link", nil)];
	[[inView undoManager] endUndoGrouping];
}

#pragma mark URL Validation and other Delegate Oddities

- (void)textDidChange:(NSNotification *)aNotification
{
    // Validate our URL
    [textView_URL textDidChange:aNotification];
    [imageView_invalidURLAlert setHidden:[textView_URL isURLValid]];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if (aSelector == @selector(insertNewline:)) {
            [self acceptURL:nil];
            return YES;

    } else if (aSelector == @selector(insertTab:)) {
		[[textView_URL window] selectNextKeyView:self];
		return YES;
		
	} else if (aSelector == @selector(insertBacktab:)) {
		[[textView_URL window] selectPreviousKeyView:self];
		return YES;
	}
	
    return NO;
}

@end
