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

#import <Adium/AIStatusItem.h>
#import <Adium/AIStatusGroup.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>

/*!
 * @class AIStatusItem
 * @brief Abstract superclass for statuses and status groups
 */
@implementation AIStatusItem

/*!
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		statusDict = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

/*!
* @brief Copy
 */
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)mutableCopy
{
	AIStatusItem *miniMe = [[[self class] alloc] init];
	
	miniMe->statusDict = [statusDict mutableCopy];
	
	//Clear the unique ID for this new status, since it should not share our ID.
	[miniMe->statusDict removeObjectForKey:STATUS_UNIQUE_ID];
	
	return miniMe;
}

/*!
* @brief Encode with Coder
 */
- (void)encodeWithCoder:(NSCoder *)encoder
{
	encoding = YES;

	//Ensure we have a unique status ID before encoding. We set encoding = YES so it won't trigger further saving/encoding.
	[self uniqueStatusID];
	
	if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:statusDict forKey:@"AIStatusDict"];
		
    } else {
        [encoder encodeObject:statusDict];
    }
	
	encoding = NO;
}

/*!
 * @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		if ([decoder allowsKeyedCoding]) {
			// Can decode keys in any order		
			statusDict = [[decoder decodeObjectForKey:@"AIStatusDict"] mutableCopy];
			
		} else {
			// Must decode keys in same order as encodeWithCoder:		
			statusDict = [[decoder decodeObject] mutableCopy];
		}
	}
	
	return self;
}

- (NSString *)title
{	
	NSString *title = [statusDict objectForKey:STATUS_TITLE];
	
	return ([title length] ? title : nil);
}

/*!
 * @brief Set the title
 */
- (void)setTitle:(NSString *)inTitle
{
	if (inTitle) {
		[statusDict setObject:inTitle
					   forKey:STATUS_TITLE];
	} else {
		[statusDict removeObjectForKey:STATUS_TITLE];
	}
}

/*!
 * @brief The general status type
 *
 * @result An AIStatusType broadly indicating the type of state
 */
- (AIStatusType)statusType
{
	NSNumber *statusType = [statusDict objectForKey:STATUS_STATUS_TYPE];

	return (statusType ? [statusType intValue] : AIAwayStatusType);
}

/*!
* @brief Set the general status type
 *
 * @param statusType An AIStatusType broadly indicating the type of state
 */
- (void)setStatusType:(AIStatusType)statusType
{
	[statusDict setObject:[NSNumber numberWithInt:statusType]
				   forKey:STATUS_STATUS_TYPE];
}

- (AIStatusMutabilityType)mutabilityType
{
	return AIEditableStatusState;
}

/*!
* @brief Returns an appropriate icon for this state
 *
 * This method will generate an appropriate status icon based on the state's content.
 *
 * @param iconType The AIStatusIconType to use
 * @param direction The direction
 *
 * @result An <tt>NSImage</tt>
 */
- (NSImage *)iconOfType:(AIStatusIconType)iconType direction:(AIIconDirection)direction
{
	AIStatusType	statusType;
	
	statusType = self.statusType;
	
	return [AIStatusIcons statusIconForStatusName:nil
									   statusType:statusType
										 iconType:iconType
										direction:direction];
}

/*!
* @brief Returns an appropriate icon for this state
 *
 * This method will generate an appropriate status icon based on the state's content.
 *
 * @result An <tt>NSImage</tt>
 */ 
- (NSImage *)icon
{
	return [self iconOfType:AIStatusIconList direction:AIIconNormal];
}

- (NSImage *)menuIcon
{
	return [self iconOfType:AIStatusIconMenu direction:AIIconNormal];
}

#pragma mark Unique status ID

/*!
 * @brief Next available unique status ID
 *
 * Each call to this method will return a new, incremented value.
 */
- (NSNumber *)nextUniqueStatusID
{
	NSNumber	*nextUniqueStatusID;

	//Retain and autorelease since we'll be replacing this value (and therefore releasing it) via the preferenceController.
	nextUniqueStatusID = [adium.preferenceController preferenceForKey:@"TopStatusID"
																	group:PREF_GROUP_SAVED_STATUS];
	if (!nextUniqueStatusID) nextUniqueStatusID = [NSNumber numberWithInt:1];

	[adium.preferenceController setPreference:[NSNumber numberWithInt:([nextUniqueStatusID intValue] + 1)]
										 forKey:@"TopStatusID"
										  group:PREF_GROUP_SAVED_STATUS];

	return nextUniqueStatusID;
}

