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


#import "adiumPurpleRequest.h"
#import "ESPurpleRequestActionController.h"
#import "ESPurpleRequestWindowController.h"
#import "ESPurpleFileReceiveRequestController.h"
#import "AILibpurplePlugin.h"
#import "AMPurpleRequestFieldsController.h"

#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIListContact.h>
#import <AIUtilities/AIObjectAdditions.h>

#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>

#import <libintl/libintl.h>

/*
 * Purple requires us to return a handle from each of the request functions.  This handle is passed back to use in 
 * adiumPurpleRequestClose() if the request window is no longer valid -- for example, a chat invitation window is open,
 * and then the account disconnects.  All window controllers created from adiumPurpleRequest.m should return non-autoreleased
 * instances of themselves.  They then release themselves when their window closes.  Rather than calling
 * [[self window] close], they should use purple_request_close_with_handle(self) to ensure proper bookkeeping purpleside.
 */
 
//Jabber registration
#import <libpurple/jabber.h>

/* resolved id for Meanwhile */
struct resolved_id {
	char *id;
	char *name;
};

/*!
 * @brief Process button text, removing gtk+ accelerator underscores
 *
 * Textual underscores are indicated by "__"
 */
NSString *processButtonText(NSString *inButtonText)
{
	NSMutableString	*processedText = [inButtonText mutableCopy];
	
#define UNDERSCORE_PLACEHOLDER @"&&&&&"

	//Replace escaped underscores with our placeholder
	[processedText replaceOccurrencesOfString:@"__"
								   withString:UNDERSCORE_PLACEHOLDER
									  options:NSLiteralSearch
										range:NSMakeRange(0, [processedText length])];
	//Remove solitary underscores
	[processedText replaceOccurrencesOfString:@"_"
								   withString:@""
									  options:NSLiteralSearch
										range:NSMakeRange(0, [processedText length])];

	//Replace the placeholder with an underscore
	[processedText replaceOccurrencesOfString:UNDERSCORE_PLACEHOLDER
								   withString:@"_"
									  options:NSLiteralSearch
										range:NSMakeRange(0, [processedText length])];
	
	return [processedText autorelease];
	
}

static void *adiumPurpleRequestInput(
								   const char *title, const char *primary,
								   const char *secondary, const char *defaultValue,
								   gboolean multiline, gboolean masked, gchar *hint,
								   const char *okText, GCallback okCb, 
								   const char *cancelText, GCallback cancelCb,
								   PurpleAccount *account, const char *who, PurpleConversation *conv,
								   void *userData)
{
	/*
	 Multiline should be a paragraph-sized box; otherwise, a single line will suffice.
	 Masked means we want to use an NSSecureTextField sort of thing.
	 We may receive any combination of primary and secondary text (either, both, or neither).
	 */
	id					requestController = nil;
	NSString			*primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	
	//Ignore purple trying to get an account's password; we'll feed it the password and reconnect if it gets here, somehow.
	if ([primaryString rangeOfString:@"Enter password for "].location != NSNotFound) return [NSNull null];
	
	NSMutableDictionary *infoDict;
	NSString			*okButtonText = processButtonText([NSString stringWithUTF8String:okText]);
	NSString			*cancelButtonText = processButtonText([NSString stringWithUTF8String:cancelText]);
	
	infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:okButtonText,@"OK Text",
		cancelButtonText,@"Cancel Text",
		[NSValue valueWithPointer:okCb],@"OK Callback",
		[NSValue valueWithPointer:cancelCb],@"Cancel Callback",
		[NSValue valueWithPointer:userData],@"userData",nil];
	
	
	if (primaryString) [infoDict setObject:primaryString forKey:@"Primary Text"];
	if (title) [infoDict setObject:[NSString stringWithUTF8String:title] forKey:@"Title"];	
	if (defaultValue) [infoDict setObject:[NSString stringWithUTF8String:defaultValue] forKey:@"Default Value"];
	if (secondary) [infoDict setObject:[NSString stringWithUTF8String:secondary] forKey:@"Secondary Text"];
	
	[infoDict setObject:[NSNumber numberWithBool:multiline] forKey:@"Multiline"];
	[infoDict setObject:[NSNumber numberWithBool:masked] forKey:@"Masked"];
	
	AILogWithSignature(@"%@",infoDict);
	
	requestController = [ESPurpleRequestWindowController showInputWindowWithDict:infoDict];
	
	return requestController;
}

