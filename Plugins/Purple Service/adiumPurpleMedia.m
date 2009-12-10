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

#error Must be called when destroying AIMedia
static void
adium_media_disconnect_levels(PurpleMedia *media, AIMedia *adiumMedia)
{
	PurpleMediaManager *manager = purple_media_get_manager(media);
	GstElement *element = purple_media_manager_get_pipeline(manager);
	gulong handler_id = g_signal_handler_find(G_OBJECT(gst_pipeline_get_bus(GST_PIPELINE(element))),
						  G_SIGNAL_MATCH_FUNC | G_SIGNAL_MATCH_DATA, 0, 0, 
						  NULL, G_CALLBACK(level_message_cb), adiumMedia);
	if (handler_id)
		g_signal_handler_disconnect(G_OBJECT(gst_pipeline_get_bus(GST_PIPELINE(element))),
					    handler_id);
}

typedef struct
{
	AIMedia *adiumMedia;
	gchar *session_id;
	gchar *participant;
} AdiumMediaRealizeData;

static gboolean
realize_cb_cb(AdiumMediaRealizeData *data)
{
	AdiumMediaPrivate *priv = data->gtkmedia->priv;
	gulong window_id;

#ifdef _WIN32
	if (data->participant == NULL)
		window_id = GDK_WINDOW_HWND(priv->local_video->window);
	else
		window_id = GDK_WINDOW_HWND(priv->remote_video->window);
#elif defined(HAVE_X11)
	if (data->participant == NULL)
		window_id = GDK_WINDOW_XWINDOW(priv->local_video->window);
	else
		window_id = GDK_WINDOW_XWINDOW(priv->remote_video->window);
#else
#	error "Unsupported windowing system"
#endif

	purple_media_set_output_window(priv->media, data->session_id,
			data->participant, window_id);

	g_free(data->session_id);
	g_free(data->participant);
	g_free(data);
	return FALSE;
}

static void
realize_cb(GtkWidget *widget, AdiumMediaRealizeData *data)
{
	g_timeout_add(0, (GSourceFunc)realize_cb_cb, data);
}

static void
adium_media_emit_message(PurpleMedia *media, const char *message, AIMedia *adiumMedia)
{
#error emit message	
}

static void
adium_media_error_cb(PurpleMedia *media, const char *error, AIMedia *adiumMedia)
{
#error error message
}

