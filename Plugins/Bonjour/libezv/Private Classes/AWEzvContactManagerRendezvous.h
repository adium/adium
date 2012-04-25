/*
 * Project:     Libezv
 * File:        AWEzvContactManagerRendezvous.h
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

/* IMPORTANT NOTE:
 * The rendezvous part of this library is implemented using the low-level Mach
 * port messaging to the mDNSResponser due to bugs in NSNetService. These bugs
 * include the inability to modify the TXT record of an advertised service, when
 * a service is no longer being published TXT records associated with the
 * service are not released and the inability to observe changes in the TXT
 * records of others.Until these bugs are fixed, we will continue to use the
 * Mach messaging interface to mDNSResponder (or another interface with similar
 * capabilities) instead of NSNetService/NSNetServiceBrowser
 */

#import "AWEzvContactManager.h"
#import "AWEzvDefines.h"

@interface AWEzvContactManager (Rendezvous)
	
- (void) login;
- (void) logout;
- (void) disconnect;
- (void) setConnected:(BOOL)connected;

- (void) setStatus:(AWEzvStatus)status withMessage:(NSString *)message;
- (void) updateAnnounceInfo;
- (void) updatedName;
- (void) updatedStatus;
- (void) setImageData:(NSData *)JPEGData;

- (NSString *)myInstanceName;

- (void) startBrowsing;
- (void) stopBrowsing;

- (void)browseResultwithFlags:(DNSServiceFlags)flags
				  onInterface:(uint32_t) interfaceIndex
						 name:(const char *)replyName
						 type:(const char *)replyType
					   domain:(const char *)replyDomain
						   av:(BOOL) av;

- (void)updateContact:(AWEzvContact *)iccontact
			 withData:(AWEzvRendezvousData *)rendezvousData
			 withHost:(NSString *)host
		withInterface:(uint32_t)interface
			 withPort:(uint16_t)recPort
				   av:(BOOL)av;

- (void)findAddressForContact:(AWEzvContact *)contact
					 withHost:(NSString *)host
				withInterface:(uint32_t)interface;

- (void)updateAddressForContact:(AWEzvContact *)contact
						   addr:(const void *)buff
						addrLen:(uint16_t)addrLen
						   host:(const char*) host
				 interfaceIndex:(uint32_t)interface
						   more:(boolean_t)moreToCome;

- (void)updateImageForContact:(AWEzvContact *)contact
						 data:(const void *)buff
					  dataLen:(uint16_t)addrLen
						 more:(boolean_t)moreToCome;

- (void) updatePHSH;

// REALLY PRIVATE STUFF
- (void) setInstanceName:(NSString *)newName;
- (void) regCallBack:(int)errorCode;

- (void) contactWillDeallocate:(AWEzvContact *)contact;

@end
