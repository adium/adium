//
//  AITag.h
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-01-14.
//  Copyright 2005 The Adium Team. All rights reserved.
//

//for encoding an AITag as a dictionary.
extern NSString *AITag_TagNameKey;
extern NSString *AITag_AttributeNamesKey;
extern NSString *AITag_AttributeValuesKey;
extern NSString *AITag_ContentsKey;

@interface AITag: NSObject
{
	NSString *name;
	NSMutableArray *attributeNames;
	NSMutableArray *attributeValues;
	
	/*the contents of a tag are mixed: each sub-item can be either a tag or a string.
	 *for example,
	 *	<a href="foo.xhtml">Click <b>here</b> for Foo's description</a>
	 *could be represented as:
	 *	tag: name "a", attributes: ("href", "foo.xhtml"), contents: {
	 *		string: "Click "
	 *		tag:    name "b", contents: {
	 *			string: "here"
	 *		}
	 *		string: " for Foo's description"
	 *	} //tag "a"
	 */
	NSMutableArray *contents;
}

+ (id)tagWithName:(NSString *)newName
   attributeNames:(NSArray *)newAttributeNames
  attributeValues:(NSArray *)newAttributeValues
         contents:(NSArray *)contents;

+ (id)tagWithDictionaryRepresentation:(NSDictionary *)dict;
+ (id)tagWithArrayRepresentation:(NSArray *)array;
//pass a dictionary or array.
+ (id)tagWithPropertyList:(id)plist;

#pragma mark -

- (id)initWithName:(NSString *)newName
    attributeNames:(NSArray *)newAttributeNames
   attributeValues:(NSArray *)newAttributeValues
          contents:(NSArray *)contents;

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict;
- (id)initWithArrayRepresentation:(NSArray *)array;
//pass a dictionary or array.
- (id)initWithPropertyList:(id)plist;

#pragma mark -

- (id)propertyList;
- (NSDictionary *)dictionaryRepresentation;
- (NSArray *)arrayRepresentation;

#pragma mark -

- (unsigned)hash;
- (BOOL)isEqualToTag:(AITag *)other;

#pragma mark -
#pragma mark Tag name

- (NSString *)name;
- (void)setName:(NSString *)newName;

#pragma mark -
#pragma mark Attributes

- (unsigned)countAttributes;
- (void)attributeAtIndex:(unsigned)index name:(out NSString **)outName value:(out NSString **)outValue;
- (void)replaceAttributeAtIndex:(unsigned)index name:(NSString *)newName value:(NSString *)newValue;
- (void)removeAttributeAtIndex:(unsigned)index;
//returns index of the new attribute.
- (unsigned)addAttributeWithName:(NSString *)newName value:(NSString *)newValue;

#pragma mark -

- (BOOL)hasAttributeWithName:(NSString *)attrName;
- (BOOL)hasAttributeWithValue:(NSString *)attrValue;
- (unsigned)indexOfFirstAttributeWithName:(NSString *)attrName;
- (unsigned)indexOfFirstAttributeWithValue:(NSString *)attrValue;
- (NSString *)valueOfFirstAttributeWithName:(NSString *)attrName;
- (NSString *)nameOfFirstAttributeWithValue:(NSString *)attrValue;

#pragma mark -
#pragma mark Contents

- (NSArray *)contents;
- (NSMutableArray *)mutableContents;
- (NSString *)flattenedContents;

#pragma mark -

- (unsigned)count;
- (id)objectAtIndex:(unsigned)index;
- (void)removeObjectAtIndex:(unsigned)index;
- (id)lastObject;
- (void)removeLastObject;
- (unsigned)addObject:(id)obj;

@end
