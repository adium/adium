/*
 * Project:     Libezv
 * File:        AWEzv.h
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
#import "EKEzvOutgoingFileTransfer.h"

@class AWEzvContact, AWEzvContactManager;

@protocol AWEzvClientProtocol <NSObject>
- (void) reportLoggedIn;
- (void) reportLoggedOut;
- (void) userLoggedOut:(AWEzvContact *)contact;
- (void) userChangedState:(AWEzvContact *)contact;
- (void) userChangedImage:(AWEzvContact *)contact;
- (void) user:(AWEzvContact *)contact sentMessage:(NSString *)message withHtml:(NSString *)html;
- (void) user:(AWEzvContact *)contact typingNotification:(AWEzvTyping)typingStatus;
- (void) user:(AWEzvContact *)contact typeAhead:(NSString *)message withHtml:(NSString *)html;

// File Transfer
- (void)updateProgressForFileTransfer:(EKEzvFileTransfer *)fileTransfer percent:(NSNumber *)percent bytesSent:(NSNumber *)bytesSent;
- (void)remoteCanceledFileTransfer:(EKEzvFileTransfer *)fileTransfer;
- (void)transferFailed:(EKEzvFileTransfer *)fileTransfer;
// Incoming File Transfer
- (void)user:(AWEzvContact *)contact sentFile:(EKEzvFileTransfer *)fileTransfer;
// Outgoing File Transfer
- (void)remoteUserBeganDownload:(EKEzvOutgoingFileTransfer *)fileTransfer;
- (void)remoteUserFinishedDownload:(EKEzvOutgoingFileTransfer *)fileTransfer;

- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity;
- (void) reportError:(NSString *)error ofLevel:(AWEzvErrorSeverity)severity forUser:(NSString *)contact;

@end

@interface AWEzv : NSObject {
    id <AWEzvClientProtocol> client;
    AWEzvContactManager *manager;
    
    NSString *name;
    AWEzvStatus status;
    NSDate *idleTime;
}

- (id) initWithClient:(id <AWEzvClientProtocol, NSObject>)newClient;

- (void) login;
- (void) logout;
- (id <AWEzvClientProtocol, NSObject>) client;
- (void) sendMessage:(NSString *)message to:(NSString *)contact withHtml:(NSString *)html;
- (void) sendTypingNotification:(AWEzvTyping)typingStatus to:(NSString*)contact;
- (void) sendTypeAhead:(NSString *)message to:(NSString *)contact withHtml:(NSString *)html;
- (void) setName:(NSString *)name;
- (void) setStatus:(AWEzvStatus)status withMessage:(NSString *)message;
- (void) setIdleTime:(NSDate *)date;
- (void) setContactImageData:(NSData *)contactImage;
- (AWEzvContact *) contactForIdentifier:(NSString *)uniqueID;

// This API is subject to change
- (void) sendFile:(NSString *)filename to:(NSString *)contact size:(size_t)size;

- (void) startOutgoingFileTransfer:(EKEzvOutgoingFileTransfer *)transfer;
- (void)transferCancelled:(EKEzvFileTransfer *)transfer;
- (void) transferAccepted:(EKEzvFileTransfer *)transfer withFileName:(NSString *)fileName;
@end
