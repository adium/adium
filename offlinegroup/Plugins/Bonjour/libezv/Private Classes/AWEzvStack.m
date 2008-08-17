/*
 * Project:     Libezv
 * File:        AWEzvStack.h
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

#import "AWEzvStack.h"
#import "AWEzvSupportRoutines.h"

@implementation AWEzvStack
- (id) init 
{
    if ((self = [super init])) {
		top = NULL;
		size = 0;
	}
    
    return self;
}

- (void)dealloc {
    stacklink *next;
    
    while (top != NULL) {
        next = top->next;
	free (top);
	top = next;
    }
	
	[super dealloc];
}

- (void) push:(id)value {
    stacklink	*newlink;
    
    newlink = (stacklink *) malloc(sizeof(stacklink));
    if (newlink == NULL) {
        AWEzvLog(@"Could not allocate new stack link");
        return;
    }
    
    newlink->data = [value retain];
    newlink->next = top;
    top = newlink;
    size++;
}

- (id) pop {
    id value;
    stacklink	*toplink;
    
    if (size != 0) {
        toplink = top;
        top = top->next;
        value = [toplink->data autorelease];
        free(toplink);
        size--;
    } else {
        value = nil;
    }
    return value;
}

- (unsigned int) size {
    return size;
}
- (id) top {
    if (top != NULL)
        return top->data;
    else
        return nil;
}

@end
