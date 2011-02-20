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

#import "AMPurpleJabberFormGenerator.h"

@interface AMPurpleJabberFormField (protectedMethods)

- (id)initWithXML:(xmlnode*)xml;

@end

@implementation AMPurpleJabberFormField

/* factory method pattern */
+ (AMPurpleJabberFormField*)fieldForXML:(xmlnode*)xml {
	const char *fieldtype = xmlnode_get_attrib(xml,"type");
	if(!fieldtype)
		return nil;
	
	Class class;
	if(!strcmp(fieldtype,"boolean"))
		class = [AMPurpleJabberFormFieldBoolean class];
	else if(!strcmp(fieldtype,"fixed"))
		class = [AMPurpleJabberFormFieldFixed class];
	else if(!strcmp(fieldtype,"hidden"))
		class = [AMPurpleJabberFormFieldHidden class];
	else if(!strcmp(fieldtype,"jid-multi"))
		class = [AMPurpleJabberFormFieldJidMulti class];
	else if(!strcmp(fieldtype,"jid-single"))
		class = [AMPurpleJabberFormFieldJidSingle class];
	else if(!strcmp(fieldtype,"list-multi"))
		class = [AMPurpleJabberFormFieldListMulti class];
	else if(!strcmp(fieldtype,"list-single"))
		class = [AMPurpleJabberFormFieldListSingle class];
	else if(!strcmp(fieldtype,"text-multi"))
		class = [AMPurpleJabberFormFieldTextMulti class];
	else if(!strcmp(fieldtype,"text-private"))
		class = [AMPurpleJabberFormFieldTextPrivate class];
	else if(!strcmp(fieldtype,"text-single"))
		class = [AMPurpleJabberFormFieldTextSingle class];
	else
		return nil;
	
	return [[[class alloc] initWithXML:xml] autorelease];
}

- (id)initWithXML:(xmlnode*)xml {
	if((self = [self init])) {
		if(xmlnode_get_child(xml,"required"))
			required = YES;
		const char *labelstr = xmlnode_get_attrib(xml,"label");
		if(labelstr)
			[self setLabel:[NSString stringWithUTF8String:labelstr]];
		const char *varstr = xmlnode_get_attrib(xml,"var");
		if(varstr)
			[self setVariable:[NSString stringWithUTF8String:varstr]];
		xmlnode *descnode = xmlnode_get_child(xml,"desc");
		if(descnode) {
			const char *descstr = xmlnode_get_data(descnode);
			if(descstr)
				[self setDescription:[NSString stringWithUTF8String:descstr]];
		}
	}
	return self;
}

- (void)setRequired:(BOOL)_required {
	required = _required;
}

- (BOOL)required {
	return required;
}

- (void)setLabel:(NSString*)_label {
	id old = label;
	label = [_label copy];
	[old release];
}

- (NSString*)label {
	return label;
}

- (void)setVariable:(NSString*)_var {
	id old = var;
	var = [_var copy];
	[old release];
}

- (NSString*)var {
	return var;
}

- (void)setDescription:(NSString*)_desc {
	id old = desc;
	desc = [_desc copy];
	[old release];
}

- (NSString*)desc {
	return desc;
}

- (void)dealloc {
	[label release];
	[var release];
	[desc release];
	[super dealloc];
}

- (xmlnode*)xml {
	xmlnode *xml_result = xmlnode_new("field");
	if(label)
		xmlnode_set_attrib(xml_result,"label",[label UTF8String]);
	if(var)
		xmlnode_set_attrib(xml_result,"var",[var UTF8String]);
	if(required)
		xmlnode_new_child(xml_result,"required");
	if(desc)
		xmlnode_insert_data(xmlnode_new_child(xml_result,"desc"), [desc UTF8String], -1);
	
	return xml_result;
}

@end


@implementation AMPurpleJabberFormFieldBoolean

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		xmlnode *valuenode = xmlnode_get_child(xml,"value");
		if(valuenode) {
			const char *v = xmlnode_get_data(valuenode);
			if(v && (!strcmp(v, "1") || !strcmp(v, "true")))
				[self setBoolValue:YES];
		}
	}
	return self;
}

- (void)setBoolValue:(BOOL)_value {
	value = _value;
}

