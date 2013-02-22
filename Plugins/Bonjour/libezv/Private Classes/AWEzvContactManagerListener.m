/*
 * Project:     Libezv
 * File:        AWEzvContactManagerListener.m
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
#import "AWEzvContactManager.h"
#import "AWEzvContact.h"
#import "AWEzvContactPrivate.h"
#import "AWEzv.h"

/* socket functions */
#import <arpa/inet.h>

#define	MAXBACKLOG	5

@interface AWEzvContactManager (Listener_Private)
- (void)connectionReceived:(NSNotification *)aNotification;
@end

@implementation AWEzvContactManager (Listener)
/* start listening for incoming connections
   return value: port we're listening to */
- (unsigned int)listen {
	int			fd;		/* file descriptor for listening socket */
	struct sockaddr_in	serverAddress;	/* server address structure             */
	
	int temp;         /* used to pass to routines that want a pointer to an int */
	
	port = 5298;      /* default iChat port */
	
	/* NSFileHandle's acceptConnectionInBackgroundAndNotify method expects a
	   socket that is bound and listening */

	if ((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
		[[client client] reportError:@"Could not create listening socket for iChat Bonjour" ofLevel:AWEzvConnectionError];
		return -1;
	}

	/* setup server address structure */
	memset(&serverAddress, 0, sizeof(serverAddress));
	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
	serverAddress.sin_port = htons(port);

	/* here we just keep trying to bind ports from the port number up. When one
	   succeeds we can go ahead and advertise using it. We still use SO_REUSEADDR
	   in the socket options however, as iChat appears to like it better if we use
	   port 5298 when possible */
	temp = 1;
	if (setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &temp, sizeof(temp)) < 0) {
		[[client client] reportError:@"Could not set socket to SO_REUSEADDR" ofLevel:AWEzvWarning];

	}
	while (bind(fd, (struct sockaddr *)&serverAddress, sizeof(serverAddress)) < 0) {
		port++;
		serverAddress.sin_port = htons(port);
	}

	/* now to create file handle to accept incoming connections */
	if (listen(fd, MAXBACKLOG) == 0) {
		listenSocket = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:YES];
	}

	/* and start to listen on the port */
	[[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(connectionReceived:)
					  name:NSFileHandleConnectionAcceptedNotification
					  object:listenSocket];
	[listenSocket acceptConnectionInBackgroundAndNotify];

	/* return the port we're listening on */
	return port;
}

- (void) stopListening {
    if (listenSocket != nil) {
		[listenSocket closeFile];
		listenSocket = nil;
    }
}

/* notification from listenSocket that we've got a connection to handle */
- (void)connectionReceived:(NSNotification *)aNotification {
	AILog(@"%s: Got notification with name %@; userInfo is:\n%@", __PRETTY_FUNCTION__, [aNotification name], [aNotification userInfo]);
	NSFileHandle 	*incomingConnection = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
	NSString		*ipAddr;
	NSMutableString	*contactIdentifier;
	int			fd;
	socklen_t	size;
	struct sockaddr_in	remoteAddress;
	AWEzvXMLStream      *stream;
	AWEzvContact	*contact;

	/* get details of incoming connection */
	fd = [incomingConnection fileDescriptor];
	size = sizeof(remoteAddress);
	if (getpeername(fd, (struct sockaddr *)&remoteAddress, &size) == -1) {
		// [[client client] reportError:@"Could not get socket name" ofLevel:AWEzvError];
		[incomingConnection closeFile];
		return;
	}

	/* we have to ask it to keep accepting connections now */
	[[aNotification object] acceptConnectionInBackgroundAndNotify];

	ipAddr = [NSString stringWithUTF8String:inet_ntoa((&remoteAddress)->sin_addr)];

	AILog(@"%s: Remote IP address (basis of contactIdentifier) is %@", __PRETTY_FUNCTION__, ipAddr);
	contactIdentifier = [ipAddr mutableCopy];
	[contactIdentifier replaceOccurrencesOfString:@"."
		       withString:@"_"
		       options:NSLiteralSearch
		       range:NSMakeRange(0, [contactIdentifier length])];
		       
	contact = [contacts objectForKey:contactIdentifier];
	AILog(@"%s: Looked in contacts for contactIdentifier %@; got %@", __PRETTY_FUNCTION__, contactIdentifier, contact);
	/* Discover the appropriate record if required */
	if ([contact rendezvous] == nil) {

		for (contact in [contacts allValues]) {
			AILog(@"%s: Searching contacts; rendezvous is %@ and ipaddr is %@", __PRETTY_FUNCTION__, contact.rendezvous, contact.ipAddr);
			if ([contact rendezvous] != nil && [contact.ipAddr isEqualToString:ipAddr])
				break;
		}
		
		if (!contact)  {
			/* We couldn't find an existing contact... but clearly we're getting a connection from someone. Create a contact
			 * and add it to the contacts dictionary.
			 */
			contact = [[AWEzvContact alloc] init];
			
			contact.ipAddr = ipAddr;
			
			[contact setUniqueID:contactIdentifier];
			[contact setManager:self];
			/* save contact in dictionary */
			[contacts setObject:contact forKey:contactIdentifier];
		}
	}

	if (contact == nil) {
		[[client client] reportError:[NSString stringWithFormat:@"Incoming connection from non-existent contact %@.", contactIdentifier] ofLevel:AWEzvError];

		[incomingConnection closeFile];
		return;
	}
	
	stream = [[AWEzvXMLStream alloc] initWithFileHandle:incomingConnection initiator:0];
	[stream setDelegate:contact];
	contact.stream = stream;
	[stream readAndParse];

	return;
}

@end
