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

#import "AIDockTile.h"

@implementation AIDockTile

- (void)setDockTile:(NSDockTile *)inDockTile
{
	if (!inDockTile) return;
	
	CFPreferencesAppSynchronize(CFSTR("com.adiumX.adiumX"));
	CFStringRef path = CFPreferencesCopyAppValue(CFSTR("DockTilePath"), CFSTR("com.adiumX.adiumX"));
	
	if (!path) {
		NSLog(@"AIDockTilePlugin: DockTilePath not found.");
		return;
	}
	
	NSImage *image = [[[NSImage alloc] initByReferencingFile:(NSString *)path] autorelease];
	NSImageView *view = [[[NSImageView alloc] init] autorelease];
	
	[view setImage:image];
	[inDockTile setContentView:view];
	[inDockTile display];
	
	CFRelease(path);
}

- (void)launchDebug
{
	NSString *path = [[NSBundle bundleForClass:[self class]] bundlePath];
	
	NSMutableArray *pathComponents = [[[path pathComponents] mutableCopy] autorelease];
	
	// PlugIns/AIDockTilePlugin.docktileplugin
	[pathComponents removeLastObject];
	[pathComponents removeLastObject];
	
	NSString *adiumPath = [[[NSString pathWithComponents:pathComponents] stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:@"Adium"];
		
	NSTask *adiumTask = [[[NSTask alloc] init] autorelease];
	
	[adiumTask setLaunchPath:adiumPath];
	[adiumTask setArguments:@[@"--debug"]];
	
	[adiumTask launch];
}

- (NSMenu *)dockMenu
{
	if (dockMenu) return dockMenu;
	
	dockMenu = [[NSMenu alloc] init];
	NSMenuItem *menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Launch in Debug Mode"
																				action:@selector(launchDebug)
																		 keyEquivalent:@""];
	menuItem.target = self;
	
	[dockMenu addItem:menuItem];
	
	[menuItem release];
	
	return dockMenu;
}

- (void)dealloc
{
	[dockMenu release];
	
	[super dealloc];
}

@end