- (BOOL)boolValue {
	return value;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","boolean");
	if(value)
		xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),"1",-1);
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldFixed

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		xmlnode *valuenode = xmlnode_get_child(xml,"value");
		if(valuenode) {
			const char *valstr = xmlnode_get_data(valuenode);
			if(valstr)
				[self setStringValue:[NSString stringWithUTF8String:valstr]];
		}
	}
	return self;
}

- (void)dealloc {
	[value release];
	[super dealloc];
}

- (void)setStringValue:(NSString*)_value {
	id old = value;
	value = [_value copy];
	[old release];
}

- (NSString*)stringValue {
	return value;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","fixed");
	if(value)
		xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[value UTF8String],-1);
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldHidden

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		xmlnode *valuenode = xmlnode_get_child(xml,"value");
		if(valuenode) {
			const char *valstr = xmlnode_get_data(valuenode);
			if(valstr)
				[self setStringValue:[NSString stringWithUTF8String:valstr]];
		}
	}
	return self;
}

- (void)dealloc {
	[value release];
	[super dealloc];
}

- (void)setStringValue:(NSString*)_value {
	id old = value;
	value = [_value copy];
	[old release];
}

- (NSString*)stringValue {
	return value;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","hidden");
	if(value)
		xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[value UTF8String],-1);
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldJidMulti

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		NSMutableArray *values = [NSMutableArray array];
		xmlnode *valuenode;
		for(valuenode = xml->child; valuenode; valuenode = valuenode->next) {
			if(valuenode->type == XMLNODE_TYPE_TAG && !strcmp(valuenode->name, "value")) {
				const char *content = xmlnode_get_data(valuenode);
				if(content)
					[values addObject:[NSString stringWithUTF8String:content]];
			}
		}
		[self setJIDs:values];
	}
	return self;
}

- (void)dealloc {
	[jids release];
	[super dealloc];
}

- (void)setJIDs:(NSArray*)_jids {
	id old = jids;
	jids = [_jids copy];
	[old release];
}

- (NSArray*)jids {
	return jids;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","jid-multi");
	if(jids) {
		NSString *jid;
		for(jid in jids)
			xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[jid UTF8String],-1);
	}
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldJidSingle

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		xmlnode *value = xmlnode_get_child(xml,"value");
		if(value) {
			const char *valstr = xmlnode_get_data(value);
			if(valstr)
				[self setJID:[NSString stringWithUTF8String:valstr]];
		}
	}
	return self;
}

- (void)dealloc {
	[jid release];
	[super dealloc];
}

- (void)setJID:(NSString*)_jid {
	id old = jid;
	jid = [_jid copy];
	[old release];
}

- (NSString*)jid {
	return jid;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","jid-single");
	if(jid)
		xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[jid UTF8String],-1);
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldListMulti

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		NSMutableArray *newvalues = [NSMutableArray array];
		xmlnode *valuenode;
		for(valuenode = xml->child; valuenode; valuenode = valuenode->next) {
			if(valuenode->type == XMLNODE_TYPE_TAG && !strcmp(valuenode->name, "value")) {
				const char *content = xmlnode_get_data(valuenode);
				if(content)
					[newvalues addObject:[NSString stringWithUTF8String:content]];
			}
		}
		[self setStringValues:newvalues];

		NSMutableArray *newoptions = [NSMutableArray array];
		xmlnode *option;
		for(option = xml->child; option; option = option->next) {
			if(option->type == XMLNODE_TYPE_TAG && !strcmp(option->name, "option")) {
				const char *labelstr = xmlnode_get_attrib(option,"label");
				xmlnode *lvaluenode = xmlnode_get_child(option,"value");
				if(!valuenode) {
					/* invalid field */
					[self release];
					return nil;
				}
				const char *valuestr = xmlnode_get_data(lvaluenode);
				if(!valuestr) {
					[self release];
					return nil;
				}
				[newoptions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSString stringWithUTF8String:valuestr], @"value",
					labelstr?[NSString stringWithUTF8String:labelstr]:nil, @"label",
					nil]];
			}
		}
		[self setOptions:newoptions];
	}
	return self;
}

- (void)dealloc {
	[options release];
	[values release];
	[super dealloc];
}

- (void)setOptions:(NSArray*)_options {
	id old = options;
	options = [_options copy];
	[old release];
}

- (NSArray*)options {
	return options;
}

- (void)setStringValues:(NSArray*)_values {
	id old = values;
	values = [_values copy];
	[old release];
}

