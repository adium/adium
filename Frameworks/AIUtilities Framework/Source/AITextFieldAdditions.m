/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "AITextFieldAdditions.h"
#import "AIWiredString.h"

@implementation NSTextField (AITextFieldAdditions)

- (void)selectRange:(NSRange)range
{
    NSText	*fieldEditor;

    fieldEditor = [[self window] fieldEditor:YES forObject:self];

    [fieldEditor setSelectedRange:range];
}

- (AIWiredString *)secureStringValue
{
	//unfortunately, there is no really good way to do this.
	//the best we can do is to take our string value using normal NSString,
	//	get it released as soon as possible, and return a wired version.
	AIWiredString *result = nil;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *stringValue = [self stringValue];
	result = [[AIWiredString alloc] initWithString:stringValue];

	[pool release];
	return [result autorelease];
}

@end
