//
//  AIPurpleCertificateViewer.h
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-04.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//


@class AIAccount;

@interface AIPurpleCertificateViewer : NSObject {
	CFArrayRef certificatechain;
	
	AIAccount *account;
}

+ (void)displayCertificateChain:(CFArrayRef)cc forAccount:(AIAccount*)account;

@end
