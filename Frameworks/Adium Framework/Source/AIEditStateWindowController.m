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

#import <Adium/AIAccount.h>
#import <Adium/AIEditStateWindowController.h>
#import <Adium/AIStatus.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIAutoScrollView.h>
#import <AIUtilities/AIStringFormatter.h>
#import <AIUtilities/AITextAttributes.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <Adium/AIMessageEntryTextView.h>

#define CONTROL_SPACING			8
#define WINDOW_HEIGHT_PADDING	30

#define	SEND_ON_ENTER					@"Send On Enter"

@interface AIEditStateWindowController ()
- (id)initWithWindowNibName:(NSString *)windowNibName forType:(AIStatusType)inStatusType andAccount:(AIAccount *)inAccount customState:(AIStatus *)inStatusState notifyingTarget:(id)inTarget showSaveCheckbox:(BOOL)inShowSaveCheckbox;
- (id)_positionControl:(id)control relativeTo:(id)guide height:(CGFloat *)height;
- (void)configureStateMenu;

- (void)setOriginalStatusState:(AIStatus *)inState forType:(AIStatusType)inStatusType;
- (void)setAccount:(AIAccount *)inAccount;
- (void)configureForAccountAndWorkingStatusState;

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void)notifyOfStateChange;
@end

/*!
 * @class AIEditStateWindowController
 * @brief Interface for editing a status state
 *
 * This class provides an interface for editing a status state dictionary's properties.
 */
@implementation AIEditStateWindowController

static	NSMutableDictionary	*controllerDict = nil;

/*!
 * @brief Open a custom state editor window or sheet
 *
 * Open either a sheet or window containing a state editor.  The state editor will be primed with the passed state
 * dictionary.  When the user successfully closes the editor, the target will be notified and passed the updated
 * state dictionary.  Only one window will be shown per target at a time.
 *
 * @param inStatusState Initial AIStatus
 * @param inStatusType AIStatusType to use initially if inStatusState is nil
 * @param inAccount The account which to configure the custom state window; nil to configure globally
 * @param inShowSaveCheckbox YES if the save checkbox should be shown; NO if it should not. If YES, the title on an incoming status will be cleared to make it auto-update.
 * @param parentWindow Parent window for a sheet, nil for a stand alone editor
 * @param inTarget Target object to notify when editing is complete
 */
+ (id)editCustomState:(AIStatus *)inStatusState forType:(AIStatusType)inStatusType andAccount:(AIAccount *)inAccount withSaveOption:(BOOL)inShowSaveCheckbox onWindow:(id)parentWindow notifyingTarget:(id)inTarget
{
	AIEditStateWindowController	*controller;

	NSNumber	*targetHash = [NSNumber numberWithUnsignedInteger:[inTarget hash]];
		
	if ((controller = [controllerDict objectForKey:targetHash])) {
		[controller setAccount:inAccount];

		if ([[controller currentConfiguration] statusType] != inStatusType) {
			//It's not currently editing a status of the type requested; configure based on the passed status
			[controller setOriginalStatusState:inStatusState forType:inStatusType];
			[controller configureForAccountAndWorkingStatusState];
		}

	} else {
		controller = [[self alloc] initWithWindowNibName:@"EditStateSheet" 
												 forType:inStatusType 
											  andAccount:inAccount
											 customState:inStatusState 
										 notifyingTarget:inTarget
										showSaveCheckbox:inShowSaveCheckbox];
		if (!controllerDict) controllerDict = [[NSMutableDictionary alloc] init];
		[controllerDict setObject:controller forKey:targetHash];
	}
	
	if (parentWindow) {
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}

	return controller;
}

/*!
 * @brief Init the window controller
 */
- (id)initWithWindowNibName:(NSString *)windowNibName forType:(AIStatusType)inStatusType andAccount:(AIAccount *)inAccount customState:(AIStatus *)inStatusState notifyingTarget:(id)inTarget showSaveCheckbox:(BOOL)inShowSaveCheckbox
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		target = inTarget;
		showSaveCheckbox = inShowSaveCheckbox;

		[self setOriginalStatusState:inStatusState forType:inStatusType];
		[self setAccount:inAccount];
	}
	
	return self;
}

/*!
 * @brief Set our status state
 *
 * Also create the working state if we don't have one or the original status state is of the wrong statusType.
 * If showSaveCheckbox is YES, clear workingStatusState's title so it will autoupdate.
 */
