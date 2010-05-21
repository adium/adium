//
//  AIAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 4/7/07.
//

#import <Adium/AIPreferencePane.h>

@class KNShelfSplitView, AIModularPaneCategoryView;

@interface AIAdvancedPreferences : AIPreferencePane {
	IBOutlet KNShelfSplitView			*shelf_splitView;
	
	IBOutlet NSTableView	*tableView_categories;
	IBOutlet AIModularPaneCategoryView	*modularPane;
	
	NSMutableArray		    *loadedAdvancedPanes;
	NSMutableArray		    *_advancedCategoryArray;
}

@end
