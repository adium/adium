/* AIXMLElement.m
 *
 * Created by Peter Hosey on 2006-06-07.
 *
 * This class is explicitly released under the BSD license with the following modification:
 * It may be used without reproduction of its copyright notice within The Adium Project.
 *
 * This class was created for use in the Adium project, which is released under the GPL.
 * The release of this specific class (AIXMLElement) under BSD in no way changes the licensing of any other portion
 * of the Adium project.
 *
 ****
 Copyright © 2006 Peter Hosey, Colin Barrett
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of Peter Hosey nor the names of his contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Adium/AIXMLElement.h>

#import <AIUtilities/AIStringAdditions.h>

#import <ESDebugAILog.h>

@interface AIXMLElement()
@property (readwrite, retain, nonatomic) NSMutableArray *attributeNames;
@property (readwrite, retain, nonatomic) NSMutableArray *attributeValues;
@end

@implementation AIXMLElement

+ (id) elementWithNamespaceName:(NSString *)namespace elementName:(NSString *)newName
{
	if (namespace)
		newName = [NSString stringWithFormat:@"%@:%@", namespace, newName];
	return [self elementWithName:newName];
}
- (id) initWithNamespaceName:(NSString *)namespace elementName:(NSString *)newName
{
	if (namespace)
		newName = [NSString stringWithFormat:@"%@:%@", namespace, newName];
	return [self initWithName:newName];
}
+ (id) elementWithName:(NSString *)newName
{
	return [[[self alloc] initWithName:newName] autorelease];
}
- (id) initWithName:(NSString *)newName
{
	NSParameterAssert(newName != nil);

	if ((self = [super init])) {
		name = [newName copy];
		self.attributeNames  = [NSMutableArray array];
		self.attributeValues = [NSMutableArray array];
		contents = [[NSMutableArray alloc] init];

		//If a list of self-closing tags exists, this could change to a lookup into a static NSSet
		selfCloses = (([newName caseInsensitiveCompare:@"br"] == NSOrderedSame) ? YES : NO);
	}
	return self;
}

@synthesize attributeNames, attributeValues;

- (id) init
{
	NSException *exc = [NSException exceptionWithName:@"Can't init AIXMLElement"
											   reason:@"AIXMLElement does not support the -init method; use -initWithName: instead."
											 userInfo:nil];
	[exc raise];
	return nil;
}

- (void) dealloc
{
	[name release];
	[attributeNames  release];
	[attributeValues release];
	[contents release];

	[super dealloc];
}

- (id) copyWithZone:(NSZone *)zone {
	AIXMLElement *other = [[AIXMLElement allocWithZone:zone] initWithName:name];
	other.attributeNames  = [NSMutableArray arrayWithArray:attributeNames];
	other.attributeValues = [NSMutableArray arrayWithArray:attributeValues];
	other.selfCloses = selfCloses;
	other.contents = self.contents; //uses setArray, so this copies

	return other;
}

#pragma mark -

/*!
 * @brief This element's name
 *
 * @returns An NSString of this element's name
 */
- (NSString *)name
{
	return name;
}

/*!
 * @brief Number of attributes
 *
 * @returns The number of attributes for this element.
 */
- (NSUInteger)numberOfAttributes
{
	return [attributeNames count];
}

/*!
 * @brief Attributes for this element
 *
 * @returns An NSDictionary keyed on the attribute names with their values
 */
- (NSDictionary *)attributes
{
	return [NSDictionary dictionaryWithObjects:attributeValues forKeys:attributeNames];
}

/*!
 * @brief Set attributes and their values
 *
 * @param newAttrNames An array of NSStrings, new names of the attributes
 * @param newAttrVals An array of NSStrings, new values of the given attributes
 *
 * You cannot duplicate attributes in this assignment, and you must provide arrays of the same length.
 *
 * This overrides any currently-set attributes.
 */
