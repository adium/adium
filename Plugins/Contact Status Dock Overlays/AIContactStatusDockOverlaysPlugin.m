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

#import "AIContactStatusDockOverlaysPlugin.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import "AIDockController.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIIconState.h>

#define SMALLESTRADIUS				15
#define RADIUSRANGE					36
#define SMALLESTFONTSIZE			14
#define FONTSIZERANGE				30

#define	DOCK_OVERLAY_ALERT_SHORT	AILocalizedString(@"Display name in the dock icon",nil)
#define DOCK_OVERLAY_ALERT_LONG		DOCK_OVERLAY_ALERT_SHORT

@interface AIContactStatusDockOverlaysPlugin ()
- (void)_setOverlay;
- (NSImage *)overlayImageFlash:(BOOL)flash;
- (void)flushPreferenceColorCache;
- (void)chatClosed:(NSNotification *)notification;
- (void)removeDockOverlay:(NSTimer *)removeTimer;
@end

@implementation AIContactStatusDockOverlaysPlugin

/*!
* @brief Install
 */
- (void)installPlugin
{
	overlayObjectsArray = [[NSMutableArray alloc] init];
    overlayState = nil;

    //Register as a contact observer (For signed on / signed off)
    [[AIContactObserverManager sharedManager] registerListObjectObserver:self];
	
	//Register as a chat observer (for unviewed content)
	[adium.chatController registerChatObserver:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(chatClosed:)
									   name:Chat_WillClose
									 object:nil];
	
    //Prefs
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	
    //
    image1 = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
    image2 = [[NSImage alloc] initWithSize:NSMakeSize(128,128)];
	
	//Install our contact alert
	[adium.contactAlertsController registerActionID:DOCK_OVERLAY_ALERT_IDENTIFIER withHandler:self];
}

- (void)uninstallPlugin
{
	[[AIContactObserverManager sharedManager] unregisterListObjectObserver:self];
	[adium.chatController unregisterChatObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[adium.preferenceController unregisterPreferenceObserver:self];
}

/*!
* @brief Short description
 * @result A short localized description of the action
 */
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return DOCK_OVERLAY_ALERT_SHORT;
}

/*!
* @brief Long description
 * @result A longer localized description of the action which should take into account the details dictionary as appropraite.
 */
- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return DOCK_OVERLAY_ALERT_LONG;
}

/*!
* @brief Image
 */
- (NSImage *)imageForActionID:(NSString *)actionID
{
	//XXX
	return [NSImage imageNamed:@"DockAlert" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIModularPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return nil;
}

/*!
* @brief Perform an action
 *
 * @param actionID The ID of the action to perform
 * @param listObject The listObject associated with the event triggering the action. It may be nil
 * @param details If set by the details pane when the action was created, the details dictionary for this particular action
 * @param eventID The eventID which triggered this action
 * @param userInfo Additional information associated with the event; userInfo's type will vary with the actionID.
 */
- (BOOL)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	BOOL isMessageEvent = [adium.contactAlertsController isMessageEvent:eventID];
	
	if (isMessageEvent) {
		AIChat	*chat;

		if ((chat = [userInfo objectForKey:@"AIChat"]) &&
		   (chat != adium.interfaceController.activeChat) &&
		   (![overlayObjectsArray containsObjectIdenticalTo:chat])) {
			[overlayObjectsArray addObject:chat];
			
			//Wait until the next run loop so this event is done processing (and our unviewed content count is right)
			[self performSelector:@selector(_setOverlay)
					   withObject:nil
					   afterDelay:0];

			/* The chat observer method is responsible for removing this overlay later */
		}

	} else if (listObject) {
		NSTimer	*removeTimer;
		
		//Clear any current timer for this object o ahve its overlay removed
		if ((removeTimer = [listObject valueForProperty:@"DockOverlayRemoveTimer"])) [removeTimer invalidate];
		
		//Add a timer to remove this overlay
		removeTimer = [NSTimer scheduledTimerWithTimeInterval:5
													   target:self
													 selector:@selector(removeDockOverlay:)
													 userInfo:listObject
													  repeats:NO];
		[listObject setValue:removeTimer
							 forProperty:@"DockOverlayRemoveTimer"
							 notify:NotifyNever];

		if (![overlayObjectsArray containsObject:listObject]) {
			[overlayObjectsArray addObject:listObject];
		}

		//Wait until the next run loop so this event is done processing
		[self performSelector:@selector(_setOverlay)
				   withObject:nil
				   afterDelay:0];
	}
	
	return YES;
}

