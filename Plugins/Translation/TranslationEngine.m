/*
 * TranslationEngine.m
 * Fire
 *
 * Created by Alan Humpherys on Wed Mar 19 2003.
 * Copyright (c) 2003. All rights reserved.
 *
 * Modernized and modified by Evan Schoenberg on Sun mar 12 2006.
 * Some parts copyright (c) 2006. All rights reserved.
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

#import "TranslationEngine.h"
#import "AITranslatorPlugin.h"
#import "AITranslatorRequestDelegate.h"

@interface NSString (FireStringAdditions)
- (NSString *)URLEncodedStringUsingCFEncoding:(CFStringEncoding)encoding;
@end

@implementation TranslationEngine

// Currently, the translation engine uses www.worldlingo.com to power the
// translations.  If this ever becomes unavailable, it is possible to use:
//  www.translations.com
//  www.freetranslation.com
//  babelfish.altavista.com

- (void)translate:(NSDictionary *)messageDict notifyingTarget:(id)target
{   
    NSString *POSTBody = nil;
    NSString *inputString = nil;
    NSString *from = nil;
    NSString *to = nil;
    NSString *encodedMsg = nil;
    NSDictionary *translationEncodingDict = nil;
    NSNumber *latinEncoding;
    unsigned int srcEncoding;
	
    inputString = [messageDict objectForKey:TC_MESSAGE_KEY];
    from = [messageDict objectForKey:TC_FROM_KEY];
    to = [messageDict objectForKey:TC_TO_KEY];
	
    if (!inputString || !from || !to) {
        TRANSLATION_ERROR(TE_BAD_PARMS);
        return;
    }
    
    // Normalize and Validate languages
    if ([from isEqualToString:@"DefaultLanguage"]) {
        // This shouldn't occur with proper localization
        // Defaulting to English
        from = @"en";
    }
    if ([to isEqualToString:@"DefaultLanguage"]) {
        // This shouldn't occur with proper localization
        // Defaulting to English
        to = @"en";
    }
	
    // Match the cases used on their website
    from = [from uppercaseString];
    to = [to lowercaseString];
	
    if ([[from lowercaseString] isEqualToString:to]) {
        //No Translation needed
		[target translatedString:inputString forMessageDict:messageDict];

        return;
    }
	
    latinEncoding = [NSNumber numberWithUnsignedInt:kCFStringEncodingISOLatin1];
	
    // This is the list of encodings expected by the website
    translationEncodingDict = [[NSDictionary alloc] initWithObjectsAndKeys:
        latinEncoding,	@"en",
        latinEncoding,	@"es",
        latinEncoding,	@"fr",
        latinEncoding,	@"de",
        latinEncoding,	@"pt",
        latinEncoding,	@"it",
        latinEncoding,	@"nl",
        [NSNumber numberWithUnsignedInt:kCFStringEncodingISOLatinGreek],@"el",
        [NSNumber numberWithUnsignedInt:kCFStringEncodingDOSRussian],	@"ru",
        [NSNumber numberWithUnsignedInt:kCFStringEncodingShiftJIS],	@"ja",
        [NSNumber numberWithUnsignedInt:kCFStringEncodingEUC_CN],	@"zh_cn",
        [NSNumber numberWithUnsignedInt:kCFStringEncodingBig5],		@"zh_tw",
        [NSNumber numberWithUnsignedInt:kCFStringEncodingEUC_KR],	@"ko",
        nil];
	
    // Change string to proper encoding and URLEncode it
    srcEncoding = [(NSNumber *)[translationEncodingDict objectForKey:[from lowercaseString]] unsignedIntValue];
	[translationEncodingDict release];

    if (!CFStringIsEncodingAvailable(srcEncoding)) {
        TRANSLATION_ERROR(TE_LANG_NOT_SUPPORTED);
        return;
    }
	
	encodedMsg = [inputString URLEncodedStringUsingCFEncoding:srcEncoding];

    POSTBody = [NSString stringWithFormat:
        @"wl_srclang=%@&wl_trglang=%@&wl_text=%@&wl_url=&wl_glossary=gl1&wl_documenttype=dt9",
        from,
        to,
        encodedMsg];
	
	NSMutableURLRequest *request;
	
	request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://www.worldlingo.com/wl/translate"]
									  cachePolicy:NSURLRequestReloadIgnoringCacheData
								  timeoutInterval:120];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[POSTBody dataUsingEncoding:NSUTF8StringEncoding]];
	[request addValue:@"www.worldlingo.com" forHTTPHeaderField:@"Host"];
	[request addValue:@"http://www.worldlingo.com/products_services/worldlingo_translator.html" forHTTPHeaderField:@"Referer"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];

	AITranslatorRequestDelegate *requestDelegate = [AITranslatorRequestDelegate translatorRequestDelegateForDict:messageDict
																								 notifyingTarget:target];
	[NSURLConnection connectionWithRequest:request delegate:requestDelegate];
}

@end

@implementation NSString (FireStringAdditons)
+ (NSString *)URLEncodingForCharacter:(const unsigned char)c
{
    if (c == ' ') {
        return @"+";
    } else if (c == '\n') {
        // Change linefeeds to the CR-LF pair expected
        return @"%0D%0A";
    } else if (isalnum(c)) {
        // Regular AlphaNumerics
        return [NSString stringWithFormat:@"%c",c];
    } else {
        // Non-Printable, NULL, Non-ASCII, and other "dangerous" characters
        return [NSString stringWithFormat:@"%%%02X",c];
    }
}

- (NSString *)URLEncodedStringUsingCFEncoding:(CFStringEncoding)encoding {
    NSMutableString *rValue = nil;
    NSData *encodedData;
    unsigned int dataLength;
    unsigned int i;
    unsigned char *dataBytes;
	
    if ((encoding == kCFStringEncodingInvalidId) || !CFStringIsEncodingAvailable(encoding)) {
        // Unknown encoding type
        return nil;
    }
	
    encodedData = (NSData *)CFStringCreateExternalRepresentation (NULL, (CFStringRef)self, encoding, '*');
    [encodedData autorelease];
    
    dataLength = [encodedData length];
    dataBytes = (unsigned char *)[encodedData bytes];
    rValue = [[[NSMutableString alloc] init] autorelease];
	
    for(i=0;i < dataLength;i++) {
        [rValue appendString:[NSString URLEncodingForCharacter:dataBytes[i]]];
    }
	
    return rValue;
}

@end
