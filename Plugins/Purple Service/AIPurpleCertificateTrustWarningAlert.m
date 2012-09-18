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

#import "AIPurpleCertificateTrustWarningAlert.h"
#import <SecurityInterface/SFCertificateTrustPanel.h>
#import <Security/SecureTransport.h>
#import <Security/SecPolicySearch.h>
#import <Security/SecPolicy.h>
#import <Security/oidsalg.h>
#import <Adium/AIAccountControllerProtocol.h>
#import "ESPurpleJabberAccount.h"
#import "AIPurpleGTalkAccount.h"

//#define ALWAYS_SHOW_TRUST_WARNING

static NSMutableDictionary *acceptedCertificates = nil;

@interface AIPurpleCertificateTrustWarningAlert ()
- (id)initWithAccount:(AIAccount*)account
			 hostname:(NSString*)hostname
		 certificates:(CFArrayRef)certs
	   resultCallback:(void (*)(gboolean trusted, void *userdata))_query_cert_cb
			 userData:(void*)ud;
- (IBAction)showWindow:(id)sender;
- (void)runTrustPanelOnWindow:(NSWindow *)window;
- (void)certificateTrustSheetDidEnd:(SFCertificateTrustPanel *)trustpanel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@interface SFCertificateTrustPanel (SecretsIKnow)
- (void)setInformativeText:(NSString *)inString;
@end

@implementation AIPurpleCertificateTrustWarningAlert

+ (void)displayTrustWarningAlertWithAccount:(AIAccount *)account
								   hostname:(NSString *)hostname
							   certificates:(CFArrayRef)certs
							 resultCallback:(void (*)(gboolean trusted, void *userdata))_query_cert_cb
								   userData:(void*)ud
{
	if ([hostname caseInsensitiveCompare:@"talk.google.com"] == NSOrderedSame &&
		![[account preferenceForKey:KEY_JABBER_FORCE_OLD_SSL group:GROUP_ACCOUNT_STATUS] boolValue]) {
		NSString *UID = account.UID;
		NSRange startOfDomain = [UID rangeOfString:@"@"];

		if (startOfDomain.location == NSNotFound ||
			([[UID substringFromIndex:NSMaxRange(startOfDomain)] caseInsensitiveCompare:@"gmail.com"] == NSOrderedSame)) {
			/* Google Talk accounts end up with a cert signed using gmail.com as the server.
			 * However, Google For Domains accounts are signed using talk.google.com
			 */
			hostname = @"gmail.com";
		} else if ([[UID substringFromIndex:NSMaxRange(startOfDomain)] caseInsensitiveCompare:@"googlemail.com"] == NSOrderedSame) {
			/* There are three certificates, as far as I (am) know. Maybe we should ask Sean for confirmation. */
			hostname = @"googlemail.com";
		}
	}

	AIPurpleCertificateTrustWarningAlert *alert = [[self alloc] initWithAccount:account hostname:hostname certificates:certs resultCallback:_query_cert_cb userData:ud];
	[alert showWindow:nil];
	[alert release];
}

- (id)initWithAccount:(AIAccount*)_account
			 hostname:(NSString*)_hostname
		 certificates:(CFArrayRef)certs
	   resultCallback:(void (*)(gboolean trusted, void *userdata))_query_cert_cb
			 userData:(void*)ud
{
	if((self = [super init])) {
		if(!acceptedCertificates)
			acceptedCertificates = [[NSMutableDictionary alloc] init];
		query_cert_cb = _query_cert_cb;
		
		certificates = certs;
		CFRetain(certificates);
		
		account = _account;
		hostname = [_hostname copy];
		
		userdata = ud;
	}
	return [self retain];
}

- (void)dealloc {
	CFRelease(certificates);
	[hostname release];
	[super dealloc];
}

