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

#import "AIMiniToolbarTableView.h"
#import	"AIMiniToolbarItem.h"
#import "AIMiniToolbarCenter.h"
#import "AIMiniToolbarCustomizeController.h"

@implementation AIMiniToolbarTableView

//Simple subclass of table view to initiate a drag from within the mouse down event (as the drag methods require)

//Initiate a drag on mouse down
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint		clickLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    int			dragRow;

    //Get the clicked item
    dragRow = [self rowAtPoint:clickLocation];
    if(dragRow != -1){
        [controller dragItemAtRow:dragRow fromPoint:clickLocation withEvent:theEvent];
    }
}

//Allow dragging from the table view while the window is in the background
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

@end
