/*
 * Project:     Libezv
 * File:        AWEzvContact.m
 *
 * Version:     1.0
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004-2005 Andrew Wellington.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "AWEzvContact.h"
#import "AWEzvContactPrivate.h"
#import "AWEzvXMLNode.h"
#import "AWEzvXMLStream.h"
#import "AWEzvRendezvousData.h"
#include "sha1.h"

@implementation AWEzvContact
- (NSString *)uniqueID
{
    return _uniqueID;
}

- (NSString *) name
{
    return _name;
}

- (AWEzvStatus) status
{
    return _status;
}

- (NSString *) statusMessage
{
    return [_rendezvous getField:@"msg"];
}

- (NSDate *) idleSinceDate
{
    return _idleSinceDate;
}

- (AWEzvContactManager *)manager
{
	return _manager;
}

- (void) setUniqueID:(NSString *)uniqueID
{
    if (_uniqueID != uniqueID) {
        [_uniqueID release];
		_uniqueID = [uniqueID retain];
	}
}

- (void) setContactImageData:(NSImage *)contactImageData
{
    if (_contactImageData != contactImageData) {
		[_contactImageData release];
		_contactImageData = [contactImageData retain];
	}
}

- (NSImage *) contactImageData
{
    return _contactImageData;
}
- (void)setImageHash:(NSString *)newHash
{
	if (imageHash != newHash) {
        [imageHash release];
        imageHash = [newHash retain];
    }
}
- (NSString *)imageHash
{
	return imageHash;
}


#pragma mark Sending Messages
//Note: html should actually be HTML; libezv in imservices assumes it is plaintext
- (void) sendMessage:(NSString *)message withHtml:(NSString *)html
{
	AWEzvXMLNode *messageNode, *bodyNode, *textNode, *htmlNode, *htmlBodyNode, *htmlMessageNode;
	NSMutableString *mutableString;
	NSString *messageExtraEscapedString;
	NSString *htmlFiltered;
	NSString *fixedHTML;
	
	/* Lets 'fix' absz and size to include quotes */
	fixedHTML = [self fixHTML:html];
	//XXX if _ipAddr is nil, we should do something
	if (_ipAddr != nil) {

		if (_stream == nil) {
			[self createConnection];
		}

	/* Message cleanup */
	/* actual message */
		mutableString = [message mutableCopy];
		[mutableString replaceOccurrencesOfString:@"<br>" withString:@"<br />"
			options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
		[mutableString replaceOccurrencesOfString:@"&" withString:@"&amp;"
			options:NSLiteralSearch range:NSMakeRange(0, [mutableString length])];
		[mutableString replaceOccurrencesOfString:@"<" withString:@"&lt;"
			options:NSLiteralSearch range:NSMakeRange(0, [mutableString length])];
		[mutableString replaceOccurrencesOfString:@">" withString:@"&gt;"
			options:NSLiteralSearch range:NSMakeRange(0, [mutableString length])];
		messageExtraEscapedString = [mutableString copy];
		[mutableString release];

		mutableString = [fixedHTML mutableCopy];
		[mutableString replaceOccurrencesOfString:@"<br>" withString:@"<br />"
			options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableString length])];
		htmlFiltered = [mutableString copy];
		[mutableString release];

	/* setup XML tree */
		messageNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"message"];
		//[messageNode addAttribute:@"to" withValue:_ipAddr];
		[messageNode addAttribute:@"to" withValue:_uniqueID];
		[messageNode addAttribute:@"from" withValue: [_manager myInstanceName]];
		[messageNode addAttribute:@"type" withValue:@"chat"];

		bodyNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"body"];
		[messageNode addChild:bodyNode];

		textNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLText name:messageExtraEscapedString];
		[bodyNode addChild:textNode];

	
			
		htmlNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"html"];
		[htmlNode addAttribute:@"xmlns" withValue:@"http://www.w3.org/1999/xhtml"];
		[messageNode addChild:htmlNode];
        
		htmlBodyNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"body"];
		[htmlNode addChild:htmlBodyNode];
        
		htmlMessageNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLRaw name:htmlFiltered];
		[htmlBodyNode addChild:htmlMessageNode];
				
		/* send the data */
		[_stream sendString:[messageNode xmlString]];

		


	/* release messages */
		[htmlMessageNode release];
		[htmlBodyNode release];
		[htmlNode release];
		[textNode release];
		[bodyNode release];
		[messageNode release];
		[messageExtraEscapedString release];
		[htmlFiltered release];

	} else {
		[self setStatus: AWEzvUndefined];

		/* and notify */
		[[[[self manager] client] client] userChangedState:self];
		[[[[self manager] client] client] reportError:@"Could Not Send" ofLevel:AWEzvError forUser:[self uniqueID]];
	}
}
- (NSString *) fixHTML:(NSString *)html
{
	/* ABSZ and SIZE are set to integers without quotes which doesn't work with iChat so lets add quotes */
	NSMutableString *mutableHTML;
	NSRange findRange;

	mutableHTML = [html mutableCopy];

	findRange = [mutableHTML rangeOfString:@"ABSZ="];
	if (findRange.location != NSNotFound && findRange.length == 5) {
		/* We have a correct ABSZ= string */
		[mutableHTML insertString:@"\"" atIndex:(findRange.location + findRange.length)];
		int i = (findRange.location + findRange.length);
		while (([mutableHTML characterAtIndex:i] != ' ') && ([mutableHTML characterAtIndex:i] != '>')) {
			i++;
		}
		[mutableHTML insertString:@"\"" atIndex: i];
	}

	findRange = [mutableHTML rangeOfString:@"SIZE="];
	if (findRange.location != NSNotFound && findRange.length == 5) {
		/* We have a correct SIZE= string */
		[mutableHTML insertString:@"\"" atIndex:(findRange.location + findRange.length)];
		int i = (findRange.location + findRange.length);
		while (([mutableHTML characterAtIndex:i] != ' ') && ([mutableHTML characterAtIndex:i] != '>')) {
			i++;
		}
		[mutableHTML insertString:@"\"" atIndex: i];
	}

	/* iChat display pt sized fonts larger than the NSTextView, however, using px makes the sizes the same */
	findRange = [mutableHTML rangeOfString:@"font-size"];
	if (findRange.location != NSNotFound) {
		/*We have found the pt for font-size */
		NSRange	 nextSemicolon = [mutableHTML rangeOfString:@";"
											  options:NSLiteralSearch
												range:NSMakeRange(findRange.location, [mutableHTML length] - findRange.location)];
		[mutableHTML replaceOccurrencesOfString:@"pt" withString:@"px" options:NSCaseInsensitiveSearch range:NSMakeRange(findRange.location, NSMaxRange(nextSemicolon) - findRange.location)];
	}

	return [mutableHTML autorelease];
}

