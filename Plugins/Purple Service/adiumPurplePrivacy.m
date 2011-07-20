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

#import "adiumPurplePrivacy.h"
#import <AIUtilities/AIObjectAdditions.h>

static void adiumPurplePermitAdded(PurpleAccount *account, const char *name)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[accountLookup(account)	privacyPermitListAdded:[NSString stringWithUTF8String:purple_normalize(account, name)]];
    [pool drain];
}
static void adiumPurplePermitRemoved(PurpleAccount *account, const char *name)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[accountLookup(account)	privacyPermitListRemoved:[NSString stringWithUTF8String:purple_normalize(account, name)]];
    [pool drain];
}
static void adiumPurpleDenyAdded(PurpleAccount *account, const char *name)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[accountLookup(account)	privacyDenyListAdded:[NSString stringWithUTF8String:purple_normalize(account, name)]];
    [pool drain];
}
static void adiumPurpleDenyRemoved(PurpleAccount *account, const char *name)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[accountLookup(account)	privacyDenyListRemoved:[NSString stringWithUTF8String:purple_normalize(account, name)]];
    [pool drain];
}

static PurplePrivacyUiOps adiumPurplePrivacyOps = {
    adiumPurplePermitAdded,
    adiumPurplePermitRemoved,
    adiumPurpleDenyAdded,
    adiumPurpleDenyRemoved,
	/* _purple_reserved 1-4 */
	NULL, NULL, NULL, NULL
};

PurplePrivacyUiOps *adium_purple_privacy_get_ui_ops()
{
	return &adiumPurplePrivacyOps;
}
