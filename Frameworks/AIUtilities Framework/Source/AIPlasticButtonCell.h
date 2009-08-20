//
//  AIPlasticButtonCell.m
//  AIUtilities
//
//  Created by Mac-arena the Bored Zo on 2005-11-26.
//

/*!
 * @class AIPlasticButtonCell
 * @brief NSButtonCell subclass for implementing a "plastic" Aqua button
 *
 * NOTE: The current implementation is incomplete (in particular, NSCellImagePosition values other than
 * NSImageOnly and NSNoImage are quite broken). Please fix if you can.
 */
@interface AIPlasticButtonCell : NSButtonCell {
    NSImage			*plasticCaps;
    NSImage			*plasticMiddle;
    NSImage			*plasticPressedCaps;
    NSImage			*plasticPressedMiddle;
    NSImage			*plasticDefaultCaps;
    NSImage			*plasticDefaultMiddle;
}

@end
