/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/*
    Cocoa wrapper of low level sockets
*/

#import "AISocket.h"
#include <unistd.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

@interface AISocket (PRIVATE)
- (id)initWithHost:(NSString *)host port:(int)port;
- (BOOL)readyForSending;
- (BOOL)readyForReceiving;
@end

@implementation AISocket

//-------------------
//  Public Methods
//-----------------------
+ (AISocket *)socketWithHost:(NSString *)host port:(int)port
{
    return [[[self alloc] initWithHost:host port:port] autorelease];
}

- (BOOL)isValid
{
    return isValid;
}

//Send data
- (BOOL)sendData:(NSData *)inData
{
    BOOL success = NO;

    //If we are ready for sending, send out the buffer contents
    if ([self readyForSending]) {
        const char		*bytes = [inData bytes];
        int			length = [inData length];
        int			bytesLeft = length;
        int			bytesSent = 0;

        //send it
        while (bytesLeft > 0) {
            bytesSent = send(theSocket, bytes + (length - bytesLeft), bytesLeft, 0);
            if (bytesSent <= 0) {
                isValid = NO;
                break;
            }
            
            bytesLeft -= bytesSent;
        }

        success = YES;
    }

    return success;
}


//Get data
- (BOOL)getData:(NSData **)outData ofLength:(int)inLength remove:(BOOL)shouldRemove
{
    BOOL		allDataAvailable;
    int		 	bytesRead;
    char		tempBuffer[8192];

    //
    *outData = nil;
    allDataAvailable = NO;

    //
    if ([readBuffer length] >= inLength) { // this data is fully in the buffer
        //Return the correct bytes from the buffer
        *outData = [NSData dataWithBytes:[readBuffer bytes] length:inLength];// autorelease];
        allDataAvailable = YES;
        
		//Remove the bytes from the read buffer (if desired)
		if (allDataAvailable && shouldRemove) {
			[self removeDataBytes:inLength];
		}

    } else { // This data hasn't arrived yet (or has only partially arrived)

        if ([self readyForReceiving]) {
            //Read the bytes (or remaining bytes) from the net
            bytesRead = recv(theSocket, &tempBuffer, (inLength - [readBuffer length]), 0);

            if (bytesRead == 0) { //Our socket is disconnected
                isValid = NO;

            } else if (bytesRead > 0) {
                //Append the bytes to the read buffer
                [readBuffer appendBytes:tempBuffer length:bytesRead];

                *outData = readBuffer; //Return the data read so far
                allDataAvailable = ([readBuffer length] == inLength); //YES if we have all the data

                //Remove the bytes from the read buffer (if desired)
                if (allDataAvailable && shouldRemove) {
                    [self removeDataBytes:inLength];
                }
            }

        }
    }

    return allDataAvailable;
}

- (BOOL)getDataToNewline:(NSData **)outData remove:(BOOL)shouldRemove
{
    BOOL	lineAvailable;
    char 	tempBuffer[8192];
    const char	*bytes;
    int 	length;
    int 	c;

    //Read a chunk of data into the buffer
    if ([self readyForReceiving]) {
        int	bytesRead;

        bytesRead = recv(theSocket, &tempBuffer, sizeof(tempBuffer), 0);

        if (bytesRead == 0) { //Our socket is disconnected
            isValid = NO;
        } else if (bytesRead > 0) { //Append the bytes to the read buffer
            [readBuffer appendBytes:tempBuffer length:bytesRead];
        }
    }

    //
    *outData = readBuffer;
    lineAvailable = NO;

    //Search the buffer for a newline (Scanning manually is faster than letting NSString handle it)
    length = [readBuffer length];
    bytes = [readBuffer bytes];

    for (c = 0; c < length - 1; c++) {
        if (bytes[c] == '\r' && bytes[c+1] == '\n') {
            *outData = [NSData dataWithBytes:bytes length:(c + 2)];
            lineAvailable = YES;
            
            //Remove the bytes from the read buffer (if desired)
            if (shouldRemove) {
                [self removeDataBytes:(c + 2)];
            }

            break;
        }
    }

    return lineAvailable;
}

