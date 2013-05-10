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
#import "AWEzvRendezvousData.h"
#import "AWEzvContactManager.h"
#import "AWEzvContactManagerRendezvous.h"
#import "AWEzv.h"
#import "EKEzvFileTransfer.h"
#import "EKEzvIncomingFileTransfer.h"

#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@implementation AWEzvContact

@synthesize uniqueID, name, status, idleSinceDate, contactImageData, port, ipAddr, imageHash, manager, stream, addressServiceController, imageServiceController, resolveServiceController, rendezvous;

- (NSString *) statusMessage
{
    return [self.rendezvous getField:@"msg"];
}

- (void)dealloc
{
	[self.manager contactWillDeallocate:self];
	
	self.name = nil;
	self.uniqueID = nil;
	self.contactImageData = nil;
	self.idleSinceDate = nil;

	self.stream.delegate = nil;
	self.stream = nil;
	self.rendezvous = nil;
	self.ipAddr = nil;
	self.imageHash = nil;
	self.resolveServiceController = nil;
	self.imageServiceController = nil;
	self.addressServiceController = nil;
	self.manager = nil;
	
	[super dealloc];
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
	//XXX if self.ipAddr is nil, we should do something
	if (self.ipAddr != nil) {

		if (self.stream == nil) {
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
		//[messageNode addAttribute:@"to" withValue:self.ipAddr];
		[messageNode addAttribute:@"to" withValue:self.uniqueID];
		[messageNode addAttribute:@"from" withValue: [self.manager myInstanceName]];
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
		[self.stream sendString:[messageNode xmlString]];

		


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
		[self.manager.client.client userChangedState:self];
		[self.manager.client.client reportError:@"Could Not Send" ofLevel:AWEzvError forUser:[self uniqueID]];
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
		NSInteger i = (findRange.location + findRange.length);
		while (([mutableHTML characterAtIndex:i] != ' ') && ([mutableHTML characterAtIndex:i] != '>')) {
			i++;
		}
		[mutableHTML insertString:@"\"" atIndex: i];
	}

	findRange = [mutableHTML rangeOfString:@"SIZE="];
	if (findRange.location != NSNotFound && findRange.length == 5) {
		/* We have a correct SIZE= string */
		[mutableHTML insertString:@"\"" atIndex:(findRange.location + findRange.length)];
		NSInteger i = (findRange.location + findRange.length);
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

	if (self.ipAddr != nil) {
		messageNode = [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"message"];
		[messageNode addAttribute:@"to" withValue:[self uniqueID]];
		[messageNode addAttribute:@"from" withValue:[self.manager myInstanceName]];

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
		[self.stream sendString:[messageNode xmlString]];

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
	if (self.ipAddr != nil) {
		if (self.stream == nil) {
			[self createConnection];
		}
		messageNode =  [[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:@"message"];
		[messageNode addAttribute:@"to" withValue:[self uniqueID]];
		[messageNode addAttribute:@"from" withValue:[self.manager myInstanceName]];
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
		[self.stream sendString:[messageNode xmlString]];
		
		[urlValue release];
		[urlNode release];
		[xNode release];
		[htmlNode release];
		[bodyNode release];
		[messageNode release];
	}
}

#pragma mark Various Handling Stuff

- (void) setStatus:(AWEzvStatus) inStatus {
    status = inStatus;
    
    /* if it's idle it'll be reset soon */
    self.idleSinceDate = nil;
}


- (int) serial {
    return self.rendezvous.serial;
}

#pragma mark Connection Handling
/* connect to contact if required */
- (void)createConnection {
	int			fd;
	struct sockaddr_in	socketAddress;	/* socket address structure */
	NSFileHandle	*connection;
	
	if (self.stream != nil || (self.ipAddr == nil))
		return;
	
	if ((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		[self.manager.client.client reportError:@"Could not create socket to connect to contact for iChat Bonjour" ofLevel:AWEzvError];
		return;
	}
	
	/* setup socket address structure */	
	memset(&socketAddress, 0, sizeof(socketAddress));
	socketAddress.sin_family = AF_INET;
	socketAddress.sin_addr.s_addr = inet_addr([self.ipAddr UTF8String]);
	socketAddress.sin_port = htons([self port]);
	
	/* connect to client */
	if (connect(fd, (const struct sockaddr *)&socketAddress, sizeof(socketAddress)) < 0) {
		[self.manager.client.client reportError:
		 [NSString stringWithFormat:@"%@: Could not connect socket on fd %i to contact (%@:%i)", self, fd, self.ipAddr, [self port]]
											  ofLevel:AWEzvError];
		return;
	}
	
	/* make NSFileHandle */
	connection = [[NSFileHandle alloc] initWithFileDescriptor:fd];
	
	/* now to create stream */
	self.stream = [[[AWEzvXMLStream alloc] initWithFileHandle:connection initiator:1] autorelease];
	[self.stream setDelegate:self];
	[self.stream readAndParse];
	
	[connection release];
}


#pragma mark XML Handling
- (void) XMLReceived:(AWEzvXMLNode *)root {
	if (root.type != AWEzvXMLElement)
		return;
	
	/* parse incoming message */
	if ([root.name isEqualToString:@"message"])
		[self XMLReceivedMessage:root];
	else if ([root.name isEqualToString:@"iq"]) {
		/* We can also receive items such as 
		 * <iq id="iChat_887C7BB4" type="set" to="erichjkr@erkreutzer">
		 *   <query xmlns="jabber:iq:oob">
		 *     <url type="file" size="2556" posixflags="000001B4" mimeType="image/gif">http://192.168.1.100:5297/7E17EB87552F078C/Gere%20Mask.gif</url>
		 *   </query>
		 * </iq>
		 */
		[self XMLReceivedIQ:root];
	}
}

- (void) XMLReceivedMessage:(AWEzvXMLNode *)root {
	NSString	    *plaintext = nil;
	NSString	    *html = nil;
	
	for (AWEzvXMLNode *node in root.children) {
		
		if (node.type != AWEzvXMLElement)
			continue;
		
		NSString *type = [root.attributes objectForKey:@"type"];
		
		if (type && ([type isEqualToString:@"chat"])) {
			
			if ([node.name isEqualToString:@"body"]) {
				for (AWEzvXMLNode *child in node.children) {
					if (child.type == AWEzvXMLText)
						plaintext = child.name;
				}
			} else if ([node.name isEqualToString:@"html"]) {
				/* Fix iChat's sending of line-breaks as <br></br> by replacing <br></br> with <br /> */
				NSString *xmlString = [node xmlString];
				html = [xmlString stringByReplacingOccurrencesOfString:@"<br></br>" withString:@"<br />" options:NSCaseInsensitiveSearch range:NSMakeRange(0, xmlString.length)];
			}
		
		}
		
		if ([node.name isEqualToString:@"x"]) {
			[self XMLCheckForEvent:node];
			[self XMLCheckForOOB:node];
		}
	}
	
	/* if we've got a message then we can send it to the client to display */
	if (plaintext.length > 0)
		[self.manager.client.client user:self sentMessage:plaintext withHtml:html];
}

- (void) XMLReceivedIQ:(AWEzvXMLNode *)root {
	for (AWEzvXMLNode *node in root.children) {
		if (node.type == AWEzvXMLElement && [node.name isEqualToString:@"query"]) {
			[self XMLCheckForOOB:node];
		}
	}
}

- (void) XMLCheckForEvent:(AWEzvXMLNode *)node {
	BOOL			eventFlag = NO;
	
	/* check for events in jabber stream */
	for (NSString *key in [node.attributes keyEnumerator]) {
		if (([key isEqualToString:@"xmlns"]) && 
			([(NSString *)[node.attributes objectForKey:key] isEqualToString:@"jabber:x:event"])) {
			eventFlag = YES;
		}
	}
	
	if (!eventFlag)
		return;
	
	/* if we've got an event, check for typing action. this is all we support
	 for now */
	for (AWEzvXMLNode *obj in node.children) {
		if ([obj.name isEqualToString:@"composing"]) {
			[self.manager.client.client user:self typingNotification:AWEzvIsTyping];
			return;
		}
		[self.manager.client.client user:self typingNotification:AWEzvNotTyping];
	}
	
}

- (void) XMLCheckForOOB:(AWEzvXMLNode *)node {
	/* The following is an example of what iChat 3.1.8 v445 sends upon file transfer */
	/*
	 *
	 *<x xmlns="jabber:x:oob"><url type="file" size="15767265" posixflags="000001A4" mimeType="application/zip">http://192.168.1.111:5297/4D6C52DF9D399D00/Adium.zip</url></x>
	 *
	 **/
	BOOL			OOBFlag = NO;
	
	/* check for events in jabber stream */
	for (NSString *key in [node.attributes keyEnumerator]) {
		if (([key isEqualToString:@"xmlns"]) && 
			([(NSString *)[node.attributes objectForKey:key] isEqualToString:@"jabber:x:oob"] || [(NSString *)[node.attributes objectForKey:key] isEqualToString:@"jabber:iq:oob"])) {
			OOBFlag = YES;
		}
	}
	
	if (!OOBFlag)
		return;
	
	BOOL urlFlag = NO;
	AWEzvXMLNode	*obj = nil;

	/* If we have an oob entry check for url */
	for (obj in node.children) {
		if ([obj.name isEqualToString:@"url"]) {
			urlFlag = YES;
			break;
		}
	}
	
	if (!urlFlag)
		return;
	
	[self evaluteURLXML:obj];
}

- (void) XMLConnectionClosed {
    self.stream = nil;
}

#pragma mark File Transfer

- (void)evaluteURLXML:(AWEzvXMLNode *)node{
	/* Examle url:
	 <url type="file" size="15767265" posixflags="000001A4" mimeType="application/zip">http://192.168.1.111:5297/4D6C52DF9D399D00/Adium.zip</url>
	 -and-
	 <url type="directory" size="90048908" nfiles="3456" posixflags="000001ED">http://192.168.1.101:34570/A26F7D11E2EDC3D9/folder/</url>
	 */
	
	NSString		*key;
	
	
	/* We have a url, so let's determine what type it is */
	NSString *type = nil, *sizeString = nil, *nfiles = nil, *posixflags = nil, *mimeType = nil;
	for (key in [node.attributes keyEnumerator]) {
		if ([key isEqualToString:@"type"]) {
			type = [[node attributes] objectForKey:key];
		} else if ([key isEqualToString:@"size"]) {
			sizeString = [[node attributes] objectForKey:key]; 
		} else if ([key isEqualToString:@"nfiles"]) {
			nfiles = [[node attributes] objectForKey:key]; 
		} else if ([key isEqualToString:@"posixflags"]) {
			posixflags = [[node attributes] objectForKey:key]; 
		} else if ([key isEqualToString:@"mimeType"]) {
			mimeType = [[node attributes] objectForKey:key]; 
		}
	}
	
	/*Find the url */
	NSString *url = nil;
	for (node in [node.children objectEnumerator]) {
		if (node.type == AWEzvXMLText) {
			url = node.name;
		}
	}
	/*Let's get the name out of the url */
	NSString *fileName = nil;
	fileName = [url lastPathComponent];
	fileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	/* Parse type information */
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	NSNumber *size = [numberFormatter numberFromString:sizeString];
	// unsigned long long size = [[numberFormatter numberFromString:sizeString] unsignedLongLongValue];
	[numberFormatter release];
	
	
	/* Set up EKEzvFileTransfer object */
	EKEzvIncomingFileTransfer *fileTransfer = [[EKEzvIncomingFileTransfer alloc] init];
	[fileTransfer setContact: self];
	[fileTransfer setManager: self.manager];
	[fileTransfer setSizeWithNSNumber: size];
	[fileTransfer setDirection: EKEzvIncomingTransfer];
	[fileTransfer setUrl: url];
	[fileTransfer setRemoteFilename: fileName];
	if ([type isEqualToString:@"directory"]) {
		[fileTransfer setType:EKEzvDirectory_Transfer];
	} else if ([type isEqualToString:@"file"]) {
		[fileTransfer setType:EKEzvFile_Transfer];
	}
	
	[self.manager.client.client user:self sentFile:fileTransfer];
	[fileTransfer release];
}

@end