- (NSArray*)stringValues {
	return values;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","list-multi");
	if(options) {
		for(NSDictionary *option in options) {
			xmlnode *optnode = xmlnode_new_child(xml_result,"option");
			xmlnode_set_attrib(optnode,"label",[[option objectForKey:@"label"] UTF8String]);
			xmlnode_insert_data(xmlnode_new_child(optnode,"value"),[[option objectForKey:@"value"] UTF8String],-1);
		}
		NSString *value;
		for(value in values)
			xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[value UTF8String],-1);
	}
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldListSingle

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		xmlnode *valuenode = xmlnode_get_child(xml,"value");
		if(valuenode) {
			const char *valstr = xmlnode_get_data(valuenode);
			if(valstr)
				[self setStringValue:[NSString stringWithUTF8String:valstr]];
		}
		
		NSMutableArray *newoptions = [NSMutableArray array];
		xmlnode *option;
		for(option = xml->child; option; option = option->next) {
			if(option->type == XMLNODE_TYPE_TAG && !strcmp(option->name, "option")) {
				const char *labelstr = xmlnode_get_attrib(option,"label");
				xmlnode *lvaluenode = xmlnode_get_child(option,"value");
				if(!lvaluenode) {
					/* invalid field */
					[self release];
					return nil;
				}
				const char *valuestr = xmlnode_get_data(lvaluenode);
				if(!valuestr) {
					[self release];
					return nil;
				}
				[newoptions addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[NSString stringWithUTF8String:valuestr], @"value",
					labelstr?[NSString stringWithUTF8String:labelstr]:nil, @"label",
					nil]];
			}
		}
		[self setOptions:newoptions];
	}
	return self;
}

- (void)dealloc {
	[options release];
	[value release];
	[super dealloc];
}

- (void)setStringValue:(NSString*)_value {
	id old = value;
	value = [_value copy];
	[old release];
}

- (NSString*)stringValue {
	return value;
}

- (void)setOptions:(NSArray*)_options {
	id old = options;
	options = [_options copy];
	[old release];
}

- (NSArray*)options {
	return options;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","list-single");
	if(options) {
		NSDictionary *option;
		for(option in options) {
			xmlnode *optnode = xmlnode_new_child(xml_result,"option");
			xmlnode_set_attrib(optnode,"label",[[option objectForKey:@"label"] UTF8String]);
			xmlnode_insert_data(xmlnode_new_child(optnode,"value"),[[option objectForKey:@"value"] UTF8String],-1);
		}
		if(value)
			xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[value UTF8String],-1);
	}
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldTextMulti

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		NSMutableArray *values = [NSMutableArray array];
		xmlnode *valuenode;
		for(valuenode = xml->child; valuenode; valuenode = valuenode->next) {
			if(valuenode->type == XMLNODE_TYPE_TAG && !strcmp(valuenode->name, "value")) {
				const char *content = xmlnode_get_data(valuenode);
				if(content)
					[values addObject:[NSString stringWithUTF8String:content]];
			}
		}
		[self setStringValue:[values componentsJoinedByString:@"\n"]];
	}
	return self;
}

- (void)dealloc {
	[value release];
	[super dealloc];
}

- (void)setStringValue:(NSString*)_value {
	id old = value;
	value = [_value copy];
	[old release];
}

- (NSString*)stringValue {
	return value;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","text-multi");
	if(value) {
		for (NSString *line in [value componentsSeparatedByString:@"\n"])
			xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[line UTF8String],-1);
	}
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldTextSingle

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		xmlnode *valuenode = xmlnode_get_child(xml,"value");
		if(valuenode) {
			const char *valstr = xmlnode_get_data(valuenode);
			if(valstr)
				[self setStringValue:[NSString stringWithUTF8String:valstr]];
		}
	}
	return self;
}

- (void)dealloc {
	[value release];
	[super dealloc];
}

- (void)setStringValue:(NSString*)_value {
	id old = value;
	value = [_value copy];
	[old release];
}

- (NSString*)stringValue {
	return value;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","text-single");
	if(value)
		xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[value UTF8String],-1);
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormFieldTextPrivate

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super initWithXML:xml])) {
		xmlnode *valuenode = xmlnode_get_child(xml,"value");
		if(valuenode) {
			const char *valstr = xmlnode_get_data(valuenode);
			if(valstr)
				[self setStringValue:[NSString stringWithUTF8String:valstr]];
		}
	}
	return self;
}

