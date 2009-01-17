/*
 * Project:     Libezv
 * File:        AWEzvContactManagerRendezvous.m
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

#import "AWEzvContactManager.h"
#import "AWEzvContactManagerRendezvous.h"
#import "AWEzv.h"
#import "AWEzvPrivate.h"
#import "AWEzvContact.h"
#import "AWEzvContactPrivate.h"
#import "AWEzvRendezvousData.h"

#import "AWEzvSupportRoutines.h"

#include <dns_sd.h>

#include <openssl/sha.h>

/* One of the stupidest things I've ever met. Doing DNS lookups using the standard
 * functions does not for mDNS records work unless you're in BIND 8 compatibility
 * mode. And of course how do you get data from say a NULL record for iChat stuff?
 * With the standard DNS functions. So we have to use BIND 8 mode. Which means we
 * have to implement our own DNS packet parser. What were people thinking here?
 */
#define BIND_8_COMPAT 1
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <resolv.h>
#include <errno.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#include <SystemConfiguration/SystemConfiguration.h>
// The ServiceController manages cleanup of DNSServiceRef & runloop info for an outstanding request
@interface ServiceController : NSObject
{
	DNSServiceRef			fServiceRef;
	CFSocketRef				fSocketRef;
	CFRunLoopSourceRef		fRunloopSrc;
	AWEzvContactManager		*contactManager;
}

- (id)initWithServiceRef:(DNSServiceRef)ref forContactManager:(AWEzvContactManager *)inContactManager;
- (boolean_t)addToCurrentRunLoop;
- (void)breakdownServiceController;
- (DNSServiceRef)serviceRef;
@property (readonly, nonatomic) AWEzvContactManager *contactManager;

@end // interface ServiceController

/* C-helper function prototypes */
void register_reply ( 
    DNSServiceRef sdRef, 
    DNSServiceFlags flags, 
    DNSServiceErrorType errorCode, 
    const char *name, 
    const char *regtype, 
    const char *domain, 
    void *context );

static void ProcessSockData (
   CFSocketRef s,
   CFSocketCallBackType callbackType,
   CFDataRef address,
   const void *data,
   void *info
);

void handle_av_browse_reply ( 
    DNSServiceRef sdRef, 
    DNSServiceFlags flags, 
    uint32_t interfaceIndex, 
    DNSServiceErrorType errorCode, 
    const char *serviceName, 
    const char *regtype, 
    const char *replyDomain, 
    void *context );

void resolve_reply ( 
    DNSServiceRef sdRef, 
    DNSServiceFlags flags, 
    uint32_t interfaceIndex, 
    DNSServiceErrorType errorCode, 
    const char *fullname, 
    const char *hosttarget, 
    uint16_t port, 
    uint16_t txtLen, 
    const unsigned char *txtRecord, 
    void *context );

void AddressQueryRecordReply( DNSServiceRef DNSServiceRef, DNSServiceFlags flags, uint32_t interfaceIndex, 
								DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype, uint16_t rrclass, 
								uint16_t rdlen, const void *rdata, uint32_t ttl, void *context );
								
void ImageQueryRecordReply( DNSServiceRef DNSServiceRef, DNSServiceFlags flags, uint32_t interfaceIndex, 
								DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype, uint16_t rrclass, 
								uint16_t rdlen, const void *rdata, uint32_t ttl, void *context );	
								
void image_register_reply ( 
    DNSServiceRef sdRef, 
    DNSRecordRef RecordRef, 
    DNSServiceFlags flags, 
    DNSServiceErrorType errorCode, 
    void *context );							

