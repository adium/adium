//
//  ESShowContactInfoPromptController.m
//  Adium
//
//  Created by Evan Schoenberg on 1/8/06.
//

#import "ESShowContactInfoPromptController.h"
#import "AIContactInfoWindowController.h"
#import <Adium/AIListContact.h>

#define SHOW_CONTACT_INFO_PROMPT_NIB	@"ShowContactInfoPrompt"
#define GET_INFO_BUTTON_TITLE			AILocalizedStringFromTable(@"Get Info", @"Buttons", "'Get Info' on a button; when pressed, the information for a specified contact will be displayed")
#define GET_INFO_WINDOW_TITLE			AILocalizedString(@"Get Info", nil)

static ESShowContactInfoPromptController *sharedShowInfoPromptInstance = nil;

/*!
 * @class ESShowContactInfoPromptController
 * @brief Controller for the Show Contact Info prompt, which allows one to get info on an arbitrary contact
 */
@implementation ESShowContactInfoPromptController

/*!
 * @brief Return our shared instance
 * @result The shared instance
 */
+ (id)sharedInstance 
{
	return sharedShowInfoPromptInstance;
}

/*!
 * @brief Create the shared instance
 * @result The shared instance
 */
+ (id)createSharedInstance 
{
	sharedShowInfoPromptInstance = [[self alloc] initWithWindowNibName:SHOW_CONTACT_INFO_PROMPT_NIB];
	
	return sharedShowInfoPromptInstance;
}

/*!
 * @brief Destroy the shared instance
 */
+ (void)destroySharedInstance 
{
	[sharedShowInfoPromptInstance autorelease]; sharedShowInfoPromptInstance = nil;
}

/*!
 * @brief Window did load
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[label_using setLocalizedString:AILocalizedString(@"Using:","Label in front of an account drop-down selector to determine what account to use")];
	[label_contact setLocalizedString:AILocalizedString(@"Contact:",nil)];

	[button_okay setLocalizedString:GET_INFO_BUTTON_TITLE];
	[[self window] setTitle:GET_INFO_WINDOW_TITLE];
}

/*!
 * @brief Show info for the desired contact
 */
- (IBAction)okay:(id)sender
{
	AIListContact	*contact;

	if ((contact = [self contactFromTextField])) {
		[super okay:sender];

		[AIContactInfoWindowController showInfoWindowForListObject:contact];

		//Close the prompt
        [[self class] closeSharedInstance];
    }
}

- (NSString *)lastAccountIDKey
{
	return @"ShowContactInfo";
}

@end
