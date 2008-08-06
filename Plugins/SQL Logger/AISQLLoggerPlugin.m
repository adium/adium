/*-------------------------------------------------------------------------------------------------------*\
| AISQLLoggerPlugin 1.0 for Adium                                                                         |
| AISQLLoggerPlugin: Copyright (C) 2002-2005 Jeffrey Melloy.                                              |
| <jmelloy@visualdistortion.org> <http://www.visualdistortion.org/adium/>                                 |
| Adium: Copyright (C) 2001-2005 Adam Iser. <adamiser@mac.com> <http://www.adiumx.com>                    |---\
\---------------------------------------------------------------------------------------------------------/   |
  | This program is free software; you can redistribute it and/or modify it under the terms of the GNU        |
  | General Public License as published by the Free Software Foundation; either version 2 of the License,     |
  | or (at your option) any later version.                                                                    |
  |                                                                                                           |
  | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even    |
  | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General         |
  | Public License for more details.                                                                          |
  |                                                                                                           |
  | You should have received a copy of the GNU General Public License along with this program; if not,        |
  | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.    |
  \----------------------------------------------------------------------------------------------------------*/

#import "AISQLLoggerPlugin.h"
#import "JMSQLLoggerAdvancedPreferences.h"
#import "libpq-fe.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIHTMLDecoder.h>
#import "AIInterfaceController.h"
#import "AIContentController.h"
#import <Adium/AIContentMessage.h>
#import "AIChat.h"
#import <Adium/AIListContact.h>
#import "AIService.h"

#define SQL_LOG_VIEWER  AILocalizedString(@"SQL Log Viewer",nil)

@interface AISQLLoggerPlugin (PRIVATE)
- (void)_addMessage:(NSAttributedString *)message dest:(NSString *)destName source:(NSString *)sourceName sendDisplay:(NSString *)sendDisp destDisplay:(NSString *)destDisp sendServe:(NSString *)s_service recServe:(NSString *)r_service;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AISQLLoggerPlugin

- (void)installPlugin
{
	NSString	*connInfo;
	id			tmp;

    //Install some prefs.
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:SQL_LOGGING_DEFAULT_PREFS
																		forClass:[self class]]
										  forGroup:PREF_GROUP_SQL_LOGGING];
    advancedPreferences = [[JMSQLLoggerAdvancedPreferences preferencePane] retain];

	//Watch for pref changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SQL_LOGGING];

	if ([username isEqualToString:@""] ) {
		username = nil;
	}

	if ([database isEqualToString:@""] ) {
		database = nil;
	}

	connInfo = [NSString stringWithFormat:@"host=\'%@\' port=\'%@\' user=\'%@\' password=\'%@\' dbname=\'%@\' sslmode=\'prefer\'",
						(tmp = url) ? tmp: @"", (tmp = port) ? tmp: @"", (tmp = username) ? tmp: NSUserName(),
				   (tmp = password) ? tmp: @"", (tmp = database) ? tmp: NSUserName()];

    conn = PQconnectdb([connInfo cString]);
    if (PQstatus(conn) == CONNECTION_BAD)
    {
        NSString *error =  [NSString stringWithCString:PQerrorMessage(conn)];
        [[adium interfaceController] handleErrorMessage:@"Connection to database failed." withDescription:error];
    }
}

- (void)uninstallPlugin
{
        PQfinish(conn);
	[[adium preferenceController] unregisterPreferenceObserver:self];
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	bool			newLogValue;

	newLogValue = [[prefDict objectForKey:KEY_SQL_LOGGER_ENABLE] boolValue];
	username = [prefDict objectForKey:KEY_SQL_USERNAME];
	url = [prefDict objectForKey:KEY_SQL_URL];
	port = [prefDict objectForKey:KEY_SQL_PORT];
	database = [prefDict objectForKey:KEY_SQL_DATABASE];
	password = [prefDict objectForKey:KEY_SQL_PASSWORD];

	if (newLogValue != observingContent) {
		observingContent = newLogValue;

		if (!observingContent) { //Stop Logging
			[[adium notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];

		} else { //Start Logging
			[[adium notificationCenter] addObserver:self selector:@selector(adiumSentOrReceivedContent:) name:Content_ContentObjectAdded object:nil];
		}
	}
}

//Content was sent or recieved
- (void)adiumSentOrReceivedContent:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"AIContentObject"];

    //Message Content
    if (([[content type] isEqualToString:CONTENT_MESSAGE_TYPE] ||  ||
		 [[content type] isEqualToString:CONTENT_NOTIFICATION_TYPE]) && [content postProcessContent]) {
        AIChat		*chat = [notification object];
        AIListObject	*source = [content source];
        AIListObject	*destination = [content destination];
        AIAccount	*account = [chat account];

        NSString	*srcDisplay = nil;
        NSString	*destDisplay = nil;
        NSString	*destUID = nil;
        NSString	*srcUID = nil;
        NSString	*destSrv = nil;
        NSString	*srcSrv = nil;

        if ([[account UID] isEqual:[source UID]]) {
#warning I think it would be better to use the destination of the message as a test here, but I am not sure.
            destUID  = [chat name];
            if (!destUID) {
                destUID = [[chat listObject] UID];
                destDisplay = [[chat listObject] displayName];
            }
            else {
                destDisplay = [chat displayName];;
            }
            destSrv = [[[chat account] service] serviceID];
            srcDisplay = [source displayName];
            srcUID = [source UID];
            srcSrv = [[source service] serviceID];
        } else {
            destUID = [chat name];
            if (!destUID) {
                srcDisplay = [[chat listObject] displayName];
                srcUID = [[chat listObject] UID];
                destUID = [destination UID];
                destDisplay = [destination displayName];
            }
            else {
                srcUID = [source UID];
                srcDisplay = srcUID;
                destDisplay = [chat displayName];
            }
            srcSrv = [[[chat account] service] serviceID];
            destSrv = srcSrv;
        }

        if (account && source) {
            //Log the message
            [self _addMessage:[[content message] attributedStringByConvertingAttachmentsToStrings]
                         dest:destUID
                       source:srcUID
                  sendDisplay:srcDisplay
                  destDisplay:destDisplay
                    sendServe:srcSrv
                     recServe:destSrv];
        }
    }
}

