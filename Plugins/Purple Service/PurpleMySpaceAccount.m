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

#import "PurpleMySpaceAccount.h"
#import <Adium/AIHTMLDecoder.h>

@implementation PurpleMySpaceAccount

- (const char*)protocolPlugin
{
    return "prpl-myspace";
}

- (NSString *)connectionStringForStep:(NSInteger)step
{
	switch (step) {
	case 0:
		return AILocalizedString(@"Connecting",nil);
	case 1:
		return AILocalizedString(@"Reading challenge", "Description of a step in the connection process for MySpace. This could be translated as something like 'Reading from server'.");
	case 2:
		return AILocalizedString(@"Logging in","Connection step");
	case 3:
		return AILocalizedString(@"Connected","Connection step");
	}

	return nil;
}
	
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	return [AIHTMLDecoder encodeHTML:inAttributedString
							 headers:YES
							fontTags:YES
				  includingColorTags:YES
					   closeFontTags:YES
						   styleTags:YES
		  closeStyleTagsOnFontChange:YES
					  encodeNonASCII:YES
						encodeSpaces:NO
						  imagesPath:nil
				   attachmentsAsText:YES
		   onlyIncludeOutgoingImages:NO
					  simpleTagsOnly:NO
					  bodyBackground:NO
				 allowJavascriptURLs:YES];
}

@end
