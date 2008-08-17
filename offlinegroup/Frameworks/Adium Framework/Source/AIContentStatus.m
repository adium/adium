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

#import <Adium/AIContentObject.h>
#import <Adium/AIContentStatus.h>

@interface AIContentStatus ()
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
		   message:(NSAttributedString *)inMessage
		  withType:(NSString *)inStatus;
@end

@implementation AIContentStatus

//Create a new status content object
+ (id)statusInChat:(AIChat *)inChat
		withSource:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
		   message:(NSAttributedString *)inMessage
		  withType:(NSString *)inStatus
{
    return [[[self alloc] initWithChat:inChat
								source:inSource
						   destination:inDest
								  date:inDate
							   message:inMessage
							  withType:inStatus] autorelease];
}

//init
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate *)inDate
		   message:(NSAttributedString *)inMessage
		  withType:(NSString *)inStatus
{
    [super initWithChat:inChat source:inSource destination:inDest date:inDate message:inMessage];
	
	//Filter so that triggers in messages can be resolved, don't track status changes
	filterContent = YES;
	trackContent = NO;

    //Store source and dest
	statusType = [inStatus retain];
	
    return self;
}

//Dealloc
- (void)dealloc
{
	[statusType release]; statusType = nil;
	[loggedMessage release]; loggedMessage = nil;
	[coalescingKey release]; coalescingKey = nil;

    [super dealloc];
}

- (NSMutableArray *)displayClasses
{
	NSMutableArray *classes = [super displayClasses];
	
	//The notion of direction is not very useful on statuses
	NSUInteger idx = [classes indexOfObject:@"incoming"];
	if(idx != NSNotFound)
		[classes removeObjectAtIndex:idx];
	
	[classes addObject:@"status"];
	[classes addObject:statusType];
	return classes;
}

//Content Identifier
- (NSString *)type
{
    return CONTENT_STATUS_TYPE;
}

//The type of status change this is
- (NSString *)status
{
	return statusType;
}

- (void)setLoggedMessage:(NSAttributedString *)inLoggedMessage
{
	if (loggedMessage != inLoggedMessage) {
		[loggedMessage release];
		loggedMessage = [inLoggedMessage retain];
	}
}

- (NSAttributedString *)loggedMessage
{
	return loggedMessage;
}

- (void)setCoalescingKey:(NSString *)inCoalescingKey
{
	coalescingKey = [inCoalescingKey copy];
}

- (NSString *)coalescingKey
{
	return coalescingKey;
}

@end