- (IBAction)showWindow:(id)sender {
	OSStatus err;
	SecPolicySearchRef searchRef = NULL;
	SecPolicyRef policyRef;
	
	CSSM_DATA data;
	err = SecCertificateGetData((SecCertificateRef)CFArrayGetValueAtIndex(certificates, 0), &data);
	if(err == noErr) {
		// Did we ask the user to confirm this certificate before?
		// Note that this information is not stored on the disk, which is on purpose.
		NSUInteger oldCertHash = [[acceptedCertificates objectForKey:hostname] unsignedIntegerValue];
		if (oldCertHash) {
			NSData *certData = [[NSData alloc] initWithBytesNoCopy:data.Data length:data.Length freeWhenDone:NO];
			NSUInteger newCertHash = [certData hash];
			[certData release];
			
			if (oldCertHash == newCertHash) {
				query_cert_cb(true, userdata);
				[self release];
				return;
			}
		}
	}
		
	
	err = SecPolicySearchCreate(CSSM_CERT_X_509v3, &CSSMOID_APPLE_TP_SSL, NULL, &searchRef);
	if(err != noErr) {
		NSBeep();
		[self release];
		return;
	}
	
	err = SecPolicySearchCopyNext(searchRef, &policyRef);
	if(err != noErr) {
		CFRelease(searchRef);
		NSBeep();
		[self release];
		return;
	}

	NSAssert( UINT_MAX > [hostname length],
					 @"More string data than libpurple can handle.  Abort." );
	
	CSSM_APPLE_TP_SSL_OPTIONS ssloptions = {
		.Version = CSSM_APPLE_TP_SSL_OPTS_VERSION,
		.ServerNameLen = (UInt32)([hostname length]+1),
		.ServerName = [hostname cStringUsingEncoding:NSASCIIStringEncoding],
		.Flags = 0
	};
	
	CSSM_DATA theCssmData = {
		.Length = sizeof(ssloptions),
		.Data = (uint8*)&ssloptions 
	};
	
	SecPolicySetValue(policyRef, &theCssmData); // Don't care about the error
	
	err = SecTrustCreateWithCertificates(certificates, policyRef, &trustRef);

	if(err != noErr) {
		CFRelease(searchRef);
		CFRelease(policyRef);
		if (trustRef)
			CFRelease(trustRef);
		NSBeep();
		[self release];
		return;
	}
		
	// test whether we aren't already trusting this certificate
	SecTrustResultType result;
	err = SecTrustEvaluate(trustRef, &result);
	if(err == noErr) {
		// with help from http://lists.apple.com/archives/Apple-cdsa/2006/Apr/msg00013.html
		switch(result) {
			case kSecTrustResultProceed: // trust ok, go right ahead
			case kSecTrustResultUnspecified: // trust ok, user has no particular opinion about this
#ifndef ALWAYS_SHOW_TRUST_WARNING
				query_cert_cb(true, userdata);
				[self autorelease];
				break;
#endif
			case kSecTrustResultConfirm: // trust ok, but user asked (earlier) that you check with him before proceeding
			case kSecTrustResultDeny: // trust ok, but user previously said not to trust it anyway
			case kSecTrustResultRecoverableTrustFailure: // trust broken, perhaps argue with the user
			case kSecTrustResultOtherError: // failure other than trust evaluation; e.g., internal failure of the SecTrustEvaluate function. We'll let the user decide where to go from here.
			{
				
#if 1
				//Show on an independent window.
#define TRUST_PANEL_WIDTH 535
				NSWindow *fakeWindow = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, TRUST_PANEL_WIDTH, 1)
																	styleMask:(NSTitledWindowMask | NSMiniaturizableWindowMask)
																	  backing:NSBackingStoreBuffered
																		defer:NO] autorelease];
				[fakeWindow center];
				[fakeWindow setTitle:AILocalizedString(@"Verify Certificate", nil)];

				[self runTrustPanelOnWindow:fakeWindow];
				[fakeWindow makeKeyAndOrderFront:nil];
#else
				//Show as a sheet on the account's preferences
				[adium.accountController editAccount:account onWindow:nil notifyingTarget:self];
#endif
				break;
			}
			default:
				/*
				 * kSecTrustResultFatalTrustFailure -> trust broken, user can't fix it
				 * kSecTrustResultInvalid -> logic error; fix your program (SecTrust was used incorrectly)
				 */
				query_cert_cb(false, userdata);
				[self autorelease];
				break;
		}
	} else {
		query_cert_cb(false, userdata);
		[self autorelease];
	}

	CFRelease(searchRef);
	CFRelease(policyRef);
	CFRelease(trustRef);
}