static void *adiumPurpleRequestChoice(const char *title, const char *primary,
									const char *secondary, gint defaultValue,
									const char *okText, GCallback okCb,
									const char *cancelText, GCallback cancelCb,
									PurpleAccount *account, const char *who, PurpleConversation *conv,
									void *userData, va_list choices)
{
	AILogWithSignature(@"%s\n%s\n%s ",
			   (title ? title : ""),
			   (primary ? primary : ""),
			   (secondary ? secondary : ""));
	
	return nil;
}

//Purple requests the user take an action such as accept or deny a buddy's attempt to add us to her list 
static void *adiumPurpleRequestAction(const char *title, const char *primary,
									const char *secondary, gint default_action,
									PurpleAccount *account, const char *who, PurpleConversation *conv,
									void *userData,
									size_t actionCount, va_list actions)
{
    NSString			*titleString = (title ? [NSString stringWithUTF8String:title] : @"");
	NSString			*primaryString = (primary ? [NSString stringWithUTF8String:primary] : nil);
	id					requestController = nil;
	NSInteger					i;
	BOOL				handled = NO;

	if (primaryString && ([primaryString isEqualToString:[NSString stringWithFormat:[NSString stringWithUTF8String:_("%s has just asked to directly connect to %s")],
														  who, purple_account_get_username(account)]])) {
		AIListContact *adiumContact = contactLookupFromBuddy(purple_find_buddy(account, who));

		// Look up the user preference for this setting -- we use the same settings as the File Transfer code.
		AIFileTransferAutoAcceptType autoAccept = [[adium.preferenceController preferenceForKey:KEY_FT_AUTO_ACCEPT 
																							group:PREF_GROUP_FILE_TRANSFER] intValue];
		if ((autoAccept == AutoAccept_All) || 
			((autoAccept == AutoAccept_FromContactList) && adiumContact && [adiumContact isIntentionallyNotAStranger])) {
			GCallback ok_cb;

			//Get the callback for Connect, skipping over the title
			va_arg(actions, char *);
			ok_cb = va_arg(actions, GCallback);
			
			((PurpleRequestActionCb)ok_cb)(userData, default_action);
			
			handled = YES;
		}
	} else if (primary && strcmp(primary, _("Accept chat invitation?")) == 0) {
		AIListContact *contact = contactLookupFromBuddy(purple_find_buddy(account, who));
		[adium.contactAlertsController generateEvent:CONTENT_GROUP_CHAT_INVITE
										 forListObject:contact
											  userInfo:[NSDictionary dictionary]
						  previouslyPerformedActionIDs:nil];	
	}

	if (!handled) {
		NSString		*secondaryString = (secondary ? [NSString stringWithUTF8String:secondary] : nil);
		NSMutableArray	*buttonNamesArray = [NSMutableArray arrayWithCapacity:actionCount];
		GCallback		*callBacks = g_new0(GCallback, actionCount);
		
		//Generate the actions names and callbacks into useable forms
		for (i = 0; i < actionCount; i += 1) {
			char *buttonName;
			
			//Get the name
			buttonName = va_arg(actions, char *);
			[buttonNamesArray addObject:processButtonText([NSString stringWithUTF8String:buttonName])];
			
			//Get the callback for that name
			callBacks[i] = va_arg(actions, GCallback);
		}
		
		//Make default_action (or first if none specified) the last one
		if (default_action < (NSInteger)actionCount-1) {
			// If there's no default_action, assume the first one is, and move it to the end.
			if (default_action == -1)
				default_action = 0;

			GCallback tempCallBack = callBacks[actionCount-1];
			callBacks[actionCount-1] = callBacks[default_action];
			callBacks[default_action] = tempCallBack;
			
			[buttonNamesArray exchangeObjectAtIndex:default_action withObjectAtIndex:(actionCount-1)];
		}
		
		NSMutableDictionary	*infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										 buttonNamesArray,@"Button Names",
										 [NSValue valueWithPointer:callBacks],@"callBacks",
										 [NSValue valueWithPointer:userData],@"userData",
										 titleString,@"TitleString",nil];
		
		// If we have both a primary and secondary string, use the primary as a header.
		if (secondaryString) {
			[infoDict setObject:primaryString forKey:@"MessageHeader"];
			[infoDict setObject:secondaryString forKey:@"Message"];
		} else {
			[infoDict setObject:primaryString forKey:@"Message"];
		}
		
		AIAccount *adiumAccount = accountLookup(account);
		if (adiumAccount) {
			[infoDict setObject:adiumAccount forKey:@"AIAccount"];
		}
		
		if (who) {
			AIListContact *adiumContact = contactLookupFromBuddy(purple_find_buddy(account, who));
			if (adiumContact) {
				[infoDict setObject:adiumContact forKey:@"AIListContact"];
			}
			
			[infoDict setObject:[NSString stringWithUTF8String:who] forKey:@"who"];
		}

		requestController = [ESPurpleRequestActionController showActionWindowWithDict:infoDict];
	}

	return requestController;
}

