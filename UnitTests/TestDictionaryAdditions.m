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
#import "TestDictionaryAdditions.h"

#import <AIUtilities/AIDictionaryAdditions.h>

@implementation TestDictionaryAdditions

- (NSMutableDictionary *)startingDictionary {
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInteger:0U], @"Foo",
		[NSNumber numberWithUnsignedInteger:1U], @"Bar",
		[NSNumber numberWithUnsignedInteger:2U], @"Baz",
		nil];
}
- (NSDictionary *)translation {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"Green", @"Foo",
		@"Red",   @"Bar",
		@"Blue",  @"Baz",
		nil];
}
- (NSDictionary *)addition {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInteger:3U], @"Qux",
		[NSNumber numberWithUnsignedInteger:4U], @"Quux",
		[NSNumber numberWithUnsignedInteger:5U], @"Quuux",
		nil];
}
- (NSSet *)deletia {
	return [NSSet setWithObjects:
		@"Foo",
		@"Bar",
		@"Baz",
		nil];
}

#pragma mark Test case methods

- (void)testTranslateAddRemove_translate {
	NSMutableDictionary *dict = [self startingDictionary];
	NSDictionary *translation = [self translation];

	[dict translate:translation
				add:nil
			 remove:nil];

	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Foo"]], @"translate:add:remove: method failed to translate %@ to %@", @"Foo", [translation objectForKey:@"Foo"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Bar"]], @"translate:add:remove: method failed to translate %@ to %@", @"Bar", [translation objectForKey:@"Bar"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Baz"]], @"translate:add:remove: method failed to translate %@ to %@", @"Baz", [translation objectForKey:@"Baz"]);
}

- (void)testTranslateAddRemove_add {
	NSMutableDictionary *dict = [self startingDictionary];

	[dict translate:nil
				add:[self addition]
			 remove:nil];

	STAssertNotNil([dict objectForKey:@"Foo"],   @"translate:add:remove: method failed to keep %@", @"Foo");
	STAssertNotNil([dict objectForKey:@"Bar"],   @"translate:add:remove: method failed to keep %@", @"Bar");
	STAssertNotNil([dict objectForKey:@"Baz"],   @"translate:add:remove: method failed to keep %@", @"Baz");
	STAssertNotNil([dict objectForKey:@"Qux"],   @"translate:add:remove: method failed to add %@", @"Qux");
	STAssertNotNil([dict objectForKey:@"Quux"],  @"translate:add:remove: method failed to add %@", @"Quux");
	STAssertNotNil([dict objectForKey:@"Quuux"], @"translate:add:remove: method failed to add %@", @"Quuux");
}

- (void)testTranslateAddRemove_remove {
	NSMutableDictionary *dict = [self startingDictionary];

	[dict translate:nil
				add:nil
			 remove:[self deletia]];

	STAssertNil([dict objectForKey:@"Foo"], @"translate:add:remove: method failed to remove %@", @"Foo");
	STAssertNil([dict objectForKey:@"Bar"], @"translate:add:remove: method failed to remove %@", @"Bar");
	STAssertNil([dict objectForKey:@"Baz"], @"translate:add:remove: method failed to remove %@", @"Baz");
}

#pragma mark -

- (void)testTranslateAddRemove_translateAdd {
	NSMutableDictionary *dict = [self startingDictionary];
	NSDictionary *translation = [self translation];

	[dict translate:translation
				add:[self addition]
			 remove:nil];

	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Foo"]], @"translate:add:remove: method failed to translate %@ to %@", @"Foo", [translation objectForKey:@"Foo"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Bar"]], @"translate:add:remove: method failed to translate %@ to %@", @"Bar", [translation objectForKey:@"Bar"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Baz"]], @"translate:add:remove: method failed to translate %@ to %@", @"Baz", [translation objectForKey:@"Baz"]);

	STAssertNotNil([dict objectForKey:@"Foo"],   @"translate:add:remove: method failed to keep %@", @"Foo");
	STAssertNotNil([dict objectForKey:@"Bar"],   @"translate:add:remove: method failed to keep %@", @"Bar");
	STAssertNotNil([dict objectForKey:@"Baz"],   @"translate:add:remove: method failed to keep %@", @"Baz");
	STAssertNotNil([dict objectForKey:@"Qux"],   @"translate:add:remove: method failed to add %@", @"Qux");
	STAssertNotNil([dict objectForKey:@"Quux"],  @"translate:add:remove: method failed to add %@", @"Quux");
	STAssertNotNil([dict objectForKey:@"Quuux"], @"translate:add:remove: method failed to add %@", @"Quuux");
}

