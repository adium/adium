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
