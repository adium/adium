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

#import "TestNSData+Base64.h"
#import "NSData+Base64.h"

@implementation TestNSData_Base64

- (void)testBase64Encode
{
	NSString *decodedString = @"abcdefghijklmnopqrstuvwxyz1234567890!@#$%^&";
	NSData *decodedData = [decodedString dataUsingEncoding:NSUTF8StringEncoding];
	NSString *expectedEncodedString = @"YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY3ODkwIUAjJCVeJg==";
	NSString *actualEncodedString = [decodedData base64EncodedString];
	STAssertTrue([expectedEncodedString isEqualToString:actualEncodedString], nil);
	
	decodedString = @"☃";
	decodedData = [decodedString dataUsingEncoding:NSUTF8StringEncoding];
	expectedEncodedString = @"4piD";
	actualEncodedString = [decodedData base64EncodedString];
	STAssertTrue([expectedEncodedString isEqualToString:actualEncodedString], nil);
}

- (void)testBase64Decode
{
	NSString *encodedString = @"YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY3ODkwIUAjJCVeJg==";
	NSString *decodedString = @"abcdefghijklmnopqrstuvwxyz1234567890!@#$%^&";
	NSData *encodedData = [decodedString dataUsingEncoding:NSUTF8StringEncoding];
	NSData *decodedData = [NSData dataFromBase64String:encodedString];
	STAssertTrue([encodedData isEqualToData:decodedData], nil);
	
	encodedString = @"4piD";
	decodedString = @"☃";
	encodedData = [decodedString dataUsingEncoding:NSUTF8StringEncoding];
	decodedData = [NSData dataFromBase64String:encodedString];
	STAssertTrue([encodedData isEqualToData:decodedData], nil);
}

@end