static void *adiumPurpleRequestFields(const char *title, const char *primary,
									const char *secondary, PurpleRequestFields *fields,
									const char *okText, GCallback okCb,
									const char *cancelText, GCallback cancelCb,
									PurpleAccount *account, const char *who, PurpleConversation *conv,
									void *userData)
{
	id					requestController = nil;
	NSString			*titleString = (title ?  [[NSString stringWithUTF8String:title] lowercaseString] : nil);

    if (titleString && 
		[titleString rangeOfString:@"new jabber"].location != NSNotFound) {
		/* Jabber registration request. Instead of displaying a request dialogue, we fill in the information automatically.
		 * And by that, I mean that we accept all the default empty values, since the username and password are preset for us. */
		((PurpleRequestFieldsCb)okCb)(userData, fields);
		
	} else {
		AILog(@"adiumPurpleRequestFields: %s\n%s\n%s ",
				   (title ? title : ""),
				   (primary ? primary : ""),
				   (secondary ? secondary : ""));
        
        id self = (CBPurpleAccount*)account->ui_data; // for AILocalizedString
		
        requestController = [[AMPurpleRequestFieldsController alloc] initWithTitle:title?[NSString stringWithUTF8String:title]:nil
                                                                       primaryText:primary?[NSString stringWithUTF8String:primary]:nil
                                                                     secondaryText:secondary?[NSString stringWithUTF8String:secondary]:nil
                                                                     requestFields:fields
                                                                            okText:okText?[NSString stringWithUTF8String:okText]:AILocalizedString(@"OK",nil)
                                                                          callback:okCb
                                                                        cancelText:cancelText?[NSString stringWithUTF8String:cancelText]:AILocalizedString(@"Cancel",nil)
                                                                          callback:cancelCb
                                                                           account:(CBPurpleAccount*)account->ui_data
                                                                               who:who?[NSString stringWithUTF8String:who]:nil
                                                                      conversation:conv
                                                                          userData:userData];
#if 0
		GList					*gl, *fl, *field_list;
		PurpleRequestFieldGroup	*group;

		//Look through each group, processing each field
		for (gl = purple_request_fields_get_groups(fields);
			 gl != NULL;
			 gl = gl->next) {
			
			group = gl->data;
			field_list = purple_request_field_group_get_fields(group);
			
			for (fl = field_list; fl != NULL; fl = fl->next) {
				/*
				typedef enum
				{
					PURPLE_REQUEST_FIELD_NONE,
					PURPLE_REQUEST_FIELD_STRING,
					PURPLE_REQUEST_FIELD_INTEGER,
					PURPLE_REQUEST_FIELD_BOOLEAN,
					PURPLE_REQUEST_FIELD_CHOICE,
					PURPLE_REQUEST_FIELD_LIST,
					PURPLE_REQUEST_FIELD_LABEL,
					PURPLE_REQUEST_FIELD_ACCOUNT
				} PurpleRequestFieldType;
				*/

				/*
				PurpleRequestField		*field;
				PurpleRequestFieldType	type;
				
				field = (PurpleRequestField *)fl->data;
				type = purple_request_field_get_type(field);
				if (type == PURPLE_REQUEST_FIELD_STRING) {
					if (strcasecmp("username", purple_request_field_get_label(field)) == 0) {
						purple_request_field_string_set_value(field, purple_account_get_username(account));
					} else if (strcasecmp("password", purple_request_field_get_label(field)) == 0) {
						purple_request_field_string_set_value(field, purple_account_get_password(account));
					}
				}
				 */
			}
			
		}
//		((PurpleRequestFieldsCb)okCb)(userData, fields);
#endif
	}
    
	return requestController;
}

