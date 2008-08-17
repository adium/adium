//
//  AIStatusItem.h
//  Adium
//
//  Created by Evan Schoenberg on 11/23/05.
//

#import <Adium/AIStatusIcons.h>
#import <Adium/AIStatusDefines.h>

@class AIStatusGroup;

@interface AIStatusItem : NSObject <NSCoding> {
	NSMutableDictionary	*statusDict;
	AIStatusGroup		*containingStatusGroup;

	BOOL				encoding;
}

- (NSString *)title;
- (void)setTitle:(NSString *)inTitle;

- (NSImage *)menuIcon;
- (NSImage *)icon;
- (NSImage *)iconOfType:(AIStatusIconType)iconType direction:(AIIconDirection)direction;

- (AIStatusType)statusType;
- (void)setStatusType:(AIStatusType)statusType;

- (AIStatusMutabilityType)mutabilityType;

- (NSNumber *)uniqueStatusID;
- (int)preexistingUniqueStatusID;
- (void)setUniqueStatusID:(NSNumber *)inUniqueStatusID;

- (AIStatusGroup *)containingStatusGroup;
- (void)setContainingStatusGroup:(AIStatusGroup *)inStatusGroup;

#pragma mark Applescript
- (AIStatusTypeApplescript)statusTypeApplescript;
- (void)setStatusTypeApplescript:(AIStatusTypeApplescript)statusTypeApplescript;

@end
