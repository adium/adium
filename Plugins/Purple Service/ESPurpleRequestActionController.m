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

#import "ESPurpleRequestActionController.h"
#import <AdiumLibpurple/PurpleCommon.h>
#import "adiumPurpleRequest.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import "ESTextAndButtonsWindowController.h"
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

@interface ESPurpleRequestActionController ()
- (id)initWithDict:(NSDictionary *)infoDict;
- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict;
- (void)doRequestActionCbValue:(NSValue *)callBackValue
			 withUserDataValue:(NSValue *)userDataValue 
				 callBackIndex:(NSNumber *)callBackIndexNumber;
@end

@implementation ESPurpleRequestActionController

/*!
 * @brief Show an action request window
 *
 * @param infoDict Dictionary of information to display, including callbacks for the buttons
 * @result The ESPurpleRequestActionController for the displayed window
 */
+ (ESPurpleRequestActionController *)showActionWindowWithDict:(NSDictionary *)infoDict
{
	return [[self alloc] initWithDict:infoDict];
}

- (id)initWithDict:(NSDictionary *)infoDict
{
	if ((self = [super init])) {
		NSAttributedString	*attributedMessage = nil;
		NSArray				*buttonNamesArray;
		NSString			*title = nil, *message = nil;
		NSString			*messageHeader = nil, *defaultButton = nil, *alternateButton = nil, *otherButton = nil;
		NSUInteger			buttonNamesArrayCount;

		infoDict = [self translatedInfoDict:infoDict];

		theInfoDict = [infoDict retain];

		title = [infoDict objectForKey:@"TitleString"];
		
		//Message or message header may be in HTML. If it's plain text, we'll just be getting an attributed string out of this.
		message = [infoDict objectForKey:@"Message"];
		attributedMessage = (message ? [AIHTMLDecoder decodeHTML:message] : nil);
		
		// Decode the message header's HTML, and get the string value.
		messageHeader = [infoDict objectForKey:@"MessageHeader"];

		if (messageHeader) {
			messageHeader = [[AIHTMLDecoder decodeHTML:messageHeader] string];
		}
		
		// If we're not give an attributed message, use the title as a message.
		if (!attributedMessage) {
			attributedMessage = [NSAttributedString stringWithString:title];
			title = nil;
		}
		
		buttonNamesArray = [infoDict objectForKey:@"Button Names"];
		buttonNamesArrayCount = [buttonNamesArray count];
		
		//The last object in the buttons array is the default; alternate is second to last; otherButton is last
		defaultButton = [buttonNamesArray lastObject];
		if (buttonNamesArrayCount > 1) {
			alternateButton = [buttonNamesArray objectAtIndex:(buttonNamesArrayCount-2)];
			
			if (buttonNamesArrayCount > 2) {
				otherButton = [buttonNamesArray objectAtIndex:(buttonNamesArrayCount-3)];			
			}
		}
		
		/*
		 * If we have an attribMsg and a titleString, use the titleString as the window title.
		 * If we just have the titleString (and no attribMsg), it is our message, and the window has no title.
		 */
		requestController = [[ESTextAndButtonsWindowController alloc] initWithTitle:title
																				   defaultButton:defaultButton
																				 alternateButton:alternateButton
																					 otherButton:otherButton
																			   withMessageHeader:messageHeader
																					  andMessage:attributedMessage
																						  target:self
																						userInfo:infoDict];
		// We retain it once more, as showOnWindow will (eventually) do a release.
		[requestController retain];
		[requestController showOnWindow:nil];
		
		if ([infoDict objectForKey:@"Image"])
			[requestController setImage:[infoDict objectForKey:@"Image"]];

		[requestController setAllowsCloseWithoutResponse:NO];
	}
	
	return self;
}

- (void)dealloc
{
	[requestController release]; requestController = nil;
	[theInfoDict release];

	[super dealloc];
}

