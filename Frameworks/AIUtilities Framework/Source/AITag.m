//
//  AITag.m
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-01-14.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "AITag.h"
#include <sys/param.h>

NSString *AITag_TagNameKey = @"Tag name";
NSString *AITag_AttributeNamesKey = @"Attribute names";
NSString *AITag_AttributeValuesKey = @"Attribute values";
NSString *AITag_ContentsKey = @"Contents";

@implementation AITag

+ (id)tagWithName:(NSString *)newName
   attributeNames:(NSArray *)newAttributeNames
  attributeValues:(NSArray *)newAttributeValues
         contents:(NSArray *)newContents
{
	return [[[self alloc] initWithName:newName
	                    attributeNames:newAttributeNames
	                   attributeValues:newAttributeValues
	                          contents:newContents] autorelease];
}

+ (id)tagWithDictionaryRepresentation:(NSDictionary *)dict
{
	return [[[self alloc] initWithDictionaryRepresentation:dict] autorelease];
}
+ (id)tagWithArrayRepresentation:(NSArray *)array
{
	return [[[self alloc] initWithArrayRepresentation:array] autorelease];
}
+ (id)tagWithPropertyList:(id)plist
{
	return [[[self alloc] initWithPropertyList:plist] autorelease];
}

#pragma mark -

- (id)initWithName:(NSString *)newName
    attributeNames:(NSArray *)newAttributeNames
   attributeValues:(NSArray *)newAttributeValues
          contents:(NSArray *)newContents
{
	if ((self = [super init])) {
		name = [newName copy];
		attributeNames = [newAttributeNames mutableCopy];
		attributeValues = [newAttributeValues mutableCopy];
		contents = [newContents mutableCopy];
	}
	return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict
{
	return [self initWithName:[dict objectForKey:AITag_TagNameKey]
	           attributeNames:[dict objectForKey:AITag_AttributeNamesKey]
	          attributeValues:[dict objectForKey:AITag_AttributeValuesKey]
	          	     contents:[dict objectForKey:AITag_ContentsKey]];
}
- (id)initWithArrayRepresentation:(NSArray *)array
{
	NSParameterAssert([array count] == 4);
	return [self initWithName:[array objectAtIndex:0]
	           attributeNames:[array objectAtIndex:1]
	          attributeValues:[array objectAtIndex:2]
	          	     contents:[array objectAtIndex:3]];
}
//pass a dictionary or array.
- (id)initWithPropertyList:(id)plist {
	if ([plist isKindOfClass:[NSArray class]]) {
		return [self initWithArrayRepresentation:plist];
	} else if ([plist isKindOfClass:[NSDictionary class]]) {
		return [self initWithDictionaryRepresentation:plist];
	} else {
		NSString *format = @"Attempt was made to initialize AITag %p with a property list that was neither an array nor a dictionary\n"
			@"---Description of property list %p follows\n"
			@"%@\n"
			@"---End description of property list %p";
		NSLog(format, self, plist, plist, plist);

		[self release];
		return nil;
	}
}

#pragma mark -

- (id)propertyList {
	return [self dictionaryRepresentation];
}
- (NSDictionary *)dictionaryRepresentation {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		name, AITag_TagNameKey,
		[NSArray arrayWithArray:attributeNames], AITag_AttributeNamesKey,
		[NSArray arrayWithArray:attributeValues], AITag_AttributeValuesKey,
		[NSArray arrayWithArray:contents], AITag_ContentsKey,
		nil];
}
- (NSArray *)arrayRepresentation {
	return [NSArray arrayWithObjects:
		name,
		[NSArray arrayWithArray:attributeNames],
		[NSArray arrayWithArray:attributeValues],
		[NSArray arrayWithArray:contents],
		nil];
}

#pragma mark -

- (unsigned)hash
{
	unsigned hash = [name hash];
	NSEnumerator *objEnum = [attributeNames objectEnumerator];
	id obj;
	while ((obj = [objEnum nextObject])) {
		hash ^= [obj hash];
	}
	objEnum = [attributeValues objectEnumerator];
	while ((obj = [objEnum nextObject])) {
		hash ^= [obj hash];
	}
	objEnum = [contents objectEnumerator];
	while ((obj = [objEnum nextObject])) {
		hash ^= [obj hash];
	}
	return hash;
}
- (BOOL)isEqualToTag:(AITag *)other
{
	return [name isEqualToString:other->name] \
		&& [attributeNames isEqualToArray:other->attributeNames] \
		&& [attributeValues isEqualToArray:other->attributeValues] \
		&& [contents isEqualToArray:other->contents];
}
- (BOOL)isEqual:(id)other
{
	if (![other isKindOfClass:[AITag class]]) {
		//not an AITag? can't be equal.
		return NO;
	} else {
		return [self isEqualToTag:other];
	}
}

