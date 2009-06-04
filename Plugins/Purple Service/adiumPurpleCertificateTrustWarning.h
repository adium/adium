/*
 *  adiumPurpleCertificateTrustWarning.h
 *  Adium
 *
 *  Created by Andreas Monitzer on 2007-11-05.
 *  Copyright 2007 Andreas Monitzer. All rights reserved.
 *
 */

#import <CoreFoundation/CoreFoundation.h>
#import <libpurple/libpurple.h>

void adium_query_cert_chain(PurpleSslConnection *gsc, const char *hostname, CFArrayRef certs, void (*query_cert_cb)(gboolean trusted, void *userdata), void *userdata);
