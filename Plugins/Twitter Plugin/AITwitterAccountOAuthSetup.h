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

#import "AITwitterAccount.h"

typedef enum {
	AIOAuthStepFailure = 0,
	
	AIOAuthStepStart,
	AIOAuthStepRequestToken,
	AIOAuthStepVerifyingRequest,
	AIOAuthStepAccessToken,
} AIOAuthSetupStep;


@protocol AITwitterAccountOAuthSetupDelegate;

@interface AITwitterAccountOAuthSetup : NSObject {
	id delegate;
	
	AITwitterAccount *account;
	
	OAConsumer	*consumer;
	OAToken		*requestToken;
	
	NSString	*verifier;
}

- (id)initWithDelegate:(id <AITwitterAccountOAuthSetupDelegate>)inDelegate
			forAccount:(AITwitterAccount *)inAccount;

@property (retain, nonatomic) NSString *verifier;

- (void)beginSetup;
- (void)fetchAccessToken;
@end

@protocol AITwitterAccountOAuthSetupDelegate
- (void)OAuthSetup:(AITwitterAccountOAuthSetup *)setup changedToStep:(AIOAuthSetupStep)setupStep withToken:(OAToken *)token responseBody:(NSString *)body;
@end
