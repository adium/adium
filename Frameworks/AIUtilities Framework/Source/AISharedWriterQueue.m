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
#import "AISharedWriterQueue.h"

@implementation AISharedWriterQueue

static inline dispatch_queue_t queue() {
    static dispatch_queue_t sharedWriterQueue = nil;
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedWriterQueue = dispatch_queue_create("com.adium.sharedAsyncIOQueue", 0);
    });
	
	return sharedWriterQueue;
}

+ (void) addOperation:(dispatch_block_t)op {
    dispatch_async(queue(), op);
}

+ (void) waitUntilAllOperationsAreFinished {
    dispatch_sync(queue(), ^{});
}

@end
