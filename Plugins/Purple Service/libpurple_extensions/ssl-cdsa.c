/*
 * CDSA SSL-plugin for purple
 *
 * Copyright (c) 2007 Andreas Monitzer <andy@monitzer.com>
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
#import <libpurple/version.h>

#define SSL_CDSA_PLUGIN_ID "ssl-cdsa"

#ifdef HAVE_CDSA

#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif

//#define CDSA_DEBUG

#import <Security/Security.h>
#import <unistd.h>

typedef struct
{
	SSLContextRef	ssl_ctx;
	guint	handshake_handler;
} PurpleSslCDSAData;

static GList *connections = NULL;

#define PURPLE_SSL_CDSA_DATA(gsc) ((PurpleSslCDSAData *)gsc->private_data)
#define PURPLE_SSL_CONNECTION_IS_VALID(gsc) (g_list_find(connections, (gsc)) != NULL)

#define PURPLE_SSL_CDSA_BUGGY_TLS_WORKAROUND "ssl_cdsa_buggy_tls_workaround"

static OSStatus ssl_cdsa_set_enabled_ciphers(SSLContextRef ctx, const SSLCipherSuite *ciphers);

/*
 * query_cert_chain - callback for letting the user review the certificate before accepting it
 *
 * gsc: The secure connection used
 * err: one of the following:
 *  errSSLUnknownRootCert—The peer has a valid certificate chain, but the root of the chain is not a known anchor certificate.
 *  errSSLNoRootCert—The peer's certificate chain was not verifiable to a root certificate.
 *  errSSLCertExpired—The peer's certificate chain has one or more expired certificates.
 *  errSSLXCertChainInvalid—The peer has an invalid certificate chain; for example, signature verification within the chain failed, or no certificates were found.
 * hostname: The name of the host to be verified (for display purposes)
 * certs: an array of values of type SecCertificateRef representing the peer certificate and the certificate chain used to validate it. The certificate at index 0 of the returned array is the peer certificate; the root certificate (or the closest certificate to it) is at the end of the returned array.
 * accept_cert: the callback to be called when the user chooses to trust this certificate chain
 * reject_cert: the callback to be called when the user does not trust this certificate chain
 * userdata: opaque pointer which has to be passed to the callbacks
 */
typedef
void (*query_cert_chain)(PurpleSslConnection *gsc, const char *hostname, CFArrayRef certs, void (*query_cert_cb)(gboolean trusted, void *userdata), void *userdata);

static query_cert_chain certificate_ui_cb = NULL;
static void ssl_cdsa_create_context(gpointer data);

/*
 * ssl_cdsa_init
 */
static gboolean
ssl_cdsa_init(void)
{
	return (TRUE);
}

/*
 * ssl_cdsa_uninit
 */
static void
ssl_cdsa_uninit(void)
{
}

struct query_cert_userdata {
	CFArrayRef certs;
	char *hostname;
	PurpleSslConnection *gsc;
	PurpleInputCondition cond;
};

static void ssl_cdsa_close(PurpleSslConnection *gsc);

static void query_cert_result(gboolean trusted, void *userdata) {
	struct query_cert_userdata *ud = (struct query_cert_userdata*)userdata;
	PurpleSslConnection *gsc = (PurpleSslConnection *)ud->gsc;
	
	CFRelease(ud->certs);
	free(ud->hostname);

	if (PURPLE_SSL_CONNECTION_IS_VALID(gsc)) {
		if (!trusted) {
			if (gsc->error_cb != NULL)
				gsc->error_cb(gsc, PURPLE_SSL_CERTIFICATE_INVALID,
							  gsc->connect_cb_data);
			
			purple_ssl_close(ud->gsc);
		} else {
			purple_debug_info("cdsa", "SSL_connect complete\n");
			
			/* SSL connected now */
			ud->gsc->connect_cb(ud->gsc->connect_cb_data, ud->gsc, ud->cond);
		}
	}

	free(ud);
}

/*
 * ssl_cdsa_handshake_cb
 */
