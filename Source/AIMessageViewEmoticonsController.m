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


#import "AIMessageViewEmoticonsController.h"
#import "AIEmoticonController.h"
/*#import <Adium/AIAccountControllerProtocol.h>
 #import <Adium/AIContactControllerProtocol.h>
 #import "AIStandardListWindowController.h"
 #import <Adium/AIAccount.h>
 #import <AIUtilities/AIApplicationAdditions.h>
 #import <AIUtilities/AIImageAdditions.h>
 #import <AIUtilities/AIMenuAdditions.h>
 #import <AIUtilities/AIStringAdditions.h>
 */
#import <Adium/AIEmoticonPack.h>
#import <Adium/AIEmoticon.h>
#import <AIUtilities/AIImageDrawingAdditions.h>

#define PREFERENCES_GROUP_EMOTICONS	@"Emoticons"


#pragma mark AIMessageViewEmoticonsController

@interface AIMessageViewEmoticonsController ()

- (id)initWithNibName:(NSString *)nibName textView:(AIMessageEntryTextView *)textView atPoint:(NSPoint)aPoint;
/* 
 - (void)emoticonsForPack:(AIEmoticonPack *)emoticonPack;
 
 // Menu actions
 - (void)insertEmoticon:(id)sender;
 */
// Notifications
//- (void)parentWindowWillClose:(NSNotification *)aNotification;

@end


@implementation AIMessageViewEmoticonsController

@synthesize menu, emoticonsCollectionView, emoticonTitleLabel, emoticonSymbolLabel;
@synthesize textView;
@synthesize emoticons, emoticonTitles, emoticonSymbols;


+ (void)popUpMenuForTextView:(AIMessageEntryTextView *)textView atPoint:(NSPoint)aPoint
{
	[[[self alloc] initWithNibName:@"MessageViewEmoticonsMenu" textView:textView atPoint:aPoint] autorelease];
}

/*!
 * @brief Set-up and open the menu
 */
