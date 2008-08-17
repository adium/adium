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

#import "AIPurpleGTalkAccountViewController.h"


@implementation AIPurpleGTalkAccountViewController

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	//GTalk forces the use of TLS
	[checkBox_useTLS setEnabled:NO];
	
	[checkBox_checkMail setEnabled:YES];
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	[textField_connectServer setStringValue:@"talk.google.com"];
	[textField_connectServer setEditable:NO];
	[textField_connectServer setBordered:NO];
	[textField_connectServer setDrawsBackground:NO];
}

@end
