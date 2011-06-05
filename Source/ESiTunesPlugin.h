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

#define KEY_CURRENT_TRACK_FORMAT	@"Current Track Format"

#define ALBUM_TRIGGER				AILocalizedString(@"%_album","Trigger for the album of the currently playing iTunes song")
#define ARTIST_TRIGGER				AILocalizedString(@"%_artist","Trigger for the artist of the currently playing iTunes song")
#define COMPOSER_TRIGGER			AILocalizedString(@"%_composer","Trigger for the composer of the currently playing iTunes song")
#define GENRE_TRIGGER				AILocalizedString(@"%_genre","Trigger for the genre of the currently playing iTunes song")
#define STATUS_TRIGGER				AILocalizedString(@"%_status","Trigger for the genre of the currently playing iTunes song")
#define TRACK_TRIGGER				AILocalizedString(@"%_track","Trigger for the name of the currently playing iTunes song")
#define YEAR_TRIGGER				AILocalizedString(@"%_year","Trigger for the year of the currently playing iTunes song")
#define	STORE_URL_TRIGGER			AILocalizedString(@"%_iTMS","Trigger for an iTunes Music Store link to the currently playing iTunes song")
#define MUSIC_TRIGGER				AILocalizedString(@"%_music","Command which triggers *is listening to %_track by %_artist*")
#define CURRENT_TRACK_TRIGGER		AILocalizedString(@"%_iTunes","Trigger for the song - artist of the currently playing iTunes song")

#define ITUNES_ALBUM				@"Album"
#define ITUNES_ARTIST				@"Artist"
#define ITUNES_COMPOSER				@"Composer"
#define ITUNES_GENRE				@"Genre"
#define ITUNES_PLAYER_STATE			@"Player State"
#define ITUNES_NAME					@"Name"
#define ITUNES_STREAM_TITLE			@"Stream Title"
#define ITUNES_STORE_URL			@"Store URL"
#define ITUNES_TOTAL_TIME			@"Total Time"
#define ITUNES_YEAR					@"Year"

@interface ESiTunesPlugin : AIPlugin <AIContentFilter> {
	NSDictionary *iTunesCurrentInfo;
	
	NSDictionary *substitutionDict;
	NSDictionary *phraseSubstitutionDict;
	BOOL iTunesIsStopped;
	BOOL iTunesIsPaused;
}

@end