#pragma mark -
#pragma mark Tag name

- (NSString *)name
{
	return name;
}
- (void)setName:(NSString *)newName
{
	[name release];
	name = [newName copy];
}

#pragma mark -
#pragma mark Attributes

- (unsigned)countAttributes
{
	unsigned  numNames =  [attributeNames count];
	unsigned numValues = [attributeValues count];
	return MIN(numNames, numValues);
}
- (void)attributeAtIndex:(unsigned)index name:(out NSString **)outName value:(out NSString **)outValue
{
	if (outName)  *outName  =  [attributeNames objectAtIndex:index];
	if (outValue) *outValue = [attributeValues objectAtIndex:index];
}
- (void)replaceAttributeAtIndex:(unsigned)index name:(NSString *)newAttrName value:(NSString *)newAttrValue
{
	NSParameterAssert(newAttrName != nil);
	NSParameterAssert(newAttrValue != nil);
	NSParameterAssert((index < [attributeNames count]) && (index < [attributeValues count]));

	[attributeNames  replaceObjectAtIndex:index withObject:newAttrName];
	[attributeValues replaceObjectAtIndex:index withObject:newAttrValue];
}
- (void)removeAttributeAtIndex:(unsigned)index {
	NSParameterAssert((index < [attributeNames count]) && (index < [attributeValues count]));
	[attributeNames  removeObjectAtIndex:index];
	[attributeValues removeObjectAtIndex:index];
}
//returns index of the new attribute.
- (unsigned)addAttributeWithName:(NSString *)newAttrName value:(NSString *)newAttrValue {
	NSParameterAssert(newAttrName != nil);
	NSParameterAssert(newAttrValue != nil);
	unsigned newIndex = [attributeNames count];
	[attributeNames  addObject:newAttrName];
	[attributeValues addObject:newAttrValue];
	return newIndex;
}

#pragma mark -

- (BOOL)hasAttributeWithName:(NSString *)attrName
{
	return [attributeNames containsObject:attrName];
}
- (BOOL)hasAttributeWithValue:(NSString *)attrValue
{
	return [attributeValues containsObject:attrValue];
}
- (unsigned)indexOfFirstAttributeWithName:(NSString *)attrName
{
	return [attributeNames indexOfObject:attrName];
}
- (unsigned)indexOfFirstAttributeWithValue:(NSString *)attrValue
{
	return [attributeValues indexOfObject:attrValue];
}
- (NSString *)valueOfFirstAttributeWithName:(NSString *)attrName
{
	return [attributeValues objectAtIndex:[self indexOfFirstAttributeWithName:attrName]];
}
- (NSString *)nameOfFirstAttributeWithValue:(NSString *)attrValue
{
	return [attributeNames objectAtIndex:[self indexOfFirstAttributeWithValue:attrValue]];
}

#pragma mark -
#pragma mark Contents

- (NSArray *)contents
{
	return [NSArray arrayWithArray:contents];
}
- (NSMutableArray *)mutableContents
{
	return [NSMutableArray arrayWithArray:contents];
}
- (NSString *)flattenedContents
{
	NSMutableString *string = [NSMutableString string];
	Class stringClass = [NSString class];
	NSEnumerator *contentsEnumerator = [contents objectEnumerator];
	id obj;
	while ((obj = [contentsEnumerator nextObject])) {
		if ([obj respondsToSelector:@selector(flattenedContents)]) {
			[string appendString:[obj flattenedContents]];
		} else if ([obj isKindOfClass:stringClass]) {
			[string appendString:obj];
		} else {
			[string appendString:[obj description]];
		}
	}
	return string;
}

#pragma mark -

- (unsigned)count
{
	return [contents count];
}
- (id)objectAtIndex:(unsigned)index
{
	return [contents objectAtIndex:index];
}
- (void)removeObjectAtIndex:(unsigned)index
{
	[contents removeObjectAtIndex:index];
}
- (id)lastObject
{
	return [contents lastObject];
}
- (void)removeLastObject
{
	[contents removeLastObject];
}
- (unsigned)addObject:(id)obj
{
	unsigned newIndex = [contents count];
	[contents addObject:obj];
	return newIndex;
}

@end
