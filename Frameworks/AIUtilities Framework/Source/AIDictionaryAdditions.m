/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

/*
    Allows easy access to the elements of a dictionary
*/

#import "AIDictionaryAdditions.h"
#import "AIFileManagerAdditions.h"

@interface AIWriteDictionaryOperation : NSOperation 
{
	NSString *path;
	NSString *name;
	NSDictionary *dict;
}

- (AIWriteDictionaryOperation *)initWithPath:(NSString *)path name:(NSString *)s dictionary:(NSDictionary *)dict;

@end

@implementation AIWriteDictionaryOperation
- (AIWriteDictionaryOperation *)initWithPath:(NSString *)p name:(NSString *)s dictionary:(NSDictionary *)d
{
	if ((self = [super init]))
	{
		path = [p retain];
		dict = [d retain];
		name = [s retain];
	}
	return self;
}

- (void) dealloc
{
	[name release];
	[dict release];
	[path release];
	[super dealloc];
}

- (void) main
{
	[dict writeToPath:path withName:name];
}
@end

@implementation NSDictionary (AIDictionaryAdditions)

// Returns a dictionary from the owners bundle with the specified name
+ (NSDictionary *)dictionaryNamed:(NSString *)name forClass:(Class)inClass
{
    NSBundle		*ownerBundle;
    NSString		*dictPath;
    NSDictionary	*dict;

    //Get the bundle
    ownerBundle = [NSBundle bundleForClass:inClass];

    //Open the image
    dictPath = [ownerBundle pathForResource:name ofType:@"plist"];    
    dict = [NSDictionary dictionaryWithContentsOfFile:dictPath];

    return dict;
}

