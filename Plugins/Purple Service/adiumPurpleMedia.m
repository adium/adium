#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#include <string.h>
#include <libpurple/media.h>
#include <libpurple/mediamanager.h>

//XXX
#include "media-gst.h"

#include <gst/interfaces/xoverlay.h>

#define ADIUM_TYPE_MEDIA            (adium_media_get_type())
#define ADIUM_MEDIA(obj)            (G_TYPE_CHECK_INSTANCE_CAST((obj), ADIUM_TYPE_MEDIA, AdiumMedia))
#define ADIUM_MEDIA_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST((klass), ADIUM_TYPE_MEDIA, AdiumMediaClass))
#define ADIUM_IS_MEDIA(obj)         (G_TYPE_CHECK_INSTANCE_TYPE((obj), ADIUM_TYPE_MEDIA))
#define ADIUM_IS_MEDIA_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE((klass), ADIUM_TYPE_MEDIA))
#define ADIUM_MEDIA_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS((obj), ADIUM_TYPE_MEDIA, AdiumMediaClass))

typedef struct _AdiumMedia AdiumMedia;
typedef struct _AdiumMediaClass AdiumMediaClass;
typedef struct _AdiumMediaPrivate AdiumMediaPrivate;

typedef enum
{
	/* Waiting for response */
	ADIUM_MEDIA_WAITING = 1,
	/* Got request */
	ADIUM_MEDIA_REQUESTED,
	/* Accepted call */
	ADIUM_MEDIA_ACCEPTED,
	/* Rejected call */
	ADIUM_MEDIA_REJECTED,
} AdiumMediaState;

struct _AdiumMediaClass
{
	GtkWindowClass parent_class;
};

struct _AdiumMedia
{
	GtkWindow parent;
	AdiumMediaPrivate *priv;
};

struct _AdiumMediaPrivate
{
	PurpleMedia *media;
	gchar *screenname;
	GstElement *send_level;
	GstElement *recv_level;

	AdiumMediaState state;

	guint timeout_id;
	PurpleMediaSessionType request_type;
};

#define ADIUM_MEDIA_GET_PRIVATE(obj) (G_TYPE_INSTANCE_GET_PRIVATE((obj), ADIUM_TYPE_MEDIA, AdiumMediaPrivate))

static void adium_media_class_init (AdiumMediaClass *klass);
static void adium_media_init (AdiumMedia *media);
static void adium_media_dispose (GObject *object);
static void adium_media_finalize (GObject *object);
static void adium_media_get_property (GObject *object, guint prop_id, GValue *value, GParamSpec *pspec);
static void adium_media_set_property (GObject *object, guint prop_id, const GValue *value, GParamSpec *pspec);
static void adium_media_set_state(AdiumMedia *gtkmedia, AdiumMediaState state);

#if 0
enum {
	LAST_SIGNAL
};
static guint adium_media_signals[LAST_SIGNAL] = {0};
#endif

enum {
	PROP_0,
	PROP_MEDIA,
	PROP_SCREENNAME,
	PROP_SEND_LEVEL,
	PROP_RECV_LEVEL
};

static GType
adium_media_get_type(void)
{
	static GType type = 0;

	if (type == 0) {
		static const GTypeInfo info = {
			sizeof(AdiumMediaClass),
			NULL,
			NULL,
			(GClassInitFunc) adium_media_class_init,
			NULL,
			NULL,
			sizeof(AdiumMedia),
			0,
			(GInstanceInitFunc) adium_media_init,
			NULL
		};
		type = g_type_register_static(GTK_TYPE_WINDOW, "AdiumMedia", &info, 0);
	}
	return type;
}


