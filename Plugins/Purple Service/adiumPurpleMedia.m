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
	AdiumMedia *gtkmedia;
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
adium_media_error_cb(AdiumMedia *media, const char *error, AdiumMedia *gtkmedia)
{
	PurpleConversation *conv = purple_find_conversation_with_account(
			PURPLE_CONV_TYPE_ANY, gtkmedia->priv->screenname,
			purple_media_get_account(gtkmedia->priv->media));
	if (conv != NULL)
		purple_conversation_write(conv, NULL, error,
				PURPLE_MESSAGE_ERROR, time(NULL));
	gtk_statusbar_push(GTK_STATUSBAR(gtkmedia->priv->statusbar),
			0, error);
}

static GtkWidget *
adium_media_add_audio_widget(AdiumMedia *gtkmedia,
		PurpleMediaSessionType type)
{
	GtkWidget *volume_widget, *progress_parent, *volume, *progress;
	double value;

	if (type & PURPLE_MEDIA_SEND_AUDIO) {
		value = purple_prefs_get_int(
			"/purple/media/audio/volume/input");
	} else if (type & PURPLE_MEDIA_RECV_AUDIO) {
		value = purple_prefs_get_int(
			"/purple/media/audio/volume/output");
	} else
		g_return_val_if_reached(NULL);

#if GTK_CHECK_VERSION(2,12,0)
	/* Setup widget structure */
	volume_widget = gtk_hbox_new(FALSE, ADIUM_HIG_BOX_SPACE);
	progress_parent = gtk_vbox_new(FALSE, 0);
	gtk_box_pack_start(GTK_BOX(volume_widget),
			progress_parent, TRUE, TRUE, 0);

	/* Volume button */
	volume = gtk_volume_button_new();
	gtk_scale_button_set_value(GTK_SCALE_BUTTON(volume), value/100.0);
	gtk_box_pack_end(GTK_BOX(volume_widget),
			volume, FALSE, FALSE, 0);
#else
	/* Setup widget structure */
	volume_widget = gtk_vbox_new(FALSE, 0);
	progress_parent = volume_widget;

	/* Volume slider */
	volume = gtk_hscale_new_with_range(0.0, 100.0, 5.0);
	gtk_range_set_increments(GTK_RANGE(volume), 5.0, 25.0);
	gtk_range_set_value(GTK_RANGE(volume), value);
	gtk_scale_set_draw_value(GTK_SCALE(volume), FALSE);
	gtk_box_pack_end(GTK_BOX(volume_widget),
			volume, TRUE, FALSE, 0);
#endif

	/* Volume level indicator */
	progress = gtk_progress_bar_new();
	gtk_widget_set_size_request(progress, 250, 10);
	gtk_box_pack_end(GTK_BOX(progress_parent), progress, TRUE, FALSE, 0);

	if (type & PURPLE_MEDIA_SEND_AUDIO) {
		g_signal_connect (G_OBJECT(volume), "value-changed",
				G_CALLBACK(adium_media_input_volume_changed),
				gtkmedia->priv->media);
		gtkmedia->priv->send_progress = progress;
	} else if (type & PURPLE_MEDIA_RECV_AUDIO) {
		g_signal_connect (G_OBJECT(volume), "value-changed",
				G_CALLBACK(adium_media_output_volume_changed),
				gtkmedia->priv->media);
		gtkmedia->priv->recv_progress = progress;
	}

	gtk_widget_show_all(volume_widget);

	return volume_widget;
}

static void
adium_media_ready_cb(PurpleMedia *media, AdiumMedia *gtkmedia, const gchar *sid)
{
	GtkWidget *send_widget = NULL, *recv_widget = NULL, *button_widget = NULL;
	PurpleMediaSessionType type =
			purple_media_get_session_type(media, sid);
	GdkPixbuf *icon = NULL;

	if (gtkmedia->priv->recv_widget == NULL
			&& type & (PURPLE_MEDIA_RECV_VIDEO |
			PURPLE_MEDIA_RECV_AUDIO)) {
		recv_widget = gtk_vbox_new(FALSE, ADIUM_HIG_BOX_SPACE);	
		gtk_box_pack_start(GTK_BOX(gtkmedia->priv->display),
				recv_widget, TRUE, TRUE, 0);
		gtk_widget_show(recv_widget);
	} else
		recv_widget = gtkmedia->priv->recv_widget;
	if (gtkmedia->priv->send_widget == NULL
			&& type & (PURPLE_MEDIA_SEND_VIDEO |
			PURPLE_MEDIA_SEND_AUDIO)) {
		send_widget = gtk_vbox_new(FALSE, ADIUM_HIG_BOX_SPACE);
		gtk_box_pack_start(GTK_BOX(gtkmedia->priv->display),
				send_widget, TRUE, TRUE, 0);
		button_widget = gtk_hbox_new(FALSE, ADIUM_HIG_BOX_SPACE);
		gtk_box_pack_end(GTK_BOX(send_widget), button_widget,
				FALSE, FALSE, 0);
		gtk_widget_show(GTK_WIDGET(button_widget));
		gtk_widget_show(send_widget);

		/* Hold button */
		gtkmedia->priv->hold =
				gtk_toggle_button_new_with_mnemonic("_Hold");
		g_signal_connect(gtkmedia->priv->hold, "toggled",
				G_CALLBACK(adium_media_hold_toggled),
				gtkmedia);
		gtk_box_pack_end(GTK_BOX(button_widget), gtkmedia->priv->hold,
				FALSE, FALSE, 0);
		gtk_widget_show(gtkmedia->priv->hold);
	} else {
		send_widget = gtkmedia->priv->send_widget;
		button_widget = gtkmedia->priv->button_widget;
	}

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

	if (send_widget != NULL)
		gtkmedia->priv->send_widget = send_widget;
	if (recv_widget != NULL)
		gtkmedia->priv->recv_widget = recv_widget;
	if (button_widget != NULL)
		gtkmedia->priv->button_widget = button_widget;

	if (purple_media_is_initiator(media, sid, NULL) == FALSE) {
#error XXX Add something to accept or reject this media
	}

	/* set the window icon according to the type */
	if (type & PURPLE_MEDIA_VIDEO) {
		icon = gtk_widget_render_icon(GTK_WIDGET(gtkmedia),
			ADIUM_STOCK_TOOLBAR_VIDEO_CALL,
			gtk_icon_size_from_name(ADIUM_ICON_SIZE_TANGO_LARGE), NULL);
	} else if (type & PURPLE_MEDIA_AUDIO) {
		icon = gtk_widget_render_icon(GTK_WIDGET(gtkmedia),
			ADIUM_STOCK_TOOLBAR_AUDIO_CALL,
			gtk_icon_size_from_name(ADIUM_ICON_SIZE_TANGO_LARGE), NULL);
	}

	if (icon) {
		gtk_window_set_icon(GTK_WINDOW(gtkmedia), icon);
		g_object_unref(icon);
	}
	
	gtk_widget_show(gtkmedia->priv->display);
}

