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

#if	ENABLE_WEBCAM

#import "adiumPurpleWebcam.h"

#pragma mark Webcam
static void adiumPurpleWebcamNew(PurpleWebcam *gwc)
{
	AILog(@"adiumPurpleWebcamNew");
	//	PurpleGtkWebcam *c;
	//	char *tmp;
	//	
	//	c = g_new0(PurpleGtkWebcam, 1);
	//	
	//	gwc->ui_data = c;
	//	c->gwc = gwc;
	//	
	//	c->button = purple_pixbuf_button_from_stock(_("Close"), GTK_STOCK_CLOSE, PURPLE_BUTTON_HORIZONTAL);
	//	c->vbox = gtk_vbox_new(FALSE, 0);
	//	gtk_box_pack_end_defaults(GTK_BOX(c->vbox), GTK_WIDGET(c->button));
	//	
	//	c->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	//	tmp = g_strdup_printf(_("%s's Webcam"), gwc->name);
	//	gtk_window_set_title(GTK_WINDOW(c->window), tmp);
	//	g_free(tmp);
	//	
	//	gtk_container_add(GTK_CONTAINER(c->window), c->vbox);
	//	
	//	g_signal_connect(G_OBJECT(c->button), "clicked",
	//					 G_CALLBACK(purple_gtk_webcam_close_clicked), c);
	//	
	//	g_signal_connect(G_OBJECT(c->window), "destroy",
	//					 G_CALLBACK(purple_gtk_webcam_destroy), c);
	//	
	//	c->image = gtk_image_new_from_stock(PURPLE_STOCK_LOGO, gtk_icon_size_from_name(PURPLE_ICON_SIZE_LOGO));
	//	gtk_box_pack_start_defaults(GTK_BOX(c->vbox), c->image);
	//	gtk_widget_show(GTK_WIDGET(c->image));
	//	
	//	gtk_widget_show(GTK_WIDGET(c->button));
	//	gtk_widget_show(GTK_WIDGET(c->vbox));
	//	gtk_widget_show(GTK_WIDGET(c->window));
}

static NSMutableData	*frameData = nil;

static void adiumPurpleWebcamUpdate(PurpleWebcam *gwc,
								  const unsigned char *image, NSUInteger size,
								  NSUInteger timestamp, NSUInteger id)
{
	AILog(@"adiumPurpleWebcamUpdate (Frame %i , %i bytes)", id, size);
	
	if (!frameData) {
		frameData = [[NSMutableData alloc] init];		
	}
	
	[frameData appendBytes:image length:size];
	
	//	PurpleGtkWebcam *cam;
	//	WCFrame *f;
	//	GError *e = NULL;
	//	
	//	purple_debug_misc("gtkwebcam", "Got %d bytes of frame %d.\n", size, id);
	//	
	//	cam = gwc->ui_data;
	//	if (!cam)
	//		return;
	//	
	//	f = wcframe_find_by_no(cam->frames, id);
	//	if (!f) {
	//		f = wcframe_new(cam, id);
	//		cam->frames = g_list_append(cam->frames, f);
	//	}
	//	
	//	if (!gdk_pixbuf_loader_write(f->loader, image, size, &e)) {
	//		purple_debug(PURPLE_DEBUG_MISC, "gtkwebcam", "gdk_pixbuf_loader_write failed:%s\n", e->message);
	//		g_error_free(e);
	//	}
}

static void adiumPurpleWebcamFrameFinished(PurpleWebcam *wc, NSUInteger id)
{
	AILog(@"adiumPurpleWebcamFrameFinished");
	
	NSBitmapImageRep *rep;
	rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(unsigned char **)[frameData bytes]
												  pixelsWide:320
												  pixelsHigh:240
											   bitsPerSample:8
											 samplesPerPixel:3
													hasAlpha:NO
													isPlanar:NO
											  colorSpaceName:NSCalibratedRGBColorSpace
												 bytesPerRow:0
												bitsPerPixel:0]; 
	
	AILog(@"rep = %@",rep);
	
	//	[adium performSelectorOnMainThread:@selector(showImage:) withObject:rep waitUntilDone:NO];
	
	//	NSImage *tmp = [[NSImage alloc] init];
	//	[tmp addRepresentation:rep];
	
	
	
	
	
	
	//	[rep release];
	[frameData release]; frameData = nil;
	
	
	
	
	
	//	AILog(@"Bitmap?: %@",[NSImage initWithData:frameData]);
	
	//	PurpleGtkWebcam *cam;
	//	WCFrame *f;
	//	
	//	cam = wc->ui_data;
	//	if (!cam)
	//		return;
	//	f = wcframe_find_by_no(cam->frames, id);
	//	if (!f)
	//		return;
	//	
	//	gdk_pixbuf_loader_close(f->loader, NULL);
	//	f->loader = NULL;
}

static void adiumPurpleWebcamClose(PurpleWebcam *gwc)
{
	AILog(@"adiumPurpleWebcamClose");
	//	PurpleGtkWebcam *cam;
	//	
	//	cam = gwc->ui_data;
	//	if (!cam)
	//		return;
	//	
	//	cam->gwc = NULL;
	//	gwc->ui_data = NULL;
}

static void adiumPurpleWebcamGotInvite(PurpleConnection *gc, const gchar *who)
{
	AILog(@"adiumPurpleWebcamGotInvite");
	
	purple_webcam_invite_accept(gc, who);
	
	
	//	gchar *str = g_strdup_printf(_("%s has invited you (%s) to view their Webcam."), who,
	//								 purple_connection_get_display_name(gc));
	//	struct _ggwc_gcaw *g = g_new0(struct _ggwc_gcaw, 1);
	//	
	//	g->gc = gc;
	//	g->who = g_strdup(who);
	//	
	//	purple_request_action(gc, _("Webcam Invite"), str, _("Will you accept this invitation?"), 0,
	//						g, 2, _("Accept"), G_CALLBACK(_invite_accept), _("Decline"),
	//						G_CALLBACK(_invite_decline));
	//	
	//	g_free(str);
}

static struct purple_webcam_ui_ops adiumPurpleWebcamOps =
{
	adiumPurpleWebcamNew,
	adiumPurpleWebcamUpdate,
	adiumPurpleWebcamFrameFinished,
	adiumPurpleWebcamClose,
	adiumPurpleWebcamGotInvite
};

struct purple_webcam_ui_ops *adium_purple_webcam_get_ui_ops(void)
{
	return &adiumPurpleWebcamOps;
}

gboolean purple_init_j2k_plugin(void);
void initPurpleWebcamSupport(void)
{
	//Init the plugin
	purple_init_j2k_plugin();
	
	//Set the UI Ops
	purple_webcam_set_ui_ops(adium_purple_webcam_get_ui_ops());
}

#endif
