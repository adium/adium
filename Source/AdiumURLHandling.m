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

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>

#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>

#import "AdiumURLHandling.h"
#import "XtrasInstaller.h"
#import "ESTextAndButtonsWindowController.h"
#import "AINewContactWindowController.h"
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIURLAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIService.h>

#define GROUP_URL_HANDLING			@"URL Handling Group"
#define KEY_DONT_PROMPT_FOR_URL		@"Don't Prompt for URL"
#define KEY_COMPLETED_FIRST_LAUNCH	@"AdiumURLHandling:CompletedFirstLaunch"

#define ADIUM_BUNDLE_ID				@"com.adiumX.adiumX"
#define SUPPORTED_MESSAGING_SCHEMES_ARRAY		[NSArray arrayWithObjects:@"aim", @"ymsgr", @"yahoo", @"xmpp", @"jabber", @"msn", nil]

@interface AdiumURLHandling(PRIVATE)
+ (void)registerAsDefaultIMClient;
+ (void)_setHelperAppForScheme:(NSString *)scheme;
+ (BOOL)_checkHelperAppForScheme:(NSString *)scheme;
+ (void)_openChatToContactWithName:(NSString *)name onService:(NSString *)serviceIdentifier withMessage:(NSString *)body;
+ (void)_openAIMGroupChat:(NSString *)roomname onExchange:(int)exchange;
+ (void)_openXMPPGroupChat:(NSString *)name onServer:(NSString *)server withPassword:(NSString *)inPassword;
- (void)promptUser;
@end

@implementation AdiumURLHandling

+ (void)registerURLTypes
{
	NSEnumerator *enumerator = [SUPPORTED_MESSAGING_SCHEMES_ARRAY objectEnumerator];
	NSString	 *scheme;
	BOOL		 alreadySet = YES;

	//Determine if any schemes aren't set to us; we'll prompt if not
	while (alreadySet && (scheme = [enumerator nextObject])) {
		alreadySet &= [self _checkHelperAppForScheme:scheme];
	}
	 
	if (!alreadySet) {
		//Ask the user
		AdiumURLHandling *instance = [[AdiumURLHandling alloc] init];
		[instance promptUser];
		[instance release];
	}
	
	//Adium xtras
	[self _setHelperAppForScheme:@"adiumxtra"];
}

+ (void)registerAsDefaultIMClient
{		
	//Configure the protocols we want.
	NSEnumerator *enumerator = [SUPPORTED_MESSAGING_SCHEMES_ARRAY objectEnumerator];
	NSString	 *scheme;
	
	//Determine if any schemes aren't set to us; we'll prompt if not
	while ((scheme = [enumerator nextObject])) {
		[AdiumURLHandling _setHelperAppForScheme:scheme];
	}

	//Adium xtras
	[AdiumURLHandling _setHelperAppForScheme:@"adiumxtra"];
}

