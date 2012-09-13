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

#import <Adium/ESTextAndButtonsWindowController.h>

#define TEXT_AND_BUTTONS_WINDOW_NIB   @"TextAndButtonsWindow"

@interface ESTextAndButtonsWindowController ()
- (void)configureWindow;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation ESTextAndButtonsWindowController

/*!
 * @brief Show a text and buttons window which will notify a target when a button is clicked or the window is closed.
 *
 * The buttons have titles of defaultButton, alternateButton, and otherButton.
 * The buttons are laid out on the lower-right corner of the window, with defaultButton on the right, alternateButton on
 * the left, and otherButton in the middle. 
 *
 * If defaultButton is nil or an empty string, a default localized button title (“OK” in English) is used. 
 * For the remaining buttons, the window displays them only if their corresponding button title is non-nil.
 *
 * @param inTitle Window title
 * @param inDefaultButton Rightmost button.  Localized OK if nil.
 * @param inAlternateButton Leftmost button.  Hidden if nil.
 * @param inOtherButton Middle button.  Hidden if nil. inAlternateButton must be non-nil for inOtherButton to be used.
 * @param parentWindow Window on which to display as a sheet.  Displayed as a normal window if nil.
 * @param inMessageHeader A plain <tt>NSString</tt> which will be displayed as a bolded header for the message.  Hidden if nil.
 * @param inMessage The <tt>NSAttributedString</tt> which is the body of text for the window.
 * @param inImage The NSImage to display; if nil, the default application icon will be shown
 * @param inTarget The target to send the selector <tt>textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo</tt> when the sheet ends.
 * @param inUserInfo User info which will be passed back to inTarget
 *
 * @see AITextAndButtonsReturnCode
 *
 * @result A initialized <tt>ESTextAndButtonsWindowController</tt>.
 */
- (id)initWithTitle:(NSString *)inTitle
	  defaultButton:(NSString *)inDefaultButton
	alternateButton:(NSString *)inAlternateButton
		otherButton:(NSString *)inOtherButton
		suppression:(NSString *)inSuppression
  withMessageHeader:(NSString *)inMessageHeader
		 andMessage:(NSAttributedString *)inMessage
			  image:(NSImage *)inImage
			 target:(id)inTarget
		   userInfo:(id)inUserInfo
{
	if (self = [self init]) {
		[self changeWindowToTitle:inTitle
					defaultButton:inDefaultButton
				  alternateButton:inAlternateButton
					  otherButton:inOtherButton
					  suppression:inSuppression
				withMessageHeader:inMessageHeader
					   andMessage:inMessage
							image:inImage
						   target:inTarget
						 userInfo:inUserInfo];
	}
	
	return self;
}

- (id)init
{
	if (self = [super initWithWindowNibName:TEXT_AND_BUTTONS_WINDOW_NIB]) {
		
	}
	
	return self;
}