static void
ssl_cdsa_handshake_cb(gpointer data, gint source, PurpleInputCondition cond)
{
	PurpleSslConnection *gsc = (PurpleSslConnection *)data;
	PurpleAccount *account = gsc->account;
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
    OSStatus err;
	
	purple_debug_info("cdsa", "Connecting\n");
	
	/*
	 * do the negotiation that sets up the SSL connection between
	 * here and there.
	 */
	err = SSLHandshake(cdsa_data->ssl_ctx);
    if (err == errSSLPeerBadRecordMac
		&& !purple_account_get_bool(account, PURPLE_SSL_CDSA_BUGGY_TLS_WORKAROUND, false)
		&& !strcmp(purple_account_get_protocol_id(account),"prpl-jabber")) {
        /*
         * Set a flag so we know to explicitly disable TLS 1.1 and 1.2 on our next (immediate) connection attempt for this account.
         * Some XMPP servers use buggy TLS stacks that incorrectly report their capabilities, which breaks things with 10.8's new support
         * for TLS 1.1 and 1.2.
         */
        purple_debug_info("cdsa", "SSLHandshake reported that the server rejected our MAC, which most likely means it lied about the TLS versions it supports.");
        purple_debug_info("cdsa", "Setting a flag in this account to only use TLS 1.0 and below on the next connection attempt.");
    
        purple_account_set_bool(account, PURPLE_SSL_CDSA_BUGGY_TLS_WORKAROUND, true);
        if (gsc->error_cb != NULL)
            gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED, gsc->connect_cb_data);
        purple_ssl_close(gsc);
        return;
    } else if (err != noErr) {
		if(err == errSSLWouldBlock)
			return;
		fprintf(stderr,"cdsa: SSLHandshake failed with error %d\n",(int)err);
		purple_debug_error("cdsa", "SSLHandshake failed with error %d\n",(int)err);
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
						  gsc->connect_cb_data);
		
		purple_ssl_close(gsc);
		return;
	}
		
	purple_input_remove(cdsa_data->handshake_handler);
	cdsa_data->handshake_handler = 0;
	
	purple_debug_info("cdsa", "SSL_connect: verifying certificate\n");
	
	if(certificate_ui_cb) { // does the application want to verify the certificate?
		struct query_cert_userdata *userdata = (struct query_cert_userdata*)malloc(sizeof(struct query_cert_userdata));
		size_t hostnamelen = 0;
		
		SSLGetPeerDomainNameLength(cdsa_data->ssl_ctx, &hostnamelen);
		userdata->hostname = (char*)malloc(hostnamelen+1);
		SSLGetPeerDomainName(cdsa_data->ssl_ctx, userdata->hostname, &hostnamelen);
		userdata->hostname[hostnamelen] = '\0'; // just make sure it's zero-terminated
		userdata->cond = cond;
		userdata->gsc = gsc;
		SSLCopyPeerCertificates(cdsa_data->ssl_ctx, &userdata->certs);
		
		certificate_ui_cb(gsc, userdata->hostname, userdata->certs, query_cert_result, userdata);
	} else {
		purple_debug_info("cdsa", "SSL_connect complete (did not verify certificate)\n");
		
		/* SSL connected now */
		gsc->connect_cb(gsc->connect_cb_data, gsc, cond);
	}
}

/*
 * R/W. Called out from SSL.
 */
