//  ESiTunesPlugin.h
//  Adium
//
//  Started by Evan Schoenberg on 6/11/05.
//	Assigned to Kiel Gillard (Trac Ticket #316)
	
#import <Adium/AIContentControllerProtocol.h>

typedef enum {
	AUTODISABLES = 0,
	ALWAYS_ENABLED = 1,
	ENABLED_IF_ITUNES_PLAYING = 2,
	RESPONDER_IS_WEBVIEW = 3
} KGiTunesPluginMenuItemKind;

#define Adium_iTunesTrackChangedNotification @"Adium_iTunesTrackChangedNotification"

#define ITUNES_ALBUM		@"Album"
#define ITUNES_ARTIST		@"Artist"
#define ITUNES_COMPOSER		@"Composer"
#define ITUNES_GENRE		@"Genre"
#define ITUNES_PLAYER_STATE	@"Player State"
#define ITUNES_NAME			@"Name"
#define ITUNES_STREAM_TITLE @"Stream Title"
#define ITUNES_STORE_URL	@"Store URL"
#define ITUNES_TOTAL_TIME	@"Total Time"
#define ITUNES_YEAR			@"Year"

@interface ESiTunesPlugin : AIPlugin <AIContentFilter> {
	NSDictionary *iTunesCurrentInfo;
	
	NSDictionary *substitutionDict;
	NSDictionary *phraseSubstitutionDict;
	BOOL iTunesIsStopped;
	BOOL iTunesIsPaused;
}

@end
