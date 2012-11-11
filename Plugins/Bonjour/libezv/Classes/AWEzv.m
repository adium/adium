/*
 * Project:     Libezv
 * File:        AWEzv.m
 *
 * Version:     1.0
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004-2007 Andrew Wellington.
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

#import "AWEzv.h"

#import "AWEzvContact.h"

#import "EKEzvFileTransfer.h"
#import "EKEzvOutgoingFileTransfer.h"

/* Private classes - libezv use only */
#import "AWEzvContactManager.h"
#import "AWEzvContactManagerRendezvous.h"
#import "AWEzvContactManagerListener.h"

#import "AWEzvSupportRoutines.h"

@implementation AWEzv
- (id) initWithClient:(id <AWEzvClientProtocol, NSObject>)newClient 
{
	if ((self = [super init])) {
		client = newClient;
		name = nil;
		status = AWEzvUndefined;
	}	
    
    return self;
}

- (void) dealloc {
	//Ensure we log out before deallocing
	[self logout];
}

- (id <AWEzvClientProtocol, NSObject>) client {
    return client;
}

- (void) login {
    manager = [(AWEzvContactManager *)[AWEzvContactManager alloc] initWithClient:self];
    [manager listen];
    [manager login];
}

- (void) setName:(NSString *)newName {
	if (name != newName) {
		name = newName;
		[manager updatedName];
	}
}
- (void) setStatus:(AWEzvStatus)newStatus withMessage:(NSString *)message{
    status = newStatus;
    [manager setStatus:status withMessage:message];
}

- (void) setIdleTime:(NSDate *)date {
	if (!date) {
		idleTime = nil;
		status = AWEzvOnline;
	} else {
		idleTime = date;
		status = AWEzvIdle;
	}
    [manager updatedStatus];
}

- (void) sendMessage:(NSString *)message to:(NSString *)uniqueId withHtml:(NSString *)html {
    AWEzvContact *contact;
    
    contact = [manager contactForIdentifier:uniqueId];
	[contact sendMessage:message withHtml:html];
}

- (void) setContactImageData:(NSData *)contactImage {
	[manager setImageData: contactImage];
}

- (void) sendTypingNotification:(AWEzvTyping)typingStatus to:(NSString *)uniqueId {
    AWEzvContact *contact;
    
    contact = [manager contactForIdentifier:uniqueId];
    if (contact != nil) {
		[contact sendTypingNotification:typingStatus];
	}
}

- (void) sendTypeAhead:(NSString *)message to:(NSString *)contact withHtml:(NSString *)html {
    /* Not implemented yet */
}

- (void) logout
{
	AILogWithSignature(@"Manager is %@", manager);
	[manager logout];
	[manager stopListening];
	[manager stopBrowsing];
	[manager closeConnections];
}

- (void) sendFile:(NSString *)filename to:(NSString *)contact size:(size_t)size
{
    /* Not implemented yet */
}
- (void) startOutgoingFileTransfer:(EKEzvOutgoingFileTransfer *)transfer
{
	[transfer setManager:manager];
	[transfer startSending];
}

- (void) transferAccepted:(EKEzvFileTransfer *)transfer withFileName:(NSString *)fileName{
	/* Tell the EKEZvFileTransfer object to download!! */
	[transfer setLocalFilename: fileName];
	[transfer begin];
	
}
- (void)transferCancelled:(EKEzvFileTransfer *)transfer{
	[transfer cancel];
}

- (AWEzvContact *)contactForIdentifier:(NSString *)uniqueID {
    return [manager contactForIdentifier:uniqueID];
}

@end