static OSStatus SocketRead(
                    SSLConnectionRef   connection,
                    void         *data,       /* owned by 
                                               * caller, data
                                               * RETURNED */
                    size_t         *dataLength)  /* IN/OUT */ 
                    {
    NSUInteger      bytesToGo = *dataLength;
    NSUInteger       initLen = bytesToGo;
    UInt8      *currData = (UInt8 *)data;
    int        sock;
    OSStatus    rtn = noErr;
    ssize_t      bytesRead;
    ssize_t     rrtn;
    
		assert( UINT_MAX >= (NSUInteger)connection );
		sock = (int)(NSUInteger)connection;
										 
    *dataLength = 0;
    
    for(;;) {
        bytesRead = 0;
        rrtn = read(sock, currData, bytesToGo);
        if (rrtn <= 0) {
            /* this is guesswork... */
            int theErr = errno;
            switch(theErr) {
                case ENOENT:
                    /* connection closed */
                    rtn = errSSLClosedGraceful;
                    break;
                case ECONNRESET:
                    rtn = errSSLClosedAbort;
                    break;
				case 0:
                case EAGAIN:
                    rtn = errSSLWouldBlock;
                    break;
                default:
                    fprintf(stderr,"SocketRead: read(%lu) error %d\n",
							(unsigned long)bytesToGo, theErr);
                    rtn = errSSLFatalAlert;
                    break;
            }
            break;
        }
        else {
            bytesRead = rrtn;
        }
        bytesToGo -= bytesRead;
        currData  += bytesRead;
        
        if(bytesToGo == 0) {
            /* filled buffer with incoming data, done */
            break;
        }
    }
    *dataLength = initLen - bytesToGo;
    if(rtn != noErr && rtn != errSSLWouldBlock)
        fprintf(stderr,"SocketRead err = %d\n", (int)rtn);
    
    return rtn;
}

static OSStatus SocketWrite(
                     SSLConnectionRef   connection,
                     const void       *data, 
                     size_t         *dataLength)  /* IN/OUT */ 
                     {
    NSUInteger    bytesSent = 0;
    int sock;
    ssize_t    length;
    NSUInteger    dataLen = *dataLength;
    const UInt8 *dataPtr = (UInt8 *)data;
    OSStatus  ortn;

		assert( UINT_MAX >= (NSUInteger)connection );
		sock = (int)(NSUInteger)connection;
											
    *dataLength = 0;
    
    do {
        length = write(sock, 
                       (char*)dataPtr + bytesSent, 
                       dataLen - bytesSent);
    } while ((length > 0) && 
             ( (bytesSent += length) < dataLen) );
    
    if(length <= 0) {
        if(errno == EAGAIN) {
            ortn = errSSLWouldBlock;
        }
        else {
            ortn = errSSLFatalAlert;
        }
    }
    else {
        ortn = noErr;
    }
    *dataLength = bytesSent;
    return ortn;
}