- (void)setAttributeNames:(NSArray *)newAttrNames values:(NSArray *)newAttrVals
{
	NSAssert2([newAttrNames count] == [newAttrVals count], @"Attribute names and values have different lengths, %lui and %lui respectively", (unsigned long)[newAttrNames count], [newAttrVals count]);
	NSUInteger numberOfDuplicates = [newAttrNames count] - [[NSSet setWithArray:newAttrNames] count];
    NSAssert1(numberOfDuplicates == 0, @"Duplicate attributes are not allowed; found %lui duplicate(s)", (unsigned long)numberOfDuplicates);
	
	[attributeNames setArray:newAttrNames];
	[attributeValues setArray:newAttrVals];
}

/*!
 * @brief Set an attribute and its value
 *
 * This will replace any currently-set value if overriding, otherwise it adds the attribute.
 *
 * @param attrVal The NSString value for the attribute
 * @param attrName The NSString name for the attribute
 */
- (void)setValue:(NSString *)attrVal forAttribute:(NSString *)attrName
{
	NSUInteger idx = [attributeNames indexOfObject:attrName];
	if (idx != NSNotFound) {
		[attributeValues replaceObjectAtIndex:idx withObject:attrVal];
	} else {
		[attributeNames addObject:attrName];
		[attributeValues addObject:attrVal];
	}
}

/*!
 * @brief The value of an attribute
 *
 * @param attrName The name of the attribute
 * @returns The value for the given attrName attribute
 */
- (NSString *)valueForAttribute:(NSString *)attrName
{
	NSUInteger idx = [attributeNames indexOfObject:attrName];
	if (idx != NSNotFound)
		return [attributeValues objectAtIndex:idx];
	return nil;
}

@synthesize selfCloses;

#pragma mark -

/*!
 * @brief Add an already-escaped object
 *
 * @param obj The already-escaped object, either an NSString or an AIXMLelement
 *
 * Adds the object as a child for this element at the last index.
 *
 * Unlike -addObject:, this does not attempt to escape any XML entities present in the string.
 * This is useful for reading in already-escaped content, such as from an XML file.
 */
- (void)addEscapedObject:(id)obj
{
	//Warn but don't assert if null is added.  Adding nothing is a no-op, but we may want to investigate where this is happening further.
	if (!obj) {
		AILog(@"Attempted to add null to AIXMLElement %@, backtrace available in debug mode", obj);
		AILogBacktrace();
		return;
	}
	NSAssert2(([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[AIXMLElement class]]), @"%@: addObject: %@ is of incorrect class",self,obj);
	
	[contents addObject:obj];
}

/*!
 * @brief Add an unescaped object
 *
 * @param obj The unescaped object, either an NSString or an AIXMLelement
 * 
 * Adds the object as a child for this element at the last index.
 */
- (void)addObject:(id)obj
{
	//Warn but don't assert if null is added.  Adding nothing is a no-op, but we may want to investigate where this is happening further.
	if (!obj) {
		AILog(@"Attempted to add null to AIXMLElement %@, backtrace available in debug mode", obj);
		AILogBacktrace();
		return;
	}

	BOOL isString = [obj isKindOfClass:[NSString class]];
	NSAssert2((isString || [obj isKindOfClass:[AIXMLElement class]]), @"%@: addObject: %@ is of incorrect class",self,obj);

	if(isString) {
		obj = [obj stringByEscapingForXMLWithEntities:nil];
	}

	[contents addObject:obj];
}

/*!
 * @brief Add objects from an array.
 *
 * @param array The NSArray of NSString or AIXMLElement elements to add as children.
 *
 * Calls -addObject: on all of the elements in the array, so they must all be valid inputs for -addObject:
 */
- (void) addObjectsFromArray:(NSArray *)array
{
	//We do it this way for the assertion, and to get free escaping of strings.
	for (id obj in array) {
		[self addObject:obj];
	}
}

/*!
 * @brief Insert an escaped object at an index
 *
 * @param obj The NSString or AIXMLElement object to insert
 * @param idx The index to insert the object at
 *
 * Much like -addEscapedObject:, this inserts an object at a specific index without escaping it.
 */