static void
adium_media_state_changed_cb(PurpleMedia *media, PurpleMediaState state,
		gchar *sid, gchar *name, AdiumMedia *gtkmedia)
{
	purple_debug_info("gtkmedia", "state: %d sid: %s name: %s\n",
			state, sid ? sid : "(null)", name ? name : "(null)");
	if (sid == NULL && name == NULL) {
		if (state == PURPLE_MEDIA_STATE_END) {
			adium_media_emit_message(gtkmedia,
					_("The call has been terminated."));
			gtk_widget_destroy(GTK_WIDGET(gtkmedia));
		}
	} else if (state == PURPLE_MEDIA_STATE_NEW &&
			sid != NULL && name != NULL) {
		adium_media_ready_cb(media, gtkmedia, sid);
	}
}

static void
adium_media_stream_info_cb(PurpleMedia *media, PurpleMediaInfoType type,
		gchar *sid, gchar *name, gboolean local,
		AdiumMedia *gtkmedia)
{
	if (type == PURPLE_MEDIA_INFO_REJECT) {
		adium_media_emit_message(gtkmedia,
				_("You have rejected the call."));
	} else if (type == PURPLE_MEDIA_INFO_ACCEPT) {
		if (local == TRUE)
			purple_request_close_with_handle(gtkmedia);
		adium_media_set_state(gtkmedia, ADIUM_MEDIA_ACCEPTED);
		adium_media_emit_message(gtkmedia, _("Call in progress."));
		gtk_statusbar_push(GTK_STATUSBAR(gtkmedia->priv->statusbar),
				0, _("Call in progress."));
		gtk_widget_show(GTK_WIDGET(gtkmedia));
	}
}

static void
adium_media_set_property (GObject *object, guint prop_id, const GValue *value, GParamSpec *pspec)
{
	AdiumMedia *media;
	g_return_if_fail(ADIUM_IS_MEDIA(object));

	media = ADIUM_MEDIA(object);
	switch (prop_id) {
		case PROP_MEDIA:
		{
			if (media->priv->media)
				g_object_unref(media->priv->media);
			media->priv->media = g_value_get_object(value);
			g_object_ref(media->priv->media);

			if (purple_media_is_initiator(media->priv->media,
					 NULL, NULL) == TRUE)
				adium_media_set_state(media, ADIUM_MEDIA_WAITING);
			else
				adium_media_set_state(media, ADIUM_MEDIA_REQUESTED);

			g_signal_connect(G_OBJECT(media->priv->media), "error",
				G_CALLBACK(adium_media_error_cb), media);
			g_signal_connect(G_OBJECT(media->priv->media), "state-changed",
				G_CALLBACK(adium_media_state_changed_cb), media);
			g_signal_connect(G_OBJECT(media->priv->media), "stream-info",
				G_CALLBACK(adium_media_stream_info_cb), media);
			break;
		}
		case PROP_SCREENNAME:
			if (media->priv->screenname)
				g_free(media->priv->screenname);
			media->priv->screenname = g_value_dup_string(value);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
adium_media_get_property (GObject *object, guint prop_id, GValue *value, GParamSpec *pspec)
{
	AdiumMedia *media;
	g_return_if_fail(ADIUM_IS_MEDIA(object));

	media = ADIUM_MEDIA(object);

	switch (prop_id) {
		case PROP_MEDIA:
			g_value_set_object(value, media->priv->media);
			break;
		case PROP_SCREENNAME:
			g_value_set_string(value, media->priv->screenname);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static GtkWidget *
adium_media_new(PurpleMedia *media, const gchar *screenname)
{
	AdiumMedia *gtkmedia = g_object_new(adium_media_get_type(),
					     "media", media,
					     "screenname", screenname, NULL);
	return GTK_WIDGET(gtkmedia);
}

static void
adium_media_set_state(AdiumMedia *gtkmedia, AdiumMediaState state)
{
	gtkmedia->priv->state = state;
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
		[adium.mediaController showMedia:adiumMedia];
	}

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
