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

#import <Adium/AIAccountControllerProtocol.h>

@class AIAccount;

@interface AdiumPasswords : NSObject {

}

- (void)controllerDidLoad;

//Accounts
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;
- (NSString *)passwordForAccount:(AIAccount *)inAccount;
- (void)passwordForAccount:(AIAccount *)inAccount
			  promptOption:(AIPromptOption)promptOption
		   notifyingTarget:(id)inTarget
				  selector:(SEL)inSelector
				   context:(id)inContext;

//Proxy Servers
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName;
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName;
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;

//Special passwords
- (void)passwordForType:(AISpecialPasswordType)inType forAccount:(AIAccount *)inAccount promptOption:(AIPromptOption)inOption name:(NSString *)inName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;
- (NSString *)passwordForType:(AISpecialPasswordType)inType forAccount:(AIAccount *)inAccount name:(NSString *)inName;
- (void)setPassword:(NSString *)inPassword forType:(AISpecialPasswordType)inType forAccount:(AIAccount *)inAccount name:(NSString *)inName;
@end
