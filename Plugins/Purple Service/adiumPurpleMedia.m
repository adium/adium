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

#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIAccount.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMedia.h>
#import <Adium/AIMediaControllerProtocol.h>
#include <string.h>
#include <libpurple/media.h>
#include <libpurple/mediamanager.h>
#include <libpurple/media-gst.h>
#include <gst/interfaces/xoverlay.h>

static void
level_message_cb(PurpleMedia *media, gchar *session_id, gchar *participant,
		double level, AIMedia *adiumMedia)
{
	if (participant == NULL) {
		// Send progress
		[adiumMedia setSendProgress:(CGFloat)level];
	} else {
		// Receive progress
		[adiumMedia setReceiveProgress:(CGFloat)level];
	}
}

static void
adium_media_emit_message(AIMedia *adiumMedia, const char *message)
{
#warning emit message	
	
	NSLog(@"Media emit message: %s", message);
}

static void
adium_media_error_cb(AIMedia *adiumMdia, const char *message)
{
#warning error message
	
	NSLog(@"Media error message: %s", message);
}

static void
adium_media_ready_cb(PurpleMedia *media, AIMedia *adiumMedia, const gchar *sid)
{
	PurpleMediaSessionType type = purple_media_get_session_type(media, sid);
	
	if (type & PURPLE_MEDIA_RECV_VIDEO) {
		// Setup receiving video view
#warning Set up receiving video view
	}
	
	if (type & PURPLE_MEDIA_SEND_VIDEO) {
		// Set up sending video view
#warning Set up sending video view
	}

	if (type & PURPLE_MEDIA_RECV_AUDIO) {
		// Set up receiving audio
#warning Set up receiving audio
	}
	
	if (type & PURPLE_MEDIA_SEND_AUDIO) {
		// Set up sending audio
#warning Set up sending audio
	}

	if (purple_media_is_initiator(media, sid, NULL) == FALSE) {
#warning Add something to accept or reject this media
	}

	/* set the window icon according to the type */
	if (type & PURPLE_MEDIA_VIDEO) {
		adiumMedia.mediaType |= AIMediaTypeVideo;
	} else if (type & PURPLE_MEDIA_AUDIO) {
		adiumMedia.mediaType |= AIMediaTypeAudio;
	}
}

static void
adium_media_state_changed_cb(PurpleMedia *media, PurpleMediaState state, gchar *sid, gchar *name, AIMedia *adiumMedia)
{
	NSLog(@"state: %d sid: %s name: %s\n", state, sid ? sid : "(null)", name ? name : "(null)");
	
	adiumMedia.mediaState = state;
	
	if (sid == NULL && name == NULL) {
		if (state == PURPLE_MEDIA_STATE_END) {
			adium_media_emit_message(adiumMedia, _("The call has been terminated."));
		}
	} else if (state == PURPLE_MEDIA_STATE_NEW && sid != NULL && name != NULL) {
		adium_media_ready_cb(media, adiumMedia, sid);
	}
}

static void
adium_media_stream_info_cb(PurpleMedia *media, PurpleMediaInfoType type, gchar *sid, gchar *name, gboolean local, AIMedia *adiumMedia)
{
	NSLog(@"Media stream info cb: %d", type);
	
	if (type == PURPLE_MEDIA_INFO_REJECT) {
		adium_media_emit_message(adiumMedia, _("You have rejected the call."));
	} else if (type == PURPLE_MEDIA_INFO_ACCEPT) {		
#warning Check for pending accept/deny
		adiumMedia.mediaState = AIMediaStateAccepted;
		
		adium_media_emit_message(adiumMedia, _("Call in progress."));
	}
}

