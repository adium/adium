/*	$OpenBSD: ssl-openssl.c,v 1.10 2006/10/31 19:32:51 brad Exp $	*/
/*
 * OpenSSL SSL-plugin for purple
 *
 * Copyright (c) 2004 Brad Smith <brad@comstyle.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#import <libpurple/internal.h>
#import <libpurple/debug.h>
#import <libpurple/plugin.h>
#import <libpurple/sslconn.h>
#import <libpurple/version.h>

#define SSL_OPENSSL_PLUGIN_ID "ssl-openssl"

#ifdef HAVE_OPENSSL

#import <openssl/ssl.h>
#import <openssl/err.h>

typedef struct
{
	SSL	*ssl;
	SSL_CTX	*ssl_ctx;
	guint	handshake_handler;
} PurpleSslOpensslData;

#define PURPLE_SSL_OPENSSL_DATA(gsc) ((PurpleSslOpensslData *)gsc->private_data)

/*
 * ssl_openssl_init_openssl
 *
 * load the error strings we might want to use eventually, and init the
 * openssl library
 */
static void
ssl_openssl_init_openssl(void)
{
	/*
	 * load the error number to string strings so that we can make sense
	 * of ssl issues while debugging this code
	 */
	SSL_load_error_strings();

	/*
	 * we need to initialise the openssl library
	 * we do not seed the random number generator, although we probably
	 * should in purple-win32.
	 */
	SSL_library_init();
}

/*
 * ssl_openssl_init
 */
static gboolean
ssl_openssl_init(void)
{
	return (TRUE);
}

/*
 * ssl_openssl_uninit
 *
 * couldn't find anything to match the call to SSL_library_init in the man
 * pages, i wonder if there actually is anything we need to call
 */
static void
ssl_openssl_uninit(void)
{
	ERR_free_strings();
}

/*
 * ssl_openssl_handshake_cb
 */
static void
ssl_openssl_handshake_cb(gpointer data, gint source, PurpleInputCondition cond)
{
	PurpleSslConnection *gsc = (PurpleSslConnection *)data;
	PurpleSslOpensslData *openssl_data = PURPLE_SSL_OPENSSL_DATA(gsc);
	int ret, ret2;

	purple_debug_info("openssl", "Connecting\n");

	/*
	 * do the negotiation that sets up the SSL connection between
	 * here and there.
	 */
	ret = SSL_connect(openssl_data->ssl);
	if (ret <= 0) {
		purple_debug_info("openssl", "SSL_get_error\n");
		ret2 = SSL_get_error(openssl_data->ssl, ret);

		if (ret2 == SSL_ERROR_WANT_READ || ret2 == SSL_ERROR_WANT_WRITE)
			return;

		purple_debug_error("openssl", "SSL_connect failed: %s\n", ERR_error_string(ret2, NULL));

		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
				gsc->connect_cb_data);

		purple_ssl_close(gsc);
		return;
	}

	purple_input_remove(openssl_data->handshake_handler);
	openssl_data->handshake_handler = 0;

	purple_debug_info("openssl", "SSL_connect complete\n");

	/* SSL connected now */
	gsc->connect_cb(gsc->connect_cb_data, gsc, cond);
}

/*
 * ssl_openssl_connect
 *
 * given a socket, put an openssl connection around it.
 */
static void
ssl_openssl_connect(PurpleSslConnection *gsc)
{
	PurpleSslOpensslData *openssl_data;

	/*
	 * allocate some memory to store variables for the openssl connection.
	 * the memory comes zero'd from g_new0 so we don't need to null the
	 * pointers held in this struct.
	 */
	openssl_data = g_new0(PurpleSslOpensslData, 1);
	gsc->private_data = openssl_data;

	/*
	 * allocate a new SSL_CTX object
	*/
	openssl_data->ssl_ctx = SSL_CTX_new(SSLv23_client_method());
	if (openssl_data->ssl_ctx == NULL) {
		purple_debug_error("openssl", "SSL_CTX_new failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
				gsc->connect_cb_data);

		purple_ssl_close(gsc);
		return;
	}

	/*
	 * allocate a new SSL object
	 */
	openssl_data->ssl = SSL_new(openssl_data->ssl_ctx);
	if (openssl_data->ssl == NULL) {
		purple_debug_error("openssl", "SSL_new failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
				gsc->connect_cb_data);

		purple_ssl_close(gsc);
		return;
	}

	/*
	 * now we associate the file descriptor we have with the SSL connection
	 */
	if (SSL_set_fd(openssl_data->ssl, gsc->fd) == 0) {
		purple_debug_error("openssl", "SSL_set_fd failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
				gsc->connect_cb_data);

		purple_ssl_close(gsc);
		return;
	}

	openssl_data->handshake_handler = purple_input_add(gsc->fd,
		PURPLE_INPUT_READ, ssl_openssl_handshake_cb, gsc);

	ssl_openssl_handshake_cb(gsc, gsc->fd, PURPLE_INPUT_READ);
}

