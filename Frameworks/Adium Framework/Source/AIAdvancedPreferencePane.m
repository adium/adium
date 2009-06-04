//
//  AIAdvancedPreferencePane.m
//  Adium
//
//  Created by Evan Schoenberg on 8/23/06.
//

#import "AIAdvancedPreferencePane.h"

@implementation AIAdvancedPreferencePane
//Return a new preference pane
+ (AIAdvancedPreferencePane *)preferencePane
{
    return [[[self alloc] init] autorelease];
}

//Return a new preference pane, passing plugin
+ (AIAdvancedPreferencePane *)preferencePaneForPlugin:(id)inPlugin
{
    return [[[self alloc] initForPlugin:inPlugin] autorelease];
}

//Init
- (id)init
{
	if ((self = [super init])) {
		[adium.preferenceController addAdvancedPreferencePane:self];
	}
	return self;
}

- (NSComparisonResult)caseInsensitiveCompare:(id)other
{
	NSString *nibName = [self label];
	if ([other isKindOfClass:[NSString class]]) {
		return [nibName caseInsensitiveCompare:other];
	} else {
		return [nibName caseInsensitiveCompare:[other label]];
	}
}


//For subclasses -------------------------------------------------------------------------------
//Return an image for these preferences (advanced only)
- (NSImage *)image
{
	return nil;
}

//Resizable
- (BOOL)resizable
{
	return YES;
}

@end
