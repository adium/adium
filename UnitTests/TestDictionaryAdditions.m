#import "TestDictionaryAdditions.h"

#import <AIUtilities/AIDictionaryAdditions.h>

@implementation TestDictionaryAdditions

- (NSMutableDictionary *)startingDictionary {
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt:0U], @"Foo",
		[NSNumber numberWithUnsignedInt:1U], @"Bar",
		[NSNumber numberWithUnsignedInt:2U], @"Baz",
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
		[NSNumber numberWithUnsignedInt:3U], @"Qux",
		[NSNumber numberWithUnsignedInt:4U], @"Quux",
		[NSNumber numberWithUnsignedInt:5U], @"Quuux",
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
