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
#import "TestRichTextCoercion.h"

#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIRichTextCoercer.h>

#import <unistd.h>
#import <sysexits.h>
#import <sys/wait.h>

@implementation TestRichTextCoercion

- (NSDictionary *)dictionaryForScriptSuiteNamed:(NSString *)suiteName fromSdefFile:(NSString *)path
{
	NSDictionary *scriptSuite = nil;

	NSFileManager *mgr = [NSFileManager defaultManager];
#warning 64BIT: Check formatting arguments
	NSString *scriptSuitesFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"AdiumTest-%u-ScriptSuites", getpid()]];
	NSLog(@"scriptSuitesFolder: %@", scriptSuitesFolder);
	if([mgr createDirectoryAtPath:scriptSuitesFolder withIntermediateDirectories:YES attributes:nil error:NULL]) {
		NSArray *args = [NSArray arrayWithObjects:
			//scriptSuite format.
			@"-f", @"s",
			//Minimum system version: Tiger. (So we specify 10.3, because it does not recognize “10.4”.)
			@"-V", @"10.3",
			//Output to our temp folder.
			@"-o", scriptSuitesFolder,
			//Input from the sdef file.
			path,
			nil];
		NSLog(@"launchedTaskWithLaunchPath:arguments: %@", args);
		NSTask *sdp = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/sdp"
											   arguments:args];
		[sdp waitUntilExit];
		STAssertEquals([sdp terminationStatus], 0, @"sdp didn't exited with status 0");

		NSString *scriptSuitePath = [scriptSuitesFolder stringByAppendingPathComponent:[suiteName stringByAppendingPathExtension:@"scriptSuite"]];
		scriptSuite = [NSDictionary dictionaryWithContentsOfFile:scriptSuitePath];
		STAssertNotNil(scriptSuite, @"No script suite named %@ in sdef file %@", suiteName, path);

		NSLog(@"deleting files in directory: %@", scriptSuitesFolder);
		[mgr removeFilesInDirectory:scriptSuitesFolder withPrefix:nil movingToTrash:NO];
		NSLog(@"deleted files in directory: %@", scriptSuitesFolder);
	}

	return scriptSuite;
}
- (NSDictionary *)dictionaryForScriptTerminologyNamed:(NSString *)suiteName fromSdefFile:(NSString *)path
{
	NSDictionary *scriptTerminology = nil;
	
	NSFileManager *mgr = [NSFileManager defaultManager];
#warning 64BIT: Check formatting arguments
	NSString *scriptTerminologiesFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"AdiumTest-%u-ScriptTerminologies", getpid()]];
	NSLog(@"scriptTerminologiesFolder: %@", scriptTerminologiesFolder);
	if([mgr createDirectoryAtPath:scriptTerminologiesFolder withIntermediateDirectories:YES attributes:nil error:NULL]) {
		NSArray *args = [NSArray arrayWithObjects:
			//scriptTerminology format.
			@"-f", @"t",
						 //Minimum system version: Tiger. (So we specify 10.3, because it does not recognize “10.4”.)
			@"-V", @"10.3",
			//Output to our temp folder.
			@"-o", scriptTerminologiesFolder,
			//Input from the sdef file.
			path,
			nil];
		NSLog(@"launchedTaskWithLaunchPath:arguments: %@", args);
		NSTask *sdp = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/sdp"
											   arguments:args];
		[sdp waitUntilExit];
		STAssertEquals([sdp terminationStatus], 0, @"sdp didn't exited with status 0");
		
		NSString *scriptTerminologyPath = [scriptTerminologiesFolder stringByAppendingPathComponent:[suiteName stringByAppendingPathExtension:@"scriptTerminology"]];
		scriptTerminology = [NSDictionary dictionaryWithContentsOfFile:scriptTerminologyPath];
		STAssertNotNil(scriptTerminology, @"No script suite named %@ in sdef file %@", suiteName, path);
		
		NSLog(@"deleting files in directory: %@", scriptTerminologiesFolder);
		[mgr removeFilesInDirectory:scriptTerminologiesFolder withPrefix:nil movingToTrash:NO];
		NSLog(@"deleted files in directory: %@", scriptTerminologiesFolder);
	}
	
	return scriptTerminology;
}
- (NSDictionary *)dictionaryByMergingSuiteDictionary:(NSDictionary *)scriptSuite withTerminologyDictionary:(NSDictionary *)scriptTerminology
{
	NSMutableDictionary *merged = [[scriptSuite mutableCopy] autorelease];

	NSMutableDictionary *classes = [[[scriptSuite objectForKey:@"Classes"] mutableCopy] autorelease];
	NSDictionary *terminologyClasses = [scriptTerminology objectForKey:@"Classes"];

	NSLog(@"Before add: %@", classes);
	NSEnumerator *keyEnum = [classes keyEnumerator];
	NSString *className;
	while ((className = [keyEnum nextObject])) {
		NSMutableDictionary *classDict = [[[classes objectForKey:className] mutableCopy] autorelease];
		[classDict translate:nil
						 add:[terminologyClasses objectForKey:className]
					  remove:nil];
		[classes setObject:classDict forKey:className];
	}
	NSLog(@" After add: %@", classes);

	[merged setObject:classes
			   forKey:@"Classes"];
	NSLog(@"Suite %C Terminology: %@", 0x222A, merged);
	return merged;
}

