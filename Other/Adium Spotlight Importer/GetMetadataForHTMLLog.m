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

#import "GetMetadataForHTMLLog.h"
#import "GetMetadataForHTMLLog-Additions.h"

#import <AIUtilities/ISO8601DateFormatter.h>

static char *gaim_markup_strip_html(const char *str);

//Given an Adium log file name, return an NSDate for its creation date
static NSDate *dateFromHTMLLog(NSString *pathToFile)
{
	ISO8601DateFormatter *formatter = [[ISO8601DateFormatter alloc] init];
	formatter.timeSeparator = '.';
	NSRange openParenRange, closeParenRange;
	
	if ((openParenRange = [pathToFile rangeOfString:@"(" options:NSBackwardsSearch]).location != NSNotFound) {
		openParenRange = NSMakeRange(openParenRange.location, [pathToFile length] - openParenRange.location);
		if ((closeParenRange = [pathToFile rangeOfString:@")" options:0 range:openParenRange]).location != NSNotFound) {
			//Add and subtract one to remove the parenthesis
			NSString *dateString = [pathToFile substringWithRange:NSMakeRange(openParenRange.location + 1, (closeParenRange.location - openParenRange.location))];
			return [formatter dateFromString:[dateString stringByReplacingOccurrencesOfString:@"|" withString:@"-"]];
		}
	}
	return nil;
}

NSString *CopyTextContentForHTMLLogData(NSData *logData) {
    /* Perhaps we want to decode the HTML instead of stripping it so we can process
	 * the attributed contents to turn links into link (URL) for searching purposes...
	 */
	NSString *textContent = nil;
    const char* UTF8HTMLCString = [logData bytes];
    if (UTF8HTMLCString) {
		//Strip the HTML markup
		char *plainText = gaim_markup_strip_html(UTF8HTMLCString);
		textContent = [[NSString alloc] initWithUTF8String:plainText];
		free((void *)plainText);
	}
    
    return textContent;
}

Boolean GetMetadataForHTMLLog(NSMutableDictionary *attributes, NSString *pathToFile)
{
	/* HTML log is stored as ServiceID.Account_Name/Destination_Name/Destination_Name (2006|03|30).AdiumHTMLLog
	* or HTML log is stored as ServiceID.Account_Name/Destination_Name/Destination_Name (2006-03-30).AdiumHTMLLog
	*/
	NSArray *pathComponents = [pathToFile pathComponents];
	NSUInteger count = [pathComponents count];
	NSString *toUID = ((count >= 2) ? [pathComponents objectAtIndex:(count - 2)] : nil);
	NSString *sourceFolder = ((count >= 3) ? [pathComponents objectAtIndex:(count - 3)] : nil);
	NSString *serviceClass, *fromUID;
	NSArray  *serviceAndFromUIDArray;

	/* Determine the service and fromUID - should be SERVICE.ACCOUNT_NAME
	 * Check against count to guard in case of old, malformed or otherwise odd folders & whatnot sitting in log base
	 */
	serviceAndFromUIDArray = [sourceFolder componentsSeparatedByString:@"."];
	
	if ([serviceAndFromUIDArray count] >= 2) {
		serviceClass = [serviceAndFromUIDArray objectAtIndex:0];
		
		//Use substringFromIndex so we include the rest of the string in the case of a UID with a . in it
		fromUID = [sourceFolder substringFromIndex:([serviceClass length] + 1)]; //One off for the '.'
	} else {
		//Fallback: blank non-nil serviceClass; folderName as the fromUID
		serviceClass = @"";
		fromUID = sourceFolder;
	}
	
	NSDate *date;
	
	if ((date = dateFromHTMLLog(pathToFile))) {
		[attributes setObject:date
					   forKey:(NSString *)kMDItemContentCreationDate];
		[attributes setObject:date
					   forKey:(NSString *)kMDItemLastUsedDate];
	}
	
    NSData *logData = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:pathToFile isDirectory:NO]
                                                    options:NSDataReadingUncached error:NULL];
    NSString *textContent = nil;
	if ((textContent = CopyTextContentForHTMLLogData(logData))) {
		[attributes setObject:textContent
					   forKey:(NSString *)kMDItemTextContent];
	}
	
	[attributes setObject:serviceClass
				   forKey:@"com_adiumX_service"];
	if (fromUID) {
		[attributes setObject:fromUID
					   forKey:@"com_adiumX_chatSource"];
	}

	if (toUID) {
		[attributes setObject:toUID
					   forKey:@"com_adiumX_chatDestination"];
		[attributes setObject:[NSString stringWithFormat:@"%@ on %@",toUID,[date descriptionWithCalendarFormat:@"%y-%m-%d"
																									  timeZone:nil
																										locale:nil]]
					   forKey:(NSString *)kMDItemDisplayName];
	}

	[attributes setObject:@"Chat log"
				   forKey:(NSString *)kMDItemKind];
	return TRUE;
}