static void
adium_media_ready_cb(PurpleMedia *media, AIMedia *adiumMedia, const gchar *sid)
{
	PurpleMediaSessionType type = purple_media_get_session_type(media, sid);
	
	if (type & PURPLE_MEDIA_RECV_VIDEO) {
		AdiumMediaRealizeData *data;
		GtkWidget *aspect;
		GtkWidget *remote_video;
		GdkColor color = {0, 0, 0, 0};

		aspect = gtk_aspect_frame_new(NULL, 0.5, 0.5, 4.0/3.0, FALSE);
		gtk_frame_set_shadow_type(GTK_FRAME(aspect), GTK_SHADOW_IN);
		gtk_box_pack_start(GTK_BOX(recv_widget), aspect, TRUE, TRUE, 0);

		data = g_new0(AdiumMediaRealizeData, 1);
		data->gtkmedia = gtkmedia;
		data->session_id = g_strdup(sid);
		data->participant = g_strdup(gtkmedia->priv->screenname);

		remote_video = gtk_drawing_area_new();
		gtk_widget_modify_bg(remote_video, GTK_STATE_NORMAL, &color);
		g_signal_connect(G_OBJECT(remote_video), "realize",
				G_CALLBACK(realize_cb), data);
		gtk_container_add(GTK_CONTAINER(aspect), remote_video);
		gtk_widget_set_size_request (GTK_WIDGET(remote_video), 320, 240);
		gtk_widget_show(remote_video);
		gtk_widget_show(aspect);

		gtkmedia->priv->remote_video = remote_video;
	}
	
	if (type & PURPLE_MEDIA_SEND_VIDEO) {
		AdiumMediaRealizeData *data;
		GtkWidget *aspect;
		GtkWidget *local_video;
		GdkColor color = {0, 0, 0, 0};

		aspect = gtk_aspect_frame_new(NULL, 0.5, 0.5, 4.0/3.0, FALSE);
		gtk_frame_set_shadow_type(GTK_FRAME(aspect), GTK_SHADOW_IN);
		gtk_box_pack_start(GTK_BOX(send_widget), aspect, TRUE, TRUE, 0);

		data = g_new0(AdiumMediaRealizeData, 1);
		data->gtkmedia = gtkmedia;
		data->session_id = g_strdup(sid);
		data->participant = NULL;

		local_video = gtk_drawing_area_new();
		gtk_widget_modify_bg(local_video, GTK_STATE_NORMAL, &color);
		g_signal_connect(G_OBJECT(local_video), "realize",
				G_CALLBACK(realize_cb), data);
		gtk_container_add(GTK_CONTAINER(aspect), local_video);
		gtk_widget_set_size_request (GTK_WIDGET(local_video), 160, 120);

		gtk_widget_show(local_video);
		gtk_widget_show(aspect);

		gtkmedia->priv->pause =
				gtk_toggle_button_new_with_mnemonic(_("_Pause"));
		g_signal_connect(gtkmedia->priv->pause, "toggled",
				G_CALLBACK(adium_media_pause_toggled),
				gtkmedia);
		gtk_box_pack_end(GTK_BOX(button_widget), gtkmedia->priv->pause,
				FALSE, FALSE, 0);
		gtk_widget_show(gtkmedia->priv->pause);

		gtkmedia->priv->local_video = local_video;
	}

	if (type & PURPLE_MEDIA_RECV_AUDIO) {
		gtk_box_pack_end(GTK_BOX(recv_widget),
				adium_media_add_audio_widget(gtkmedia,
				PURPLE_MEDIA_RECV_AUDIO), FALSE, FALSE, 0);
	}
	if (type & PURPLE_MEDIA_SEND_AUDIO) {
		gtkmedia->priv->mute =
				gtk_toggle_button_new_with_mnemonic("_Mute");
		g_signal_connect(gtkmedia->priv->mute, "toggled",
				G_CALLBACK(adium_media_mute_toggled),
				gtkmedia);
		gtk_box_pack_end(GTK_BOX(button_widget), gtkmedia->priv->mute,
				FALSE, FALSE, 0);
		gtk_widget_show(gtkmedia->priv->mute);

		gtk_box_pack_end(GTK_BOX(send_widget),
				adium_media_add_audio_widget(gtkmedia,
				PURPLE_MEDIA_SEND_AUDIO), FALSE, FALSE, 0);
	}


	if (type & PURPLE_MEDIA_AUDIO &&
			gtkmedia->priv->level_handler_id == 0) {
		gtkmedia->priv->level_handler_id = g_signal_connect(
				media, "level", G_CALLBACK(level_message_cb),
				gtkmedia);
	}

	if (purple_media_is_initiator(media, sid, NULL) == FALSE) {
#error XXX Add something to accept or reject this media
	}

	/* set the window icon according to the type */
	if (type & PURPLE_MEDIA_VIDEO) {
		adiumMedia.mediaType = AIMediaTypeVideo;
	} else if (type & PURPLE_MEDIA_AUDIO) {
		adiumMedia.mediaType = AIMediaTypeAudio;
	}
}

static void
adium_media_state_changed_cb(PurpleMedia *media, PurpleMediaState state, gchar *sid, gchar *name, AIMedia *adiumMedia)
{
	AILog(@"state: %d sid: %s name: %s\n", state, sid ? sid : "(null)", name ? name : "(null)");
	
	if (sid == NULL && name == NULL) {
		if (state == PURPLE_MEDIA_STATE_END) {
#error			adium_media_emit_message(adiumMedia, _("The call has been terminated."));
		}
	} else if (state == PURPLE_MEDIA_STATE_NEW && sid != NULL && name != NULL) {
		adium_media_ready_cb(media, adiumMedia, sid);
	}
}

static void
adium_media_stream_info_cb(PurpleMedia *media, PurpleMediaInfoType type, gchar *sid, gchar *name, gboolean local, AIMedia *adiumMedia)
{
	if (type == PURPLE_MEDIA_INFO_REJECT) {
#warning		adium_media_emit_message(gtkmedia, _("You have rejected the call."));
	} else if (type == PURPLE_MEDIA_INFO_ACCEPT) {		
#warning Check for pending accept/deny
		adiumMedia.mediaState = AIMediaStateAccepted;
		
#error		adium_media_emit_message(gtkmedia, _("Call in progress."));
	}
}