static void
ssl_cdsa_create_context(gpointer data) {
    PurpleSslConnection *gsc = (PurpleSslConnection *)data;
    PurpleAccount *account = gsc->account;
	PurpleSslCDSAData *cdsa_data;
    OSStatus err;
    
    /*
	 * allocate some memory to store variables for the cdsa connection.
	 * the memory comes zero'd from g_new0 so we don't need to null the
	 * pointers held in this struct.
	 */
    cdsa_data = g_new0(PurpleSslCDSAData, 1);
	gsc->private_data = cdsa_data;
	connections = g_list_append(connections, gsc);
    
    /*
	 * allocate a new SSLContextRef object
	 */
    err = SSLNewContext(false, &cdsa_data->ssl_ctx);
	if (err != noErr) {
		purple_debug_error("cdsa", "SSLNewContext failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
		purple_ssl_close(gsc);
		return;
	}
    
    /*
     * Set up our callbacks for reading/writing the file descriptor
     */
    err = SSLSetIOFuncs(cdsa_data->ssl_ctx, SocketRead, SocketWrite);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetIOFuncs failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
		purple_ssl_close(gsc);
		return;
    }
    
    /*
     * Pass the connection information to the connection to be used by our callbacks
     */
    err = (OSStatus)SSLSetConnection(cdsa_data->ssl_ctx, (SSLConnectionRef)(intptr_t)gsc->fd);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetConnection failed\n");
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
		purple_ssl_close(gsc);
		return;
    }
    
    /*
     * Disable ciphers that confuse some servers
     */
    SSLCipherSuite ciphers[28] = {
        TLS_RSA_WITH_AES_128_CBC_SHA,
        SSL_RSA_WITH_RC4_128_SHA,
        SSL_RSA_WITH_RC4_128_MD5,
        TLS_RSA_WITH_AES_256_CBC_SHA,
        SSL_RSA_WITH_3DES_EDE_CBC_SHA,
        SSL_RSA_WITH_3DES_EDE_CBC_MD5,
        SSL_RSA_WITH_DES_CBC_SHA,
        SSL_RSA_EXPORT_WITH_RC4_40_MD5,
        SSL_RSA_EXPORT_WITH_DES40_CBC_SHA,
        SSL_RSA_EXPORT_WITH_RC2_CBC_40_MD5,
        TLS_DHE_DSS_WITH_AES_128_CBC_SHA,
        TLS_DHE_RSA_WITH_AES_128_CBC_SHA,
        TLS_DHE_DSS_WITH_AES_256_CBC_SHA,
        TLS_DHE_RSA_WITH_AES_256_CBC_SHA,
        SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA,
        SSL_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA,
        SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA,
        SSL_DHE_DSS_WITH_DES_CBC_SHA,
        SSL_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA,
        TLS_DH_anon_WITH_AES_128_CBC_SHA,
        TLS_DH_anon_WITH_AES_256_CBC_SHA,
        SSL_DH_anon_WITH_RC4_128_MD5,
        SSL_DH_anon_WITH_3DES_EDE_CBC_SHA,
        SSL_DH_anon_WITH_DES_CBC_SHA,
        SSL_DH_anon_EXPORT_WITH_RC4_40_MD5,
        SSL_DH_anon_EXPORT_WITH_DES40_CBC_SHA,
        SSL_RSA_WITH_NULL_MD5,
        SSL_NO_SUCH_CIPHERSUITE
    };
    
    err = ssl_cdsa_set_enabled_ciphers(cdsa_data->ssl_ctx, ciphers);
    if (err != noErr) {
        purple_debug_error("cdsa", "SSLSetEnabledCiphers failed\n");
        if (gsc->error_cb != NULL)
            gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
        purple_ssl_close(gsc);
        return;
    }
    
    if (purple_account_get_bool(account, PURPLE_SSL_CDSA_BUGGY_TLS_WORKAROUND, false)) {
        purple_debug_info("cdsa", "Explicitly disabling TLS 1.1 and above to try and work around buggy TLS stacks\n");
        
        OSStatus protoErr;
        protoErr = SSLSetProtocolVersionEnabled(cdsa_data->ssl_ctx, kSSLProtocolAll, false);
        if (protoErr != noErr) {
            purple_debug_error("cdsa", "SSLSetProtocolVersionEnabled failed to disable protocols\n");
            if (gsc->error_cb != NULL)
                gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED, gsc->connect_cb_data);
            purple_ssl_close(gsc);
            return;
        }
        
        protoErr = SSLSetProtocolVersionEnabled(cdsa_data->ssl_ctx, kSSLProtocol2, true);
        protoErr = SSLSetProtocolVersionEnabled(cdsa_data->ssl_ctx, kSSLProtocol3, true);
        protoErr = SSLSetProtocolVersionEnabled(cdsa_data->ssl_ctx, kTLSProtocol1, true);
    }
    
    if(gsc->host) {
        /*
         * Set the peer's domain name so CDSA can check the certificate's CN
         */
        err = SSLSetPeerDomainName(cdsa_data->ssl_ctx, gsc->host, strlen(gsc->host));
        if (err != noErr) {
            purple_debug_error("cdsa", "SSLSetPeerDomainName failed\n");
            if (gsc->error_cb != NULL)
                gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                              gsc->connect_cb_data);
            
            purple_ssl_close(gsc);
            return;
        }
    }
    
	/*
     * Disable verifying the certificate chain.
	 * We have to do that manually later on! This is the only way to be able to continue with a connection, even though the user
	 * had to manually accept the certificate.
     */
	err = SSLSetEnableCertVerify(cdsa_data->ssl_ctx, false);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetEnableCertVerify failed\n");
        /* error is not fatal */
    }
	
	cdsa_data->handshake_handler = purple_input_add(gsc->fd, PURPLE_INPUT_READ, ssl_cdsa_handshake_cb, gsc);
}