- (id)initWithNibName:(NSString *)nibName textView:(AIMessageEntryTextView *)aView atPoint:(NSPoint)aPoint
{
	if ([[NSBundle mainBundle] loadNibFile:nibName
						 externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:self, NSNibOwner, AI_topLevelObjects, NSNibTopLevelObjects, nil]
								  withZone:nil]) {
		
		// Release top level objects, release AI_topLevelObjects in -dealloc
		[AI_topLevelObjects makeObjectsPerformSelector:@selector(release)];
		
		// Set the text view
		[self setTextView:aView];
		
		// Set-up collection view
		[emoticonsCollectionView setMaxNumberOfColumns:10];
		//[emoticonsCollectionView setMaxNumberOfRows:2];
		[emoticonsCollectionView setMinItemSize:NSMakeSize(20.0f, 20.0f)];
		[emoticonsCollectionView setMaxItemSize:NSMakeSize(20.0f, 20.0f)];
		[emoticonsCollectionView setHighlightStyle:AIImageCollectionViewHighlightBackgroundStyle];
		[emoticonsCollectionView setHighlightSize:0.0f];
		[emoticonsCollectionView setHighlightCornerRadius:3.0f];
		
		// Set-up emoticons
		NSArray	*activePacks = [adium.emoticonController activeEmoticonPacks];
		AIEmoticonPack *pack;
		AIEmoticon *emoticon;
		
		NSMutableArray *icons = [[NSMutableArray alloc] init];
		NSMutableArray *titles = [[NSMutableArray alloc] init];
		NSMutableArray *symbols = [[NSMutableArray alloc] init];
		
		if ([activePacks count] > 0) {
			for (pack in activePacks) {
				for (emoticon in [pack enabledEmoticons]) {
					[icons addObject:[[emoticon image] imageByScalingForMenuItem]];
					[titles addObject:[emoticon name]];
					[symbols addObject:[[emoticon textEquivalents] objectAtIndex:0]];
				}
			}
		}
		
		[self setEmoticons:icons];
		[self setEmoticonTitles:titles];
		[self setEmoticonSymbols:symbols];
		
		[icons release];
		[titles release];
		[symbols release];
		
		NSSize alignmentSize = NSMakeSize([alignmentView frame].size.width, ceil([[self emoticons] count] / 10.0f) * 20.0f);
		
		
		/*NSLog(@"%lu", [[self emoticons] count]);
		 NSLog(@"%f", [[self emoticons] count] / 10.0f * 20.0f);
		 NSLog(@"%f", ceil([[self emoticons] count] / 10.0f));
		 NSLog(@"%f", ceil([[self emoticons] count] / 10.0f) * 20.0f);
		 NSLog(@"%@", [[[[emoticonsCollectionView superview] superview] superview] class]);
		 NSLog(@"%@", NSStringFromSize(alignmentSize));*/
		// Add in flat emoticon menu
		/*if ([activePacks count] == 1) {
		 pack = [activePacks objectAtIndex:0];
		 AIEmoticon *emoticon = [[pack enabledEmoticons] objectAtIndex:0];
		 
		 if ([emoticon isEnabled] && ![[item representedObject] isEqualTo:emoticon]) {
		 [item setTitle:[emoticon name]];
		 [item setTarget:self];
		 [item setAction:@selector(insertEmoticon:)];
		 [item setKeyEquivalent:@""];
		 [item setImage:[[emoticon image] imageByScalingForMenuItem]];
		 [item setRepresentedObject:emoticon];
		 [item setSubmenu:nil];
		 }
		 // Add in multi-pack menu
		 } else if ([activePacks count] > 1) {
		 pack = [activePacks objectAtIndex:idx];
		 if (![[item title] isEqualToString:[pack name]]){
		 [item setTitle:[pack name]];
		 [item setTarget:nil];
		 [item setAction:nil];
		 [item setKeyEquivalent:@""];
		 [item setImage:[[pack menuPreviewImage] imageByScalingForMenuItem]];
		 [item setRepresentedObject:nil];
		 [item setSubmenu:[self flatEmoticonMenuForPack:pack]];
		 }
		 }*/
		/*NSMutableArray *pictures = [self recentSmallPictures];
		 NSSize pictureSize = NSMakeSize(32.0f, 32.0f);
		 
		 // Resize pictures
		 for (NSImage *picture in pictures) {
		 [picture setSize:pictureSize];
		 }
		 
		 if ([pictures count] < 10) {
		 // Create an "empty" image, placeholder icon
		 NSImage	*emptyPicture = [[NSImage alloc] initWithSize:pictureSize];
		 
		 [emptyPicture lockFocus];
		 [[NSColor secondarySelectedControlColor] set];
		 NSRectFill(NSMakeRect(0.0f, 0.0f, 32.0f, 32.0f));
		 [emptyPicture unlockFocus];
		 
		 // Add placeholders to images
		 for (NSUInteger i = [pictures count]; i < 10; ++i) {
		 [pictures addObject:emptyPicture];
		 }
		 
		 [emptyPicture release];
		 }
		 
		 [self setImages:pictures];
		 */		
		/*[[NSNotificationCenter defaultCenter] addObserver:self
		 selector:@selector(parentWindowWillClose:)
		 name:NSWindowWillCloseNotification
		 object:[aView window]];
		 */
		
		/*[menu popUpMenuPositioningItem:[menu itemAtIndex:0]
							atLocation:NSMakePoint([aView frame].size.width - [menu size].width - 5.0f, -[menu size].height)
								inView:[aView superview]];*/
		//[aView bounds].size.width - [menu size].width - 5.0f, [aView bounds].size.height - [menu size].height		
		//([menu numberOfItems] - 1)
		[alignmentView setFrameSize:alignmentSize];
		[alignmentView setNeedsDisplay:YES];
		
		// Adjust opening position
		aPoint.x -= [menu size].width;

		[menu popUpMenuPositioningItem:[menu itemAtIndex:0]
							atLocation:aPoint
								inView:[aView superview]];
	}
	
	return self;
}

- (void)dealloc
{
	[emoticons release];
	[emoticonTitles release];
	[emoticonSymbols release];
	[textView release];
	[AI_topLevelObjects release];
	
	[super dealloc];
}

#pragma mark -

/*- (NSArray *)recentPictures
 {
 NSArray *recentPictures = [(IKPictureTakerRecentPictureRepository *)[IKPictureTakerRecentPictureRepository recentRepository] recentPictures];
 
 if (recentPictures.count > 10)
 return [recentPictures subarrayWithRange:NSMakeRange(0, 10)];
 else
 return recentPictures;
 }*/

/*!
 * @brief Small icons for recent pictures
 */
/*- (NSMutableArray *)recentSmallPictures
 {
 NSArray *recentPictures = [self recentPictures];
 
 NSMutableArray *array = [[recentPictures valueForKey:@"smallIcon"] mutableCopy];
 for (NSInteger i = (array.count-1); i >= 0; i--) {
 id imageOrNull = [array objectAtIndex:i];
 
 // Not all icons have a small icon
 if (imageOrNull == [NSNull null]) {
 IKPictureTakerRecentPicture *picture = [recentPictures objectAtIndex:i];
 
 [array replaceObjectAtIndex:i
 withObject:[picture editedImage]];
 }
 }
 
 return [array autorelease];
 }*/

