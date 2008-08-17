/*
 * TranslationController.h
 * Fire
 *
 * Created by Alan Humpherys on Sat Feb 22 2003.
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

#import <Adium/AIPlugin.h>
#import <Adium/AIContentControllerProtocol.h>
#import "TranslationEngine.h"

#define TC_MESSAGE_KEY	@"msg"
#define	TC_FROM_KEY	@"from"
#define TC_TO_KEY	@"to"

@interface AITranslatorPlugin : AIPlugin <AIDelayedContentFilter>
{
    NSMutableArray *messages;
    NSObject<TranslationEngineInterface> *engine;

	int numberTranslating;
}

@end

@interface AITranslatorPlugin (engineCallbacks)

// The following methods are ONLY to be called by the translationEngine
// Calling them from other locations will result in incorrect behavior
- (void)translatedString:(NSString *)translatedString forMessageDict:(NSDictionary *)messageDict;
- (void)translationError:(NSString *)errorMessage forMessageDict:(NSDictionary *)messageDict;

@end