@implementation AWEzvContactManager (Rendezvous)
#pragma mark Announcing Functions
- (void) login {
	regCount = 0;

	/* create data structure we'll advertise with */
	userAnnounceData = [[AWEzvRendezvousData alloc] init];
	/* set field contents of the data */
	[userAnnounceData setField:@"1st" content:[client name]];
	[userAnnounceData setField:@"email" content:@""];
	[userAnnounceData setField:@"ext" content:@""];
	[userAnnounceData setField:@"jid" content:@""];
	[userAnnounceData setField:@"last" content:@""];
	[userAnnounceData setField:@"msg" content:@""];
	[userAnnounceData setField:@"nick" content:@""];
	[userAnnounceData setField:@"node" content:@""];
	[userAnnounceData setField:@"AIM" content:@""];
	[userAnnounceData setField:@"email" content:@""];
	[userAnnounceData setField:@"port.p2pj" content:[NSString stringWithFormat:@"%u", port]];
	[userAnnounceData setField:@"txtvers" content:@"1"];
	[userAnnounceData setField:@"version" content:@"1"];

	[self setStatus:[client status] withMessage:nil];

	/* find username and computer name */
	CFStringRef consoleUser = SCDynamicStoreCopyConsoleUser(NULL, NULL, NULL);
	CFStringRef computerName = SCDynamicStoreCopyLocalHostName(NULL);
	if (!computerName) {
		/* computerName can return NULL if the computer name is not set or an error occurs */
		CFUUIDRef	uuid;

		uuid = CFUUIDCreate(NULL);
		computerName = CFUUIDCreateString(NULL, uuid);
		CFRelease(uuid);		
	}
    avInstanceName = [NSString stringWithFormat:@"%@@%@", (consoleUser ? (NSString *)consoleUser : @""), (computerName ? (NSString *)computerName : @"")];
	if (consoleUser) CFRelease(consoleUser);
	if (computerName) CFRelease(computerName);
	[avInstanceName retain];
    /* register service with mDNSResponder */

	DNSServiceRef servRef;
	DNSServiceErrorType dnsError;

	TXTRecordRef txtRecord;
	txtRecord = [userAnnounceData dataAsTXTRecordRef];

	dnsError = DNSServiceRegister(
			/* uninitialized service discovery reference */ &servRef, 
		    /* flags indicating how to handle name conflicts */ /* kDNSServiceFlagsNoAutoRename */ 0, 
		    /* interface on which to register, 0 for all available */ 0, 
		    /* service's name, may be null */ [avInstanceName UTF8String],
		    /* service registration type */ "_presence._tcp", 
		    /* domain, may be NULL */ NULL,
		    /* SRV target host name, may be NULL */ NULL,
		    /* port number in network byte order */ htons(port), 
		    /* length of txt record in bytes, 0 for NULL txt record */ TXTRecordGetLength(&txtRecord) , 
		    /* txt record properly formatted, may be NULL */ TXTRecordGetBytesPtr(&txtRecord) ,
		    /* call back function, may be NULL */ register_reply,
			/* application context pointer, may be null */ self);

	if (dnsError == kDNSServiceErr_NoError) {		
		fDomainBrowser = [[ServiceController alloc] initWithServiceRef:servRef forContactManager:self];
		[fDomainBrowser addToCurrentRunLoop];
		avDNSReference = servRef;
	} else {
		[[client client] reportError:@"Could not register DNS service: _presence._tcp" ofLevel:AWEzvConnectionError];
		[self disconnect];
	}
	TXTRecordDeallocate(&txtRecord);
}

/* this is used for a clean logout */
- (void) logout {
    [self disconnect];
}

/* this causes an actual disconnect */
- (void) disconnect {
	AILogWithSignature(@"Disconnecting");

	[fServiceBrowser release]; fServiceBrowser = nil;

	/* Remove Resolvers, this also deallocates the DNSServiceReferences */
	if (fDomainBrowser != nil) {
		AILogWithSignature(@"Releasing %@",fDomainBrowser);
		[fDomainBrowser release]; fDomainBrowser = nil;

		avDNSReference = nil;
		imageServiceRef = nil;
		
		[avInstanceName release]; avInstanceName = nil;
	}

	[self setConnected:NO];
}

- (void) setConnected:(BOOL)connected {
	if (isConnected != connected) {
		isConnected = connected;
		if (connected)
			[[client client] reportLoggedIn];
		else
			[[client client] reportLoggedOut];
	}
}

- (void)setStatus:(AWEzvStatus)status withMessage:(NSString *)message {
	NSString *statusString; /* string for use in Rendezous field */
	/* work out the string for rendezvous */
	switch (status) {
		case AWEzvIdle:
			statusString = @"away";
	    	break;
		case AWEzvAway:
			statusString = @"dnd";
			break;
		case AWEzvOnline:
			statusString = @"avail";
			break;
		default:
	    	/* if something weird, default to available */
			statusString = @"avail";
	}

	/* add it to our data */
	[userAnnounceData setField:@"status" content:statusString];

	/* now set the message */
	if ([message length]) {
		[userAnnounceData setField:@"msg" content:message];
	} else {
		[userAnnounceData deleteField:@"msg"];
	}

	/* check for idle */
	if ([client idleTime]) {
		[userAnnounceData setField:@"away" content:[NSString stringWithFormat:@"%f", [[client idleTime] timeIntervalSinceReferenceDate]]];
	} else {
		[userAnnounceData deleteField:@"away"];
	}

	/* announce to network */
	if (isConnected == YES)
		[self updateAnnounceInfo];
}

