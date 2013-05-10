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

#import "AIMiniToolbarCenter.h"
#import "AIMiniToolbarItem.h"
#import "AIMiniToolbar.h"
#import "AIVerticallyCenteredTextCell.h"
#import "AIMiniToolbarCustomizeController.h"

@interface AIMiniToolbarCenter (PRIVATE)
- (id)init;
- (void)dragItem:(NSNumber *)inRow;
@end

@implementation AIMiniToolbarCenter

static AIMiniToolbarCenter *defaultCenter = nil;
+ (id)defaultCenter
{
    if(!defaultCenter){
        defaultCenter = [[self alloc] init];
    }
    
    return defaultCenter;
}

//Return the 'AIMiniToolbarItem's for the specified toolbar
- (NSArray *)itemsForToolbar:(NSString *)inType
{
    return [toolbarDict objectForKey:inType];
}

//Returns all the available toolbar items
- (NSArray *)allItems
{
    return [itemDict allValues];
}

//Set the toolbar item identifiers associated with a toolbar
- (void)setItems:(NSArray *)inItems forToolbar:(NSString *)inType
{
    //Change the items
    [toolbarDict setObject:inItems forKey:inType];

    //Send out a notification
    [[NSNotificationCenter defaultCenter] postNotificationName:AIMiniToolbar_ItemsChanged object:inType userInfo:nil];
}

//Register a toolbar item
- (void)registerItem:(AIMiniToolbarItem *)inItem
{
    [itemDict setObject:inItem forKey:[inItem identifier]];
}

//Returns a new instance of the specifed toolbar item
- (AIMiniToolbarItem *)itemWithIdentifier:(NSString *)inIdentifier
{
    return [[[itemDict objectForKey:inIdentifier] copy] autorelease];
}

//Show the customization palette
- (IBAction)customizeToolbar:(AIMiniToolbar *)toolbar
{
    if(![self customizing:toolbar]){ //Do nothing if this toolbar is already being customized
        if(customizeController){
            ///End any existing customization
            [customizeController close];
            [customizeController release]; customizeController = nil;
        }
        
        //Display the customization palette
        customizeController = [[AIMiniToolbarCustomizeController customizationWindowControllerForToolbar:toolbar] retain];
        [customizeController showWindow:nil];

        //Add it to our customizing list and notify
        if(customizeIdentifier){
            [customizeIdentifier release];
        }

        customizeIdentifier = [[toolbar identifier] retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:AIMiniToolbar_RefreshItem object:nil];
    }
}

//Returns yes if the specified toolbar is being customized
- (BOOL)customizing:(AIMiniToolbar *)toolbar
{
    if(customizeIdentifier && (toolbar == nil || [customizeIdentifier isEqualToString:[toolbar identifier]])){
        return YES;
    }else{
        return NO;
    }
}

//Closes the customization palettes
- (IBAction)endCustomization:(AIMiniToolbar *)toolbar
{
    [customizeController closeWindow:nil];
}

//Called by the customization window as it closes
- (void)customizationDidEnd:(AIMiniToolbar *)inToolbar
{
    //Release the customization panel
    [customizeController autorelease]; customizeController = nil;

    //Remove it from our list and notify
    [customizeIdentifier release]; customizeIdentifier = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:AIMiniToolbar_RefreshItem object:nil];
}


// Private ---------------------------------------------------------------------------
- (id)init
{
	if(([super init])) {
		toolbarDict = [[NSMutableDictionary alloc] init];
		itemDict = [[NSMutableDictionary alloc] init];
		customizeIdentifier = nil;
		customizeController = nil;
	}
	return self;
}

- (void)dealloc
{
    [toolbarDict release];
    [itemDict release];
    [customizeIdentifier release];
    [customizeController release];

    [super dealloc];
}


@end
