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

#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIToolbarControllerProtocol.h>
#import "SHLinkEditorWindowController.h"
#import "SHLinkManagementPlugin.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIToolbarUtilities.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import <AIUtilities/AIPopUpToolbarItem.h>

//Browsers used with Scripting Bridge
#import "Safari.h"
#import "GoogleChrome.h"
#import "NetNewsWire.h"
#import "OmniWeb.h"

#define SAFARI_BUNDLE_ID @"com.apple.Safari"
#define WEBKIT_BUNDLE_ID @"org.webkit.nightly.WebKit"
#define CHROME_BUNDLE_ID @"com.google.Chrome"
#define OMNIWEB_BUNDLE_ID @"com.omnigroup.OmniWeb5"
#define NETNEWSWIRE_BUNDLE_ID @"com.ranchero.NetNewsWire"

#define BROWSER_ACTIVE_TAB_KEY_PATHS        @{ \
SAFARI_BUNDLE_ID : @{ @"URL" : @"windows.@first.currentTab.URL", @"title" : @"windows.@first.currentTab.name" }, \
WEBKIT_BUNDLE_ID : @{ @"URL" : @"windows.@first.currentTab.URL", @"title" : @"windows.@first.currentTab.name" }, \
CHROME_BUNDLE_ID : @{ @"URL" : @"windows.@first.activeTab.URL", @"title" : @"windows.@first.activeTab.title" }, \
OMNIWEB_BUNDLE_ID : @{ @"URL" : @"activeWorkspace.browsers.@first.activeTab.address", @"title" : @"activeWorkspace.browsers.@first.activeTab.title" } }

#define ADD_LINK_TITLE			[AILocalizedString(@"Add Link",nil) stringByAppendingEllipsis]
#define EDIT_LINK_TITLE			[AILocalizedString(@"Edit Link",nil) stringByAppendingEllipsis]
#define RM_LINK_TITLE           AILocalizedString(@"Remove Link",nil)

@interface SHLinkManagementPlugin ()
- (BOOL)textViewSelectionIsLink:(NSTextView *)textView;
- (void)registerToolbarItem;
- (IBAction)editFormattedLink:(id)sender;
- (IBAction)removeFormattedLink:(id)sender;
@end

@implementation SHLinkManagementPlugin

- (void)installPlugin
{
	NSMenuItem	*menuItem;
	
    //Add/Edit Link... menu item (edit menu)
    menuItem = [[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
																	 target:self
																	 action:@selector(editFormattedLink:)
															  keyEquivalent:@"k"];
    [adium.menuController addMenuItem:menuItem toLocation:LOC_Edit_Links];
    
    //Context menu
    menuItem = [[NSMenuItem alloc] initWithTitle:EDIT_LINK_TITLE
																	 target:self
																	 action:@selector(editFormattedLink:)
															  keyEquivalent:@""];
    [adium.menuController addContextualMenuItem:menuItem toLocation:Context_TextView_LinkEditing];
    [self registerToolbarItem];
}

- (void)uninstallPlugin
{
	
}

//Update our add/edit link menu item
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	//Enable the insert link menu items
	if (menuItem.action == @selector(addLink:))
		return YES;
	
	NSResponder	*responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
	if (responder && [responder isKindOfClass:[NSTextView class]]) {
		if ([[menuItem title] isEqualToString:RM_LINK_TITLE]) {
			// only make remove link menu item active if slection is a link.
			return [self textViewSelectionIsLink:(NSTextView *)responder];
		} else {
			//Update the menu item's title to reflect the current action
			[menuItem setTitle:([self textViewSelectionIsLink:(NSTextView *)responder] ? EDIT_LINK_TITLE : ADD_LINK_TITLE)];
			
			return ([(NSTextView *)responder isEditable] && [(NSTextView *)responder isRichText]);
		}
	} else {
		return NO; //Disable the menu item if a text field is not key
	}
	
}

//Add or edit a link
- (IBAction)editFormattedLink:(id)sender
{
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSTextView	*earliestTextView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];

    if (earliestTextView &&
		![[keyWin windowController] isKindOfClass:[SHLinkEditorWindowController class]]) {
		SHLinkEditorWindowController *linkEditorWindowController = [[SHLinkEditorWindowController alloc] initWithTextView:earliestTextView
																										  notifyingTarget:nil];
		[linkEditorWindowController showOnWindow:keyWin];
    }
}

