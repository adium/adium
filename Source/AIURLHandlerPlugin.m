//
//  AIURLHandlerPlugin.m
//  Adium
//
//  Created by Zachary West on 2009-04-03.
//

#import "AIURLHandlerPlugin.h"
#import "AIURLHandlerAdvancedPreferences.h"

#import "AINewContactWindowController.h"
#import "XtrasInstaller.h"

#import <AIUtilities/AIURLAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIService.h>
#import <Adium/AIAccount.h>

@interface AIURLHandlerPlugin()
- (void)checkHandledSchemes;

- (void)handleURL:(NSNotification *)notification;

- (void)_openChatToContactWithName:(NSString *)name onService:(NSString *)serviceIdentifier withMessage:(NSString *)body;
- (void)_openAIMGroupChat:(NSString *)roomname onExchange:(NSInteger)exchange;
- (void)_openXMPPGroupChat:(NSString *)name onServer:(NSString *)server withPassword:(NSString *)inPassword;
- (void)_openIRCGroupChat:(NSString *)name onServer:(NSString *)server withPassword:(NSString *)password;
@end

/*!
 * @class AIURLHandlerPlugin
 *
 * The URL handler plugin handles URL events sent to us.
 *
 * For example, it will convert aim://goim?sn=fuark to open a chat window with
 * the user "fuark" on the first available AIM account.
 *
 * This plugin is also responsible for managing the default application settings
 * for the schemes we support, and enforcing if necessary our ownership.
 */
@implementation AIURLHandlerPlugin
/*!
 * @brief Install plugin
 *
 * This sets up our advanced preferences view and checks our defaults.
 */
- (void)installPlugin
{
	preferences = [[AIURLHandlerAdvancedPreferences preferencePaneForPlugin:self] retain];
	
	[self checkHandledSchemes];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleURL:)
												 name:AIURLHandleNotification
											   object:nil];
}

/*!
 * @brief Unisntall
 */
- (void)uninstallPlugin
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[preferences release];
}

#pragma mark Scheme enforcement
/*!
 * @brief Set Adium as the default for all handled schemes
 *
 * For all service schemes (and their aliases), set ourself as their default bundle ID.
 */
- (void)setAdiumAsDefault
{
	for (NSString *scheme in self.uniqueSchemes) {
		[self setDefaultForScheme:scheme toBundleID:ADIUM_BUNDLE_ID];
	}	
}

/*!
 * @brief Check our handled schemes
 *
 * If this is the first launch, or the user has "enforce Adium as default" set, set ourself
 * as the default for all available service schemes.
 *
 * Always set ourself as the default for our helper schemes (such as adiumxtra).
 */
- (void)checkHandledSchemes
{
	if ((![[adium.preferenceController preferenceForKey:PREF_KEY_SET_DEFAULT_FIRST_TIME
												  group:GROUP_URL_HANDLING] boolValue]) ||
		([[adium.preferenceController preferenceForKey:PREF_KEY_ENFORCE_DEFAULT
												 group:GROUP_URL_HANDLING] boolValue])) {
		// Either this is our first launch, or we're set to enforce our defaults.
		// Set ourself as the default for everything.
		
		[self setAdiumAsDefault];
	}
	
	for (NSString *scheme in self.helperSchemes) {
		[self setDefaultForScheme:scheme toBundleID:ADIUM_BUNDLE_ID];
	}
}

#pragma mark Schemes
/*!
 * @brief Get a service ID from a scheme
 *
 * Asking for the service ID of an unknown scheme will return nil.
 *
 * @param scheme One of our supported schemes
 * @returns The serviceID for the service which uses the scheme given
 */
- (NSString *)serviceIDForScheme:(NSString *)scheme
{
	static NSDictionary	*schemeToServiceDict = nil;
	if (!schemeToServiceDict) {
		schemeToServiceDict = [[NSDictionary alloc] initWithObjectsAndKeys:
							   @"AIM",    @"aim",
							   @"Yahoo!", @"ymsgr",
							   @"Yahoo!", @"yahoo",
							   @"Jabber", @"xmpp",
							   @"Jabber", @"jabber",
							   @"GTalk",  @"gtalk",
							   @"MSN",    @"msn",
							   @"IRC",	   @"irc",
							   nil];
	}
	
	return [schemeToServiceDict objectForKey:scheme];
}

/*!
 * @brief All of the schemes similar to a given scheme
 *
 * Several services (such as Yahoo and Jabber) have several scheme
 * aliases which are possible schemes for them. Instead of having multiple
 * entries each, we simply use a reference one and apply to all aliases.
 *
 * @param scheme A reference scheme (see -uniqueSchemes)
 * @returns An NSArray of all schemes similar to the given one.
 */
- (NSArray *)allSchemesLikeScheme:(NSString *)scheme
{
	if ([scheme isEqualToString:@"ymsgr"]) {
		return [NSArray arrayWithObjects:@"yahoo", @"ymsgr", nil];
	} else if ([scheme isEqualToString:@"xmpp"]) {
		return [NSArray arrayWithObjects:@"xmpp", @"jabber", @"gtalk", nil];
	} else {
		return [NSArray arrayWithObject:scheme];
	}
}