- (void)setOriginalStatusState:(AIStatus *)inStatusState forType:(AIStatusType)inStatusType
{
	if (originalStatusState != inStatusState) {
		originalStatusState = inStatusState;
	}
	
	workingStatusState = (originalStatusState ? 
						  [originalStatusState mutableCopy] :
						  [AIStatus statusOfType:inStatusType]);
	
	/* Reset to the default for this status type if we're not on it already */
	if (workingStatusState.statusType != inStatusType) {
		[workingStatusState setStatusType:inStatusType];
		[workingStatusState setStatusName:[[adium statusController] defaultStatusNameForType:inStatusType]];

		[workingStatusState setHasAutoReply:(inStatusType == AIAwayStatusType)];
	}

	//Clear the title if the save checkbox is showing so it will autoupdate.
	if (showSaveCheckbox) [workingStatusState setTitle:nil];
}

- (void)setAccount:(AIAccount *)inAccount
{
	if (inAccount != account) {
		account = inAccount;
	}
}

/*!
 * @brief Configure the window after it loads
 */
- (void)windowDidLoad
{
//	NSNumberFormatter	*intFormatter;
	BOOL				sendOnEnter;

	sendOnEnter = [[adium.preferenceController preferenceForKey:SEND_ON_ENTER
															group:PREF_GROUP_GENERAL] boolValue];
	
	[scrollView_statusMessage setAutohidesScrollers:YES];
	[scrollView_statusMessage setAlwaysDrawFocusRingIfFocused:YES];
	[textView_statusMessage setTarget:self action:@selector(okay:)];
	[textView_statusMessage setDelegate:self];

	[textView_statusMessage setAllowsDocumentBackgroundColorChange:YES];
	[textView_autoReply setAllowsDocumentBackgroundColorChange:YES];

	[textView_statusMessage setSendOnReturn:NO];
	[textView_statusMessage setSendOnEnter:sendOnEnter];
	
	if ([textView_statusMessage isKindOfClass:[AIMessageEntryTextView class]]) {
		[(AIMessageEntryTextView *)textView_statusMessage setClearOnEscape:NO];
		[(AIMessageEntryTextView *)textView_statusMessage setPushPopEnabled:NO];
		[(AIMessageEntryTextView *)textView_statusMessage setHistoryEnabled:NO];
	}
	
	[scrollView_autoReply setAutohidesScrollers:YES];
	[scrollView_autoReply setAlwaysDrawFocusRingIfFocused:YES];
	[textView_autoReply setTarget:self action:@selector(okay:)];
	[textView_autoReply setDelegate:self];

	//Return inserts a new line
	[textView_autoReply setSendOnReturn:NO];

	/* Enter follows the user's preference. By default, then, enter will send the okay: selector.
	 * If the user expects enter to insert a newline in a message, however, it will do that here, too. */
	[textView_autoReply setSendOnEnter:sendOnEnter];

	if ([textView_autoReply isKindOfClass:[AIMessageEntryTextView class]]) {
		[(AIMessageEntryTextView *)textView_autoReply setClearOnEscape:NO];
		[(AIMessageEntryTextView *)textView_autoReply setPushPopEnabled:NO];
		[(AIMessageEntryTextView *)textView_autoReply setHistoryEnabled:NO];
	}
	
	[self configureForAccountAndWorkingStatusState];
	
	[textView_statusMessage setTypingAttributes:[adium.contentController defaultFormattingAttributes]];
	[textView_autoReply setTypingAttributes:[adium.contentController defaultFormattingAttributes]];

	NSMutableCharacterSet *noNewlinesCharacterSet;
	noNewlinesCharacterSet = [[[NSCharacterSet characterSetWithCharactersInString:@""] invertedSet] mutableCopy];
	[noNewlinesCharacterSet removeCharactersInString:@"\n\r"];
	[textField_title setFormatter:[AIStringFormatter stringFormatterAllowingCharacters:noNewlinesCharacterSet
																				length:0 /* No length limit */
																		 caseSensitive:NO
																		  errorMessage:nil]];

	if (!showSaveCheckbox) {
		[checkBox_save setHidden:YES];
	}
	
	[super windowDidLoad];
	
	[self updateControlVisibilityAndResizeWindow];
}

/*!
 * @brief Configure for our account and working status state
 *
 * This means updating the state menu to be appropriate for our account's service as well as setting up
 * the rest of the fields.
 */
- (void)configureForAccountAndWorkingStatusState
{
	[self configureStateMenu];
	
	//Configure our editor for the working state
	[self configureForState:workingStatusState];	
}

/*!
 * @brief Configure the state menu with a fresh menu of active statuses
 */
- (void)configureStateMenu
{
	[popUp_state setMenu:[adium.statusController menuOfStatusesForService:(account ? account.service : nil)
																 withTarget:self]];
	needToRebuildPopUpState = NO;	
}

