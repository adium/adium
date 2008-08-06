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

#import "AIStatusIconPreviewController.h"

@implementation AIStatusIconPreviewController

- (NSView *) previewView
{
	return tableView;
}

- (void) setXtra:(AIXtraInfo *)xtraInfo
{
	[images autorelease];
	images = [[NSMutableArray alloc] init];
	[statusNames autorelease];
	NSEnumerator * paths;
	NSString * resourcePath = [xtraInfo resourcePath];
	NSDictionary * iconDict = [[NSDictionary dictionaryWithContentsOfFile:[resourcePath stringByAppendingPathComponent:@"Icons.plist"]] objectForKey:@"List"];
	
	paths = [[iconDict allValues] objectEnumerator];
	statusNames = [[iconDict allKeys] retain];
			
	NSImage * image;
	NSString * imageName;
	NSString * imagePath;
	while((imageName = [paths nextObject]))
	{
		imagePath = [resourcePath stringByAppendingPathComponent:imageName];
		image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
		if(image)
			[images addObject:image];
	}
	[tableView reloadData];
	[tableView sizeToFit];
}

- (void) awakeFromNib
{	
	[tableView setIntercellSpacing:NSMakeSize(1.0f, 3.0f)];
	[tableView setHeaderView:nil];
	
	NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:@"Status Icon"];
	[column setMaxWidth:32.0f];
	[column setMinWidth:32.0f];
	[column setDataCell:[[[NSImageCell alloc]init]autorelease]];
	[tableView addTableColumn:column];
	[column release];
	
	column = [[NSTableColumn alloc] initWithIdentifier:@"Status Name"];
	[tableView addTableColumn:column];
	[column release];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	return NO;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [statusNames count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if([[aTableColumn identifier] isEqualToString:@"Status Icon"])
		return [images objectAtIndex:rowIndex];
	else
		return [statusNames objectAtIndex:rowIndex];
}

@end
