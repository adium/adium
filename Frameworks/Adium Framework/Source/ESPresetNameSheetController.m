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

#import <Adium/ESPresetNameSheetController.h>

#define	PRESET_NAME_SHEET	@"PresetNameSheet"

@interface ESPresetNameSheetController ()
- (void)configureExplanatoryTextWithString:(NSString *)inExplanatoryText;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation ESPresetNameSheetController

- (void)showOnWindow:(NSWindow *)parentWindow
{
	//Must be called on a window
	NSParameterAssert(parentWindow != nil);
	
	[NSApp beginSheet:self.window
	   modalForWindow:parentWindow
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (id)initWithDefaultName:(NSString *)inDefaultName explanatoryText:(NSString *)inExplanatoryText notifyingTarget:(id)inTarget userInfo:(id)inUserInfo
{
	//Target must respond to the ending selector
	NSParameterAssert([inTarget respondsToSelector:@selector(presetNameSheetControllerDidEnd:returnCode:newName:userInfo:)]);
	
	if ((self = [super initWithWindowNibName:PRESET_NAME_SHEET])) {
		defaultName = inDefaultName;
		explanatoryText = inExplanatoryText;
		target = inTarget;
		userInfo = inUserInfo;
	}
	
	return self;
}

/*!
 * @brief Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
    [sheet orderOut:nil];
}

/*!
* @brief As the window closes, release this controller instance
 *
 * The instance retained itself (rather, was not autoreleased when created) so it could function independently.
 */
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
}

- (IBAction)okay:(id)sender
{
	NSString	*newName = [textField_name stringValue];
	
	if (![target respondsToSelector:@selector(presetNameSheetController:shouldAcceptNewName:userInfo:)] ||
	   [target presetNameSheetController:self
					 shouldAcceptNewName:newName
								userInfo:userInfo]) {
		
		[target presetNameSheetControllerDidEnd:self 
									 returnCode:ESPresetNameSheetOkayReturn 
										newName:newName
									   userInfo:userInfo];
		
		[self closeWindow:nil];

	} else {
		NSString	*nameInUseText;
		
		nameInUseText = [NSString stringWithFormat:AILocalizedString(@"\"%@\" is already in use.", nil), newName];
		[self configureExplanatoryTextWithString:[NSString stringWithFormat:@"%@\n\n%@", explanatoryText, nameInUseText]];

		NSBeep();
	}
}

- (IBAction)cancel:(id)sender
{
	[target presetNameSheetControllerDidEnd:self
								 returnCode:ESPresetNameSheetCancelReturn
									newName:nil
								   userInfo:userInfo];

	[self closeWindow:nil];	
}

- (void)windowDidLoad
{
	[textView_explanatoryText setHorizontallyResizable:NO];
    [textView_explanatoryText setVerticallyResizable:YES];
    [textView_explanatoryText setDrawsBackground:NO];
    [scrollView_explanatoryText setDrawsBackground:NO];

	//Set the default name
	[textField_name setStringValue:defaultName];
	[label_name setLocalizedString:AILocalizedString(@"Title:", "Label in front of the title for a preset")];
	[button_ok setLocalizedString:AILocalizedString(@"OK", nil)];
	[button_cancel setLocalizedString:AILocalizedString(@"Cancel", nil)];
	
	[self configureExplanatoryTextWithString:explanatoryText];
}

- (void)configureExplanatoryTextWithString:(NSString *)inExplanatoryText
{
	NSRect	frame = [[self window] frame];
	CGFloat		heightChange = 0;
		
	//Set the explanatory text and resize as needed
	[textView_explanatoryText setString:inExplanatoryText];
	   
	//Resize the window frame to fit the error title
	[textView_explanatoryText sizeToFit];
	heightChange += [textView_explanatoryText frame].size.height - [scrollView_explanatoryText documentVisibleRect].size.height;
	   
	frame.size.height += heightChange;
	frame.origin.y -= heightChange;
	
	//Perform the window resizing as needed
	[[self window] setFrame:frame display:YES animate:YES];
}

@end