/*!
 * @brief Unique schemes we support
 *
 * @returns An NSArray of all of the schemes we support.
 */
- (NSArray *)uniqueSchemes
{
	return [NSArray arrayWithObjects:@"aim", @"irc", @"xmpp", @"msn", @"ymsgr", nil];
}

/*!
 * @brief Helper schemes
 *
 * Helper schemes are schemes which we should always be registered as the default application
 * for. This includes things like the adiumxtra:// installer, and twitterreply:// for the Twitter
 * service.
 *
 * @returns An NSArray of all of the helper schemes we support.
 */
- (NSArray *)helperSchemes
{
	return [NSArray arrayWithObjects:@"twitterreply", @"adiumxtra", nil];
}

#pragma mark Default Bundle
/*!
 * @brief Set an application as the default for a scheme
 *
 * @param inScheme The scheme to set the default for
 * @param bundleID The bundle ID of an application to set as the default for the given scheme
 */
- (void)setDefaultForScheme:(NSString *)inScheme toBundleID:(NSString *)bundleID
{
	for (NSString *scheme in [self allSchemesLikeScheme:inScheme]) {
		LSSetDefaultHandlerForURLScheme((CFStringRef)scheme, (CFStringRef)bundleID);
	}
}

/*!
 * @brief Default application bundle ID for a scheme
 *
 * @param scheme The scheme to determine the default application for
 * @returns An NSString bundle ID for the default application of a scheme
 */
- (NSString *)defaultApplicationBundleIDForScheme:(NSString *)scheme
{
	return ((NSString *)LSCopyDefaultHandlerForURLScheme((CFStringRef)scheme)).lowercaseString;
}

#pragma mark URL Handling
/*!
 * @brief Handle a URL notification
 *
 * @param notification An NSNotification whose -object is the NSString of a URL.
 */
