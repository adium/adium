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

#import "ESPurpleJabberAccountViewController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIService.h>
#include <SystemConfiguration/SystemConfiguration.h>

#define SERVERFEEDRSSURL @"https://www.xmpp.net/servers/feed/rss"

@implementation ESPurpleJabberAccountViewController

- (NSString *)nibName{
    return @"ESPurpleJabberAccountView";
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[checkBox_checkMail setEnabled:NO];
	
	[[adium notificationCenter] addObserver:self
								   selector:@selector(contactListChanged:)
									   name:Contact_ListChanged
									 object:nil];
}

//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	//Connection security
	[checkBox_forceOldSSL setState:[[account preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_requireTLS setState:[[account preferenceForKey:KEY_JABBER_REQUIRE_TLS group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_checkCertificates setState:[account preferenceForKey:KEY_JABBER_VERIFY_CERTS group:GROUP_ACCOUNT_STATUS]?[[account preferenceForKey:KEY_JABBER_VERIFY_CERTS group:GROUP_ACCOUNT_STATUS] boolValue]:YES];
	[checkBox_allowPlaintext setState:[[account preferenceForKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS] boolValue]];
	
	//Resource
	if([account preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS])
		[textField_resource setStringValue:[account preferenceForKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS]];
	else
		[textField_resource setStringValue:[(NSString*)SCDynamicStoreCopyLocalHostName(NULL) autorelease]];
	
	//Connect server
	NSString *connectServer = [account preferenceForKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	[textField_connectServer setStringValue:(connectServer ? connectServer : @"")];
	
	//Priority
	NSNumber *priority = [account preferenceForKey:KEY_JABBER_PRIORITY_AVAILABLE group:GROUP_ACCOUNT_STATUS];
	[textField_priorityAvailable setStringValue:(priority ? [priority stringValue] : @"")];
	priority = [account preferenceForKey:KEY_JABBER_PRIORITY_AWAY group:GROUP_ACCOUNT_STATUS];
	[textField_priorityAway setStringValue:(priority ? [priority stringValue] : @"")];
		
	//Subscription behavior
	int subbeh = [[account preferenceForKey:KEY_JABBER_SUBSCRIPTION_BEHAVIOR group:GROUP_ACCOUNT_STATUS] intValue];
	[popup_subscriptionBehavior selectItemWithTag:subbeh];
	NSString *defaultGroup = [account preferenceForKey:KEY_JABBER_SUBSCRIPTION_GROUP group:GROUP_ACCOUNT_STATUS];
	[comboBox_subscriptionGroup setStringValue:(defaultGroup ? defaultGroup : @"")];
	
	//Hide the register button if the account can't register new accounts
	[button_register setHidden:![[account service] canRegisterNewAccounts]];
	
	//Set hidden flag of the default group combobox
	[self subscriptionModeDidChange:nil];
}

//Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
	
	//Connection security
	[account setPreference:[NSNumber numberWithBool:[checkBox_forceOldSSL state]]
					forKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:[checkBox_requireTLS state]]
								   forKey:KEY_JABBER_REQUIRE_TLS group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:[checkBox_checkCertificates state]]
					forKey:KEY_JABBER_VERIFY_CERTS group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithBool:[checkBox_allowPlaintext state]]
					forKey:KEY_JABBER_ALLOW_PLAINTEXT group:GROUP_ACCOUNT_STATUS];

	//Resource
	[account setPreference:([[textField_resource stringValue] length] ? [textField_resource stringValue] : nil)
					forKey:KEY_JABBER_RESOURCE group:GROUP_ACCOUNT_STATUS];
	
	//Connect server
	[account setPreference:([[textField_connectServer stringValue] length] ? [textField_connectServer stringValue] : nil)
					forKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];

	//Priority
	[account setPreference:([textField_priorityAvailable intValue] ? [NSNumber numberWithInt:[textField_priorityAvailable intValue]] : nil)
					forKey:KEY_JABBER_PRIORITY_AVAILABLE
					 group:GROUP_ACCOUNT_STATUS];
	[account setPreference:([textField_priorityAway intValue] ? [NSNumber numberWithInt:[textField_priorityAway intValue]] : nil)
					forKey:KEY_JABBER_PRIORITY_AWAY
					 group:GROUP_ACCOUNT_STATUS];

	//Subscription Behavior
	[account setPreference:([[popup_subscriptionBehavior selectedItem] tag] ? [NSNumber numberWithInt:[[popup_subscriptionBehavior selectedItem] tag]] : nil)
					forKey:KEY_JABBER_SUBSCRIPTION_BEHAVIOR
					 group:GROUP_ACCOUNT_STATUS];
	[account setPreference:([[comboBox_subscriptionGroup stringValue] length] ? [comboBox_subscriptionGroup stringValue] : nil)
					forKey:KEY_JABBER_SUBSCRIPTION_GROUP group:GROUP_ACCOUNT_STATUS];
}