/*!
 * @brief Called before the window is closed
 *
 * As our window is closing, we auto-release this window controller instance.  This allows our editor to function
 * independently without needing a separate object to retain and release it.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];

	//Stop tracking with the controllerDict
	NSNumber	*targetHash = [NSNumber numberWithUnsignedInteger:[target hash]];
	[controllerDict removeObjectForKey:targetHash];
}

/*!
 * Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	//Stop tracking with the controllerDict
	NSNumber	*targetHash = [NSNumber numberWithUnsignedInteger:[target hash]];
	[controllerDict removeObjectForKey:targetHash];
	
    [sheet orderOut:nil];
}

- (NSString *)adiumFrameAutosaveName
{
	return @"EditStateWindow";
}

//Behavior -------------------------------------------------------------------------------------------------------------
#pragma mark Behavior
/*!
 * @brief Okay
 *
 * Save changes, notify our target of the new configuration, and close the editor.
 */
- (IBAction)okay:(id)sender
{
	if (target && [target respondsToSelector:@selector(customStatusState:changedTo:forAccount:)]) {
		//Perform on a delay so the sheet can begin closing immediately.
		[self performSelector:@selector(notifyOfStateChange)
				   withObject:nil
				   afterDelay:0];
	}
	
	[self closeWindow:nil];
}

/*!
 * @brief Notify our target of the state changing
 *
 * Called by -[self okay:]
 */
- (void)notifyOfStateChange
{
	[target customStatusState:originalStatusState changedTo:[self currentConfiguration] forAccount:account];
}

/*!
 * @brief Cancel
 *
 * Close the editor without saving changes.
 */
- (IBAction)cancel:(id)sender
{
	[self closeWindow:nil];
}

- (void)textViewDidCancel:(NSTextView *)inTextView
{
	[self cancel:inTextView];
}

/*!
 * @brief Update the display of the status's title in the window
 */
- (void)updateTitleDisplay
{
	[textField_title setStringValue:[workingStatusState title]];
}

/*!
 * @brief Invoked when a control value is changed
 *
 * Invoked with the user changes the value of an editor control.  In response, we update control visibility and
 * resize the window.
 */
- (IBAction)statusControlChanged:(id)sender
{
	if (sender == checkbox_autoReply)
		[workingStatusState setHasAutoReply:[checkbox_autoReply state]];	
	else if (sender == checkbox_customAutoReply) 
		[workingStatusState setAutoReplyIsStatusMessage:![checkbox_customAutoReply state]];	
	else if (sender == checkbox_idle)
		[workingStatusState setShouldForceInitialIdleTime:[checkbox_idle state]];
	else if (sender == checkBox_muteSounds)
		[workingStatusState setMutesSound:[checkBox_muteSounds state]];
	else if (sender == checkBox_silenceGrowl)
		[workingStatusState setSilencesGrowl:[checkBox_silenceGrowl state]];	
	
	[self updateControlVisibilityAndResizeWindow];
	[self updateTitleDisplay];
}

/*!
 * @brief NSTextField changed
 */
- (void)controlTextDidChange:(NSNotification *)notification
{
	id sender = [notification object];

	if (sender == textField_title) {
		NSString	*newTitle = [textField_title stringValue];
		
		if ([newTitle length]) [workingStatusState setTitle:newTitle];
	}
}

/*!
 * @brief NSTextView changed
 */
- (void)textDidChange:(NSNotification *)notification
{
	id sender = [notification object];

	if (sender == textView_statusMessage) {
		[workingStatusState setStatusMessage:[[textView_statusMessage textStorage] copy]];
		
	} else if (sender == textView_autoReply) {
		[workingStatusState setAutoReply:[[textView_autoReply textStorage] copy]];
		
	}
	
	[self updateTitleDisplay];
}

/*!
 * @brief NSTextField ended editing
 *
 * If our title is cleared out, restore it to using the default title for the rest of the configuration
 */
- (void)controlTextDidEndEditing:(NSNotification *)notification
{
	id sender = [notification object];

	if (sender == textField_title) {
		NSString	*newTitle = [textField_title stringValue];
		
		//Set to nil if the field is cleared to get back to the automatically generated value
		if (![newTitle length]) {
			[workingStatusState setTitle:nil];
			
			[self updateTitleDisplay];
		}
	}
}

/*!
 * @brief Invoked when a new status type is selected
 */
