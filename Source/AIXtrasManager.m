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

#import "AIXtrasManager.h"
#import "AIXtraInfo.h"
#import "AIXtraPreviewController.h"
#import <Adium/AIDockControllerProtocol.h>
#import <Adium/AIPathUtilities.h>
#import <Adium/KNShelfSplitView.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>

#define ADIUM_XTRAS_PAGE		AILocalizedString(@"http://xtras.adium.im/","Adium xtras page. Localized only if a translated version exists.")
#define DELETE					AILocalizedStringFromTable(@"Delete", @"Buttons", nil)
#define GET_MORE_XTRAS			AILocalizedStringFromTable(@"Get More Xtras", @"Buttons", "Button in the Xtras Manager to go to xtras.adium.im to get more adiumxtras")

#define MINIMUM_SOURCE_LIST_WIDTH 40

@interface AIXtrasManager ()
- (void)installToolbar;
- (void)updateForSelectedCategory;
- (void)xtrasChanged:(NSNotification *)not;
@end

@implementation AIXtrasManager

static AIXtrasManager *manager;

+ (AIXtrasManager *) sharedManager
{
	return manager;
}

- (void)installPlugin
{
	manager = self;
}

- (void)windowDidLoad
{
	[window setTitle:AILocalizedString(@"Xtras Manager", "Xtras Manager window title")];

	[self installToolbar];

	[tableView_categories setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	AIImageTextCell			*cell;
	//Configure our tableViews
	cell = [[AIImageTextCell alloc] init];
	[cell setFont:[NSFont systemFontOfSize:12]];
	[[tableView_categories tableColumnWithIdentifier:@"name"] setDataCell:cell];
	[cell release];
	
	cell = [[AIImageTextCell alloc] init];
	[cell setFont:[NSFont systemFontOfSize:12]];
	[[xtraList tableColumnWithIdentifier:@"xtras"] setDataCell:cell];
	[cell release];

	//XXX ???
	[previewContainerView setHasVerticalScroller:YES];
	[previewContainerView setAutohidesScrollers:YES];
	[previewContainerView setBorderType:NSBezelBorder];

	[tableView_categories selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	
	[self updateForSelectedCategory];
}

- (void)showXtras
{
	if (!window) {
		[self loadXtras];
		
		showInfo = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
									   selector:@selector(xtrasChanged:)
										   name:AIXtrasDidChangeNotification
										 object:nil];
		[NSBundle loadNibNamed:@"XtrasManager" owner:self];
		[self windowDidLoad];
	}
		
	[window makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
										  name:AIXtrasDidChangeNotification
										object:nil];
	
	[categories release]; categories = nil;
	[toolbarItems release]; toolbarItems = nil;

	//Release top-level nib objects besides the window
	[view_content release]; view_content = nil;
	[view_shelf release]; view_shelf = nil;	

	//XXX don't need to do this when this is a window controller
	window = nil;
}


- (void)xtrasChanged:(NSNotification *)not
{
	//Clear our cache of loaded Xtras
	[self loadXtras];
	
	//Now redisplay our current category, in case it changed
	[self updateForSelectedCategory];
}

NSInteger categorySort(id categoryA, id categoryB, void * context)
{
	return [[categoryA objectForKey:@"Name"] caseInsensitiveCompare:[categoryB objectForKey:@"Name"]];
}

- (void)loadXtras
{
	[categories release];
	categories = [[NSMutableArray alloc] init];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIMessageStylesDirectory], @"Directory",
		AILocalizedString(@"Message Styles", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumMessageStyle"], @"Image", nil]];

	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIContactListDirectory], @"Directory",
		AILocalizedString(@"Contact List Themes", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumListTheme"], @"Image", nil]];
	

	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIStatusIconsDirectory], @"Directory",
		AILocalizedString(@"Status Icons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumStatusIcons"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AISoundsDirectory], @"Directory",
		AILocalizedString(@"Sound Sets", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumSoundset"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIDockIconsDirectory], @"Directory",
		AILocalizedString(@"Dock Icons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumIcon"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIEmoticonsDirectory], @"Directory",
		AILocalizedString(@"Emoticons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumEmoticonset"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIScriptsDirectory], @"Directory",
		AILocalizedString(@"Scripts", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumScripts"], @"Image", nil]];

	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIServiceIconsDirectory], @"Directory",
		AILocalizedString(@"Service Icons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumServiceIcons"], @"Image", nil]];
	
	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:AIMenuBarIconsDirectory], @"Directory",
		AILocalizedString(@"Menu Bar Icons", "AdiumXtras category name"), @"Name",
		[NSImage imageNamed:@"AdiumMenuBarIcons"], @"Image", nil]];

	[categories addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   [NSNumber numberWithInteger:AIPluginsDirectory], @"Directory",
						   AILocalizedString(@"Plugins", "AdiumXtras category name"), @"Name",
						   [NSImage imageNamed:@"AdiumPlugin"], @"Image", nil]];

	
	[categories sortUsingFunction:categorySort context:NULL];
}