static void
adium_media_class_init (AdiumMediaClass *klass)
{
	GObjectClass *gobject_class = (GObjectClass*)klass;
	parent_class = g_type_class_peek_parent(klass);

	gobject_class->dispose = adium_media_dispose;
	gobject_class->finalize = adium_media_finalize;
	gobject_class->set_property = adium_media_set_property;
	gobject_class->get_property = adium_media_get_property;

	g_object_class_install_property(gobject_class, PROP_MEDIA,
			g_param_spec_object("media",
			"PurpleMedia",
			"The PurpleMedia associated with this media.",
			PURPLE_TYPE_MEDIA,
			G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE));
	g_object_class_install_property(gobject_class, PROP_SCREENNAME,
			g_param_spec_string("screenname",
			"Screenname",
			"The screenname of the user this session is with.",
			NULL,
			G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE));
	g_object_class_install_property(gobject_class, PROP_SEND_LEVEL,
			g_param_spec_object("send-level",
			"Send level",
			"The GstElement of this media's send 'level'",
			GST_TYPE_ELEMENT,
			G_PARAM_READWRITE));
	g_object_class_install_property(gobject_class, PROP_RECV_LEVEL,
			g_param_spec_object("recv-level",
			"Receive level",
			"The GstElement of this media's recv 'level'",
			GST_TYPE_ELEMENT,
			G_PARAM_READWRITE));

	g_type_class_add_private(klass, sizeof(AdiumMediaPrivate));
}

static void
adium_media_set_is_muted(AdiumMedia *media, BOOL isMuted)
{
	purple_media_stream_info(media->priv->media,
			(isMuted ? PURPLE_MEDIA_INFO_MUTE : PURPLE_MEDIA_INFO_UNMUTE),
			NULL, NULL, TRUE);
}

static gboolean
adium_media_delete_event_cb(GtkWidget *widget,
		GdkEvent *event, AdiumMedia *media)
{
	if (media->priv->media)
		purple_media_stream_info(media->priv->media,
				PURPLE_MEDIA_INFO_HANGUP, NULL, NULL, TRUE);
	return FALSE;
}

#ifdef HAVE_X11
static int
adium_x_error_handler(Display *display, XErrorEvent *event)
{
	const gchar *error_type;
	switch (event->error_code) {
#define XERRORCASE(type) case type: error_type = #type; break
		XERRORCASE(BadAccess);
		XERRORCASE(BadAlloc);
		XERRORCASE(BadAtom);
		XERRORCASE(BadColor);
		XERRORCASE(BadCursor);
		XERRORCASE(BadDrawable);
		XERRORCASE(BadFont);
		XERRORCASE(BadGC);
		XERRORCASE(BadIDChoice);
		XERRORCASE(BadImplementation);
		XERRORCASE(BadLength);
		XERRORCASE(BadMatch);
		XERRORCASE(BadName);
		XERRORCASE(BadPixmap);
		XERRORCASE(BadRequest);
		XERRORCASE(BadValue);
		XERRORCASE(BadWindow);
#undef XERRORCASE
		default:
			error_type = "unknown";
			break;
	}
	purple_debug_error("media", "A %s Xlib error has occurred. "
			"The program would normally crash now.\n",
			error_type);
	return 0;
}
#endif

static void
menu_hangup(gpointer data, guint action, GtkWidget *item)
{
	AdiumMedia *gtkmedia = ADIUM_MEDIA(data);
	purple_media_stream_info(gtkmedia->priv->media,
			PURPLE_MEDIA_INFO_HANGUP, NULL, NULL, TRUE);
}

static GtkItemFactoryEntry menu_items[] = {
	{ N_("/_Media"), NULL, NULL, 0, "<Branch>", NULL },
	{ N_("/Media/_Hangup"), NULL, menu_hangup, 0, "<Item>", NULL },
};

static gint menu_item_count = sizeof(menu_items) / sizeof(menu_items[0]);

static const char *
item_factory_translate_func (const char *path, gpointer func_data)
{
	return _(path);
}

static GtkWidget *
setup_menubar(AdiumMedia *window)
{
	GtkAccelGroup *accel_group;
	GtkWidget *menu;

	accel_group = gtk_accel_group_new ();
	gtk_window_add_accel_group(GTK_WINDOW(window), accel_group);
	g_object_unref(accel_group);

	window->priv->item_factory = gtk_item_factory_new(GTK_TYPE_MENU_BAR,
			"<main>", accel_group);

	gtk_item_factory_set_translate_func(window->priv->item_factory,
			(GtkTranslateFunc)item_factory_translate_func,
			NULL, NULL);

	gtk_item_factory_create_items(window->priv->item_factory,
			menu_item_count, menu_items, window);
	g_signal_connect(G_OBJECT(accel_group), "accel-changed",
			G_CALLBACK(adium_save_accels_cb), NULL);

	menu = gtk_item_factory_get_widget(
			window->priv->item_factory, "<main>");

	gtk_widget_show(menu);
	return menu;
}

