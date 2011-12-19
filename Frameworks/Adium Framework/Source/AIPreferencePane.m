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

#import <Adium/AIPreferencePane.h>

#define PREFERENCE_VIEW_NIB		@"PreferenceView"	//Filename of the preference view nib

@implementation AIPreferencePane

//Return a new preference pane
+ (AIPreferencePane *)preferencePane
{
    return [[[self alloc] init] autorelease];
}

//Return a new preference pane, passing plugin
+ (AIPreferencePane *)preferencePaneForPlugin:(id)inPlugin
{
    return [[[self alloc] initForPlugin:inPlugin] autorelease];
}

//Init
- (id)init
{
	if ((self = [super init])) {
		[adium.preferenceController addPreferencePane:self];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

+ (NSArray *)preferencePanes
{
	return nil;
}

- (AIPreferenceCategory)category
{
	return AIPref_Advanced;
}

- (NSView *)paneView
{
	return [self view];
}

- (NSString *)paneName
{
	return [self label];
}

int getRandomNumber()
{
	return 4;	// chosen by fair dice roll.
				// guaranteed to be random.
}

- (NSString *)paneIdentifier
{
	NSLog(@"*** %@ does not implement paneIdentifier, which is required!", self);
	/* The subclass should implement paneIdentifier. If it doesn't, which can happen for an old external plugin,
	 * generate a random paneIdentifier for this instance so that we can still function properly.
	 */
	return [NSString stringWithFormat:@"uniquePaneIdentifier-%i",getRandomNumber()];
}

- (NSImage *)paneIcon
{
	return nil;
}

- (NSString *)paneToolTip
{
	return nil;
}

- (BOOL)allowsHorizontalResizing
{
	return NO;	
}

- (BOOL)allowsVerticalResizing
{
	return NO;
}

@end

