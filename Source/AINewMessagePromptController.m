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

#import "AINewMessagePromptController.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>

#define NEW_MESSAGE_PROMPT_NIB	@"NewMessagePrompt"

static AINewMessagePromptController *sharedNewMessageInstance = nil;

/*!
 * @class AINewMessagePromptController
 * @brief Controller for the New Message prompt, which allows messaging an arbitrary contact
 */
@implementation AINewMessagePromptController

/*!
 * @brief Return our shared instance
 * @result The shared instance
 */
+ (id)sharedInstance 
{
	return sharedNewMessageInstance;
}

/*!
 * @brief Create the shared instance
 * @result The shared instance
 */
+ (id)createSharedInstance 
{
	sharedNewMessageInstance = [[self alloc] initWithWindowNibName:NEW_MESSAGE_PROMPT_NIB];
	
	return sharedNewMessageInstance;
}

/*!
 * @brief Destroy the shared instance
 */
+ (void)destroySharedInstance 
{
	sharedNewMessageInstance = nil;
}

/*!
 * @brief Window did load
 */
- (void)windowDidLoad
{
	[super windowDidLoad];
	
	[label_from setLocalizedString:AILocalizedString(@"From:",nil)];
	[label_to setLocalizedString:AILocalizedString(@"To:",nil)];
	
	[button_okay setLocalizedString:AILocalizedStringFromTable(@"Message", @"Buttons", "Button title to open a message window the specific contact from the 'New Chat' window")];
	
	[[self window] setTitle:AILocalizedString(@"New Message",nil)];
}

/*!
 * @brief Suppress system autocompletion
 */
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)indexa
{
	return nil;
}

/*!
 * @brief Open a chat with the desired contact
 */
- (IBAction)okay:(id)sender
{
	AIListContact	*contact;
	
    if ((contact = [self contactFromTextField])) {
        //Initiate the message - the contact is on the right account
		[super okay:sender];

        [adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:contact
																			onPreferredAccount:NO]];
		
		//Close the prompt
        [[self class] closeSharedInstance];
    }
}

- (NSString *)lastAccountIDKey
{
	return @"NewMessagePrompt";
}

@end
