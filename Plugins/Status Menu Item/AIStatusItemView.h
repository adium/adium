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

#import "AIImageTextCellView.h"

@interface AIStatusItemView : AIImageTextCellView {
	NSStatusItem			*statusItem;
	
	BOOL					mouseDown;
	
	NSImage					*regularImage;
	NSImage					*alternateImage;
	
	NSMenu					*menu;
	NSMenu					*alternateMenu;
}

@property(readonly) NSUInteger desiredWidth;

@property(copy) NSImage *regularImage;
@property(copy) NSImage *alternateImage;

//These are by retain in case you want to set a delegate for the menu.
@property(retain) NSMenu *menu;
@property(retain) NSMenu *alternateMenu;

@property(assign) NSStatusItem *statusItem;

@end
