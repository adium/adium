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
