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

#import "AIDockController.h"
#import "AIDockIconSelectionSheet.h"
#import "AIAppearancePreferencesPlugin.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageGridView.h>
#import <AIUtilities/AIBezierPathAdditions.h>
#import <AIUtilities/AIGradientAdditions.h>
#import <Adium/AIIconState.h>

#define PREF_GROUP_DOCK_ICON		@"Dock Icon"
#define DEFAULT_DOCK_ICON_NAME		@"Adiumy Green"

@interface AIDockIconSelectionSheet ()
- (void)selectIconWithName:(NSString *)selectName;
- (void)xtrasChanged:(NSNotification *)notification;
- (void)selectIconWithName:(NSString *)selectName;
@end

@implementation AIDockIconSelectionSheet

+ (void)showDockIconSelectorOnWindow:(NSWindow *)parentWindow
{
	AIDockIconSelectionSheet	*controller;
	
	controller = [[self alloc] initWithWindowNibName:@"DockIconSelectionSheet"];
	
	if (parentWindow) {
		[NSApp beginSheet:[controller window]
		   modalForWindow:parentWindow
			modalDelegate:controller
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:nil];
	} else {
		[controller showWindow:nil];
		[[controller window] makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}
}

/*!
 * Invoked as the sheet closes, dismiss the sheet
 */
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:nil];

    [self setAnimatedDockIconAtIndex:-1];
	[self autorelease];
}

//Setup our preference view
- (void)windowDidLoad
{
	//Init
	animatedIndex = -1;
	iconArray = nil;

	//Setup our image grid
	[imageGridView_icons setImageSize:NSMakeSize(64,64)];

    //Observe xtras changes
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:AIXtrasDidChangeNotification
									 object:nil];
	[self xtrasChanged:nil];

	[button_OK setLocalizedString:AILocalizedStringFromTable(@"Close", @"Buttons", nil)];

	[super windowDidLoad];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[iconArray release]; iconArray = nil;

	[super dealloc];
}

//Preference view is closing
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
    [self setAnimatedDockIconAtIndex:-1];
	[self autorelease];
}

//When the xtras are changed, update our icons
- (void)xtrasChanged:(NSNotification *)notification
{
	if (!notification || [[notification object] caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
		[iconArray release];
		iconArray = [[NSMutableArray alloc] init];
		
		//Fetch the pack previews
		for (NSString *path in [adium.dockController availableDockIconPacks]) {
			AIIconState		*previewState = [adium.dockController previewStateForIconPackAtPath:path];
			[iconArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"Path", previewState, @"State", nil]];    
		}
		
		[imageGridView_icons reloadData];
		[self selectIconWithName:[adium.preferenceController preferenceForKey:KEY_ACTIVE_DOCK_ICON
																		  group:PREF_GROUP_APPEARANCE]];
	}
}

//Build an array of available icon packs

//Set the selected icon by name
- (void)selectIconWithName:(NSString *)selectName
{
	NSDictionary	*iconDict;
	NSInteger				index = 0;
	
	for (iconDict in iconArray) {
		NSString	*iconName = [[[iconDict objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension]		;
		if ([iconName isEqualToString:selectName]) {
			[imageGridView_icons selectIndex:index];
			break; //we can exit early
		}
		index++;
	}
}


//Animation ------------------------------------------------------------------------------------------------------------
#pragma mark Animation
//Start animating an icon in our grid by index (pass -1 to stop animation)
- (void)setAnimatedDockIconAtIndex:(NSInteger)index
{
	//Schedule the old and new animating images for redraw
	[imageGridView_icons setNeedsDisplayOfImageAtIndex:animatedIndex];
	[imageGridView_icons setNeedsDisplayOfImageAtIndex:index];
	
	//Stop the current animation
    if (animationTimer) {
        [animationTimer invalidate];
        [animationTimer release];
        animationTimer = nil;
	}
	[animatedIconState release]; animatedIconState = nil;
	animatedIndex = -1;

	//Start the new animation
	if (index != -1) {
		NSString	*path = [[iconArray objectAtIndex:index] objectForKey:@"Path"];

		animatedIconState = [[self animatedStateForDockIconAtPath:path] retain];
		animatedIndex = index;
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval:[animatedIconState animationDelay]
														   target:self
														 selector:@selector(animate:)
														 userInfo:nil
														  repeats:YES] retain];
    }
}

