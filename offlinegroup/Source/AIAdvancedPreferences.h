//
//  AIAdvancedPreferences.h
//  Adium
//
//  Created by Evan Schoenberg on 4/7/07.
//

#import <Adium/AIPreferencePane.h>

@class KNShelfSplitView, AIAlternatingRowTableView, AIModularPaneCategoryView;

@interface AIAdvancedPreferences : AIPreferencePane {
	IBOutlet KNShelfSplitView			*shelf_splitView;
	
	IBOutlet AIAlternatingRowTableView	*tableView_categories;
	IBOutlet AIModularPaneCategoryView	*modularPane;
	
	NSMutableArray		    *loadedAdvancedPanes;
	NSMutableArray		    *_advancedCategoryArray;
}

@end