/*
 * ssl_cdsa_connect
 *
 * given a socket, put an cdsa connection around it.
 */
static void
ssl_cdsa_connect(PurpleSslConnection *gsc) {
	
    ssl_cdsa_create_context(gsc);
    
	// calling this here relys on the fact that SSLHandshake has to be called at least twice
	// to get an actual connection (first time returning errSSLWouldBlock).
	// I guess this is always the case because SSLHandshake has to send the initial greeting first, and then wait
	// for a reply from the server, which would block the connection. SSLHandshake is called again when the server
	// has sent its reply (this is achieved by the second line below)
    ssl_cdsa_handshake_cb(gsc, gsc->fd, PURPLE_INPUT_READ);
}

static void
ssl_cdsa_close(PurpleSslConnection *gsc)
{
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);

#ifdef CDSA_DEBUG
	purple_debug_info("cdsa", "Closing PurpleSslConnection %p", cdsa_data);
#endif

	if (cdsa_data == NULL)
		return;

	if (cdsa_data->handshake_handler)
		purple_input_remove(cdsa_data->handshake_handler);

	if (cdsa_data->ssl_ctx != NULL) {
        OSStatus err;
        SSLSessionState state;
        
        err = SSLGetSessionState(cdsa_data->ssl_ctx, &state);
        if(err != noErr)
            purple_debug_error("cdsa", "SSLGetSessionState failed\n");
        else if(state == kSSLConnected) {
            err = SSLClose(cdsa_data->ssl_ctx);
            if(err != noErr)
                purple_debug_error("cdsa", "SSLClose failed\n");
        }
		
#ifdef CDSA_DEBUG
		purple_debug_info("cdsa", "SSLDisposeContext(%p)", cdsa_data->ssl_ctx);
#endif

        err = SSLDisposeContext(cdsa_data->ssl_ctx);
        if(err != noErr)
            purple_debug_error("cdsa", "SSLDisposeContext failed\n");
        cdsa_data->ssl_ctx = NULL;
    }

	connections = g_list_remove(connections, gsc);

	g_free(cdsa_data);
	gsc->private_data = NULL;
}

static size_t
ssl_cdsa_read(PurpleSslConnection *gsc, void *data, size_t len)
{
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
	OSStatus	err;			/* Error info */
	size_t		processed;		/* Number of bytes processed */
	size_t		result;			/* Return value */

    errno = 0;
    err = SSLRead(cdsa_data->ssl_ctx, data, len, &processed);
	switch (err) {
		case noErr:
			result = processed;
			break;
		case errSSLWouldBlock:
			errno = EAGAIN;
			result = ((processed > 0) ? processed : -1);
			break;
		case errSSLClosedGraceful:
			result = 0;
			break;
		default:
			result = -1;
			purple_debug_error("cdsa", "receive failed (%d): %s\n", (int)err, strerror(errno));
			break;
	}

    return result;
}

static size_t
ssl_cdsa_write(PurpleSslConnection *gsc, const void *data, size_t len)
{
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
	OSStatus	err;			/* Error info */
	size_t		processed;		/* Number of bytes processed */
	size_t		result;			/* Return value */
	
	if (cdsa_data != NULL) {
#ifdef CDSA_DEBUG
		purple_debug_info("cdsa", "SSLWrite(%p, %p %i)", cdsa_data->ssl_ctx, data, len);
#endif

        err = SSLWrite(cdsa_data->ssl_ctx, data, len, &processed);
        
		switch (err) {
			case noErr:
				result = processed;
				break;
			case errSSLWouldBlock:
				errno = EAGAIN;
				result = ((processed > 0) ? processed : -1);
				break;
			case errSSLClosedGraceful:
				result = 0;
				break;
			default:
				result = -1;
				purple_debug_error("cdsa", "send failed (%d): %s\n", (int)err, strerror(errno));
				break;
		}
		
		return result;
    } else {
		return -1;
	}
}

static gboolean register_certificate_ui_cb(query_cert_chain cb) {
	certificate_ui_cb = cb;
	
	return true;
}