- (void)handleURL:(NSNotification *)notification
{
	NSString *urlString = notification.object;
	NSURL *url = [NSURL URLWithString:urlString];
	
	if (!url)
		return;
	
	NSString	*scheme, *newScheme;
	NSString	*serviceID;
	
	//make sure we have the // in ://, as it simplifies later processing.
	if (![[url resourceSpecifier] hasPrefix:@"//"]) {
		urlString = [NSString stringWithFormat:@"%@://%@", [url scheme], [url resourceSpecifier]];
		url = [NSURL URLWithString:urlString];
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
		urlString = [NSString stringWithFormat:@"%@:%@", scheme, [url resourceSpecifier]];
		url = [NSURL URLWithString:urlString];
	}

	if ((serviceID = [self serviceIDForScheme:scheme])) {
		NSString *host = [url host];
		NSString *query = [url query];
		
		if ([scheme isEqualToString:@"aim"]) {
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
				AIService	*service = [adium.accountController firstServiceWithServiceID:serviceID];
				
				if (name) {
					[adium.contactController requestAddContactWithUID:name
					 service:service
					 account:nil];
					
				} else {
					NSString		*listOfNames = [url queryArgumentForKey:@"listofscreennames"];
					NSArray			*names = [listOfNames componentsSeparatedByString:@","];
					
					for (name in names) {
						NSString	*decodedName = [[name stringByDecodingURLEscapes] compactedString];
						[adium.contactController requestAddContactWithUID:decodedName
						 service:service
						 account:nil];
					}
				}
			} else if ([host caseInsensitiveCompare:@"gochat"]  == NSOrderedSame) {
				// aim://gochat?RoomName=AdiumRocks
				NSString	*roomname = [[url queryArgumentForKey:@"roomname"] stringByDecodingURLEscapes];
				NSString	*exchangeString = [url queryArgumentForKey:@"exchange"];
				if (roomname) {
					NSInteger exchange = 0;
					if (exchangeString) {
						exchange = [exchangeString integerValue];	
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
						[adium.preferenceController setPreference:imageData
						 forKey:KEY_USER_ICON
						 group:GROUP_ACCOUNT_STATUS];
					}
				}
			}
		} else if ([scheme isEqualToString:@"ymsgr"]) {
			if ([host caseInsensitiveCompare:@"sendim"] == NSOrderedSame) {
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
			}
		} else if ([scheme isEqualToString:@"gtalk"]) {
			if ([url queryArgumentForKey:@"openChatToScreenName"]) {
				// gtalk:chat?jid=foo@gmail.com&from_jid=bar@gmail.com
				NSString *name = [[[url queryArgumentForKey:@"jid"] stringByDecodingURLEscapes] compactedString];
				
				if (name) {
					[self _openChatToContactWithName:name
										   onService:serviceID
										 withMessage:nil];
				}
			}
		} else if ([scheme isEqualToString:@"xmpp"]) {
			if ([query rangeOfString:@"message"].location == 0) {
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
				
				jabberService = [adium.accountController firstServiceWithServiceID:@"Jabber"];
				
				[AINewContactWindowController promptForNewContactOnWindow:nil
																	 name:[NSString stringWithFormat:@"%@@%@", [url user], [url host]]
																  service:jabberService
																  account:nil];
			} else if ([query rangeOfString:@"remove"].location == 0
					   || [query rangeOfString:@"unsubscribe"].location == 0) {
				// xmpp:johndoe@jabber.org?remove
				// xmpp:johndoe@jabber.org?unsubscribe
				
			} else if (([query caseInsensitiveCompare:@"join"] == NSOrderedSame) &&
					   ([scheme caseInsensitiveCompare:@"xmpp"] == NSOrderedSame)) {
				NSString *password = [[url queryArgumentForKey:@"password"] stringByDecodingURLEscapes];
				//TODO: password support: xmpp:darkcave@macbeth.shakespeare.lit?join;password=cauldronburn
				
				[self _openXMPPGroupChat:[url user]
								onServer:[url host]
							withPassword:password];
				
				//TODO: 
			}
		} else if ([scheme caseInsensitiveCompare:@"irc"] == NSOrderedSame) {
			// irc://server/channel?password
			NSString *channelName = [url fragment];
			
			if (!channelName.length && [url.path.lastPathComponent isEqualToString:@"/"]) {
				channelName = @"#";
			} else if (!channelName.length) {
				channelName = url.path.lastPathComponent;
			} else {
				channelName = [@"#" stringByAppendingString:channelName];
			}
			
			channelName = [channelName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			[self _openIRCGroupChat:channelName onServer:[url host] withPassword:[url query]];
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
		
	} else if ([scheme isEqualToString:@"adiumxtra"]) {
		//Installs an adium extra
		// adiumxtra://www.adiumxtras.com/path/to/xtra.zip
		
		[[XtrasInstaller installer] installXtraAtURL:url];
	} else if ([scheme isEqualToString:@"twitterreply"]) {
		// We want to reply to a specific status update.
		// Broadcast the notification.
		
		// If you're modifying this, also modify the post in AIWebKitDelegate.m
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AITwitterReplyLinkClicked" object:url];
	}
}

#pragma mark Chat openers

- (void)_openChatToContactWithName:(NSString *)UID onService:(NSString *)serviceID withMessage:(NSString *)message
{
	AIListContact		*contact = [adium.contactController preferredContactWithUID:UID
									andServiceID:serviceID 
									forSendingContentType:CONTENT_MESSAGE_TYPE];
	if (contact) {
		//Open the chat and set it as active
		[adium.interfaceController setActiveChat:[adium.chatController openChatWithContact:contact
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

- (void)_openIRCGroupChat:(NSString *)name onServer:(NSString *)server withPassword:(NSString *)password
{
	AIAccount *ircAccount = nil;
	
	for (AIAccount *account in adium.accountController.accounts) {
		if ([account.service.serviceClass isEqualToString:@"IRC"] && [account.host isEqualToString:server]) {
			ircAccount = account;
			break;
		}
	}
	
	if (!ircAccount) {
		NSRunAlertPanel(AILocalizedString(@"Unable to Join Channel", nil),
						AILocalizedString(@"Unable to join the channel %@, no account exists for server %@.", nil),
						AILocalizedStringFromTable(@"OK", @"Buttons", "Verb 'OK' on a button"),
						nil,
						nil,
						name,
						server);
	} else if (name) {
		[adium.chatController chatWithName:name
		 identifier:nil
		 onAccount:ircAccount
		 chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
						   name, @"channel",
						   password, @"password", /* may be nil, so should be last */
						   nil]];
	} else {
		NSBeep();
	}
}

- (void)_openXMPPGroupChat:(NSString *)name onServer:(NSString *)server withPassword:(NSString *)password
{
	AIAccount		*account;
	NSEnumerator	*enumerator;
	
	//Find an XMPP-compatible online account which can create group chats
	enumerator = [[adium.accountController accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if (account.online &&
			[account.service.serviceClass isEqualToString:@"Jabber"] &&
			[account.service canCreateGroupChats]) {
			break;
		}
	}
	
	if (name && account) {
		[adium.chatController chatWithName:name
		 identifier:nil
		 onAccount:account
		 chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
						   name, @"room",
						   server, @"server",
						   account.formattedUID, @"handle",
						   password, @"password", /* may be nil, so should be last */
						   nil]];
	} else {
		NSBeep();
	}
}

- (void)_openAIMGroupChat:(NSString *)roomname onExchange:(NSInteger)exchange
{
	AIAccount		*account;
	NSEnumerator	*enumerator;
	
	//Find an AIM-compatible online account which can create group chats
	enumerator = [[adium.accountController accounts] objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if (account.online &&
			[account.service.serviceClass isEqualToString:@"AIM-compatible"] &&
			[account.service canCreateGroupChats]) {
			break;
		}
	}
	
	if (roomname && account) {
		[adium.chatController chatWithName:roomname
		 identifier:nil
		 onAccount:account
		 chatCreationInfo:[NSDictionary dictionaryWithObjectsAndKeys:
						   roomname, @"room",
						   [NSNumber numberWithInteger:exchange], @"exchange",
						   nil]];
	} else {
		NSBeep();
	}
}

@end
