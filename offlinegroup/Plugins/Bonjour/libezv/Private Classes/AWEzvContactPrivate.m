/*
 * Project:     Libezv
 * File:        AWEzvContactPrivate.m
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

#import "AWEzvContactPrivate.h"
#import "AWEzvPrivate.h"
#import "AWEzvXMLStream.h"
#import "AWEzvXMLNode.h"
#import "AWEzvContactManager.h"
#import "AWEzvRendezvousData.h"
#import "AWEzvSupportRoutines.h"
#import "EKEzvFileTransfer.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation AWEzvContact (Private)
#pragma mark Various Handling Stuff

- (void)dealloc
{
	[_manager contactWillDeallocate:self];
	
	[_name release];
	[_uniqueID release];
	[_contactImageData release];
    [_idleSinceDate release];
	
	[_stream release];
	[_rendezvous release];
	[_ipAddr release];
	[imageHash release];

	[_resolveServiceController release];
	[_imageServiceController release];
	[_addressServiceController release];
	[_manager release];

	[super dealloc];
}

- (void) setStream:(AWEzvXMLStream *)stream {
    if (stream != _stream) {
		[_stream release];
		_stream = [stream retain];
	}

}
- (AWEzvXMLStream *)stream{
	return _stream;
}

- (void) setStatus:(AWEzvStatus) status {
    _status = status;
    
    /* if it's idle it'll be reset soon */
    [_idleSinceDate release];
    _idleSinceDate = nil;
}

- (void) setIdleSinceDate:(NSDate *) idleSince {
    if (idleSince != _idleSinceDate) {
		[_idleSinceDate release];
		_idleSinceDate = [idleSince retain];
	}
}

- (void) setName:(NSString *)name {
	if (name != _name) {
		[_name release];
		_name = [name retain];
	}
}

- (void) setRendezvous:(AWEzvRendezvousData *)rendezvous {
	if (rendezvous != _rendezvous) {
		[_rendezvous release];
		_rendezvous = [rendezvous retain];
	}
}

- (AWEzvRendezvousData *) rendezvous {
    return _rendezvous;
}

- (NSString *)ipaddr {
    return _ipAddr;
}

- (void) setIpaddr:(NSString *)myipaddr {
	
    if (_ipAddr != myipaddr) {
        [_ipAddr release];
		_ipAddr = [myipaddr retain];
	}
}

- (u_int16_t) port {
    return _port;
}

- (void) setPort:(u_int16_t)port {
    _port = port;
}

- (int) serial {
    return [_rendezvous serial];
}

- (void) setManager:(AWEzvContactManager *)manager {
    if (_manager != manager) {
        [_manager release];
		_manager = [manager retain];
	}
}

- (AWEzvContactManager *) manager {
    return _manager;
}

- (void) setResolveServiceController:(ServiceController *)controller
{
	if (_resolveServiceController != controller) {
		[_resolveServiceController release];
		_resolveServiceController = [controller retain];
	}
}

- (ServiceController *) resolveServiceController{
	return _resolveServiceController;
}

- (void) setImageServiceController:(ServiceController *)controller{
	if (_imageServiceController != controller) {
        [_imageServiceController release];
		_imageServiceController = [controller retain];
	}
}
- (ServiceController *) imageServiceController{
	return _imageServiceController;
}

- (void) setAddressServiceController:(ServiceController *)controller{
	if (_addressServiceController != controller) {
        [_addressServiceController release];
		_addressServiceController = [controller retain];
	}
}
- (ServiceController *) addressServiceController{
	return _addressServiceController;
}

