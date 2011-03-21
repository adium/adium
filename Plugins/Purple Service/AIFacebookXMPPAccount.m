//
//  AIFacebookXMPPAccount.m
//  Adium
//
//  Created by Colin Barrett on 11/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AIFacebookXMPPAccount.h"
#import <Adium/AIStatus.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIListContact.h>
#import "adiumPurpleCore.h"
#import <libpurple/jabber.h>
#import "ESPurpleJabberAccount.h"
#import "auth_fb.h"
#import "auth.h"

#import "AIFacebookXMPPOAuthWebViewWindowController.h"
#import "JSONKit.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIPasswordPromptController.h>
#import <Adium/AILoginControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>
#import <Adium/AIService.h>

enum {
    AINoNetworkState,
    AIMeGraphAPINetworkState,
    AIPromoteSessionNetworkState
};

@interface AIFacebookXMPPAccount ()
- (void)finishMigration;

@property (nonatomic, copy) NSString *oAuthToken;
@property (nonatomic, assign) NSUInteger networkState;
@property (nonatomic, assign) NSURLConnection *connection; // assign because NSURLConnection retains its delegate.
@property (nonatomic, retain) NSURLResponse *connectionResponse;
@property (nonatomic, retain) NSMutableData *connectionData;

- (void)meGraphAPIDidFinishLoading:(NSData *)graphAPIData response:(NSURLResponse *)response error:(NSError *)inError;
- (void)promoteSessionDidFinishLoading:(NSData *)secretData response:(NSURLResponse *)response error:(NSError *)inError;
@end

@implementation AIFacebookXMPPAccount

@synthesize oAuthWC;
@synthesize migratingAccount;
@synthesize oAuthToken;
@synthesize networkState, connection, connectionResponse, connectionData;

- (void)dealloc
{
    [oAuthWC release];
    [oAuthToken release];
    
    [connection cancel];
    [connectionResponse release];
    [connectionData release];

    [super dealloc];
}

#pragma mark Connectivitiy

- (const char*)protocolPlugin
{
	return "prpl-jabber";
}

- (NSString *)serverSuffix
{
	return @"@chat.facebook.com";
}

/* Specify a host for network-reachability-code purposes */
- (NSString *)host
{
	return @"chat.facebook.com";
}

- (void)configurePurpleAccount
{
	[super configurePurpleAccount];

	purple_account_set_username(account, self.purpleAccountName);
	purple_account_set_string(account, "connection_security", "");
    purple_account_set_string(account, "fb_api_key", "819fd0b010d15eac1b36648f0126ece3");
    purple_account_set_string(account, "fb_api_secret", [[self preferenceForKey:@"FBSessionSecret" group:GROUP_ACCOUNT_STATUS] UTF8String]);
}

- (const char *)purpleAccountName
{
	NSString	*userNameWithHost = nil, *completeUserName = nil;
	BOOL		serverAppendedToUID;
	
	serverAppendedToUID = ([UID rangeOfString:@"@"].location != NSNotFound);
	
	if (serverAppendedToUID) {
		userNameWithHost = UID;
	} else {
		userNameWithHost = [UID stringByAppendingString:[self serverSuffix]];
	}
	
	completeUserName = [NSString stringWithFormat:@"-%@/Adium" ,userNameWithHost];
	
	return [completeUserName UTF8String];
}

- (BOOL)encrypted
{
	return NO;
}

- (BOOL)allowAccountUnregistrationIfSupportedByLibpurple
{
	return NO;
}

/*!
 * @brief Password entered callback
 *
 * Callback after the user enters her password for connecting; finish the connect process.
 */
- (void)passwordReturnedForConnect:(NSString *)inPassword returnCode:(AIPasswordPromptReturn)returnCode context:(id)inContext
{
    if ((returnCode == AIPasswordPromptOKReturn) && (inPassword.length == 0)) {
		/* No password retrieved from the keychain */
		[self requestFacebookAuthorization];

	} else {
		[super passwordReturnedForConnect:inPassword returnCode:returnCode context:inContext];
	}
}