#pragma mark - NSMenu delegate

- (void)menuNeedsUpdate:(NSMenu *)aMenu
{
	/*NSSize alignmentSize = NSMakeSize([[[[[self emoticonsCollectionView] superview] superview] superview] frame].size.width, ceil([[self emoticons] count] / 10.0f) * 20.0f);
	 //NSSize newSize = NSMakeSize([[[[self emoticonsCollectionView] superview] superview] frame].size.width, alignmentSize.height);
	 //NSLog(@"%@", NSStringFromSize(alignmentSize));
	 //NSLog(@"%@", NSStringFromSize(newSize));
	 
	 NSLog(@"%@", NSStringFromRect([[[self emoticonsCollectionView] superview] frame]));
	 NSLog(@"%@", NSStringFromRect([[[[self emoticonsCollectionView] superview] superview] frame]));
	 NSLog(@"%@", NSStringFromRect([[[[[self emoticonsCollectionView] superview] superview] superview] frame]));
	 
	 //NSLog(@"%@", [[[[self emoticonsCollectionView] superview] superview] class]);
	 [[[[[self emoticonsCollectionView] superview] superview] superview] setFrameSize:alignmentSize];
	 [[[[[self emoticonsCollectionView] superview] superview] superview] setNeedsDisplay:YES];
	 
	 //[[menu itemAtIndex:0] setView:[[[[self emoticonsCollectionView] superview] superview] superview]];
	 //[[[[self emoticonsCollectionView] superview] superview] setFrameSize:newSize];
	 
	 //[[[menu itemAtIndex:0] view] setFrameSize:alignmentSize];
	 //[[[menu itemAtIndex:0] view] setNeedsDisplay:YES];
	 */
	
	/*NSMenuItem *menuItem;
	 
	 menuItem = [aMenu itemAtIndex:0];
	 [menuItem setTitle:AILocalizedString(@"Recent Icons:", "Label at the top of the recent icons picker shown in the contact list")];
	 
	 // Add menu items for accounts
	 NSMutableSet *onlineAccounts = [NSMutableSet set];
	 NSMutableSet *ownIconAccounts = [NSMutableSet set];
	 
	 AIAccount *activeAccount = nil;
	 activeAccount = [AIStandardListWindowController activeAccountForIconsGettingOnlineAccounts:onlineAccounts
	 ownIconAccounts:ownIconAccounts];
	 
	 NSInteger ownIconAccountsCount = [ownIconAccounts count];
	 NSInteger onlineAccountsCount = [onlineAccounts count];
	 
	 if (ownIconAccountsCount > 1) {
	 menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Change Icon For:", nil)
	 target:nil
	 action:nil
	 keyEquivalent:@""];
	 
	 [menuItem setEnabled:NO];
	 [aMenu addItem:menuItem];
	 [menuItem release];
	 
	 for (AIAccount *account in ownIconAccounts) {
	 menuItem = [[NSMenuItem alloc] initWithTitle:account.formattedUID
	 target:self
	 action:@selector(selectedAccount:)
	 keyEquivalent:@""];
	 
	 [menuItem setRepresentedObject:account];
	 
	 //Put a checkmark if it is the active account
	 if (activeAccount == account) {
	 [menuItem setState:NSOnState];
	 }
	 
	 [menuItem setIndentationLevel:1];
	 [aMenu addItem:menuItem];
	 
	 [menuItem release];
	 }
	 
	 //There are at least some accounts using the global preference if the counts differ
	 if (onlineAccountsCount != ownIconAccountsCount) {
	 menuItem = [[NSMenuItem alloc] initWithTitle:ALL_OTHER_ACCOUNTS
	 target:self
	 action:@selector(selectedAccount:)
	 keyEquivalent:@""];
	 if (!activeAccount) {
	 [menuItem setState:NSOnState];
	 }
	 
	 [menuItem setIndentationLevel:1];
	 [aMenu addItem:menuItem];
	 [menuItem release];
	 }
	 
	 [aMenu addItem:[NSMenuItem separatorItem]];
	 }
	 
	 menuItem = [[NSMenuItem alloc] initWithTitle:[AILocalizedString(@"Choose Icon", nil) stringByAppendingEllipsis]
	 target:self
	 action:@selector(choosePicture:)
	 keyEquivalent:@""];
	 
	 [aMenu addItem:menuItem];
	 [menuItem release];
	 
	 menuItem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Clear Recent Pictures", nil)
	 target:self
	 action:@selector(clearRecentPictures:)
	 keyEquivalent:@""];
	 
	 [aMenu addItem:menuItem];
	 [menuItem release];*/
}

