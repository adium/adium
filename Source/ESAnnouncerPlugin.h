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

#import <Adium/AIContactAlertsControllerProtocol.h>

#define ANNOUNCER_DEFAULT_PREFS 	@"AnnouncerDefaults"
#define PREF_GROUP_ANNOUNCER		@"Announcer"
#define KEY_ANNOUNCER_TIME			@"Speak Time"
#define KEY_ANNOUNCER_SENDER		@"Speak Sender"

#define KEY_ANNOUNCER_TEXT_TO_SPEAK @"TextToSpeak"

#define KEY_VOICE_STRING				@"Voice"
#define KEY_PITCH						@"Pitch"
#define KEY_RATE						@"Rate"
#define KEY_PITCH_CUSTOM				@"Custom Pitch"
#define KEY_RATE_CUSTOM					@"Custom Rate"

#define SPEAK_TEXT_ALERT_IDENTIFIER		@"SpeakText"
#define SPEAK_EVENT_ALERT_IDENTIFIER	@"SpeakEvent"

#define	SPEAK_EVENT_TIME				AILocalizedString(@"Speak Event Time",nil)

@interface ESAnnouncerPlugin : AIPlugin <AIActionHandler> {
    NSString					*lastSenderString;
}

@end
