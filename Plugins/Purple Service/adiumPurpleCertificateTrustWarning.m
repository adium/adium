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
	NSObject<AIAccountController> *accountController = [adium accountController];
	// only the jabber service supports this right now
	NSEnumerator *e = [[accountController accountsCompatibleWithService:[accountController firstServiceWithServiceID:@"Jabber"]] objectEnumerator];
	ESPurpleJabberAccount *account;
	
	while((account = [e nextObject])) {
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
