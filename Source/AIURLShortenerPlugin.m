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

#import "AIURLShortenerPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AutoHyperlinks/AHHyperlinkScanner.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>

#define SHORTEN_LINK_TITLE	AILocalizedString(@"Replace with Shortened URL", nil)

@interface AIURLShortenerPlugin()
- (void)shortenLink;

- (void)shortenAddress:(NSString *)address
		   withService:(AIShortenLinkService)service
			inTextView:(NSTextView *)textView;

- (void)insertResultFromURL:(NSURL *)inURL intoTextView:(NSTextView *)textView;
- (NSString *)resultFromURL:(NSURL *)inURL;
- (void)setShortener:(NSMenuItem *)menuItem;
@end

@implementation AIURLShortenerPlugin

- (void)installPlugin
{
	NSMenuItem *menuItem;
	
	NSMenu *shortenerSubMenu = [[NSMenu alloc] init];
	[shortenerSubMenu setDelegate:self];
	
	// Edit menu
	menuItem = [[NSMenuItem alloc] initWithTitle:SHORTEN_LINK_TITLE
										   target:self
										   action:@selector(shortenLink)
									keyEquivalent:@"K"
										  keyMask:NSCommandKeyMask];
	
	[menuItem setSubmenu:shortenerSubMenu];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Edit_Links];
	
	// Context menu
	menuItem = [[NSMenuItem alloc] initWithTitle:SHORTEN_LINK_TITLE
										   target:self
										   action:@selector(shortenLink)
									keyEquivalent:@""];
	
	[menuItem setSubmenu:[shortenerSubMenu copy]];
	
	[adium.menuController addContextualMenuItem:menuItem toLocation:Context_TextView_Edit];
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_FORMATTING];
}

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

#pragma mark Preferences
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if(object)
		return;
	
	if(firstTime || [key isEqualToString:KEY_SHORTENER_PREFERENCE]) {
		shortener = [[prefDict objectForKey:KEY_SHORTENER_PREFERENCE] intValue];
	}
}

#pragma mark Menu Item
/*!
 * @brief Update our shortener list
 *
 * @param menu The NSMenu which needs to be recomputed
 *
 * We're dealing with two separate menus with the same contents and a changing value.
 * Dynamically generate each time, since it's a short and simple operation.
 */
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSDictionary *shorteners = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:AITinyURL], @"tinyurl.com",
																		  [NSNumber numberWithInteger:AIisgd], @"is.gd",
																		  [NSNumber numberWithInteger:AIMetamark], @"xrl.us",
																		  nil];

	[menu removeAllItems];
	
	for(NSString *service in shorteners.allKeys) {
		NSInteger shortenerTag = [[shorteners objectForKey:service] integerValue];
			
		NSMenuItem *newItem = [menu addItemWithTitle:service
											  target:self
											  action:@selector(setShortener:)
									   keyEquivalent:@""
												 tag:shortenerTag];
		
		[newItem setState:(shortener == shortenerTag)];
	}
}

/*!
 * @brief Shortens the URL to the chosen service
 *
 * @param menuItem An NSMenuItem whose tag is a valid AIShortenLinkService
 */
- (void)setShortener:(NSMenuItem *)menuItem
{
	NSInteger shortenerTag = menuItem.tag;
	
	[adium.preferenceController setPreference:[NSNumber numberWithInteger:shortenerTag]
									   forKey:KEY_SHORTENER_PREFERENCE
										group:PREF_GROUP_FORMATTING];
	
	[self shortenLink];
}

/*!
 * @brief Our menu item is valid if we have a text view to replace in, the text view has some selected text in it, and the selected text is a valid URL.
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSTextView	*textView = (NSTextView *)[[NSApp keyWindow] earliestResponderOfClass:[NSTextView class]];
	if (textView) {
		NSAttributedString *text = textView.textStorage;
		NSRange selectedRange = textView.selectedRange;

		//If we have some text and the start of the selection is not at the end of the string...
		if ((text.length > 0) && (selectedRange.location < text.length)) {
			if ([text attribute:NSLinkAttributeName atIndex:selectedRange.location effectiveRange:NULL])
				return YES;

			if (selectedRange.length > 0) {
				//If the selected text is a URL (more or less), good enough for us.
				return [AHHyperlinkScanner isStringValidURI:[text.string substringWithRange:selectedRange] usingStrict:NO fromIndex:NULL withStatus:NULL schemeLength:NULL];
			}
		}
	}

	return NO;
}

/*!
 * @brief Shorten a URL
 *
 * In the current window, take the currently-selected URL, or the URL of the attributed range the
 * cursor is on, and shorten it using the service the user has set.
 */
