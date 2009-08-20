//
//  AIPurpleCertificateViewer.m
//  Adium
//
//  Created by Andreas Monitzer on 2007-11-04.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "AIPurpleCertificateViewer.h"
#import <SecurityInterface/SFCertificatePanel.h>
#import <Adium/AIAccountControllerProtocol.h>

@interface AIPurpleCertificateViewer (privateMethods)

- (id)initWithCertificateChain:(CFArrayRef)cc forAccount:(AIAccount*)_account;
- (IBAction)showWindow:(id)sender;

@end

@implementation AIPurpleCertificateViewer

+ (void)displayCertificateChain:(CFArrayRef)cc forAccount:(AIAccount*)account {
	AIPurpleCertificateViewer *viewer = [[self alloc] initWithCertificateChain:cc forAccount:account];
	[viewer showWindow:nil];
	[viewer release];
}

- (id)initWithCertificateChain:(CFArrayRef)cc forAccount:(AIAccount*)_account {
	if((self = [super init])) {
		certificatechain = cc;
		CFRetain(certificatechain);
		account = _account;
	}
	return [self retain];
}

- (void)dealloc {
	CFRelease(certificatechain);
	[super dealloc];
}

- (IBAction)showWindow:(id)sender {
	[adium.accountController editAccount:account onWindow:nil notifyingTarget:self];
}

- (void)editAccountWindow:(NSWindow*)window didOpenForAccount:(AIAccount *)inAccount {
	SFCertificatePanel *panel = [[SFCertificatePanel alloc] init];
	[panel beginSheetForWindow:window modalDelegate:self didEndSelector:@selector(certificateSheetDidEnd:returnCode:contextInfo:) contextInfo:window certificates:(NSArray*)certificatechain showGroup:YES];
}

- (void)certificateSheetDidEnd:(SFCertificatePanel*)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSWindow *win = (NSWindow*)contextInfo;
	[panel release];
	[win performSelector:@selector(performClose:) withObject:nil afterDelay:0.0];
}

@end