static void *adiumPurpleRequestFile(const char *title, const char *filename,
								  gboolean savedialog, GCallback ok_cb,
								  GCallback cancel_cb,
								  PurpleAccount *account, const char *who, PurpleConversation *conv,
								  void *user_data)
{	
	if (title) {
		NSString *titleString = (title ? [NSString stringWithUTF8String:title] : nil);
		if (savedialog) {
			NSSavePanel *savePanel = [NSSavePanel savePanel];
			if ([titleString length]) [savePanel setTitle:titleString];

			if ([savePanel runModalForDirectory:nil file:nil] == NSOKButton) {
				((PurpleRequestFileCb)ok_cb)(user_data, [[savePanel filename] UTF8String]);
			}			
		} else {
			NSOpenPanel *openPanel = [NSOpenPanel openPanel];
			if ([titleString length]) [openPanel setTitle:titleString];

			if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSOKButton) {
				((PurpleRequestFileCb)ok_cb)(user_data, [[openPanel filename] UTF8String]);
			}
		}
	} else {
		/* Only file transfer file requests lack a title */
		PurpleXfer *xfer = (PurpleXfer *)user_data;
		if (xfer) {
			PurpleXferType xferType = purple_xfer_get_type(xfer);
			
			if (xferType == PURPLE_XFER_RECEIVE) {
				AILog(@"*** WARNING: File request: %s from %s on IP %s which wasn't handled by the file-recv-request signal",
					  xfer->filename,xfer->who,purple_xfer_get_remote_ip(xfer));
				/* We should never get here.  The file-recv-request signal is posted before we could.  We handle that signal
				 * (in adiumPurpleSignals) and set a local filename when we do to prevent being prompted via the request_file() ui op.
				 */
				
			} else if (xferType == PURPLE_XFER_SEND) {
				/*
				 * Um, yes, we've already set the local filename... which should be the same as the file name for the transfer itself...
				 * and we do, in fact, want to send. Call the OK callback immediately.
				 */
				if (xfer->local_filename != NULL && xfer->filename != NULL) {
					AILog(@"PURPLE_XFER_SEND: %x (%s)",xfer,xfer->local_filename);
					((PurpleRequestFileCb)ok_cb)(user_data, xfer->local_filename);
				} else {
					((PurpleRequestFileCb)cancel_cb)(user_data, xfer->local_filename);
					[[SLPurpleCocoaAdapter sharedInstance] displayFileSendError];
				}
			}
		}
	}
	
	return NULL;
}

/*!
 * @brief Purple requests that we close a request window
 *
 * This is not sent after user interaction with the window.  Instead, it is sent when the window is no longer valid;
 * for example, a chat invite window after the relevant account disconnects.  We should immediately close the window.
 *
 * @param type The request type
 * @param uiHandle must be an id; it should either be NSNull or an object which can respond to close, such as NSWindowController.
 */
static void adiumPurpleRequestClose(PurpleRequestType type, void *uiHandle)
{
	id	ourHandle = (id)uiHandle;
	AILogWithSignature(@"%@ (%i)",uiHandle,[ourHandle respondsToSelector:@selector(purpleRequestClose)]);
	if ([ourHandle respondsToSelector:@selector(purpleRequestClose)]) {
		[ourHandle purpleRequestClose];

	} else if ([ourHandle respondsToSelector:@selector(closeWindow:)]) {
		[ourHandle closeWindow:nil];
	}
}

static void *adiumPurpleRequestFolder(const char *title, const char *dirname, GCallback ok_cb, GCallback cancel_cb,
									  PurpleAccount *account, const char *who, PurpleConversation *conv,
									  void *user_data)
{
	AILogWithSignature(@"");

	return NULL;
}

static PurpleRequestUiOps adiumPurpleRequestOps = {
    adiumPurpleRequestInput,
    adiumPurpleRequestChoice,
    adiumPurpleRequestAction,
    adiumPurpleRequestFields,
	adiumPurpleRequestFile,
    adiumPurpleRequestClose,
	adiumPurpleRequestFolder
};

PurpleRequestUiOps *adium_purple_request_get_ui_ops()
{
	return &adiumPurpleRequestOps;
}

@implementation ESPurpleRequestAdapter

+ (void)requestCloseWithHandle:(id)handle
{
	AILogWithSignature(@"%@", handle);
	purple_request_close_with_handle(handle);
}

@end
