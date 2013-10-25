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
#import "TestMutableStringAdditions.h"
#import "AIUnitTestUtilities.h"

#import <AIUtilities/AIMutableStringAdditions.h>

@implementation TestMutableStringAdditions

- (void)testReplaceOccurrencesOfString_withString_options
{
	NSMutableString *testString = [NSMutableString stringWithString:@"The quick brown fox jumped over the other quick brown fox"];
	
	//first make the string longer
	[testString replaceOccurrencesOfString:@"brown" withString:@"kinda lime-green with a bit of ecru" options:NSLiteralSearch];
	AISimplifiedAssertEqualObjects([NSMutableString stringWithString:@"The quick kinda lime-green with a bit of ecru fox jumped over the other quick kinda lime-green with a bit of ecru fox"], 
								   testString, 
								   @"Modified string wasn't equal to hand-made modified string");
	
	//next, try replacing something at the end; if the range didn't expand, this will fail
	[testString replaceOccurrencesOfString:@"fox" withString:@"aardvark" options:NSLiteralSearch];
	AISimplifiedAssertEqualObjects([NSMutableString stringWithString:@"The quick kinda lime-green with a bit of ecru aardvark jumped over the other quick kinda lime-green with a bit of ecru aardvark"], 
								   testString, 
								   @"After making the string longer, modifications no longer took into account the full length");
}

@end
