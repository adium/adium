//
//  AIOutlineViewAnimation.h
//  Adium
//
//  Created by Evan Schoenberg on 6/9/07.
//


@class AIAnimatingListOutlineView;

#define LIST_OBJECT_ANIMATION_DURATION .5
#define EXPANSION_DURATION .15

@interface AIOutlineViewAnimation : NSAnimation {
	NSDictionary *dict;
}

+ (AIOutlineViewAnimation *)listObjectAnimationWithDictionary:(NSDictionary *)inDict
													 delegate:(AIAnimatingListOutlineView *)inOutlineView;

@end