- (NSArray *)arrayOfXtrasAtPaths:(NSArray *)paths
{
	NSMutableArray	*contents = [NSMutableArray array];
	NSFileManager	*fileManager = [NSFileManager defaultManager];

	for (NSString *path in paths) {
		for (NSString *xtraName in [fileManager contentsOfDirectoryAtPath:path error:NULL]) {
			if (![xtraName hasPrefix:@"."]) {
				[contents addObject:[AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:xtraName]]]];
			}
		}
		
		NSString *disabledPath = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:
								  [[path lastPathComponent] stringByAppendingString:@" (Disabled)"]];
		for (NSString *xtraName in [fileManager contentsOfDirectoryAtPath:disabledPath error:NULL]) {
			if (![xtraName hasPrefix:@"."]) {
				AIXtraInfo *xtraInfo = [AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[disabledPath stringByAppendingPathComponent:xtraName]]];
				[xtraInfo setEnabled:NO];
				[contents addObject:xtraInfo];
			}
		}		
	}

	return contents;
}

- (void)dealloc
{
	[categories release];
    [selectedCategory release];

	[super dealloc];
}

- (NSArray *)xtrasForCategoryAtIndex:(NSInteger)inIndex
{
	if (inIndex == -1) return nil;

	NSDictionary	*xtrasDict = [categories objectAtIndex:inIndex];
	NSArray			*xtras;
	
	if (!(xtras = [xtrasDict objectForKey:@"Xtras"])) {
		xtras = [self arrayOfXtrasAtPaths:AISearchPathForDirectories([[xtrasDict objectForKey:@"Directory"] integerValue])];
		NSMutableDictionary *newDictionary = [xtrasDict mutableCopy];
		[newDictionary setObject:xtras forKey:@"Xtras"];
		[categories replaceObjectAtIndex:inIndex
							  withObject:newDictionary];
		[newDictionary release];
	}
	
	return xtras;
}