+ (void)handleURLEvent:(NSString *)eventString
{
	NSURL				*url = [NSURL URLWithString:eventString];

	if (url) {
		NSString	*scheme, *newScheme;
		NSString	*serviceID;

		//make sure we have the // in ://, as it simplifies later processing.
		if (![[url resourceSpecifier] hasPrefix:@"//"]) {
			eventString = [NSString stringWithFormat:@"%@://%@", [url scheme], [url resourceSpecifier]];
			url = [NSURL URLWithString:eventString];
		}

		scheme = [url scheme];

		//map schemes to common aliases (like jabber: for xmpp:).
		static NSDictionary *schemeMappingDict = nil;
		if (!schemeMappingDict) {
			schemeMappingDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"ymsgr", @"yahoo",
				@"xmpp", @"jabber",
				nil];
		}
		newScheme = [schemeMappingDict objectForKey:scheme];
		if (newScheme) {
			scheme = newScheme;
			eventString = [NSString stringWithFormat:@"%@:%@", scheme, [url resourceSpecifier]];
			url = [NSURL URLWithString:eventString];
		}

		static NSDictionary	*schemeToServiceDict = nil;
		if (!schemeToServiceDict) {
			schemeToServiceDict = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"AIM",    @"aim",
				@"Yahoo!", @"ymsgr",
				@"Jabber", @"xmpp",
 			    @"GTalk",  @"gtalk",
				@"MSN",    @"msn",
				nil];
		}
		
		if ((serviceID = [schemeToServiceDict objectForKey:scheme])) {
			NSString *host = [url host];
			NSString *query = [url query];
			if ([host caseInsensitiveCompare:@"goim"] == NSOrderedSame) {
				// aim://goim?screenname=tekjew
				NSString	*name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];

				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID 
										 withMessage:[[url queryArgumentForKey:@"message"] stringByDecodingURLEscapes]];
				}

			} else if ([host caseInsensitiveCompare:@"addbuddy"] == NSOrderedSame) {
				// aim://addbuddy?screenname=tekjew
				// aim://addbuddy?listofscreennames=screen+name1,screen+name+2&groupname=buddies
				NSString	*name = [[[url queryArgumentForKey:@"screenname"] stringByDecodingURLEscapes] compactedString];
				AIService	*service = [[adium accountController] firstServiceWithServiceID:serviceID];
				
				if (name) {
					[[adium contactController] requestAddContactWithUID:name
																service:service
																	  account:nil];
					
				} else {
					NSString		*listOfNames = [url queryArgumentForKey:@"listofscreennames"];
					NSArray			*names = [listOfNames componentsSeparatedByString:@","];
					NSEnumerator	*enumerator;
					
					enumerator = [names objectEnumerator];
					while ((name = [enumerator nextObject])) {
						NSString	*decodedName = [[name stringByDecodingURLEscapes] compactedString];
						[[adium contactController] requestAddContactWithUID:decodedName
																	service:service
																		  account:nil];
					}
				}

			} else if ([host caseInsensitiveCompare:@"sendim"] == NSOrderedSame) {
				// ymsgr://sendim?tekjew
				NSString *name = [[[url query] stringByDecodingURLEscapes] compactedString];
				
				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
				
			} else if ([host caseInsensitiveCompare:@"im"] == NSOrderedSame) {
				// ymsgr://im?to=tekjew
				NSString *name = [[[url queryArgumentForKey:@"to"] stringByDecodingURLEscapes] compactedString];
				
				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
				
			} else if ([host caseInsensitiveCompare:@"gochat"]  == NSOrderedSame) {
				// aim://gochat?RoomName=AdiumRocks
				NSString	*roomname = [[url queryArgumentForKey:@"roomname"] stringByDecodingURLEscapes];
				NSString	*exchangeString = [url queryArgumentForKey:@"exchange"];
				if (roomname) {
					int exchange = 0;
					if (exchangeString) {
						exchange = [exchangeString intValue];	
					}
					
					[self _openAIMGroupChat:roomname onExchange:(exchange ? exchange : 4)];
				}

			} else if ([url queryArgumentForKey:@"openChatToScreenName"]) {
				// aim://openChatToScreenname?tekjew  [?]
				NSString *name = [[[url queryArgumentForKey:@"openChatToScreenname"] stringByDecodingURLEscapes] compactedString];
				
				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
	
			} else if ([url queryArgumentForKey:@"openChatToScreenName"]) {
				// gtalk:chat?jid=foo@gmail.com&from_jid=bar@gmail.com
				NSString *name = [[[url queryArgumentForKey:@"jid"] stringByDecodingURLEscapes] compactedString];

				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
				
			} else if ([host caseInsensitiveCompare:@"BuddyIcon"] == NSOrderedSame) {
				//aim:BuddyIcon?src=http://www.nbc.com//Heroes/images/wallpapers/heroes-downloads-icon-single-48x48-07.gif
				NSString *urlString = [url queryArgumentForKey:@"src"];
				if ([urlString length]) {
					NSURL *urlToDownload = [[NSURL alloc] initWithString:urlString];
					NSData *imageData = (urlToDownload ? [NSData dataWithContentsOfURL:urlToDownload] : nil);
					[urlToDownload release];
					
					//Should prompt for where to apply the icon?
					if (imageData &&
						[[[NSImage alloc] initWithData:imageData] autorelease]) {
						//If we successfully got image data, and that data makes a valid NSImage, set it as our global buddy icon
						[[adium preferenceController] setPreference:imageData
																					  forKey:KEY_USER_ICON
																					   group:GROUP_ACCOUNT_STATUS];
					}
				}
				
			//Jabber additions
			} else if ([query rangeOfString:@"message"].location == 0) {
				//xmpp:johndoe@jabber.org?message;subject=Subject;body=Body
				NSString *msg = [[url queryArgumentForKey:@"body"] stringByDecodingURLEscapes];
				
				[self _openChatToContactWithName:[NSString stringWithFormat:@"%@@%@", [url user], [url host]]
				                       onService:serviceID
				                     withMessage:msg];
			} else if ([query rangeOfString:@"roster"].location == 0
			           || [query rangeOfString:@"subscribe"].location == 0) {
				//xmpp:johndoe@jabber.org?roster;name=John%20Doe;group=Friends
				//xmpp:johndoe@jabber.org?subscribe
				
				//Group specification and name specification is currently ignored,
				//due to limitations in the AINewContactWindowController API.

				AIService *jabberService;

				jabberService = [[adium accountController] firstServiceWithServiceID:@"Jabber"];

				[AINewContactWindowController promptForNewContactOnWindow:nil
				                                                     name:[NSString stringWithFormat:@"%@@%@", [url user], [url host]]
				                                                  service:jabberService
																  account:nil];
			} else if ([query rangeOfString:@"remove"].location == 0
			           || [query rangeOfString:@"unsubscribe"].location == 0) {
				// xmpp:johndoe@jabber.org?remove
				// xmpp:johndoe@jabber.org?unsubscribe
				
			} else {
				if (([query caseInsensitiveCompare:@"join"] == NSOrderedSame) &&
					([scheme caseInsensitiveCompare:@"xmpp"] == NSOrderedSame)) {
					NSString *password = [[url queryArgumentForKey:@"password"] stringByDecodingURLEscapes];
					//TODO: password support: xmpp:darkcave@macbeth.shakespeare.lit?join;password=cauldronburn

					[self _openXMPPGroupChat:[url user]
									onServer:[url host]
								withPassword:password];

					//TODO: 
				} else {
					//Default to opening the host as a name.
					NSString	*user = [url user];
					NSString	*host = [url host];
					NSString	*name;
					if (user && [user length]) {
						//jabber://tekjew@jabber.org
						//msn://jdoe@hotmail.com
						name = [NSString stringWithFormat:@"%@@%@",[url user],[url host]];
					} else {
						//aim://tekjew
						name = host;
					}
					
					[self _openChatToContactWithName:[name compactedString]
										   onService:serviceID
										 withMessage:nil];
				}
			}
			
		} else if ([scheme isEqualToString:@"adiumxtra"]) {
			//Installs an adium extra
			// adiumxtra://www.adiumxtras.com/path/to/xtra.zip

			[[XtrasInstaller installer] installXtraAtURL:url];
		}
	}
}

