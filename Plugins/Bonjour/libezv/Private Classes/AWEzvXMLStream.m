/*
 * Project:     Libezv
 * File:        AWEzvXMLStream.m
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


#import "AWEzvXMLStream.h"
#import "AWEzvXMLNode.h"
#import "AWEzvStack.h"
#import <AIUtilities/AIStringAdditions.h>
#import "AWEzvSupportRoutines.h"
#import "AWEzvContactManagerRendezvous.h"

#define XMLCALL
#import <expat.h> 

/* XML Function prototypes */
void xml_start_element	(void *userData,
                         const XML_Char *name,
                         const XML_Char **atts);
void xml_end_element	(void *userData,
                         const XML_Char *name);
void xml_char_data	(void *userData,
                         const XML_Char *s,
                         int len);

@interface AWEzvXMLStream ()
- (void) connectionDidEnd;
- (void) dataReceived:(NSNotification *)aNotification;
- (void) dataAvailable:(NSNotification *)aNotification;
@end

@implementation AWEzvXMLStream

- (id) initWithFileHandle:(NSFileHandle *)myConnection initiator:(int)myInitiator 
{
	if ((self = [super init])) {
		connection = [myConnection retain];
		delegate = nil;
		nodeStack = [[AWEzvStack alloc] init];
		initiator = myInitiator;
		negotiated = 0;
	}	
    
	return self;
}

- (void)dealloc
{
	if (connection != nil) {
		[connection closeFile];
	    [connection release];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[nodeStack release];
	
	[super dealloc];
}

@synthesize fileHandle = connection;

- (void) readAndParse {
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(dataReceived:)
					  name:NSFileHandleReadCompletionNotification
					  object:connection];
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(dataAvailable:)
					  name:NSFileHandleDataAvailableNotification
					  object:connection];
    
    parser = XML_ParserCreate(NULL);
    XML_SetUserData(parser, self);
    XML_SetElementHandler(parser, &xml_start_element, &xml_end_element);
    XML_SetCharacterDataHandler(parser, &xml_char_data);
    XML_SetParamEntityParsing(parser, XML_PARAM_ENTITY_PARSING_NEVER);
    
    if (!negotiated && initiator) {
        [self sendNegotiationInitiator:initiator];
    }
    
    [connection waitForDataInBackgroundAndNotify];
    
}

- (void) sendData:(NSData *)data {
	@try {
		[connection writeData:data];
	}
	@catch(NSException *e) {
		NSLog(@"Could not send Bonjour data on %@: %@", self, e);
		AILogWithSignature(@"Could not send Bonjour data on %@: %@", self, e);
		[self connectionDidEnd];
	}
}

