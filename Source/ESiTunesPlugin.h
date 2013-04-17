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

#import <Adium/AIContentControllerProtocol.h>

typedef enum {
	AUTODISABLES = 0,
	ALWAYS_ENABLED = 1,
	ENABLED_IF_ITUNES_PLAYING = 2,
	RESPONDER_IS_WEBVIEW = 3
} KGiTunesPluginMenuItemKind;

#define Adium_iTunesTrackChangedNotification		@"Adium_iTunesTrackChangedNotification"
#define Adium_CurrentTrackFormatChangedNotification	@"Adium_CurrentTrackFormatChangedNotification"

#define TRIGGER_ALBUM				@"%_album"
#define TRIGGER_ARTIST				@"%_artist"
#define TRIGGER_COMPOSER			@"%_composer"
#define TRIGGER_GENRE				@"%_genre"
#define TRIGGER_STATUS				@"%_status"
#define TRIGGER_TRACK				@"%_track"
#define TRIGGER_YEAR				@"%_year"
#define	TRIGGER_STORE_URL			@"%_iTMS"
#define TRIGGER_MUSIC				@"%_music"
#define TRIGGER_CURRENT_TRACK		@"%_iTunes"

#define KEY_TRIGGERS_TOOLBAR		@"iTunesItem"
#define KEY_ITUNES_TRACK_FORMAT		@"Current Track Format"
#define KEY_ITUNES_ALBUM			@"Album"
#define KEY_ITUNES_ARTIST			@"Artist"
#define KEY_ITUNES_COMPOSER			@"Composer"
#define KEY_ITUNES_GENRE			@"Genre"
#define KEY_ITUNES_PLAYER_STATE		@"Player State"
#define KEY_ITUNES_NAME				@"Name"
#define KEY_ITUNES_STREAM_TITLE		@"Stream Title"
#define KEY_ITUNES_STORE_URL		@"Store URL"
#define KEY_ITUNES_TOTAL_TIME		@"Total Time"
#define KEY_ITUNES_YEAR				@"Year"

@interface ESiTunesPlugin : AIPlugin <AIContentFilter> {
	NSDictionary *iTunesCurrentInfo;
	
	NSDictionary *substitutionDict;
	NSDictionary *phraseSubstitutionDict;
	BOOL iTunesIsStopped;
	BOOL iTunesIsPaused;
}

@end
