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

#import "ESPurpleRequestWindowController.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>

#define MULTILINE_WINDOW_NIB	@"PurpleMultilineRequestWindow"
#define SINGLELINE_WINDOW_NIB   @"PurpleSinglelineRequestWindow"

@interface ESPurpleRequestWindowController ()
- (void)showWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline;
- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict;
@end

@implementation ESPurpleRequestWindowController
 
+ (ESPurpleRequestWindowController *)showInputWindowWithDict:(NSDictionary *)infoDict
{
	ESPurpleRequestWindowController	*requestWindowController;
	BOOL							multiline = [[infoDict objectForKey:@"Multiline"] boolValue];
	
	if ((requestWindowController = [[self alloc] initWithWindowNibName:(multiline ? MULTILINE_WINDOW_NIB : SINGLELINE_WINDOW_NIB)
														 withDict:infoDict
															 multiline:multiline])) {
		[requestWindowController showWindow:nil];
		[[requestWindowController window] makeKeyAndOrderFront:nil];
	}
	
	return requestWindowController;
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)infoDict multiline:(BOOL)multiline
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		[self showWindowWithDict:[self translatedInfoDict:infoDict]
					   multiline:multiline];
	}
	
    return self;
}

- (void)showWindowWithDict:(NSDictionary *)infoDict multiline:(BOOL)multiline
{	
	NSRect		windowFrame;
	NSWindow	*window;
	
	NSInteger			heightChange = 0;

	//Ensure the window is loaded
	window = [self window];
	windowFrame = [window frame];

	//If masked, replace our textField_input with a secure one
	if ([[infoDict objectForKey:@"Masked"] boolValue]) {
		NSRect				inputFrame = [textField_input frame];
		NSSecureTextField	*secureTextField = [[[NSSecureTextField alloc] initWithFrame:inputFrame] autorelease];
		
		[[textField_input superview] addSubview:secureTextField];
		[secureTextField setNeedsDisplay:YES];
		[textField_input removeFromSuperview];
		textField_input = secureTextField;		
	}

	//Buttons
	{
		//Use the supplied OK text, then shift the button left so that the right side remains in the old location in the window
		NSString *okText = [infoDict objectForKey:@"OK Text"];
		
		[button_okay setTitle:(okText ? okText : AILocalizedString(@"OK",nil))];
		
		//Use the supplied Cancel text, then shift the button left
		NSString	*cancelText = [infoDict objectForKey:@"Cancel Text"];
		
		[button_cancel setTitle:(cancelText ? cancelText : AILocalizedString(@"Cancel",nil))];
	}
	
	//Window Title
	{
		NSString *title = [infoDict objectForKey:@"Title"];
		[[self window] setTitle:(title ? title : @"")];
	}
	
	//Primary text field
	{
		NSScrollView	*scrollView_primary = [textView_primary enclosingScrollView];
		NSString		*primary = [infoDict objectForKey:@"Primary Text"];
		NSRect			primaryFrame = [scrollView_primary frame];
		
		[textView_primary setVerticallyResizable:YES];
		[textView_primary setHorizontallyResizable:NO];
		[textView_primary setDrawsBackground:NO];
		[textView_primary setTextContainerInset:NSZeroSize];
		[scrollView_primary setDrawsBackground:NO];
		
		[textView_primary setString:(primary ? primary : @"")];
		
		//Resize the window frame to fit the error title
		[textView_primary sizeToFit];
		heightChange = [textView_primary frame].size.height - [scrollView_primary documentVisibleRect].size.height;
		
		primaryFrame.size.height += heightChange;
		primaryFrame.origin.y -= heightChange;
		
		[scrollView_primary setFrame:primaryFrame];
		
		windowFrame.size.height += heightChange;
		windowFrame.origin.y -= heightChange;
		
		//Resize the window to fit the message
		//[window setFrame:windowFrame display:YES animate:NO];
	}
	
	//Secondary text field
	{
		NSString	*secondary = [infoDict objectForKey:@"Secondary Text"];

		NSRect	originalFrame = [scrollView_secondary frame];
		originalFrame.origin.y -= heightChange;
		[scrollView_secondary setFrame:originalFrame];
		
		[textView_secondary setVerticallyResizable:YES];
		[textView_secondary setHorizontallyResizable:NO];
		[textView_secondary setDrawsBackground:NO];
		[textView_secondary setTextContainerInset:NSZeroSize];
		[scrollView_secondary setDrawsBackground:NO];
		
		[textView_secondary setString:(secondary ? secondary : @"")];
		
		//Resize the window frame to fit the error title
		[textView_secondary sizeToFit];
		heightChange = [textView_secondary frame].size.height - [scrollView_secondary documentVisibleRect].size.height;

		windowFrame.size.height += heightChange;
		windowFrame.origin.y -= heightChange;
	}

	//Resize the window to fit the message
	[window setFrame:windowFrame display:YES animate:NO];

	//Default value
	{
		NSString *defaultValue = [infoDict objectForKey:@"Default Value"];
		[textField_input setStringValue:(defaultValue ? defaultValue : @"")];
		[textField_input selectText:nil];
	}

	okayCallbackValue = [[infoDict objectForKey:@"OK Callback"] retain];
	cancelCallbackValue = [[infoDict objectForKey:@"Cancel Callback"] retain];
	userDataValue = [[infoDict objectForKey:@"userData"] retain];
	
	[self showWindow:nil];
}

