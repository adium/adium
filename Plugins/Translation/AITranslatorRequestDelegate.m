//
//  AITranslatorRequestDelegate.m
//  Adium
//  Created by Evan Schoenberg on 3/12/06.

/* Response decoding based on:
 * TranslationEngine.m
 * Fire
 *
 * Created by Alan Humpherys on Wed Mar 19 2003.
 * Copyright (c) 2003. All rights reserved.
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

#import "AITranslatorRequestDelegate.h"
#import "TranslationEngine.h"
#import "AITranslatorPlugin.h"
#import <AIUtilities/AIStringAdditions.h>

@interface AITranslatorRequestDelegate (PRIVATE)
- (id)initWithDict:(NSDictionary *)inDict notifyingTarget:(id)inTarget;
@end

@implementation AITranslatorRequestDelegate
+ (id)translatorRequestDelegateForDict:(NSDictionary *)inDict notifyingTarget:(id)inTarget
{
	return [[[self alloc] initWithDict:inDict notifyingTarget:inTarget] autorelease];
}

- (id)initWithDict:(NSDictionary *)inDict notifyingTarget:(id)inTarget
{
	if ((self = [super init])) {
		messageDict = [inDict retain];
		target = [inTarget retain];
		state = Translator_SearchForTextArea;
		response = [[NSMutableString alloc] init];
		targetRange = NSMakeRange(0,0);
		
	}
	
	return self;
}

- (void)dealloc
{
	[messageDict release];
	[target release];
	[response release];

	[super dealloc];
}

- (void)searchCompletedWithLocation:(int)location
{
	NSString	*translation;

	// Reset the Range to reflect the returned translation
	targetRange = NSMakeRange(0, location);

	// We may have some newlines and spaces at the beginning of the range.  If we do, let's
    // skip past those.
    while ([response characterAtIndex:(targetRange.location)] == '\n' ||
           [response characterAtIndex:(targetRange.location)] == '\r' ||
           [response characterAtIndex:(targetRange.location)] == ' ') {
        targetRange.location++;
        targetRange.length--;
    }
	
    // Now we might have some extra newlines and spaces at the end of our range.  Let's
    // fix that, too.
    while ([response characterAtIndex:(targetRange.location+targetRange.length-1)] == '\n' ||
           [response characterAtIndex:(targetRange.location+targetRange.length-1)] == '\r' ||
           [response characterAtIndex:(targetRange.location+targetRange.length-1)] == ' ') {
        targetRange.length--;
    }
	
    translation = [response substringWithRange:targetRange];
	
    if (!translation || [translation length] == 0) {
        TRANSLATION_ERROR(TE_UNKNOWN_ERROR);
        return;
    }
	
    // The worldlingo website may add a meta tag to the start of the returned string.  We must delete this
    // tag because the clients do not understand it.
    targetRange = [translation rangeOfString:@"<meta "];
    if (targetRange.location != NSNotFound) {
        NSRange endRange = [translation rangeOfString:@">" 
											  options:NSLiteralSearch
												range:NSMakeRange(targetRange.location + targetRange.length,
																  [translation length] - targetRange.location - targetRange.length)];
        
        if (endRange.location != NSNotFound) {
            response = [NSMutableString stringWithString:translation];
            [response deleteCharactersInRange:NSMakeRange(targetRange.location,endRange.location - targetRange.location + 1)];

			// Make a copy to ensure type integrity
            translation = [NSString stringWithString:response];
        }
    }
	
	[target translatedString:translation forMessageDict:messageDict];		
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	//	The target looks like:
    //	<textarea name="wl_result"...>This is what we're looking for.</textarea>
    //	Receive characters from the server.  We'll keep going as long as
    //	we haven't found the closing </textarea>
	if (state != Translator_SearchCompleted) {
		NSString *retrievedData = [NSString stringWithData:data encoding:NSUTF8StringEncoding];
		if (retrievedData && [retrievedData length]) {
			[response appendString:retrievedData];
		} else {
			AILog(@"Null new data.. %@ so far...",response);
		}
		
        switch (state) {
            case Translator_SearchForTextArea:
			{
                targetRange = [response rangeOfString:@"<textarea name=\"wl_result\""];
                if (targetRange.location == NSNotFound) {
                    break;
                } else {
                    // found textarea beginning
                    state = Translator_SearchForEndOfTag;
                    // Throw away all preamble data
                    targetRange.length = targetRange.location + targetRange.length;
                    targetRange.location = 0;
                    [response deleteCharactersInRange:targetRange];
                    // fall through to next state
                }
			}
			case Translator_SearchForEndOfTag:
			{
				targetRange = [response rangeOfString:@">"];
				if (targetRange.location == NSNotFound) {
					break;
				} else {
					// found closing of <textarea *> tag
					state = Translator_SearchForTextAreaClose;
					// Throw away all preamble data
					targetRange.length = targetRange.location + targetRange.length;
					targetRange.location = 0;
					[response deleteCharactersInRange:targetRange];
					// fall through to next state
				}
			}
			case Translator_SearchForTextAreaClose:
			{
				targetRange = [response rangeOfString:@"</textarea>"];
				if (targetRange.location != NSNotFound) {
					// found closing of </textarea> tag
					state = Translator_SearchCompleted;
				}
				break;
			}
			case Translator_SearchCompleted:
				break;
        }
		
		if (!response || [response length] == 0) {
			TRANSLATION_ERROR(TE_NO_RESPONSE);
			return;
		}
	}
	
	if (state == Translator_SearchCompleted) {
		if (targetRange.location == 0) {
			TRANSLATION_ERROR(TE_EMPTY_RESPONSE);
			return;
		}

		[self searchCompletedWithLocation:targetRange.location];
		[connection cancel];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	AILog(@"Translation failed: %@", [error localizedDescription]);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (state != Translator_SearchCompleted) {
        TRANSLATION_ERROR(TE_CANT_DECODE);
    }
}

@end
