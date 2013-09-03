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
#import <libpurple/plugin.h>
#import <libpurple/sslconn.h>
#import <libpurple/version.h>
#import <libpurple/signals.h>

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
	
	SSLCipherSuite suite;
	SSLGetNegotiatedCipher(cdsa_data->ssl_ctx, &suite);
	
	purple_debug_info("cdsa", "Using cipher %x.\n", suite);
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

static gboolean
ssl_cdsa_use_cipher(SSLCipherSuite suite) {
	switch (suite) {
		case SSL_RSA_WITH_3DES_EDE_CBC_MD5:
		case SSL_RSA_WITH_RC2_CBC_MD5:
		case SSL_RSA_WITH_3DES_EDE_CBC_SHA:
		case SSL_DH_DSS_WITH_3DES_EDE_CBC_SHA:
		case SSL_DH_RSA_WITH_3DES_EDE_CBC_SHA:
		case SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA:
		case SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA:
		case SSL_RSA_WITH_RC4_128_MD5:
		case SSL_RSA_WITH_RC4_128_SHA:
		case TLS_ECDH_ECDSA_WITH_RC4_128_SHA:
		case TLS_ECDHE_ECDSA_WITH_RC4_128_SHA:
		case TLS_ECDH_RSA_WITH_RC4_128_SHA:
		case TLS_ECDHE_RSA_WITH_RC4_128_SHA:
		case TLS_RSA_WITH_AES_128_CBC_SHA:
		case TLS_DH_DSS_WITH_AES_128_CBC_SHA:
		case TLS_DH_RSA_WITH_AES_128_CBC_SHA:
		case TLS_DHE_DSS_WITH_AES_128_CBC_SHA:
		case TLS_DHE_RSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDH_RSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA:
		case TLS_RSA_WITH_AES_256_CBC_SHA:
		case TLS_DH_DSS_WITH_AES_256_CBC_SHA:
		case TLS_DH_RSA_WITH_AES_256_CBC_SHA:
		case TLS_DHE_DSS_WITH_AES_256_CBC_SHA:
		case TLS_DHE_RSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDH_RSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:
		case TLS_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_RSA_WITH_AES_256_GCM_SHA384:
		case TLS_DHE_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_DHE_RSA_WITH_AES_256_GCM_SHA384:
		case TLS_DH_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_DH_RSA_WITH_AES_256_GCM_SHA384:
		case TLS_DHE_DSS_WITH_AES_128_GCM_SHA256:
		case TLS_DHE_DSS_WITH_AES_256_GCM_SHA384:
		case TLS_DH_DSS_WITH_AES_128_GCM_SHA256:
		case TLS_DH_DSS_WITH_AES_256_GCM_SHA384:
		case TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:
		case TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384:
		case TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:
		case TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384:
			return TRUE;
			
		default:
			return FALSE;
	}
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
    err = SSLSetConnection(cdsa_data->ssl_ctx, (SSLConnectionRef)(intptr_t)gsc->fd);
    if (err != noErr) {
		purple_debug_error("cdsa", "SSLSetConnection failed: %d\n", err);
		if (gsc->error_cb != NULL)
			gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
		purple_ssl_close(gsc);
		return;
    }
	
	size_t numCiphers = 0;
	
	err = SSLGetNumberSupportedCiphers(cdsa_data->ssl_ctx, &numCiphers);
	
	if (err != noErr) {
		purple_debug_error("cdsa", "SSLGetNumberEnabledCiphers failed: %d\n", err);
        if (gsc->error_cb != NULL)
            gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
        purple_ssl_close(gsc);
        return;
	}
	
	SSLCipherSuite ciphers[numCiphers];
    
    err = SSLGetSupportedCiphers(cdsa_data->ssl_ctx, ciphers, &numCiphers);
	if (err != noErr) {
		purple_debug_error("cdsa", "SSLGetSupportedCiphers failed: %d\n", err);
        if (gsc->error_cb != NULL)
            gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
        purple_ssl_close(gsc);
        return;
	}
	
	SSLCipherSuite enabledCiphers[numCiphers];
	size_t numEnabledCiphers = 0;
	int i;
	
	for (i = 0; i < numCiphers; i++) {
		if (ssl_cdsa_use_cipher(ciphers[i])) {
			enabledCiphers[numEnabledCiphers] = ciphers[i];
			numEnabledCiphers++;
		}
	}
	
    err = SSLSetEnabledCiphers(cdsa_data->ssl_ctx, enabledCiphers, numEnabledCiphers);
    if (err != noErr) {
        purple_debug_error("cdsa", "SSLSetEnabledCiphers failed: %d\n", err);
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