static void
adium_media_init (AdiumMedia *media)
{
	GtkWidget *vbox;
	media->priv = ADIUM_MEDIA_GET_PRIVATE(media);

#ifdef HAVE_X11
	XSetErrorHandler(adium_x_error_handler);
#endif

	vbox = gtk_vbox_new(FALSE, 0);
	gtk_container_add(GTK_CONTAINER(media), vbox);

	media->priv->statusbar = gtk_statusbar_new();
	gtk_box_pack_end(GTK_BOX(vbox), media->priv->statusbar,
			FALSE, FALSE, 0);
	gtk_statusbar_push(GTK_STATUSBAR(media->priv->statusbar),
			0, _("Calling..."));
	gtk_widget_show(media->priv->statusbar);

	media->priv->menubar = setup_menubar(media);
	gtk_box_pack_start(GTK_BOX(vbox), media->priv->menubar,
			FALSE, TRUE, 0);

	media->priv->display = gtk_vbox_new(FALSE, ADIUM_HIG_BOX_SPACE);
	gtk_container_set_border_width(GTK_CONTAINER(media->priv->display),
			ADIUM_HIG_BOX_SPACE);
	gtk_box_pack_start(GTK_BOX(vbox), media->priv->display,
			TRUE, TRUE, ADIUM_HIG_BOX_SPACE);
	gtk_widget_show(vbox);

	g_signal_connect(G_OBJECT(media), "delete-event",
			G_CALLBACK(adium_media_delete_event_cb), media);
}

static gboolean
level_message_cb(GstBus *bus, GstMessage *message, AdiumMedia *gtkmedia)
{
	gdouble rms_db;
	gdouble percent;
	const GValue *list;
	const GValue *value;

	GstElement *src = GST_ELEMENT(GST_MESSAGE_SRC(message));
	GtkWidget *progress;

	if (message->type != GST_MESSAGE_ELEMENT)
		return TRUE;

	if (!gst_structure_has_name(
			gst_message_get_structure(message), "level"))
		return TRUE;

	if (src == gtkmedia->priv->send_level)
		progress = gtkmedia->priv->send_progress;
	else if (src == gtkmedia->priv->recv_level)
		progress = gtkmedia->priv->recv_progress;
	else
		return TRUE;

	list = gst_structure_get_value(
			gst_message_get_structure(message), "rms");

	/* Only bother with the first channel. */
	value = gst_value_list_get_value(list, 0);
	rms_db = g_value_get_double(value);

	percent = pow(10, rms_db / 20) * 5;

	if(percent > 1.0)
		percent = 1.0;

	gtk_progress_bar_set_fraction(GTK_PROGRESS_BAR(progress), percent);
	return TRUE;
}


static void
adium_media_disconnect_levels(PurpleMedia *media, AdiumMedia *gtkmedia)
{
	PurpleMediaManager *manager = purple_media_get_manager(media);
	GstElement *element = purple_media_manager_get_pipeline(manager);
	gulong handler_id = g_signal_handler_find(G_OBJECT(gst_pipeline_get_bus(GST_PIPELINE(element))),
						  G_SIGNAL_MATCH_FUNC | G_SIGNAL_MATCH_DATA, 0, 0, 
						  NULL, G_CALLBACK(level_message_cb), gtkmedia);
	if (handler_id)
		g_signal_handler_disconnect(G_OBJECT(gst_pipeline_get_bus(GST_PIPELINE(element))),
					    handler_id);
}

static void
adium_media_dispose(GObject *media)
{
	AdiumMedia *gtkmedia = ADIUM_MEDIA(media);
	purple_debug_info("gtkmedia", "adium_media_dispose\n");

	if (gtkmedia->priv->media) {
		purple_request_close_with_handle(gtkmedia);
		purple_media_remove_output_windows(gtkmedia->priv->media);
		adium_media_disconnect_levels(gtkmedia->priv->media, gtkmedia);
		g_object_unref(gtkmedia->priv->media);
		gtkmedia->priv->media = NULL;
	}

	if (gtkmedia->priv->item_factory) {
		g_object_unref(gtkmedia->priv->item_factory);
		gtkmedia->priv->item_factory = NULL;
	}

	if (gtkmedia->priv->send_level) {
		gst_object_unref(gtkmedia->priv->send_level);
		gtkmedia->priv->send_level = NULL;
	}

	if (gtkmedia->priv->recv_level) {
		gst_object_unref(gtkmedia->priv->recv_level);
		gtkmedia->priv->recv_level = NULL;
	}

	G_OBJECT_CLASS(parent_class)->dispose(media);
}

