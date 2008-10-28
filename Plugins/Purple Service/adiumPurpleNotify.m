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
#import "adiumPurpleNotify.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <AIUtilities/AIObjectAdditions.h>
#import "AMPurpleSearchResultsController.h"

static void *adiumPurpleNotifyMessage(PurpleNotifyMsgType type, const char *title, const char *primary, const char *secondary)
{
	AILog(@"adiumPurpleNotifyMessage: type: %i\n%s\n%s\n%s ",
			   type,
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""));

	return ([[SLPurpleCocoaAdapter sharedInstance] handleNotifyMessageOfType:type
																 withTitle:title
																   primary:primary
																 secondary:secondary]);
}

static void *adiumPurpleNotifyEmails(PurpleConnection *gc, size_t count, gboolean detailed, const char **subjects, const char **froms, const char **tos, const char **urls)
{
    //Values passed can be null
	AIAccount	*account = (PURPLE_CONNECTION_IS_VALID(gc) ?
							accountLookup(purple_connection_get_account(gc)) :
							nil);

    return [ESPurpleNotifyEmailController handleNotifyEmailsForAccount:account
															   count:count 
															detailed:detailed
															subjects:subjects
															   froms:froms
																 tos:tos
																urls:urls];
}

static void *adiumPurpleNotifyEmail(PurpleConnection *gc, const char *subject, const char *from, const char *to, const char *url)
{
	return adiumPurpleNotifyEmails(gc,
								 1,
								 TRUE,
								 (subject ? &subject : NULL),
								 (from ? &from : NULL),
								 (to ? &to : NULL),
								 (url ? &url : NULL));
}

static void *adiumPurpleNotifyFormatted(const char *title, const char *primary, const char *secondary, const char *text)
{
	AILog(@"adiumPurpleNotifyFormatted: %s\n%s\n%s\n%s ",
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""),
			   (text ? text : ""));

	return ([[SLPurpleCocoaAdapter sharedInstance] handleNotifyFormattedWithTitle:title
																		primary:primary
																	  secondary:secondary
																		   text:text]);	
}

static void *adiumPurpleNotifySearchResults(PurpleConnection *gc, const char *title,
										  const char *primary, const char *secondary,
										  PurpleNotifySearchResults *results, gpointer user_data)
{
	AILog(@"**** returning search results");
	//This will be released in adiumPurpleNotifyClose()
	return [[AMPurpleSearchResultsController alloc] initWithPurpleConnection:gc
																	   title:(title ? [NSString stringWithUTF8String:title] : nil)
																 primaryText:(primary ? [NSString stringWithUTF8String:primary] : nil)
															   secondaryText:(secondary ? [NSString stringWithUTF8String:secondary] : nil)
															   searchResults:results
																	userData:user_data];
}

static void adiumPurpleNotifySearchResultsNewRows(PurpleConnection *gc,
												 PurpleNotifySearchResults *results,
												 void *data)
{
	if([(id)data isKindOfClass:[AMPurpleSearchResultsController class]]) {
		[(AMPurpleSearchResultsController*)data addResults:results];
	}
}

static void *adiumPurpleNotifyUserinfo(PurpleConnection *gc, const char *who,
									 PurpleNotifyUserInfo *user_info)
{	
	if (PURPLE_CONNECTION_IS_VALID(gc)) {
		PurpleAccount		*account = purple_connection_get_account(gc);
		PurpleBuddy		*buddy = purple_find_buddy(account, who);
		CBPurpleAccount	*adiumAccount = accountLookup(account);
		AIListContact	*contact;

		contact = contactLookupFromBuddy(buddy);
		if (!contact) {
			NSString *UID = [NSString stringWithUTF8String:purple_normalize(account, who)];

			contact = [accountLookup(account) contactWithUID:UID];
		}

		[adiumAccount updateUserInfo:contact
							withData:user_info];
	}
	
    return NULL;
}

static void *adiumPurpleNotifyUri(const char *uri)
{
	AILogWithSignature(@"Opening URI %s",uri);

	if (uri) {
		NSString *passedURI = [NSString stringWithUTF8String:uri];

		if ([passedURI hasPrefix:[NSString stringWithUTF8String:g_get_tmp_dir()]] ||
			[passedURI hasPrefix:NSTemporaryDirectory()]) {
			NSString *actualURI = passedURI;

			if (![[passedURI pathExtension] length]) {
				actualURI = [passedURI stringByAppendingPathExtension:@"htm"];
				[[NSFileManager defaultManager] copyItemAtPath:passedURI
												  toPath:actualURI
												 error:NULL];
			}
		
			FSRef appRef;
			
			//Open the HTML file with a web browser, not with an HTML editor
			if (LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://google.com"],
									   kLSRolesViewer,
									   &appRef,
									   NULL) != kLSApplicationNotFoundErr) {
				FSRef urlRef;

				if (FSPathMakeRef((UInt8 *)[actualURI fileSystemRepresentation], &urlRef, NULL) == noErr) {
					LSLaunchFSRefSpec spec;
					
					spec.appRef = &appRef;
					spec.numDocs = 1;
					spec.itemRefs = &urlRef;
					spec.passThruParams = NULL;
					spec.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchAsync;
					spec.asyncRefCon = NULL;
					
					LSOpenFromRefSpec(&spec, NULL);				
				}
			}
		} else {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:passedURI]];
		}
	}
	
    return NULL;
}

static void adiumPurpleNotifyClose(PurpleNotifyType type,void *uiHandle)
{
	id ourHandle = uiHandle;
	AILogWithSignature(@"Closing %p (%i)",ourHandle,type);

	if ([ourHandle respondsToSelector:@selector(purpleRequestClose)]) {
		[ourHandle performSelector:@selector(purpleRequestClose)];
		[ourHandle release];
	} else if ([ourHandle respondsToSelector:@selector(closeWindow:)]) {
		[ourHandle performSelector:@selector(closeWindow:)
						withObject:nil];
	}
}

static PurpleNotifyUiOps adiumPurpleNotifyOps = {
    adiumPurpleNotifyMessage,
    adiumPurpleNotifyEmail,
    adiumPurpleNotifyEmails,
    adiumPurpleNotifyFormatted,
	adiumPurpleNotifySearchResults,
	adiumPurpleNotifySearchResultsNewRows,
	adiumPurpleNotifyUserinfo,
    adiumPurpleNotifyUri,
    adiumPurpleNotifyClose
};

PurpleNotifyUiOps *adium_purple_notify_get_ui_ops(void)
{
	return &adiumPurpleNotifyOps;
}
