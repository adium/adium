//
//  AIURLHandlerAdvancedPreferences.h
//  Adium
//
//  Created by Zachary West on 2009-04-02.
//

#import <Adium/AIAdvancedPreferencePane.h>
#import <AIUtilities/AIAlternatingRowTableView.h>
#import "AIURLHandlerPlugin.h"

@interface AIURLHandlerAdvancedPreferences : AIAdvancedPreferencePane {
	IBOutlet		AIAlternatingRowTableView	*tableView;
	
	IBOutlet		NSButton					*button_setDefault;
	IBOutlet		NSButton					*checkBox_enforceDefault;
	
	NSArray										*servicesList;
	NSMutableDictionary							*services;
}

- (IBAction)setDefault:(id)sender;
- (IBAction)enforceDefault:(id)sender;

@end
