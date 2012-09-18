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

#import "ESPurpleNotifyEmailController.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <AdiumLibpurple/PurpleCommon.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIAccount.h>


@interface ESPurpleNotifyEmailController ()
+ (void)openURLString:(NSString *)urlString;
+ (void)startMailApplication;
+ (NSString *)mailApplicationName;
+ (void)showNotifyEmailWindowForAccount:(AIAccount *)account withMessage:(NSAttributedString *)inMessage URLString:(NSString *)inURLString;
@end

@implementation ESPurpleNotifyEmailController

/*!
 * @brief Handle the notification of emails
 *
 * This may be called from the purple thread.
 */
+ (void *)handleNotifyEmailsForAccount:(AIAccount *)account count:(size_t)count detailed:(BOOL)detailed subjects:(const char **)subjects froms:(const char **)froms tos:(const char **)tos urls:(const char **)urls
{
	NSFontManager				*fontManager = [NSFontManager sharedFontManager];
	NSFont						*messageFont = [NSFont messageFontOfSize:11];
	NSMutableParagraphStyle		*centeredParagraphStyle;
	NSMutableAttributedString   *message;
	
	centeredParagraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[centeredParagraphStyle setAlignment:NSCenterTextAlignment];
	message = [[NSMutableAttributedString alloc] init];
	
	//Title
	NSString		*title;
	NSFont			*titleFont;
	NSDictionary	*titleAttributes;
	
	title = AILocalizedString(@"You have mail!\n",nil);
	titleFont = [fontManager convertFont:[NSFont messageFontOfSize:12]
							 toHaveTrait:NSBoldFontMask];
	titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:titleFont,NSFontAttributeName,
		centeredParagraphStyle,NSParagraphStyleAttributeName,nil];
	
	[message appendAttributedString:[[NSAttributedString alloc] initWithString:title
																	 attributes:titleAttributes]];
	
	//Message
	NSString		*numberMessage;
	NSDictionary	*numberMessageAttributes;
	NSString		*yourName;
	
	if (account) {
		yourName = account.formattedUID;
	} else if (tos && *tos) {
		yourName = [NSString stringWithUTF8String:*tos];
	} else {
		yourName = nil;
	}

	if (yourName && [yourName length]) {
		numberMessage = ((count == 1) ? 
						 [NSString stringWithFormat:AILocalizedString(@"%@ has 1 new message.",nil), yourName] :
						 [NSString stringWithFormat:AILocalizedString(@"%@ has %u new messages.",nil), yourName, count]);

	} else {
		numberMessage = ((count == 1) ? 
						 AILocalizedString(@"You have 1 new message.",nil) :
						 [NSString stringWithFormat:AILocalizedString(@"You have %u new messages.",nil), count]);		
	}

	numberMessageAttributes = [NSDictionary dictionaryWithObjectsAndKeys:messageFont,NSFontAttributeName,
		centeredParagraphStyle,NSParagraphStyleAttributeName,nil];
	
	[message appendAttributedString:[[NSAttributedString alloc] initWithString:numberMessage
																	 attributes:numberMessageAttributes]];
	
	if (count == 1) {
		BOOL	haveFroms    = (froms    != NULL);
		BOOL	haveSubjects = (subjects != NULL);
		
		if (haveFroms || haveSubjects) {
			NSFont			*fieldFont;
			NSDictionary	*fieldAttributed, *infoAttributed;
			
			fieldFont =  [fontManager convertFont:messageFont
									  toHaveTrait:NSBoldFontMask];
			fieldAttributed = [NSDictionary dictionaryWithObject:fieldFont forKey:NSFontAttributeName];
			infoAttributed = [NSDictionary dictionaryWithObject:messageFont forKey:NSFontAttributeName];
			
			//Skip a line
			[[message mutableString] appendString:@"\n\n"];
			
			if (haveFroms) {
				NSString	*fromString = [NSString stringWithUTF8String:(*froms)];
				if (fromString && [fromString length]) {
					[message appendAttributedString:[[NSAttributedString alloc] initWithString:AILocalizedString(@"From: ",nil)
																					 attributes:fieldAttributed]];
					[message appendAttributedString:[[NSAttributedString alloc] initWithString:fromString
																					 attributes:infoAttributed]];
				}
			}
			
			if (haveFroms && haveSubjects) {
				[[message mutableString] appendString:@"\n"];
			}
			
			if (haveSubjects) {
				NSString	*subjectString = [NSString stringWithUTF8String:(*subjects)];
				if (subjectString && [subjectString length]) {
					[message appendAttributedString:[[NSAttributedString alloc] initWithString:AILocalizedString(@"Subject: ",nil)
																					 attributes:fieldAttributed]];
					AILog(@"%@: %@ appending %@",self,message,subjectString);
					[message appendAttributedString:[[NSAttributedString alloc] initWithString:subjectString
																					 attributes:infoAttributed]];				
				} else {
					AILog(@"Got an invalid subjectString from %s",*subjects);
				}
			}
		}
	}
	
	NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:title,@"Title",
		message,@"Message",nil];
	
	NSString	*urlString = ((urls && *urls) ? [NSString stringWithUTF8String:(*urls)] : nil);

	if (urlString) {
		[infoDict setObject:urlString forKey:@"URL"];
	}
	
	assert([[NSThread currentThread] isMainThread]);
	[self showNotifyEmailWindowForAccount:account withMessage:message URLString:(urlString ? urlString : nil)];

	return NULL;
}