- (void)insertEscapedObject:(id)obj atIndex:(NSUInteger)idx
{
	NSParameterAssert([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[AIXMLElement class]]);
	
	[contents insertObject:obj atIndex:idx];
}

/*!
 * @brief Insert an unescaped object at an index
 *
 * @param obj The NSString or AIXMLElement object to insert
 * @param idx The index to insert the object at
 *
 * Much like -addObject:, this inserts an object at a specific index after escaping it.
 */
- (void) insertObject:(id)obj atIndex:(NSUInteger)idx
{
	BOOL isString = [obj isKindOfClass:[NSString class]];
	NSParameterAssert(isString || [obj isKindOfClass:[AIXMLElement class]]);

	if(isString) {
		obj = [obj stringByEscapingForXMLWithEntities:nil];
	}

	[contents insertObject:obj atIndex:idx];
}

/*!
 * @brief The contents of this element
 *
 * @returns An NSArray of the NSString or AIXMLElement children for this element
 */
- (NSArray *)contents
{
	return contents;
}

/*!
 * @brief Set the contents of this element
 *
 * @param newContents The NSArray of NSString or AIXMLElement elements to set as the new contents.
 *
 * This overrides any currently-set contents.
 */
- (void)setContents:(NSArray *)newContents
{
	[contents setArray:newContents];
}

/*!
 * @brief The contents of this element as an XML string.
 *
 * @returns An NSString which corresponds to an XML representation of this element and its children.
 */
- (NSString *)contentsAsXMLString
{
	NSMutableString *contentString = [NSMutableString string];
	id obj = nil;
	for (obj in contents) {
		if ([obj isKindOfClass:[NSString class]])
			[contentString appendString:obj];
		else if ([obj isKindOfClass:[AIXMLElement class]])
			[contentString appendString:[obj XMLString]];
	}
	return contentString;
}

#pragma mark -

/*!
 * @brief Quoted XML attribute value string for string
 *
 * @param str The string to quote
 *
 * @returns An escaped, quoted string for the given string.
 */
- (NSString *)quotedXMLAttributeValueStringForString:(NSString *)str
{
	return [NSString stringWithFormat:@"\"%@\"", [str stringByEscapingForXMLWithEntities:nil]];
}

/*!
 * @brief Append an XML representation of the element string to a mutable string
 * 
 * @param string The NSMutableString to append to
 */
- (void)appendXMLStringtoString:(NSMutableString *)string
{
	[string appendFormat:@"<%@", name];
	if ([attributeNames count]) {
		NSUInteger attributeIdx = 0U;
		NSString *key;
		for (key in attributeNames) {
			NSString *value = [attributeValues objectAtIndex:attributeIdx++];
			if ([value respondsToSelector:@selector(stringValue)]) {
				value = [(NSNumber *)value stringValue];
			} else if ([value respondsToSelector:@selector(absoluteString)]) {
				value = [(NSURL *)value absoluteString];
			}
			[string appendFormat:@" %@=%@", key, [self quotedXMLAttributeValueStringForString:value]];
		}
	}
	if ((![contents count]) && (selfCloses)) {
		[string appendString:@" /"];
	}
	[string appendString:@">"];

	id obj;
	for (obj in contents) {
		if ([obj isKindOfClass:[NSString class]]) {
			[string appendString:(NSString *)obj];
		} else if([obj isKindOfClass:[AIXMLElement class]]) {
			[(AIXMLElement *)obj appendXMLStringtoString:string];
		}
	}

	if ([contents count] || !selfCloses) {
		[string appendFormat:@"</%@>", name];
	}
}

/*!
 * @brief An XML string representation of this element
 *
 * @returns An NSString of an XML representation of this element
 *
 * This is equivalent to -appendXMLStringToString: onto an empty string.
 *
 * This includes the element, its attributes, and its children and their attributes.
 */
- (NSString *)XMLString
{
	NSMutableString *string = [NSMutableString string];
	[self appendXMLStringtoString:string];
	return [NSString stringWithString:string];
}

