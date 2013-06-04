#import "AIDockNameOverlay.h"
#import "AIDockController.h"
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <Adium/AIChat.h>
#import <Adium/AIAccount.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <Adium/AIAbstractListController.h>
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIBezierPathAdditions.h>


#define DOCK_OVERLAY_ALERT_SHORT	AILocalizedString(@"Display name in the dock icon",nil)
#define DOCK_OVERLAY_ALERT_LONG		DOCK_OVERLAY_ALERT_SHORT

@interface AIDockNameOverlay ()
- (void)flushPreferenceColorCache;
- (void)drawOverlay;
- (void)removeDockOverlay:(NSTimer *)removeTimer;
@end

@implementation AIDockNameOverlay
- (void)installPlugin
{
	//Install our contact alert
	[adium.contactAlertsController registerActionID:DOCK_OVERLAY_ALERT_IDENTIFIER withHandler:self];

	overlayObjectsArray = [[NSMutableArray alloc] init];
	
	//Register as a contact observer (For signed on / signed off)
	[[AIContactObserverManager sharedManager] registerListObjectObserver:self];
	
	[adium.chatController registerChatObserver:self];
	
	//Observe pref changes
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_APPEARANCE];
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_LIST_THEME];
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

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
	[adium.chatController unregisterChatObserver:self];
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
	return [NSImage imageNamed:@"events-dock-name" forClass:[self class]];
}

/*!
 * @brief Details pane
 * @result An <tt>AIActionDetailsPane</tt> to use for configuring this action, or nil if no configuration is possible.
 */
- (AIActionDetailsPane *)detailsPaneForActionID:(NSString *)actionID
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
		AIChat *chat;
		
		if ((chat = [userInfo objectForKey:@"AIChat"]) &&
			(chat != adium.interfaceController.activeChat)) {
			if (![overlayObjectsArray containsObjectIdenticalTo:chat])
				[overlayObjectsArray addObject:chat];
			
			//Wait until the next run loop so that this event is done processing and our unviewed content count is correct
			[self performSelector:@selector(drawOverlay)
					   withObject:nil
					   afterDelay:0];
		}
		
	} else if (listObject) {
		NSTimer *removeTimer;
		
		//Clear any current timer for this object to have its overlay removed
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
		
		if (![overlayObjectsArray containsObjectIdenticalTo:listObject])
			[overlayObjectsArray addObject:listObject];
		
		[self drawOverlay];
	}
	
	return YES;
}

/*!
 * @brief Allow multiple actions?
 *
 * If this method returns YES, every one of this action associated with the triggering event will be executed.
 * If this method returns NO, only the first will be.
 */
- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

/*!
 * @brief When a chat no longer has unviewed content remove it from display
 */
- (NSSet *)updateChat:(AIChat *)inChat keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if (inModifiedKeys == nil || [inModifiedKeys containsObject:KEY_UNVIEWED_CONTENT]) {
		if (![inChat unviewedContentCount]) {
			[overlayObjectsArray removeObjectIdenticalTo:inChat];
			[self drawOverlay];
		}
	}
	
	return nil;
}

/*!
 * @brief When an account signs on or off force an overlay update as its contacts statuses may have silently changed
 */
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent
{
	if ([inObject isKindOfClass:[AIAccount class]]) {
		if ([inModifiedKeys containsObject:@"isOnline"]) {
			BOOL madeChanges = NO;
			
			for (AIListObject *listObject in [[overlayObjectsArray copy] autorelease]) {
				if (([listObject respondsToSelector:@selector(account)]) &&
					([(id)listObject account] == inObject) &&
					([overlayObjectsArray containsObjectIdenticalTo:listObject])) {
					[overlayObjectsArray removeObjectIdenticalTo:listObject];
					madeChanges = YES;
				}
			}
			
			if (madeChanges) [self drawOverlay];
		}
	}
	
	return nil;
}

- (void)removeDockOverlay:(NSTimer *)removeTimer
{
	AIListObject *inObject = [removeTimer userInfo];
	[overlayObjectsArray removeObjectIdenticalTo:inObject];
	
	[inObject setValue:nil
		   forProperty:@"DockOverlayRemoveTimer"
				notify:NotifyNever];
	
	[self drawOverlay];
}

- (void)drawOverlay
{
	NSFont				*font;
	NSParagraphStyle	*paragraphStyle;
	CGFloat				iconHeight;
	CGFloat				top, bottom;
	NSImage				*image = [[NSImage alloc] initWithSize:NSMakeSize(128, 128)];
	
	iconHeight = 30.0f;
	bottom = 2;
	top = bottom + iconHeight;
	
	//Set up the string details
	font = [NSFont boldSystemFontOfSize:24.0f];
	paragraphStyle = [NSParagraphStyle styleWithAlignment:NSCenterTextAlignment lineBreakMode:NSLineBreakByClipping];
	
	[image lockFocus];
	
	//Clear our image
	[[NSColor clearColor] set];
	NSRectFillUsingOperation(NSMakeRect(0, 0, 128, 128), NSCompositeCopy);
	
	//Draw overlays for each contact
	for (ESObjectWithProperties *object in [overlayObjectsArray reverseObjectEnumerator]) {
		if (top >= 128)
			break;
		
		CGFloat			arcRadius, stringInset;
		NSBezierPath	*path;
		NSRect			pillRect;
		NSColor			*backColor = nil, *textColor = nil, *borderColor = nil;
		
		//Create the pill frame
		arcRadius = (iconHeight / 2.0f);
		stringInset = (iconHeight / 4.0f);
		pillRect = NSMakeRect(0, bottom, 127, iconHeight);
		
		path = [NSBezierPath bezierPathWithRoundedRect:pillRect radius:arcRadius];
		[path setLineWidth:((iconHeight/2.0f) * 0.13333f)];
		
		if ([object integerValueForProperty:KEY_UNVIEWED_CONTENT]) { //Unviewed
			backColor = backUnviewedContentColor;
			textColor = unviewedContentColor;
		} else if ([object boolValueForProperty:@"signedOn"]) { //Signed on
			backColor = backSignedOnColor;
			textColor = signedOnColor;
		} else if ([object boolValueForProperty:@"signedOff"]) { //Signed off
			backColor = backSignedOffColor;
			textColor = signedOffColor;
		}
		
		if (!backColor)
			backColor = [NSColor whiteColor];
		if (!textColor)
			textColor = [NSColor blackColor];
		
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
		[object.displayName drawInRect:NSMakeRect(stringInset + 1, bottom - 1, 127 - (stringInset * 2), top - bottom)
						withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, textColor, NSForegroundColorAttributeName, nil]];
		
		//Move up to the next pill
		bottom = top + 3.0f;
		top = bottom + iconHeight;
	}
	
	[image unlockFocus];
	
	[adium.dockController setOverlay:image];
	[image release];
}

@end