- (void)shortenLink
{
	NSWindow	*keyWin = NSApplication.sharedApplication.keyWindow;
	NSTextView	*textView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];
	
	// Don't try and do anything on an empty input line or if we're at the end
	if(!textView.textStorage.length || textView.selectedRange.location == textView.textStorage.length) {
		NSBeep();
		return;
	}
	
	NSRange selectedRange = textView.selectedRange;
	NSRange	rangeOfLinkAttribute;
	
	NSString *linkURL = nil;
	
	id unknownLinkURL = [textView.textStorage attribute:NSLinkAttributeName
												atIndex:selectedRange.location
										 effectiveRange:&rangeOfLinkAttribute];
	
	if (unknownLinkURL) {
		//If a link exists at our selection, expand the selection to encompass that entire link
		selectedRange = rangeOfLinkAttribute;
		[textView setSelectedRange:selectedRange];

		if([unknownLinkURL isKindOfClass:[NSURL class]]) {
			linkURL = [(NSURL *)unknownLinkURL absoluteString];
		} else {
			linkURL = unknownLinkURL;
		}
	} else {
		linkURL = [[textView attributedSubstringFromRange:selectedRange] string];
	}
	
	if(linkURL.length) {
		// Make sure the HTTP prefix is set.
		if(![linkURL hasPrefix:@"http"]) {
			linkURL = [@"http://" stringByAppendingString:linkURL];
		}
		
		// Convert to a shortened URL using the user's preference.
		[self shortenAddress:linkURL
				 withService:shortener
				  inTextView:textView];
	} else {
		NSBeep();
	}
}

#pragma mark Shorten a URL
/*!
 * @brief Shorten the requested address
 *
 * @param address An NSString with the absolute address to shorten
 * @param service An AIShortenLinkService value corresponding to the service used for shortening
 * @param textView An NSTextView whose selected range will be replaced with the shortened value
 */
- (void)shortenAddress:(NSString *)address
		   withService:(AIShortenLinkService)service
			inTextView:(NSTextView *)textView
{
	NSString *request = nil;
	
	switch(service) {
		case AITinyURL:
			request = [NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", [address stringByAddingPercentEscapesForAllCharacters]];
			break;
			
		case AIisgd:
			request = [NSString stringWithFormat:@"http://is.gd/api.php?longurl=%@", [address stringByAddingPercentEscapesForAllCharacters]];
			break;
			
		case AIMetamark:
			request = [NSString stringWithFormat:@"http://metamark.net/api/rest/simple?long_url=%@", [address stringByAddingPercentEscapesForAllCharacters]];
			break;
			
		default:
			
			break;
	}
	
	if (request) {
		[self insertResultFromURL:[NSURL URLWithString:request] intoTextView:textView];
	}
}

#pragma mark Simple shorteners
/*!
 * @brief Request a URL, insert into text view
 *
 * @param inURL The NSURL to request
 * @param textView the NSTextView to insert the shortened URL itno
 *
 * Replaces the selected text in textView with the result of requesting
 * the page at inURL if successful. Otherwise, beep.
 */
- (void)insertResultFromURL:(NSURL *)inURL intoTextView:(NSTextView *)textView
{	
	NSString *shortenedURL = [self resultFromURL:inURL];
	
	if(shortenedURL) {
		NSRange selectedRange = textView.selectedRange;
		
		// Replace the current selection with the new URL
		NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[textView.attributedString attributesAtIndex:selectedRange.location effectiveRange:nil]];
		[attrs setObject:shortenedURL forKey:NSLinkAttributeName];
		
		[textView.textStorage replaceCharactersInRange:selectedRange
								  withAttributedString:[[NSAttributedString alloc] initWithString:shortenedURL attributes:attrs]];
		
		// Select the inserted URL
		textView.selectedRange = NSMakeRange(selectedRange.location, shortenedURL.length);
		
		// Post a notification that we've changed the text
		[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
											  			    object:textView];
	} else {
		// Be as obscure as possible: roadrunner.
		NSBeep();
	}
}

/*!
 * @brief Requests a URL, returns the contents
 *
 * @param inURL The NSURL to request
 * @return An NSString of the page requested or nil
 *
 * Synchronously requests the given URL. If the request is successful, i.e. the
 * HTTP status code is 200 and there's no error, the contents of the page are returned.
 */
- (NSString *)resultFromURL:(NSURL *)inURL
{
	NSString *resultString = nil;
	
	NSURLResponse *response = nil;
	NSError *errorResponse = nil;
	
	// We send a synchronous request so the user can't change selection on us.
	// If the target site is slow, this may seem unpleasant.
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:inURL];
	[request setHTTPShouldHandleCookies:NO];
	NSData	*shortenedData = [NSURLConnection sendSynchronousRequest:request
												  returningResponse:&response
															  error:&errorResponse];
	
	AILogWithSignature(@"Requesting %@", inURL);
	
	// If the request was successful, replace the selected text with the shortened URL. Otherwise fail silently.
	if(shortenedData && !errorResponse && ((NSHTTPURLResponse *)response).statusCode == 200) {
		resultString = [[NSString stringWithData:shortenedData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		AILogWithSignature(@"Shortened to %@", resultString);
	} else {
		AILogWithSignature(@"Unable to shorten: %@", errorResponse);
	}
	
	return resultString;
}

@end