- (void)removeDockOverlay:(NSTimer *)removeTimer
{
	AIListObject	*inObject = [removeTimer userInfo];

	[overlayObjectsArray removeObjectIdenticalTo:inObject];
	
	[inObject setValue:nil
					   forProperty:@"DockOverlayRemoveTimer"
					   notify:NotifyNever];
	
	[self _setOverlay];
}

- (void)chatClosed:(NSNotification *)notification
{
	AIChat	*chat = [notification object];
	
	[overlayObjectsArray removeObjectIdenticalTo:chat];
	
	[self _setOverlay];
}

/*!
* @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 *
 * Don't allow multiple dock actions to occur.  While a series of "Bounce every 5 seconds," "Bounce every 10 seconds,"
 * and so on actions could be combined sanely, a series of "Bounce once" would make the dock go crazy.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{	
	if ([group isEqualToString:PREF_GROUP_LIST_THEME]) {
		//Grab colors from status coloring plugin's prefs    
		[self flushPreferenceColorCache];
		signedOffColor = [[[prefDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor] retain];
		signedOnColor = [[[prefDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor] retain];
		unviewedContentColor = [[[prefDict objectForKey:KEY_UNVIEWED_COLOR] representedColor] retain];
		
		backSignedOffColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor] retain];
		backSignedOnColor = [[[prefDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor] retain];
		backUnviewedContentColor = [[[prefDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor] retain];

	} else if ([group isEqualToString:PREF_GROUP_APPEARANCE]) {
		if (!key || [key isEqualToString:KEY_ANIMATE_DOCK_ICON]) {
			BOOL newShouldAnimate = [[prefDict objectForKey:KEY_ANIMATE_DOCK_ICON] boolValue];
			if (newShouldAnimate != shouldAnimate) {
				shouldAnimate = newShouldAnimate;

				//Redo our overlay to respect our new preference
				if (!firstTime) [self _setOverlay];
			}
		}
	}
}


- (void)flushPreferenceColorCache
{
	[signedOffColor release]; signedOffColor = nil;
	[signedOnColor release]; signedOnColor = nil;
	[unviewedContentColor release]; unviewedContentColor = nil;
	[backSignedOffColor release]; backSignedOffColor = nil;
	[backSignedOnColor release]; backSignedOnColor = nil;
	[backUnviewedContentColor release]; backUnviewedContentColor = nil;	
}

- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		//When an account signs on or off, force an overlay update as it may have silently changed
		//contacts' statuses
		if ([inModifiedKeys containsObject:@"isOnline"]) {
			BOOL			madeChanges = NO;
			
			for (AIListObject *listObject in [[overlayObjectsArray copy] autorelease]) {
				if (([listObject respondsToSelector:@selector(account)]) &&
				   ([(id)listObject account] == inObject) &&
				   ([overlayObjectsArray containsObjectIdenticalTo:listObject])) {
					[overlayObjectsArray removeObject:listObject];
					madeChanges = YES;
				}
			}
			
			if (madeChanges) [self _setOverlay];
		}
	}
	
	return nil;
}

/*!
 * @brief When a chat no longer has unviewed content, remove it from display
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
		
		if (![inChat unviewedContentCount]) {
			if ([overlayObjectsArray containsObjectIdenticalTo:inChat]) {
				[overlayObjectsArray removeObjectIdenticalTo:inChat];
				[self _setOverlay];
			}
		}
	}
	
	return nil;
}

- (void)_setOverlay
{
    //Remove & release the current overlay state
    if (overlayState) {
        [adium.dockController removeIconStateNamed:@"ContactStatusOverlay"];
        [overlayState release]; overlayState = nil;
    }

    //Create & set the new overlay state
    if ([overlayObjectsArray count] != 0) {
        //Set the state
		if (shouldAnimate) {
			overlayState = [[AIIconState alloc] initWithImages:[NSArray arrayWithObjects:[self overlayImageFlash:NO], [self overlayImageFlash:YES], nil]
														 delay:0.5f
												       looping:YES 
													   overlay:YES];
		} else {
			overlayState = [[AIIconState alloc] initWithImage:[self overlayImageFlash:NO]
													  overlay:YES];
		}

        [adium.dockController setIconState:overlayState named:@"ContactStatusOverlay"];
    }   
}

- (NSImage *)overlayImageFlash:(BOOL)flash
{
    NSEnumerator		*enumerator;
    ESObjectWithProperties  *object;
    NSFont				*font;
    NSParagraphStyle	*paragraphStyle;
    CGFloat				dockIconScale;
    CGFloat					iconHeight;
    CGFloat				top, bottom;
    NSImage				*image = (flash ? image1 : image2);
	
    //Pre-calc some sizes
    dockIconScale = 1- [adium.dockController dockIconScale];
    iconHeight = (SMALLESTRADIUS + (RADIUSRANGE * dockIconScale));

	top = 126;
	bottom = top - iconHeight;

    //Set up the string details
    font = [NSFont boldSystemFontOfSize:(SMALLESTFONTSIZE + (FONTSIZERANGE * dockIconScale))];
    paragraphStyle = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment lineBreakMode:NSLineBreakByClipping];
	
    //Clear our image
    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFillUsingOperation(NSMakeRect(0, 0, 128, 128), NSCompositeCopy);
	
    //Draw overlays for each contact
    enumerator = [overlayObjectsArray reverseObjectEnumerator];
    while ((object = [enumerator nextObject]) && !(top < 0) && bottom < 128) {
        CGFloat			left, right, arcRadius, stringInset;
        NSBezierPath	*path;
        NSColor			*backColor = nil, *textColor = nil, *borderColor = nil;
		
        //Create the pill frame
        arcRadius = (iconHeight / 2.0f);
        stringInset = (iconHeight / 4.0f);
        left = 1 + arcRadius;
        right = 127 - arcRadius;
		
        path = [NSBezierPath bezierPath];
        [path setLineWidth:((iconHeight/2.0f) * 0.13333f)];
        //Top
        [path moveToPoint: NSMakePoint(left, top)];
        [path lineToPoint: NSMakePoint(right, top)];
		
        //Right rounded cap
        [path appendBezierPathWithArcWithCenter:NSMakePoint(right, top - arcRadius) 
										 radius:arcRadius
									 startAngle:90
									   endAngle:0
									  clockwise:YES];
        [path lineToPoint: NSMakePoint(right + arcRadius, bottom + arcRadius)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(right, bottom + arcRadius) 
										 radius:arcRadius
									 startAngle:0
									   endAngle:270
									  clockwise:YES];
		
        //Bottom
        [path moveToPoint: NSMakePoint(right, bottom)];
        [path lineToPoint: NSMakePoint(left, bottom)];
		
        //Left rounded cap
        [path appendBezierPathWithArcWithCenter:NSMakePoint(left, bottom + arcRadius)
										 radius:arcRadius
									 startAngle:270
									   endAngle:180
									  clockwise:YES];
        [path lineToPoint: NSMakePoint(left - arcRadius, top - arcRadius)];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(left, top - arcRadius) radius:arcRadius startAngle:180 endAngle:90 clockwise:YES];

        if ([object integerValueForProperty:KEY_UNVIEWED_CONTENT]) { //Unviewed
			if (flash) {
                backColor = [NSColor whiteColor];
                textColor = [NSColor blackColor];
            } else {
                backColor = backUnviewedContentColor;
                textColor = unviewedContentColor;
            }
        } else if ([object boolValueForProperty:@"signedOn"]) { //Signed on
            backColor = backSignedOnColor;
            textColor = signedOnColor;
			
        } else if ([object boolValueForProperty:@"signedOff"]) { //Signed off
            backColor = backSignedOffColor;
            textColor = signedOffColor;
			
        }
		
		if (!backColor) {
			backColor = [NSColor whiteColor];
		}
		if (!textColor) {
			textColor = [NSColor blackColor];
		}
		
        //Lighten/Darken the back color slightly
        if ([backColor colorIsDark]) {
            backColor = [backColor darkenBy:-0.15f];
            borderColor = [backColor darkenBy:-0.3f];
        } else {
            backColor = [backColor darkenBy:0.15f];
            borderColor = [backColor darkenBy:0.3f];
        }
		
        //Draw
        [backColor set];
        [path fill];
        [borderColor set];
        [path stroke];
		
        //Get the object's display name
        [object.displayName drawInRect:NSMakeRect(0 + stringInset, bottom + 1, 128 - (stringInset * 2), top - bottom)
                           withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]];
		/*        
			nameString = [[[NSAttributedString alloc] initWithString:contact.displayName attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]] autorelease];
        [nameString drawInRect:NSMakeRect(0 + stringInset, bottom + 1, 128 - (stringInset * 2), top - bottom)];*/
		
        //Move down to the next pill
		top -= (iconHeight + 7.0f * dockIconScale);
		bottom = top - iconHeight;
    }
	
    [image unlockFocus];
    
    return image;
}

@end