- (void)retrievePasswordThenConnect
{
	if ([self boolValueForProperty:@"Prompt For Password On Next Connect"]) 
		/* We attempted to connect, but we had incorrect authorization. Display our auth request window. */
		[self requestFacebookAuthorization];

	else {
		/* Retrieve the user's password. Never prompt for a password, as we'll implement our own authorization handling
		 * if the password can't be retrieved.
		 */
		[adium.accountController passwordForAccount:self 
									   promptOption:AIPromptNever
									notifyingTarget:self
										   selector:@selector(passwordReturnedForConnect:returnCode:context:)
											context:nil];	
	}
}

#pragma mark Status

- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
							  arguments:(NSMutableDictionary *)arguments
{
	const char		*statusID = NULL;
	NSString		*statusName = statusState.statusName;
	NSString		*statusMessageString = [statusState statusMessageString];
	NSNumber		*priority = nil;
	
	if (!statusMessageString) statusMessageString = @"";
	
	switch (statusState.statusType) {
		case AIAvailableStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_FREE_FOR_CHAT]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_FREE_FOR_CHAT]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_CHAT);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AVAILABLE group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIAwayStatusType:
		{
			if (([statusName isEqualToString:STATUS_NAME_DND]) ||
				([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]] == NSOrderedSame) ||
				[statusName isEqualToString:STATUS_NAME_BUSY]) {
				//Note that Jabber doesn't actually support a 'busy' status; if we have it set because some other service supports it, treat it as DND
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_DND);
				
			} else if (([statusName isEqualToString:STATUS_NAME_EXTENDED_AWAY]) ||
					   ([statusMessageString caseInsensitiveCompare:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]] == NSOrderedSame))
				statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_XA);
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			break;
		}
			
		case AIInvisibleStatusType:
			AILog(@"Warning: Invisibility is not yet supported in libpurple 2.0.0 jabber");
			priority = [self preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
			statusID = jabber_buddy_state_get_status_id(JABBER_BUDDY_STATE_AWAY);
			break;
			
		case AIOfflineStatusType:
			break;
	}
	
	//Set our priority, which is actually set along with the status...Default is 0.
	[arguments setObject:(priority ? priority : [NSNumber numberWithInt:0])
				  forKey:@"priority"];
	
	//If we didn't get a purple status ID, request one from super
	if (statusID == NULL) statusID = [super purpleStatusIDForStatus:statusState arguments:arguments];
	
	return statusID;
}

#pragma mark Account configuration

- (void)setName:(NSString *)name UID:(NSString *)inUID
{
	[self filterAndSetUID:inUID];
	
	[self setFormattedUID:name notify:NotifyNever];
}

#pragma mark Contacts

/*!
 * @brief Set an alias for a contact
 *
 * Normally, we consider the name a 'serverside alias' unless it matches the UID's characters
 * However, the UID in facebook should never be presented to the user if possible; it's for internal use
 * only.  We'll therefore consider any alias a formatted UID such that it will replace the UID when displayed
 * in Adium.
 */
- (void)updateContact:(AIListContact *)theContact toAlias:(NSString *)purpleAlias
{
	if (![purpleAlias isEqualToString:theContact.formattedUID] && 
		![purpleAlias isEqualToString:theContact.UID]) {
		[theContact setFormattedUID:purpleAlias
							 notify:NotifyLater];
		
		//Apply any changes
		[theContact notifyOfChangedPropertiesSilently:silentAndDelayed];
	}
}