#pragma mark Connection Handling
/* connect to contact if required */
- (void)createConnection {
	int			fd;
	struct sockaddr_in	socketAddress;	/* socket address structure */
	NSFileHandle	*connection;

	if (_stream != nil || (_ipAddr == nil))
		return;

	if ((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		[[[[self manager] client] client] reportError:@"Could not create socket to connect to contact for iChat Bonjour" ofLevel:AWEzvError];
		return;
	}

	/* setup socket address structure */	
	memset(&socketAddress, 0, sizeof(socketAddress));
	socketAddress.sin_family = AF_INET;
	socketAddress.sin_addr.s_addr = inet_addr([_ipAddr UTF8String]);
	socketAddress.sin_port = htons([self port]);

	/* connect to client */
	if (connect(fd, (const struct sockaddr *)&socketAddress, sizeof(socketAddress)) < 0) {
		[[[[self manager] client] client] reportError:
		 [NSString stringWithFormat:@"%@: Could not connect socket on fd %i to contact (%@:%i)", self, fd, _ipAddr, [self port]]
							ofLevel:AWEzvError];
		return;
	}

	/* make NSFileHandle */
	connection = [[NSFileHandle alloc] initWithFileDescriptor:fd];

	/* now to create stream */
	_stream = [[AWEzvXMLStream alloc] initWithFileHandle:connection initiator:1];
	[_stream setDelegate:self];
	[_stream readAndParse];

	[connection release];
}


#pragma mark XML Handling
- (void) XMLReceivedMessage:(AWEzvXMLNode *)root {
	/* XXX This routine is rather ugly! */
	AWEzvXMLNode    *node;
	NSString	    *plaintext = nil;
	NSString	    *html = nil;

	/* parse incoming message */
	if (([root type] == AWEzvXMLElement) && ([[root name] isEqualToString:@"message"])) {
		if (([[root attributes] objectForKey:@"type"] != nil) && ([(NSString *)[[root attributes] objectForKey:@"type"] isEqualToString:@"chat"])) {
			NSEnumerator	*objs = [[root children] objectEnumerator];

			while ((node = [objs nextObject])) {
				if (([node type] == AWEzvXMLElement) && ([[node name] isEqualToString:@"body"])) {
					NSEnumerator	*childs = [[node children] objectEnumerator];

					while ((node = [childs nextObject])) {
						if ([node type] == AWEzvXMLText) {
							plaintext = [node name];
						}
					}
				}

				if (([node type] == AWEzvXMLElement) && ([[node name] isEqualToString:@"html"])) {
					html = [node xmlString];
					/* Fix iChat's sending of line-breaks as <br></br> by replacing <br></br> with <br /> */
					NSMutableString *mutableHtml = [html mutableCopy];
					[mutableHtml replaceOccurrencesOfString:@"<br></br>" withString:@"<br />" 
						options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableHtml length])];
					html = [mutableHtml autorelease];
				}

				if (([node type] == AWEzvXMLElement) && ([[node name] isEqualToString:@"x"])) {
					[self XMLCheckForEvent:node];
					[self XMLCheckForOOB:node];
				}
			}

		} else {
			NSEnumerator	*objs = [[root children] objectEnumerator];

			while ((node = [objs nextObject])) {
				if (([node type] == AWEzvXMLElement) && ([[node name] isEqualToString:@"x"])) {
					[self XMLCheckForEvent:node];
					[self XMLCheckForOOB:node];
				}
			}
		}

	/* if we've got a message then we can send it to the client to display */
		if ([plaintext length] > 0)
			[[[[self manager] client] client] user:self sentMessage:plaintext withHtml:html];

	} else if (([root type] == AWEzvXMLElement) && ([[root name] isEqualToString:@"iq"])) {
		/* We can also receive items such as 
		 * <iq id="iChat_887C7BB4" type="set" to="erichjkr@erkreutzer">
		 *   <query xmlns="jabber:iq:oob">
		 *     <url type="file" size="2556" posixflags="000001B4" mimeType="image/gif">http://192.168.1.100:5297/7E17EB87552F078C/Gere%20Mask.gif</url>
		 *   </query>
		 * </iq>
		 */
		NSEnumerator	*objs = [[root children] objectEnumerator];

		while ((node = [objs nextObject])) {
			if (([node type] == AWEzvXMLElement) && ([[node name] isEqualToString:@"query"])) {
				[self XMLCheckForOOB:node];
			}
		}

	}
}

- (void) XMLCheckForEvent:(AWEzvXMLNode *)node {
	NSEnumerator	*objs = [[node attributes] keyEnumerator];
	NSString		*key;
	AWEzvXMLNode	*obj;
	int			eventFlag = 0;

	/* check for events in jabber stream */
	while ((key = [objs nextObject])) {
		if (([key isEqualToString:@"xmlns"]) && 
		([(NSString *)[[node attributes] objectForKey:key] isEqualToString:@"jabber:x:event"])) {
			eventFlag = 1;
		}
	}

	if (!eventFlag)
		return;

	/* if we've got an event, check for typing action. this is all we support
	for now */
		objs = [[node children] objectEnumerator];
	while ((obj = [objs nextObject])) {
		if ([[obj name] isEqualToString:@"composing"]) {
			[[[[self manager] client] client] user:self typingNotification:AWEzvIsTyping];
			return;
		}
		[[[[self manager] client] client] user:self typingNotification:AWEzvNotTyping];
	}

}