- (IBAction)selectStatus:(id)sender
{
	NSDictionary	*stateDict = [[popUp_state selectedItem] representedObject];
	if (stateDict) {
		[workingStatusState setStatusType:[[stateDict objectForKey:KEY_STATUS_TYPE] intValue]];
		[workingStatusState setStatusName:[stateDict objectForKey:KEY_STATUS_NAME]];
	}

	[self updateTitleDisplay];
}

/*!
 * @brief Override AIWindowController's stringWithSavedFrame to provide a custom saved frame
 *
 * We want our savedframe to match the way the window will load, which means it needs to be as if all controls were visible.
 */
- (NSString *)stringWithSavedFrame
{
	NSWindow *window = [self window];
	NSString *stringWithSavedFrame;

	NSRect frame = [window frame];
	CGFloat delta  = 0;
	delta += ([scrollView_autoReply isHidden] ? ([scrollView_autoReply frame].size.height + CONTROL_SPACING) : 0);
	delta += ([checkbox_customAutoReply isHidden] ? ([checkbox_customAutoReply frame].size.height + CONTROL_SPACING) : 0);
	delta += ([box_idle isHidden] ? ([box_idle frame].size.height + CONTROL_SPACING) : 0);

	frame.size.height += delta;
	frame.origin.y -= delta;

	NSRect screenFrame = [[window screen] frame];
	stringWithSavedFrame = [NSString stringWithFormat:@"%0f %0f %0f %0f %0f %0f %0f %0f",
		frame.origin.x, frame.origin.y, frame.size.width, frame.size.height,
		screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height];

	return stringWithSavedFrame;
}

- (NSRect)savedFrameFromString:(NSString *)frameString
{
	NSRect savedFrame = [super savedFrameFromString:frameString];
	
	CGFloat delta  = 0;
	delta += ([scrollView_autoReply isHidden] ? ([scrollView_autoReply frame].size.height + CONTROL_SPACING) : 0);
	delta += ([checkbox_customAutoReply isHidden] ? ([checkbox_customAutoReply frame].size.height + CONTROL_SPACING) : 0);
	delta += ([box_idle isHidden] ? ([box_idle frame].size.height + CONTROL_SPACING) : 0);	

	savedFrame.size.height -= delta;
	savedFrame.origin.y += delta;

	//Magic? This is the amount our numbers are off from the nib... if the nib changes, this magic will probably change, too.
	savedFrame.size.height += CONTROL_SPACING*3;

	return savedFrame;
}


/*!
 * @brief Update control visibility and resize the editor window
 *
 * This method updates control visibility (When checkboxes are off we hide the controls below them) and resizes the
 * window to fit just the remaining visible controls.
 */
- (void)updateControlVisibilityAndResizeWindow
{
	//Visibility
	NSWindow	*window = [self window];
		
	[scrollView_autoReply setHidden:(![checkbox_autoReply state] || ![checkbox_customAutoReply state])];
	[checkbox_customAutoReply setHidden:![checkbox_autoReply state]];
	[box_idle setHidden:![checkbox_idle state]];
		
	//Sizing
	//XXX - This is quick & dirty -ai
	id	current = box_title;
	CGFloat	height = WINDOW_HEIGHT_PADDING + [current frame].size.height;

	current = [self _positionControl:box_separatorLine relativeTo:current height:&height];
	current = [self _positionControl:box_state relativeTo:current height:&height];	
	current = [self _positionControl:box_statusMessage relativeTo:current height:&height];
	current = [self _positionControl:checkbox_autoReply relativeTo:current height:&height];
	current = [self _positionControl:checkbox_customAutoReply relativeTo:current height:&height];
	current = [self _positionControl:scrollView_autoReply relativeTo:current height:&height];
	current = [self _positionControl:checkbox_idle relativeTo:current height:&height];
	current = [self _positionControl:box_idle relativeTo:current height:&height];
	current = [self _positionControl:checkBox_muteSounds relativeTo:current height:&height];
	current = [self _positionControl:checkBox_silenceGrowl relativeTo:current height:&height];
	[self _positionControl:checkBox_save relativeTo:current height:&height];

	[window setContentSize:NSMakeSize([[window contentView] frame].size.width, height)
				   display:YES
				   animate:NO];
}

/*!
 * @brief Position a control
 *
 * Position the passed control relative to another control in the editor window, keeping track of total control
 * height.  If the passed control is hidden, it won't be positioned or influence the total height at all.
 * @param control The control to reposition
 * @param guide The control we're positoining relative to
 * @param height A pointer to the total control height, which will be updated to include control
 * @return Returns control if it's visible, otherwise returns guide
 */
