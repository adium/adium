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

#import "GBQuestionHandlerPlugin.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import "ESTextAndButtonsWindowController.h"
#import <AIUtilities/AIObjectAdditions.h>

typedef enum
{
	ALERT_TYPE_ERROR,
	ALERT_TYPE_QUESTION
} AlertType;

@interface GBQuestionHandlerPlugin (privateFunctions)
- (BOOL)displayNextAlert;
@end

@implementation GBQuestionHandlerPlugin

- (id)init
{
	if( (self = [super init]) != nil)
	{
		questionQueue = [[NSMutableArray alloc] init];
		errorQueue = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[questionQueue release];
	[errorQueue release];
	[currentAlert release];
	[super dealloc];
}

- (void)installPlugin
{
    //Install our observers
    [[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(handleQuestion:)
									   name:Interface_ShouldDisplayQuestion 
									 object:nil];
}

- (void)uninstallPlugin
{
}

- (void)handleType:(AlertType)type userInfo:(NSDictionary *)userInfo
{
	NSDictionary *infoCopy = [userInfo copy];
	
	switch(type)
	{
		case ALERT_TYPE_QUESTION:
			[questionQueue addObject:infoCopy];
			break;
		case ALERT_TYPE_ERROR:
			[errorQueue addObject:infoCopy];
			break;
	}
	[infoCopy release];
	if(currentAlert == nil)
		[self displayNextAlert];
}

- (void)handleQuestion:(NSNotification *)notification
{
	[self handleType:ALERT_TYPE_QUESTION userInfo:notification.userInfo];
}

- (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode suppression:(BOOL)suppression userInfo:(id)userInfo
{
	NSString *selectorString = [userInfo objectForKey:@"Selector"];
	id target = [userInfo objectForKey:@"Target"];
	BOOL	ret = YES;
	
	if(target != nil || selectorString != nil)
	{
		SEL selector = NSSelectorFromString(selectorString);
		if([target respondsToSelector:selector])
		{
			[target performSelector:selector withObject:[NSNumber numberWithInteger:returnCode] withObject:[userInfo objectForKey:@"Userinfo"] withObject:[NSNumber numberWithBool:suppression]];
		}
	}
	if([self displayNextAlert])
		//More alerts so don't hide window
		ret = NO;
	else
	{
		// Note: Explicitly not released here: ESTextAndButtonsWindowController will autorelease itself in -windowWillClose:
		[currentAlert close];
		currentAlert = nil;
	}
	return ret;
}

- (BOOL)displayNextAlert
{
	BOOL ret = NO;
	if([errorQueue count] != 0)
	{
		NSDictionary *info = [errorQueue objectAtIndex:0];
		if(currentAlert == nil)
			currentAlert = [[ESTextAndButtonsWindowController alloc] init];
		[currentAlert changeWindowToTitle:[info objectForKey:@"Window Title"]
							defaultButton:AILocalizedString(@"Next", @"Next Button")
						  alternateButton:AILocalizedString(@"Dismiss All", @"Dismiss All Button")
							  otherButton:nil
							  suppression:nil
						withMessageHeader:[info objectForKey:@"Title"]
							   andMessage:[info objectForKey:@"Description"]
									image:nil
								   target:self
								 userInfo:info];
		[currentAlert show];
		[errorQueue removeObjectAtIndex:0];
		ret = YES;
	}
	else if ([questionQueue count] != 0)
	{
		NSDictionary *info = [questionQueue objectAtIndex:0];
		if(currentAlert == nil)
			currentAlert = [[ESTextAndButtonsWindowController alloc] init];
		[currentAlert changeWindowToTitle:[info objectForKey:@"Window Title"]
							defaultButton:[info objectForKey:@"Default Button"]
						  alternateButton:[info objectForKey:@"Alternate Button"]
							  otherButton:[info objectForKey:@"Other Button"]
							  suppression:[info objectForKey:@"Suppression Checkbox"]
						withMessageHeader:[info objectForKey:@"Title"]
							   andMessage:[info objectForKey:@"Description"]
									image:nil
								   target:self
								 userInfo:info];
		[currentAlert show];
		[questionQueue removeObjectAtIndex:0];
		ret = YES;
	}
	return ret;
}

@end
