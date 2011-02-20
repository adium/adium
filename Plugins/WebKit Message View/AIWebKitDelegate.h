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

#import <WebKit/WebKit.h>

@class ESWebView;

//This class is a workaround for a crash that occurs in 10.4.9 that we think has to do with webkit delegates being deallocated. Note that this crash is definitely not possible.

@class AIWebKitMessageViewController;

@interface AIWebKitDelegate : NSObject {
	NSMutableDictionary *mapping;
}

+ (AIWebKitDelegate *)sharedWebKitDelegate;
- (void) addDelegate:(AIWebKitMessageViewController *)controller forView:(ESWebView *)wv;
- (void) removeDelegate:(AIWebKitMessageViewController *)controller;

@end