static gboolean
adium_media_new_cb(PurpleMediaManager *manager, PurpleMedia *media,
		PurpleAccount *account, gchar *screenname, gpointer nul)
{
	AIListContact *contact = contactLookupFromBuddy(purple_find_buddy(account, screenname));
	AIAccount *adiumAccount = accountLookup(account);
	
	AIMedia *adiumMedia = [adium.mediaController mediaWithContact:contact onAccount:adiumAccount];

	adiumMedia.protocolInfo = (id)media;
	
	if (purple_media_is_initiator(media, NULL, NULL) == TRUE) {
		[adiumMedia show];
		
		adiumMedia.mediaState = AIMediaStateWaiting;
	} else {
		adiumMedia.mediaState = AIMediaStateRequested;
	}
	
	g_signal_connect(G_OBJECT(media), "error",
					 G_CALLBACK(adium_media_error_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "state-changed",
					 G_CALLBACK(adium_media_state_changed_cb), adiumMedia);
	g_signal_connect(G_OBJECT(media), "stream-info",
					 G_CALLBACK(adium_media_stream_info_cb), adiumMedia);
	
	return TRUE;
}

static GstElement *
create_default_video_src(PurpleMedia *media,
		const gchar *session_id, const gchar *participant)
{
	GstElement *sendbin, *src, *videoscale, *capsfilter;
	GstPad *pad;
	GstPad *ghost;
	GstCaps *caps;

#ifdef _WIN32
	/* autovideosrc doesn't pick ksvideosrc for some reason */
	src = gst_element_factory_make("ksvideosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("dshowvideosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("autovideosrc", NULL);
#else
	src = gst_element_factory_make("gconfvideosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("autovideosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("v4l2src", NULL);
	if (src == NULL)
		src = gst_element_factory_make("v4lsrc", NULL);
#endif
	if (src == NULL) {
		purple_debug_error("gtkmedia", "Unable to find a suitable "
				"element for the default video source.\n");
		return NULL;
	}

	sendbin = gst_bin_new("adiumdefaultvideosrc");
	videoscale = gst_element_factory_make("videoscale", NULL);
	capsfilter = gst_element_factory_make("capsfilter", NULL);

	/* It was recommended to set the size <= 352x288 and framerate <= 20 */
	caps = gst_caps_from_string("video/x-raw-yuv , width=[250,352] , "
			"height=[200,288] , framerate=[1/1,20/1]");
	g_object_set(G_OBJECT(capsfilter), "caps", caps, NULL);

	gst_bin_add_many(GST_BIN(sendbin), src,
			videoscale, capsfilter, NULL);
	gst_element_link_many(src, videoscale, capsfilter, NULL);

	pad = gst_element_get_static_pad(capsfilter, "src");
	ghost = gst_ghost_pad_new("ghostsrc", pad);
	gst_object_unref(pad);
	gst_element_add_pad(sendbin, ghost);

	return sendbin;
}

static GstElement *
create_default_video_sink(PurpleMedia *media,
		const gchar *session_id, const gchar *participant)
{
	GstElement *sink = gst_element_factory_make("gconfvideosink", NULL);
	if (sink == NULL)
		sink = gst_element_factory_make("autovideosink", NULL);
	if (sink == NULL)
		purple_debug_error("gtkmedia", "Unable to find a suitable "
				"element for the default video sink.\n");
	return sink;
}

static GstElement *
create_default_audio_src(PurpleMedia *media,
		const gchar *session_id, const gchar *participant)
{
	GstElement *src;
	src = gst_element_factory_make("gconfaudiosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("autoaudiosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("alsasrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("osssrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("dshowaudiosrc", NULL);
	if (src == NULL) {
		purple_debug_error("gtkmedia", "Unable to find a suitable "
				"element for the default audio source.\n");
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
	sink = gst_element_factory_make("gconfaudiosink", NULL);
	if (sink == NULL)
		sink = gst_element_factory_make("autoaudiosink",NULL);
	if (sink == NULL) {
		purple_debug_error("gtkmedia", "Unable to find a suitable "
				"element for the default audio sink.\n");
		return NULL;
	}
	return sink;
}
	
void
adium_medias_init(void)
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

	AILog(@"Registering media element types");
	purple_media_manager_set_active_element(manager, default_video_src);
	purple_media_manager_set_active_element(manager, default_video_sink);
	purple_media_manager_set_active_element(manager, default_audio_src);
	purple_media_manager_set_active_element(manager, default_audio_sink);
}
