/*
 * Project:     Libezv
 * File:        AWEzvXMLStream.h
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

#define XMLCALL
#import <expat.h> 

@class AWEzvStack, AWEzvXMLNode, AWEzvContactManager;
@protocol AWEzvXMLStreamProtocol;

@interface AWEzvXMLStream : NSObject {
    XML_Parser	parser;
    id <AWEzvXMLStreamProtocol>	delegate;
    NSFileHandle *connection;
    AWEzvStack	*nodeStack;
    int		initiator, negotiated;
}

- (id) initWithFileHandle:(NSFileHandle *)connection initiator:(int)initiator;
@property (readonly, nonatomic) NSFileHandle *fileHandle;
- (void) readAndParse;
- (void) sendData:(NSData *)data;
- (void) sendString:(NSString *)string;
- (void) endConnection;
@property (assign, readwrite, nonatomic) id<AWEzvXMLStreamProtocol> delegate;

/* Private methods: used by private implementation, do NOT use these methods */
- (void) xmlStartElement:(const XML_Char *)name attributes:(const XML_Char **)attributes;
- (void) xmlEndElement:(const XML_Char *)name;
- (void) xmlCharData:(const XML_Char *)data length:(int)len;

- (void) sendNegotiationInitiator:(int)initiator;


@end

@protocol AWEzvXMLStreamProtocol
- (void) XMLConnectionClosed;
- (void) XMLReceived:(AWEzvXMLNode *)root;
@property (readonly, copy, nonatomic) NSString *uniqueID;
@property (readonly, retain, nonatomic) AWEzvContactManager *manager;
@end