/* udpates information announced over network for user */
- (void) updateAnnounceInfo {
	DNSServiceErrorType updateError;
	TXTRecordRef txtRecord;

	if (!isConnected)
		return;

	if (avDNSReference == NULL) {
		[[client client] reportError:@"avDNSReference is null when trying to update the TXT Record" ofLevel:AWEzvWarning];
		return;
	}

	txtRecord = [userAnnounceData dataAsTXTRecordRef];
	AILogWithSignature(@"%@", [userAnnounceData dictionary]);
	updateError = DNSServiceUpdateRecord (
		/* serviceRef */ avDNSReference,
		/* recordRef, may be NULL */ NULL,
		/* Flags, currently ignored */ 0,
		/* length */ TXTRecordGetLength(&txtRecord),
		/* data */ TXTRecordGetBytesPtr(&txtRecord),
		/* time to live */ 0 );
	if (updateError != kDNSServiceErr_NoError) {		
		[[client client] reportError:@"Error updating TXT Record" ofLevel:AWEzvConnectionError];
		[self disconnect];
	}
	
	TXTRecordDeallocate(&txtRecord);
}

- (void) updatedName {
	[userAnnounceData setField:@"1st" content:[client name]];
	[self updateAnnounceInfo];
}

- (void) updatedStatus {
	[self setStatus:[client status] withMessage:[userAnnounceData getField:@"msg"]];
}

- (void)setImageData:(NSData *)JPEGData {
	DNSServiceErrorType error;
	SHA_CTX ctx;
	unsigned char digest[20];

	if (avDNSReference == NULL) {
		[[client client] reportError:@"Error setting image data" ofLevel:AWEzvWarning];
		return;
	}

	if (JPEGData == nil) {
		/* no image so remove record and update txt records*/
		error = DNSServiceRemoveRecord ( 
		    /* service reference */ avDNSReference, 
		    /* record reference */ imageRef, 
		    /* flags, ignored */ 0);
		if (error == kDNSServiceErr_NoError) {
			imageRef = nil;
			[userAnnounceData deleteField:@"phsh"];
			[self updateAnnounceInfo];
			return;
		}
	}

	if (imageRef != nil && JPEGData != nil) {
		/* Remove the old reference before updating the image. 
		 * This works around a bug experienced when updating the record to use an image that occupied more space
		 **/
		error = DNSServiceRemoveRecord ( 
		    /* service reference */ /*imageServiceRef*/avDNSReference, 
		    /* record reference */ imageRef, 
			/* flags, ignored */ 1);
		if (error != kDNSServiceErr_NoError) {
			[[client client] reportError:@"Error removing old image before setting new image" ofLevel:AWEzvWarning];
			return;
		} else {
			[userAnnounceData deleteField:@"phsh"];
			imageRef = nil;
		}
	}

	error = DNSServiceAddRecord (/*service reference */ avDNSReference, 
	                             /*record reference */ &imageRef, 
	                             /* flags, ignored */ 0, 
	                             /* type */ kDNSServiceType_NULL, 
	                             /* length */ [JPEGData length], 
	                             /* data */ [JPEGData bytes], 
	                             /* time to live; 0=default */ 0);

	if (error == kDNSServiceErr_NoError) {
		/* Let's create the hash */
		SHA1_Init(&ctx);
		SHA1_Update(&ctx, [JPEGData bytes], (unsigned long)[JPEGData length]);
		SHA1_Final(digest, &ctx);
		imagehash = [[NSData dataWithBytes:digest length:20] retain];
		AILogWithSignature(@"Will update with hash %@; length is %u", imagehash, [JPEGData length]);
		[self updatePHSH];
	} else {
		[[client client] reportError:@"Error adding image record" ofLevel:AWEzvWarning];
	}
}

- (void) updatePHSH {
	if (imagehash != nil) {
		[userAnnounceData setField:@"phsh" content:[imagehash autorelease]];
		/* announce to network */
		[self updateAnnounceInfo];
	} else {
		[userAnnounceData deleteField:@"phsh"];
	}
}

