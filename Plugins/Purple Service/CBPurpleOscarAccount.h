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

#import "CBPurpleAccount.h"
#import <libpurple/oscar.h>

//From oscar.c
#define OSCAR_STATUS_ID_INVISIBLE	"invisible"
#define OSCAR_STATUS_ID_OFFLINE		"offline"
#define OSCAR_STATUS_ID_AVAILABLE	"available"
#define OSCAR_STATUS_ID_AWAY		"away"
#define OSCAR_STATUS_ID_DND			"dnd"
#define OSCAR_STATUS_ID_NA			"na"
#define OSCAR_STATUS_ID_OCCUPIED	"occupied"
#define OSCAR_STATUS_ID_FREE4CHAT	"free4chat"
#define OSCAR_STATUS_ID_CUSTOM		"custom"

#define PREFERENCE_ALLOW_MULTIPLE_LOGINS @"Allow Multiple Logins"
#define PREFERENCE_FT_PROXY_SERVER	@"Always Use FT Proxy"

// obsolete, migrate to PREFERENCE_ENCRYPTION_TYPE
#define PREFERENCE_SSL_CONNECTION	@"Connect Using SSL"

#define PREFERENCE_ENCRYPTION_TYPE	@"Encryption Type"

#define PREFERENCE_ENCRYPTION_TYPE_OPPORTUNISTIC @"Opportunistic Encryption"
#define PREFERENCE_ENCRYPTION_TYPE_REQUIRED @"Require Encryption"
#define PREFERENCE_ENCRYPTION_TYPE_NO @"No Encryption"

@interface CBPurpleOscarAccount : CBPurpleAccount  <AIAccount_Files> {
	NSTimer			*delayedSignonUpdateTimer;
	NSMutableArray  *arrayOfContactsForDelayedUpdates;
	
	NSMutableDictionary	*directIMQueue;
	NSMutableSet		*purpleImagesToUnref;
}

@end
