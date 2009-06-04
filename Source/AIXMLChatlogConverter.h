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


typedef enum{
	XML_STATE_NONE,
	XML_STATE_CHAT,
	XML_STATE_MESSAGE,
	XML_STATE_EVENT_MESSAGE,
	XML_STATE_STATUS_MESSAGE
} chatLogState;

/*!
 *	@brief Different ways of formatting display names
 */
typedef enum {
	AIDefaultName = 0,
	AIDisplayName = 1,
	AIDisplayName_ScreenName = 2,
	AIScreenName_DisplayName = 3,
	AIScreenName = 4
} AINameFormat;

@class AIHTMLDecoder;

@interface AIXMLChatlogConverter : NSObject {
	CFXMLParserRef	parser;
	NSString		*inputFileString;
	NSDictionary	*eventTranslate;
	
	NSDateFormatter *dateFormatter;
	
	chatLogState	state;
	NSString		*sender;
	NSString		*senderAlias;
	NSString		*mySN;
	NSString		*service;
	NSString		*myDisplayName;
	NSCalendarDate	*date;
	NSInteger				messageStart;
	BOOL			autoResponse;
	BOOL			showTimestamps;
	BOOL			showEmoticons;
	NSString		*status;
	
	NSMutableAttributedString *output;
	NSAttributedString *newlineAttributedString;
	NSDictionary	*statusLookup;
	AIHTMLDecoder	*htmlDecoder;

	AINameFormat	nameFormat;
}

+ (NSAttributedString *)readFile:(NSString *)filePath withOptions:(NSDictionary *)options;
- (NSAttributedString *)readFile:(NSString *)filePath withOptions:(NSDictionary *)options;

@end
