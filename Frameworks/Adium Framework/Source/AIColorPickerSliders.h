//
//  AIColorPickerSliders.h
//  Adium
//
//  Created by Evan Schoenberg on 9/25/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

//Private class :(
@interface NSColorPickerSliders:NSColorPicker <NSColorPickingCustom>
{
    id sliderModePopUp;
    id slidersView;
    id greySliders;
    id rgbSliders;
    id hsbSliders;
    id cmykSliders;
    id currViewObject;
    id sliderContainer;
    id colorProfileButton;
    int modeMask;
}

- (void)_setupProfileUI;

@end

@interface AIColorPickerSliders : NSColorPickerSliders {

}

@end
