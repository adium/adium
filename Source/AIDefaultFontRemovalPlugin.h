//
//  AIDefaultFontRemoval.h
//  Adium
//
//  Created by Zachary West on 2009-10-28.
//  Copyright 2009  . All rights reserved.
//

#import <Adium/AIContentControllerProtocol.h>

/*!
 * @class AIDefaultFontRemoval
 *
 * This class removes the default (as in, shipping with Adium) font attributes
 * for a given outgoing message. This restores a "plaintext" default for messages.
 *
 * The basic effect is that Helvetica sized 12 (set in FormattingDefaults.plist) is
 * stripped from outgoing messages, along with any background coloring if no foreground 
 * is specified.
 */
@interface AIDefaultFontRemovalPlugin : AIPlugin <AIContentFilter> {
	NSDictionary *defaultRemovedAttributes;
}

@end
