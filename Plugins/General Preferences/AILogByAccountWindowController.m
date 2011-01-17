//
//  AILogByAccountWindowController.m
//  Adium
//
//  Created by Zachary West on 2011-01-14.
//  Copyright 2011  . All rights reserved.
//

#import "AILogByAccountWindowController.h"

#import "AIAccountControllerProtocol.h"
#import "AILoggerPlugin.h"
#import <Adium/AIServiceIcons.h>
#import "AIAccount.h"

@implementation AILogByAccountWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	if((self = [super initWithWindowNibName:windowNibName])) {
		accounts = [adium.accountController.accounts retain];
	}
	return self;
}

- (void)dealloc
{
	[accounts release];
	[super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [accounts count];
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	if([aTableColumn.identifier isEqualToString:@"checkbox"]) {
		NSNumber *disabled = [[accounts objectAtIndex:rowIndex] preferenceForKey:KEY_LOGGER_OBJECT_DISABLE
																		   group:PREF_GROUP_LOGGING];
		
		return [NSNumber numberWithBool:![disabled boolValue]];
	} else if([aTableColumn.identifier isEqualToString:@"icon"]) {
		return [AIServiceIcons serviceIconForObject:[accounts objectAtIndex:rowIndex]
											   type:AIServiceIconLarge
										  direction:AIIconNormal];
	} else if([aTableColumn.identifier isEqualToString:@"accountName"]) {
		return [[accounts objectAtIndex:rowIndex] explicitFormattedUID];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if([aTableColumn.identifier isEqualToString:@"checkbox"]) {
		[[accounts objectAtIndex:rowIndex] setPreference:[NSNumber numberWithBool:![object boolValue]]
												  forKey:KEY_LOGGER_OBJECT_DISABLE
												   group:PREF_GROUP_LOGGING];
	}
}

- (IBAction)done:(id)sender
{
	[NSApp endSheet:self.window];
}

@end
