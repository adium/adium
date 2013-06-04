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
#import <libpurple/internal.h>

#import <libpurple/account.h>
#import <libpurple/accountopt.h>
#import <libpurple/buddyicon.h>
#import <libpurple/cipher.h>
#import <libpurple/conversation.h>
#import <libpurple/core.h>
#import <libpurple/debug.h>
#import <libpurple/ft.h>
#import <libpurple/imgstore.h>
#import <libpurple/network.h>
#import <libpurple/notify.h>
#import <libpurple/privacy.h>
#import <libpurple/prpl.h>
#import <libpurple/proxy.h>
#import <libpurple/request.h>
#import <libpurple/util.h>
#import <libpurple/version.h>

#import <libpurple/oscar.h>

void oscar_reformat_screenname(PurpleConnection *gc, const char *nick);
