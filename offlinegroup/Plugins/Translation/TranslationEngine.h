/*
 * TranslationEngine.h
 * Fire
 *
 * Created by Alan Humpherys on Wed Mar 19 2003.
 * Copyright (c) 2003 Fire Development Team and/or epicware, Inc.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <AppKit/AppKit.h>

#define TRANSLATION_ERROR(msg)	[target translationError:(msg) forMessageDict:messageDict];

// Definition of Translation Error Strings
#define TE_BAD_PARMS		NSLocalizedString(@"Bad Parameters Sent to Translation",@"Translation Error")
#define TE_LANG_NOT_SUPPORTED	NSLocalizedString(@"Support for this language has not been installed on your Macintosh",@"Translation Error")
#define TE_CANT_ENCODE		NSLocalizedString(@"Unable to encode message for transmission to translation server",@"Translation Error")
#define TE_HOST_NOT_FOUND	NSLocalizedString(@"Host not found",@"Translation Error")
#define TE_CANT_OPEN_SOCKET	NSLocalizedString(@"Could not open socket to translation server",@"Translation Error")
#define TE_CANT_BIND_PORT	NSLocalizedString(@"Could not bind a port to use",@"Translation Error")
#define TE_CANT_CONNECT		NSLocalizedString(@"Cannot connect to the translation server",@"Translation Error")
#define TE_CANT_TRANSMIT	NSLocalizedString(@"Cannot send data to translation server",@"Translation Error")
#define TE_NO_RESPONSE		NSLocalizedString(@"No translated page was returned",@"Translation Error")
#define TE_CANT_DECODE		NSLocalizedString(@"No translation found: Server too busy",@"Translation Error")
#define TE_EMPTY_RESPONSE	NSLocalizedString(@"A blank translation was returned",@"Translation Error")
#define TE_UNKNOWN_ERROR	NSLocalizedString(@"Unknown error in translation",@"Translation Error")

@protocol TranslationEngineInterface
- (void)translate:(NSDictionary *)messageDict notifyingTarget:(id)target;
@end

@interface TranslationEngine : NSObject <TranslationEngineInterface>
{
}

@end
