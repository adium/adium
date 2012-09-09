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
	IBOutlet AIImageCollectionView *__weak imageCollectionView;
	IBOutlet NSButton *__weak okButton;
    
	NSMutableArray *icons;
	NSMutableArray *__weak iconsData;
		
	// Currently animated icon state and its index
    AIIconState *__weak animatedIconState;
	NSInteger animatedIndex;
	NSTimer *__weak animationTimer;
	
	// Previous selected icon
	NSUInteger previousIndex;
}

@property (weak) IBOutlet AIImageCollectionView *imageCollectionView;
@property (weak) IBOutlet NSButton *okButton;
@property (copy) NSMutableArray *icons;
@property (weak) NSMutableArray *iconsData;
@property (weak) AIIconState *animatedIconState;
@property (assign) NSInteger animatedIndex;
@property (weak) NSTimer *animationTimer;
@property (assign) NSUInteger previousIndex;

- (void)openOnWindow:(NSWindow *)parentWindow __attribute__((ns_consumes_self));

#pragma mark - Animations

- (void)setAnimatedDockIconAtIndex:(NSInteger)index;
- (AIIconState *)animatedStateForDockIconAtPath:(NSString *)path;

@end
