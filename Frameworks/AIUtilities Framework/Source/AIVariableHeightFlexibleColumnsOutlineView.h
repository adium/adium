//
//  AIVariableHeightFlexibleColumnsOutlineView.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 3/16/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <AIUtilities/AIVariableHeightOutlineView.h>

@interface AIVariableHeightFlexibleColumnsOutlineView : AIVariableHeightOutlineView {

}

@end

@interface NSObject (AIVariableHeightFlexibleColumnsOutlineViewDelegate)
- (BOOL)outlineView:(NSOutlineView *)inOutlineView extendToEdgeColumn:(int)column ofRow:(int)row;
@end
