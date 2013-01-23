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

#import "AIOTRTopBarLoggingWarningController.h"
#import <Adium/AIPreferenceControllerProtocol.h>

@implementation AIOTRTopBarLoggingWarningController

- (id)init
{
    self = [super initWithNibName:@"AIOTRTopBarLoggingWarningController"
						   bundle:[NSBundle bundleForClass:[AIOTRTopBarLoggingWarningController class]]];
    if (self) {
        [self loadView];
		
		view_backgroundView.startColor = [NSColor colorWithCalibratedRed:1.0
																   green:.95
																	blue:.3
																   alpha:1.0];
		
		view_backgroundView.endColor = [NSColor colorWithCalibratedRed:1.0
																 green:.95
																  blue:.5
																 alpha:1.0];
    }
    
    return self;
}

- (IBAction)configureLogging:(id)sender
{
	[adium.preferenceController openPreferencesToCategoryWithIdentifier:@"Messages"];
}

@end
