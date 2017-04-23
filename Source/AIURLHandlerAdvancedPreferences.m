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

#import "AIURLHandlerAdvancedPreferences.h"
#import "AIPreferenceWindowController.h"

#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>

@interface AIURLHandlerAdvancedPreferences()
- (void)configureTableView;

- (void)initializeServiceInformationForSchemes:(NSArray *)schemes;
- (NSMenu *)applicationMenuForScheme:(NSString *)scheme;
- (NSArray *)applicationDictionaryArrayForScheme:(NSString *)scheme;
- (NSImage *)serviceImageForScheme:(NSString *)scheme;
- (NSString *)serviceNameForScheme:(NSString *)scheme;
@end

@implementation AIURLHandlerAdvancedPreferences
#pragma mark Preference pane settings
- (AIPreferenceCategory)category
{
    return AIPref_Advanced;
}
- (NSString *)label{
    return AILocalizedString(@"Default Client",nil);
}
- (NSString *)nibName{
    return @"AIURLHandlerPreferences";
}
- (NSImage *)image{
	return [NSImage imageNamed:@"pref-defaultclient" forClass:[AIPreferenceWindowController class]];
}

- (void)viewDidLoad
{
	[servicesList release];
	
	servicesList = [((AIURLHandlerPlugin *)plugin).uniqueSchemes retain];
	
	[self configureTableView];
	[self initializeServiceInformationForSchemes:servicesList];
	
	[button_setDefault setLocalizedString:AILocalizedString(@"Set Default for All", nil)];
	[checkBox_enforceDefault setLocalizedString:AILocalizedString(@"Always set Adium as the default", nil)];
	
	[checkBox_enforceDefault setState:[[adium.preferenceController preferenceForKey:PREF_KEY_ENFORCE_DEFAULT
																			  group:GROUP_URL_HANDLING] boolValue]];
	
	[tableView setEnabled:![[adium.preferenceController preferenceForKey:PREF_KEY_ENFORCE_DEFAULT
																   group:GROUP_URL_HANDLING] boolValue]];
	
	[super viewDidLoad];
}

- (void)dealloc
{
	[servicesList release];
	[services release];
	[super dealloc];
}

#pragma mark Actions
- (IBAction)setDefault:(id)sender
{
	[plugin setAdiumAsDefault];
	[tableView reloadData];
}

- (IBAction)enforceDefault:(id)sender
{
	[adium.preferenceController setPreference:[NSNumber numberWithBool:[sender state]]
									   forKey:PREF_KEY_ENFORCE_DEFAULT
										group:GROUP_URL_HANDLING];
	
	[tableView setEnabled:![sender state]];
	
	if ([sender state]) {
		[plugin setAdiumAsDefault];
	}
}

#pragma mark Scheme information
- (void)initializeServiceInformationForSchemes:(NSArray *)schemes
{
	[services release]; services = [[NSMutableDictionary alloc] init];
	
	for (NSString *scheme in schemes) {
		[services setObject:[NSMutableDictionary dictionary] forKey:scheme];
	}
}

- (NSMenu *)applicationMenuForScheme:(NSString *)scheme
{
	NSMutableDictionary		*servicesInformation = [services objectForKey:scheme];
	NSMenu					*menu = [servicesInformation objectForKey:@"applicationsMenu"];
	
	if (!menu) {
		menu = [[[NSMenu alloc] init] autorelease];
		
		for (NSDictionary *application in [self applicationDictionaryArrayForScheme:scheme]) {
			NSMenuItem *menuItem = [menu addItemWithTitle:[application objectForKey:@"ApplicationName"]
												   target:nil
												   action:nil
											keyEquivalent:@""];
			
			[menuItem setImage:[[application objectForKey:@"ApplicationImage"] imageByScalingForMenuItem]];
			[menuItem setRepresentedObject:[application objectForKey:@"BundleID"]];
		}
		
		[servicesInformation setObject:menu forKey:@"applicationsMenu"];
	}
	
	return menu;
}

