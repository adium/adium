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

/*
 Friends don't let friends use metal.  If this class is in your project, it means you've taken responsibility
for the actions of others, following only the true, Aqua path to peace, justice, and a bigger slice of the pizza pie.
*/

#import <Adium/ItIsNotACoincidenceThatMetalAndDevilNearlyRhymeWindow.h>

@implementation ItIsNotACoincidenceThatMetalAndDevilNearlyRhymeWindow

+ (void)load
{
	//Pose as NSWindow if not on Leopard.
	//Leopard erases the distinction between BM and Aqua, so we don't need to do this after Leopard.
	//And since we don't support anything but Tiger and Leopard now, we can just check Tiger.
	if ([NSApp isTiger]) {
    	//Anything you can do, I can do better...
    	[self poseAsClass:[NSWindow class]];
	}
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	//Cancel out any attempt to create Windows Of Satan.
	if (styleMask & NSTexturedBackgroundWindowMask) {
		styleMask &= ~NSTexturedBackgroundWindowMask;
	}

	//Otherwise, proceed as normal.
	return ([super initWithContentRect:contentRect
					 styleMask:styleMask
					   backing:backingType
						 defer:flag]);
}
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag screen:(NSScreen *)aScreen
{
	//Fight the good fight.
	if (styleMask & NSTexturedBackgroundWindowMask) {
		styleMask &= ~NSTexturedBackgroundWindowMask;
	}

	//Otherwise, proceed as normal.
	return [super initWithContentRect:contentRect
					 styleMask:styleMask
					   backing:backingType
						 defer:flag
						screen:aScreen];
}

@end