- (void)setUp
{
	//Load Adium.sdef in order to have the Text suite.
	NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
	NSDictionary *scriptSuite = [self dictionaryForScriptSuiteNamed:@"NSTextSuite" fromSdefFile:[testBundle pathForResource:@"Adium" ofType:@"sdef"]];
	NSDictionary *scriptTerminology = [self dictionaryForScriptTerminologyNamed:@"NSTextSuite" fromSdefFile:[testBundle pathForResource:@"Adium" ofType:@"sdef"]];
	NSDictionary *scriptSuiteAndTerminology = [self dictionaryByMergingSuiteDictionary:scriptSuite withTerminologyDictionary:scriptTerminology];
	[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuiteWithDictionary:scriptSuiteAndTerminology fromBundle:testBundle];

	[AIRichTextCoercer enableRichTextCoercion];
}

- (id)giveMeA:(Class)class ofThisString:(NSString *)str
{
	id result = nil;

	if([class isSubclassOfClass:[NSString class]]) {
		result = [class stringWithString:str];
	} else if([class isSubclassOfClass:[NSAttributedString class]]) {
		NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:12.0f] forKey:NSFontAttributeName];
		result = [[class alloc] initWithString:str attributes:attrs];
	}

	return result;
}

#pragma mark Test case methods

/*
- (void)testAttributedStringToPlainText {
	NSString *str = @"Too close for missiles; I'm switching to ducks!";

	NSAttributedString *input = [self giveMeA:[NSAttributedString class] ofThisString:str];
	NSString *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:[NSString class]];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:[NSString class]], @"Coercion to NSString must result in an NSString; instead, it resulted in an %@", [output class]);
	STAssertEqualObjects(output, input, @"Coercion must not change the object's value");
}
- (void)testMutableAttributedStringToPlainText {
	NSString *str = @"The quack is strong with this one.";

	NSMutableAttributedString *input = [self giveMeA:[NSMutableAttributedString class] ofThisString:str];
	NSString *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:[NSString class]];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:[NSString class]], @"Coercion to NSString must result in an NSString; instead, it resulted in an %@", [output class]);
	STAssertEqualObjects(output, input, @"Coercion must not change the object's value");
}
*/
- (void)testTextStorageToPlainText {
	NSString *str = @"David's gerbil";

	NSTextStorage *input = [self giveMeA:[NSTextStorage class] ofThisString:str];
	NSString *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:[NSString class]];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:[NSString class]], @"Coercion to NSString must result in an NSString; instead, it resulted in an %@", [output class]);
	STAssertEqualObjects(output, [input string], @"Coercion must not change the object's value");
}

#pragma mark -