/*!
 * @brief Append a UTF-8 XML representation of the element string to a mutable string
 * 
 * @param string The NSMutableString to append to
 */
- (void)appendUTF8XMLBytesToData:(NSMutableData *)data
{
	NSMutableString *startTag = [NSMutableString stringWithFormat:@"<%@", name];
	if ([self numberOfAttributes]) {
		NSUInteger attributeIdx = 0U;
		NSString *key;
		for (key in attributeNames) {
			NSString *value = [attributeValues objectAtIndex:attributeIdx++];
			if ([value respondsToSelector:@selector(stringValue)]) {
				value = [(NSNumber *)value stringValue];
			} else if ([value respondsToSelector:@selector(absoluteString)]) {
				value = [(NSURL *)value absoluteString];
			}
			[startTag appendFormat:@" %@=%@", key, [self quotedXMLAttributeValueStringForString:value]];
		}
	}
	if ((![contents count]) && (selfCloses)) {
		[startTag appendString:@" /"];
	}
	[startTag appendString:@">"];
	[data appendData:[startTag dataUsingEncoding:NSUTF8StringEncoding]];

	id obj;
	for (obj in contents) {
		if ([obj isKindOfClass:[NSString class]]) {
			[data appendData:[(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding]];
		} else if([obj isKindOfClass:[AIXMLElement class]]) {
			[(AIXMLElement *)obj appendUTF8XMLBytesToData:data];
		}
	}

	if ([contents count] || !selfCloses) {
		[data appendData:[[NSString stringWithFormat:@"</%@>", name] dataUsingEncoding:NSUTF8StringEncoding]];
	}
}

/*!
 * @brief A UTF-8 XML string representation of this element
 *
 * @returns An NSString of a UTF-8 XML representation of this element
 *
 * This is equivalent to -appendUTF8XMLStringToString: onto an empty string.
 *
 * This includes the element, its attributes, and its children and their attributes.
 */
- (NSData *)UTF8XMLData
{
	NSMutableData *data = [NSMutableData data];
	[self appendUTF8XMLBytesToData:data];
	return [NSData dataWithData:data];
}

- (NSString *)description
{
	NSMutableString *string = [NSMutableString stringWithFormat:@"<%@ AIXMLElement:id=\"%p\"", name, self];
	if ([attributeNames count] && [attributeValues count]) { //there's no way these could be different values, but whatever
		NSUInteger attributeIdx = 0U;
		NSString *key;
		for (key in attributeNames) {
			NSString *value = [attributeValues objectAtIndex:attributeIdx++];
			if ([value respondsToSelector:@selector(stringValue)]) {
				value = [(NSNumber *)value stringValue];
			} else if ([value respondsToSelector:@selector(absoluteString)]) {
				value = [(NSURL *)value absoluteString];
			}
			[string appendFormat:@" %@=%@", key, [self quotedXMLAttributeValueStringForString:value]];
		}
	}
	[string appendString:@" />"];

	return [NSString stringWithString:string];
}

#pragma mark KVC

/*
These aren't working. I recommend calling -objectForKey on the return value of -attributes.

Adium[302:117] The following unhandled exception was ignored: NSUnknownKeyException ([<AIXMLElement 0xce582b0> valueForUndefinedKey:]: this class is not key value coding-compliant for the key auto.)

*/
/*
- (id) valueForKey:(NSString *)key {
	NSUInteger idx = [attributeNames indexOfObject:key];	
	return (idx != NSNotFound) ? [attributeValues objectAtIndex:idx] : [super valueForKey:key];
}
//FIXME: this shouldn't clobber setObject:forKey: on NSObject.
- (void) setValue:(id)obj forKey:(NSString *)key {
	NSUInteger idx = [attributeNames indexOfObject:key];
	if(idx == NSNotFound) {
		[attributeNames addObject:key];
		[attributeValues addObject:obj];
	} else {
		[attributeValues replaceObjectAtIndex:idx withObject:obj];
	}
}

*/

@end
