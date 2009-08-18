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

- (NSString *) name
{
	return name;
}

- (unsigned)numberOfAttributes
{
	return [attributeNames count];
}
- (NSDictionary *)attributes
{
	return [NSDictionary dictionaryWithObjects:attributeValues forKeys:attributeNames];
}
- (void) setAttributeNames:(NSArray *)newAttrNames values:(NSArray *)newAttrVals
{
	NSAssert2([newAttrNames count] == [newAttrVals count], @"Attribute names and values have different lengths, %ui and %ui respectively", [newAttrNames count], [newAttrVals count]);
	unsigned numberOfDuplicates = [newAttrNames count] - [[NSSet setWithArray:newAttrNames] count];
	NSAssert1(numberOfDuplicates == 0, @"Duplicate attributes are not allowed; found %ui duplicate(s)",  numberOfDuplicates);
	
	[attributeNames setArray:newAttrNames];
	[attributeValues setArray:newAttrVals];
}

- (void)setValue:(NSString *)attrVal forAttribute:(NSString *)attrName
{
	NSUInteger index = [attributeNames indexOfObject:attrName];
	if (index != NSNotFound) {
		[attributeValues replaceObjectAtIndex:index withObject:attrVal];
	} else {
		[attributeNames addObject:attrName];
		[attributeValues addObject:attrVal];
	}
}
- (NSString *)valueForAttribute:(NSString *)attrName
{
	NSUInteger index = [attributeNames indexOfObject:attrName];
	if (index != NSNotFound)
		return [attributeValues objectAtIndex:index];
	return nil;
}

@synthesize selfCloses;

#pragma mark -

//NSString: Unescaped string data (will be escaped for XMLification).
//AIXMLElement: Sub-element (e.g. span in a p).
- (void)addEscapedObject:(id)obj
{
	//Warn but don't assert if null is added.  Adding nothing is a no-op, but we may want to investigate where this is happening further.
	if (!obj) NSLog(@"Warning: Attempted to add (null) to %@", obj);

	NSAssert2(([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[AIXMLElement class]]), @"%@: addObject: %@ is of incorrect class",self,obj);
	
	[contents addObject:obj];
}

- (void) addObject:(id)obj
{
	//Warn but don't assert if null is added.  Adding nothing is a no-op, but we may want to investigate where this is happening further.
	if (!obj) NSLog(@"Warning: Attempted to add (null) to %@", obj);

	BOOL isString = [obj isKindOfClass:[NSString class]];
	NSAssert2((isString || [obj isKindOfClass:[AIXMLElement class]]), @"%@: addObject: %@ is of incorrect class",self,obj);

	if(isString) {
		obj = [obj stringByEscapingForXMLWithEntities:nil];
	}

	[contents addObject:obj];
}
- (void) addObjectsFromArray:(NSArray *)array
{
	//We do it this way for the assertion, and to get free escaping of strings.
	id obj;
	for (obj in array) {
		[self addObject:obj];
	}
}
- (void) insertObject:(id)obj atIndex:(unsigned)idx
{
	BOOL isString = [obj isKindOfClass:[NSString class]];
	NSParameterAssert(isString || [obj isKindOfClass:[AIXMLElement class]]);

	if(isString) {
		obj = [obj stringByEscapingForXMLWithEntities:nil];
	}

	[contents insertObject:obj atIndex:idx];
}

- (NSArray *)contents
{
	return contents;
}
- (void)setContents:(NSArray *)newContents
{
	[contents setArray:newContents];
}

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

- (NSString *) quotedXMLAttributeValueStringForString:(NSString *)str
{
	return [NSString stringWithFormat:@"\"%@\"", [str stringByEscapingForXMLWithEntities:nil]];
}

- (void) appendXMLStringtoString:(NSMutableString *)string
{
	[string appendFormat:@"<%@", name];
	if ([attributeNames count]) {
		unsigned attributeIdx = 0U;
		NSString *key;
		for (key in attributeNames) {
			NSString *value = [attributeValues objectAtIndex:attributeIdx++];
			if ([value respondsToSelector:@selector(stringValue)]) {
				value = [(NSNumber *)value stringValue];
			} else if ([value respondsToSelector:@selector(absoluteString)]) {
				value = [(NSURL *)value absoluteString];
			}
			[string appendFormat:@" %@=\"%@\"", key, value];
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
- (NSString *) XMLString
{
	NSMutableString *string = [NSMutableString string];
	[self appendXMLStringtoString:string];
	return [NSString stringWithString:string];
}

- (void) appendUTF8XMLBytesToData:(NSMutableData *)data
{
	NSMutableString *startTag = [NSMutableString stringWithFormat:@"<%@", name];
	if ([self numberOfAttributes]) {
		unsigned attributeIdx = 0U;
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
		unsigned attributeIdx = 0U;
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
	unsigned idx = [attributeNames indexOfObject:key];	
	return (idx != NSNotFound) ? [attributeValues objectAtIndex:idx] : [super valueForKey:key];
}
//FIXME: this shouldn't clobber setObject:forKey: on NSObject.
- (void) setValue:(id)obj forKey:(NSString *)key {
	unsigned idx = [attributeNames indexOfObject:key];
	if(idx == NSNotFound) {
		[attributeNames addObject:key];
		[attributeValues addObject:obj];
	} else {
		[attributeValues replaceObjectAtIndex:idx withObject:obj];
	}
}

*/

@end