#pragma mark Browsing Functions
/* start browsing the network for new rendezvous clients */
- (void) startBrowsing {
	[fServiceBrowser release]; fServiceBrowser = nil;

	/* destroy old contact dictionary if one exists */
	[contacts release];

	/* allocate new contact dictionary */
	contacts = [[NSMutableDictionary alloc] init];

	/* create AV browser */
	DNSServiceRef browsRef;
	DNSServiceErrorType avBrowseError;

	avBrowseError = DNSServiceBrowse (/* uninitialized DNSServiceRef */ &browsRef,
	                                  /* flags, currently unused */ 0,
	                                  /* interface index, 0 for all available */ 0,
	                                  /* registration type */ "_presence._tcp",
	                                  /* domain, may be null for default */ NULL,
	                                  /* callBack function */ handle_av_browse_reply,
	                                  /* context, may be null */ self);

	if (avBrowseError == kDNSServiceErr_NoError) {
		fServiceBrowser = [[ServiceController alloc] initWithServiceRef:browsRef forContactManager:self];
		[fServiceBrowser addToCurrentRunLoop];
	} else {
		[[client client] reportError:@"Could not browse for _presence._tcp instances" ofLevel:AWEzvConnectionError];
		[self disconnect];
	}
}

/* stop looking for new rendezvous clients */
- (void)stopBrowsing{
	AILogWithSignature(@"fServiceBrowser is %@ (retain count %i)", fServiceBrowser, [fServiceBrowser retainCount]);
	[fServiceBrowser release]; fServiceBrowser = nil;
}

/* handle a message from our browser */
- (void)browseResultwithFlags:(DNSServiceFlags)flags
	onInterface:(uint32_t) interfaceIndex
	name:(const char *)replyName
	type:(const char *)replyType
	domain:(const char *)replyDomain
	av:(BOOL) av {
	
	AWEzvContact *contact;
	if (!replyName)
		return;

	NSString *replyNameString = [NSString stringWithUTF8String:replyName];
	if (!replyNameString)
		return;
	if (flags == (kDNSServiceFlagsAdd) || flags == (kDNSServiceFlagsMoreComing | kDNSServiceFlagsAdd)) {
		/* Add this contact */
		/* initialise contact */
		contact = [[AWEzvContact alloc] init];
		[contact setUniqueID:replyNameString];
		[contact setManager:self];
		/* save contact in dictionary */
		[contacts setObject:contact forKey:replyNameString];
		[contact autorelease];

		/* and resolve contact */
		DNSServiceRef resolveRef;
		DNSServiceErrorType resolveRefError;

		resolveRefError = DNSServiceResolve (
			/* serviceref uninitialized */ &resolveRef,
			/* flags, currently ignored */ 0,
			/* interfaceIndex */ 0/*interfaceIndex*/,
			/* full name */ replyName,
			/* registration type */ "_presence._tcp" /* replyType */,
			/* domain */ replyDomain,
			/* callback */ resolve_reply,
			/* contxt, may be NULL */ contact);

		if (resolveRefError == kDNSServiceErr_NoError) {
			ServiceController *serviceResolver = [[ServiceController alloc] initWithServiceRef:resolveRef forContactManager:self];
			[contact setResolveServiceController:serviceResolver];
			[[contact resolveServiceController] addToCurrentRunLoop];
			[serviceResolver release];

		} else {
			[[client client] reportError:@"Could not search for TXT records" ofLevel:AWEzvConnectionError];
			[self disconnect];
		}
	} else {
		/* delete the contact */
		contact = [contacts objectForKey:replyNameString];
		if (!contact)
			return;
		[[client client] userLoggedOut:contact];
		/* remove the contact from our data structures */
		[contacts removeObjectForKey:replyNameString];
		return;
	}
}
- (void)findAddressForContact:(AWEzvContact *)contact
	withHost:(NSString *)host
	withInterface:(uint32_t)interface{

	/* Now we need to query the record for the ip address */

	DNSServiceErrorType err;
	DNSServiceRef		serviceRef;

	err = DNSServiceQueryRecord( &serviceRef, (DNSServiceFlags) 0, interface, [host UTF8String], 
	                             kDNSServiceType_A, kDNSServiceClass_IN, AddressQueryRecordReply, contact);
	if ( err == kDNSServiceErr_NoError) {
		ServiceController *temp = [[ServiceController alloc] initWithServiceRef:serviceRef forContactManager:self];
		[contact setAddressServiceController:temp];
		[[contact addressServiceController] addToCurrentRunLoop];
		[temp release];
	} else {
		[[client client] reportError:@"Error finding adress for contact" ofLevel:AWEzvError];
	}
}

