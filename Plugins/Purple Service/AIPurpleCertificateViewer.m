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

#import "AIPurpleCertificateViewer.h"
#import <SecurityInterface/SFCertificatePanel.h>
#import <Adium/AIAccountControllerProtocol.h>

@interface AIPurpleCertificateViewer (privateMethods)

- (id)initWithCertificateChain:(CFArrayRef)cc forAccount:(AIAccount*)_account;
- (IBAction)showWindow:(id)sender;
- (void)certificateSheetDidEnd:(SFCertificatePanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

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

- (void)certificateSheetDidEnd:(SFCertificatePanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSWindow *win = (NSWindow*)contextInfo;
	[panel release];
	[win performSelector:@selector(performClose:) withObject:nil afterDelay:0.0];
}

@end
