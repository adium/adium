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

#import <Adium/AIContactObserverManager.h>
#import <Adium/AIInterfaceControllerProtocol.h>

@interface AIContactStatusColoringPlugin : AIPlugin <AIListObjectObserver, AIFlashObserver> {
    NSMutableSet	*flashingListObjects;

    BOOL		awayEnabled;
    BOOL		idleEnabled;
    BOOL		signedOffEnabled;
    BOOL		signedOnEnabled;
    BOOL		typingEnabled;
    BOOL		unviewedContentEnabled;
    BOOL		onlineEnabled;
    BOOL		awayAndIdleEnabled;
	BOOL		offlineEnabled;
    BOOL		mobileEnabled;

	BOOL		flashUnviewedContentEnabled;

    NSColor		*awayColor;
    NSColor		*idleColor;
    NSColor		*signedOffColor;
    NSColor		*signedOnColor;
    NSColor		*typingColor;
    NSColor		*unviewedContentColor;
    NSColor		*onlineColor;
    NSColor		*awayAndIdleColor;
	NSColor		*offlineColor;
	NSColor		*mobileColor;
    
    NSColor		*awayInvertedColor;
    NSColor		*idleInvertedColor;
    NSColor		*signedOffInvertedColor;
    NSColor		*signedOnInvertedColor;
    NSColor		*typingInvertedColor;
    NSColor		*unviewedContentInvertedColor;
    NSColor		*onlineInvertedColor;
    NSColor		*awayAndIdleInvertedColor;
	NSColor		*offlineInvertedColor;
	NSColor		*mobileInvertedColor;
	
    NSColor		*awayLabelColor;
    NSColor		*idleLabelColor;
    NSColor		*signedOffLabelColor;
    NSColor		*signedOnLabelColor;
    NSColor		*typingLabelColor;
    NSColor		*unviewedContentLabelColor;
    NSColor		*onlineLabelColor;
    NSColor		*awayAndIdleLabelColor;
	NSColor		*offlineLabelColor;
	NSColor		*mobileLabelColor;

	BOOL		offlineImageFading;
	
	NSSet		*interestedKeysSet;
}

@end
