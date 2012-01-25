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

#import <Adium/AIWindowController.h>
#import <AIUtilities/AIImageCollectionView.h>

@class AIIconState;

@interface AIDockIconSelectionSheet : AIWindowController <AIImageCollectionViewDelegate> {
@private
	IBOutlet AIImageCollectionView *__unsafe_unretained imageCollectionView;
	IBOutlet NSButton *__unsafe_unretained okButton;
    
	NSMutableArray *icons;
	NSMutableArray *__unsafe_unretained iconsData;
		
	// Currently animated icon state and its index
    AIIconState *__unsafe_unretained animatedIconState;
	NSInteger animatedIndex;
	NSTimer *__unsafe_unretained animationTimer;
	
	// Previous selected icon
	NSUInteger previousIndex;
}

@property (unsafe_unretained) IBOutlet AIImageCollectionView *imageCollectionView;
@property (unsafe_unretained) IBOutlet NSButton *okButton;
@property (copy) NSMutableArray *icons;
@property (unsafe_unretained) NSMutableArray *iconsData;
@property (unsafe_unretained) AIIconState *animatedIconState;
@property (assign) NSInteger animatedIndex;
@property (unsafe_unretained) NSTimer *animationTimer;
@property (assign) NSUInteger previousIndex;

+ (void)showDockIconSelectorOnWindow:(NSWindow *)parentWindow;

#pragma mark - Animations

- (void)setAnimatedDockIconAtIndex:(NSInteger)index;
- (AIIconState *)animatedStateForDockIconAtPath:(NSString *)path;

@end