//Remove data from the buffer
- (void)removeDataBytes:(int)inLength
{
    if ([readBuffer length] == inLength) {
        //Reset the data
        [readBuffer autorelease]; readBuffer = nil;
        readBuffer = [[NSMutableData alloc] init];
    } else {
        const char *bytes = [readBuffer bytes];

        //subtract the bytes
        [readBuffer autorelease];
        readBuffer = [[NSMutableData alloc] initWithBytes:&bytes[inLength] length:([readBuffer length] - inLength)];
    }
}

- (NSString *)hostIP
{
    return hostIP;
}

- (int)hostPort
{
    return hostPort;
}


//-------------------
//  Hidden Methods
//-----------------------

//-------------------
//  Private Methods
//-----------------------
- (id)initWithHost:(NSString *)host port:(int)port
{
    struct sockaddr_in 		socketAddress;
    struct hostent 		*hostEnt;
    char			*address;

    //resolve the host
    hostEnt = gethostbyname([host cString]);
    if (!hostEnt) {
        NSLog(@"Error finding host");
        return nil;
    }
    address = inet_ntoa(*((struct in_addr *)hostEnt->h_addr));
    hostIP = [[NSString alloc] initWithCString:address]; //Remember our host IP
    hostPort = port;    
    
    //Create the socket
    theSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (theSocket < 0) {
        NSLog(@"Error creating socket");
        return nil;
    }

    //Make it non-blocking
    fcntl(theSocket, F_SETFL, O_NONBLOCK);    

    //Setup the socket (destination) address
    socketAddress.sin_family = AF_INET;
    socketAddress.sin_port = htons(port);
    inet_aton(address, &(socketAddress.sin_addr));
    memset(&(socketAddress.sin_zero),'\0',8);

    //Set up the send & read buffer
    readBuffer = [[NSMutableData alloc] init];
    
    //Connect
    isValid = YES;    
    if (connect(theSocket, (struct sockaddr *)&socketAddress, sizeof(struct sockaddr)) != 0 && errno != EINPROGRESS) {    
        NSLog(@"Error initiating connecting");
        isValid = NO;
    }

    return self;
}

//Returns YES if the connection is ready for sending
- (BOOL)readyForSending
{
    struct timeval 	timeOut;
    fd_set 		writefds;
    int			result;

    //Set the timeout to 0
    timeOut.tv_sec = 0;
    timeOut.tv_usec = 0;

    //Set up the writefds
    FD_ZERO(&writefds);
    FD_SET(theSocket, &writefds);

    result = select(theSocket + 1, NULL, &writefds, NULL, &timeOut);

    {//Check for errors (that could case a SIGPIPE ?:\)
        int 	error;
        socklen_t	size = sizeof(error);

        getsockopt(theSocket, SOL_SOCKET, SO_ERROR, &error, &size);
        if (error != 0) {
            NSLog(@"Socket(opt) error: %i",(int)error);
            isValid = NO;
            return NO;
        }
    }

    return (result != 0);
}

//Returns YES if the connection is ready for receiving
- (BOOL)readyForReceiving
{
    struct timeval 	timeOut;
    fd_set 		receivefds;
    int			result;

    //Set the timeout to 0
    timeOut.tv_sec = 0;
    timeOut.tv_usec = 0;

    //Set up the writefds
    FD_ZERO(&receivefds);
    FD_SET(theSocket, &receivefds);

    result = select(theSocket + 1, &receivefds, NULL, NULL, &timeOut);

    return (result != 0);
}

- (void)dealloc
{
    close(theSocket);
    [readBuffer release];
    [hostIP release];
   
    [super dealloc];
}

@end

/* Mini-Docs
Non blocking reading

 if ([socket readyForReceiving] && [socket getDataOfLength:HEADER_SIZE]) {
     if ([socket getDataOfLength:CONTENT_SIZE]) {
         [socket removeDataBytes:HEADER_SIZE + CONTENT_SIZE];

         //Process the packet         
     }
 }

 - Allows us to delay until a certain amount of bytes are present
 - Lets us examine a series of bytes without flushing them from the socket

 This lets us wait for a header, determine its length, and then wait until both the header and contents are present
*/

