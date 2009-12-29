//
//  AIContactListRecentImagesWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 12/19/05.
//

#import "AIContactListRecentImagesWindowController.h"
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import "AIStandardListWindowController.h"
#import "AIContactListImagePicker.h"
#import "AIMenuItemView.h"
#import <Adium/AIAccount.h>
#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIBorderlessWindow.h>
#import <AIUtilities/AIColoredBoxView.h>
#import <AIUtilities/AIImageGridView.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#import "IKRecentPicture.h" //10.5+, private

#define FADE_INCREMENT	0.3
#define FADE_TIME		.3

@interface AIContactListRecentImagesWindowController ()
- (id)initWithWindowNibName:(NSString *)inWindowNibName
				imagePicker:(AIContactListImagePicker *)inPicker;
- (void)fadeOutAndClose;
@end

@implementation AIContactListRecentImagesWindowController
/*!
 * @brief Show the window
 *
 * @param inPoint The bottom-right corner of our parent view
 * @param inPicker Our parent AIContactListImagePicker
 */
+ (void)showWindowFromPoint:(NSPoint)inPoint
				imagePicker:(AIContactListImagePicker *)inPicker
{
	AIContactListRecentImagesWindowController	*controller = [[self alloc] initWithWindowNibName:@"ContactListRecentImages"
																					  imagePicker:inPicker];

	NSWindow			*window = [controller window];

	[controller positionFromPoint:inPoint];
	[(AIBorderlessWindow *)window setMoveable:NO];
	
	[controller showWindow:nil];
	[window makeKeyAndOrderFront:nil];
}

- (id)initWithWindowNibName:(NSString *)inWindowNibName
				imagePicker:(AIContactListImagePicker *)inPicker
{
	if ((self = [super initWithWindowNibName:inWindowNibName])) {
		picker = [inPicker retain];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(parentWindowWillClose:)
													 name:NSWindowWillCloseNotification
												   object:[picker window]];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[picker release];
	
	[super dealloc];
}

- (void)windowDidLoad
{
	[imageGridView setImageSize:NSMakeSize(30, 30)];	
	[coloredBox setColor:[NSColor windowBackgroundColor]];
	[label_recentIcons setLocalizedString:AILocalizedString(@"Recent Icons:", "Label at the top of the recent icons picker shown in the contact list")];

	[picker setMaxSize:NSMakeSize(256, 256)];

	currentHoveredIndex = -1;
}

- (void)positionFromPoint:(NSPoint)inPoint
{
	NSWindow *window = [self window];
	NSRect	 frame = [window frame];
	NSRect	 screenFrame = [[window screen] visibleFrame];
	
	frame.origin.x = inPoint.x - frame.size.width;
	if (frame.origin.x < screenFrame.origin.x) {
		frame.origin.x = screenFrame.origin.x;
	} else if (frame.origin.x + frame.size.width > screenFrame.origin.x + screenFrame.size.width) {
		frame.origin.x = screenFrame.origin.x + screenFrame.size.width - frame.size.width;
	}
	
	frame.origin.y = inPoint.y - frame.size.height;
	if (frame.origin.y < screenFrame.origin.y) {
		frame.origin.y = screenFrame.origin.y;
	}
	
	//Ensure our window is visible above the window of the imagePicker that created us
	if ([window level] < [[picker window] level]) {
		[window setLevel:[[picker window] level] + 1];
	}
	
	[window setFrame:frame display:NO animate:NO];	
}

- (NSUInteger)numberOfImagesInImageGridView:(AIImageGridView *)imageGridView
{
	return 10;
}

- (NSArray *)recentPictures
{
	return [(IKPictureTakerRecentPictureRepository *)[IKPictureTakerRecentPictureRepository recentRepository] recentPictures];
}

- (NSArray *)recentSmallIcons
{
	return [[(IKPictureTakerRecentPictureRepository *)[IKPictureTakerRecentPictureRepository recentRepository] recentPictures] valueForKey:@"smallIcon"];
}

- (NSImage *)imageGridView:(AIImageGridView *)imageGridView imageAtIndex:(NSUInteger)index
{
	NSImage		*displayImage;
	NSArray		*recentSmallIcons = [self recentSmallIcons];
	if (index < [recentSmallIcons count]) {
		NSImage		 *image = [recentSmallIcons objectAtIndex:index];
		NSSize		size = [image size];
		NSBezierPath *fullPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, size.width, size.height)];
		displayImage = [image copy];
		
		[displayImage lockFocus];
		
		if (index == currentHoveredIndex) {
			[[[NSColor blueColor] colorWithAlphaComponent:0.30f] set];
			[fullPath fill];
			
			[[NSColor blueColor] set];
			[fullPath stroke];
			
		} else {
			[[NSColor whiteColor] set];
			[fullPath stroke];
		}
		
		[displayImage unlockFocus];
	} else {
		NSSize		 size = NSMakeSize(32, 32);
		NSBezierPath *fullPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, size.width, size.height)];

		displayImage = [[NSImage alloc] initWithSize:size];
		[displayImage lockFocus];
		
		[[NSColor lightGrayColor] set];
		[fullPath fill];
		
		[displayImage unlockFocus];
	}
	
	return [displayImage autorelease];
}

- (void)imageGridView:(AIImageGridView *)inImageGridView cursorIsHoveringImageAtIndex:(NSUInteger)index
{
	//Update our hovered index and redisplay the image
	currentHoveredIndex = index;
	[imageGridView setNeedsDisplayOfImageAtIndex:index];
}