+ (void)_setHelperAppForScheme:(NSString *)scheme
{
	LSSetDefaultHandlerForURLScheme((CFStringRef)scheme, (CFStringRef)ADIUM_BUNDLE_ID);
}

+ (BOOL)_checkHelperAppForScheme:(NSString *)scheme
{
	BOOL	 adiumIsHelper;
	NSString *handler = (NSString *)LSCopyDefaultHandlerForURLScheme((CFStringRef)scheme);
	adiumIsHelper = ([handler caseInsensitiveCompare:ADIUM_BUNDLE_ID] == NSOrderedSame);
	[handler release];
	
	return adiumIsHelper;
}

+ (void)_openChatToContactWithName:(NSString *)UID onService:(NSString *)serviceID withMessage:(NSString *)message
{
	AIListContact		*contact = [[adium contactController] preferredContactWithUID:UID
														  andServiceID:serviceID 
												 forSendingContentType:CONTENT_MESSAGE_TYPE];
	if (contact) {
		//Open the chat and set it as active
		[[adium interfaceController] setActiveChat:[[adium chatController] openChatWithContact:contact
																						onPreferredAccount:YES]];
		
		//Insert the message text as if the user had typed it after opening the chat
		NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		if (message && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]) {
			[responder insertText:message];
		}

	} else {
		NSBeep();
	}
}