// returns the dictionary from the specified path
+ (NSDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create
{
    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);

	NSDictionary	*dictionary = [NSDictionary dictionaryWithContentsOfFile:[[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"]];

	if (!dictionary && create) dictionary = [NSDictionary dictionary];

    return dictionary;
}

- (BOOL)validateAsPropertyList
{
	BOOL validated = YES;
	NSEnumerator *enumerator = [self keyEnumerator];
	NSString	 *key;
	while ((key = [enumerator nextObject])) {
		if (![key isKindOfClass:[NSString class]]) {
			NSLog(@"** Dictionary failed validation: %@: Key %@ is a %@ but must be an NSString",
				  self, key, NSStringFromClass([key class]));
			validated = NO;
		}

		id value = [self objectForKey:key];
		Class valueClass = [value class];
		if (![value isKindOfClass:[NSString class]] &&
			![value isKindOfClass:[NSData class]] &&
			![value isKindOfClass:[NSNumber class]] &&
			![value isKindOfClass:[NSArray class]] &&
			![value isKindOfClass:[NSDictionary class]] &&
			![value isKindOfClass:[NSDate class]]) {
			NSLog(@"** Dictionary failed validation: %@: Value %@ is a %@ but must be a string, data, number, array, dictionary, or date",
				  self, value, NSStringFromClass(valueClass));
			validated = NO;
		}
		
		if ([value isKindOfClass:[NSArray class]] ||[value isKindOfClass:[NSDictionary class]]) {
			BOOL successOfValue = [value validateAsPropertyList];
			if (validated) validated = successOfValue;
		}
	}

return validated;
}

- (BOOL)writeToPath:(NSString *)path withName:(NSString *)name
{
	NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);

	[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL]; //make sure the path exists
	 
	 NSData *plistData;
	 NSString *retainedError = nil;
	 plistData = [NSPropertyListSerialization dataFromPropertyList:self
															format:NSPropertyListBinaryFormat_v1_0
												  errorDescription:&retainedError];
	 if (plistData) {
		 BOOL success = [plistData writeToFile:[[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"]
		 atomically:YES];
		 if (!success)
			 NSLog(@"%s: Error writing path %@, name %@ (%@)", __PRETTY_FUNCTION__, path, name, [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"]);
		 
		 return success;
	 } else {		
		 NSLog(@"%s: Could not serialize. Error: \"%@\".", __PRETTY_FUNCTION__, retainedError);
		 [self validateAsPropertyList];
		 
		 if (retainedError) [retainedError release];
		 
		 return NO;
	 }
	return YES;
}

static NSOperationQueue *dictWriterQueue;
// saves this dictionary to the specified path

- (void)asyncWriteToPath:(NSString *)path withName:(NSString *)name
{
	NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);

	if (!dictWriterQueue) {
		dictWriterQueue = [[NSOperationQueue alloc] init];
	}
	
	AIWriteDictionaryOperation *op = [[[AIWriteDictionaryOperation alloc] initWithPath:path name:name dictionary:self] autorelease];
	[dictWriterQueue addOperation:op];
}

- (NSDictionary *)dictionaryByTranslating:(NSDictionary *)translation adding:(NSDictionary *)addition removing:(NSSet *)removal
{
	NSDictionary *result;

	//only do work if we have work to do.
	if (translation || addition || removal) {
		NSMutableDictionary *mutable = [self mutableCopy];

		[mutable translate:translation add:addition remove:removal];

		result = [[self class] dictionaryWithDictionary:mutable];
		[mutable release];
	} else {
		result = [[self retain] autorelease];
	}

	return result;
}

- (NSSet *)allKeysSet {
	return [NSSet setWithArray:[self allKeys]];
}
- (NSMutableSet *)allKeysMutableSet {
	return [NSMutableSet setWithArray:[self allKeys]];
}

- (void)compareWithPriorDictionary:(NSDictionary *)other
                      getAddedKeys:(out NSSet **)outAddedKeys
                    getRemovedKeys:(out NSSet **)outRemovedKeys
                includeChangedKeys:(BOOL)flag
{
	if (!other) {
		if (outAddedKeys) *outAddedKeys = [self allKeysSet];
		if (outRemovedKeys) *outRemovedKeys = [NSSet set];
	} else {
		NSMutableSet *addedKeys = nil;
		if (outAddedKeys) {
			unsigned capacity = [self count];
			if (flag) capacity += [other count];
			addedKeys = [NSMutableSet setWithCapacity:capacity];
		}

		NSMutableSet *removedKeys = nil;
		if (outRemovedKeys) {
			unsigned capacity = [other count];
			if (flag) capacity += [self count];
			removedKeys = [NSMutableSet setWithCapacity:capacity];
		}

		NSEnumerator *keysEnum = [self keyEnumerator];
		NSString *key;
		while ((key = [keysEnum nextObject])) {
			id otherObj = [other objectForKey:key];
			if (!otherObj) {
				//Not in other, but is in self: Added.
				[addedKeys addObject:key];
			} else if(flag && ![otherObj isEqual:[self objectForKey:key]]) {
				//Exists in both, objects are not equal, and flag is not NO: Different, and we should put the key in both sets to indicate this.
				[addedKeys addObject:key];
				[removedKeys addObject:key];
			}
		}
		if (outAddedKeys) *outAddedKeys = [NSSet setWithSet:addedKeys];

		if (outRemovedKeys) {
			keysEnum = [other keyEnumerator];
			while ((key = [keysEnum nextObject])) {
				if (![self objectForKey:key]) {
					//In other, but not in self: Removed.
					[removedKeys addObject:key];
				}
			}

			*outRemovedKeys = [NSSet setWithSet:removedKeys];
		}
	}
}

- (NSDictionary *)dictionaryWithIntersectionWithSetOfKeys:(NSSet *)keys
{
	NSMutableDictionary *mutableSelf = [self mutableCopy];
	[mutableSelf intersectSetOfKeys:keys];
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:mutableSelf];
	[mutableSelf release];
	return result;
}
- (NSDictionary *)dictionaryWithDifferenceWithSetOfKeys:(NSSet *)keys
{
	NSMutableDictionary *mutableSelf = [self mutableCopy];
	[mutableSelf minusSetOfKeys:keys];
	NSDictionary *result = [NSDictionary dictionaryWithDictionary:mutableSelf];
	[mutableSelf release];
	return result;
}

- (NSString *)CSSString
{
	NSMutableArray *properties = [NSMutableArray arrayWithCapacity:[self count]];

	NSEnumerator *keysEnum = [self keyEnumerator];
	NSString *key;
	while ((key = [keysEnum nextObject])) {
		[properties addObject:[NSString stringWithFormat:@"%@: %@;", key, [self objectForKey:key]]];
	}

	return [properties componentsJoinedByString:@" "];
}

@end

@implementation NSMutableDictionary (AIDictionaryAdditions)

// returns the dictionary from the specified path
+ (NSMutableDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create
{
	NSMutableDictionary	*dictionary;
	
    NSParameterAssert(path != nil); NSParameterAssert([path length] != 0);
    NSParameterAssert(name != nil); NSParameterAssert([name length] != 0);
	
	NSData *plistData;
	NSString *error;
	
	plistData = [[NSData alloc] initWithContentsOfFile:[[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"plist"]];
	
	dictionary = [NSPropertyListSerialization propertyListFromData:plistData
												  mutabilityOption:NSPropertyListMutableContainers
															format:NULL
												  errorDescription:&error];
	[plistData release];

	if (!dictionary && create) dictionary = [NSMutableDictionary dictionary];
	
    return dictionary;
}


- (void)translate:(NSDictionary *)translation add:(NSDictionary *)addition remove:(NSSet *)removal
{
	//only do work if we have work to do.
	if (translation || addition || removal) {
		NSDictionary *selfCopy = [self copy];
		NSEnumerator *keyEnum = [selfCopy keyEnumerator];
		NSString *key;

		while ((key = [keyEnum nextObject])) {
			NSString *newKey = [translation objectForKey:key];
			if (newKey) {
				[self setObject:[selfCopy objectForKey:key] forKey:newKey];
			}

			if (removal && [removal containsObject:key]) {
				[self removeObjectForKey:key];
			}
		}

		[selfCopy release];

		//Add items that aren't in the removal set.
		keyEnum = [addition keyEnumerator];
		while ((key = [keyEnum nextObject])) {
			if (!(removal && [removal containsObject:key])) {
				[self setObject:[addition objectForKey:key] forKey:key];
			}
		}
	}
}

- (void)intersectSetOfKeys:(NSSet *)keys
{
	NSMutableArray *keysToRemove = [NSMutableArray array];
	NSEnumerator *myKeysEnum = [self keyEnumerator];
	NSString *key;
	while ((key = [myKeysEnum nextObject])) {
		if (![keys containsObject:key]) {
			[keysToRemove addObject:key];
		}
	}
	NSEnumerator *deadKeysEnum = [keysToRemove objectEnumerator];
	while ((key = [deadKeysEnum nextObject])) {
		[self removeObjectForKey:key];
	}
}
- (void)minusSetOfKeys:(NSSet *)keys
{
	NSEnumerator *keysEnum = [keys objectEnumerator];
	NSString *key;
	while ((key = [keysEnum nextObject])) {
		[self removeObjectForKey:key];
	}
}

@end