- (void)updateForSelectedCategory
{
	[selectedCategory autorelease];
	selectedCategory = [[self xtrasForCategoryAtIndex:[tableView_categories selectedRow]] mutableCopy];

	[xtraList reloadData];
	if ([xtraList numberOfRows]) {
		[xtraList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}

	[self updatePreview];
}

- (void)updatePreview
{
	AIXtraInfo *xtra = nil;

	if ([selectedCategory count] > 0 && [xtraList selectedRow] != -1) {
		xtra = [selectedCategory objectAtIndex:[xtraList selectedRow]];
	}

	if (xtra) {
		//[showInfoControl setHidden:NO];
		if(showInfo)
			[NSBundle loadNibNamed:@"XtraInfoView" owner:self];
		else {
			[NSBundle loadNibNamed:@"XtraPreviewImageView" owner:self];
			/*	NSString * xtraType = [xtra type];
			
			if ([xtraType isEqualToString:AIXtraTypeEmoticons])
			[NSBundle loadNibNamed:@"EmoticonPreviewView" owner:self];
			else if ([xtraType isEqualToString:AIXtraTypeDockIcon])
			[NSBundle loadNibNamed:@"DockIconPreviewView" owner:self];
			else if ([xtraType isEqualToString:AIXtraTypeMessageStyle])
			[NSBundle loadNibNamed:@"WebkitMessageStylePreviewView" owner:self];
			else if ([xtraType isEqualToString:AIXtraTypeStatusIcons]) {
				[NSBundle loadNibNamed:@"StatusIconPreviewView" owner:self];
			}
			else if ([xtraType isEqualToString:AIXtraTypeServiceIcons]) {
				[NSBundle loadNibNamed:@"ServiceIconPreviewView" owner:self];
			}
			else { //catchall behavior is to just show the readme
				[NSBundle loadNibNamed:@"XtraInfoView" owner:self];
				[showInfoControl setHidden:YES];
			}*/
		}
		if (previewController/* && previewContainerView*/) {
			NSView *pv = [previewController previewView];
			NSSize docSize = [previewContainerView documentVisibleRect].size;
			NSRect viewFrame = [pv frame];
			viewFrame.size.width = docSize.width;
			if([pv respondsToSelector:@selector(image)]) viewFrame.size.height = [[(NSImageView *)pv image]size].height;
			if(viewFrame.size.height < docSize.height) viewFrame.size.height = docSize.height;
			[pv setFrameSize:viewFrame.size];
			[previewContainerView setDocumentView:pv];
			[previewController setXtra:xtra];
			[previewContainerView setNeedsDisplay:YES];
		}		
	}
}

- (IBAction) setShowsInfo:(id)sender
{
	showInfo = ([sender selectedSegment] != 0);

	[self updatePreview];
}

- (void)deleteXtrasAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		NSFileManager * fileManager = [NSFileManager defaultManager];
		NSIndexSet * indices = [xtraList selectedRowIndexes];
		NSMutableSet * pathExtensions = [NSMutableSet set];
		NSString * path;
		for (NSInteger i = [indices lastIndex]; i >= 0; i--) {
			if ([indices containsIndex:i]) {
				path = [[selectedCategory objectAtIndex:i] path];
				[pathExtensions addObject:[path pathExtension]];
				[fileManager trashFileAtPath:path];
			}
		}
		[xtraList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		[selectedCategory removeObjectsAtIndexes:indices];
		[xtraList reloadData];
		/*
		 XXX this is ugly. We should use the AIXtraInfo's type instead of the path extension
		*/
		for (path in pathExtensions) { //usually this will only run once
			[[NSNotificationCenter defaultCenter] postNotificationName:AIXtrasDidChangeNotification
													  object:path];
		}
	}
}

- (IBAction) deleteXtra:(id)sender
{
	NSUInteger selectionCount = [[xtraList selectedRowIndexes] count];

	NSAlert * warning = [NSAlert alertWithMessageText:((selectionCount > 1) ?
													   [NSString stringWithFormat:AILocalizedString(@"Delete %lu Xtras?", nil), selectionCount] :
													   AILocalizedString(@"Delete Xtra?", nil))
										defaultButton:AILocalizedString(@"Delete", nil)
									  alternateButton:AILocalizedString(@"Cancel", nil)
										  otherButton:nil
							informativeTextWithFormat:((selectionCount > 1) ?
													   AILocalizedString(@"The selected Xtras will be moved to the Trash.", nil) :
													   AILocalizedString(@"The selected Xtra will be moved to the Trash.", nil))];
	[warning beginSheetModalForWindow:window
						modalDelegate:self
					   didEndSelector:@selector(deleteXtrasAlertDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
}

- (IBAction)browseXtras:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ADIUM_XTRAS_PAGE]];
}

- (IBAction)checkForUpdates:(id)sender
{
	
}

