/*
 *  adiumPurpleCertificateTrustWarning.m
 *  Adium
 *
 *  Created by Andreas Monitzer on 2007-11-05.
 *  Copyright 2007 Andreas Monitzer. All rights reserved.
 *
 */

#import "adiumPurpleCertificateTrustWarning.h"
#import "AIPurpleCertificateTrustWarningAlert.h"

#import <Adium/AIAccount.h>
#import <Adium/AIAccountControllerProtocol.h>
#import "ESPurpleJabberAccount.h"

void adium_query_cert_chain(PurpleSslConnection *gsc, const char *hostname, CFArrayRef certs, void (*query_cert_cb)(gboolean trusted, void *userdata), void *userdata) {
	// only the jabber service supports this right now
	for (ESPurpleJabberAccount *account in [adium.accountController accountsCompatibleWithService:[adium.accountController firstServiceWithServiceID:@"Jabber"]]) {
		if([account secureConnection] == gsc) {
			if([account shouldVerifyCertificates])
				[AIPurpleCertificateTrustWarningAlert displayTrustWarningAlertWithAccount:account
																				 hostname:[NSString stringWithUTF8String:hostname]
																			 certificates:certs
																		   resultCallback:query_cert_cb
																				 userData:userdata];
			else
				query_cert_cb(true, userdata);
			return;
		}
	}
	// default fallback
	query_cert_cb(true, userdata);
}
