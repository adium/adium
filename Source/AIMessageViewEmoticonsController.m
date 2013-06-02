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
#import <Adium/AIEmoticonPack.h>
#import <Adium/AIEmoticon.h>
#import <AIUtilities/AIImageDrawingAdditions.h>
#import "AIMessageEntryTextView.h"

#define PREFERENCES_GROUP_EMOTICONS	@"Emoticons"


#pragma mark AIMessageViewEmoticonsController

@interface AIMessageViewEmoticonsController ()

- (id)initWithNibName:(NSString *)nibName textView:(AIMessageEntryTextView *)textView atPoint:(NSPoint)aPoint;

@end


@implementation AIMessageViewEmoticonsController

@synthesize textView;
@synthesize emoticons, emoticonTitles, emoticonSymbols;

@synthesize menu, emoticonsCollectionView, emoticonTitleLabel, emoticonSymbolLabel, alignmentView;

+ (void)popUpMenuForTextView:(AIMessageEntryTextView *)textView atPoint:(NSPoint)aPoint
{
	[[self alloc] initWithNibName:@"MessageViewEmoticonsMenu" textView:textView atPoint:aPoint];
}

- (void)dealloc
{
	AILogWithSignature(@"%p", self);
}

/*!
 * @brief Set-up and open the menu
 */
- (id)initWithNibName:(NSString *)nibName textView:(AIMessageEntryTextView *)aView atPoint:(NSPoint)aPoint
{
	self = [super init];
	if ([[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:nil]) {
		
		// Set the text view
		[self setTextView:aView];
		
		// Set-up collection view
		[self.emoticonsCollectionView setMaxNumberOfColumns:10];
		[self.emoticonsCollectionView setMinItemSize:NSMakeSize(20.0f, 20.0f)];
		[self.emoticonsCollectionView setMaxItemSize:NSMakeSize(20.0f, 20.0f)];
		[self.emoticonsCollectionView setHighlightStyle:AIImageCollectionViewHighlightBackgroundStyle];
		[self.emoticonsCollectionView setHighlightSize:0.0f];
		[self.emoticonsCollectionView setHighlightCornerRadius:3.0f];
		
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
		
		NSSize alignmentSize = NSMakeSize([alignmentView frame].size.width, ceil([[self emoticons] count] / 10.0f) * 20.0f);
		
		[alignmentView setFrameSize:alignmentSize];
		[alignmentView setNeedsDisplay:YES];
		
		// Adjust opening position
		aPoint.x -= [menu size].width;

		[menu popUpMenuPositioningItem:[menu itemAtIndex:0]
							atLocation:aPoint
								inView:[aView superview]];
	}
	
	AILogWithSignature(@"%p", self);
	
	return self;
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
		[emoticonTitleLabel setTitleWithMnemonic:[[self emoticonTitles] objectAtIndex:anIndex]];
		[emoticonSymbolLabel setTitleWithMnemonic:[[self emoticonSymbols] objectAtIndex:anIndex]];
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
			
			[aTextView insertText:emoticonString];
			
			if (tmpRange.length != 0) {
				[aTextView setSelectedRange:NSMakeRange((tmpRange.location + emoticonString.length), 0)];
			}
		}
	}
	
	[menu cancelTracking];
}

- (void)menuDidClose:(NSMenu *)inMenu
{
	[menu setDelegate:nil];
	[emoticonsCollectionView setDelegate:nil];
}

@end