/*- (void)testPlainTextToAttributedString {
	NSString *str = @"Now with a kitchen sink plugin.";
	Class destClass = [NSAttributedString class];

	NSString *input = [self giveMeA:[NSString class] ofThisString:str];
	NSAttributedString *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:destClass];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:destClass], @"Coercion to %@ must result in an %@; instead, it resulted in an %@", destClass, destClass, [output class]);
	STAssertEqualObjects(output, input, @"Coercion must not change the object's value");
}
- (void)testPlainTextToMutableAttributedString {
	NSString *str = @"More fun than a bag of chips.";
	Class destClass = [NSMutableAttributedString class];

	NSString *input = [self giveMeA:[NSString class] ofThisString:str];
	NSMutableAttributedString *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:destClass];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:destClass], @"Coercion to %@ must result in an %@; instead, it resulted in an %@", destClass, destClass, [output class]);
	STAssertEqualObjects(output, input, @"Coercion must not change the object's value");
}
*/
- (void)testPlainTextToTextStorage {
	NSString *str = @"Now with 30% more Zing!";
	Class destClass = [NSTextStorage class];

	NSString *input = [self giveMeA:[NSString class] ofThisString:str];
	NSTextStorage *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:destClass];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:destClass], @"Coercion to %@ must result in an %@; instead, it resulted in an %@", destClass, destClass, [output class]);
	STAssertEqualObjects([output string], input, @"Coercion must not change the object's value");
}

#pragma mark -

//Coerce the string, then mutate the original.
/*- (void)testMutableAttributedStringToPlainTextWithMutations {
	NSString *str = @"One time it got me a cookie...";

	NSMutableAttributedString *input = [self giveMeA:[NSMutableAttributedString class] ofThisString:str];
	NSString *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:[NSString class]];

	//Mutate the original.
	NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Courier" size:14.0f] forKey:NSFontAttributeName];
	NSAttributedString *replacement = [[[NSAttributedString alloc] initWithString:@" (one of the slogans from the old Adium X site)" attributes:attrs] autorelease];
	[input replaceCharactersInRange:(NSRange){ [input length], 0U }
			   withAttributedString:replacement];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:[NSString class]], @"Coercion to NSString must result in an NSString; instead, it resulted in an %@", [output class]);
	STAssertEqualObjects(output, str, @"Coercion must not change the object's value");
}
*/
- (void)testTextStorageToPlainTextWithMutations {
	NSString *str = @"The only IM client with duck 'n' cover.";

	NSTextStorage *input = [self giveMeA:[NSTextStorage class] ofThisString:str];
	NSString *output = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:input toClass:[NSString class]];

	//Mutate the original.
	NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Courier" size:14.0f] forKey:NSFontAttributeName];
	NSAttributedString *replacement = [[[NSAttributedString alloc] initWithString:@" (one of the slogans from the old Adium X site)" attributes:attrs] autorelease];
	[input replaceCharactersInRange:(NSRange){ [input length], 0U }
			   withAttributedString:replacement];

	STAssertNotNil(output, @"Coercion returned nil");
	STAssertTrue([output isKindOfClass:[NSString class]], @"Coercion to NSString must result in an NSString; instead, it resulted in an %@", [output class]);
	STAssertEqualObjects(output, str, @"Coercion must not change the object's value");
}

#pragma mark -

//Run the AppleScript “x as y”, where x is an AS object and y is an AS class.
- (void)testRichTextToPlainTextInAppleScript {
	NSString *source = 
		@"set x to (\"So you don't have to IM like it's 1999.\" as rich text)\n"
		@"x as text"
		;
#warning Implement me
}
- (void)testPlainTextToRichTextInAppleScript {
	NSString *source = 
		@"\"Ducks eat for free at Subway!\" as rich text"
		;

	NSDictionary *errorInfo = nil;
	[[[[NSAppleScript alloc] initWithSource:source] autorelease] executeAndReturnError:&errorInfo];

	STAssertNil(errorInfo, @"AppleScript returned an error: %@", errorInfo);
}

@end