//Returns an animated AIIconState for the dock icon pack at the specified path
- (AIIconState *)animatedStateForDockIconAtPath:(NSString *)path
{
	NSDictionary 	*iconPackDict = [adium.dockController iconPackAtPath:path];
	NSDictionary	*stateDict = [iconPackDict objectForKey:@"State"];
	
	return [[[AIIconState alloc] initByCompositingStates:[NSArray arrayWithObjects:
		[stateDict objectForKey:@"Base"],
		[stateDict objectForKey:@"Online"],
		[stateDict objectForKey:@"Alert"], nil]] autorelease];
}

//Animate the hovered icon
- (void)animate:(NSTimer *)timer
{
	[animatedIconState nextFrame];
	[imageGridView_icons setNeedsDisplayOfImageAtIndex:animatedIndex];
}

//ImageGridView Delegate -----------------------------------------------------------------------------------------------
#pragma mark ImageGridView Delegate
- (NSUInteger)numberOfImagesInImageGridView:(AIImageGridView *)imageGridView
{
	return [iconArray count];
}

- (NSImage *)imageGridView:(AIImageGridView *)imageGridView imageAtIndex:(NSUInteger)inIndex
{
	NSImage *image  = ((inIndex == animatedIndex) ?
					   animatedIconState.image :
					   [[[iconArray objectAtIndex:inIndex] objectForKey:@"State"] image]);

	if (inIndex == imageGridView_icons.selectedIndex) {
		NSSize size = image.size;
		NSRect fullRect = NSMakeRect(0, 0, size.width, size.height);
		NSImage *selectedImage = [[NSImage alloc] initWithSize:size];
		[selectedImage lockFocus];
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:fullRect
															  radius:6.0];
		[[NSGradient selectedControlGradient] drawInBezierPath:path angle:90];
		[image drawInRect:fullRect
				 fromRect:fullRect
				operation:NSCompositeSourceOver
				 fraction:0.9];
		[selectedImage unlockFocus];
		
		image = [selectedImage autorelease];
	}

	return image;
}

- (void)imageGridViewSelectionDidChange:(NSNotification *)notification
{	
	NSDictionary	*iconDict = [iconArray objectAtIndex:[imageGridView_icons selectedIndex]];
	NSString		*iconName = [[[iconDict objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension];
	
	if (![[adium.preferenceController preferenceForKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_APPEARANCE] isEqualToString:iconName])
		[adium.preferenceController setPreference:iconName forKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_APPEARANCE];
}

- (void)imageGridView:(AIImageGridView *)imageGridView cursorIsHoveringImageAtIndex:(NSUInteger)index
{
	[self setAnimatedDockIconAtIndex:index];
}


//Deleting dock xtras --------------------------------------------------------------------------------------------------
#pragma mark Deleting dock xtras
//Delete the selected dock icon
- (void)imageGridViewDeleteSelectedImage:(AIImageGridView *)imageGridView
{            
	NSString	*selectedIconPath = [[iconArray objectAtIndex:[imageGridView selectedIndex]] valueForKey:@"Path"];
	NSString	*name = [[selectedIconPath lastPathComponent] stringByDeletingPathExtension];
	
	//We need atleast one icon installed, so prevent the user from deleting the default icon
	if (![name isEqualToString:DEFAULT_DOCK_ICON_NAME]) {
		NSBeginAlertSheet(AILocalizedString(@"Delete Dock Icon",nil),
						  AILocalizedString(@"Delete",nil),
						  AILocalizedString(@"Cancel",nil),
						  @"",
						  [self window], 
						  self, 
						  @selector(trashConfirmSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  selectedIconPath,
						  AILocalizedString(@"Are you sure you want to delete the %@ Dock Icon? It will be moved to the Trash.",nil), name);
	}
}
- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSString *)selectedIconPath
{
    if (returnCode == NSOKButton) {
		NSInteger deletedIndex = [imageGridView_icons selectedIndex];
		
		//Deselect and stop animating
		[self setAnimatedDockIconAtIndex:-1];
		[imageGridView_icons selectIndex:-1];
		
		//Trash the file & Rebuild our icons
		[[NSFileManager defaultManager] trashFileAtPath:selectedIconPath];

		//Select the next available icon
		[imageGridView_icons selectIndex:deletedIndex];
    }
}

@end