- (void)doRequestInputCbValue:(NSValue *)inCallBackValue
					  withUserDataValue:(NSValue *)inUserDataValue 
							inputString:(NSString *)inString
{
	PurpleRequestInputCb callBack = [inCallBackValue pointerValue];
	if (callBack) {
		callBack([inUserDataValue pointerValue],[inString UTF8String]);
	}	
}

- (IBAction)pressedButton:(id)sender
{
	if (sender == button_okay) {
		[self doRequestInputCbValue:okayCallbackValue
				  withUserDataValue:userDataValue
						inputString:[[[textField_input stringValue] copy] autorelease]];
		
		[cancelCallbackValue release]; cancelCallbackValue = nil;
		[[self window] close];
		
	} else if (sender == button_cancel) {
		[[self window] performClose:nil];
	}
}

- (void)dealloc
{
	[okayCallbackValue release]; okayCallbackValue = nil;
	[cancelCallbackValue release]; cancelCallbackValue = nil;
	[userDataValue release]; userDataValue = nil;
	
	[super dealloc];
}

- (void)doWindowWillClose
{
	if (cancelCallbackValue) {
		[self doRequestInputCbValue:cancelCallbackValue
				  withUserDataValue:userDataValue
						inputString:[[[textField_input stringValue] copy] autorelease]];
	}
}

/*!
 * @brief Translate the strings in the info dictionary
 *
 * The following declarations let genstrings know about what translations we want
 * AILocalizedString(@"Set your friendly name.","Title for the MSN display name setting dialogue box")
 * AILocalizedString(@"This is the name that other MSN buddies will see you as.", "Description for the MSN display name setting dialogue.")
 * AILocalizedString(@"Set your home phone number.", "Title for the dialogue prompting for your home phone number")
 * AILocalizedString(@"Set your work phone number.", "Title for the dialogue prompting for your work phone number")
 * AILocalizedString(@"Set your mobile phone number.", "Title for the dialogue prompting for your mobile phone number")
 */
- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict
{
	NSMutableDictionary	*translatedDict = [inDict mutableCopy];
	
	NSString	*primary = [inDict objectForKey:@"Primary Text"];
	NSString	*secondary = [inDict objectForKey:@"Secondary Text"];
	NSString	*okText = [inDict objectForKey:@"OK Text"];
	NSString	*cancelText = [inDict objectForKey:@"Cancel Text"];

	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];

	//Replace each string with a translated version if possible
	[translatedDict setObject:[thisBundle localizedStringForKey:primary
														  value:primary
														  table:nil]
					   forKey:@"Primary Text"];
	[translatedDict setObject:[thisBundle localizedStringForKey:secondary
														  value:secondary
														  table:nil]
					   forKey:@"Secondary Text"];
	[translatedDict setObject:[thisBundle localizedStringForKey:okText
														  value:okText
														  table:nil]
					   forKey:@"OK Text"];
	[translatedDict setObject:[thisBundle localizedStringForKey:cancelText
														  value:cancelText
														  table:nil]
					   forKey:@"Cancel Text"];
	
	return [translatedDict autorelease];
}

@end
