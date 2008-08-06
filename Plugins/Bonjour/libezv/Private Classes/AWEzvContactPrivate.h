/*
 * Project:     Libezv
 * File:        AWEzvContactPrivate.h
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

#import <Foundation/Foundation.h>
#import <AWEzvContact.h>

@class AWEzvXMLNode;

@interface AWEzvContact (Private)
- (void) setStream:(AWEzvXMLStream *)stream;
- (AWEzvXMLStream *)stream;
- (void) setStatus:(AWEzvStatus) status;
- (void) setIdleSinceDate:(NSDate *) idleSince;

- (void)setName:(NSString *)name;

- (void) setRendezvous:(AWEzvRendezvousData *)rendezvous;
- (AWEzvRendezvousData *) rendezvous;
- (NSString *)ipaddr;
- (void) setIpaddr:(NSString *)myipaddr;
- (u_int16_t) port;
- (void) setPort:(u_int16_t)port;

- (void) setManager:(AWEzvContactManager *)manager;
- (AWEzvContactManager *) manager;

- (void) setResolveServiceController:(ServiceController *)controller;
- (ServiceController *) resolveServiceController;

- (void) setImageServiceController:(ServiceController *)controller;
- (ServiceController *) imageServiceController;

- (void) setAddressServiceController:(ServiceController *)controller;
- (ServiceController *) addressServiceController;

- (int) serial;

- (void)createConnection;

- (void) XMLReceivedMessage:(AWEzvXMLNode *)root;
- (void) XMLCheckForEvent:(AWEzvXMLNode *)node;
- (void) XMLCheckForOOB:(AWEzvXMLNode *)node;
- (void)evaluteURLXML:(AWEzvXMLNode *)node;
@end
