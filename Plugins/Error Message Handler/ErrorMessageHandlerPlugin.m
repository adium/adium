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

#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import "ESPanelAlertDetailPane.h"
#import "ErrorMessageHandlerPlugin.h"
#import "ErrorMessageWindowController.h"
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIListObject.h>

#define ERROR_MESSAGE_ALERT_SHORT	AILocalizedString(@"Display an alert",nil)
#define ERROR_MESSAGE_ALERT_LONG	AILocalizedString(@"Display the alert \"%@\"",nil)

@implementation ErrorMessageHandlerPlugin

- (void)installPlugin
{
    //Install our observers
    [[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(handleError:)
									   name:Interface_ShouldDisplayErrorMessage 
									 object:nil];
    
    //Install our contact alert
	[adium.contactAlertsController registerActionID:ERROR_MESSAGE_CONTACT_ALERT_IDENTIFIER
										  withHandler:self];

	[adium.contactAlertsController registerEventID:INTERFACE_ERROR_MESSAGE 
										 withHandler:self
											 inGroup:AIOtherEventHandlerGroup
										  globalOnly:YES];
}

- (void)uninstallPlugin
{
    [ErrorMessageWindowController closeSharedInstance]; //Close the error window
}

- (void)handleError:(NSNotification *)notification
{
    NSDictionary	*userInfo;
    NSString		*errorTitle;
    NSString		*errorDesc;
    NSString		*windowTitle;
    
    //Get the error info
    userInfo = [notification userInfo];
    errorTitle = [userInfo objectForKey:@"Title"];
    errorDesc = [userInfo objectForKey:@"Description"];
    windowTitle = [userInfo objectForKey:@"Window Title"];

    //Display an alert
    [[ErrorMessageWindowController errorMessageWindowController] displayError:errorTitle 
															  withDescription:errorDesc
																	withTitle:windowTitle];
	
	//Generate the event (for no list object, so only global triggers apply)
	[adium.contactAlertsController generateEvent:INTERFACE_ERROR_MESSAGE
									 forListObject:nil
										  userInfo:userInfo
					  previouslyPerformedActionIDs:nil];
	
}


//Display Dialog Alert -------------------------------------------------------------------------------------------------
#pragma mark Display Dialog Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return ERROR_MESSAGE_ALERT_SHORT;
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	NSString	*alertText = [[details objectForKey:KEY_ALERT_TEXT] lastPathComponent];
	
	if (alertText && [alertText length]) {
		return [NSString stringWithFormat:ERROR_MESSAGE_ALERT_LONG, alertText];
	} else {
		return ERROR_MESSAGE_ALERT_SHORT;
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return [NSImage imageNamed:@"events-error-alert" forClass:[self class]];
}

- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
{
	return [ESPanelAlertDetailPane actionDetailsPane];
}

- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
    __block NSString    *dateString;
	
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:NO showingAMorPM:YES perform:^(NSDateFormatter *dateFormatter){
		dateString =  [dateFormatter stringFromDate:[NSCalendarDate calendarDate]];
	}];
	
	NSString	*alertText = [[details objectForKey:KEY_ALERT_TEXT] lastPathComponent];

	//Display an alert
    [[ErrorMessageWindowController errorMessageWindowController] displayError:listObject.displayName 
															  withDescription:(alertText ? [NSString stringWithFormat:@"%@: %@", dateString, alertText] : @"")
																	withTitle:AILocalizedString(@"Contact Alert",nil)];
	
	return YES;
}


#pragma mark Error Message event
// Error Message Event (global only)
- (NSString *)shortDescriptionForEventID:(NSString *)eventID {	return @""; }

- (NSString *)globalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:INTERFACE_ERROR_MESSAGE]) {
		description = AILocalizedString(@"Error occurs",nil);
	} else {
		description = @"";
	}
	
	return description;
}

//Evan: This exists because old X(tras) relied upon matching the description of event IDs, and I don't feel like making
//a converter for old packs.  If anyone wants to fix this situation, please feel free :)
- (NSString *)englishGlobalShortDescriptionForEventID:(NSString *)eventID
{
	NSString	*description;
	
	if ([eventID isEqualToString:INTERFACE_ERROR_MESSAGE]) {
		description = @"Error";
	} else {
		description = @"";
	}
	
	return description;
}


- (NSString *)longDescriptionForEventID:(NSString *)eventID forListObject:(AIListObject *)listObject	
{
	NSString	*description;

	if ([eventID isEqualToString:INTERFACE_ERROR_MESSAGE]) {
		description = AILocalizedString(@"When an error occurs",nil);
	} else {
		description = @"";
	}
	
	return description;
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return YES;
}

- (NSString *)naturalLanguageDescriptionForEventID:(NSString *)eventID
										listObject:(AIListObject *)listObject
										  userInfo:(id)userInfo
									includeSubject:(BOOL)includeSubject
{
	NSString	*description = nil;

	if ([eventID isEqualToString:INTERFACE_ERROR_MESSAGE]) {
		NSString	*errorTitle = [userInfo objectForKey:@"Title"];
		NSString	*errorDescription = [userInfo objectForKey:@"Description"];
		if (errorTitle && errorDescription) {
			description = [NSString stringWithFormat:@"%@\n%@",errorTitle,errorDescription];
			
		} else if (errorTitle || errorDescription) {
			description = (errorTitle ? errorTitle : errorDescription);
			
		} else {
			description = AILocalizedString(@"An error occurred",nil);
		}

	} else {
		description = @"";
	}
	
	return description;
}

- (NSImage *)imageForEventID:(NSString *)eventID
{
	static NSImage	*eventImage = nil;
	if (!eventImage) eventImage = [NSImage imageNamed:@"events-error-alert" forClass:[self class]];
	return eventImage;
}

- (NSString *)descriptionForCombinedEventID:(NSString *)eventID
							  forListObject:(AIListObject *)listObject
									forChat:(AIChat *)chat
								  withCount:(NSUInteger)count
{
	return [NSString stringWithFormat:AILocalizedString(@"%u errors", nil), count];
}

@end
