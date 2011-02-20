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

#import <Adium/AIContentEvent.h>

@implementation AIContentEvent

+ (id)eventInChat:(AIChat *)inChat
	   withSource:(id)inSource
	  destination:(id)inDest
			 date:(NSDate *)inDate
		  message:(NSAttributedString *)inMessage
		 withType:(NSString *)inStatus
{
	return [super statusInChat:inChat
					withSource:inSource
				   destination:inDest 
						  date:inDate 
					   message:inMessage 
					  withType:inStatus];
}

//Content Identifier
- (NSString *)type
{
    return CONTENT_EVENT_TYPE;
}

- (NSMutableArray *)displayClasses
{
	NSMutableArray *classes = [super displayClasses];
	
	//Events are not really status changes...
	NSUInteger idx = [classes indexOfObject:@"status"];
	if(idx != NSNotFound)
		[classes removeObjectAtIndex:idx];
	
	[classes addObject:@"event"];
	return classes;
}

- (NSAttributedString *)loggedMessage
{
	return self.message;
}

- (NSString *)eventType
{
	return [super status];
}

@end
