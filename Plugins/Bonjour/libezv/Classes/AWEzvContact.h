/*
 * Project:     Libezv
 * File:        AWEzvContact.h
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

#import "AWEzvDefines.h"
#import "AWEzvXMLStream.h"

@class AWEzvXMLStream, AWEzvRendezvousData, AWEzvContactManager, NSImage, ServiceController, EKEzvOutgoingFileTransfer;

@interface AWEzvContact : NSObject <AWEzvXMLStreamProtocol> {
	NSString *__weak name;
	NSString *uniqueID;
	NSData *__weak contactImageData;
	AWEzvStatus status;
	NSDate *__weak idleSinceDate;
	AWEzvXMLStream *stream;
	AWEzvRendezvousData *__weak rendezvous;
	NSString *__weak ipAddr;
	NSString *__weak imageHash;
	u_int16_t port;
	AWEzvContactManager *manager;
	ServiceController *__weak resolveServiceController;
	ServiceController *__weak imageServiceController;
	ServiceController *__weak addressServiceController;
}

@property (readwrite, copy, nonatomic) NSString *uniqueID;
@property (weak, readwrite, nonatomic) NSData *contactImageData;
@property (weak, readwrite, nonatomic) NSString *imageHash;
@property (readonly, nonatomic) AWEzvStatus status;
@property (weak, readonly, nonatomic) NSString *statusMessage;
@property (weak, readonly, nonatomic) NSDate *idleSinceDate;
@property (weak, readonly, nonatomic) NSString *name;

- (void)sendMessage:(NSString *)message withHtml:(NSString *)html;
- (NSString *) fixHTML:(NSString *)html;
- (void) sendTypingNotification:(AWEzvTyping)typingStatus;
- (void)sendOutgoingFileTransfer:(EKEzvOutgoingFileTransfer *)transfer;
@end