- (void)dealloc {
	[value release];
	[super dealloc];
}

- (void)setStringValue:(NSString*)_value {
	id old = value;
	value = [_value copy];
	[old release];
}

- (NSString*)stringValue {
	return value;
}

- (xmlnode*)xml {
	xmlnode *xml_result = [super xml];
	
	xmlnode_set_attrib(xml_result,"type","text-private");
	if(value)
		xmlnode_insert_data(xmlnode_new_child(xml_result,"value"),[value UTF8String],-1);
	
	return xml_result;
}

@end

@implementation AMPurpleJabberFormGenerator

- (id)initWithType:(enum AMPurpleJabberFormType)_type {
	if((self = [super init])) {
		type = _type;
		fields = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithXML:(xmlnode*)xml {
	if((self = [super init])) {
		// verify that this is really a jabber:x:data
		if(xml->type != XMLNODE_TYPE_TAG || strcmp(xml->name, "x")) {
			[self release];
			return nil;
		}
		const char *xmlns = xmlnode_get_namespace(xml);
		if(!xmlns || strcmp(xmlns,"jabber:x:data")) {
			[self release];
			return nil;
		}
		
		// read global settings
		const char *typestr = xmlnode_get_attrib(xml,"type");
		if(!typestr) {
			[self release];
			return nil;
		}
		
		if(!strcmp(typestr, "form"))
			type = form;
		else if(!strcmp(typestr, "submit"))
			type = submit;
		else if(!strcmp(typestr, "cancel"))
			type = cancel;
		else if(!strcmp(typestr, "result"))
			type = result;
		else { /* unknown form type */
			[self release];
			return nil;
		}
		
		xmlnode *titlenode = xmlnode_get_child(xml,"title");
		if(titlenode) {
			const char *titlestr = xmlnode_get_data(titlenode);
			if(titlestr)
				[self setTitle:[NSString stringWithUTF8String:titlestr]];
		}
		xmlnode *instructionsnode = xmlnode_get_child(xml,"instructions");
		if(instructionsnode) {
			const char *instructionsstr = xmlnode_get_data(instructionsnode);
			if(instructionsstr)
				[self setInstructions:[NSString stringWithUTF8String:instructionsstr]];
		}
		
		// get fields
		fields = [[NSMutableArray alloc] init];
		xmlnode *field;
		for(field = xml->child; field; field = field->next) {
			if(field->type == XMLNODE_TYPE_TAG && !strcmp(field->name,"field")) {
				AMPurpleJabberFormField *fieldobj = [AMPurpleJabberFormField fieldForXML:field];
				if(fieldobj)
					[self addField:fieldobj];
			}
		}
	}
	return self;
}

- (void)dealloc {
	[title release];
	[instructions release];
	[fields release];
	[super dealloc];
}

- (void)setTitle:(NSString*)_title {
	id old = title;
	title = [_title copy];
	[old release];
}

- (void)setInstructions:(NSString*)_instructions {
	id old = instructions;
	instructions = [_instructions copy];
	[old release];
}

- (NSString*)title {
	return title;
}

- (NSString*)instructions {
	return instructions;
}

- (enum AMPurpleJabberFormType)type {
	return type;
}

- (void)addField:(AMPurpleJabberFormField*)field {
	[fields addObject:field];
}

- (void)removeField:(AMPurpleJabberFormField*)field {
	[fields removeObject:field];
}

- (NSArray*)fields {
	return fields;
}

- (xmlnode*)xml {
	xmlnode *xml = xmlnode_new("x");
	xmlnode_set_namespace(xml,"jabber:x:data");
	switch(type) {
		case form:
			xmlnode_set_attrib(xml,"type","form");
			break;
		case submit:
			xmlnode_set_attrib(xml,"type","submit");
			break;
		case cancel:
			xmlnode_set_attrib(xml,"type","cancel");
			break;
		case result:
			xmlnode_set_attrib(xml,"type","result");
			break;
	}
	if(title)
		xmlnode_insert_data(xmlnode_new_child(xml,"title"),[title UTF8String],-1);
	if(instructions)
		xmlnode_insert_data(xmlnode_new_child(xml,"instructions"),[instructions UTF8String],-1);
	AMPurpleJabberFormField *field;
	for(field in fields) {
		xmlnode *fieldxml = [field xml];
		if(fieldxml)
			xmlnode_insert_child(xml,fieldxml);
	}
	return xml;
}

@end
