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

#define PREFERENCES_GROUP_EMOTICONS	@"Emoticons"


#pragma mark AIMessageViewEmoticonsController

@interface AIMessageViewEmoticonsController ()

- (id)initWithNibName:(NSString *)nibName textView:(AIMessageEntryTextView *)textView atPoint:(NSPoint)aPoint;

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
	self = [super init];
	if ([[NSBundle mainBundle] loadNibFile:nibName
						 externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:self, NSNibOwner, AI_topLevelObjects, NSNibTopLevelObjects, nil]
								  withZone:nil]) {
		
		// Release top level objects, release AI_topLevelObjects in -dealloc
		[AI_topLevelObjects makeObjectsPerformSelector:@selector(release)];
		
		// Set the text view
		[self setTextView:aView];
		
		// Set-up collection view
		[emoticonsCollectionView setMaxNumberOfColumns:10];
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
			
			[aTextView insertText:emoticonString];
			
			if (tmpRange.length != 0) {
				[aTextView setSelectedRange:NSMakeRange((tmpRange.location + emoticonString.length), 0)];
			}
		}
	}
	
	[menu cancelTracking];
}

@end
