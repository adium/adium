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
#import <Adium/AIMenuControllerProtocol.h>

#define SHORTEN_LINK_TITLE	AILocalizedString(@"Replace with Shortened URL", nil)

typedef enum {
	AITinyURL = 0,
	AIISGD,
	AIMetamark
} AIShortenLinkService;

@interface AIURLShortenerPlugin()
- (void)shortenAddress:(NSString *)address
		   withService:(AIShortenLinkService)service
			inTextView:(NSTextView *)textView;

- (void)insertResultFromURL:(NSURL *)inURL intoTextView:(NSTextView *)textView;
- (NSString *)resultFromURL:(NSURL *)inURL;
@end

@implementation AIURLShortenerPlugin

- (void)installPlugin
{
	NSMenuItem *menuItem;
	
	// Edit menu
	menuItem = [[[NSMenuItem alloc] initWithTitle:SHORTEN_LINK_TITLE
										   target:self
										   action:@selector(shortenLink:)
									keyEquivalent:@"K"
										  keyMask:NSCommandKeyMask] autorelease];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Edit_Links];
	
	// Context menu
	menuItem = [[[NSMenuItem alloc] initWithTitle:SHORTEN_LINK_TITLE
										   target:self
										   action:@selector(shortenLink:)
									keyEquivalent:@""] autorelease];
	
	[adium.menuController addContextualMenuItem:menuItem toLocation:Context_TextView_Edit];
}

- (void)uninstallPlugin
{
	
}

- (void)dealloc
{	
	[super dealloc];
}

#pragma mark Menu ItemCount
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	
	return (responder && [responder isKindOfClass:[NSTextView class]]);
}

- (void)shortenLink:(NSMenuItem *)menuItem
{
	NSWindow	*keyWindow = NSApplication.sharedApplication.keyWindow;
	NSTextView	*textView = (NSTextView *)[keyWindow earliestResponderOfClass:[NSTextView class]];
	
	// Don't try and do anything on an empty input line.
	if(!textView.textStorage.length)
		return;
	
	NSRange selectedRange = textView.selectedRange;
	NSRange	rangeOfLinkAttribute;
	
	NSString *linkURL = nil;
	
	id unknownLinkURL = [textView.textStorage attribute:NSLinkAttributeName
												atIndex:selectedRange.location
										 effectiveRange:&rangeOfLinkAttribute];
	
	if (unknownLinkURL) {
		//If a link exists at our selection, expand the selection to encompass that entire link
		[textView setSelectedRange:rangeOfLinkAttribute];
		selectedRange = rangeOfLinkAttribute;

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
		
		// Convert to a tiny URL
		[self shortenAddress:linkURL
				 withService:AITinyURL
				  inTextView:textView];
	} else {
		NSBeep();
	}
}

#pragma mark Shorten a URL
- (void)shortenAddress:(NSString *)address
		   withService:(AIShortenLinkService)service
			inTextView:(NSTextView *)textView
{
	NSString *request = nil;
	
	switch(service) {
		case AITinyURL:
			request = [NSString stringWithFormat:@"http://tinyurl.com/api-create.php?url=%@", [address stringByEncodingURLEscapes]];
			break;
			
		case AIISGD:
			request = [NSString stringWithFormat:@"http://is.gd/api.php?longurl=%@", [address stringByEncodingURLEscapes]];
			break;
			
		case AIMetamark:
			request = [NSString stringWithFormat:@"http://metamark.net/api/rest/simple?long_url=%@", [address stringByEncodingURLEscapes]];
			break;
			
		default:
			
			break;
	}
	
	if (request) {
		[self insertResultFromURL:[NSURL URLWithString:request] intoTextView:textView];
	}
}

#pragma mark Simple shorteners
- (void)insertResultFromURL:(NSURL *)inURL intoTextView:(NSTextView *)textView
{	
	NSString *shortenedURL = [self resultFromURL:inURL];
	
	if(shortenedURL) {
		[textView.textStorage replaceCharactersInRange:textView.selectedRange
		 withAttributedString:[NSAttributedString attributedStringWithLinkLabel:shortenedURL
																linkDestination:shortenedURL]];
	} else {
		// Be as obscure as possible: roadrunner.
		NSBeep();
	}
}

- (NSString *)resultFromURL:(NSURL *)inURL
{
	NSString *resultString = nil;
	
	NSURLResponse *response = nil;
	NSError *errorResponse = nil;
	
	NSData	*shortenedData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:inURL]
												  returningResponse:&response
															  error:&errorResponse];
	
	AILogWithSignature(@"Requesting %@", inURL);
	
	// If the request was successful, replace the selected text with the shortened URL. Otherwise fail silently.
	if(((NSHTTPURLResponse *)response).statusCode == 200) {
		resultString = [NSString stringWithData:shortenedData encoding:NSUTF8StringEncoding];
		AILogWithSignature(@"Shortened to %@", resultString);
	} else {
		AILogWithSignature(@"Unable to shorten: %@", errorResponse);
	}
	
	return resultString;
}

@end
