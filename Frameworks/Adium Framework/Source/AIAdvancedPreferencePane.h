//
//  AIAdvancedPreferencePane.h
//  Adium
//
//  Created by Evan Schoenberg on 8/23/06.
//

#import <Adium/AIModularPane.h>

@interface AIAdvancedPreferencePane : AIModularPane {

}

+ (AIAdvancedPreferencePane *)preferencePane;
+ (AIAdvancedPreferencePane *)preferencePaneForPlugin:(id)inPlugin;

@end
