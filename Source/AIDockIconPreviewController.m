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

#import "AIDockIconPreviewController.h"
#import <Adium/AIIconState.h>
#import <Adium/AIDockControllerProtocol.h>
#import <AIUtilities/AIVerticallyCenteredTextCell.h>

@implementation AIDockIconPreviewController

- (NSView *) previewView
{
	return tableView;
}

- (void) setXtra:(AIXtraInfo *)xtraInfo
{
	[images autorelease];
	[statusNames autorelease];
	NSDictionary * pack = [[adium.dockController iconPackAtPath:[xtraInfo path]] objectForKey:@"State"];
	images = [[pack allValues] retain];
	statusNames = [[pack allKeys] retain];
	[tableView reloadData];
	[tableView sizeToFit];
}

- (void) awakeFromNib
{	
	[tableView setHeaderView:nil];
	[tableView setRowHeight:48.0f];
	
	NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:@"Dock Icon"];
	[column setMaxWidth:48.0f];
	[column setMinWidth:48.0f];
	[column setDataCell:[[[NSImageCell alloc]init]autorelease]];
	[tableView addTableColumn:column];
	[column release];
	
	column = [[NSTableColumn alloc] initWithIdentifier:@"Status"];
	[column setDataCell:[[[AIVerticallyCenteredTextCell alloc] init] autorelease]];
	[tableView addTableColumn:column];
	[column release];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [statusNames count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if([[aTableColumn identifier] isEqualToString:@"Dock Icon"])
		return [[images objectAtIndex:rowIndex] image];
	else
		return [statusNames objectAtIndex:rowIndex];
}

@end