- (void)menuDidClose:(NSMenu *)aMenu
{
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//[[[self textView] window] makeFirstResponder:(NSResponder *)textView];
	//NSLog(@"%@", [[[[NSApplication sharedApplication] keyWindow] firstResponder] class]);
}

#pragma mark - AIImageCollectionView delegate

- (BOOL)imageCollectionView:(AIImageCollectionView *)collectionView shouldHighlightItemAtIndex:(NSUInteger)anIndex
{	
	return (anIndex < [[self emoticons] count]);
}

- (void)imageCollectionView:(AIImageCollectionView *)collectionView didHighlightItemAtIndex:(NSUInteger)anIndex
{
	if (anIndex < [[self emoticons] count]) {
		// Update Title and Symbol (Text Equivalent)
		[[self emoticonTitleLabel] setTitleWithMnemonic:[[self emoticonTitles] objectAtIndex:anIndex]];
		[[self emoticonSymbolLabel] setTitleWithMnemonic:[[self emoticonSymbols] objectAtIndex:anIndex]];
	}
}

- (BOOL)imageCollectionView:(AIImageCollectionView *)imageCollectionView shouldSelectItemAtIndex:(NSUInteger)anIndex
{
	return (anIndex < [[self emoticons] count]);
}

- (void)imageCollectionView:(AIImageCollectionView *)imageCollectionView didSelectItemAtIndex:(NSUInteger)anIndex
{
	if (anIndex < [[self emoticons] count]) {
		// Insert emoticon
		NSString *emoticonString = [[self emoticonSymbols] objectAtIndex:anIndex];
		AIMessageEntryTextView *aTextView = [self textView];
		
		if (emoticonString && [aTextView isEditable]) {
			NSRange tmpRange = [aTextView selectedRange];
			
			/*if (tmpRange.length != 0) {
			 [aTextView setSelectedRange:NSMakeRange((tmpRange.location + tmpRange.length), 0)];
			 //NSLog(@"%@", NSStringFromRange(tmpRange));
			 }*/
			
			//NSLog(@"%@", [[[[NSApplication sharedApplication] keyWindow] firstResponder] class]);
			[aTextView insertText:emoticonString];
			
			if (tmpRange.length != 0) {
				[aTextView setSelectedRange:NSMakeRange((tmpRange.location + emoticonString.length), 0)];
				//NSLog(@"%@", NSStringFromRange(tmpRange));
			}
			
			
			//NSLog(@"%@", [[[[NSApplication sharedApplication] keyWindow] firstResponder] class]);
			//[[aTextView window] makeFirstResponder:(NSResponder *)aTextView];
			//NSLog(@"%@", [[[[NSApplication sharedApplication] keyWindow] firstResponder] class]);
			//[[[NSApplication sharedApplication] keyWindow] makeFirstResponder:(NSResponder *)aTextView];
		}
		
		// Make the text view have focus
		//[[adium.interfaceController windowForChat:timelineChat] makeFirstResponder:textView];
		
		//[[aTextView window] makeFirstResponder:(NSResponder *)aTextView];
		
		//NSLog(@"%@", [[[[NSApplication sharedApplication] keyWindow] firstResponder] class]);
		//id recentPicture = [recentPictures objectAtIndex:anIndex];
		/*
		 if ([sender isKindOfClass:[NSMenuItem class]]) {
		 NSString *emoString = [[[sender representedObject] textEquivalents] objectAtIndex:0];
		 
		 NSResponder *responder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
		 if (emoString && [responder isKindOfClass:[NSTextView class]] && [(NSTextView *)responder isEditable]) {
		 NSRange tmpRange = [(NSTextView *)responder selectedRange];
		 if (0 != tmpRange.length) {
		 [(NSTextView *)responder setSelectedRange:NSMakeRange((tmpRange.location + tmpRange.length),0)];
		 }
		 [responder insertText:emoString];
		 }
		 }
		 */
	}
	
	[menu cancelTracking];
}

#pragma mark - Menu Actions
/*
 - (void)insertEmoticon:(id)sender
 {
 //[sender representedObject];
 }*/

#pragma mark - Parent Window Notifications

/*- (void)windowDidResignMain:(NSNotification *)aNotification
 {
 [menu cancelTracking];
 }
 
 - (void)windowDidResignKey:(NSNotification *)aNotification
 {
 [menu cancelTracking];		
 }
 
 - (void)parentWindowWillClose:(NSNotification *)aNotification
 {
 // Close menu, when our parent window closes
 [menu cancelTracking];
 }*/

@end
