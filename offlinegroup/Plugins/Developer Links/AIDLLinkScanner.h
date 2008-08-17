/*
 * The AutoHyperlinks Framework is the legal property of its developers (DEVELOPERS), whose names are listed in the
 * copyright file included with this source distribution.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the AutoHyperlinks Framework nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <AutoHyperlinks/AHMarkedHyperlink.h>
#import "AIDeveloperLinksPlugin.h"
#import "AIDLLexer.h"

extern int AIDLleng;
extern int AIDLlex();
typedef struct AIDL_buffer_state *AIDL_BUFFER_STATE;
void AIDL_switch_to_buffer(AIDL_BUFFER_STATE);
AIDL_BUFFER_STATE AIDL_scan_string (const char *);
void AIDL_delete_buffer(AIDL_BUFFER_STATE);

extern unsigned int AIDLStringOffset;

@class AHMarkedHyperlink;

@interface AIDLLinkScanner : NSObject
{
	AI_DEV_LINK_VERIFICATION_STATUS	 validStatus;
}


- (AI_DEV_LINK_VERIFICATION_STATUS)validationStatus;

/*!
 * @brief Determine the validity of a given string using the default strictness
 *
 * @param inString The string to be verified
 * @return Boolean
 */
- (BOOL)isStringValidURL:(NSString *)inString;


/*!
 * @brief Fetches all the URLs from a string
 * @param inString The NSString with potential URLs in it
 * @return An array of AHMarkedHyperlinks representing each matched URL in the string or nil if no matches.
 */
- (NSArray *)allURLsFromString:(NSString *)inString;

/*!
 * @brief Fetches all the URLs from a NSTextView
 * @param inView The NSTextView with potential URLs in it
 * @return An array of AHMarkedHyperlinks representing each matched URL in the textView or nil if no matches.
 */
- (NSArray *)allURLsFromTextView:(NSTextView *)inView;

/*!
 * @brief Scans an attributed string for URLs then adds the link attribs and objects.
 * @param inString The NSAttributedString to be linkified
 * @return An autoreleased NSAttributedString.
 */
- (NSAttributedString *)linkifyString:(NSAttributedString *)inString;

/*!
 * @brief Scans a NSTextView's text store for URLs then adds the link attribs and objects.
 * 
 * This scan happens in place: the origional NSTextView is modified, and nothing is returned.
 * @param inView The NSTextView to be linkified.
 */
- (void)linkifyTextView:(NSTextView *)inView;

@end
