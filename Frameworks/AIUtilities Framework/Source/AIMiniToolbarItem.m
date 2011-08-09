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

#import "AIMiniToolbarItem.h"
#import "AIMiniToolbarButton.h"

@protocol NSVIEW_SETENABLED //Used to prevent a warning below
- (void)setEnabled:(BOOL)flag;
@end

@implementation AIMiniToolbarItem

//Init
- (id)initWithIdentifier:(NSString *)inIdentifier
{
	if((self = [super init])) {
		identifier = [inIdentifier retain];
		paletteLabel = nil;
		allowsDuplicatesInToolbar = NO;
		flexibleWidth = NO;
	}
	return self;
}

- (void)dealloc
{
    [identifier release];
    [paletteLabel release];
    [toolTip release];
    [target release];
    [image release];
    [view release];
    [delegate release];
    [objects release];

    [super dealloc];
}

//Duplicate this object
- (id)copyWithZone:(NSZone *)zone
{
    AIMiniToolbarItem	*newItem;

    newItem = [[AIMiniToolbarItem alloc] initWithIdentifier:[self identifier]];    
    //Properties
    [newItem setPaletteLabel:[self paletteLabel]];
    [newItem setToolTip:[self toolTip]];
    [newItem setEnabled:[self isEnabled]];
    [newItem setAllowsDuplicatesInToolbar:[self allowsDuplicatesInToolbar]];
    [newItem setFlexibleWidth:[self flexibleWidth]];
    //Action
    [newItem setTarget:[self target]];
    [newItem setAction:[self action]];
    [newItem setDelegate:[self delegate]];
    //View
    [newItem setView:[[[self view] copy] autorelease]];
    if([[newItem view] respondsToSelector:@selector(setToolbarItem:)]){
        [[newItem view] performSelector:@selector(setToolbarItem:) withObject:newItem]; //make sure it's setup to the new toolbar item
    }
    
    [newItem configureForObjects:[self configurationObjects]];

    return newItem;
}

//Toolbar item identifier
- (NSString *)identifier{
    return identifier;
}

//Palette Label, displayed by the item on the customization palette
- (void)setPaletteLabel:(NSString *)inPaletteLabel{
    if(paletteLabel != inPaletteLabel){
        [paletteLabel release];
        paletteLabel = [inPaletteLabel retain];
    }
}
- (NSString *)paletteLabel{
    return paletteLabel;
}


//Tooltip displayed for the item
- (void)setToolTip:(NSString *)inToolTip{
    if(toolTip != inToolTip){
        [toolTip release];
        toolTip = [inToolTip retain];
        
        if(view && [view respondsToSelector:@selector(setToolTip:)]){
            [view setToolTip:toolTip];
        }
    }
}
- (NSString *)toolTip{
    return toolTip;
}


//Set and get the action of an item
- (void)setTarget:(id)inTarget
{
    if(target != inTarget){
        [target release]; target = [inTarget retain];
    }
}
- (id)target{
    return target;
}

- (void)setAction:(SEL)inAction
{
    action = inAction;
}
- (SEL)action{
    return action;
}


//Enable/Disable the item
- (void)setEnabled:(BOOL)inEnabled{
    enabled = inEnabled;
    if(view && [view respondsToSelector:@selector(setEnabled:)]){
        [(NSView<NSVIEW_SETENABLED> *)view setEnabled:enabled];
    }
}
- (BOOL)isEnabled{
    return enabled;
}


//Set the item's image
- (void)setImage:(NSImage *)inImage{
    if(image != inImage){
        [image release];
        image = [inImage retain];

        if(view && [view respondsToSelector:@selector(setImage:)]){
            [view performSelector:@selector(setImage:) withObject:image];
        }
    }
}
- (NSImage *)image{
    return image;
}


//Control whether this item can appear more than once in a toolbar
- (void)setAllowsDuplicatesInToolbar:(BOOL)inValue{
    allowsDuplicatesInToolbar = inValue;
}
- (BOOL)allowsDuplicatesInToolbar{
    return allowsDuplicatesInToolbar;
}


//Access the view for this item
- (void)setView:(NSView *)inView{
    if(view == nil){
        view = [inView retain];
    }
}
- (NSView *)view{
    if(view == nil){ //Basic button
        view = [[AIMiniToolbarButton miniToolbarButtonWithImage:image] retain];
        [(AIMiniToolbarButton *)view setToolbarItem:self];
        [(AIMiniToolbarButton *)view setToolTip:toolTip];
        [(AIMiniToolbarButton *)view setEnabled:enabled];
    }

    return view;
}


//Get and set the delegate of this toolbar item
- (void)setDelegate:(NSObject<AIMiniToolbarItemDelegate> *)inDelegate{
    if(delegate != inDelegate){
        NSParameterAssert([inDelegate conformsToProtocol:@protocol(AIMiniToolbarItemDelegate)]);

        [delegate release];
        delegate = [inDelegate retain];
    }
}
- (NSObject<AIMiniToolbarItemDelegate> *)delegate{
    return delegate;
}


//Configure this item
- (BOOL)configureForObjects:(NSDictionary *)inObjects{
    //Retain the configuration objects
    if(objects != inObjects){
        [objects release]; objects = [inObjects retain];
    }

    //Inform our delegate so it can configure this item
    if(delegate){
        return [delegate configureToolbarItem:self forObjects:inObjects];
    }else{
        return YES;
    }
}
- (NSDictionary *)configurationObjects{
    return objects;
}


//Flexible
- (void)setFlexibleWidth:(BOOL)inflexibleWidth{
    flexibleWidth = inflexibleWidth;
}
- (BOOL)flexibleWidth{
    return flexibleWidth;
}


@end





