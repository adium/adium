//
//  AIFontSelectionPopUpButton.m
//  AIUtilities.framework
//
//  Created by Adam Iser on 6/17/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//

#import "AIFontSelectionPopUpButton.h"
#import "AIStringUtilities.h"
#import "AIMenuAdditions.h"
#import "AIParagraphStyleAdditions.h"

#define FONT_CUSTOM_TITLE		AILocalizedStringFromTableInBundle(@"Custom...", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)
#define FONT_SAMPLE_WIDTH		60
#define FONT_SAMPLE_HEIGHT		16

@interface AIFontSelectionPopUpButton (PRIVATE)
- (void)_buildFontMenu;
- (void)_setCustomFont:(NSFont *)inFont;
- (NSImage *)_sampleImageForFont:(NSFont *)inFont;
@end

@implementation AIFontSelectionPopUpButton

/*!
 * @brief Shared init code
 */
- (void)_initObjectSelectionPopUpButton
{
	[super _initObjectSelectionPopUpButton];
    
    //Setup our default fonts
    [self setCustomValue:[NSFont controlContentFontOfSize:0]];
    [self setPresetValues:[NSArray arrayWithObjects:
		@"System Font",[NSFont systemFontOfSize:0],
		@"Bold System Font",[NSFont boldSystemFontOfSize:0],
		@"Label Font",[NSFont labelFontOfSize:0],
		nil]];	
}

- (void)setFont:(NSFont *)inFont
{
	[self setObjectValue:inFont];
}

- (NSFont *)font
{
	return [self objectValue];
}

- (void)setAvailableFonts:(NSArray *)inFonts
{
	[self setPresetValues:inFonts];
}

/*!
 * @brief Invoked when the custom menu item is selected
 */
- (void)selectCustomValue:(id)sender
{
    [[NSFontManager sharedFontManager] setAction:@selector(customFontChanged:)];
	[[self window] makeFirstResponder:self];
    [[NSFontManager sharedFontManager] setSelectedFont:[self customValue] isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:nil];
}

/*!
 * @brief Update the font panel when we regain key
 */
- (BOOL)becomeFirstResponder 
{
	[[NSFontManager sharedFontManager] setSelectedFont:[self customValue] isMultiple:NO];
	
	return YES;
}

/*!
 * @brief Invoked when a new custom font is picked
 */
- (void)customFontChanged:(id)sender
{
	NSFont	*newFont = [[[self  customValue] copy] autorelease];
	
	[self setCustomValue:[sender convertFont:newFont]];
}

/*!
 * @brief Updates a menu image for the value
 */
- (void)updateMenuItem:(NSMenuItem *)menuItem forValue:(id)inValue
{
	NSFont	*font = [[NSFontManager sharedFontManager] convertFont:inValue toSize:[NSFont systemFontSize]];
	
	if(font){
		NSDictionary		*attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
		NSAttributedString	*sample = [[NSAttributedString alloc] initWithString:[menuItem title]
																	  attributes:attributes];
		
		[menuItem setAttributedTitle:sample];
		[sample release];
	}

 //   NSImage	*image;
//    NSRect	imageRect;
//    
//    //Create the sample image
//    imageRect = NSMakeRect(0, 0, FONT_SAMPLE_WIDTH, FONT_SAMPLE_HEIGHT);
//    image = [[[NSImage alloc] initWithSize:imageRect.size] autorelease];
//	
//    [image lockFocus];
//	
//	
//	NSDictionary		*attributes = [NSDictionary dictionaryWithObjectsAndKeys:
//		font, NSFontAttributeName,
//		//		[NSParagraphStyle styleWithAlignment:NSCenterTextAlignment], NSParagraphStyleAttributeName,
//		nil];
//	NSAttributedString	*sample = [[NSAttributedString alloc] initWithString:@"Font" attributes:attributes];
//	NSSize				size = [sample size];
//	
//	[sample drawAtPoint:NSMakePoint(imageRect.origin.x + (imageRect.size.width - size.width) / 2.0,
//									imageRect.origin.y + (imageRect.size.height - size.height) / 2.0)];
//	
////    [inValue set];
////   [NSBezierPath fillRect:imageRect];
//    [[NSColor grayColor] set];
//    [NSBezierPath strokeRect:imageRect];
//    [image unlockFocus];
//	
//	[menuItem setImage:image];
	
}

@end