- (id)_positionControl:(id)control relativeTo:(id)guide height:(CGFloat *)height
{
	if (![control isHidden]) {
		NSRect	frame = [control frame];
		
		//Position this control relative to the one above it
		frame.origin.y = [guide frame].origin.y - CONTROL_SPACING - frame.size.height;
		
		[control setFrame:frame];
		(*height) += frame.size.height + CONTROL_SPACING;
		
		return control;
	} else {
		return guide;
	}
}


//Configuration --------------------------------------------------------------------------------------------------------
#pragma mark Configuration
/*!
 * @brief Configure the editor for a state
 *
 * Configured the editor's controls to represent the passed state dictionary.
 * @param statusState A NSDictionary containing status state keys and values
 */
- (void)configureForState:(AIStatus *)statusState
{
	//State menu
	NSString	*description;
	NSUInteger			idx;

	if (needToRebuildPopUpState) {
		[self configureStateMenu];
	}

	description = [adium.statusController descriptionForStateOfStatus:statusState];
	idx = (description ? [popUp_state indexOfItemWithTitle:description] : -1);
	if (idx != -1) {
		[popUp_state selectItemAtIndex:idx];

	} else {
		if (description) {
			[popUp_state setTitle:[NSString stringWithFormat:@"%@ (%@)",
				description,
				AILocalizedString(@"No compatible accounts connected", nil)]];

		} else {
			[popUp_state setTitle:AILocalizedString(@"Unknown", nil)];			
		}

		needToRebuildPopUpState = YES;
	}

	//Toggles
	[checkbox_idle setState:[statusState shouldForceInitialIdleTime]];
	[checkbox_autoReply setState:[statusState hasAutoReply]];
	[checkbox_customAutoReply setState:![statusState autoReplyIsStatusMessage]];
	[checkBox_muteSounds setState:[statusState mutesSound]];
	[checkBox_silenceGrowl setState:[statusState silencesGrowl]];
	
	//Strings
	NSAttributedString	*statusMessage = statusState.statusMessage;
	NSAttributedString	*autoReply = [statusState autoReply];

	NSAttributedString	*blankString = [NSAttributedString stringWithString:@""];
	
	if (!statusMessage) statusMessage = blankString;
	[[textView_statusMessage textStorage] setAttributedString:statusMessage];
	[textView_statusMessage setSelectedRange:NSMakeRange(0, [statusMessage length])];

	if (!autoReply) autoReply = blankString;
	[[textView_autoReply textStorage] setAttributedString:autoReply];
	
	//Set Background Colors
	if([autoReply attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil]) {
			[textView_autoReply setBackgroundColor:[autoReply attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil]];
	}
	
	if([statusMessage attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil]) {
			[textView_statusMessage setBackgroundColor:[statusMessage attribute:AIBodyColorAttributeName atIndex:0 effectiveRange:nil]];
	}
	
	//Disallow an undo to before this point
	[[textView_autoReply undoManager] removeAllActions];
	[[textView_statusMessage undoManager] removeAllActions];

	//Idle start
	double	idleStart = [statusState forcedInitialIdleTime];
	[textField_idleMinutes setIntValue:(int)((((int)idleStart)%3600)/60)];
	[stepper_idleMinutes setIntValue:(int)((((int)idleStart)%3600)/60)];
	
	[textField_idleHours setIntValue:(int)(idleStart/3600)];
	[stepper_idleHours setIntValue:(int)(idleStart/3600)];

	//Update visiblity and size
	[self updateControlVisibilityAndResizeWindow];
	
	//Update our title
	[self updateTitleDisplay];
}

/*!
 * @brief Returns the current state
 *
 * Builds and returns a state dictionary representation of the current editor values.  If no controls have been
 * modified since the editor was configured, the returned state will be identical in content to the one passed
 * to configureForState:.
 */
- (AIStatus *)currentConfiguration
{
	double		idleStart = [textField_idleHours intValue]*3600 + [textField_idleMinutes intValue]*60;
	
	[workingStatusState setMutabilityType:((!showSaveCheckbox || ([checkBox_save state] == NSOnState)) ?
										   AIEditableStatusState :
										   AITemporaryEditableStatusState)];

	[workingStatusState setForcedInitialIdleTime:idleStart];

	//Set the title if necessary
	if (![[workingStatusState title] isEqualToString:[textField_title stringValue]]) {
		[workingStatusState setTitle:[textField_title stringValue]];
	}

	//Do not allow the creation of a Now Playing status
	if ([workingStatusState specialStatusType] == AINowPlayingSpecialStatusType) {
		[workingStatusState setSpecialStatusType:AINoSpecialStatusType];
	}

	return workingStatusState;
}

@end