- (void)testTranslateAddRemove_translateRemove {
	NSMutableDictionary *dict = [self startingDictionary];
	NSDictionary *translation = [self translation];

	[dict translate:translation
				add:nil
			 remove:[self deletia]];

	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Foo"]], @"translate:add:remove: method failed to translate %@ to %@", @"Foo", [translation objectForKey:@"Foo"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Bar"]], @"translate:add:remove: method failed to translate %@ to %@", @"Bar", [translation objectForKey:@"Bar"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Baz"]], @"translate:add:remove: method failed to translate %@ to %@", @"Baz", [translation objectForKey:@"Baz"]);

	STAssertNil([dict objectForKey:@"Foo"], @"translate:add:remove: method failed to remove %@", @"Foo");
	STAssertNil([dict objectForKey:@"Bar"], @"translate:add:remove: method failed to remove %@", @"Bar");
	STAssertNil([dict objectForKey:@"Baz"], @"translate:add:remove: method failed to remove %@", @"Baz");
}

- (void)testTranslateAddRemove_addRemove {
	NSMutableDictionary *dict = [self startingDictionary];

	[dict translate:nil
				add:[self addition]
			 remove:[self deletia]];

	STAssertNotNil([dict objectForKey:@"Qux"],   @"translate:add:remove: method failed to add %@", @"Qux");
	STAssertNotNil([dict objectForKey:@"Quux"],  @"translate:add:remove: method failed to add %@", @"Quux");
	STAssertNotNil([dict objectForKey:@"Quuux"], @"translate:add:remove: method failed to add %@", @"Quuux");

	STAssertNil([dict objectForKey:@"Foo"], @"translate:add:remove: method failed to remove %@", @"Foo");
	STAssertNil([dict objectForKey:@"Bar"], @"translate:add:remove: method failed to remove %@", @"Bar");
	STAssertNil([dict objectForKey:@"Baz"], @"translate:add:remove: method failed to remove %@", @"Baz");
}

#pragma mark -

- (void)testTranslateAddRemove_translateAddRemove {
	NSMutableDictionary *dict = [self startingDictionary];
	NSDictionary *translation = [self translation];

	[dict translate:translation
				add:[self addition]
			 remove:[self deletia]];

	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Foo"]], @"translate:add:remove: method failed to translate %@ to %@", @"Foo", [translation objectForKey:@"Foo"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Bar"]], @"translate:add:remove: method failed to translate %@ to %@", @"Bar", [translation objectForKey:@"Bar"]);
	STAssertNotNil([dict objectForKey:[translation objectForKey:@"Baz"]], @"translate:add:remove: method failed to translate %@ to %@", @"Baz", [translation objectForKey:@"Baz"]);

	STAssertNotNil([dict objectForKey:@"Qux"],   @"translate:add:remove: method failed to add %@", @"Qux");
	STAssertNotNil([dict objectForKey:@"Quux"],  @"translate:add:remove: method failed to add %@", @"Quux");
	STAssertNotNil([dict objectForKey:@"Quuux"], @"translate:add:remove: method failed to add %@", @"Quuux");

	STAssertNil([dict objectForKey:@"Foo"], @"translate:add:remove: method failed to remove %@", @"Foo");
	STAssertNil([dict objectForKey:@"Bar"], @"translate:add:remove: method failed to remove %@", @"Bar");
	STAssertNil([dict objectForKey:@"Baz"], @"translate:add:remove: method failed to remove %@", @"Baz");
}

@end