- (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode suppression:(BOOL)suppression userInfo:(id)userInfo
{
	GCallback		*theCallBacks;
	NSUInteger	actionCount;
	NSInteger				callBackIndex;

	theCallBacks = [[userInfo objectForKey:@"callBacks"] pointerValue];
	actionCount = [[userInfo objectForKey:@"Button Names"] count];

	callBackIndex = -1;
		
	switch (returnCode) {
		case AITextAndButtonsDefaultReturn:
			callBackIndex = (actionCount - 1);
			break;
			
		case AITextAndButtonsAlternateReturn:
			callBackIndex = (actionCount - 2);
			break;

		case AITextAndButtonsOtherReturn:
			callBackIndex = (actionCount - 3);
			break;
			
		case AITextAndButtonsClosedWithoutResponse:
			break;
	}

	if ((callBackIndex != -1) && (theCallBacks[callBackIndex] != NULL)) {
		[self doRequestActionCbValue:[NSValue valueWithPointer:theCallBacks[callBackIndex]]
				   withUserDataValue:[userInfo objectForKey:@"userData"]
					   callBackIndex:[NSNumber numberWithInteger:callBackIndex]];

	} else {
		NSLog(@"Failure.");
	}
	
	//We won't need to try to close it ourselves later
	[requestController release]; requestController = nil;
	
	//Inform libpurple that the request window closed
	[ESPurpleRequestAdapter requestCloseWithHandle:self];	

	return YES;
}

- (void)doRequestActionCbValue:(NSValue *)callBackValue
			 withUserDataValue:(NSValue *)userDataValue 
				 callBackIndex:(NSNumber *)callBackIndexNumber
{
	AILogWithSignature(@"");

	PurpleRequestActionCb callBack = [callBackValue pointerValue];
	if (callBack) {
		callBack([userDataValue pointerValue],[callBackIndexNumber intValue]);
	}
}

/*!
 * @brief libpurple has been made aware we closed or has informed us we should close
 *
 * Close our requestController's window if it's open; then release (we returned without autoreleasing initially).
 */
- (void)purpleRequestClose
{
	AILogWithSignature(@"");

	if (requestController) {
		[[requestController window] orderOut:self];
		[requestController close];
	}
	
	[self autorelease];
}

/*!
 * @brief Translate the strings in the info dictionary
 *
 * The following declarations let genstrings know about what translations we want
 * AILocalizedString(@"Allow MSN Mobile pages?", nil)
 * AILocalizedString(@"Do you want to allow or disallow people on your buddy list to send you MSN Mobile pages to your cell phone or other mobile device?", nil)
 * AILocalizedString(@"Allow","Button title to allow an action")
 * AILocalizedString(@"Disallow", "Button title to prevent an action")
 * AILocalizedString(@"Connect",nil)
 * AILocalizedString(@"Cancel", nil)
 * AILocalizedString(@"Send", nil)
 */

- (void)processBuddyListSynchronizationForTitle:(NSString **)title message:(NSString **)message
{
	/*
	 title is "Buddy list synchronization issue in %s (%s)"),
	 purple_account_get_username(account),
	 purple_account_get_protocol_name(account));
	 
	 message is ("%s on the local list is inside the group \"%s\" but not on the server list. Do you want this buddy to be added?")
	 
	or ("%s is on the local list but not on the server list. Do you want this buddy to be added?"),	
	*/
	NSRange startRange = [*title rangeOfString:@"Buddy list synchronization issue in "];
	*title  = [NSString stringWithFormat:AILocalizedString(@"Contact list synchronization error for %@", nil), [*title substringFromIndex:NSMaxRange(startRange)]];	
	
	startRange = [*message rangeOfString:@" "];
	*message = [NSString stringWithFormat:AILocalizedString(@"%@ is on your local contact list but not on the server list. Do you want to add this contact to your list?", nil), [*message substringToIndex:startRange.location]];
}

- (NSDictionary *)translatedInfoDict:(NSDictionary *)inDict
{
	NSMutableDictionary	*translatedDict = [inDict mutableCopy];
	
	NSString		*title = [inDict objectForKey:@"TitleString"];
	NSString		*message = [inDict objectForKey:@"Message"];
	NSMutableArray	*buttonNamesArray = [NSMutableArray array];
	NSBundle		*thisBundle = [NSBundle bundleForClass:[self class]];
	NSString		*buttonName;
	NSEnumerator	*enumerator;

	if (title && [title rangeOfString:@"Buddy list synchronization issue in"].location != NSNotFound) {
		[self processBuddyListSynchronizationForTitle:&title message:&message];
		[translatedDict setObject:title
						   forKey:@"TitleString"];
		[translatedDict setObject:message
						   forKey:@"Message"];
		
	} else {
		//Replace each string with a translated version if possible
		[translatedDict setObject:[thisBundle localizedStringForKey:title
															  value:title
															  table:nil]
						   forKey:@"TitleString"];
		[translatedDict setObject:[thisBundle localizedStringForKey:message
															  value:message
															  table:nil]
						   forKey:@"Message"];
	}

	enumerator = [[inDict objectForKey:@"Button Names"] objectEnumerator];
	while ((buttonName = [enumerator nextObject])) {
		[buttonNamesArray addObject:[thisBundle localizedStringForKey:buttonName
																value:buttonName
																table:nil]];
	}
	[translatedDict setObject:buttonNamesArray
					   forKey:@"Button Names"];

	return [translatedDict autorelease];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %@>",[super description], theInfoDict];
}

@end