static gboolean
adium_media_new_cb(PurpleMediaManager *manager, PurpleMedia *media,
		PurpleAccount *account, gchar *screenname, gpointer nul)
{
	NSLog(@"Media new cb: %s", screenname);
	
	AIListContact *contact = contactLookupFromBuddy(purple_find_buddy(account, screenname));
	AIAccount *adiumAccount = accountLookup(account);
	
	AIMedia *adiumMedia = [adium.mediaController mediaWithContact:contact onAccount:adiumAccount];

	adiumMedia.protocolInfo = (id)media;
	
	if (purple_media_is_initiator(media, NULL, NULL) == TRUE) {		
		adiumMedia.mediaState = AIMediaStateWaiting;
		
		[[adium.mediaController windowControllerForMedia:adiumMedia] showWindow:nil];
	} else {
		adiumMedia.mediaState = AIMediaStateRequested;
	}
	
	g_signal_connect(G_OBJECT(media), "error",
					 G_CALLBACK(adium_media_error_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "state-changed",
					 G_CALLBACK(adium_media_state_changed_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "stream-info",
					 G_CALLBACK(adium_media_stream_info_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "level",
					 G_CALLBACK(level_message_cb), adiumMedia);
	
	return TRUE;
}

void adium_media_remove(AIMedia *adiumMedia)
{
	PurpleMedia *media = (PurpleMedia *)adiumMedia.protocolInfo;
	
	purple_media_remove_output_windows(media);
	
	PurpleMediaManager *manager = purple_media_get_manager(media);
	GstElement *element = purple_media_manager_get_pipeline(manager);
	gulong handler_id = g_signal_handler_find(G_OBJECT(gst_pipeline_get_bus(GST_PIPELINE(element))),
											  G_SIGNAL_MATCH_FUNC | G_SIGNAL_MATCH_DATA, 0, 0, 
											  NULL, G_CALLBACK(level_message_cb), adiumMedia);
	if (handler_id) {
		g_signal_handler_disconnect(G_OBJECT(gst_pipeline_get_bus(GST_PIPELINE(element))), handler_id);
	}
}

static GstElement *
create_default_video_src(PurpleMedia *media,
		const gchar *session_id, const gchar *participant)
{
	GstElement *sendbin, *src, *videoscale, *capsfilter;
	GstPad *pad;
	GstPad *ghost;
	GstCaps *caps;

	src = gst_element_factory_make("osxvideosrc", NULL);
	
	if (src == NULL) {
		NSLog(@"Unable to find suitable element for default video source.");
		return NULL;
	}

	sendbin = gst_bin_new("adiumdefaultvideosrc");
	videoscale = gst_element_factory_make("videoscale", NULL);
	capsfilter = gst_element_factory_make("capsfilter", NULL);

	/* It was recommended to set the size <= 352x288 and framerate <= 20 */
	caps = gst_caps_from_string("video/x-raw-yuv , width=[250,352] , height=[200,288] , framerate=[1/1,20/1]");
	g_object_set(G_OBJECT(capsfilter), "caps", caps, NULL);

	gst_bin_add_many(GST_BIN(sendbin), src, videoscale, capsfilter, NULL);
	gst_element_link_many(src, videoscale, capsfilter, NULL);

	pad = gst_element_get_static_pad(capsfilter, "src");
	ghost = gst_ghost_pad_new("ghostsrc", pad);
	gst_object_unref(pad);
	gst_element_add_pad(sendbin, ghost);

	return sendbin;
}

static GstElement *
create_default_video_sink(PurpleMedia *media, const gchar *session_id, const gchar *participant)
{
	GstElement *sink = gst_element_factory_make("osxvideosink", NULL);
	
	if (sink == NULL) {
		NSLog(@"Unable to find suitable element for default video sink.");
	}
	
	return sink;
}

static GstElement *
create_default_audio_src(PurpleMedia *media,
		const gchar *session_id, const gchar *participant)
{
	GstElement *src;
	src = gst_element_factory_make("osxaudiosrc", NULL);
	
	if (src == NULL) {
		NSLog(@"Unable to find suitable element for default audio source.");
		return NULL;
	}
	
	gst_element_set_name(src, "adiumdefaultaudiosrc");
	return src;
}

static GstElement *
create_default_audio_sink(PurpleMedia *media,
		const gchar *session_id, const gchar *participant)
{
	GstElement *sink;
	sink = gst_element_factory_make("osxaudiosink", NULL);

	if (sink == NULL) {
		NSLog(@"Unable to find suitable element for default audio sink.");
		return NULL;
	}
	
	return sink;
}
	
void
adiumPurpleMedia_init(void)
{	
	PurpleMediaManager *manager = purple_media_manager_get();
	PurpleMediaElementInfo *default_video_src =
			g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
			"id", "adiumdefaultvideosrc",
			"name", "Adium Default Video Source",
			"type", PURPLE_MEDIA_ELEMENT_VIDEO
					| PURPLE_MEDIA_ELEMENT_SRC
					| PURPLE_MEDIA_ELEMENT_ONE_SRC
					| PURPLE_MEDIA_ELEMENT_UNIQUE,
			"create-cb", create_default_video_src, NULL);
	PurpleMediaElementInfo *default_video_sink =
			g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
			"id", "adiumdefaultvideosink",
			"name", "Adium Default Video Sink",
			"type", PURPLE_MEDIA_ELEMENT_VIDEO
					| PURPLE_MEDIA_ELEMENT_SINK
					| PURPLE_MEDIA_ELEMENT_ONE_SINK,
			"create-cb", create_default_video_sink, NULL);
	PurpleMediaElementInfo *default_audio_src =
			g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
			"id", "adiumdefaultaudiosrc",
			"name", "Adium Default Audio Source",
			"type", PURPLE_MEDIA_ELEMENT_AUDIO
					| PURPLE_MEDIA_ELEMENT_SRC
					| PURPLE_MEDIA_ELEMENT_ONE_SRC
					| PURPLE_MEDIA_ELEMENT_UNIQUE,
			"create-cb", create_default_audio_src, NULL);
	PurpleMediaElementInfo *default_audio_sink =
			g_object_new(PURPLE_TYPE_MEDIA_ELEMENT_INFO,
			"id", "adiumdefaultaudiosink",
			"name", "Adium Default Audio Sink",
			"type", PURPLE_MEDIA_ELEMENT_AUDIO
					| PURPLE_MEDIA_ELEMENT_SINK
					| PURPLE_MEDIA_ELEMENT_ONE_SINK,
			"create-cb", create_default_audio_sink, NULL);

	g_signal_connect(G_OBJECT(manager), "init-media",
			 G_CALLBACK(adium_media_new_cb), NULL);

	purple_media_manager_set_ui_caps(manager, 
			PURPLE_MEDIA_CAPS_AUDIO |
			PURPLE_MEDIA_CAPS_AUDIO_SINGLE_DIRECTION |
			PURPLE_MEDIA_CAPS_VIDEO |
			PURPLE_MEDIA_CAPS_VIDEO_SINGLE_DIRECTION |
			PURPLE_MEDIA_CAPS_AUDIO_VIDEO);

	AILogWithSignature(@"Registering media element types");
	purple_media_manager_set_active_element(manager, default_video_src);
	purple_media_manager_set_active_element(manager, default_video_sink);
	purple_media_manager_set_active_element(manager, default_audio_src);
	purple_media_manager_set_active_element(manager, default_audio_sink);
}
