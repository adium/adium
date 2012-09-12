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

#import "AIDockIconSelectionSheet.h"
#import "AIDockController.h"
#import "AIAppearancePreferencesPlugin.h"
#import <AIUtilities/AIFileManagerAdditions.h>
#import <Adium/AIIconState.h>
#import <Adium/AIDockControllerProtocol.h>

#define PREF_GROUP_DOCK_ICON	@"Dock Icon"
#define DEFAULT_DOCK_ICON_NAME	@"Adiumy Green"

@interface AIDockIconSelectionSheet ()

- (void)selectIconWithName:(NSString *)selectName;
- (void)xtrasChanged:(NSNotification *)notification;

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSString *)selectedIconPath;

@end

@implementation AIDockIconSelectionSheet

@synthesize imageCollectionView, okButton;
@synthesize icons, iconsData, animatedIconState, animatedIndex, animationTimer, previousIndex;

- (id)init
{
	if (self = [super initWithWindowNibName:@"DockIconSelectionSheet"]) {
		
	}
	
	return self;
}

- (void)showOnWindow:(NSWindow *)parentWindow
{
	[super showOnWindow:parentWindow];
	
	if (!parentWindow) {
		[self.window makeKeyAndOrderFront:nil];
		[NSApp activateIgnoringOtherApps:YES];
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Setup our preference view
- (void)windowDidLoad
{
	// Init
	[self setIcons:nil];
	[self setIconsData:nil];
	[self setAnimatedIndex:NSNotFound];
	[self setPreviousIndex:NSNotFound];
	
	// Set-up collection view
	[[self imageCollectionView] setMaxNumberOfColumns:7];
	[[self imageCollectionView] setMaxItemSize:NSMakeSize(64.0f, 64.0f)];
	[[self imageCollectionView] setMinItemSize:NSMakeSize(64.0f, 64.0f)];
	[[self imageCollectionView] setHighlightStyle:AIImageCollectionViewHighlightBackgroundStyle];
	[[self imageCollectionView] setHighlightCornerRadius:4.0f];
	
    // Observe xtras changes
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(xtrasChanged:)
												 name:AIXtrasDidChangeNotification
											   object:nil];

	[self xtrasChanged:nil];
	[[self okButton] setLocalizedString:AILocalizedStringFromTable(@"Close", @"Buttons", nil)];

	[super windowDidLoad];
}

// Preference view is closing
- (void)windowWillClose:(id)sender
{
    [self setAnimatedDockIconAtIndex:NSNotFound];
	
	[super windowWillClose:sender];
}

#pragma mark -

// Invoked as the sheet closes, dismiss the sheet
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [self setAnimatedDockIconAtIndex:NSNotFound];
	
    [sheet orderOut:nil];
}

// When the xtras are changed, update our icons
- (void)xtrasChanged:(NSNotification *)notification
{
	if (!notification || [[notification object] caseInsensitiveCompare:@"AdiumIcon"] == NSOrderedSame) {
		[self setIconsData:[NSMutableArray array]];
		NSMutableArray *dockIcons = [[NSMutableArray alloc] init];
		
		// Fetch the pack previews
		for (NSString *path in [adium.dockController availableDockIconPacks]) {
			AIIconState *previewState = [adium.dockController previewStateForIconPackAtPath:path];
			[[self iconsData] addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:path, @"Path", previewState, @"State", nil]];
			[dockIcons addObject:[previewState image]];
		}
		
		[self setIcons:dockIcons];

		[self selectIconWithName:[adium.preferenceController preferenceForKey:KEY_ACTIVE_DOCK_ICON
																		group:PREF_GROUP_APPEARANCE]];
	}
}