- (void)showOnWindow:(NSWindow *)parentWindow
{
	if (parentWindow) {
		[NSApp beginSheet:self.window
		   modalForWindow:parentWindow
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
		
	} else {
		[self show];
	}
}

- (id)initWithTitle:(NSString *)inTitle
						  defaultButton:(NSString *)inDefaultButton
						alternateButton:(NSString *)inAlternateButton
							otherButton:(NSString *)inOtherButton
					  withMessageHeader:(NSString *)inMessageHeader
							 andMessage:(NSAttributedString *)inMessage
								 target:(id)inTarget
							   userInfo:(id)inUserInfo
{
	return [self initWithTitle:inTitle
				 defaultButton:inDefaultButton
			   alternateButton:inAlternateButton
				   otherButton:inOtherButton
				   suppression:nil
			 withMessageHeader:inMessageHeader
					andMessage:inMessage
						 image:nil
						target:inTarget
					  userInfo:inUserInfo];
}

/*!
 * @brief Change and show a text and buttons window which will notify a target when a button is clicked or the window is closed. 
 *
 * The buttons have titles of defaultButton, alternateButton, and otherButton.
 * The buttons are laid out on the lower-right corner of the window, with defaultButton on the right, alternateButton on
 * the left, and otherButton in the middle. 
 *
 * If defaultButton is nil or an empty string, a default localized button title (“OK” in English) is used. 
 * For the remaining buttons, the window displays them only if their corresponding button title is non-nil.
 *
 * @param inTitle Window title
 * @param inDefaultButton Rightmost button.  Localized OK if nil.
 * @param inAlternateButton Leftmost button.  Hidden if nil.
 * @param inOtherButton Middle button.  Hidden if nil. inAlternateButton must be non-nil for inOtherButton to be used.
 * @param inMessageHeader A plain <tt>NSString</tt> which will be displayed as a bolded header for the message.  Hidden if nil.
 * @param inMessage The <tt>NSAttributedString</tt> which is the body of text for the window.
 * @param inImage The NSImage to display; if nil, the default application icon will be shown
 * @param inTarget The target to send the selector <tt>textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo</tt> when the sheet ends.
 * @param inUserInfo User info which will be passed back to inTarget
 *
 * @see AITextAndButtonsReturnCode
 */
- (void)changeWindowToTitle:(NSString *)inTitle
			  defaultButton:(NSString *)inDefaultButton
			alternateButton:(NSString *)inAlternateButton
				otherButton:(NSString *)inOtherButton
				suppression:(NSString *)inSuppression
		  withMessageHeader:(NSString *)inMessageHeader
				 andMessage:(NSAttributedString *)inMessage
					  image:(NSImage *)inImage
					 target:(id)inTarget
				   userInfo:(id)inUserInfo
{
	[title release];
	[defaultButton release];
	[alternateButton release];
	[otherButton release];
	[suppression release];
	[messageHeader release];
	[message release];
	[target release];
	[userInfo release];
	[image release];
	
	title = [inTitle retain];
	defaultButton = [inDefaultButton retain];
	alternateButton = ([inAlternateButton length] ? [inAlternateButton retain] : nil);
	otherButton = ([inOtherButton length] ? [inOtherButton retain] : nil);
	suppression = ([inSuppression length] ? [inSuppression retain] : nil);
	messageHeader = ([inMessageHeader length] ? [inMessageHeader retain] : nil);
	message = [inMessage retain];
	target = [inTarget retain];
	userInfo = [inUserInfo retain];
	image = [inImage retain];

	userClickedButton = NO;
	allowsCloseWithoutResponse = YES;
	[self configureWindow];
}

- (void)show
{
	[self showWindow:nil];
	[[self window] orderFront:nil];
}

/*!
 * @brief Can the window be closed without clicking one of the buttons?
 */
- (void)setAllowsCloseWithoutResponse:(BOOL)inAllowsCloseWithoutResponse
{
	allowsCloseWithoutResponse = inAllowsCloseWithoutResponse;
	
	[[[self window] standardWindowButton:NSWindowCloseButton] setEnabled:allowsCloseWithoutResponse];
}

/*!
 * @brief Set the image
 */
- (void)setImage:(NSImage *)inImage;
{
	if (inImage != image) {
		[image release];
		image = [inImage retain];
		[imageView setImage:image];
	}
}

- (void)setKeyEquivalent:(NSString *)keyEquivalent modifierMask:(unsigned int)mask forButton:(AITextAndButtonsWindowButton)windowButton
{
	NSButton *button = nil;
	switch (windowButton) {		
		case AITextAndButtonsWindowButtonDefault:
			button = button_default;
			break;

		case AITextAndButtonsWindowButtonAlternate:
			button = button_alternate;
			break;

		case AITextAndButtonsWindowButtonOther:
			button = button_other;
			break;
	}

	[button setKeyEquivalent:keyEquivalent];
	[button setKeyEquivalentModifierMask:mask];
}

/*!
 * @brief Refuse to let the window close, if allowsCloseWithoutResponse = NO
 */
- (BOOL)windowShouldClose:(id)sender
{
	if (!userClickedButton) {
		if (allowsCloseWithoutResponse) {
			//Notify the target that the window closed with no response
			[target textAndButtonsWindowDidEnd:[self window]
									returnCode:AITextAndButtonsClosedWithoutResponse
								   suppression:checkbox_suppression.state
									  userInfo:userInfo];
		} else {
			//Don't allow the close
			NSBeep();
			return NO;
		}
	}
	
	return YES;
}

/*!
 * @brief Perform behaviors before the window closes
 *
 * If the user did not click a button to get us here, inform the target that the window closed
 * with no response, sending it the AITextAndButtonsClosedWithoutResponse return code (default behavior)
 *
 * As our window is closing, we auto-release this window controller instance.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
	[self autorelease];
	
	//Release our target immediately to avoid a potential mutual retain (if the target is retaining us)
	[target release]; target = nil;
}

/*!
 * @brief Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];
	
	[self autorelease];
}

/*!
 * @brief Configure the window.
 *
 * Here we perform configuration and autosizing for our message and buttons.
 */

- (void)configureWindow
{
	NSWindow	*window = [self window];
	CGFloat		heightChange = 0;
	NSInteger	distanceFromBottomOfMessageToButtons = 24;
	NSRect		windowFrame = [window frame];

	//Set the image if we have one
	if (image) {
		[imageView setImage:image];
	}

	//Hide the toolbar and zoom buttons
	[[window standardWindowButton:NSWindowToolbarButton] setFrame:NSZeroRect];
	[[window standardWindowButton:NSWindowZoomButton]    setFrame:NSZeroRect];
	
	//Title
	if (title) {
		[window setTitle:title];
	} else {
		[window setExcludedFromWindowsMenu:YES];
	}

	//Message header
	if (messageHeader) {
		NSRect messageHeaderFrame = [scrollView_messageHeader frame];

		//Resize the window frame to fit the error title
		[textView_messageHeader setVerticallyResizable:YES];
		[textView_messageHeader setDrawsBackground:NO];
		[scrollView_messageHeader setDrawsBackground:NO];
		[textView_messageHeader setString:messageHeader];
		
		[textView_messageHeader sizeToFit];
		heightChange += [textView_messageHeader frame].size.height - [scrollView_messageHeader documentVisibleRect].size.height;
		messageHeaderFrame.size.height += heightChange;
		messageHeaderFrame.origin.y -= heightChange;
		
		[scrollView_messageHeader setFrame:messageHeaderFrame];

	} else {
		NSRect messageHeaderFrame = [scrollView_messageHeader frame];
		NSRect scrollFrame = [scrollView_message frame];
		
		//Remove the header area
		if ([scrollView_messageHeader respondsToSelector:@selector(setHidden:)]) {
			[scrollView_messageHeader setHidden:YES];
		} else {
			[scrollView_messageHeader setFrame:NSZeroRect];	
		}
		
		//verticalChange is how far we can move our message area up since we don't have a messageHeader
		CGFloat verticalChange = (messageHeaderFrame.size.height +
							  (messageHeaderFrame.origin.y - (scrollFrame.origin.y+scrollFrame.size.height)));

		scrollFrame.size.height += verticalChange;

		[scrollView_message setFrame:scrollFrame];
	}

	//Set the message, then change the window size accordingly
	{
		CGFloat		messageHeightChange;

		[textView_message setVerticallyResizable:YES];
		[textView_message setDrawsBackground:NO];
		[scrollView_message setDrawsBackground:NO];
		
		[[textView_message textStorage] setAttributedString:message];
		[textView_message sizeToFit];
		messageHeightChange = [textView_message frame].size.height - [scrollView_message documentVisibleRect].size.height;
		heightChange += messageHeightChange;

		NSRect	messageFrame = [scrollView_message frame];
		messageFrame.origin.y -= heightChange;
		if (messageHeightChange > 0) {
			messageFrame.size.height += messageHeightChange;
		}
		
		[scrollView_message setFrame:messageFrame];
		[scrollView_message setNeedsDisplay:YES];
	}
	
	if (suppression) {
		NSRect	optionFrame = [checkbox_suppression frame];
		optionFrame.origin.y -= heightChange;
		heightChange += optionFrame.size.height;
		
		[checkbox_suppression setFrame:optionFrame];
		[checkbox_suppression setLocalizedString:suppression];
		[checkbox_suppression setState:NSOffState];
	} else {
		[checkbox_suppression setHidden:YES];
	}
	
	/* distanceFromBottomOfMessageToButtons pixels from the original bottom of scrollView_message to the
	 * proper positioning above the buttons; after that, the window needs to expand.
	 */
	if (heightChange > distanceFromBottomOfMessageToButtons) {
		windowFrame.size.height += (heightChange - distanceFromBottomOfMessageToButtons);
		windowFrame.origin.y -= (heightChange - distanceFromBottomOfMessageToButtons);
	}
	
	//Set the default button
	NSRect newFrame;

	[button_default setTitle:(defaultButton ? defaultButton : AILocalizedString(@"OK",nil))];
	[button_default sizeToFit];
	
	newFrame = [button_default frame];

	/* For NSButtons, sizeToFit is 8 pixels smaller than the HIG recommended size  */
	newFrame.size.width += 8;
	/* Only use integral widths to keep alignment correct; round up as an extra pixel of whitespace never hurt anybody */
	newFrame.size.width = AIround(NSWidth(newFrame) + 0.5f);
	if (newFrame.size.width < 90) newFrame.size.width = 90;
	newFrame.origin.x = NSWidth([window frame]) - NSWidth(newFrame) - 14;

	[button_default setFrame:newFrame];
	
	//Set the alternate button if we were provided one, otherwise hide it
	if (alternateButton) {
		[button_alternate setTitle:alternateButton];
		[button_alternate sizeToFit];
		
		newFrame = [button_alternate frame];
		/* For NSButtons, sizeToFit is 8 pixels smaller than the HIG recommended size  */
		newFrame.size.width += 8;
		/* Only use integral widths to keep alignment correct; round up as an extra pixel of whitespace never hurt anybody */
		newFrame.size.width = AIround(NSWidth(newFrame) + 0.5f);
		if (newFrame.size.width < 90) newFrame.size.width = 90;
		newFrame.origin.x = NSMinX([button_default frame]) - NSWidth(newFrame) + 2;

		[button_alternate setFrame:newFrame];

		//Set the other button if we were provided one, otherwise hide it
		if (otherButton) {
			[window setFrame:windowFrame display:NO animate:NO];
			
			NSRect oldFrame = [button_other frame];

			[button_other setTitle:otherButton];

			[button_other sizeToFit];
			
			newFrame = [button_other frame];
			/* For NSButtons, sizeToFit is 8 pixels smaller than the HIG recommended size  */
			newFrame.size.width += 8;
			/* Only use integral widths to keep alignment correct; round up as an extra pixel of whitespace never hurt anybody */
			newFrame.size.width = AIround(NSWidth(newFrame) + 0.5f);
			if (newFrame.size.width < 90) newFrame.size.width = 90;

			newFrame.origin.x = NSMinX([button_alternate frame]) - 36 - NSWidth(newFrame);
			
			[button_other setFrame:newFrame];
			
			//Increase the window size to keep our origin in the same location after resizing
			NSUInteger oldAutosizingMask = [button_other autoresizingMask]; 
			[button_other setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];
			windowFrame.size.width += oldFrame.origin.x - newFrame.origin.x;
			[window setFrame:windowFrame display:NO animate:NO];
			if (NSMinX([button_other frame]) < 18) {
				//Keep the left side far enough away from the left side of the window
				windowFrame.size.width += 18 - NSMinX([button_other frame]);
				[window setFrame:windowFrame display:NO animate:NO];				
			}

			[button_other setAutoresizingMask:oldAutosizingMask];

		} else {
			[button_other setHidden:YES];
		}
		
	} else {
		[button_alternate setHidden:YES];
		[button_other setHidden:YES];
	}
	
	//Resize the window to fit the message
	[window setFrame:windowFrame display:NO animate:NO];
	
    //Center the window (if we're not a sheet)
    [window center];
	[window display];
}

- (IBAction)pressedButton:(id)sender
{
	AITextAndButtonsReturnCode returnCode;
	
	userClickedButton = YES;

	if (sender == button_default)
		returnCode = AITextAndButtonsDefaultReturn;
	else if (sender == button_alternate)
		returnCode = AITextAndButtonsAlternateReturn;			
	else if (sender == button_other)
		returnCode = AITextAndButtonsOtherReturn;
	else
		returnCode = AITextAndButtonsClosedWithoutResponse;

	//Notify the target
	if ([target textAndButtonsWindowDidEnd:[self window]
								returnCode:returnCode
							   suppression:checkbox_suppression.state
								  userInfo:userInfo]) {
		
		//Close the window if the target returns YES
		[self closeWindow:nil];
	}
}

/*!
 * @brief If escape or return are pressed inside one of our text views, pass the action on to our buttons
 */
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	NSButton *equivalentButton = nil;

	AILogWithSignature(@"escape? %i newline? %i",[[button_alternate keyEquivalent] isEqualToString:@"\E"],[[button_default keyEquivalent] isEqualToString:@"\n"]);

	if (aSelector == @selector(cancelOperation:) &&
		[[button_alternate keyEquivalent] isEqualToString:@"\E"]) {
		equivalentButton = button_alternate;

	} else if (((aSelector == @selector(insertNewline:)) || (aSelector == @selector(insertNewlineIgnoringFieldEditor:))) &&
			   [[button_default keyEquivalent] isEqualToString:@"\n"]) {
		equivalentButton = button_default;

	}
	
	if (equivalentButton) {
		[equivalentButton performClick:aTextView];
		return YES;

	} else {
		return NO;
	}
}


- (void)dealloc
{
	[title release];
	[defaultButton release];
	[target release];
	[alternateButton release];
	[otherButton release];
	[messageHeader release];
	[message release];
	[userInfo release];
	[image release];

	[super dealloc];
}

@end
