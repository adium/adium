//
//  AIPurpleCertificateTrustWarningAlert.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-05.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import <Adium/AIAccount.h>
#import <Security/SecTrust.h>
#import <libpurple/libpurple.h>

@interface AIPurpleCertificateTrustWarningAlert : NSObject {
	CFArrayRef certificates;
	SecTrustRef trustRef;
	AIAccount *account;
	
	void (*query_cert_cb)(gboolean trusted, void *userdata);
	void *userdata;
	NSString *hostname;
}

+ (void)displayTrustWarningAlertWithAccount:(AIAccount*)account hostname:(NSString*)hostname certificates:(CFArrayRef)certs resultCallback:(void (*)(gboolean trusted, void *userdata))_query_cert_cb userData:(void*)ud;

@end