static gboolean copy_certificate_chain(PurpleSslConnection *gsc /* IN */, CFArrayRef *result /* OUT */) {
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED
	// this function was declared deprecated in 10.5
	return SSLGetPeerCertificates(cdsa_data->ssl_ctx, result) == noErr;
#else
	return SSLCopyPeerCertificates(cdsa_data->ssl_ctx, result) == noErr;
#endif
}

static PurpleSslOps ssl_ops = {
	ssl_cdsa_init,
	ssl_cdsa_uninit,
	ssl_cdsa_connect,
	ssl_cdsa_close,
	ssl_cdsa_read,
	ssl_cdsa_write,
	NULL, /* get_peer_certificates */
	NULL, /* reserved2 */
	NULL, /* reserved3 */
	NULL  /* reserved4 */
};

#endif /* HAVE_CDSA */

static gboolean
plugin_load(PurplePlugin *plugin)
{
#ifdef HAVE_CDSA
	if (!purple_ssl_get_ops())
		purple_ssl_set_ops(&ssl_ops);
	
	purple_plugin_ipc_register(plugin,
							   "register_certificate_ui_cb",
							   PURPLE_CALLBACK(register_certificate_ui_cb),
							   purple_marshal_BOOLEAN__POINTER,
							   purple_value_new(PURPLE_TYPE_BOOLEAN),
							   1, purple_value_new(PURPLE_TYPE_POINTER));

	purple_plugin_ipc_register(plugin,
							   "copy_certificate_chain",
							   PURPLE_CALLBACK(copy_certificate_chain),
							   purple_marshal_BOOLEAN__POINTER_POINTER,
							   purple_value_new(PURPLE_TYPE_BOOLEAN),
							   2, purple_value_new(PURPLE_TYPE_POINTER), purple_value_new(PURPLE_TYPE_POINTER));
	
	return (TRUE);
#else
	return (FALSE);
#endif
}

