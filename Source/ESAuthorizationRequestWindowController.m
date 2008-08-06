//
//  ESAuthorizationRequestWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 5/18/05.
//

#import "ESAuthorizationRequestWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESAuthorizationRequestWindowController (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict forAccount:(AIAccount *)inAccount;
@end

@implementation ESAuthorizationRequestWindowController

+ (ESAuthorizationRequestWindowController *)showAuthorizationRequestWithDict:(NSDictionary *)inInfoDict  forAccount:(AIAccount *)inAccount
{
	ESAuthorizationRequestWindowController	*controller;
	
	if ((controller = [[self alloc] initWithWindowNibName:@"AuthorizationRequestWindow"
												 withDict:inInfoDict
											   forAccount:inAccount])) {
		[controller showWindow:nil];
		[[controller window] orderFront:nil];
	}
	
	return controller;
}

//Init
- (id)initWithWindowNibName:(NSString *)windowNibName withDict:(NSDictionary *)inInfoDict forAccount:(AIAccount *)inAccount
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		infoDict = [inInfoDict retain];
		account = [inAccount retain];
	}
	
    return self;
}

- (void)dealloc
{
	[infoDict release]; infoDict = nil;
	[account release]; account = nil;

	[super dealloc];
}

- (void)windowDidLoad
{	
	NSString	*message;

	[super windowDidLoad];

	[textField_header setStringValue:AILocalizedString(@"Authorization Requested",nil)];
	[checkBox_addToList setLocalizedString:AILocalizedString(@"Add to my Contact List", "Checkbox in the Authorizatoin Request window to add the contact to the contact list if authorization is granted")]; 
	[button_authorize setLocalizedString:AILocalizedString(@"Authorize", nil)];
	[button_deny setLocalizedString:AILocalizedString(@"Deny", nil)];

	// Hide the "Add to my Contact List" checkbox if the contact already exists in the list
	AIListContact *contact = [[adium contactController] existingContactWithService:[account service] account:account UID:[infoDict objectForKey:@"Remote Name"]];
	if (contact && [contact isIntentionallyNotAStranger]) {
		[checkBox_addToList setState:NSOffState];
		[checkBox_addToList setEnabled:NO];
		[checkBox_addToList setHidden:YES];
	}

	if ([infoDict objectForKey:@"Reason"]) {
		message = [NSString stringWithFormat:
			AILocalizedString(@"The contact %@ wants to add %@ to his or her contact list for the following reason:\n%@",nil),
			[infoDict objectForKey:@"Remote Name"],
			[account formattedUID],
			[infoDict objectForKey:@"Reason"]];

	} else {
		message = [NSString stringWithFormat:
			AILocalizedString(@"The contact %@ wants to add %@ to his or her contact list.",nil),
			[infoDict objectForKey:@"Remote Name"],
			[account formattedUID]];
	}

	NSScrollView *scrollView_message = [textView_message enclosingScrollView];
	
	[textView_message setVerticallyResizable:YES];
	[textView_message setHorizontallyResizable:NO];
	[textView_message setDrawsBackground:NO];
	[textView_message setTextContainerInset:NSZeroSize];
	[scrollView_message setDrawsBackground:NO];
	
	[textView_message setString:(message ? message : @"")];
	
	//Resize the window frame to fit the error title
	[textView_message sizeToFit];
	float heightChange = [textView_message frame].size.height - [scrollView_message documentVisibleRect].size.height;

	NSRect windowFrame = [[self window] frame];
	windowFrame.size.height += heightChange;
	windowFrame.origin.y -= heightChange;
	[[self window] setFrame:windowFrame display:YES animate:NO];
	
	[[self window] center];
}

- (void)windowWillClose:(id)sender
{
	windowIsClosing = YES;

	if (!postedAuthorizationResponse) {
		[account authorizationWindowController:self
						 authorizationWithDict:infoDict
									  response:AIAuthorizationNoResponse];
	}
	
	[super windowWillClose:sender];

	[self autorelease];
}

- (void)closeWindow:(id)sender
{
	if (!windowIsClosing)
		[super closeWindow:sender];
}
	


- (IBAction)authorize:(id)sender
{
	postedAuthorizationResponse = YES;

	//Do the authorization serverside
	[account authorizationWindowController:self
					 authorizationWithDict:infoDict
							  response:AIAuthorizationAllowed];
	
	//Now handle the Add To Contact List checkbox
	AILog(@"Authorize: (%i) %@",[checkBox_addToList state],infoDict);

	if ([checkBox_addToList state] == NSOnState) {
		[[adium contactController] requestAddContactWithUID:[infoDict objectForKey:@"Remote Name"]
													service:[account service]
													account:account];
	}
	
	[infoDict release]; infoDict = nil;
	
	[self closeWindow:nil];
}

- (IBAction)deny:(id)sender
{
	postedAuthorizationResponse = YES;

	[account authorizationWindowController:self
					 authorizationWithDict:infoDict
								  response:AIAuthorizationDenied];	

	[infoDict release]; infoDict = nil;

	[self closeWindow:nil];
}

@end
