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
#import <Adium/AIPathUtilities.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIImageTextCell.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AICorePluginLoader.h>

#define ADIUM_XTRAS_PAGE		AILocalizedString(@"http://xtras.adium.im/","Adium xtras page. Localized only if a translated version exists.")

@interface AIXtrasManager ()
- (void)updateForSelectedCategory;
- (void)xtrasChanged:(NSNotification *)not;
@end

@implementation AIXtrasManager
@synthesize removeXtra, findXtras, togglePluginEnabled;

/*!
 * @brief Preference pane properties
 */
- (AIPreferenceCategory)category{
	return AIPref_Advanced;
}
- (NSString *)paneIdentifier{
	return @"Xtras";
}
- (NSString *)paneName{
    return AILocalizedString(@"Xtras",nil);
}
- (NSImage *)paneIcon{
	return [NSImage imageNamed:@"xtras_duck" forClass:[self class]];
}
- (NSString *)nibName{
    return @"Preferences-Xtras";
}

/*!
 * @brief Configure the view initially
 */
- (void)viewDidLoad
{
	[findXtras setLocalizedString:AILocalizedString(@"Find More Xtras", "Button in the Xtras Manager to go to adiumxtras.com to get more adiumxtras")];
	
	AIImageTextCell			*cell;
	//Configure our tableViews
	cell = [[AIImageTextCell alloc] init];
	[cell setFont:[NSFont systemFontOfSize:12]];
	[[tableView_categories tableColumnWithIdentifier:@"name"] setDataCell:cell];
	
	cell = [[AIImageTextCell alloc] init];
	[cell setFont:[NSFont systemFontOfSize:12]];
	[[xtraList tableColumnWithIdentifier:@"xtras"] setDataCell:cell];

	//XXX ???
	[previewContainerView setHasVerticalScroller:YES];
	[previewContainerView setAutohidesScrollers:YES];
	[previewContainerView setBorderType:NSBezelBorder];

	[self showXtras];

	[tableView_categories selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	
	[self updateForSelectedCategory];
}

- (void)showXtras
{
	[self loadXtras];
	showInfo = NO;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:AIXtrasDidChangeNotification
									 object:nil];
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
	return [[categoryA objectForKey:@"Name"] localizedCaseInsensitiveCompare:[categoryB objectForKey:@"Name"]];
}

- (void)loadXtras
{
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
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:AIXtrasDidChangeNotification
												  object:nil];
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
	}
	
	return xtras;
}

- (void)updateForSelectedCategory
{
	selectedCategory = [[self xtrasForCategoryAtIndex:[tableView_categories selectedRow]] mutableCopy];

	[xtraList reloadData];
	if ([xtraList numberOfRows]) {
		[xtraList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}

	//Show/Hide the plugin enabler for the plugin category
	if ([[[categories objectAtIndex:[tableView_categories selectedRow]] objectForKey:@"Directory"] integerValue] == AIPluginsDirectory)
		[togglePluginEnabled setHidden:NO];
	else
		[togglePluginEnabled setHidden:YES];
	
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
							informativeTextWithFormat:@"%@", ((selectionCount > 1) ?
													   AILocalizedString(@"The selected Xtras will be moved to the Trash.", nil) :
													   AILocalizedString(@"The selected Xtra will be moved to the Trash.", nil))];
	[warning beginSheetModalForWindow:self.view.window
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

- (IBAction)toggleEnable:(id)sender {
	[[xtraList selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		AIXtraInfo *xtraInfo = [selectedCategory objectAtIndex:idx];
		
		if (xtraInfo.enabled)
			[AICorePluginLoader disablePlugin:xtraInfo.path];
		else
			[AICorePluginLoader enablePlugin:xtraInfo.path];
	}];
	
	NSAlert * warning = [NSAlert alertWithMessageText:AILocalizedString(@"You will need to restart Adium", nil)
										defaultButton:AILocalizedString(@"OK", nil)
									  alternateButton:nil
										  otherButton:nil
							informativeTextWithFormat:AILocalizedString(@"Enabling or disabling plugins requires a restart of Adium.", nil)];
	[warning beginSheetModalForWindow:self.view.window
						modalDelegate:nil
					   didEndSelector:nil
						  contextInfo:nil];
	
	//Reload the plugins to reflect the recent changes
	[self xtrasChanged:nil];
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
		[cell setSubString:[(AIXtraInfo *)[selectedCategory objectAtIndex:row] version]];
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
		return [(AIXtraInfo *)[selectedCategory objectAtIndex:row] name];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == xtraList) {
		NSInteger selectedRow = [xtraList selectedRow];
		if ((selectedRow >= 0) && (selectedRow < [selectedCategory count])) {
			//AIXtraInfo *xtraInfo  = [AIXtraInfo infoWithURL:[NSURL fileURLWithPath:[[selectedCategory objectAtIndex:selectedRow] path]]];
		//	if ([[xtraList selectedRowIndexes] count] == 1)
		//		[previewController setXtra:xtraInfo];
			
			//Update the plugin enabler's title
			AIXtraInfo *xtraInfo = [selectedCategory objectAtIndex:selectedRow];
			if (xtraInfo.enabled)
				[togglePluginEnabled setTitle:AILocalizedString(@"Disable", nil)];
			else
				[togglePluginEnabled setTitle:AILocalizedString(@"Enable", nil)];
			
			[removeXtra setEnabled:YES];
		} else {
			[removeXtra setEnabled:NO];
		}
		
	} else if ([aNotification object] == tableView_categories) {
		[self updateForSelectedCategory];
	}
}

- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
	[self deleteXtra:tableView];
}

@end
