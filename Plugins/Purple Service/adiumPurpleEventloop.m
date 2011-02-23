/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "adiumPurpleEventloop.h"
#import <AIUtilities/AIApplicationAdditions.h>
#import <poll.h>
#import <unistd.h>
#import <sys/socket.h>
#import <sys/select.h>

#include <dispatch/dispatch.h>

//#define PURPLE_SOCKET_DEBUG

static guint				sourceId = 0;		//The next source key; continuously incrementing

/*
 * The sources, keyed by integer key id (wrapped in an NSNumber), holding
 * NSVaue*'s with pointers to dispatch_source_ts.
 */
static NSMutableDictionary	*sourceInfoDict = nil;

gboolean adium_source_remove(guint tag) {
	
	NSValue *srcPointer = [sourceInfoDict objectForKey:[NSNumber numberWithInt:tag]];
	
    if (!srcPointer) {
		NSLog(@"Source info for %i not found (%@)", tag, sourceInfoDict);
		return FALSE;
	}
	
	dispatch_source_t src = (dispatch_source_t)[srcPointer pointerValue];
    dispatch_source_cancel(src);
    dispatch_release(src);
	
    [sourceInfoDict removeObjectForKey:[NSNumber numberWithInt:tag]];

	return (dispatch_source_testcancel(src) != 0);
}

//Like g_source_remove, return TRUE if successful, FALSE if not
gboolean adium_timeout_remove(guint tag) {
	
    return adium_source_remove(tag);
}

guint adium_timeout_add(guint interval, GSourceFunc function, gpointer data)
{
    dispatch_queue_t main_q;
	dispatch_source_t src;
	guint tag;
	
    main_q = dispatch_get_main_queue();
	
    tag = ++sourceId;
    
    src = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, main_q);

    dispatch_source_set_timer(src, 0, ((unsigned long long)interval) * 1000000ull, 100000ull);
	
    dispatch_source_set_event_handler(src, ^{
        if (function) function(data);
        adium_timeout_remove(tag);
    });
	
    [sourceInfoDict setObject:[NSValue valueWithPointer:src]
                       forKey:[NSNumber numberWithUnsignedInt:tag]];
	
    dispatch_resume(src);

    return tag;
}

guint adium_input_add(gint fd, PurpleInputCondition condition,
					  PurpleInputFunction func, gpointer user_data)
{	
	if (fd < 0) {
		NSLog(@"INVALID: fd was %i; returning tag %i",fd,sourceId+1);
		return ++sourceId;
	}

	dispatch_queue_t main_q;
	dispatch_source_t src;
	guint tag;
	dispatch_source_type_t type;
	
    main_q = dispatch_get_main_queue();
	
    tag = ++sourceId;
	
	if (condition == PURPLE_INPUT_READ) {
		type = DISPATCH_SOURCE_TYPE_READ;
	} else {
		type = DISPATCH_SOURCE_TYPE_WRITE;
	}
	
    src = dispatch_source_create(type, fd, 0, main_q);
	
    dispatch_source_set_event_handler(src, ^{
        if (func) func(user_data, fd, condition);
    });
		
    [sourceInfoDict setObject:[NSValue valueWithPointer:src]
                       forKey:[NSNumber numberWithUnsignedInt:tag]];

	dispatch_resume(src);
	
    return tag;
}

int adium_input_get_error(int fd, int *error)
{
	int		  ret;
	socklen_t len;
	len = sizeof(*error);
	
	ret = getsockopt(fd, SOL_SOCKET, SO_ERROR, error, &len);
	if (!ret && !(*error)) {
		/*
		 * Taken from Fire's FaimP2PConnection.m:
		 * The job of this function is to detect if the connection failed or not
		 * There has to be a better way to do this
		 *
		 * Any socket that fails to connect will select for reading and writing
		 * and all reads and writes will fail
		 * Any listening socket will select for reading, and any read will fail
		 * So, select for writing, if you can write, and the write fails, not connected
		 */
		
		{
			fd_set thisfd;
			struct timeval timeout;
			
			FD_ZERO(&thisfd);
			FD_SET(fd, &thisfd);
			timeout.tv_sec = 0;
			timeout.tv_usec = 0;
			select(fd+1, NULL, &thisfd, NULL, &timeout);
			if(FD_ISSET(fd, &thisfd)){
				ssize_t length = 0;
				char buffer[4] = {0, 0, 0, 0};
				
				length = write(fd, buffer, length);
				if(length == -1)
				{
					/* Not connected */
					ret = -1;
					*error = ENOTCONN;
					AILog(@"adium_input_get_error(%i): Socket is NOT valid", fd);
				}
			}
		}
	}

	return ret;
}

static PurpleEventLoopUiOps adiumEventLoopUiOps = {
    adium_timeout_add,
    adium_timeout_remove,
    adium_input_add,
    adium_source_remove,
	adium_input_get_error,
	/* timeout_add_seconds */ NULL,
	/* _purple_reserved2 */ NULL,
	/* _purple_reserved3 */ NULL,
	/* _purple_reserved4 */ NULL
};

PurpleEventLoopUiOps *adium_purple_eventloop_get_ui_ops(void)
{
	if (!sourceInfoDict) sourceInfoDict = [[NSMutableDictionary alloc] init];

	return &adiumEventLoopUiOps;
}
