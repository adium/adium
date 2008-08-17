//
//  AIBorderlessListController.h
//  Adium
//
//  Created by Evan Schoenberg on 1/8/06.

#import "AIListController.h"

@interface AIBorderlessListController : AIListController {
	BOOL emptyListHiding;
	CGFloat previousAlpha;
}

@end
