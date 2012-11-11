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

#import <Adium/AIModularPane.h>

@implementation AIModularPane

//Return a new modular pane
+ (AIModularPane *)modularPane
{
    return [[self alloc] init];
}

//Return a new modular pane, passing plugin
+ (AIModularPane *)modularPaneForPlugin:(id)inPlugin
{
    return [[self alloc] initForPlugin:inPlugin];
}

//Init, passing plugin
- (id)initForPlugin:(id)inPlugin
{
    plugin = inPlugin;
    return [self init];
}

//Init
- (id)init
{
    if ((self = [super init]))
	{
		view = nil;
	}
    
    return self;
}

//Compare to another category view (for sorting on the preference window)
- (NSComparisonResult)compare:(AIModularPane *)inPane
{
    return [[self label] caseInsensitiveCompare:[inPane label]];
}

//Returns our view
- (NSView *)view
{
    if (!view) {
        //Load and configure our view
        [NSBundle loadNibNamed:[self nibName] owner:self];
        [self viewDidLoad];
		[self localizePane];
		if (![self resizable]) [view setAutoresizingMask:(NSViewMaxYMargin)];
    }
    
    return view;
}

//Close our view
- (void)closeView
{
	if (view) {
		[self viewWillClose];
		view = nil;
	}
}


//For subclasses -------------------------------------------------------------------------------
//Pane label
- (NSString *)label
{
	return @"";
}

//Nib to load
- (NSString *)nibName
{
    return @"";    
}

//Configure the preference view
- (void)viewDidLoad
{
    
}

- (void)localizePane
{
	
}

//Preference view is closing
- (void)viewWillClose
{
    
}

//Apply a changed controls
- (IBAction)changePreference:(id)sender
{
    [self configureControlDimming];
}

//Configure control dimming
- (void)configureControlDimming
{
    
}

//Resizable
- (BOOL)resizable
{
	return NO;
}

- (BOOL)resizableHorizontally
{
	return NO;
}

@end