+ (void)_openXMPPGroupChat:(NSString *)name onServer:(NSString *)server withPassword:(NSString *)password
{
	AIAccount		*account;
	NSEnumerator	*enumerator;
	
	//Find an XMPP-compatible online account which can create group chats
	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account online] &&
			[[account serviceClass] isEqualToString:@"Jabber"] &&
			[[account service] canCreateGroupChats]) {
			break;
		}
	}
	
	if (name && account) {
		[[adium chatController] chatWithName:name
														   identifier:nil
															onAccount:account
													 chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																	   name, @"room",
																	   server, @"server",
																	   [account formattedUID], @"handle",
																	   password, @"password", /* may be nil, so should be last */
																	   nil]];
	} else {
		NSBeep();
	}
}

+ (void)_openAIMGroupChat:(NSString *)roomname onExchange:(int)exchange
{
	AIAccount		*account;
	NSEnumerator	*enumerator;
	
	//Find an AIM-compatible online account which can create group chats
	enumerator = [[[adium accountController] accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if ([account online] &&
			[[account serviceClass] isEqualToString:@"AIM-compatible"] &&
			[[account service] canCreateGroupChats]) {
			break;
		}
	}
	
	if (roomname && account) {
		[[adium chatController] chatWithName:roomname
														   identifier:nil
															onAccount:account
													 chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																		roomname, @"room",
																		[NSNumber numberWithInt:exchange], @"exchange",
																		nil]];
	} else {
		NSBeep();
	}
}

- (void)URLQuestion:(NSNumber *)number info:(id)info
{
	AITextAndButtonsReturnCode ret = [number intValue];
	switch(ret)
	{
		case AITextAndButtonsOtherReturn:
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES] forKey:KEY_DONT_PROMPT_FOR_URL group:GROUP_URL_HANDLING];
			break;
		case AITextAndButtonsDefaultReturn:
			[AdiumURLHandling registerAsDefaultIMClient];
			break;
		case AITextAndButtonsAlternateReturn:
		default:
			break;
	}
}

- (void)promptUser
{
	if ([[[adium preferenceController] preferenceForKey:KEY_COMPLETED_FIRST_LAUNCH group:GROUP_URL_HANDLING] boolValue]) {
		if(![[adium preferenceController] preferenceForKey:KEY_DONT_PROMPT_FOR_URL group:GROUP_URL_HANDLING])
			[[adium interfaceController] displayQuestion:AILocalizedString(@"Change default messaging client?", nil)
										 withDescription:AILocalizedString(@"Adium is not your default Instant Messaging client. The default client is loaded when you click messaging URLs in web pages. Would you like Adium to become the default?", nil)
										 withWindowTitle:nil
										   defaultButton:AILocalizedString(@"Yes", nil)
										 alternateButton:AILocalizedString(@"No", nil)
											 otherButton:AILocalizedString(@"Never", nil)
												  target:self
												selector:@selector(URLQuestion:info:)
												userInfo:nil];
	} else {
		//On the first launch, simply register. If the user uses another IM client which takes control of the protocols again, we'll prompt for what to do.
		[AdiumURLHandling registerAsDefaultIMClient];
		
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
											 forKey:KEY_COMPLETED_FIRST_LAUNCH
											  group:GROUP_URL_HANDLING];
	}
}

@end
