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

#import "AIEmoticonPreviewController.h"
#import "AIEmoticonPack.h"
#import "AIEmoticon.h"

@implementation AIEmoticonPreviewController

- (NSView *) previewView
{
	return tableView;
}

- (void) awakeFromNib
{	
	[tableView setIntercellSpacing:NSMakeSize(1.0f, 3.0f)];
	[tableView setHeaderView:nil];
	
	NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:@"Emoticon"];
	[column setMaxWidth:32.0f];
	[column setMinWidth:32.0f];
	[column setDataCell:[[[NSImageCell alloc]init]autorelease]];
	[tableView addTableColumn:column];
	[column release];
	
	column = [[NSTableColumn alloc] initWithIdentifier:@"Text Equivalent"];
	[tableView addTableColumn:column];
	[column release];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	return NO;
}

- (void) setXtra:(AIXtraInfo *)xtraInfo
{
	[emoticons autorelease];
	emoticons = [[[AIEmoticonPack emoticonPackFromPath:[xtraInfo path]] emoticons] retain];
	[tableView reloadData];
	[tableView sizeToFit];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [emoticons count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	AIEmoticon * emoticon = [emoticons objectAtIndex:rowIndex];
	if([[aTableColumn identifier] isEqualToString:@"Emoticon"])
		return [emoticon image];
	else
		return [[emoticon textEquivalents] componentsJoinedByString:@", "];
}

@end