- (void)imageGridViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger selectedIndex = [imageGridView selectedIndex];
	NSArray *recentPictures = [self recentPictures];
	if (selectedIndex < [recentPictures count]) {
		id		recentPicture = [recentPictures objectAtIndex:selectedIndex];
		NSData	*imageData = nil;
		if ([recentPicture respondsToSelector:@selector(editedImage)])
			imageData = [[recentPicture editedImage] PNGRepresentation];
		else if ([recentPicture respondsToSelector:@selector(originalImagePath)])
			imageData = [NSData dataWithContentsOfFile:[recentPicture originalImagePath]];

		//Notify as if the image had been selected in the picker
		[[picker delegate] imageViewWithImagePicker:picker
							   didChangeToImageData:imageData];

		//Now pass on the actual recent picture for use if possible
		[picker setRecentPictureAsImageInput:recentPicture];
	}
	[self fadeOutAndClose];
}

- (void)selectedAccount:(id)sender
{
	AIAccount	*activeAccount = [sender representedObject];

	//Change the active account
	[adium.preferenceController setPreference:(activeAccount ? activeAccount.internalObjectID : nil)
										 forKey:@"Active Icon Selection Account"
										  group:GROUP_ACCOUNT_STATUS];

	[menuItemView setMenu:[self menuForMenuItemView:menuItemView]];
}

- (void)chooseIcon:(id)sender
{
	[picker showImagePicker:nil];
	
	[self fadeOutAndClose];
}

- (void)clearRecentPictures:(id)sender
{
	[[IKPictureTakerRecentPictureRepository recentRepository] clearRecents:nil];
	[imageGridView reloadData];
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	[self fadeOutAndClose];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	[self fadeOutAndClose];		
}

- (void)parentWindowWillClose:(NSNotification *)aNotification
{
	//Close, no fade, when our parent window closes
	[self close];
}

#pragma mark Fading
- (void)fadeOut:(NSTimer *)inTimer
{
	CGFloat				currentAlpha = [[self window] alphaValue];
	currentAlpha -= 0.15f;
	
	if (currentAlpha <= 0) {
		[self close];
		[inTimer invalidate];

	} else {
		[[self window] setAlphaValue:currentAlpha];
	}
}

- (void)fadeOutAndClose
{
	[NSTimer scheduledTimerWithTimeInterval:.01
									 target:self 
								   selector:@selector(fadeOut:)
								   userInfo:nil
									repeats:YES];
}

#pragma mark AIMenuItemView delegate

- (NSMenu *)menuForMenuItemView:(AIMenuItemView *)inMenuItemView
{
	NSMenu		 *menu = [[NSMenu alloc] init];
	NSMutableSet *onlineAccounts = [NSMutableSet set];
	NSMutableSet *ownIconAccounts = [NSMutableSet set];
	AIAccount	 *activeAccount = nil;
	NSMenuItem	 *menuItem;

	activeAccount = [AIStandardListWindowController activeAccountForIconsGettingOnlineAccounts:onlineAccounts
																			   ownIconAccounts:ownIconAccounts];
	
	NSInteger ownIconAccountsCount = [ownIconAccounts count];
	NSInteger onlineAccountsCount = [onlineAccounts count];
	if (ownIconAccountsCount && ((ownIconAccountsCount > 1) || (onlineAccountsCount > 1))) {
		//There are at least some accounts using the global preference if the counts differ
		BOOL		 includeGlobal = (onlineAccountsCount != ownIconAccountsCount);
		AIAccount	 *account;

		menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Change Icon For:", nil)
											  target:nil
											  action:nil
									   keyEquivalent:@""];
		[menuItem setEnabled:NO];
		[menu addItem:menuItem];
		[menuItem release];
		
		for (account in ownIconAccounts) {
			//Put a check before the account if it is the active account
			menuItem = [[NSMenuItem alloc] initWithTitle:account.formattedUID
												  target:self
												  action:@selector(selectedAccount:)
										   keyEquivalent:@""];
			[menuItem setRepresentedObject:account];

			if (activeAccount == account) {
				[menuItem setState:NSOnState];
			}
			[menuItem setIndentationLevel:1];
			[menu addItem:menuItem];
			
			[menuItem release];
		}
		
		if (includeGlobal) {
			menuItem = [[NSMenuItem alloc] initWithTitle:ALL_OTHER_ACCOUNTS
												  target:self
												  action:@selector(selectedAccount:)
										   keyEquivalent:@""];
			if (!activeAccount) {
				[menuItem setState:NSOnState];
			}
			[menuItem setIndentationLevel:1];

			[menu addItem:menuItem];
			[menuItem release];
		}
		
		[menu addItem:[NSMenuItem separatorItem]];

	} else {
		//All accounts are using the global preference
	}

	menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Choose Icon", nil) stringByAppendingEllipsis]
										  target:self
										  action:@selector(chooseIcon:)
								   keyEquivalent:@""];
	[menu addItem:menuItem];
	[menuItem release];

	menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Clear Recent Pictures", nil)
										  target:self
										  action:@selector(clearRecentPictures:)
								   keyEquivalent:@""];
	[menu addItem:menuItem];
	[menuItem release];

	return [menu autorelease];
}

- (void)menuItemViewDidChangeMenu:(AIMenuItemView *)inMenuItemView
{
	NSRect	oldFrame = [inMenuItemView frame];
	[inMenuItemView sizeToFit];
	NSRect	newFrame = [inMenuItemView frame];

	CGFloat	heightDifference = newFrame.size.height - oldFrame.size.height;

	if (heightDifference != 0) {
		NSRect	myFrame = [[self window] frame];
		
		myFrame.size.height += heightDifference;
		myFrame.origin.y -= heightDifference;
		
		[[self window] setFrame:myFrame display:YES animate:NO];
	}
}


@end
