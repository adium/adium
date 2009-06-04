//
//  AIAnimatingListOutlineView.h
//  Adium
//
//  Created by Evan Schoenberg on 6/8/07.
//

#import <Adium/AIListOutlineView.h>

@interface AIAnimatingListOutlineView : AIListOutlineView {
	BOOL	enableAnimation;
	
	NSMutableDictionary *allAnimatingItemsDict;
	NSMutableSet *animations;
	NSInteger animationsCount;
	NSSize animationHedgeFactor;
	
	BOOL disableExpansionAnimation;
}

- (void)setEnableAnimation:(BOOL)shouldEnable;
- (BOOL)enableAnimation;

@end