- (NSMutableArray *)arrayOfDictionariesFromPurpleNotifyUserInfo:(PurpleNotifyUserInfo *)user_info forContact:(AIListContact *)contact
{
	NSMutableArray *array = [super arrayOfDictionariesFromPurpleNotifyUserInfo:user_info forContact:contact];
	
	NSString *displayUID = contact.UID;
	displayUID = [displayUID stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
	if ([displayUID hasSuffix:@"@chat.facebook.com"])
		displayUID = [displayUID substringToIndex:displayUID.length - @"@chat.facebook.com".length];

	[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					  AILocalizedString(@"Facebook ID", nil), KEY_KEY,
					  displayUID, KEY_VALUE,
					  nil]];

	return array;
}

#pragma mark Authorization

- (void)requestFacebookAuthorization
{
	self.oAuthWC = [[[AIFacebookXMPPOAuthWebViewWindowController alloc] init] autorelease];
	self.oAuthWC.account = self;
	
	if (self.migratingAccount) {
		self.oAuthWC.autoFillUsername = self.migratingAccount.UID;
		self.oAuthWC.autoFillPassword = [adium.accountController passwordForAccount:self.migratingAccount];
	}

	[self.oAuthWC showWindow:self];
}

- (void)oAuthWebViewController:(AIFacebookXMPPOAuthWebViewWindowController *)wc didSucceedWithToken:(NSString *)token
{
    [self setOAuthToken:token];
    
    NSString *urlstring = [NSString stringWithFormat:@"https://graph.facebook.com/me?access_token=%@", [self oAuthToken]];
    NSURL *url = [NSURL URLWithString:[urlstring stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    self.networkState = AIMeGraphAPINetworkState;
    self.connectionData = [NSMutableData data];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)meGraphAPIDidFinishLoading:(NSData *)graphAPIData response:(NSURLResponse *)inResponse error:(NSError *)inError
{
    if (inError) {
        NSLog(@"error loading graph API: %@", inError);
        // TODO: indicate setup failed 
        return;
    }
    
    NSError *error = nil;
    NSDictionary *resp = [graphAPIData objectFromJSONDataWithParseOptions:JKParseOptionNone error:&error];
    if (!resp) {
        NSLog(@"error decoding graph API response: %@", error);
        // TODO: indicate setup failed
        return;
    }
    
    NSString *uuid = [resp objectForKey:@"id"];
    NSString *name = [resp objectForKey:@"name"];
    
    /* Passwords are keyed by UID, so we need to make this change before storing the password */
	[self setName:name UID:uuid];
        
    NSString *secretURLString = [NSString stringWithFormat:@"https://api.facebook.com/method/auth.promoteSession?access_token=%@&format=JSON", [self oAuthToken]];
    NSURL *secretURL = [NSURL URLWithString:[secretURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *secretRequest = [NSURLRequest requestWithURL:secretURL];

    self.networkState = AIPromoteSessionNetworkState;
    self.connectionData = [NSMutableData data];
    self.connection = [NSURLConnection connectionWithRequest:secretRequest delegate:self];
}

- (void)promoteSessionDidFinishLoading:(NSData *)secretData response:(NSURLResponse *)response error:(NSError *)inError
{
    if (inError) {
        NSLog(@"error promoting session: %@", inError);
        // TODO: indicate setup failed
        return;
    }    
    
    NSString *secret = [[[NSString alloc] initWithData:secretData encoding:NSUTF8StringEncoding] autorelease];
    secret = [secret substringWithRange:NSMakeRange(1, [secret length] - 2)]; // strip off the quotes    
    NSString *sessionKey = [[[self oAuthToken] componentsSeparatedByString:@"|"] objectAtIndex:1];
   	
	[[adium accountController] setPassword:sessionKey forAccount:self];
	[self setPasswordTemporarily:sessionKey];
	
	[self setPreference:secret
				 forKey:@"FBSessionSecret"
				  group:GROUP_ACCOUNT_STATUS];
    
	self.oAuthWC = nil;
    self.oAuthToken = nil;
    
	/* When we're newly authorized, connect! */
	[self connect];
	
	if (self.migratingAccount) {
		[self finishMigration];        
    }
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)inConnection didReceiveResponse:(NSURLResponse *)response
{
    [[self connectionData] setLength:0];
    [self setConnectionResponse:response];
}

- (void)connection:(NSURLConnection *)inConnection didReceiveData:(NSData *)data
{
    [[self connectionData] appendData:data];
}

- (void)connection:(NSURLConnection *)inConnection didFailWithError:(NSError *)error
{
    NSUInteger state = [self networkState];
    
    [self setNetworkState:AINoNetworkState];
    [self setConnection:nil];
    [self setConnectionResponse:nil];
    [self setConnectionData:nil];    
    
    if (state == AIMeGraphAPINetworkState) {
        [self meGraphAPIDidFinishLoading:nil response:nil error:error];
    } else if (state == AIPromoteSessionNetworkState) {
        [self promoteSessionDidFinishLoading:nil response:nil error:error];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)inConnection
{
    NSURLResponse *response = [[[self connectionResponse] retain] autorelease];
    NSMutableData *data = [[[self connectionData] retain] autorelease];
    NSUInteger state = [self networkState]; 
    
    [self setNetworkState:AINoNetworkState];
    [self setConnection:nil];
    [self setConnectionResponse:nil];
    [self setConnectionData:nil];
    
    if (state == AIMeGraphAPINetworkState) {
        [self meGraphAPIDidFinishLoading:data response:response error:nil];
    } else if (state == AIPromoteSessionNetworkState) {
        [self promoteSessionDidFinishLoading:data response:response error:nil];
    }    
}

#pragma mark Migration
/*
 * Move logs from the old account's to the new account's log folder, changing the name along the way.
 * Finally delete the old account.
 */
- (void)finishMigration
{
	if (!self.migratingAccount)
		return;

	//Move logs to the new account
	NSString *logsDir = [[adium.loginController userDirectory] stringByAppendingPathComponent:@"/Logs"];
	
	NSString *oldFolder = [NSString stringWithFormat:@"%@.%@", self.migratingAccount.service.serviceID, [self.migratingAccount.UID safeFilenameString]];
	NSString *newFolder = [NSString stringWithFormat:@"%@.%@", self.service.serviceID, [self.UID safeFilenameString]];
	NSString *basePath = [[logsDir stringByAppendingPathComponent:oldFolder] stringByExpandingTildeInPath];
	NSString *newPath = [[logsDir stringByAppendingPathComponent:newFolder] stringByExpandingTildeInPath];
	
	NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
	NSInteger errors = 0;
	
	for (NSString *file in [fileManager enumeratorAtPath:basePath]) {
		if ([[file pathExtension] isEqualToString:@"xml"]) {
			/* turn 'XXXXXXX69 (2009-01-20T19.10.07-0500).xml'
			 * into '-XXXXXXX69@chat.facebook.com (2009-01-20T19.10.07-0500).xml'
			 */
			NSRange UIDrange = [[file lastPathComponent] rangeOfString:@" "];
			if (UIDrange.location > 0) {
				NSString *uid = [[file lastPathComponent] substringToIndex:UIDrange.location];
				NSString *newName = [file stringByReplacingOccurrencesOfString:uid
																	withString:[NSString stringWithFormat:@"-%@@%@", uid, self.host]];
				
				[fileManager createDirectoryAtPath:[newPath stringByAppendingPathComponent:[newName stringByDeletingLastPathComponent]]
					   withIntermediateDirectories:YES
										attributes:nil
											 error:NULL];
				if (![fileManager moveItemAtPath:[basePath stringByAppendingPathComponent:file]
										  toPath:[newPath stringByAppendingPathComponent:newName]
										   error:NULL])
					errors++;
			}
		}
	}
	
	if (!errors)
		[fileManager removeItemAtPath:basePath error:NULL];
	
	//Delete old account
	[adium.accountController deleteAccount:self.migratingAccount];
	self.migratingAccount = nil;
}

@end
