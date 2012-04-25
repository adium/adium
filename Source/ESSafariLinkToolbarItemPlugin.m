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

#import "ESApplescriptabilityController.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import "ESSafariLinkToolbarItemPlugin.h"
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <Adium/AIHTMLDecoder.h>

#define SAFARI_LINK_IDENTIFER	@"SafariLink"
#define SAFARI_LINK_SCRIPT_PATH	[[NSBundle bundleForClass:[self class]] pathForResource:@"Safari.scpt" ofType:nil]

@interface ESSafariLinkToolbarItemPlugin ()
- (IBAction)insertSafariLink:(id)sender;
- (void)applescriptDidRun:(id)userInfo resultString:(NSString *)resultString;
@end

/*!
 * @class ESSafariLinkToolbarItemPlugin
 * @brief Component to add a toolbar item which inserts a link to the active Safari web page
 */
@implementation ESSafariLinkToolbarItemPlugin

/*!
 * @brief Install
 */
- (void)installPlugin
{
	CFURLRef	urlToDefaultBrowser = NULL;
	NSString	*browserName = nil;
	NSImage		*browserImage = nil;

	if (LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://google.com"],
							   kLSRolesViewer,
							   NULL /*outAppRef*/,
							   &urlToDefaultBrowser) != kLSApplicationNotFoundErr) {
		NSString	*defaultBrowserName;
		NSString	*defaultBrowserPath;

		defaultBrowserPath = [(NSURL *)urlToDefaultBrowser path];
		defaultBrowserName = [[NSFileManager defaultManager] displayNameAtPath:defaultBrowserPath];

		//Is the default browser supported?
		NSEnumerator *enumerator = [[NSArray arrayWithObjects:@"Safari", @"Firefox", @"OmniWeb", @"Camino", @"Shiira", @"NetNewsWire", @"Google Chrome", nil] objectEnumerator];
		NSString	 *aSupportedBrowser;

		while ((aSupportedBrowser = [enumerator nextObject])) {
			if ([defaultBrowserName rangeOfString:aSupportedBrowser
										  options:(NSCaseInsensitiveSearch | NSLiteralSearch)].location != NSNotFound) {
				//Use the name and image provided by the system if possible
				browserName = defaultBrowserName;
				browserImage = [[NSWorkspace sharedWorkspace] iconForFile:defaultBrowserPath];
				break;
			}
		}
	}
	
	if (urlToDefaultBrowser) {
		CFRelease(urlToDefaultBrowser);
	}
	
	if (!browserName || !browserImage) {
		//Fall back on Safari and the image stored within our bundle if necessary
		browserName = @"Safari";
		browserImage = [NSImage imageNamed:@"Safari" forClass:[self class] loadLazily:YES];
	}	

	//Remote the path extension if there is one (.app if the Finder is set to show extensions; no change otherwise)
	browserName = [browserName stringByDeletingPathExtension];

	NSToolbarItem	*toolbarItem;
	toolbarItem = [AIToolbarUtilities toolbarItemWithIdentifier:SAFARI_LINK_IDENTIFER
														  label:[NSString stringWithFormat:AILocalizedString(@"%@ Link",nil), browserName]
												   paletteLabel:[NSString stringWithFormat:AILocalizedString(@"Insert %@ Link",nil), browserName]
														toolTip:[NSString stringWithFormat:AILocalizedString(@"Insert link to active page in %@",nil), browserName]
														 target:self
												settingSelector:@selector(setImage:)
													itemContent:browserImage
														 action:@selector(insertSafariLink:)
														   menu:nil];
	[adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}

/*!
 * @brief Insert a link to the active Safari page into the first responder if it is an NSTextView
 */
- (IBAction)insertSafariLink:(id)sender
{
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSTextView	*earliestTextView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];

	if (earliestTextView) {
		NSArray	*arguments = [NSArray arrayWithObject:AILocalizedString(@"Multiple browsers are open. Please select one link:", "Prompt when more than one web browser is available when inserting a link from the active browser.")];
		[adium.applescriptabilityController runApplescriptAtPath:SAFARI_LINK_SCRIPT_PATH
														  function:@"substitute"
														 arguments:arguments
												   notifyingTarget:self
														  selector:@selector(applescriptDidRun:resultString:)
														  userInfo:earliestTextView];
	} else {
		NSBeep();
	}
}

/*!
 * @brief A script finished running
 */
- (void)applescriptDidRun:(id)userInfo resultString:(NSString *)resultString
{
	NSTextView	*earliestTextView = (NSTextView *)userInfo;

	//If the script returns nil or fails, do nothing
	if (resultString && [resultString length]) {
		//Insert the script result - it should have returned an HTML link, so process it first
		NSAttributedString	*attributedScriptResult;
		NSDictionary		*attributes;
		
		attributedScriptResult = [AIHTMLDecoder decodeHTML:resultString];
		
		attributes = [[earliestTextView typingAttributes] copy];
		[earliestTextView insertText:attributedScriptResult];
		if (attributes) [earliestTextView setTypingAttributes:attributes];
		[attributes release];

	} else {
		NSBeep();		
	}
}

@end