- (NSArray *)applicationDictionaryArrayForScheme:(NSString *)scheme
{
	NSMutableDictionary		*servicesInformation = [services objectForKey:scheme];
	NSArray					*applications = [servicesInformation objectForKey:@"applications"];
	
	if (!applications) {
		NSArray					*applicationArray = [(NSArray *)LSCopyAllHandlersForURLScheme((CFStringRef)scheme) autorelease];
		NSMutableArray			*mutableApplications = [NSMutableArray array];
		
		for (NSString *bundleID in applicationArray) {
			// File System Ref for this bundle ID
			FSRef		fileSystemRef;
			OSStatus	err = LSFindApplicationForInfo(kLSUnknownCreator, (CFStringRef)bundleID, NULL, &fileSystemRef, NULL);
			
			if (err == kLSApplicationNotFoundErr) {
				return nil;
			}
			
			// Application Name
			HFSUniStr255	name;
			OSErr informationError = FSGetCatalogInfo(&fileSystemRef, kFSCatInfoNone, NULL, &name, NULL, NULL);
			if (informationError) { 
				return nil;
			}
			
			NSString	*applicationName = [NSString stringWithCharacters:name.unicode length:name.length];
			
			// Application Image
			IconRef iconRef;
			err = GetIconRefFromFileInfo(&fileSystemRef, 0, NULL, kFSCatInfoNone, NULL, kIconServicesNoBadgeFlag, &iconRef, NULL);
			if (err) {
				return nil;
			}
			
			NSImage *image = [[[NSImage alloc] initWithIconRef:iconRef] autorelease];
			
			[mutableApplications addObject:[NSDictionary dictionaryWithObjectsAndKeys:bundleID.lowercaseString, @"BundleID",
											applicationName, @"ApplicationName",
											image, @"ApplicationImage", nil]];
		}

		[servicesInformation setObject:mutableApplications forKey:@"applications"];
		
		applications = mutableApplications;
	}
	
	return applications;
}

- (NSImage *)serviceImageForScheme:(NSString *)scheme
{
	NSMutableDictionary		*servicesInformation = [services objectForKey:scheme];
	NSImage					*image = [servicesInformation objectForKey:@"image"];
	
	if (!image) {
		AIService *service = [adium.accountController firstServiceWithServiceID:[plugin serviceIDForScheme:scheme]];
		image = [AIServiceIcons serviceIconForService:service type:AIServiceIconLarge direction:AIIconNormal];
		if (image) [servicesInformation setObject:image forKey:@"image"];
	}
	
	return image;	
}

- (NSString *)serviceNameForScheme:(NSString *)scheme
{
	NSMutableDictionary		*servicesInformation = [services objectForKey:scheme];
	NSString				*longServiceName = [servicesInformation objectForKey:@"name"];
	
	if (!longServiceName) {
		AIService *service = [adium.accountController firstServiceWithServiceID:[plugin serviceIDForScheme:scheme]];
		longServiceName = [service longDescription];
		[servicesInformation setObject:(longServiceName ?: @"(unknown)") forKey:@"name"];
	}
	
	return longServiceName;
}

#pragma mark Table view Delegate

- (void)refreshTable
{
	[tableView reloadData];
}

- (void)configureTableView
{
	AIImageTextCell		*imageTextCell = [[AIImageTextCell alloc] init];
	[imageTextCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[[tableView tableColumnWithIdentifier:@"service"] setDataCell:imageTextCell];
	[imageTextCell release];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return servicesList.count;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *identifier = tableColumn.identifier;
	NSString *scheme = [servicesList objectAtIndex:row];
	
	if ([identifier isEqualToString:@"service"]) {
		// Configure to display the service icon and service name.
		[cell setImage:[self serviceImageForScheme:scheme]];
	} else if ([identifier isEqualToString:@"applications"]) {
		NSMenu *menu = [self applicationMenuForScheme:scheme];
		NSString *defaultApplication = [plugin defaultApplicationBundleIDForScheme:scheme];

		// Letting the NSPopupButtonCell handle state causes some buggy results. Do it ourself.
		for (NSMenuItem *menuItem in menu.itemArray) {
			[menuItem setState:[menuItem.representedObject isEqualToString:defaultApplication]];
		}
		
		[cell setMenu:menu];
		[cell setAltersStateOfSelectedItem:NO];
		[cell selectItemAtIndex:[cell indexOfItemWithRepresentedObject:defaultApplication]];
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *identifier = tableColumn.identifier;
	NSString *scheme = [servicesList objectAtIndex:row];
	
	if ([identifier isEqualToString:@"service"]) {
		return [self serviceNameForScheme:scheme];
	}
	
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *identifier = tableColumn.identifier;
	NSString *scheme = [servicesList objectAtIndex:row];
	
	if ([identifier isEqualToString:@"applications"]) {
		[plugin setDefaultForScheme:scheme
						 toBundleID:[[[self applicationMenuForScheme:scheme] itemAtIndex:[object integerValue]] representedObject]];
	}
}

@end