- (IBAction)removeFormattedLink:(id)sender
{
	NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
	NSTextView	*earliestTextView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];
    
	if (earliestTextView) {
		NSRange	selectedRange = [earliestTextView selectedRange];
		
		if ([[earliestTextView textStorage] length] &&
			selectedRange.location != NSNotFound &&
			selectedRange.location != [[earliestTextView textStorage] length]) {
			
			[[earliestTextView textStorage] attribute:NSLinkAttributeName
											  atIndex:selectedRange.location
									   effectiveRange:&selectedRange];
			[[earliestTextView textStorage] removeAttribute:NSLinkAttributeName range:selectedRange];
		}
	}
}

//Returns YES if a link is under the selection of the passed text view
- (BOOL)textViewSelectionIsLink:(NSTextView *)textView
{
	id		selectedLink = nil;
	NSRange selectionRange = [textView selectedRange];
	if ([[textView textStorage] length] &&
		selectionRange.location != NSNotFound &&
		selectionRange.location != [[textView textStorage] length]) {
		
		selectedLink = [[textView textStorage] attribute:NSLinkAttributeName
												 atIndex:selectionRange.location
										  effectiveRange:&selectionRange];
	}
	return selectedLink != nil;
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if ([menu.title isEqualToString:@"LinkPopupMenu"]) {
		//Remove existing tab entries
		[menu removeAllItemsAfterIndex:1];
		
		//Get each open browser's open tabs
		NSArray *browsers = @[SAFARI_BUNDLE_ID, CHROME_BUNDLE_ID, WEBKIT_BUNDLE_ID, OMNIWEB_BUNDLE_ID, NETNEWSWIRE_BUNDLE_ID];
		NSMutableDictionary *openTabs = [[NSMutableDictionary alloc] init];
		for (NSString *browser in browsers) {
			NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:browser];
			if (apps.count) {
				SBApplication *sbapp = [SBApplication applicationWithBundleIdentifier:browser];
				if (sbapp) {
					if ([browser isEqualToString:CHROME_BUNDLE_ID]) {
						NSMutableArray *menuItems = [[NSMutableArray alloc] init];
						[[(GoogleChromeApplication *)sbapp windows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
							if (idx > 0)
								[menuItems addObject:[NSMenuItem separatorItem]];
							[[obj tabs] enumerateObjectsUsingBlock:^(id tab, NSUInteger tabidx, BOOL *tabstop) {
								id title = [[tab title] isEqualToString:@""] ? [tab URL] : [tab title];
								[menuItems addObject:[[NSMenuItem alloc] initWithTitle:title target:self action:@selector(addLink:) keyEquivalent:@"" representedObject:[tab URL]]];
							}];
						}];
						[openTabs setObject:menuItems forKey:@"Chrome"];
						
					} else if ([browser isEqualToString:SAFARI_BUNDLE_ID] || [browser isEqualToString:WEBKIT_BUNDLE_ID]) {
						NSMutableArray *menuItems = [[NSMutableArray alloc] init];
						[[(SafariApplication *)sbapp windows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
							if (idx > 0)
								[menuItems addObject:[NSMenuItem separatorItem]];
							[[obj tabs] enumerateObjectsUsingBlock:^(id tab, NSUInteger tabidx, BOOL *tabstop) {
								[menuItems addObject:[[NSMenuItem alloc] initWithTitle:[tab name] target:self action:@selector(addLink:) keyEquivalent:@"" representedObject:[tab URL]]];
							}];
						}];
						[openTabs setObject:menuItems forKey:([browser isEqualToString:SAFARI_BUNDLE_ID] ? @"Safari" : @"WebKit")];
						
					} else if ([browser isEqualToString:NETNEWSWIRE_BUNDLE_ID]) {
						NSMutableArray *menuItems = [[NSMutableArray alloc] init];
						NSArray *urls = [(NetNewsWireApplication *)sbapp URLsOfTabs];
						[[(NetNewsWireApplication *)sbapp titlesOfTabs] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
							//Skip the "News" item
							if (idx == 0) return;
							[menuItems addObject:[[NSMenuItem alloc] initWithTitle:obj target:self action:@selector(addLink:) keyEquivalent:@"" representedObject:[urls objectAtIndex:idx]]];
						}];
						[openTabs setObject:menuItems forKey:@"NetNewsWire"];
						
					} else if ([browser isEqualToString:OMNIWEB_BUNDLE_ID]) {
						NSMutableArray *menuItems = [[NSMutableArray alloc] init];
						[[(OmniWebApplication *)sbapp browsers] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
							[[obj tabs] enumerateObjectsUsingBlock:^(id tab, NSUInteger tabidx, BOOL *tabstop) {
								[menuItems addObject:[[NSMenuItem alloc] initWithTitle:[tab title] target:self action:@selector(addLink:) keyEquivalent:@"" representedObject:[tab address]]];
							}];
						}];
						[openTabs setObject:menuItems forKey:@"OmniWeb"];
					}
				}
			}
		}
		
		/* Create the menus
		 * If there's only one browser open put the tabs in the root menu.
		 * More than one browser open, make a submenu for each.
		 */
		if (openTabs.count == 1) {
			[menu addItem:[NSMenuItem separatorItem]];
			[openTabs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				[obj enumerateObjectsUsingBlock:^(id subobj, NSUInteger idx, BOOL *substop) {
					[menu addItem:subobj];
				}];
			}];
		} else if (openTabs.count > 1) {
			[menu addItem:[NSMenuItem separatorItem]];
			[openTabs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:AILocalizedString(@"Insert %@ Link", @"Used in a menu that displays open browser tabs"), key] action:nil keyEquivalent:@""];
				NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@""];
				[obj enumerateObjectsUsingBlock:^(id subobj, NSUInteger idx, BOOL *substop) {
					[subMenu addItem:subobj];
				}];
				[menu addItem:menuItem];
				[menu setSubmenu:subMenu forItem:menuItem];
			}];
		}
	}
}

