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

#import "AIEventAdditions.h"
#import <Carbon/Carbon.h>

@implementation NSEvent (AIEventAdditions)

//There seems to be a bug in OS X which causes cocoa calls for the current modifier key to fail during application launch, so we use the carbon calls.
+ (BOOL)cmdKey{
    return (GetCurrentKeyModifiers() & cmdKey) != 0;
}

+ (BOOL)shiftKey{
    return (GetCurrentKeyModifiers() & (shiftKey | rightShiftKey)) != 0;
}

+ (BOOL)optionKey{
    return (GetCurrentKeyModifiers() & (optionKey | rightOptionKey)) != 0;
}

+ (BOOL)controlKey{
    return (GetCurrentKeyModifiers() & (controlKey | rightControlKey)) != 0;
}

- (BOOL)cmdKey{
    return ([self modifierFlags] & NSCommandKeyMask) != 0;
}

- (BOOL)shiftKey{
    return ([self modifierFlags] & NSShiftKeyMask) != 0;
}

- (BOOL)optionKey{
    return ([self modifierFlags] & NSAlternateKeyMask) != 0;
}

- (BOOL)controlKey{
    return ([self modifierFlags] & NSControlKeyMask) != 0;
}

@end