static void
ssl_openssl_close(PurpleSslConnection *gsc)
{
	PurpleSslOpensslData *openssl_data = PURPLE_SSL_OPENSSL_DATA(gsc);
	int i;

	if (openssl_data == NULL)
		return;

	if (openssl_data->handshake_handler)
		purple_input_remove(openssl_data->handshake_handler);

	if (openssl_data->ssl != NULL) {
		i = SSL_shutdown(openssl_data->ssl);
		if (i == 0)
			SSL_shutdown(openssl_data->ssl);
		SSL_free(openssl_data->ssl);
	}

	if (openssl_data->ssl_ctx != NULL)
		SSL_CTX_free(openssl_data->ssl_ctx);

	g_free(openssl_data);
	gsc->private_data = NULL;
}

static size_t
ssl_openssl_read(PurpleSslConnection *gsc, void *data, size_t len)
{
	PurpleSslOpensslData *openssl_data = PURPLE_SSL_OPENSSL_DATA(gsc);
	ssize_t s;
	int ret;

	s = SSL_read(openssl_data->ssl, data, len);
	if (s <= 0) {
		ret = SSL_get_error(openssl_data->ssl, s);

		if (ret == SSL_ERROR_WANT_READ || ret == SSL_ERROR_WANT_WRITE) {
			errno = EAGAIN;
			return (-1);
		}

		purple_debug_error("openssl", "receive failed: %s\n", ERR_error_string(ret, NULL));

		if (ret == SSL_ERROR_ZERO_RETURN) {
			s = 0;
			errno = ECONNRESET;
			
		} else {
			s = -1;
			/*
			 * TODO: Set errno to something more appropriate.  Or even
			 *       better: allow ssl plugins to keep track of their
			 *       own error message, then add a new ssl_ops function
			 *       that returns the error message.
			 */
			errno = EIO;
		}
	}

	return (s);
}

static size_t
ssl_openssl_write(PurpleSslConnection *gsc, const void *data, size_t len)
{
	PurpleSslOpensslData *openssl_data = PURPLE_SSL_OPENSSL_DATA(gsc);
	ssize_t s = 0;
	int ret;

	if (openssl_data != NULL)
		s = SSL_write(openssl_data->ssl, data, len);

	if (s <= 0) {
		ret = SSL_get_error(openssl_data->ssl, s);

		if (ret == SSL_ERROR_WANT_READ || ret == SSL_ERROR_WANT_WRITE) {
			errno = EAGAIN;
			return (-1);
		}

		purple_debug_error("openssl", "send failed: %s\n", ERR_error_string(ret, NULL));

		if (ret == SSL_ERROR_ZERO_RETURN) {
			s = 0;
			errno = ECONNRESET;

		} else {
			s = -1;
			/*
			 * TODO: Set errno to something more appropriate.  Or even
			 *       better: allow ssl plugins to keep track of their
			 *       own error message, then add a new ssl_ops function
			 *       that returns the error message.
			 */
			errno = EIO;
		}
	}

	return (s);
}

static PurpleSslOps ssl_ops = {
	ssl_openssl_init,
	ssl_openssl_uninit,
	ssl_openssl_connect,
	ssl_openssl_close,
	ssl_openssl_read,
	ssl_openssl_write
};

#endif /* HAVE_OPENSSL */

static gboolean
plugin_load(PurplePlugin *plugin)
{
#ifdef HAVE_OPENSSL
	if (!purple_ssl_get_ops())
		purple_ssl_set_ops(&ssl_ops);

	/* Init OpenSSL now so others can use it even if sslconn never does */
	ssl_openssl_init_openssl();

	return (TRUE);
#else
	return (FALSE);
#endif
}

static gboolean
plugin_unload(PurplePlugin *plugin)
{
#ifdef HAVE_OPENSSL
	if (purple_ssl_get_ops() == &ssl_ops)
		purple_ssl_set_ops(NULL);
#endif

	return (TRUE);
}

static PurplePluginInfo info = {
	PURPLE_PLUGIN_MAGIC,
	PURPLE_MAJOR_VERSION,
	PURPLE_MINOR_VERSION,
	PURPLE_PLUGIN_STANDARD,				/* type */
	NULL,						/* ui_requirement */
	PURPLE_PLUGIN_FLAG_INVISIBLE,			/* flags */
	NULL,						/* dependencies */
	PURPLE_PRIORITY_DEFAULT,				/* priority */

	SSL_OPENSSL_PLUGIN_ID,				/* id */
	N_("OpenSSL"),					/* name */
	"1.0",					/* version */

	N_("Provides SSL support through OpenSSL."),	/* description */
	N_("Provides SSL support through OpenSSL."),
	"OpenSSL",
	NULL,						/* homepage */

	plugin_load,					/* load */
	plugin_unload,					/* unload */
	NULL,						/* destroy */

	NULL,						/* ui_info */
	NULL,						/* extra_info */
	NULL,						/* prefs_info */
	NULL,						/* actions */
	/* _purple_reserved 1-4 */
	NULL, NULL, NULL, NULL
};

static void
init_plugin(PurplePlugin *plugin)
{
}

PURPLE_INIT_PLUGIN(ssl_openssl, init_plugin, info)