/*!
 * @brief Show the New Mail message
 *
 * Displays the New Mail message, optionally offerring an Open Mail button (if a URL to open the webmail is passed).
 *
 * @param account The account which received new mail
 * @param inMessage An attributed message describing the new mail
 * @param inURLString The URL to the appropriate webmail, or nil if no webmail link is available
 */
+ (void)showNotifyEmailWindowForAccount:(AIAccount *)account withMessage:(NSAttributedString *)inMessage URLString:(NSString *)inURLString
{	
	NSString *mailApplicationName = [self mailApplicationName];
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"AINoNewMailWindow"]) {
		ESTextAndButtonsWindowController *textAndButtonsWindowController = [[ESTextAndButtonsWindowController alloc] initWithTitle:AILocalizedString(@"New Mail",nil)
																													 defaultButton:nil
																												   alternateButton:(inURLString ? 
																																	AILocalizedString(@"Open Mail in Browser",nil) :
																																	nil)
																													   otherButton:((mailApplicationName && [mailApplicationName length]) ?
																																	[NSString stringWithFormat:AILocalizedString(@"Launch %@", nil), mailApplicationName] :
																																	nil)
																												 withMessageHeader:nil
																														andMessage:inMessage
																															target:self
																														  userInfo:inURLString];
		[textAndButtonsWindowController showOnWindow:nil];
	}
	
	//XXX - Hook this to the account for listobject
	[adium.contactAlertsController generateEvent:ACCOUNT_RECEIVED_EMAIL
															  forListObject:account
																   userInfo:[inMessage string]
											   previouslyPerformedActionIDs:nil];	
}

/*!
 * @brief Window was closed, either by a button being clicked or the user closing it
 */
+ (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode suppression:(BOOL)suppression userInfo:(id)userInfo
{
	switch (returnCode) {
		case AITextAndButtonsAlternateReturn:
			if (userInfo) [self openURLString:userInfo];
			break;

		case AITextAndButtonsDefaultReturn:
			break;
			
		case AITextAndButtonsOtherReturn:
			if (userInfo) [self startMailApplication];
			break;
			
		case AITextAndButtonsClosedWithoutResponse:
			//No action needed
			break;
	}
	
	return YES;
}

/*!
 * @brief Start mail application from the new mail window
 *
 * Launch the user's mail application instead of opening the webmail-page
 */ 
+ (void)startMailApplication {
	if ([[NSWorkspace sharedWorkspace] launchApplication:[self mailApplicationName]] == NO) {
		NSLog(@"Could not launch mail application '%@'", [self mailApplicationName]);
	}
}

/*!
 * @brief Open a URL string from the open mail window
 *
 * The urlString could either be a web address or a path to a local HTML file we are supposed to load.
 * The local HTML file will be in the user's temp directory, which Purple obtains with g_get_tmp_dir()...  
 * so we will, too.
 */ 
+ (void)openURLString:(NSString *)urlString
{
	if ([urlString rangeOfString:[NSString stringWithUTF8String:g_get_tmp_dir()]].location != NSNotFound) {
		//Local HTML file
		CFURLRef	appURL = NULL;
		OSStatus	err;
		
		/* Obtain the default http:// handler. We don't care what would handle _this file_ (its extension doesn't matter)
		 * nor what normally happens when the user opens a .html file since that is, on many systems, an HTML editor.
		 * Instead, we want to know what application to use for viewing web pages... and then open this file in it.
		 */
		err = LSGetApplicationForURL((__bridge CFURLRef)[NSURL URLWithString:@"http://www.adium.im"],
									 kLSRolesViewer,
									 /*outAppRef*/ NULL,
									 &appURL);
		if (err == noErr) {
			[[NSWorkspace sharedWorkspace] openFile:[urlString stringByExpandingTildeInPath]
									withApplication:[(__bridge NSURL *)appURL path]];
		} else {
			NSURL		*url;
			
			//Web address
			url = [NSURL URLWithString:urlString];
			[[NSWorkspace sharedWorkspace] openURL:url];
		}
		
		if (appURL) {
			//LSGetApplicationForURL() requires us to release the appURL when we are done with it
			CFRelease(appURL);
		}
		
	} else {
		NSURL		*emailURL;
		
		//Web address
		emailURL = [NSURL URLWithString:urlString];
		[[NSWorkspace sharedWorkspace] openURL:emailURL];
	}
}

/*!
 * @brief Returns the name of the user's mail application
 *
 * Use the LaunchServices to identify the user's mail application and return it's name
 * @return NSString with the application's name
 */ 
+ (NSString *)mailApplicationName {
	NSString *appName;
	FSRef myAppRef;
	
	LSGetApplicationForURL((__bridge CFURLRef)[NSURL URLWithString:@"mailto://"], kLSRolesAll, &myAppRef, NULL);
	CFStringRef boop = NULL;
	LSCopyDisplayNameForRef(&myAppRef, &boop);
	appName = (__bridge NSString *)boop;
	
	NSRange appRange;
	if ((appRange = [appName rangeOfString:@".app" options:(NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch)]).location != NSNotFound) {
		appName = [appName substringToIndex:appRange.location];
	}

	return appName;
}

@end