/*!
* @brief Return a unique ID for this status
 *
 * The unique ID will be assigned if necessary.
 */
- (NSNumber *)uniqueStatusID
{
	NSNumber	*uniqueStatusID = [statusDict objectForKey:STATUS_UNIQUE_ID];
	if (!uniqueStatusID) {
		uniqueStatusID = [self nextUniqueStatusID];
		[self setUniqueStatusID:uniqueStatusID];
	}
	
	return uniqueStatusID;
}

/*!
 * @brief Return the unique status ID for this status as an integer
 *
 * The unique ID will not be assigned if necessary. -1 is returned if no unique ID has been assigned previously.
 */
- (int)preexistingUniqueStatusID
{
	NSNumber	*uniqueStatusID = [statusDict objectForKey:STATUS_UNIQUE_ID];
	
	return uniqueStatusID ? [uniqueStatusID intValue] : -1;
}

- (void)setUniqueStatusID:(NSNumber *)inUniqueStatusID
{
	if (inUniqueStatusID) {
		[statusDict setObject:inUniqueStatusID
					   forKey:STATUS_UNIQUE_ID];		
	} else {
		[statusDict removeObjectForKey:STATUS_UNIQUE_ID];
	}
	
	/* If we're not currently encoding and we're within a status group, we need to let the status controller know so that it
	 * can save us and our contained group.
	 */
	if (!encoding && containingStatusGroup) {
		[adium.statusController statusStateDidSetUniqueStatusID];
	}
}

- (AIStatusGroup *)containingStatusGroup
{
	return containingStatusGroup;
}

- (void)setContainingStatusGroup:(AIStatusGroup *)inStatusGroup
{
	if (containingStatusGroup != inStatusGroup) {
		containingStatusGroup = inStatusGroup;
	}
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p [%@]>",
		NSStringFromClass([self class]),
		self,
		[[self title] stringWithEllipsisByTruncatingToLength:20]];
}


#pragma mark Applescript
/**
 * @brief statuses are specified by unique ID in the 'statuses' key of AIApplication
 */
- (NSScriptObjectSpecifier *)objectSpecifier
{
	NSScriptClassDescription *containerClassDesc = (NSScriptClassDescription *)[NSScriptClassDescription classDescriptionForClass:[NSApp class]];
	return [[NSUniqueIDSpecifier alloc]
			 initWithContainerClassDescription:containerClassDesc
			 containerSpecifier:nil key:@"statuses"
			 uniqueID:[self uniqueStatusID]];
}

- (AIStatusTypeApplescript)statusTypeApplescript
{
	AIStatusType			statusType = self.statusType;
	AIStatusTypeApplescript statusTypeApplescript;
	
	switch (statusType) {
		case AIAvailableStatusType: statusTypeApplescript = AIAvailableStatusTypeAS; break;
		case AIAwayStatusType: statusTypeApplescript = AIAwayStatusTypeAS; break;
		case AIInvisibleStatusType: statusTypeApplescript = AIInvisibleStatusTypeAS; break;
		case AIOfflineStatusType:
		default:
			statusTypeApplescript = AIOfflineStatusTypeAS; break;
	}
	
	return statusTypeApplescript;
}

- (void)setStatusTypeApplescript:(AIStatusTypeApplescript)statusTypeApplescript
{
	AIStatusType			statusType;
	
	switch (statusTypeApplescript) {
		case AIAvailableStatusTypeAS: statusType = AIAvailableStatusType; break;
		case AIAwayStatusTypeAS: statusType = AIAwayStatusType; break;
		case AIInvisibleStatusTypeAS: statusType = AIInvisibleStatusType; break;
		case AIOfflineStatusTypeAS:
		default:
			statusType = AIOfflineStatusType; break;
	}
	
	[self setStatusType:statusType];
}

@end