- (void)updateAddressForContact:(AWEzvContact *)contact
	addr:(const void *)buff 
	addrLen:(uint16_t)addrLen 
	host:(const char*) host 
	interfaceIndex:(uint32_t)interface 
	more:(boolean_t)moreToCome{

	/* check that contact exists in dictionary */
	if ([contacts objectForKey:[contact uniqueID]] == nil) {
		NSString *uniqueID = [contact uniqueID];
		/* So they haven't been seen before... not to worry we'll add them */
		if ([contact uniqueID] != nil) {
			contact = [[AWEzvContact alloc] init];
			[contact setUniqueID:uniqueID];
			[contact setManager:self];
			/* save contact in dictionary */
			[contacts setObject:contact forKey:[contact uniqueID]];
			[contact autorelease];

		} else {
			[[client client] reportError:@"Contact to update not in dictionary and has bad identifier" ofLevel:AWEzvError];
		}
	}

	NSString *ipAddr;			/* ip address of contact */
	NSRange	range;				/* just a range... */
    
	char addrBuff[256];
	
	inet_ntop( AF_INET, buff, addrBuff, sizeof addrBuff);

	ipAddr = [NSString stringWithCString:addrBuff encoding:NSUTF8StringEncoding];
    range = [ipAddr rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    if (range.location == NSNotFound) {
		[contact setIpaddr:ipAddr];
	}

	if (![contact ipaddr] || ![[contact ipaddr] length]) {
		[[client client] reportError:@"ip address not set" ofLevel:AWEzvError];
		[contact setStatus: AWEzvUndefined];
	}

	if (!moreToCome) {
		[contact setAddressServiceController: nil];
	}
}

- (void)updateImageForContact:(AWEzvContact *)contact
	data:(const void *)data 
	dataLen:(uint16_t)dataLen
	more:(boolean_t)moreToCome{

	if (!moreToCome) {
		[contact setImageServiceController: nil];
	}
	AILogWithSignature(@"%@ -> %@ (%i)", [NSData dataWithBytes:data length:dataLen], [[[NSImage alloc] initWithData:[NSData dataWithBytes:data length:dataLen]] autorelease], dataLen);
	if (dataLen != 0 ) {
		/* We have an image */
		/* parse raw Data */
		[contact setContactImageData:[NSData dataWithBytes:data length:dataLen]];
	    [[client client] userChangedImage:contact];

	} else {
		[contact setImageHash: NULL];
		[[client client] reportError:@"Error retrieving picture" ofLevel:AWEzvError];
	}
}
- (void)updateContact:(AWEzvContact *)contact
	withData:(AWEzvRendezvousData *)rendezvousData
	withHost:(NSString *)host
	withInterface:(uint32_t)interface
	withPort:(uint16_t)recPort
	av:(BOOL)av {

	NSString		*nick = nil;			/* nickname for contact */
	NSMutableString	*mutableNick = nil;		/* nickname we can modify */
	AWEzvRendezvousData	*oldrendezvous;			/* old rendezvous data for user */ /* XXX not used */
	NSNumber           *idleTime = nil;			/* idle time */

	/* check that contact exists in dictionary */
	if ([contacts objectForKey:[contact uniqueID]] == nil) {
		NSString *uniqueID = [contact uniqueID];
		/* So they haven't been seen before... not to worry we'll add them */
		if ([contact uniqueID] != nil) {
			contact = [[AWEzvContact alloc] init];
			[contact setUniqueID:uniqueID];
			[contact setManager:self];
			/* save contact in dictionary */
			[contacts setObject:contact forKey:[contact uniqueID]];
			[contact autorelease];
		} else {
			[[client client] reportError:@"Contact to update not in dictionary and has bad identifier" ofLevel:AWEzvError];
		}
	}

	if ([rendezvousData getField:@"slumming"] != nil)
		// We don't want to live in a slum
		return;

	if ([contact rendezvous] != nil) {
		oldrendezvous = [contact rendezvous];
		/* check serials */
		if ([contact serial] > [contact serial]) {
			/* AWEzvLog(@"Rendezvous update for %@ with lower serial, updating anyway", [contact uniqueID]); */
			/* we'll update anyway, and hopefully we'll be back in sync with the network */
		}
	}
	[contact setRendezvous:rendezvousData];
	
	/* now we can update the contact */
	/* get the nickname */
	if ([rendezvousData getField:@"1st"] != nil)
	nick = [rendezvousData getField:@"1st"];
	if ([rendezvousData getField:@"last"] != nil)
	if (nick == nil) {
		nick = [rendezvousData getField:@"last"];
	} else {
		mutableNick = [[nick mutableCopy] autorelease];
		[mutableNick appendString:@" "];
		[mutableNick appendString:[rendezvousData getField:@"last"]];
		nick = [[mutableNick copy] autorelease];
	} else if (nick == nil)
	    nick = @"Unnamed contact";

	[contact setName:nick];

	/* now get the status */
	if ([rendezvousData getField:@"status"] == nil) {
		[contact setStatus: AWEzvOnline];
	} else {
		if ([[rendezvousData getField:@"status"] isEqualToString:@"avail"])
			[contact setStatus: AWEzvOnline];
		else if ([[rendezvousData getField:@"status"] isEqualToString:@"dnd"])
			[contact setStatus: AWEzvAway];
		else if ([[rendezvousData getField:@"status"] isEqualToString:@"away"])
			[contact setStatus: AWEzvIdle];
		else
			[contact setStatus: AWEzvOnline];
	}
	
	/* Set idle time */
	if ([rendezvousData getField:@"away"])
		idleTime = [NSNumber numberWithLong:strtol([[rendezvousData getField:@"away"] UTF8String], NULL, 0)];
	if (idleTime)
		[contact setIdleSinceDate: [NSDate dateWithTimeIntervalSinceReferenceDate:[idleTime doubleValue]]];
	
	/* Update Buddy Icon */
	if ([rendezvousData getField:@"phsh"] != nil) {
		/* We should check to see if this is a new phsh */
		NSString *hash = [contact imageHash];
		NSString *newHash = [rendezvousData getField:@"phsh"];
		AILogWithSignature(@"received image hash %@ for %@", newHash, contact);
		if (hash == NULL || [newHash compare: hash] != NSOrderedSame) {
			[contact setImageHash: newHash];	
			/* The two hashes are different or there was no image before so there is an image to be downloaded */
			/* Download the image using DNSServiceQueryRecord */
			DNSServiceErrorType err;
			DNSServiceRef		serviceRef;

			NSString *dnsname = [NSString stringWithFormat:@"%@%s", [contact uniqueID],"._presence._tcp.local."];
			err = DNSServiceQueryRecord( &serviceRef, (DNSServiceFlags) 0, interface, [dnsname UTF8String], 
			                            kDNSServiceType_NULL, kDNSServiceClass_IN, ImageQueryRecordReply, contact);
			if ( err == kDNSServiceErr_NoError) {
				ServiceController *temp = [[ServiceController alloc] initWithServiceRef:serviceRef forContactManager:self];
				AILogWithSignature(@"requesting image with %@", temp);
				[contact setImageServiceController:temp];
				[[contact imageServiceController] addToCurrentRunLoop];
				[temp release];
			} else {
				[contact setImageHash: NULL];
				[[client client] reportError:@"Error finding image for contact" ofLevel:AWEzvError];
			}
		}
	} else {
		[contact setContactImageData:nil];
		[[client client] userChangedImage:contact];
	}

	/* now set the port */
	if (recPort == 0) {
		/* Couldn't find port from browse result so use port specified by txt records */
		if ([rendezvousData getField:@"port.p2pj"] == nil) {
			[[client client] reportError:@"Invalid rendezvous announcement for contact: no port specified" ofLevel:AWEzvError];
			return;
		}
		[contact setPort:[[rendezvousData getField:@"port.p2pj"] intValue]];
	} else {
		/* Correctly use port specified by SRV record */
		[contact setPort:recPort];
	}
	/* and notify of new user */
	[[client client] userChangedState:contact];
}

- (NSString *)myInstanceName{
	return avInstanceName;
}

- (void)setInstanceName:(NSString *)newName{
	if (avInstanceName != newName) {
		[avInstanceName release];
		avInstanceName = [newName retain];
	}
}

- (void) regCallBack:(int)errorCode {
	/* Recover if there was an error */
    if (errorCode != kDNSServiceErr_NoError) {
		switch (errorCode) {
#warning Localize and report through the connection error system
			case kDNSServiceErr_Unknown:
				[[[self client] client] reportError:@"Unknown error in Bonjour Registration"
						        ofLevel:AWEzvConnectionError];
				break;
			case kDNSServiceErr_NameConflict:
				[[[self client] client] reportError:@"A user with your Bonjour data is already online"
						        ofLevel:AWEzvConnectionError];
				break;
			default:
				[[[self client] client] reportError:@"An internal error occurred"
						        ofLevel:AWEzvConnectionError];
				AWEzvLog(@"Internal error: rendezvous code %d", errorCode);
				break;
		}
		/* kill connections */
		[self disconnect];
	} else {
		[self setConnected:YES];
		[self startBrowsing];
	}

}

- (void)contactWillDeallocate:(AWEzvContact *)contact
{
	[[client client] userLoggedOut:contact];
}

- (void)serviceControllerReceivedFatalError:(ServiceController *)serviceController
{
	[[[self client] client] reportError:@"An unrecoverable connection error occurred"
						        ofLevel:AWEzvConnectionError];
	[self disconnect];
}

@end

#pragma mark mDNS callbacks

#pragma mark mDNS Register Callbacks
void register_reply (DNSServiceRef sdRef, DNSServiceFlags flags, DNSServiceErrorType errorCode, const char *name, const char *regtype, const char *domain, void *context ) {
	AWEzvContactManager *self = context;
	[self setInstanceName:[NSString stringWithUTF8String:name]];
	[self regCallBack:errorCode];
}

void image_register_reply ( 
	DNSServiceRef sdRef, 
	DNSRecordRef RecordRef, 
	DNSServiceFlags flags, 
	DNSServiceErrorType errorCode, 
	void *context ) {
	if (errorCode != kDNSServiceErr_NoError) {
		AWEzvLog(@"error %d registering image record", errorCode);
	} else {
		AWEzvContactManager *self = context;
		[self updatePHSH];
	}
}
#pragma mark mDNS Browse Callback

/*!
 * @brief DNSServiceBrowse callback
 *
 * This may be called multiple times for a single use of DNSServiceBrowse().
 */
void handle_av_browse_reply (DNSServiceRef sdRef,
		DNSServiceFlags flags,
		uint32_t interfaceIndex,
		DNSServiceErrorType errorCode,
		const char *serviceName,
		const char *regtype,
		const char *replyDomain,
		void *context ) {
	/* Received a browser reply from DNSServiceBrowse for av, now must handle processing the list of results */
	if (errorCode == kDNSServiceErr_NoError) {
		AWEzvContactManager *self = context;
	    if (![[self myInstanceName] isEqualToString:[NSString stringWithUTF8String:serviceName]])
			[self browseResultwithFlags:flags onInterface:interfaceIndex name:serviceName type:regtype domain:replyDomain av:YES];
	} else {
		AWEzvLog(@"Error browsing");
	}
}

#pragma mark mDNS Resolve Callback
/*!
* @brief DNSServiceResolve callback
 *
 * This may be called multiple times for a single use of DNSServiceResolve().
 */
void resolve_reply (DNSServiceRef sdRef, 
					DNSServiceFlags flags, 
					uint32_t interfaceIndex, 
					DNSServiceErrorType errorCode, 
					const char *fullname, 
					const char *hosttarget, 
					uint16_t port, 
					uint16_t txtLen, 
					const unsigned char *txtRecord, 
					void *context)
{
	if (errorCode == kDNSServiceErr_NoError) {
		/* use TXTRecord methods to resolve this */
		AWEzvContact	*contact = context;
		AWEzvContactManager *self = [contact manager];
		//AWEzvLog(@"Would update contact");
		AWEzvRendezvousData *data;
		data = [[[AWEzvRendezvousData alloc] initWithTXTRecordRef:txtRecord length:txtLen] autorelease];
		[self findAddressForContact:contact withHost:[NSString stringWithUTF8String:hosttarget] withInterface:interfaceIndex];
		[self updateContact:contact withData:data withHost:[NSString stringWithUTF8String:hosttarget] withInterface:interfaceIndex withPort:ntohs(port) av:YES];

	} else {
		AWEzvLog(@"Error resolving records");
	}	
}

#pragma mark mDNS Address Callback

void AddressQueryRecordReply( DNSServiceRef DNSServiceRef, DNSServiceFlags flags, uint32_t interfaceIndex, 
								DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype, uint16_t rrclass, 
								uint16_t rdlen, const void *rdata, uint32_t ttl, void *context )
// DNSServiceQueryRecord callback used to look up IP addresses.
{
	AWEzvContact	*contact = context;
	AWEzvContactManager *self = [contact manager];

	[self updateAddressForContact:contact addr:rdata addrLen:rdlen host:fullname interfaceIndex:interfaceIndex 
						more:((flags & kDNSServiceFlagsMoreComing) != 0)];

}

#pragma mark mDNS Image Callback
void ImageQueryRecordReply( DNSServiceRef DNSServiceRef, DNSServiceFlags flags, uint32_t interfaceIndex, 
								DNSServiceErrorType errorCode, const char *fullname, uint16_t rrtype, uint16_t rrclass, 
								uint16_t rdlen, const void *rdata, uint32_t ttl, void *context )
// DNSServiceQueryRecord callback used to look up buddy icon.
{
	AWEzvContact	*contact = context;
	AWEzvContactManager *self = [contact manager];
	if (errorCode == kDNSServiceErr_NoError) {
		if (flags & kDNSServiceFlagsAdd)
			[self updateImageForContact:contact data:rdata dataLen:rdlen more:((flags & kDNSServiceFlagsMoreComing) != 0)];
	}
}

#pragma mark Service Controller

/* ServiceController was taken from Apple's DNSServiceBrowser.m */
@implementation ServiceController : NSObject

#pragma mark CFSocket Callback
/* This code was taken from Apple's DNSServiceBrowser.m */
static void	ProcessSockData( CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
// CFRunloop callback that notifies dns_sd when new data appears on a DNSServiceRef's socket.
{
	ServiceController *self = (ServiceController *)info;
	AILogWithSignature(@"Processing result for %@", self);

	DNSServiceErrorType err = DNSServiceProcessResult([self serviceRef]);
	if (err != kDNSServiceErr_NoError) {
		if ((err == kDNSServiceErr_Unknown) && !data) {
			//Try to accept(2) a connection. May be the cause of a hang on Tiger; see #7887.
			int socketFD = CFSocketGetNative(s);
			int childFD = accept(socketFD, /*addr*/ NULL, /*addrlen*/ NULL);
			AILog(@"%@: Service ref %p received an unknown error with no data; perhaps mDNSResponder crashed? Result of calling accept(2) on fd %d is %d; will disconnect with error",
				  self, [self serviceRef], socketFD, childFD);
			//We don't actually *want* a connection, so close the socket immediately.
			if (childFD > -1) close(childFD);

			[self retain];
			[[self contactManager] serviceControllerReceivedFatalError:self];
			[self breakdownServiceController];
			[self release];

		} else {
			AILog(@"DNSServiceProcessResult() for socket descriptor %d returned an error! %d with CFSocketCallBackType %d and data %s\n",
				  DNSServiceRefSockFD(info), err, type, data);
		}
	}
}

- (id) initWithServiceRef:(DNSServiceRef) ref forContactManager:(AWEzvContactManager *)inContactManager
{
	[super init];
	fServiceRef = ref;
	contactManager = [inContactManager retain];

	return self;
}

- (boolean_t) addToCurrentRunLoop
/* Add the service to the current runloop. Returns non-zero on success. */
{
	CFSocketContext			ctx = { 1, self, NULL, NULL, NULL };

	fSocketRef = CFSocketCreateWithNative(kCFAllocatorDefault, DNSServiceRefSockFD(fServiceRef),
										kCFSocketReadCallBack, ProcessSockData, &ctx);
	if (fSocketRef != NULL)
		fRunloopSrc = CFSocketCreateRunLoopSource(kCFAllocatorDefault, fSocketRef, 1);
	if (fRunloopSrc != NULL) {
		AILogWithSignature(@"Adding run loop source %p from run loop %p", fRunloopSrc, CFRunLoopGetCurrent());
		CFRunLoopAddSource(CFRunLoopGetCurrent(), fRunloopSrc, kCFRunLoopDefaultMode);
	} else
		AILog(@"%@: Could not listen to runloop socket", self);

	return (fRunloopSrc != NULL);
}

- (DNSServiceRef) serviceRef
{
	return fServiceRef;
}

- (AWEzvContactManager *)contactManager
{
	return contactManager;
}

- (void) dealloc
/* Remove service from runloop, deallocate service and associated resources */
{
	AILogWithSignature(@"%@", self);

	[self breakdownServiceController];

	[super dealloc];
}

- (void)breakdownServiceController
{
	AILogWithSignature(@"%@", self);

	if (fSocketRef != NULL) {
		CFSocketInvalidate(fSocketRef);		// Note: Also closes the underlying socket
		CFRelease(fSocketRef);
		fSocketRef = NULL;
	}

	if (fRunloopSrc != NULL) {
		AILogWithSignature(@"Removing run loop source %p from run loop %p", fRunloopSrc, CFRunLoopGetCurrent());
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), fRunloopSrc, kCFRunLoopDefaultMode);
		CFRelease(fRunloopSrc);
		fRunloopSrc = NULL;
	}

	if (fServiceRef) {
		AILogWithSignature(@"Deallocating DNSServiceRef %p", fServiceRef);

		DNSServiceRefDeallocate(fServiceRef);
		fServiceRef = NULL;
	}

	[contactManager release]; contactManager = nil;
}

@end // implementation ServiceController
