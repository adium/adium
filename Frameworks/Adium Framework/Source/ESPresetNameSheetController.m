//
//  ESPresetNameSheetController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/15/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/ESPresetNameSheetController.h>

#define	PRESET_NAME_SHEET	@"PresetNameSheet"

@interface ESPresetNameSheetController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName defaultName:(NSString *)inDefaultName explanatoryText:(NSString *)inExplanatoryText notifyingTarget:(id)inTarget userInfo:(id)inUserInfo;
- (void)configureExplanatoryTextWithString:(NSString *)inExplanatoryText;
@end

@implementation ESPresetNameSheetController

+ (void)showPresetNameSheetWithDefaultName:(NSString *)inDefaultName
						   explanatoryText:(NSString *)inExplanatoryText
								  onWindow:(NSWindow *)parentWindow
						   notifyingTarget:(id)inTarget
								  userInfo:(id)inUserInfo
{
	ESPresetNameSheetController	*controller = [[self alloc] initWithWindowNibName:PRESET_NAME_SHEET
																	  defaultName:inDefaultName
																explanatoryText:inExplanatoryText
																notifyingTarget:inTarget
																	   userInfo:inUserInfo];
	//Must be called on a window
	NSParameterAssert(parentWindow != nil);
	
	//Target must respond to the ending selector
	NSParameterAssert([inTarget respondsToSelector:@selector(presetNameSheetControllerDidEnd:returnCode:newName:userInfo:)]);
	
	[NSApp beginSheet:[controller window]
	   modalForWindow:parentWindow
		modalDelegate:controller
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (id)initWithWindowNibName:(NSString *)windowNibName defaultName:(NSString *)inDefaultName explanatoryText:(NSString *)inExplanatoryText notifyingTarget:(id)inTarget userInfo:(id)inUserInfo
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		defaultName = [inDefaultName retain];
		explanatoryText = [inExplanatoryText retain];
		target = [inTarget retain];
		userInfo = [inUserInfo retain];
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

	[self autorelease];
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
	int		heightChange = 0;
		
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
