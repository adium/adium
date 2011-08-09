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

#import "ESPanelApplescriptDetailPane.h"
#import "ESApplescriptContactAlertPlugin.h"
#import <Adium/AILocalizationTextField.h>
#import <Adium/AILocalizationButton.h>
#import <AIUtilities/AIStringAdditions.h>

@interface ESPanelApplescriptDetailPane ()
- (void)setScriptPath:(NSString *)inPath;
@end

/*!
 * @class ESPanelApplescriptDetailPane
 * @brief Details pane for the Run Applescript action
 */
@implementation ESPanelApplescriptDetailPane

/*!
 * @brief Nib name
 */
- (NSString *)nibName{
    return @"ApplescriptContactAlert";    
}

/*!
 * @brief Configure the details view
 */
- (void)viewDidLoad
{
	[super viewDidLoad];

	scriptPath = nil;
	
	[label_applescript setLocalizedString:AILocalizedString(@"AppleScript:",nil)];
	[button_browse setLocalizedString:[AILocalizedString(@"Browse",nil) stringByAppendingEllipsis]];
}

/*!
 * @brief View will close
 */
- (void)viewWillClose
{
	[scriptPath release]; scriptPath = nil;
}

/*!
 * @brief Called only when the pane is displayed a result of its action being selected
 *
 * @param inDetails A previously created details dicionary, or nil if none exists
 * @param inObject The object for which to configure
 */
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	[self setScriptPath:[inDetails objectForKey:KEY_APPLESCRIPT_TO_RUN]];
}

/*!
 * @brief Return our current configuration
 */
- (NSDictionary *)actionDetails
{
	return (scriptPath ?
		   [NSDictionary dictionaryWithObject:scriptPath forKey:KEY_APPLESCRIPT_TO_RUN] :
		   nil);
}

/*!
 * @brief Choose the applescript to run
 */
- (IBAction)chooseFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:AILocalizedString(@"Select an AppleScript",nil)];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"applescript",@"scptd",@"scpt",nil]];
	
	if ([openPanel runModal] == NSOKButton) {
		[self setScriptPath:[[openPanel URL] path]];
	}
}

/*!
 * @brief Set the path to the applescript
 *
 * This also updates our display
 *
 * @param inPath A full path to an applescript
 */
- (void)setScriptPath:(NSString *)inPath
{
	NSString	*scriptName;
	
	[scriptPath release];
	scriptPath = [inPath retain];
	
	//Update the display for this name
	scriptName = [[scriptPath lastPathComponent] stringByDeletingPathExtension];
	[textField_scriptName setStringValue:(scriptName ? scriptName : @"")];
	
	[self detailsForHeaderChanged];
}

@end