- (void) XMLCheckForOOB:(AWEzvXMLNode *)node {
	/* The following is an example of what iChat 3.1.8 v445 sends upon file transfer */
	/*
	 *
	 *<x xmlns="jabber:x:oob"><url type="file" size="15767265" posixflags="000001A4" mimeType="application/zip">http://192.168.1.111:5297/4D6C52DF9D399D00/Adium.zip</url></x>
	 *
	 **/
	NSEnumerator	*objs = [[node attributes] keyEnumerator];
	NSString		*key;
	AWEzvXMLNode	*obj;
	int			OOBFlag = 0;

	/* check for events in jabber stream */
	while ((key = [objs nextObject])) {
		if (([key isEqualToString:@"xmlns"]) && 
		([(NSString *)[[node attributes] objectForKey:key] isEqualToString:@"jabber:x:oob"] || [(NSString *)[[node attributes] objectForKey:key] isEqualToString:@"jabber:iq:oob"])) {
			OOBFlag = 1;
		}
	}
	if (!OOBFlag)
		return;
		
		
	int urlFlag = 0;
	
	/* If we have an oob entry check for url */
	objs = [[node children] objectEnumerator];
	while ((obj = [objs nextObject])) {
		if ([[obj name] isEqualToString:@"url"]) {
			urlFlag = 1;
			break;
		}
	}
	
	if (!urlFlag)
		return;
		
	[self evaluteURLXML:obj];
	
}
- (void) XMLConnectionClosed {
    [_stream autorelease];
    _stream = nil;
}

#pragma mark File Transfer

- (void)evaluteURLXML:(AWEzvXMLNode *)node{
	/* Examle url:
	<url type="file" size="15767265" posixflags="000001A4" mimeType="application/zip">http://192.168.1.111:5297/4D6C52DF9D399D00/Adium.zip</url>
	-and-
	<url type="directory" size="90048908" nfiles="3456" posixflags="000001ED">http://192.168.1.101:34570/A26F7D11E2EDC3D9/folder/</url>
	*/
	
	NSEnumerator	*objs = [[node attributes] keyEnumerator];
	NSString		*key;
	
	
	/* We have a url, so let's determine what type it is */
	NSString *type = nil, *sizeString = nil, *nfiles = nil, *posixflags = nil, *mimeType = nil;
	objs = [[node attributes] keyEnumerator];
	while ((key = [objs nextObject])) {
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
	NSEnumerator	*childs = [[node children] objectEnumerator];
	NSString *url = nil;
	while ((node = [childs nextObject])) {
		if ([node type] == AWEzvXMLText) {
			url = [node name];
		}
	}
	/*Let's get the name out of the url */
	NSString *name = nil;
	name = [url lastPathComponent];
	name = [name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	/* Parse type information */
	
	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	NSNumber *size = [numberFormatter numberFromString:sizeString];
	// unsigned long long size = [[numberFormatter numberFromString:sizeString] unsignedLongLongValue];
	[numberFormatter release];
	
	
	/* Set up EKEzvFileTransfer object */
	EKEzvIncomingFileTransfer *fileTransfer = [[EKEzvIncomingFileTransfer alloc] init];
	[fileTransfer setContact: self];
	[fileTransfer setManager: _manager];
	[fileTransfer setSizeWithNSNumber: size];
	[fileTransfer setDirection: EKEzvIncomingTransfer];
	[fileTransfer setUrl: url];
	[fileTransfer setRemoteFilename: name];
	if ([type isEqualToString:@"directory"]) {
		[fileTransfer setType:EKEzvDirectory_Transfer];
	} else if ([type isEqualToString:@"file"]) {
		[fileTransfer setType:EKEzvFile_Transfer];
	}
	
	[[[[self manager] client] client] user:self sentFile:fileTransfer];
	[fileTransfer release];
}

@end
