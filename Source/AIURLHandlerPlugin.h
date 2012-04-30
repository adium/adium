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


#define AIURLHandleNotification			@"AIURLHandleNotification"

#define PREF_KEY_ENFORCE_DEFAULT		@"Enforce Adium as Default"
#define PREF_KEY_SET_DEFAULT_FIRST_TIME @"AdiumURLHandling:CompletedFirstLaunch" // The old variable value, so we don't do this again.
#define ADIUM_BUNDLE_ID					@"com.adiumx.adiumx"
#define GROUP_URL_HANDLING				@"URL Handling Group"

@interface AIURLHandlerPlugin : AIPlugin

// Enforcement
- (void)setAdiumAsDefault;

// Schemes
- (NSString *)serviceIDForScheme:(NSString *)scheme;
- (NSArray *)allSchemesLikeScheme:(NSString *)scheme;
- (NSArray *)uniqueSchemes;
- (NSArray *)helperSchemes;

// Applications
- (void)setDefaultForScheme:(NSString *)inScheme toBundleID:(NSString *)bundleID;
- (NSString *)defaultApplicationBundleIDForScheme:(NSString *)scheme;

+ (AIURLHandlerPlugin *)sharedAIURLHandlerPlugin;

@end