static void
adium_media_finalize(GObject *media)
{
	/* AdiumMedia *gtkmedia = ADIUM_MEDIA(media); */
	purple_debug_info("gtkmedia", "adium_media_finalize\n");

	G_OBJECT_CLASS(parent_class)->finalize(media);
}

static void
adium_media_emit_message(AdiumMedia *gtkmedia, const char *msg)
{
	PurpleConversation *conv = purple_find_conversation_with_account(
			PURPLE_CONV_TYPE_ANY, gtkmedia->priv->screenname,
			purple_media_get_account(gtkmedia->priv->media));
	if (conv != NULL)
		purple_conversation_write(conv, NULL, msg,
				PURPLE_MESSAGE_SYSTEM, time(NULL));
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

static void
adium_media_accept_cb(PurpleMedia *media, int index)
{
	purple_media_stream_info(media, PURPLE_MEDIA_INFO_ACCEPT,
			NULL, NULL, TRUE);
}

static void
adium_media_reject_cb(PurpleMedia *media, int index)
{
	purple_media_stream_info(media, PURPLE_MEDIA_INFO_REJECT,
			NULL, NULL, TRUE);
}

static gboolean
adium_request_timeout_cb(AdiumMedia *gtkmedia)
{
	PurpleAccount *account;
	PurpleBuddy *buddy;
	const gchar *alias;
	PurpleMediaSessionType type;
	gchar *message = NULL;

	account = purple_media_get_account(gtkmedia->priv->media);
	buddy = purple_find_buddy(account, gtkmedia->priv->screenname);
	alias = buddy ? purple_buddy_get_contact_alias(buddy) :
			gtkmedia->priv->screenname;
	type = gtkmedia->priv->request_type;
	gtkmedia->priv->timeout_id = 0;

	if (type & PURPLE_MEDIA_AUDIO && type & PURPLE_MEDIA_VIDEO) {
		message = g_strdup_printf(_("%s wishes to start an audio/video session with you."),
				alias);
	} else if (type & PURPLE_MEDIA_AUDIO) {
		message = g_strdup_printf(_("%s wishes to start an audio session with you."),
				alias);
	} else if (type & PURPLE_MEDIA_VIDEO) {
		message = g_strdup_printf(_("%s wishes to start a video session with you."),
				alias);
	}

	gtkmedia->priv->request_type = PURPLE_MEDIA_NONE;

	purple_request_accept_cancel(gtkmedia, "Media invitation",
			message, NULL, PURPLE_DEFAULT_ACTION_NONE,
			(void*)account, gtkmedia->priv->screenname, NULL,
			gtkmedia->priv->media,
			adium_media_accept_cb,
			adium_media_reject_cb);
	adium_media_emit_message(gtkmedia, message);
	g_free(message);
	return FALSE;
}

static void
#if GTK_CHECK_VERSION(2,12,0)
adium_media_input_volume_changed(GtkScaleButton *range, double value,
		PurpleMedia *media)
{
	double val = (double)value * 100.0;
#else
adium_media_input_volume_changed(GtkRange *range, PurpleMedia *media)
{
	double val = (double)gtk_range_get_value(GTK_RANGE(range));
#endif
	purple_prefs_set_int("/adium/media/audio/volume/input", val);
	purple_media_set_input_volume(media, NULL, val / 10.0);
}

static void
#if GTK_CHECK_VERSION(2,12,0)
adium_media_output_volume_changed(GtkScaleButton *range, double value,
		PurpleMedia *media)
{
	double val = (double)value * 100.0;
#else
adium_media_output_volume_changed(GtkRange *range, PurpleMedia *media)
{
	double val = (double)gtk_range_get_value(GTK_RANGE(range));
#endif
	purple_prefs_set_int("/adium/media/audio/volume/output", val);
	purple_media_set_output_volume(media, NULL, NULL, val / 10.0);
}

static GtkWidget *
adium_media_add_audio_widget(AdiumMedia *gtkmedia,
		PurpleMediaSessionType type)
{
	GtkWidget *volume_widget, *progress_parent, *volume, *progress;
	double value;

	if (type & PURPLE_MEDIA_SEND_AUDIO) {
		value = purple_prefs_get_int(
			"/adium/media/audio/volume/input");
	} else if (type & PURPLE_MEDIA_RECV_AUDIO) {
		value = purple_prefs_get_int(
			"/adium/media/audio/volume/output");
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
	PurpleMediaManager *manager = purple_media_get_manager(media);
	GstElement *pipeline = purple_media_manager_get_pipeline(manager);
	GtkWidget *send_widget = NULL, *recv_widget = NULL;
	PurpleMediaSessionType type =
			purple_media_get_session_type(media, sid);

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
		gtk_widget_show(send_widget);
	} else
		send_widget = gtkmedia->priv->send_widget;

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

		gtkmedia->priv->local_video = local_video;
	}

	if (type & PURPLE_MEDIA_RECV_AUDIO) {
		gtk_box_pack_end(GTK_BOX(recv_widget),
				adium_media_add_audio_widget(gtkmedia,
				PURPLE_MEDIA_RECV_AUDIO), FALSE, FALSE, 0);
	}
	if (type & PURPLE_MEDIA_SEND_AUDIO) {
		GstElement *media_src;
		GtkWidget *hbox;

		hbox = gtk_hbox_new(FALSE, ADIUM_HIG_BOX_SPACE);
		gtk_box_pack_end(GTK_BOX(send_widget), hbox, FALSE, FALSE, 0);
		gtkmedia->priv->mute =
				gtk_toggle_button_new_with_mnemonic("_Mute");
		g_signal_connect(gtkmedia->priv->mute, "toggled",
				G_CALLBACK(adium_media_mute_toggled),
				gtkmedia);
		gtk_box_pack_end(GTK_BOX(hbox), gtkmedia->priv->mute,
				FALSE, FALSE, 0);
		gtk_widget_show(gtkmedia->priv->mute);
		gtk_widget_show(GTK_WIDGET(hbox));

		media_src = purple_media_get_src(media, sid);
		gtkmedia->priv->send_level = gst_bin_get_by_name(
				GST_BIN(media_src), "sendlevel");

		gtk_box_pack_end(GTK_BOX(send_widget),
				adium_media_add_audio_widget(gtkmedia,
				PURPLE_MEDIA_SEND_AUDIO), FALSE, FALSE, 0);

		gtk_widget_show(gtkmedia->priv->mute);
	}


	if (type & PURPLE_MEDIA_AUDIO) {
		GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE(pipeline));
		g_signal_connect(G_OBJECT(bus), "message::element",
				G_CALLBACK(level_message_cb), gtkmedia);
		gst_object_unref(bus);
	}

	if (send_widget != NULL)
		gtkmedia->priv->send_widget = send_widget;
	if (recv_widget != NULL)
		gtkmedia->priv->recv_widget = recv_widget;

	if (purple_media_is_initiator(media, sid, NULL) == FALSE) {
		if (gtkmedia->priv->timeout_id != 0)
			g_source_remove(gtkmedia->priv->timeout_id);
		gtkmedia->priv->request_type |= type;
		gtkmedia->priv->timeout_id = g_timeout_add(500,
				(GSourceFunc)adium_request_timeout_cb,
				gtkmedia);
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
	} else if (state == PURPLE_MEDIA_STATE_CONNECTED &&
			purple_media_get_session_type(media, sid) &
			PURPLE_MEDIA_RECV_AUDIO) {
		GstElement *tee = purple_media_get_tee(media, sid, name);
		GstIterator *iter = gst_element_iterate_src_pads(tee);
		GstPad *sinkpad;
		if (gst_iterator_next(iter, (gpointer)&sinkpad)
				 == GST_ITERATOR_OK) {
			GstPad *peer = gst_pad_get_peer(sinkpad);
			if (peer != NULL) {
				gtkmedia->priv->recv_level =
						gst_bin_get_by_name(
						GST_BIN(GST_OBJECT_PARENT(
						peer)), "recvlevel");
				gst_object_unref(peer);
			}
			gst_object_unref(sinkpad);
		}
		gst_iterator_free(iter);
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
		case PROP_SEND_LEVEL:
			if (media->priv->send_level)
				gst_object_unref(media->priv->send_level);
			media->priv->send_level = g_value_get_object(value);
			g_object_ref(media->priv->send_level);
			break;
		case PROP_RECV_LEVEL:
			if (media->priv->recv_level)
				gst_object_unref(media->priv->recv_level);
			media->priv->recv_level = g_value_get_object(value);
			g_object_ref(media->priv->recv_level);
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
		case PROP_SEND_LEVEL:
			g_value_set_object(value, media->priv->send_level);
			break;
		case PROP_RECV_LEVEL:
			g_value_set_object(value, media->priv->recv_level);
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
	AdiumMedia *gtkmedia = ADIUM_MEDIA(
			adium_media_new(media, screenname));
	PurpleBuddy *buddy = purple_find_buddy(account, screenname);
	const gchar *alias = buddy ? 
			purple_buddy_get_contact_alias(buddy) : screenname; 
	gtk_window_set_title(GTK_WINDOW(gtkmedia), alias);

	if (purple_media_is_initiator(media, NULL, NULL) == TRUE)
		gtk_widget_show(GTK_WIDGET(gtkmedia));

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

	src = gst_element_factory_make("gconfvideosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("autovideosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("v4l2src", NULL);
	if (src == NULL)
		src = gst_element_factory_make("v4lsrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("ksvideosrc", NULL);
	if (src == NULL)
		src = gst_element_factory_make("dshowvideosrc", NULL);
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
	GstElement *bin, *src, *volume, *level;
	GstPad *pad, *ghost;
	double input_volume = purple_prefs_get_int(
			"/adium/media/audio/volume/input")/10.0;

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

	bin = gst_bin_new("adiumdefaultaudiosrc");
	volume = gst_element_factory_make("volume", "purpleaudioinputvolume");
	g_object_set(volume, "volume", input_volume, NULL);
	level = gst_element_factory_make("level", "sendlevel");
	gst_bin_add_many(GST_BIN(bin), src, volume, level, NULL);
	gst_element_link(src, volume);
	gst_element_link(volume, level);
	pad = gst_element_get_pad(level, "src");
	ghost = gst_ghost_pad_new("ghostsrc", pad);
	gst_element_add_pad(bin, ghost);
	g_object_set(G_OBJECT(level), "message", TRUE, NULL);

	return bin;
}

static GstElement *
create_default_audio_sink(PurpleMedia *media,
		const gchar *session_id, const gchar *participant)
{
	GstElement *bin, *sink, *volume, *level, *queue;
	GstPad *pad, *ghost;
	double output_volume = purple_prefs_get_int(
			"/adium/media/audio/volume/output")/10.0;

	sink = gst_element_factory_make("gconfaudiosink", NULL);
	if (sink == NULL)
		sink = gst_element_factory_make("autoaudiosink",NULL);
	if (sink == NULL) {
		purple_debug_error("gtkmedia", "Unable to find a suitable "
				"element for the default audio sink.\n");
		return NULL;
	}

	bin = gst_bin_new("adiumrecvaudiobin");
	volume = gst_element_factory_make("volume", "purpleaudiooutputvolume");
	g_object_set(volume, "volume", output_volume, NULL);
	level = gst_element_factory_make("level", "recvlevel");
	queue = gst_element_factory_make("queue", NULL);
	gst_bin_add_many(GST_BIN(bin), sink, volume, level, queue, NULL);
	gst_element_link(level, sink);
	gst_element_link(volume, level);
	gst_element_link(queue, volume);
	pad = gst_element_get_pad(queue, "sink");
	ghost = gst_ghost_pad_new("ghostsink", pad);
	gst_element_add_pad(bin, ghost);
	g_object_set(G_OBJECT(level), "message", TRUE, NULL);

	return bin;
}
#endif  /* USE_VV */

void
adium_medias_init(void)
{
#ifdef USE_VV
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

	purple_debug_info("gtkmedia", "Registering media element types\n");
	purple_media_manager_set_active_element(manager, default_video_src);
	purple_media_manager_set_active_element(manager, default_video_sink);
	purple_media_manager_set_active_element(manager, default_audio_src);
	purple_media_manager_set_active_element(manager, default_audio_sink);

	purple_prefs_add_none("/adium/media");
	purple_prefs_add_none("/adium/media/audio");
	purple_prefs_add_none("/adium/media/audio/volume");
	purple_prefs_add_int("/adium/media/audio/volume/input", 10);
	purple_prefs_add_int("/adium/media/audio/volume/output", 10);
#endif
}

