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
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>

#define PREF_GROUP_DOCK_OVERLAYS		@"Dock Overlays"
#define DOCK_OVERLAY_DEFAULT_PREFS		@"DockOverlayDefaults"

#define	KEY_DOCK_SHOW_STATUS			@"Show status overlays"
#define	KEY_DOCK_SHOW_CONTENT			@"Show content overlays"
#define	KEY_DOCK_OVERLAY_POSITION		@"Overlay Position"

#define DOCK_OVERLAY_ALERT_IDENTIFIER		@"DockOverlay"

@class AIIconState;

@interface AIContactStatusDockOverlaysPlugin : AIPlugin <AIListObjectObserver, AIChatObserver, AIActionHandler> {
    NSMutableArray				*overlayObjectsArray;
    AIIconState					*overlayState;

    NSColor	*signedOffColor;
    NSColor	*signedOnColor;
    NSColor	*unviewedContentColor;

    NSColor	*backSignedOffColor;
    NSColor	*backSignedOnColor;
    NSColor	*backUnviewedContentColor;

    BOOL	showStatus;
    BOOL	showContent;
    BOOL	overlayPosition;
	BOOL	shouldAnimate;

    NSImage	*image1;
    NSImage	*image2;
}

@end