- (IBAction)subscriptionModeDidChange:(id)sender {
	// only show these two when "accept and add to contact list" is selected
	int tag = [[popup_subscriptionBehavior selectedItem] tag];
	[textField_subscriptionModeLabel setHidden:tag != 2];
	[comboBox_subscriptionGroup setHidden:tag != 2];
}

- (void)dealloc {
	[[adium notificationCenter] removeObserver:self];
	[window_registerServer release];
	[servers release];

	[super dealloc];
}

#pragma mark group combobox datasource

- (void)contactListChanged:(NSNotification*)n {
	[comboBox_subscriptionGroup reloadData];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	AIListGroup *list = [[adium contactController] contactList];
	return [list containedObjectsCount];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index {
	AIListGroup *list = [[adium contactController] contactList];
	return [[list objectAtIndex:index] formattedUID];
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string {
	AIListGroup *list = [[adium contactController] contactList];
	NSArray *groups = [list containedObjects];
	unsigned i;
	for(i=0;i < [groups count];++i) {
		AIListGroup *group = [groups objectAtIndex:i];
		if([[group formattedUID] isEqualToString:string])
			return i;
	}
	return NSNotFound;
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)string {
	AIListGroup *list = [[adium contactController] contactList];
	NSArray *groups = [list containedObjects];
	unsigned i;
	for(i=0;i < [groups count];++i) {
		AIListGroup *group = [groups objectAtIndex:i];
		if([[group formattedUID] hasPrefix:string])
			return [group formattedUID];
	}
	return string;
}

#pragma mark account creation

static int compareByDistance(id one, id two, void*context) {
	NSNumber *dist1obj = [one objectForKey:@"distance"];
	NSNumber *dist2obj = [two objectForKey:@"distance"];
	
	if((id)dist2obj == [NSNull null]) {
		if((id)dist1obj == [NSNull null])
			return NSOrderedSame;
		return NSOrderedAscending;
	}
	if((id)dist1obj == [NSNull null])
		return NSOrderedDescending;
	
	float dist1 = [dist1obj floatValue];
	float dist2 = [dist2obj floatValue];
	
	if(fabs(dist1 - dist2) < 0.000001)
		return NSOrderedSame;
	
	if(dist1 > dist2)
		return NSOrderedDescending;
	return NSOrderedAscending;
}

- (IBAction)registerNewAccount:(id)sender {
	if(!servers) {
		NSError *err = NULL;
		NSXMLDocument *serverfeed = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL URLWithString:SERVERFEEDRSSURL]
																		 options:0
																		   error:&err];
		if(err) {
			[[NSAlert alertWithError:err] runModal];
		} else {
			NSXMLElement *root = [serverfeed rootElement];
			NSArray *channels = [root elementsForName:@"channel"];
			
			if(!root || !channels || ![[root name] isEqualToString:@"rss"] || [channels count] != 1) {
				[serverfeed release];
				
				[[NSAlert alertWithMessageText:AILocalizedString(@"Parse Error.",nil)
								 defaultButton:AILocalizedString(@"OK",nil)
							   alternateButton:nil
								   otherButton:nil
					 informativeTextWithFormat:[NSString stringWithFormat:
												AILocalizedString(@"Unable to parse the server list at %@. Please try again later.",nil), SERVERFEEDRSSURL]] runModal];
			} else {
				float longitude, latitude;
				
				MachineLocation loc;
				ReadLocation(&loc);
				
				latitude = FractToFloat(loc.latitude)*(M_PI/2.0f);
				longitude = FractToFloat(loc.longitude)*(M_PI/2.0f);
				
				servers = [[NSMutableArray alloc] init];
				NSEnumerator *enumer = [[[channels lastObject] elementsForName:@"item"] objectEnumerator];
				NSXMLElement *item;
				
				while((item = [enumer nextObject])) {
					NSXMLElement *title = [[item elementsForName:@"title"] lastObject];
					if(!title)
						continue;
					NSXMLElement *description = [[item elementsForName:@"description"] lastObject];
					NSXMLElement *latitudeNode  = [[item elementsForLocalName:@"latitude"  URI:@"http://geourl.org/rss/module/"] lastObject];
					NSXMLElement *longitudeNode = [[item elementsForLocalName:@"longitude" URI:@"http://geourl.org/rss/module/"] lastObject];
					
					id distance = [NSNull null];
					if (latitudeNode && longitudeNode) {
						/* Calculate the distance between the computer and the xmpp server in km
						 * Note that this assumes that the earth is a perfect sphere
						 * If it turns out to be flat or doughnut-shaped, this will not work!
						 */
						
						float latitude2 = [[latitudeNode stringValue] floatValue] * (M_PI/180.0f);
						float longitude2 = [[longitudeNode stringValue] floatValue] * (M_PI/180.0f);
						
						float d_lat = sinf((latitude2 - latitude)/2.0);
						float d_long = sinf((longitude2 - longitude)/2.0);
						float a = d_lat*d_lat + cosf(latitude)*cosf(latitude2)*d_long*d_long;
						float c = 2*atan2f(sqrtf(a),sqrtf(1.0-a));
						float d = 6372.797*c; // mean earth radius
						
						distance = [NSNumber numberWithFloat:d];
					}
					
					[(NSMutableArray*)servers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[title stringValue], @"servername",
						(description ? (id)[description stringValue] : (id)[NSNull null]), @"description",
						distance, @"distance",
						nil]];
				}
				
				[serverfeed release];
				
				[(NSMutableArray*)servers sortUsingFunction:compareByDistance context:nil];
				
				[tableview_servers reloadData];
			}
		}
	}
	
	[NSApp beginSheet:window_registerServer
	   modalForWindow:[sender window]
		modalDelegate:self
	   didEndSelector:@selector(registrationSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}

- (void)registrationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [servers count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	id objectValue = [[servers objectAtIndex:row] objectForKey:[tableColumn identifier]];
	return ((objectValue && ![objectValue isKindOfClass:[NSNull class]]) ? objectValue : @"");
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSString *servername = [self tableView:[notification object] objectValueForTableColumn:[[notification object] tableColumnWithIdentifier:@"servername"] row:[[notification object] selectedRow]];
	[textField_registerServerName setStringValue:servername];
	[textField_registerServerPort setStringValue:@""];
}

- (IBAction)registerCancel:(id)sender {
	[window_registerServer orderOut:nil];
	[NSApp endSheet:window_registerServer];
}

- (IBAction)registerRequestAccount:(id)sender {
	[[sender window] makeFirstResponder:nil]; // apply all changes
	if([[textField_registerServerName stringValue] length] == 0) {
		NSBeep();
		return;
	}
//	[account setUID:[NSString stringWithFormat:@"unknown@%@", [textField_registerServerName stringValue]]];
	[account setPreference:[textField_registerServerName stringValue]
					forKey:KEY_JABBER_CONNECT_SERVER group:GROUP_ACCOUNT_STATUS];
	[account setPreference:[NSNumber numberWithInt:[textField_registerServerPort intValue]]
					forKey:KEY_CONNECT_PORT group:GROUP_ACCOUNT_STATUS];

	NSString *newUID;
	if ([[textField_accountUID stringValue] length]) {
		NSRange atLocation = [[textField_accountUID stringValue] rangeOfString:@"@" options:NSLiteralSearch];
		if (atLocation.location == NSNotFound)
			newUID = [NSString stringWithFormat:@"%@@%@",[textField_accountUID stringValue], [textField_registerServerName stringValue]];
		else
			newUID = [NSString stringWithFormat:@"%@@%@",[[textField_accountUID stringValue] substringToIndex:atLocation.location], [textField_registerServerName stringValue]];
	} else {
		newUID = [NSString stringWithFormat:@"nobody@%@",[textField_registerServerName stringValue]];
	}

	[account filterAndSetUID:newUID];
	
	[window_registerServer orderOut:nil];
	[NSApp endSheet:window_registerServer];
	
	[account performRegisterWithPassword:[textField_password stringValue]];
	[self didBeginRegistration];
}

@end
