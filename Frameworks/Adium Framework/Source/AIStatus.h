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

//Keys used for storage and retrieval
#define	STATUS_STATUS_MESSAGE				@"Status Message NSAttributedString"
#define	STATUS_HAS_AUTO_REPLY				@"Has AutoReply"
#define	STATUS_AUTO_REPLY_IS_STATUS_MESSAGE	@"AutoReply is Status Message"
#define	STATUS_AUTO_REPLY_MESSAGE			@"AutoReply Message NSAttributedString"
#define	STATUS_STATUS_NAME					@"Status Name"
#define STATUS_SHOULD_FORCE_INITIAL_IDLE_TIME @"Should Force Initial Idle Time"
#define	STATUS_FORCED_INITIAL_IDLE_TIME		@"Forced Initial Idle Time"
#define STATUS_INVISIBLE					@"Invisible"
#define STATUS_MUTABILITY_TYPE				@"Mutability Type"
#define STATUS_MUTE_SOUNDS					@"Mute Sounds"
#define STATUS_SILENCE_GROWL				@"Silence Growl"
#define STATUS_SPECIAL_TYPE					@"Special Type"

typedef enum {
	AINoSpecialStatusType = 0,
	AINowPlayingSpecialStatusType
} AISpecialStatusType; 

@interface AIStatus : AIStatusItem {
	NSString *filteredStatusMessage;
}

+ (AIStatus *)status;
+ (AIStatus *)statusWithDictionary:(NSDictionary *)inDictionary;
+ (AIStatus *)statusOfType:(AIStatusType)inStatusType;

- (NSAttributedString *)statusMessage;
- (void)setStatusMessage:(NSAttributedString *)statusMessage;

- (NSString *)statusMessageString;
- (void)setStatusMessageString:(NSString *)statusMessageString;

- (void)setFilteredStatusMessage:(NSString *)inFilteredStatusMessage;
- (NSString *)statusMessageTooltipString;

- (NSAttributedString *)autoReply;
- (void)setAutoReply:(NSAttributedString *)autoReply;
- (void)setAutoReplyString:(NSString *)autoReplyString;

- (BOOL)hasAutoReply;
- (void)setHasAutoReply:(BOOL)hasAutoReply;
- (BOOL)autoReplyIsStatusMessage;
- (void)setAutoReplyIsStatusMessage:(BOOL)autoReplyIsStatusMessage;

- (NSString *)statusName;
- (void)setStatusName:(NSString *)statusName;

- (BOOL)shouldForceInitialIdleTime;
- (void)setShouldForceInitialIdleTime:(BOOL)shouldForceInitialIdleTime;
- (double)forcedInitialIdleTime;
- (void)setForcedInitialIdleTime:(double)forcedInitialIdleTime;

- (void)setMutabilityType:(AIStatusMutabilityType)mutabilityType;

- (BOOL)mutesSound;
- (void)setMutesSound:(BOOL)mutes;

- (BOOL)silencesGrowl;
- (void)setSilencesGrowl:(BOOL)silences;

- (AISpecialStatusType)specialStatusType;
- (void)setSpecialStatusType:(AISpecialStatusType)inSpecialStatusType;

@end
