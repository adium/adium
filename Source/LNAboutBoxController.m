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

#import "AISoundController.h"
#import "LNAboutBoxController.h"
#import <AIUtilities/AIEventAdditions.h>
#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>

#define ABOUT_BOX_NIB		@"AboutBox"
#define	ADIUM_SITE_LINK		AILocalizedString(@"http://www.adium.im","Adium homepage. Only localize if a translated version of the page exists.")

@interface LNAboutBoxController ()
- (id)initWithWindowNibName:(NSString *)windowNibName;

- (NSString *)AI_applicationVersion:(BOOL)withBuild;
- (NSString *)AI_applicationDate;
@end

@implementation LNAboutBoxController

// Returns the shared about box instance
LNAboutBoxController *sharedAboutBoxInstance = nil;

+ (LNAboutBoxController *)aboutBoxController
{
    if (!sharedAboutBoxInstance) {
        sharedAboutBoxInstance = [[self alloc] initWithWindowNibName:ABOUT_BOX_NIB];
    }
    return sharedAboutBoxInstance;
}

// Init
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    if ((self = [super initWithWindowNibName:windowNibName])) {
		numberOfDuckClicks = -1;
	}

	return self;
}

// Prepare the about box window
- (void)windowDidLoad
{
    NSAttributedString *creditsString;
    
    // Credits
    creditsString = [[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"]
										   documentAttributes:nil];
	[textView_credits loadText:creditsString];
	
    // Setup the build date / version
    [textField_version setStringValue:[self AI_applicationVersion:NO]];
    
	// Set the localized values
	[button_homepage setLocalizedString:AILocalizedString(@"Adium Homepage",nil)];
	[button_license setLocalizedString:AILocalizedString(@"License",nil)];

    [[self window] betterCenter];
}

// Cleanup as the window is closing
- (void)windowWillClose:(id)sender
{
	[super windowWillClose:sender];
	
    sharedAboutBoxInstance = nil;
}

// Visit the Adium homepage
- (IBAction)visitHomepage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.adium.im"]];
}

// Receive the flags changed event for starting/stopping the automatic scroll via option
- (void)flagsChanged:(NSEvent *)theEvent
{
    if ([theEvent optionKey]) {
		[textView_credits toggleScrolling];
    }
}

#pragma mark Build Information

// Toggle build date/number display
- (IBAction)buildFieldClicked:(id)sender
{
    if ((++numberOfBuildFieldClicks) % 2 == 0) {
        [textField_version setStringValue:[self AI_applicationVersion:NO]];
    } else {
        [textField_version setStringValue:[self AI_applicationVersion:YES]];
    }
}

// Returns the current version of Adium
- (NSString *)AI_applicationVersion:(BOOL)withBuild
{
    NSString *version = [NSApp applicationVersion];

    return [NSString stringWithFormat:@"%@%@ (%@)", @"Version ",
                                    	(version ? version : @"X"),
            							(withBuild ? [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AIBuildIdentifier"]
                                                	: [self AI_applicationDate])];
}

// Returns the formatted build date of Adium
- (NSString *)AI_applicationDate
{
	NSTimeInterval date = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"AIBuildDate"] doubleValue];
	__block NSString *ret;
	
	[NSDateFormatter withLocalizedShortDateFormatterPerform:^(NSDateFormatter *shortDateFormatter){
		ret = [shortDateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:date]];
	}];
	
	return ret;
}

#pragma mark Software License

// Display the software license sheet
- (IBAction)showLicense:(id)sender
{
	NSURL	*licenseURL = [NSURL fileURLWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"License" ofType:@"txt"]];
	[textView_license setString:[NSString stringWithContentsOfURL:licenseURL
														 encoding:NSUTF8StringEncoding
															error:NULL]];
	
	[NSApp beginSheet:panel_licenseSheet
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

// Close the software license sheet
- (IBAction)hideLicense:(id)sender
{
    [panel_licenseSheet orderOut:nil];
    [NSApp endSheet:panel_licenseSheet returnCode:0];
}

#pragma mark Sillyness

// Flap the duck when clicked
- (IBAction)adiumDuckClicked:(id)sender
{
    numberOfDuckClicks++;
	
#define PATH_TO_SOUNDS		[NSString pathWithComponents:[NSArray arrayWithObjects:[[NSBundle mainBundle] bundlePath], @"Contents", @"Resources", @"Sounds", @"Adium.AdiumSoundset", nil]]

	if (numberOfDuckClicks == 10) {
		numberOfDuckClicks = -1;            
		[adium.soundController playSoundAtPath:[PATH_TO_SOUNDS stringByAppendingPathComponent:@"Feather Ruffle.aif"]];
	} else {
		[adium.soundController playSoundAtPath:[PATH_TO_SOUNDS stringByAppendingPathComponent:@"Quack.aif"]];
	}
	
}

@end