#pragma mark Stripping HTML

//Taken from Gaim, 'cause I knew it was there.  There may be an easier way to do this...

static BOOL g_ascii_isspace(char character)
{
	return (character == ' ');
}

static char *gaim_unescape_html(const char *html) {
	NSString *unescapedString = [[NSString stringWithUTF8String:html] stringByUnescapingFromXMLWithEntities:nil];
	const char *unescapedStringUTF8String = [unescapedString UTF8String];
	if (!unescapedStringUTF8String) NSLog(@"Warning: Could not unescape %s, or could not make a UTF8 string out of %@",html,unescapedString);

	return (unescapedStringUTF8String ? strdup(unescapedStringUTF8String) : nil);
}

/* The following are probably reasonable changes:
* - \n should be converted to a normal space
* - in addition to <br>, <p> and <div> etc. should also be converted into \n
* - We want to turn </td>#whitespace<td> sequences into a single tab
* - We want to turn <td> into a single tab (for msn profile "parsing")
* - We want to turn </tr>#whitespace<tr> sequences into a single \n
* - <script>...</script> and <style>...</style> should be completely removed
*/

static char *
gaim_markup_strip_html(const char *str)
{
	size_t i, j, k;
	BOOL visible = TRUE;
	BOOL closing_td_p = FALSE;
	char *str2;
	const char *cdata_close_tag = NULL;
	char *href = NULL;
	size_t href_st = 0;
	
	if(!str)
		return NULL;
	
	str2 = strdup(str);
	
	for (i = 0, j = 0; str2[i]; i++)
	{
		if (str2[i] == '<')
		{
			if (cdata_close_tag)
			{
				/* Note: Don't even assume any other tag is a tag in CDATA */
				if (strncasecmp(str2 + i, cdata_close_tag,
								strlen(cdata_close_tag)) == 0)
				{
					i += strlen(cdata_close_tag) - 1;
					cdata_close_tag = NULL;
				}
				continue;
			}
			else if (strncasecmp(str2 + i, "<td", 3) == 0 && closing_td_p)
			{
				str2[j++] = '\t';
				visible = TRUE;
			}
			else if (strncasecmp(str2 + i, "</td>", 5) == 0)
			{
				closing_td_p = TRUE;
				visible = FALSE;
			}
			else
			{
				closing_td_p = FALSE;
				visible = TRUE;
			}
			
			k = i + 1;
			
			if(g_ascii_isspace(str2[k]))
				visible = TRUE;
			else if (str2[k])
			{
				/* Scan until we end the tag either implicitly - closed start
				* tag - or explicitly, using a sloppy method
				* i.e., < or >
				* inside quoted attributes will screw us up
				*/
				while (str2[k] && str2[k] != '<' && str2[k] != '>')
				{
					k++;
				}
				
				/* If we've got an <a> tag with an href, save the address
				* to print later. */
				if (strncasecmp(str2 + i, "<a", 2) == 0 &&
				    g_ascii_isspace(str2[i+2]))
				{
					size_t st; /* start of href, inclusive [ */
					size_t end; /* end of href, exclusive ) */
					char delim = ' ';
					/* Find start of href */
					for (st = i + 3; st < k; st++)
					{
						if (strncasecmp(str2+st, "href=", 5) == 0)
						{
							st += 5;
							if (str2[st] == '"')
							{
								delim = '"';
								st++;
							}
							break;
						}
					}
					/* find end of address */
					for (end = st; end < k && str2[end] != delim; end++)
					{
						/* All the work is done in the loop construct above. */
					}
					
					/* If there's an address, save it.  If there was
						* already one saved, kill it. */
					if (st < k)
					{
						char *tmp;
						free(href);
						tmp = strndup(str2 + st, end - st);
						href = gaim_unescape_html(tmp);
						free(tmp);
						href_st = j;
					}
				}
				
				/* Replace </a> with an ascii representation of the
				* address the link was pointing to. */
				else if (href != NULL && strncasecmp(str2 + i, "</a>", 4) == 0)
				{
					
					size_t hrlen = strlen(href);
					
					/* Only insert the href if it's different from the CDATA. */
					if ((hrlen != j - href_st ||
					     strncmp(str2 + href_st, href, hrlen)) &&
					    (hrlen != j - href_st + 7 ||
						 strncmp(str2 + href_st, href + 7, hrlen - 7))) {
						str2[j++] = ' ';
						str2[j++] = '(';
						memmove(str2 + j, href, hrlen);
						j += hrlen;
						str2[j++] = ')';
						free(href);
						href = NULL;
					}
				}
				
				/* Check for tags which should be mapped to newline */
				else if (strncasecmp(str2 + i, "<p>", 3) == 0
						 || strncasecmp(str2 + i, "<tr", 3) == 0
						 || strncasecmp(str2 + i, "<br", 3) == 0
						 || strncasecmp(str2 + i, "<li", 3) == 0
						 || strncasecmp(str2 + i, "<div", 4) == 0
						 || strncasecmp(str2 + i, "</table>", 8) == 0) {
					str2[j++] = '\n';
				}
				
				/* Check for tags which begin CDATA and need to be closed */
				else if (strncasecmp(str2 + i, "<script", 7) == 0) {
					cdata_close_tag = "</script>";
				}
				else if (strncasecmp(str2 + i, "<style", 6) == 0) {
					cdata_close_tag = "</style>";
				}
				/* Update the index and continue checking after the tag */
				i = (str2[k] == '<' || str2[k] == '\0')? k - 1: k;
				continue;
			}
		}
		else if (cdata_close_tag)
		{
			continue;
		}
		else if	(!g_ascii_isspace(str2[i]))
		{
			visible = TRUE;
		}
		
		/* XXX: This sucks.  We need to be un-escaping all entities, which
		* includes these, as well as the &#num; ones */
		
		if (str2[i] == '&' && strncasecmp(str2 + i, "&quot;", 6) == 0)
		{
			str2[j++] = '\"';
			i = i + 5;
			continue;
		}
			
			if (str2[i] == '&' && strncasecmp(str2 + i, "&amp;", 5) == 0)
			{
				str2[j++] = '&';
				i = i + 4;
				continue;
			}
			
			if (str2[i] == '&' && strncasecmp(str2 + i, "&lt;", 4) == 0)
			{
				str2[j++] = '<';
				i = i + 3;
				continue;
			}
			
			if (str2[i] == '&' && strncasecmp(str2 + i, "&gt;", 4) == 0)
			{
				str2[j++] = '>';
				i = i + 3;
				continue;
			}
			
			if (str2[i] == '&' && strncasecmp(str2 + i, "&apos;", 6) == 0)
			{
				str2[j++] = '\'';
				i = i + 5;
				continue;
			}

			if (visible)
				str2[j++] = g_ascii_isspace(str2[i])? ' ': str2[i];
		}

	free(href);

	str2[j] = '\0';

	return str2;
}
