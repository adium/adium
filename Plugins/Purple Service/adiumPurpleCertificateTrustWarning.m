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

#import "adiumPurpleCertificateTrustWarning.h"
#import "AIPurpleCertificateTrustWarningAlert.h"

#import <Adium/AIAccountControllerProtocol.h>
#import "ESPurpleJabberAccount.h"

void adium_query_cert_chain(PurpleSslConnection *gsc, const char *hostname, CFArrayRef certs, void (*query_cert_cb)(gboolean trusted, void *userdata), void *userdata) {
	@autoreleasepool {
		
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
}