//Insert a link from the frontmost tab in the default browser
- (IBAction)addDefaultLink:(id)sender
{
	NSURL *defaultBrowser = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:@"http://adium.im"]];
	SBApplication *sbapp = [SBApplication applicationWithURL:defaultBrowser];
	if (sbapp && sbapp.isRunning) {
		NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
		NSTextView	*earliestTextView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];
		NSString *bundleID = [[NSBundle bundleWithURL:defaultBrowser] bundleIdentifier];
		
		//Make sure we support this browser
		NSDictionary *browser = [BROWSER_ACTIVE_TAB_KEY_PATHS objectForKey:bundleID];
		if (browser) {
			[SHLinkEditorWindowController insertLinkTo:[NSURL URLWithString:[sbapp valueForKeyPath:[browser objectForKey:@"URL"]]]
											  withText:[sbapp valueForKeyPath:[browser objectForKey:@"title"]]
												inView:earliestTextView];
		}
	}
}

- (IBAction)addLink:(id)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]] && [sender representedObject]) {
		NSWindow	*keyWin = [[NSApplication sharedApplication] keyWindow];
		NSTextView	*earliestTextView = (NSTextView *)[keyWin earliestResponderOfClass:[NSTextView class]];
		[SHLinkEditorWindowController insertLinkTo:[sender representedObject]
										  withText:[sender title]
											inView:earliestTextView];
	}
}

#pragma mark Toolbar Item stuff

- (void)registerToolbarItem
{
    //Unregister the existing toolbar item first
    if (toolbarItem) {
        [adium.toolbarController unregisterToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
		toolbarItem = nil;
    }
	
	NSMenu *toolbarMenu = [[NSMenu alloc] initWithTitle:@"LinkPopupMenu"];
	toolbarMenu.delegate = self;
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:ADD_LINK_TITLE
													  target:self
													  action:@selector(editFormattedLink:)
											   keyEquivalent:@""];
	[toolbarMenu addItem:menuItem];
	menuItem = [[NSMenuItem alloc] initWithTitle:RM_LINK_TITLE
										  target:self
										  action:@selector(removeFormattedLink:)
								   keyEquivalent:@""];
	[toolbarMenu addItem:menuItem];
	
	toolbarItem = [[AIPopUpToolbarItem alloc] initWithItemIdentifier:@"LinkEditor"];
	toolbarItem.menu = toolbarMenu;
	toolbarItem.label = AILocalizedString(@"Link",nil);
	toolbarItem.paletteLabel = AILocalizedString(@"Insert Link",nil);
	toolbarItem.toolTip = AILocalizedString(@"Add/Edit Hyperlink",nil);
	toolbarItem.image = [NSImage imageNamed:@"msg-insert-link" forClass:[self class] loadLazily:NO];
	toolbarItem.target = self;
	toolbarItem.action =  @selector(addDefaultLink:);

	[adium.toolbarController registerToolbarItem:toolbarItem forToolbarType:@"TextEntry"];
}
@end
