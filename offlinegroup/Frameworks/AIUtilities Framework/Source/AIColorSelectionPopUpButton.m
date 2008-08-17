//
//  AIColorSelectionPopUpButton.m
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIColorSelectionPopUpButton.h"
#import "AIStringUtilities.h"
#import "AIMenuAdditions.h"
#import "AIColorAdditions.h"

#define COLOR_SAMPLE_WIDTH		24
#define COLOR_SAMPLE_HEIGHT		12
#define SAMPLE_FRAME_DARKEN		0.3

@interface AIColorSelectionPopUpButton (PRIVATE)
- (void)_initColorSelectionPopUpButton;
- (void)_buildColorMenu;
- (void)_setCustomColor:(NSColor *)inColor;
- (NSImage *)_sampleImageForColor:(NSColor *)inColor;
@end

@implementation AIColorSelectionPopUpButton

/*!
 * @brief Shared init code
 */
- (void)_initObjectSelectionPopUpButton
{
	[super _initObjectSelectionPopUpButton];

    //Setup our default colors
    [self setCustomValue:[NSColor blackColor]];
    [self setAvailableColors:[NSArray arrayWithObjects:@"Black",[NSColor blackColor],@"White",[NSColor whiteColor],@"Red", [NSColor redColor], @"Blue", [NSColor blueColor], @"Green", [NSColor greenColor], @"Yellow", [NSColor yellowColor], nil]];
}

- (void)setColor:(NSColor *)inColor
{
	[self setObjectValue:inColor];
}

- (NSColor *)color
{
    return [self objectValue];
}

- (void)setAvailableColors:(NSArray *)inColors
{
	[self setPresetValues:inColors];
}

/*!
 * @brief Invoked when the custom menu item is selected
 */
- (void)selectCustomValue:(id)sender
{
    [[NSColorPanel sharedColorPanel] setTarget:self];
    [[NSColorPanel sharedColorPanel] setAction:@selector(customColorChanged:)];
    [[NSColorPanel sharedColorPanel] setColor:[self customValue]];
    [[NSColorPanel sharedColorPanel] makeKeyAndOrderFront:nil];
}

/*!
 * @brief Invoked when a new custom color is picked
 */
- (void)customColorChanged:(id)sender
{
	[self setCustomValue:[[[[NSColorPanel sharedColorPanel] color] copy] autorelease]];
}

/*!
 * @brief Compare two values
 */
- (BOOL)value:(id)valueA isEqualTo:(id)valueB
{
	return [valueA equalToRGBColor:valueB];
}

/*!
 * @brief Updates a menu image for the value
 */
- (void)updateMenuItem:(NSMenuItem *)menuItem forValue:(id)inValue
{
    NSImage	*image;
    NSRect	imageRect;
    
    //Create the sample image
    imageRect = NSMakeRect(0, 0, COLOR_SAMPLE_WIDTH, COLOR_SAMPLE_HEIGHT);
    image = [[[NSImage alloc] initWithSize:imageRect.size] autorelease];
	
    [image lockFocus];
    [inValue set];
    [NSBezierPath fillRect:imageRect];
    [[inValue darkenBy:SAMPLE_FRAME_DARKEN] set];
    [NSBezierPath strokeRect:imageRect];
    [image unlockFocus];
	
	[menuItem setImage:image];
}

@end