- (void) sendString:(NSString *)string {
	@try {
		[connection writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	}
	@catch(NSException *e) {
		NSLog(@"Could not send Bonjour data on %@: %@", self, e);
		AILogWithSignature(@"Could not send Bonjour data on %@: %@", self, e);
		[self connectionDidEnd];
	}
}

- (void) dataReceived:(NSNotification *)aNotification {
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSInteger	status;
    
    if ([data length] == 0) {
        if (connection != nil)
           [[aNotification object] autorelease];
        connection = nil;
        [delegate XMLConnectionClosed];
    }
    
    NSAssert( UINT_MAX >= [data length], @"Received too much data to parse" );
    status = XML_Parse(parser, [data bytes], (unsigned int)[data length], [data length] == 0 ? 1 : 0);
    
    if (connection != nil)
       [[aNotification object] waitForDataInBackgroundAndNotify];
}

- (void)dataAvailable:(NSNotification *)aNotification {
    [[aNotification object] readInBackgroundAndNotify];
}

@synthesize delegate;

- (void) xmlStartElement:(const XML_Char *)name attributes:(const XML_Char **)attributes {
    
    NSString *nodeName = [NSString stringWithUTF8String:name];
    
    AWEzvXMLNode *node = [[[AWEzvXMLNode alloc] initWithType:AWEzvXMLElement name:nodeName] autorelease];
    
    while (*attributes != NULL) {
        NSString *attribute = [NSString stringWithUTF8String:*attributes++];
        NSString *value = [NSString stringWithUTF8String:*attributes++];
        [node addAttribute:attribute withValue:value];
    }
    
    if ([nodeStack size] > 0 && [(AWEzvXMLNode *)[nodeStack top] type] == AWEzvXMLText)
        [nodeStack pop];
    
    if ([nodeStack size] > 0) {
        [(AWEzvXMLNode *)[nodeStack top] addChild:node];
    }
    
    [nodeStack push:node];
    
    if (([nodeName isEqualToString:@"stream:stream"]) && !negotiated) {
        if (initiator) {
            negotiated = 1;
        } else {
            [self sendNegotiationInitiator:0];
        }

        [nodeStack pop];
    }
}

- (void) xmlEndElement:(const XML_Char *)name {
	NSString	    *nodeName = [NSString stringWithUTF8String:name];
	if (([nodeStack size] > 0) && ([(AWEzvXMLNode *)[nodeStack top] type] == AWEzvXMLText)) {
		[nodeStack pop];
	}
	else if ([nodeStack size] == 0 && [nodeName isEqualToString:@"stream:stream"]) {
		/* We have no stack but were sent stream:stream to end, therefore end connection */
		[self endConnection];
		return;
	}
	AWEzvXMLNode    *node = [nodeStack top];
	
	if (node != nil && [[node name] isEqualToString:nodeName]) {
		[nodeStack pop];
	} else if ([[node name] isEqualToString:@"stream:stream"]) {
		// Wow, end of connection!
		[self endConnection];
		return;
	} else {
		AWEzvLog(@"Ending node that is not at top of stack");
	}
    
	if ([nodeStack size] == 0 && node != nil) {
		if (delegate != nil)
			[delegate XMLReceived:node];
		else
			AWEzvLog(@"Received message but no delegate to send it to");
	}

}
- (void) connectionDidEnd{
	@try {
		[connection closeFile];
	}
	@catch(NSException *e) {
		
	}

	[connection release];
	connection = nil;
	[delegate XMLConnectionClosed];	
}

- (void) endConnection{
	[self sendString:@"</stream:stream>"];

	[self connectionDidEnd];
}

- (void) xmlCharData:(const XML_Char *)data length:(int)len {
    AWEzvXMLNode    *node;
    NSString	    *newData;
    
    if ((len == 1) && (*data == '\n'))
        return;
    
    newData = [[[NSString alloc] initWithData:[NSData dataWithBytes:data length:len] encoding:NSUTF8StringEncoding] autorelease];
    
    if ([nodeStack size] > 0 && [(AWEzvXMLNode *)[nodeStack top] type] == AWEzvXMLText) {
        node = [nodeStack top];
        if ([node name] != nil)
            [node setName:([[node name] stringByAppendingString:newData])];
        else
            [node setName:newData];
    } else {
        node = [[[AWEzvXMLNode alloc] initWithType:AWEzvXMLText name:newData] autorelease];
        if ([nodeStack top] != nil)
            [(AWEzvXMLNode *)[nodeStack top] addChild:node];
        [nodeStack push:node];
    }
}

- (void) sendNegotiationInitiator:(int)myInitiator {
	/* spit out an XML header */
	[self sendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"];

	/* create elements for handshake */
	NSDictionary *handshakeElements = [NSDictionary dictionaryWithObjectsAndKeys:
									   ([delegate uniqueID] ? [delegate uniqueID] : @"127.0.0.1"), @"to",
										[[delegate manager] myInstanceName], @"from",
										@"jabber:client", @"xmlns",
										@"http://etherx.jabber.org/streams", @"xmlns:stream",
									   nil];

	/* and make an element info structure */
	CFXMLElementInfo	xmlElementInfo;
	xmlElementInfo.attributes = (CFDictionaryRef)handshakeElements;
	xmlElementInfo.attributeOrder = (CFArrayRef)[NSArray arrayWithObjects:@"to", @"from", @"xmlns", @"xmlns:stream", nil];
	xmlElementInfo.isEmpty = YES;

	/* create node and tree, then convert to XML text */
	CFXMLNodeRef xmlNode = CFXMLNodeCreate(NULL, kCFXMLNodeTypeElement, (CFStringRef)@"stream:stream", &xmlElementInfo, kCFXMLNodeCurrentVersion);
	CFXMLTreeRef xmlTree = CFXMLTreeCreateWithNode(NULL, xmlNode);
	NSData *data = [(NSData *)CFXMLTreeCreateXMLData(NULL, xmlTree) autorelease];
	CFRelease(xmlNode);
	CFRelease(xmlTree);

	/* Unfortunately CFXML* gives us <stream ... /> and we need <stream ...>, so we remove the / here */
	NSMutableString *mutableString = [NSMutableString stringWithData:data encoding:NSUTF8StringEncoding];
	[mutableString deleteCharactersInRange:NSMakeRange([mutableString length] - 2, 1)];
	
	/* and we send it to the connection */
	[self sendString:mutableString];

	/* and set negoiated if we didn't initiate */
	if (!myInitiator)
		negotiated = 1;
}

@end

/* XML function handlers */
void xml_start_element	 (void *userData,
                          const XML_Char *name,
                          const XML_Char **atts) {
    AWEzvXMLStream  *self = userData;    
    [self xmlStartElement:name attributes:atts];
}

void xml_end_element	(void *userData,
                         const XML_Char *name) {
    AWEzvXMLStream  *self = userData;
    [self xmlEndElement:name];
}

void xml_char_data	(void *userData,
                         const XML_Char *s,
                         int len) {
    AWEzvXMLStream  *self = userData;
    [self xmlCharData:s length:len];
}