static gboolean
plugin_unload(PurplePlugin *plugin)
{
#ifdef HAVE_CDSA
	if (purple_ssl_get_ops() == &ssl_ops)
		purple_ssl_set_ops(NULL);
	
	purple_plugin_ipc_unregister_all(plugin);
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

	SSL_CDSA_PLUGIN_ID,				/* id */
	N_("CDSA"),					/* name */
	"0.1",					/* version */

	N_("Provides SSL support through CDSA."),	/* summary */
	N_("Provides SSL support through CDSA."),	/* description */
	"CDSA",										/* author */
	"http://www.opengroup.org/security/l2-cdsa.htm",						/* homepage */

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

PURPLE_INIT_PLUGIN(ssl_cdsa, init_plugin, info)


#pragma mark -

/*
 Method: ssl_cdsa_set_enabled_ciphers
 Source: SSLExample/sslViewer.cpp
 Contains:   SSL viewer tool, SecureTransport / OS X version.
 
 Copyright:  © Copyright 2002 Apple Computer, Inc. All rights reserved.
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under AppleÕs
 copyrights in this original Apple software (the "Apple Software"), to use,
 reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions of
 the Apple Software.  Neither the name, trademarks, service marks or logos of
 Apple Computer, Inc. may be used to endorse or promote products derived from the
 Apple Software without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or implied,
 are granted by Apple herein, including but not limited to any patent rights that
 may be infringed by your derivative works or by other works in which the Apple
 Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
 OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
 (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Return string representation of SecureTransport-related OSStatus.
 */
static const char *ssl_cdsa_sslGetSSLErrString(OSStatus err)
{
	static char noErrStr[20];
    
	switch(err) {
		case noErr:                         return "noErr";
            /*
		case memFullErr:                    return "memFullErr";
		case paramErr:                      return "paramErr";
		case unimpErr:                      return "unimpErr";
		case ioErr:                         return "ioErr";
		case badReqErr:                     return "badReqErr";
             */
            /* SSL errors */
		case errSSLProtocol:                return "errSSLProtocol";
		case errSSLNegotiation:             return "errSSLNegotiation";
		case errSSLFatalAlert:              return "errSSLFatalAlert";
		case errSSLWouldBlock:              return "errSSLWouldBlock";
		case errSSLSessionNotFound:         return "errSSLSessionNotFound";
		case errSSLClosedGraceful:          return "errSSLClosedGraceful";
		case errSSLClosedAbort:             return "errSSLClosedAbort";
		case errSSLXCertChainInvalid:       return "errSSLXCertChainInvalid";
		case errSSLBadCert:                 return "errSSLBadCert";
		case errSSLCrypto:                  return "errSSLCrypto";
		case errSSLInternal:                return "errSSLInternal";
		case errSSLModuleAttach:            return "errSSLModuleAttach";
		case errSSLUnknownRootCert:         return "errSSLUnknownRootCert";
		case errSSLNoRootCert:              return "errSSLNoRootCert";
		case errSSLCertExpired:             return "errSSLCertExpired";
		case errSSLCertNotYetValid:         return "errSSLCertNotYetValid";
		case errSSLClosedNoNotify:          return "errSSLClosedNoNotify";
		case errSSLBufferOverflow:          return "errSSLBufferOverflow";
		case errSSLBadCipherSuite:          return "errSSLBadCipherSuite";
            /* TLS/Panther addenda */
		case errSSLPeerUnexpectedMsg:       return "errSSLPeerUnexpectedMsg";
		case errSSLPeerBadRecordMac:        return "errSSLPeerBadRecordMac";
		case errSSLPeerDecryptionFail:      return "errSSLPeerDecryptionFail";
		case errSSLPeerRecordOverflow:      return "errSSLPeerRecordOverflow";
		case errSSLPeerDecompressFail:      return "errSSLPeerDecompressFail";
		case errSSLPeerHandshakeFail:       return "errSSLPeerHandshakeFail";
		case errSSLPeerBadCert:             return "errSSLPeerBadCert";
		case errSSLPeerUnsupportedCert:     return "errSSLPeerUnsupportedCert";
		case errSSLPeerCertRevoked:         return "errSSLPeerCertRevoked";
		case errSSLPeerCertExpired:         return "errSSLPeerCertExpired";
		case errSSLPeerCertUnknown:         return "errSSLPeerCertUnknown";
		case errSSLIllegalParam:            return "errSSLIllegalParam";
		case errSSLPeerUnknownCA:           return "errSSLPeerUnknownCA";
		case errSSLPeerAccessDenied:        return "errSSLPeerAccessDenied";
		case errSSLPeerDecodeError:         return "errSSLPeerDecodeError";
		case errSSLPeerDecryptError:        return "errSSLPeerDecryptError";
		case errSSLPeerExportRestriction:   return "errSSLPeerExportRestriction";
		case errSSLPeerProtocolVersion:     return "errSSLPeerProtocolVersion";
		case errSSLPeerInsufficientSecurity:return "errSSLPeerInsufficientSecurity";
		case errSSLPeerInternalError:       return "errSSLPeerInternalError";
		case errSSLPeerUserCancelled:       return "errSSLPeerUserCancelled";
		case errSSLPeerNoRenegotiation:     return "errSSLPeerNoRenegotiation";
		case errSSLHostNameMismatch:        return "errSSLHostNameMismatch";
		case errSSLConnectionRefused:       return "errSSLConnectionRefused";
		case errSSLDecryptionFail:          return "errSSLDecryptionFail";
		case errSSLBadRecordMac:            return "errSSLBadRecordMac";
		case errSSLRecordOverflow:          return "errSSLRecordOverflow";
		case errSSLBadConfiguration:        return "errSSLBadConfiguration";
            
            /* some from the Sec layer */
		case errSecNotAvailable:            return "errSecNotAvailable";
		case errSecDuplicateItem:           return "errSecDuplicateItem";
		case errSecItemNotFound:            return "errSecItemNotFound";
#if TARGET_OS_MAC
		case errSecReadOnly:                return "errSecReadOnly";
		case errSecAuthFailed:              return "errSecAuthFailed";
		case errSecNoSuchKeychain:          return "errSecNoSuchKeychain";
		case errSecInvalidKeychain:         return "errSecInvalidKeychain";
		case errSecNoSuchAttr:              return "errSecNoSuchAttr";
		case errSecInvalidItemRef:          return "errSecInvalidItemRef";
		case errSecInvalidSearchRef:        return "errSecInvalidSearchRef";
		case errSecNoSuchClass:             return "errSecNoSuchClass";
		case errSecNoDefaultKeychain:       return "errSecNoDefaultKeychain";
		case errSecWrongSecVersion:         return "errSecWrongSecVersion";
		case errSecInvalidTrustSettings:    return "errSecInvalidTrustSettings";
		case errSecNoTrustSettings:         return "errSecNoTrustSettings";
#endif
		default:
#if 0
			if (err < (CSSM_BASE_ERROR +
                       (CSSM_ERRORCODE_MODULE_EXTENT * 8)))
			{
				/* assume CSSM error */
				return cssmErrToStr(err);
			}
			else
#endif
			{
				sprintf(noErrStr, "Unknown (%d)", (unsigned)err);
				return noErrStr;
			}
	}
}

static void ssl_cdsa_printSslErrStr(
                    const char 	*op,
                    OSStatus 	err)
{
	purple_debug_error("cdsa", "%s: %s\n", op, ssl_cdsa_sslGetSSLErrString(err));
}

/*
 * Given an SSLContextRef and an array of SSLCipherSuites, terminated by
 * SSL_NO_SUCH_CIPHERSUITE, select those SSLCipherSuites which the library
 * supports and do a SSLSetEnabledCiphers() specifying those.
 */
static OSStatus ssl_cdsa_set_enabled_ciphers(SSLContextRef ctx, const SSLCipherSuite *ciphers)
{
    size_t numSupported;
    OSStatus ortn;
    SSLCipherSuite *supported = NULL;
    SSLCipherSuite *enabled = NULL;
    unsigned enabledDex = 0;    // index into enabled
    unsigned supportedDex = 0;  // index into supported
    unsigned inDex = 0;         // index into ciphers
    
    /* first get all the supported ciphers */
    ortn = SSLGetNumberSupportedCiphers(ctx, &numSupported);
    if(ortn != noErr) {
        ssl_cdsa_printSslErrStr("SSLGetNumberSupportedCiphers", ortn);
        return ortn;
    }
    supported = (SSLCipherSuite *)malloc(numSupported * sizeof(SSLCipherSuite));
    ortn = SSLGetSupportedCiphers(ctx, supported, &numSupported);
    if(ortn != noErr) {
        ssl_cdsa_printSslErrStr("SSLGetSupportedCiphers", ortn);
        return ortn;
    }
    
    /*
     * Malloc an array we'll use for SSLGetEnabledCiphers - this will  be
     * bigger than the number of suites we actually specify
     */
    enabled = (SSLCipherSuite *)malloc(numSupported * sizeof(SSLCipherSuite));
    
    /*
     * For each valid suite in ciphers, see if it's in the list of
     * supported ciphers. If it is, add it to the list of ciphers to be
     * enabled.
     */
    for(inDex=0; ciphers[inDex] != SSL_NO_SUCH_CIPHERSUITE; inDex++) {
        bool isSupported = false;
        
        for(supportedDex=0; supportedDex<numSupported; supportedDex++) {
            if(ciphers[inDex] == supported[supportedDex]) {
                enabled[enabledDex++] = ciphers[inDex];
                isSupported = true;
                break;
            }
        }

        if (!isSupported)
            purple_debug_info("cdsa", "cipher %i not supported; disabled.", ciphers[inDex]);
    }
    
    /* send it on down. */
    ortn = SSLSetEnabledCiphers(ctx, enabled, enabledDex);
    if(ortn != noErr) {
        ssl_cdsa_printSslErrStr("SSLSetEnabledCiphers", ortn);
    }
    free(enabled);
    free(supported);
    return ortn;
}