// Set the selected icon by name
- (void)selectIconWithName:(NSString *)selectName
{
	NSDictionary *iconDictionary;
	NSInteger anIndex = 0;
	
	// Set previous index
	if (![[[self imageCollectionView] selectionIndexes] isEqualToIndexSet:[NSIndexSet indexSet]]) {
		[self setPreviousIndex:[[[self imageCollectionView] selectionIndexes] firstIndex]];
	}
	
	for (iconDictionary in [self iconsData]) {
		NSString *iconName = [[[iconDictionary objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension];

		if ([iconName isEqualToString:selectName]) {
			[[self imageCollectionView] setSelectionIndexes:[NSIndexSet indexSetWithIndex:anIndex]];
			break; // we can exit early
		}

		anIndex++;
	}
	
	// Set previous index - in case it wasn't set first time
	if ([self previousIndex] == NSNotFound && ![[[self imageCollectionView] selectionIndexes] isEqualToIndexSet:[NSIndexSet indexSet]]) {
		[self setPreviousIndex:[[[self imageCollectionView] selectionIndexes] firstIndex]];
	}
}

#pragma mark - Animation

// Start animating an icon in our collection by index (pass NSNotFound to stop animation)
- (void)setAnimatedDockIconAtIndex:(NSInteger)anIndex
{
	// Stop the current animation
    if ([self animationTimer]) {
        [[self animationTimer] invalidate];
        [self setAnimationTimer:nil];
	}
	
	//
	if ([self animatedIndex] != NSNotFound) {
		[[self imageCollectionView] setImage:[[[[self iconsData] objectAtIndex:[self animatedIndex]] objectForKey:@"State"] image]
							  forItemAtIndex:[self animatedIndex]];
	}
	
	
	[self setAnimatedIconState:nil];
	[self setAnimatedIndex:NSNotFound];

	// Start the new animation
	if (anIndex != NSNotFound) {
		NSString *path = [[[self iconsData] objectAtIndex:anIndex] objectForKey:@"Path"];

		[self setAnimatedIconState:[self animatedStateForDockIconAtPath:path]];
		[self setAnimatedIndex:anIndex];
		
		[self setAnimationTimer:[NSTimer scheduledTimerWithTimeInterval:[[self animatedIconState] animationDelay]
																 target:self
															   selector:@selector(animate:)
															   userInfo:nil
														  		repeats:YES]];
    }
}

// Returns an animated AIIconState for the dock icon pack at the specified path
- (AIIconState *)animatedStateForDockIconAtPath:(NSString *)path
{
	NSDictionary *iconPackDict = [adium.dockController iconPackAtPath:path];
	NSDictionary *stateDict = [iconPackDict objectForKey:@"State"];
	
	return [[AIIconState alloc] initByCompositingStates:[NSArray arrayWithObjects:[stateDict objectForKey:@"Base"],
																					[stateDict objectForKey:@"Online"],
														  							[stateDict objectForKey:@"Alert"],
														  							nil]];
}

// Animate the hovered icon
- (void)animate:(NSTimer *)timer
{
	[animatedIconState nextFrame];

	[[self imageCollectionView] setImage:animatedIconState.image forItemAtIndex:animatedIndex];
}

#pragma mark - AIImageCollectionViewDelegate

- (BOOL)imageCollectionView:(AIImageCollectionView *)collectionView shouldHighlightItemAtIndex:(NSUInteger)anIndex
{
	// Stop animation
	if (anIndex == NSNotFound) {
		[self setAnimatedDockIconAtIndex:NSNotFound];
	}
	
	return (anIndex < [[self icons] count]);
}

- (BOOL)imageCollectionView:(AIImageCollectionView *)imageCollectionView shouldSelectItemAtIndex:(NSUInteger)anIndex
{
	// Prevent empty selection
	if (anIndex == NSNotFound) {
		if ([self previousIndex] == [[self icons] count] || [self previousIndex] == NSNotFound) {
			[self selectIconWithName:[adium.preferenceController preferenceForKey:KEY_ACTIVE_DOCK_ICON
																			group:PREF_GROUP_APPEARANCE]];
		} else {
			[[self imageCollectionView] setSelectionIndexes:[NSIndexSet indexSetWithIndex:previousIndex]];
		}
	}
		
	return (anIndex < [[self icons] count]);
}

- (BOOL)imageCollectionView:(AIImageCollectionView *)imageCollectionView shouldDeleteItemsAtIndexes:(NSIndexSet *)indexes
{
	return ([indexes firstIndex] < [[self icons] count]);
}

- (void)imageCollectionView:(AIImageCollectionView *)imageCollectionView didHighlightItemAtIndex:(NSUInteger)anIndex
{
	[self setAnimatedDockIconAtIndex:anIndex];
}

- (void)imageCollectionView:(AIImageCollectionView *)imageCollectionView didSelectItemAtIndex:(NSUInteger)anIndex
{
	NSString *iconName = [[[[[self iconsData] objectAtIndex:anIndex] objectForKey:@"Path"] lastPathComponent] stringByDeletingPathExtension];
	
	if (![[adium.preferenceController preferenceForKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_APPEARANCE] isEqualToString:iconName]) {
		[adium.preferenceController setPreference:iconName forKey:KEY_ACTIVE_DOCK_ICON group:PREF_GROUP_APPEARANCE];
		
		// Set previous index
		[self setPreviousIndex:anIndex];
	}
}

#pragma mark - Deleting dock xtras

// Delete the selected dock icon
- (void)imageCollectionView:(AIImageCollectionView *)imageCollectionView didDeleteItemsAtIndexes:(NSIndexSet *)indexes
{            
	NSString *selectedIconPath = [[iconsData objectAtIndex:[[[self imageCollectionView] selectionIndexes] firstIndex]] valueForKey:@"Path"];
	NSString *name = [[selectedIconPath lastPathComponent] stringByDeletingPathExtension];
	
	// We need at least one icon installed, so prevent the user from deleting the default icon
	if (![name isEqualToString:DEFAULT_DOCK_ICON_NAME]) {
		NSBeginAlertSheet(AILocalizedString(@"Delete Dock Icon",nil),
						  AILocalizedString(@"Delete",nil),
						  AILocalizedString(@"Cancel",nil),
						  @"",
						  [self window], 
						  self, 
						  @selector(trashConfirmSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  (__bridge void *)selectedIconPath,
						  AILocalizedString(@"Are you sure you want to delete the %@ Dock Icon? It will be moved to the Trash.", nil), name);
	}
}

- (void)trashConfirmSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSString *)selectedIconPath
{
    if (returnCode == NSOKButton) {
		NSInteger deletedIndex = [[[self imageCollectionView] selectionIndexes] firstIndex];
		
		// Deselect and stop animating
		[self setAnimatedDockIconAtIndex:NSNotFound];
		[[self imageCollectionView] setSelectionIndexes:[NSIndexSet indexSet]];
		
		// Trash the file & Rebuild our icons
		[[NSFileManager defaultManager] trashFileAtPath:selectedIconPath];
		[self xtrasChanged:nil];

		// Select the next available icon (prevent empty selection)
		NSUInteger newIndex = (deletedIndex == [[self icons] count]) ? --deletedIndex : deletedIndex;
		[[self imageCollectionView] setSelectionIndexes:[NSIndexSet indexSetWithIndex:newIndex]];
    }
}

@end
