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

#import "AIContactInfoContentController.h"

@interface AIContactInfoContentController ()
-(void)_setLoadedPanes:(NSArray *)anArray;
@end

@implementation AIContactInfoContentController

+ (AIContactInfoContentController *)defaultInfoContentController
{
	return [[[self alloc] initWithContentPanes:[self defaultPanes]] autorelease];
}

- (id)initWithContentPanes:(NSArray *)panes
{
	if ((self = [self init])) {
		[self loadContentPanes:panes];
	}

	return self;
}

- (void)dealloc
{
	[loadedPanes release];
	
	[super dealloc];
}

+(NSArray *)defaultPanes
{
	return [NSArray arrayWithObjects:@"AIInfoInspectorPane", @"AIAddressBookInspectorPane", @"AIEventsInspectorPane",
			@"AIAdvancedInspectorPane", nil];
}

-(NSArray *)loadedPanes
{
	return loadedPanes;
}

-(void)_setLoadedPanes:(NSArray *)newPanes
{
	if (loadedPanes != newPanes)
	{
		[loadedPanes release];
		loadedPanes = [newPanes retain];
	}
}

-(void)loadContentPanes:(NSArray *)contentPanes
{
	NSMutableArray *contentArray = [NSMutableArray array];
	//Allocate and initialize each class, then stick it in the array.
	id currentPane = nil;
	
	for(currentPane in contentPanes) {
		Class paneClass = nil;
		if(!(paneClass = NSClassFromString(currentPane))) {
			AILogWithSignature(@"Warning: Could not obtain a class for %@", currentPane);
			return;
		}
		
		[contentArray addObject:[[[paneClass alloc] init] autorelease]];
	}

	[self _setLoadedPanes:contentArray];
}

-(IBAction)segmentSelected:(id)sender
{
#warning Needs implementation
}

@end