//Insert a message
- (void)_addMessage:(NSAttributedString *)message
               dest:(NSString *)destName
             source:(NSString *)sourceName
        sendDisplay:(NSString *)sendDisp
        destDisplay:(NSString *)destDisp
          sendServe:(NSString *)s_service
           recServe:(NSString *)r_service

{
    NSString	*sqlStatement;
    NSMutableString 	*escapeHTMLMessage;
    escapeHTMLMessage = [NSMutableString stringWithString:[AIHTMLDecoder encodeHTML:message headers:NO
																		   fontTags:NO
																 includingColorTags:NO  closeFontTags:NO
																		  styleTags:YES closeStyleTagsOnFontChange:NO
																	 encodeNonASCII:YES encodeSpaces:YES
																		 imagesPath:nil
																  attachmentsAsText:YES onlyIncludeOutgoingImages:NO
																	 simpleTagsOnly:NO
																	 bodyBackground:NO
																allowJavascriptURLs:YES]];

    char	escapeMessage[[escapeHTMLMessage length] * 2 + 1];
    char	escapeSender[[sourceName length] * 2 + 1];
    char	escapeRecip[[destName length] * 2 + 1];
    char	escapeSendDisplay[[sendDisp length] * 2 + 1];
    char	escapeRecDisplay[[destDisp length] * 2 + 1];

    PGresult *res;

    PQescapeString(escapeMessage, [escapeHTMLMessage UTF8String], [escapeHTMLMessage length]);
    PQescapeString(escapeSender, [sourceName UTF8String], [sourceName length]);
    PQescapeString(escapeRecip, [destName UTF8String], [destName length]);
    PQescapeString(escapeSendDisplay, [sendDisp UTF8String], [sendDisp length]);
    PQescapeString(escapeRecDisplay, [destDisp UTF8String], [destDisp length]);

    sqlStatement = [NSString stringWithFormat:@"insert into im.message_v (sender_sn, recipient_sn, message, sender_service, recipient_service, sender_display, recipient_display) values (\'%s\',\'%s\',\'%s\', \'%@\', \'%@\', \'%s\', \'%s\')",
    escapeSender, escapeRecip, escapeMessage, s_service, r_service, escapeSendDisplay, escapeRecDisplay];

    res = PQexec(conn, [sqlStatement UTF8String]);
    if (!res || PQresultStatus(res) != PGRES_COMMAND_OK) {
        NSLog(@"%s / %s\n%@", PQresStatus(PQresultStatus(res)), PQresultErrorMessage(res), sqlStatement);
        [[adium interfaceController] handleErrorMessage:@"Insertion failed." withDescription:@"Database Insert Failed"];
        if (res) {
            PQclear(res);
        }

        if (PQresultStatus(res) == PGRES_NONFATAL_ERROR) {
            //Disconnect and reconnect.
            PQfinish(conn);
            conn = PQconnectdb("");
            if (PQstatus(conn) == CONNECTION_BAD)
            {
                [[adium interfaceController] handleErrorMessage:@"Database reconnect failed.."
												withDescription:@"Check your settings and try again."];
                NSLog(@"%s", PQerrorMessage(conn));
            } else {
                NSLog(@"Connection to PostgreSQL successfully made.");
            }
        }
    }
    if (res) {
        PQclear(res);
    }
}

- (NSString *)pluginAuthor {
    return @"Jeffrey Melloy";
}

- (NSString *)pluginDescription {
    return @"This plugin implements chat logging into a PostgreSQL database.";
}

- (NSString *)pluginVersion {
    return @"1.0";
}

- (NSString *)pluginURL {
    return @"http://www.visualdistortion.org/sqllogger/";
}

@end
