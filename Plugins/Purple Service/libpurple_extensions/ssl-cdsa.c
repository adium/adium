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

static const char* SSLVersionToString(SSLProtocol protocol);
static const char* SSLKeyExchangeName(SSLCipherSuite suite);
static const char* SSLCipherName(SSLCipherSuite suite);
static const char* SSLMACName(SSLCipherSuite suite);

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
	
	SSLCipherSuite cipher;
	SSLProtocol protocol;
	
	err = SSLGetNegotiatedCipher(cdsa_data->ssl_ctx, &cipher);
	
	if (err == noErr) {
		err = SSLGetNegotiatedProtocolVersion(cdsa_data->ssl_ctx, &protocol);
		
		purple_debug_info("cdsa", "Your connection is using %s with %s encryption, using %s for message authentication and %s key exchange (%X).\n",
						  SSLVersionToString(protocol),
						  SSLCipherName(cipher),
						  SSLMACName(cipher),
						  SSLKeyExchangeName(cipher),
						  cipher);
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
ssl_cdsa_use_cipher(SSLCipherSuite suite, bool requireFS) {
	switch (suite) {
		case SSL_RSA_WITH_3DES_EDE_CBC_MD5:
		case SSL_RSA_WITH_RC2_CBC_MD5:
		case SSL_RSA_WITH_3DES_EDE_CBC_SHA:
		case SSL_DH_DSS_WITH_3DES_EDE_CBC_SHA:
		case SSL_DH_RSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA:
		case SSL_RSA_WITH_RC4_128_MD5:
		case SSL_RSA_WITH_RC4_128_SHA:
		case TLS_ECDH_ECDSA_WITH_RC4_128_SHA:
		case TLS_ECDH_RSA_WITH_RC4_128_SHA:
		case TLS_RSA_WITH_AES_128_CBC_SHA:
		case TLS_DH_DSS_WITH_AES_128_CBC_SHA:
		case TLS_DH_RSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDH_RSA_WITH_AES_128_CBC_SHA:
		case TLS_RSA_WITH_AES_256_CBC_SHA:
		case TLS_DH_DSS_WITH_AES_256_CBC_SHA:
		case TLS_DH_RSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDH_RSA_WITH_AES_256_CBC_SHA:
		case TLS_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_RSA_WITH_AES_256_GCM_SHA384:
		case TLS_DH_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_DH_RSA_WITH_AES_256_GCM_SHA384:
		case TLS_DH_DSS_WITH_AES_128_GCM_SHA256:
		case TLS_DH_DSS_WITH_AES_256_GCM_SHA384:
		case TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384:
		case TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384:
			return !requireFS;
		
		case SSL_DHE_DSS_WITH_3DES_EDE_CBC_SHA:
		case SSL_DHE_RSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA:
		case TLS_ECDHE_ECDSA_WITH_RC4_128_SHA:
		case TLS_ECDHE_RSA_WITH_RC4_128_SHA:
		case TLS_DHE_DSS_WITH_AES_128_CBC_SHA:
		case TLS_DHE_RSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA:
		case TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA:
		case TLS_DHE_DSS_WITH_AES_256_CBC_SHA:
		case TLS_DHE_RSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:
		case TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:
		case TLS_DHE_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_DHE_RSA_WITH_AES_256_GCM_SHA384:
		case TLS_DHE_DSS_WITH_AES_128_GCM_SHA256:
		case TLS_DHE_DSS_WITH_AES_256_GCM_SHA384:
		case TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256:
		case TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384:
		case TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:
		case TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:
		case TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:
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
	bool requireFS = purple_account_get_bool(account, "require_forward_secrecy", FALSE);
    
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
	
	err = SSLGetNumberEnabledCiphers(cdsa_data->ssl_ctx, &numCiphers);
	
	if (err != noErr) {
		purple_debug_error("cdsa", "SSLGetNumberEnabledCiphers failed: %d\n", err);
        if (gsc->error_cb != NULL)
            gsc->error_cb(gsc, PURPLE_SSL_HANDSHAKE_FAILED,
                          gsc->connect_cb_data);
        
        purple_ssl_close(gsc);
        return;
	}
	
	SSLCipherSuite ciphers[numCiphers];
    
    err = SSLGetEnabledCiphers(cdsa_data->ssl_ctx, ciphers, &numCiphers);
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
		if (ssl_cdsa_use_cipher(ciphers[i], requireFS)) {
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
	return SSLCopyPeerCertificates(cdsa_data->ssl_ctx, result) == noErr;
}

static gboolean get_cipher_details(PurpleSslConnection *gsc /* IN */, const char **ssl_info /* OUT */, const char **name /* OUT */, const char **mac /* OUT */, const char **key_exchange /* OUT */) {
	PurpleSslCDSAData *cdsa_data = PURPLE_SSL_CDSA_DATA(gsc);
	OSStatus err;
	SSLCipherSuite cipher;
	SSLProtocol protocol;
	
	err = SSLGetNegotiatedCipher(cdsa_data->ssl_ctx, &cipher);
	
	if (err != noErr) return FALSE;
	
	err = SSLGetNegotiatedProtocolVersion(cdsa_data->ssl_ctx, &protocol);
	
	if (err != noErr) return FALSE;
	
	*ssl_info = SSLVersionToString(protocol);
	*name = SSLCipherName(cipher);
	*mac = SSLMACName(cipher);
	*key_exchange = SSLKeyExchangeName(cipher);
	
	return TRUE;
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
	
	purple_plugin_ipc_register(plugin,
							   "get_cipher_details",
							   PURPLE_CALLBACK(get_cipher_details),
							   purple_marshal_BOOLEAN__POINTER_POINTER_POINTER_POINTER_POINTER,
							   purple_value_new(PURPLE_TYPE_BOOLEAN),
							   5, purple_value_new(PURPLE_TYPE_POINTER), purple_value_new(PURPLE_TYPE_POINTER),
							   purple_value_new(PURPLE_TYPE_POINTER), purple_value_new(PURPLE_TYPE_POINTER), purple_value_new(PURPLE_TYPE_POINTER));
	
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

// The following code is (loosely) based on code taken from Chromium.
// https://code.google.com/p/chromium/codesearch#chromium/src/net/ssl/ssl_cipher_suite_names.cc&sq=package:chromium

// Copyright (c) 2013 The Chromium Authors. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//    * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//    * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

static const char* SSLVersionToString(SSLProtocol protocol) {
	switch (protocol) {
		case kSSLProtocol2:
			return "SSL 2.0";
		case kSSLProtocol3:
			return "SSL 3.0";
		case kTLSProtocol1:
			return "TLS 1.0";
		case kTLSProtocol11:
			return "TLS 1.1";
		case kTLSProtocol12:
			return "TLS 1.2";
		case kDTLSProtocol1:
			return "DTLS 1.0";
		default:
			return "???";
	}
}

typedef struct {
	uint16 cipher_suite, encoded;
} CipherSuite;

static const CipherSuite kCipherSuites[] = {
	{0x0, 0x0},  // TLS_NULL_WITH_NULL_NULL
	{0x1, 0x101},  // TLS_RSA_WITH_NULL_MD5
	{0x2, 0x102},  // TLS_RSA_WITH_NULL_SHA
	{0x3, 0x209},  // TLS_RSA_EXPORT_WITH_RC4_40_MD5
	{0x4, 0x111},  // TLS_RSA_WITH_RC4_128_MD5
	{0x5, 0x112},  // TLS_RSA_WITH_RC4_128_SHA
	{0x6, 0x219},  // TLS_RSA_EXPORT_WITH_RC2_CBC_40_MD5
	{0x7, 0x122},  // TLS_RSA_WITH_IDEA_CBC_SHA
	{0x8, 0x22a},  // TLS_RSA_EXPORT_WITH_DES40_CBC_SHA
	{0x9, 0x132},  // TLS_RSA_WITH_DES_CBC_SHA
	{0xa, 0x13a},  // TLS_RSA_WITH_3DES_EDE_CBC_SHA
	{0xb, 0x32a},  // TLS_DH_DSS_EXPORT_WITH_DES40_CBC_SHA
	{0xc, 0x432},  // TLS_DH_DSS_WITH_DES_CBC_SHA
	{0xd, 0x43a},  // TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA
	{0xe, 0x52a},  // TLS_DH_RSA_EXPORT_WITH_DES40_CBC_SHA
	{0xf, 0x632},  // TLS_DH_RSA_WITH_DES_CBC_SHA
	{0x10, 0x63a},  // TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA
	{0x11, 0x72a},  // TLS_DHE_DSS_EXPORT_WITH_DES40_CBC_SHA
	{0x12, 0x832},  // TLS_DHE_DSS_WITH_DES_CBC_SHA
	{0x13, 0x83a},  // TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA
	{0x14, 0x92a},  // TLS_DHE_RSA_EXPORT_WITH_DES40_CBC_SHA
	{0x15, 0xa32},  // TLS_DHE_RSA_WITH_DES_CBC_SHA
	{0x16, 0xa3a},  // TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA
	{0x17, 0xb09},  // TLS_DH_anon_EXPORT_WITH_RC4_40_MD5
	{0x18, 0xc11},  // TLS_DH_anon_WITH_RC4_128_MD5
	{0x19, 0xb2a},  // TLS_DH_anon_EXPORT_WITH_DES40_CBC_SHA
	{0x1a, 0xc32},  // TLS_DH_anon_WITH_DES_CBC_SHA
	{0x1b, 0xc3a},  // TLS_DH_anon_WITH_3DES_EDE_CBC_SHA
	{0x2f, 0x142},  // TLS_RSA_WITH_AES_128_CBC_SHA
	{0x30, 0x442},  // TLS_DH_DSS_WITH_AES_128_CBC_SHA
	{0x31, 0x642},  // TLS_DH_RSA_WITH_AES_128_CBC_SHA
	{0x32, 0x842},  // TLS_DHE_DSS_WITH_AES_128_CBC_SHA
	{0x33, 0xa42},  // TLS_DHE_RSA_WITH_AES_128_CBC_SHA
	{0x34, 0xc42},  // TLS_DH_anon_WITH_AES_128_CBC_SHA
	{0x35, 0x14a},  // TLS_RSA_WITH_AES_256_CBC_SHA
	{0x36, 0x44a},  // TLS_DH_DSS_WITH_AES_256_CBC_SHA
	{0x37, 0x64a},  // TLS_DH_RSA_WITH_AES_256_CBC_SHA
	{0x38, 0x84a},  // TLS_DHE_DSS_WITH_AES_256_CBC_SHA
	{0x39, 0xa4a},  // TLS_DHE_RSA_WITH_AES_256_CBC_SHA
	{0x3a, 0xc4a},  // TLS_DH_anon_WITH_AES_256_CBC_SHA
	{0x3b, 0x103},  // TLS_RSA_WITH_NULL_SHA256
	{0x3c, 0x143},  // TLS_RSA_WITH_AES_128_CBC_SHA256
	{0x3d, 0x14b},  // TLS_RSA_WITH_AES_256_CBC_SHA256
	{0x3e, 0x443},  // TLS_DH_DSS_WITH_AES_128_CBC_SHA256
	{0x3f, 0x643},  // TLS_DH_RSA_WITH_AES_128_CBC_SHA256
	{0x40, 0x843},  // TLS_DHE_DSS_WITH_AES_128_CBC_SHA256
	{0x41, 0x152},  // TLS_RSA_WITH_CAMELLIA_128_CBC_SHA
	{0x42, 0x452},  // TLS_DH_DSS_WITH_CAMELLIA_128_CBC_SHA
	{0x43, 0x652},  // TLS_DH_RSA_WITH_CAMELLIA_128_CBC_SHA
	{0x44, 0x852},  // TLS_DHE_DSS_WITH_CAMELLIA_128_CBC_SHA
	{0x45, 0xa52},  // TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA
	{0x46, 0xc52},  // TLS_DH_anon_WITH_CAMELLIA_128_CBC_SHA
	{0x67, 0xa43},  // TLS_DHE_RSA_WITH_AES_128_CBC_SHA256
	{0x68, 0x44b},  // TLS_DH_DSS_WITH_AES_256_CBC_SHA256
	{0x69, 0x64b},  // TLS_DH_RSA_WITH_AES_256_CBC_SHA256
	{0x6a, 0x84b},  // TLS_DHE_DSS_WITH_AES_256_CBC_SHA256
	{0x6b, 0xa4b},  // TLS_DHE_RSA_WITH_AES_256_CBC_SHA256
	{0x6c, 0xc43},  // TLS_DH_anon_WITH_AES_128_CBC_SHA256
	{0x6d, 0xc4b},  // TLS_DH_anon_WITH_AES_256_CBC_SHA256
	{0x84, 0x15a},  // TLS_RSA_WITH_CAMELLIA_256_CBC_SHA
	{0x85, 0x45a},  // TLS_DH_DSS_WITH_CAMELLIA_256_CBC_SHA
	{0x86, 0x65a},  // TLS_DH_RSA_WITH_CAMELLIA_256_CBC_SHA
	{0x87, 0x85a},  // TLS_DHE_DSS_WITH_CAMELLIA_256_CBC_SHA
	{0x88, 0xa5a},  // TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA
	{0x89, 0xc5a},  // TLS_DH_anon_WITH_CAMELLIA_256_CBC_SHA
	{0x96, 0x162},  // TLS_RSA_WITH_SEED_CBC_SHA
	{0x97, 0x462},  // TLS_DH_DSS_WITH_SEED_CBC_SHA
	{0x98, 0x662},  // TLS_DH_RSA_WITH_SEED_CBC_SHA
	{0x99, 0x862},  // TLS_DHE_DSS_WITH_SEED_CBC_SHA
	{0x9a, 0xa62},  // TLS_DHE_RSA_WITH_SEED_CBC_SHA
	{0x9b, 0xc62},  // TLS_DH_anon_WITH_SEED_CBC_SHA
	{0x9c, 0x16f},  // TLS_RSA_WITH_AES_128_GCM_SHA256
	{0x9d, 0x177},  // TLS_RSA_WITH_AES_256_GCM_SHA384
	{0x9e, 0xa6f},  // TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
	{0x9f, 0xa77},  // TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
	{0xa0, 0x66f},  // TLS_DH_RSA_WITH_AES_128_GCM_SHA256
	{0xa1, 0x677},  // TLS_DH_RSA_WITH_AES_256_GCM_SHA384
	{0xa2, 0x86f},  // TLS_DHE_DSS_WITH_AES_128_GCM_SHA256
	{0xa3, 0x877},  // TLS_DHE_DSS_WITH_AES_256_GCM_SHA384
	{0xa4, 0x46f},  // TLS_DH_DSS_WITH_AES_128_GCM_SHA256
	{0xa5, 0x477},  // TLS_DH_DSS_WITH_AES_256_GCM_SHA384
	{0xa6, 0xc6f},  // TLS_DH_anon_WITH_AES_128_GCM_SHA256
	{0xa7, 0xc77},  // TLS_DH_anon_WITH_AES_256_GCM_SHA384
	{0xba, 0x153},  // TLS_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xbb, 0x453},  // TLS_DH_DSS_WITH_CAMELLIA_128_CBC_SHA256
	{0xbc, 0x653},  // TLS_DH_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xbd, 0x853},  // TLS_DHE_DSS_WITH_CAMELLIA_128_CBC_SHA256
	{0xbe, 0xa53},  // TLS_DHE_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xbf, 0xc53},  // TLS_DH_anon_WITH_CAMELLIA_128_CBC_SHA256
	{0xc0, 0x15b},  // TLS_RSA_WITH_CAMELLIA_256_CBC_SHA256
	{0xc1, 0x45b},  // TLS_DH_DSS_WITH_CAMELLIA_256_CBC_SHA256
	{0xc2, 0x65b},  // TLS_DH_RSA_WITH_CAMELLIA_256_CBC_SHA256
	{0xc3, 0x85b},  // TLS_DHE_DSS_WITH_CAMELLIA_256_CBC_SHA256
	{0xc4, 0xa5b},  // TLS_DHE_RSA_WITH_CAMELLIA_256_CBC_SHA256
	{0xc5, 0xc5b},  // TLS_DH_anon_WITH_CAMELLIA_256_CBC_SHA256
	{0xc001, 0xd02},  // TLS_ECDH_ECDSA_WITH_NULL_SHA
	{0xc002, 0xd12},  // TLS_ECDH_ECDSA_WITH_RC4_128_SHA
	{0xc003, 0xd3a},  // TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA
	{0xc004, 0xd42},  // TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA
	{0xc005, 0xd4a},  // TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA
	{0xc006, 0xe02},  // TLS_ECDHE_ECDSA_WITH_NULL_SHA
	{0xc007, 0xe12},  // TLS_ECDHE_ECDSA_WITH_RC4_128_SHA
	{0xc008, 0xe3a},  // TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA
	{0xc009, 0xe42},  // TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA
	{0xc00a, 0xe4a},  // TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA
	{0xc00b, 0xf02},  // TLS_ECDH_RSA_WITH_NULL_SHA
	{0xc00c, 0xf12},  // TLS_ECDH_RSA_WITH_RC4_128_SHA
	{0xc00d, 0xf3a},  // TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA
	{0xc00e, 0xf42},  // TLS_ECDH_RSA_WITH_AES_128_CBC_SHA
	{0xc00f, 0xf4a},  // TLS_ECDH_RSA_WITH_AES_256_CBC_SHA
	{0xc010, 0x1002},  // TLS_ECDHE_RSA_WITH_NULL_SHA
	{0xc011, 0x1012},  // TLS_ECDHE_RSA_WITH_RC4_128_SHA
	{0xc012, 0x103a},  // TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA
	{0xc013, 0x1042},  // TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA
	{0xc014, 0x104a},  // TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA
	{0xc015, 0x1102},  // TLS_ECDH_anon_WITH_NULL_SHA
	{0xc016, 0x1112},  // TLS_ECDH_anon_WITH_RC4_128_SHA
	{0xc017, 0x113a},  // TLS_ECDH_anon_WITH_3DES_EDE_CBC_SHA
	{0xc018, 0x1142},  // TLS_ECDH_anon_WITH_AES_128_CBC_SHA
	{0xc019, 0x114a},  // TLS_ECDH_anon_WITH_AES_256_CBC_SHA
	{0xc023, 0xe43},  // TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256
	{0xc024, 0xe4c},  // TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384
	{0xc025, 0xd43},  // TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256
	{0xc026, 0xd4c},  // TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384
	{0xc027, 0x1043},  // TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256
	{0xc028, 0x104c},  // TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
	{0xc029, 0xf43},  // TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256
	{0xc02a, 0xf4c},  // TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384
	{0xc02b, 0xe6f},  // TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
	{0xc02c, 0xe77},  // TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
	{0xc02d, 0xd6f},  // TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256
	{0xc02e, 0xd77},  // TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384
	{0xc02f, 0x106f},  // TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
	{0xc030, 0x1077},  // TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	{0xc031, 0xf6f},  // TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256
	{0xc032, 0xf77},  // TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384
	{0xc072, 0xe53},  // TLS_ECDHE_ECDSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc073, 0xe5c},  // TLS_ECDHE_ECDSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc074, 0xd53},  // TLS_ECDH_ECDSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc075, 0xd5c},  // TLS_ECDH_ECDSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc076, 0x1053},  // TLS_ECDHE_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc077, 0x105c},  // TLS_ECDHE_RSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc078, 0xf53},  // TLS_ECDH_RSA_WITH_CAMELLIA_128_CBC_SHA256
	{0xc079, 0xf5c},  // TLS_ECDH_RSA_WITH_CAMELLIA_256_CBC_SHA384
	{0xc07a, 0x17f},  // TLS_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc07b, 0x187},  // TLS_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc07c, 0xa7f},  // TLS_DHE_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc07d, 0xa87},  // TLS_DHE_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc07e, 0x67f},  // TLS_DH_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc07f, 0x687},  // TLS_DH_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc080, 0x87f},  // TLS_DHE_DSS_WITH_CAMELLIA_128_GCM_SHA256
	{0xc081, 0x887},  // TLS_DHE_DSS_WITH_CAMELLIA_256_GCM_SHA384
	{0xc082, 0x47f},  // TLS_DH_DSS_WITH_CAMELLIA_128_GCM_SHA256
	{0xc083, 0x487},  // TLS_DH_DSS_WITH_CAMELLIA_256_GCM_SHA384
	{0xc084, 0xc7f},  // TLS_DH_anon_WITH_CAMELLIA_128_GCM_SHA256
	{0xc085, 0xc87},  // TLS_DH_anon_WITH_CAMELLIA_256_GCM_SHA384
	{0xc086, 0xe7f},  // TLS_ECDHE_ECDSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc087, 0xe87},  // TLS_ECDHE_ECDSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc088, 0xd7f},  // TLS_ECDH_ECDSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc089, 0xd87},  // TLS_ECDH_ECDSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc08a, 0x107f},  // TLS_ECDHE_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc08b, 0x1087},  // TLS_ECDHE_RSA_WITH_CAMELLIA_256_GCM_SHA384
	{0xc08c, 0xf7f},  // TLS_ECDH_RSA_WITH_CAMELLIA_128_GCM_SHA256
	{0xc08d, 0xf87},  // TLS_ECDH_RSA_WITH_CAMELLIA_256_GCM_SHA384
};

static const char *kKeyExchangeNames[] = {
	"NULL",
	"RSA",
	"RSA_EXPORT",
	"DH_DSS_EXPORT",
	"DH_DSS",
	"DH_RSA_EXPORT",
	"DH_RSA",
	"DHE_DSS_EXPORT",
	"DHE_DSS",
	"DHE_RSA_EXPORT",
	"DHE_RSA",
	"DH_anon_EXPORT",
	"DH_anon",
	"ECDH_ECDSA",
	"ECDHE_ECDSA",
	"ECDH_RSA",
	"ECDHE_RSA",
	"ECDH_anon",
};

static const char *kCipherNames[] = {
	"NULL",
	"RC4_40",
	"RC4_128",
	"RC2_CBC_40",
	"IDEA_CBC",
	"DES40_CBC",
	"DES_CBC",
	"3DES_EDE_CBC",
	"AES_128_CBC",
	"AES_256_CBC",
	"CAMELLIA_128_CBC",
	"CAMELLIA_256_CBC",
	"SEED_CBC",
	"AES_128_GCM",
	"AES_256_GCM",
	"CAMELLIA_128_GCM",
	"CAMELLIA_256_GCM",
};

static const char *kMacNames[] = {
	"NULL",
	"MD5",
	"SHA1",
	"SHA256",
	"SHA384",
};

static const char* SSLKeyExchangeName(SSLCipherSuite suite) {
	int i;
	
	for (i = 0; i < sizeof(kCipherSuites) / sizeof(CipherSuite); i++) {
		if (kCipherSuites[i].cipher_suite == suite) {
			int key_exchange = kCipherSuites[i].encoded >> 8;
			
			return kKeyExchangeNames[key_exchange];
		}
	}
	
	return "???";
}

static const char* SSLCipherName(SSLCipherSuite suite) {
	int i;
	
	for (i = 0; i < sizeof(kCipherSuites) / sizeof(CipherSuite); i++) {
		if (kCipherSuites[i].cipher_suite == suite) {
			int cipher = (kCipherSuites[i].encoded >> 3) & 0x1f;
			
			return kCipherNames[cipher];
		}
	}
	
	return "???";
}

static const char* SSLMACName(SSLCipherSuite suite) {
	int i;
	
	for (i = 0; i < sizeof(kCipherSuites) / sizeof(CipherSuite); i++) {
		if (kCipherSuites[i].cipher_suite == suite) {
			int mac = kCipherSuites[i].encoded & 0x07;
			
			return kMacNames[mac];
		}
	}
	
	return "???";
}
