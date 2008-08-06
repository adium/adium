//
//  AIObjectSelectionPopUpButton.m
//  AIUtilities.framework
//
//  Created by Adam Iser on 6/17/05.
//  Copyright 2005 the Adium Team. All rights reserved.
//

#import "AIObjectSelectionPopUpButton.h"
#import "AIStringUtilities.h"
#import "AIMenuAdditions.h"

@interface AIObjectSelectionPopUpButton (PRIVATE)
- (void)_buildMenu;
@end

/*!
 * @class AIObjectSelectionPopUpButton
 *
 * AIObjectSelectionPopUpButton is an NSPopUpButton that displays preset choices.
 */
@implementation AIObjectSelectionPopUpButton

/*!
 * @brief Init
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initObjectSelectionPopUpButton];
	}
	return self;
}
- (id)initWithFrame:(NSRect)buttonFrame pullsDown:(BOOL)flag
{
	if ((self = [super initWithFrame:buttonFrame pullsDown:flag])) {
		[self _initObjectSelectionPopUpButton];
	}
	return self;
}

/*!
 * @brief Shared init code
 */
- (void)_initObjectSelectionPopUpButton
{
    //
    availableValues = nil;
    customValue = nil;
    
    //Create the custom menu item
    customMenuItem = [[NSMenuItem alloc] initWithTitle:OBJECT_SELECTION_CUSTOM_TITLE
												target:self
												action:@selector(selectCustomValue:) 
										 keyEquivalent:@""];
}

/*!
 * @brief Dealloc
 */
- (void)dealloc
{
    [availableValues release]; availableValues = nil;
    [customValue release]; customValue = nil;
    [customMenuItem release]; customMenuItem = nil;
    
    [super dealloc];
}

/*!
 * @brief Set the currently displayed value
 * 
 * If a preset exists for the value, it will be selected.  Otherwise, the custom option will be changed to this value
 * and selected
 * @param inValue value to make active
 */
- (void)setObjectValue:(id)inValue
{
    NSEnumerator	*enumerator;
    NSString		*label;

    //search for a preset
    enumerator = [availableValues objectEnumerator];
    while ((label = [enumerator nextObject])) {
        if ([self value:[enumerator nextObject] isEqualTo:inValue]) break;
    }

    //Select
    if (label) {
        [self selectItemWithTitle:label];
    } else {
        [self setCustomValue:inValue];
        [self selectItem:customMenuItem];
    }
}

/*!
 * @brief Returns the currently displayed value
 */
- (id)objectValue
{
    return [[self selectedItem] representedObject];
}

/*!
 * @brief Set the pre-set choices
 *
 * @param inValues NSArray or value presets as alternating NSString label, id value pairs
 */
- (void)setPresetValues:(NSArray *)inValues
{
    if (inValues != availableValues) {
        [availableValues release];
        availableValues = [inValues retain];

        [self _buildMenu];
    }
}

/*!
 * @brief Set the current custom value
 */
- (void)setCustomValue:(id)inValue
{
    if (customValue != inValue) {
        [customValue release]; customValue = [inValue retain];
        [customMenuItem setRepresentedObject:customValue];
		[self updateMenuItem:customMenuItem forValue:customValue];

		if([self selectedItem] == customMenuItem){
			[[self target] performSelector:[self action] withObject:self];
		}
	}
}

/*!
 * @brief Returns the current custom value
 */
- (id)customValue
{
	return customValue;
}

/*!
 * @brief Build the pre-set menu
 */
- (void)_buildMenu
{
    NSMenuItem		*menuItem;
    NSEnumerator	*enumerator;
    NSString		*label;
	id				value;
	
    //Empty our menu
    if (![self menu]) {
        [self setMenu:[[[NSMenu alloc] init] autorelease]]; //Make sure we have a menu
    }
    [self removeAllItems];
    
    //Values
    enumerator = [availableValues objectEnumerator];
    while ((label = [enumerator nextObject])) {
        value = [enumerator nextObject];
		
        //Create the menu item
        menuItem = [[[NSMenuItem alloc] initWithTitle:label target:nil action:nil keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:value];
		[self updateMenuItem:menuItem forValue:value];
		[[self menu] addItem:menuItem];
    }
	
    //Custom
    [[self menu] addItem:[NSMenuItem separatorItem]];
    [[self menu] addItem:customMenuItem];
	[self updateMenuItem:customMenuItem forValue:customValue];
}

//For subclasses
#pragma mark For subclasses
/*!
 * @brief Invoked when the custom menu item is selected
 */
- (void)selectCustomValue:(id)sender
{
	//Subclass
}

/*!
 * @brief Compare two values
 */
- (BOOL)value:(id)valueA isEqualTo:(id)valueB
{
	return [valueA isEqualTo:valueB];
}

/*!
 * @brief Updates a menu image for the value
 */
- (void)updateMenuItem:(NSMenuItem *)menuItem forValue:(id)inValue
{
	//Subclass
}

@end

