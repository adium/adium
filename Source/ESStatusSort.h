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

#import <Adium/AISortController.h>

@class AILocalizationTextField;

@interface ESStatusSort : AISortController <NSTableViewDelegate, NSTableViewDataSource> {
	IBOutlet	NSButton		*checkBox_groupAvailable;
	IBOutlet	NSButton		*checkBox_groupMobileSeparately;
	
	IBOutlet	NSMatrix		*matrix_unavailableGrouping;
	IBOutlet	NSButtonCell	*buttonCell_allUnavailable;
	IBOutlet	NSButtonCell	*buttonCell_separateUnavailable;
	IBOutlet	NSButton		*checkBox_groupAway;
	IBOutlet	NSButton		*checkBox_groupIdle;
	IBOutlet	NSButton		*checkBox_groupIdleAndAway;
	
	IBOutlet	NSButton		*checkBox_sortIdleTime;
	IBOutlet	NSButton		*checkBox_sortGroupsAlphabetically;
	
	IBOutlet	AILocalizationTextField	*label_sortWithinEachStatusGrouping;

	IBOutlet	NSMatrix		*matrix_resolution;
	IBOutlet	NSButtonCell	*buttonCell_alphabetically;
	IBOutlet	NSButton		*checkBox_alphabeticallyByLastName;
	IBOutlet	NSButtonCell	*buttonCell_manually;
	
	IBOutlet	AILocalizationTextField	*label_statusGroupOrdering;	
	IBOutlet	NSTableView		*tableView_sortOrder;
	IBOutlet	NSWindow		*window;
}

- (IBAction)closeSheet:(id)sender;

@end
