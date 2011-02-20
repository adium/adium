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