/*
 * Function: SSLSecPolicyCopy
 * Purpose:
 *   Returns a copy of the SSL policy.
 */
static SecPolicyRef SSLSecPolicyCopy()
{
	SecPolicyRef policy = NULL;
	SecPolicySearchRef policy_search;
	OSStatus status;
	
	status = SecPolicySearchCreate(CSSM_CERT_X_509v3, &CSSMOID_APPLE_TP_SSL, NULL, &policy_search);
	if (status == noErr) {
		status = SecPolicySearchCopyNext(policy_search, &policy);
		if (status != noErr) policy = NULL;
	}

	CFRelease(policy_search);
	
	return policy;
}

- (void)runTrustPanelOnWindow:(NSWindow *)window
{
	SFCertificateTrustPanel *trustPanel = [[SFCertificateTrustPanel alloc] init];
	
	// this could probably be used for a more detailed message:
	//	CFArrayRef certChain;
	//	CSSM_TP_APPLE_EVIDENCE_INFO *statusChain;
	//	err = SecTrustGetResult(trustRef, &result, &certChain, &statusChain);
	
	NSString *title;
	NSString *informativeText = [NSString stringWithFormat:AILocalizedString(@"The certificate of the server %@ is not trusted, which means that the server's identity cannot be automatically verified. Do you want to continue connecting?\n\nFor more information, click \"Show Certificate\".",nil), hostname];
	if ([trustPanel respondsToSelector:@selector(setInformativeText:)]) {
		[trustPanel setInformativeText:informativeText];
		title = [NSString stringWithFormat:AILocalizedString(@"Adium can't verify the identity of \"%@\".", nil), hostname];
	} else {
		/* We haven't seen a version of SFCertificateTrustPanel which doesn't respond to setInformativeText:, but we're using a private
		 * call found via class-dump, so have a sane backup strategy in case it changes.
		 */
		title = informativeText;
	}

	[trustPanel setAlternateButtonTitle:AILocalizedString(@"Cancel",nil)];
	[trustPanel setShowsHelp:YES];

	SecPolicyRef sslPolicy = SSLSecPolicyCopy();
	if (sslPolicy) {
		[trustPanel setPolicies:(id)sslPolicy];
		CFRelease(sslPolicy);
	}

	[trustPanel beginSheetForWindow:window
					  modalDelegate:self
					 didEndSelector:@selector(certificateTrustSheetDidEnd:returnCode:contextInfo:)
						contextInfo:window
							  trust:trustRef
							message:title];	
}


- (void)editAccountWindow:(NSWindow *)window didOpenForAccount:(AIAccount *)inAccount
{
	[self runTrustPanelOnWindow:window];	
}

- (void)certificateTrustSheetDidEnd:(SFCertificateTrustPanel *)trustpanel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	BOOL didTrustCerficate = (returnCode == NSOKButton);
	NSWindow *parentWindow = (NSWindow *)contextInfo;

	query_cert_cb(didTrustCerficate, userdata);
	/* If the user confirmed this cert, we store this information until the app is closed so the user doesn't have to re-confirm it every time
	 * (doing otherwise might be particularily annoying on auto-reconnect)
	 */
	if (didTrustCerficate) {
		CSSM_DATA certdata;
		OSStatus err = SecCertificateGetData((SecCertificateRef)CFArrayGetValueAtIndex(certificates, 0), &certdata);
		if(err == noErr) {
			[acceptedCertificates setObject:[NSNumber numberWithUnsignedInteger:[[NSData dataWithBytes:certdata.Data length:certdata.Length] hash]]
									 forKey:hostname];
		}
	}

	[trustpanel release];
	CFRelease(trustRef);

	[parentWindow performClose:nil];
	
	[self release];
}

@end