+ (BOOL)createXtraBundleAtPath:(NSString *)path 
{
	NSString *contentsPath  = [path stringByAppendingPathComponent:@"Contents"];
	NSString *resourcesPath = [contentsPath stringByAppendingPathComponent:@"Resources"];
	NSString *infoPlistPath = [contentsPath stringByAppendingPathComponent:@"Info.plist"];

	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * name = [[path lastPathComponent] stringByDeletingPathExtension];
	if (![fileManager fileExistsAtPath:path]) {
		[fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
		[fileManager createDirectoryAtPath:contentsPath withIntermediateDirectories:YES attributes:nil error:NULL];

		//Info.plist
		[[NSDictionary dictionaryWithObjectsAndKeys:
			@"English", kCFBundleDevelopmentRegionKey,
			name, kCFBundleNameKey,
			@"AdIM", @"CFBundlePackageType",
			[@"com.adiumx." stringByAppendingString:name], kCFBundleIdentifierKey,
			[NSNumber numberWithInteger:1], @"XtraBundleVersion",
			@"1.0", kCFBundleInfoDictionaryVersionKey,
			nil] writeToFile:infoPlistPath atomically:YES];

		//Resources
		[fileManager createDirectoryAtPath:resourcesPath withIntermediateDirectories:YES attributes:nil error:NULL];
	}

	BOOL isDir = NO, success;
	success = [fileManager fileExistsAtPath:resourcesPath isDirectory:&isDir] && isDir;
	if (success)
		success = [fileManager fileExistsAtPath:infoPlistPath isDirectory:&isDir] && !isDir;
	return success;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == tableView_categories) {
		[cell setImage:[[categories objectAtIndex:row] objectForKey:@"Image"]];
		[cell setSubString:nil];
	}
	else {
		AIXtraInfo *xtraInfo = [selectedCategory objectAtIndex:row];
		[cell setImage:[xtraInfo icon]];
		[cell setSubString:nil];
		[cell setEnabled:[xtraInfo enabled]];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == tableView_categories) {
		return [categories count];
	}
	else {
		return [selectedCategory count];
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == tableView_categories) {
		return [[categories objectAtIndex:row] objectForKey:@"Name"];
	} else {
		NSString * name = [(AIXtraInfo *)[selectedCategory objectAtIndex:row] name];
		NSString * version = [(AIXtraInfo *)[selectedCategory objectAtIndex:row] version];
		NSString * displayString;

		if (name) {
			if (version)
				displayString = [NSString stringWithFormat:@"%@ (%@)", name, version];
			else
				displayString = [NSString stringWithString:name];
		} else {
			displayString = @"";
		}

		return displayString;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == xtraList) {
		//int	selectedRow = [xtraList selectedRow];
		//if ((selectedRow >= 0) && (selectedRow < [selectedCategory count])) {
			//AIXtraInfo *xtraInfo  = [AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[[selectedCategory objectAtIndex:selectedRow] path]]];
		//	if ([[xtraList selectedRowIndexes] count] == 1)
		//		[previewController setXtra:xtraInfo];
		//}
		
	} else if ([aNotification object] == tableView_categories) {
		[self updateForSelectedCategory];
	}
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self deleteXtra:tableView];
}

#pragma mark Placeholder until this is a window controller
- (NSWindow *)window
{
	return window;
}

#pragma mark Toolbar

- (void)installToolbar
{	
    NSToolbar 		*toolbar = [[[NSToolbar alloc] initWithIdentifier:@"XtrasManager:Toolbar"] autorelease];
	
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    toolbarItems = [[NSMutableDictionary alloc] init];
	
	//Delete Logs
	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"delete"
											 label:DELETE
									  paletteLabel:DELETE
										   toolTip:AILocalizedString(@"Delete the selection",nil)
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"remove" forClass:[self class]]
											action:@selector(deleteXtra:)
											  menu:nil];

	[AIToolbarUtilities addToolbarItemToDictionary:toolbarItems
									withIdentifier:@"getmoreXtras"
											 label:GET_MORE_XTRAS
									  paletteLabel:GET_MORE_XTRAS
										   toolTip:GET_MORE_XTRAS
											target:self
								   settingSelector:@selector(setImage:)
									   itemContent:[NSImage imageNamed:@"xtras_duck" forClass:[self class]]
											action:@selector(browseXtras:)
											  menu:nil];
	
	[[self window] setToolbar:toolbar];
}	

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    return [AIToolbarUtilities toolbarItemFromDictionary:toolbarItems withIdentifier:itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [NSArray arrayWithObjects:@"getmoreXtras", NSToolbarFlexibleSpaceItemIdentifier, @"delete", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return [[toolbarItems allKeys] arrayByAddingObjectsFromArray:
		[NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier,
			NSToolbarCustomizeToolbarItemIdentifier, nil]];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if ([[theItem itemIdentifier] isEqualToString:@"delete"]) {
		return ([[xtraList selectedRowIndexes] count] > 0);

	} else {
		return YES;
	}
}

- (CGFloat)shelfSplitView:(KNShelfSplitView *)shelfSplitView validateWidth:(CGFloat)proposedWidth
{
	return ((proposedWidth > MINIMUM_SOURCE_LIST_WIDTH) ? proposedWidth : MINIMUM_SOURCE_LIST_WIDTH);
}

@end