#pragma mark Send Typing Notification

- (void) sendTypingNotification:(AWEzvTyping)typingStatus
{
	AWEzvXMLNode *messageNode, *bodyNode, *htmlNode, *xNode, *composingNode = nil, *idNode = nil;

	if (_ipAddr != nil) {
		messageNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"message"];
		[messageNode addAttribute:@"to" withValue:[self uniqueID]];
		[messageNode addAttribute:@"from" withValue:[_manager myInstanceName]];

		bodyNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"body"];
		[messageNode addChild:bodyNode];

		htmlNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"html"];
		[htmlNode addAttribute:@"xmlns" withValue:@"http://www.w3.org/1999/xhtml"];
		[messageNode addChild:htmlNode];

		xNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"x"];
		[xNode addAttribute:@"xmlns" withValue:@"jabber:x:event"];
		[messageNode addChild:xNode];

		if (typingStatus == AWEzvIsTyping) {
			composingNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"composing"];
			[xNode addChild:composingNode];
		}

		idNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"id"];
		[xNode addChild:idNode];

		/* send the data */
		[_stream sendString:[messageNode xmlString]];

		/* release messages */
		[idNode release];
		[composingNode release];
		[xNode release];
		[htmlNode release];
		[bodyNode release];
		[messageNode release];

	}
}

#pragma mark Outgoing FIle Transfer

- (void)sendOutgoingFileTransfer:(EKEzvOutgoingFileTransfer *)transfer
{
	/*Examle xml
	* <?xml version="1.0"?>
	* <message type="chat" to="erichjkr@erkreutzer">
	*   <body/>
	*   <html xmlns="http://www.w3.org/1999/xhtml">
	*     <body ichatballooncolor="#E68CBD" ichattextcolor="#000000"/>
	*   </html>
	*   <x xmlns="jabber:x:event">
	*     <composing/>
	*   </x>
	*   <x xmlns="jabber:x:oob">
	*     <url type="file" size="15776164" posixflags="000001A4" mimeType="application/zip" hfsflags="0000000C">http://192.168.1.100:53285/99C94EC10486D6E0/Adium.zip</url>
	*   </x>
	* </message> 
	**/	
	AWEzvXMLNode *messageNode, *bodyNode, *htmlNode, *xNode, *urlNode, *urlValue;
	if (_ipAddr != nil) {
		if (_stream == nil) {
			[self createConnection];
		}
		messageNode =  [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"message"];
		[messageNode addAttribute:@"to" withValue:[self uniqueID]];
		[messageNode addAttribute:@"from" withValue:[_manager myInstanceName]];
		[messageNode addAttribute:@"type" withValue:@"chat"];

		bodyNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"body"];
		[messageNode addChild:bodyNode];

		htmlNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"html"];
		[htmlNode addAttribute:@"xmlns" withValue:@"http://www.w3.org/1999/xhtml"];
		[messageNode addChild:htmlNode];

		xNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"x"];
		[xNode addAttribute:@"xmlns" withValue:@"jabber:x:oob"];
		[messageNode addChild:xNode];

		urlNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"url"];
		/*directory transfers*/
		if ([transfer isDirectory]) {
			[urlNode addAttribute:@"type" withValue:@"directory"];
		} else {
			[urlNode addAttribute:@"type" withValue:@"file"];
			[urlNode addAttribute:@"posixflags" withValue:[transfer posixflags]];
			[urlNode addAttribute:@"mimeType" withValue:[transfer mimeType]];
			//[urlNode addAttribute:@"hfsflags" withValue:[transfer hfsflags]];
		}
		
		[urlNode addAttribute:@"size" withValue:[NSString stringWithFormat:@"%qu", [[transfer sizeNumber] unsignedLongLongValue]]];
		urlValue = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLText name:[transfer baseURL]];
		[urlNode addChild:urlValue];
		[xNode addChild:urlNode];
		
		/*Send the xml*/
		[_stream sendString:[messageNode xmlString]];
		
		[urlValue release];
		[urlNode release];
		[xNode release];
		[htmlNode release];
		[bodyNode release];
		[messageNode release];
	}
}

@end
