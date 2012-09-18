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

#import "AIGaimAccountViewController.h"
#import "CBGaimAccount.h"

@implementation AIGaimAccountViewController

//Nib to load
- (NSString *)nibName{
    return @"GaimOscarAIMAccountView";
}

//Configure our controls
- (void)configureViewAfterLoad
{
	//Configure the standard controls
	[super configureViewAfterLoad];

	//Restrict the account name field to valid characters and length
    //AIM: 2 to 16 characters
    //mac.com address are an extension of AIM addresses: the username can be 2 to 16 characters
	//so we need 24 characters (16 + @mac.com) as well as the @ symbol.
    [textField_accountName setFormatter:
		[AIStringFormatter stringFormatterAllowingCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@. "]
													  length:24
											   caseSensitive:NO
												errorMessage:@"Your user name must be 24 characters or less, contain only letters and numbers, and start with a letter."]];
	
    //Put focus on the account name
    [[[view_accountView superview] window] setInitialFirstResponder:textField_accountName];	
}

@end
