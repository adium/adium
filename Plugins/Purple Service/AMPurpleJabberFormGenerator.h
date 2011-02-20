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

#import "glib.h"
#import "xmlnode.h"

enum AMPurpleJabberFormType {
	form = 0,
	submit,
	cancel,
	result
};

@interface AMPurpleJabberFormField : NSObject {
	BOOL required;
	NSString *label;
	NSString *var;
	NSString *desc;
}
/* use -init for creating an empty field */
+ (AMPurpleJabberFormField*)fieldForXML:(xmlnode*)xml;

- (void)setRequired:(BOOL)_required;
- (BOOL)required;
- (void)setLabel:(NSString*)_label;
- (NSString*)label;
- (void)setVariable:(NSString*)_var;
- (NSString*)var;
- (void)setDescription:(NSString*)_desc;
- (NSString*)desc;

- (xmlnode*)xml;
@end

@interface AMPurpleJabberFormFieldBoolean : AMPurpleJabberFormField {
	BOOL value;
}

- (void)setBoolValue:(BOOL)_value;
- (BOOL)boolValue;

@end

@interface AMPurpleJabberFormFieldFixed : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldHidden : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldJidMulti : AMPurpleJabberFormField {
	NSArray *jids;
}

- (void)setJIDs:(NSArray*)_jids; // array of NSString*
- (NSArray*)jids;

@end

@interface AMPurpleJabberFormFieldJidSingle : AMPurpleJabberFormField {
	NSString *jid;
}

- (void)setJID:(NSString*)_jid;
- (NSString*)jid;

@end

@interface AMPurpleJabberFormFieldListMulti : AMPurpleJabberFormField {
	NSArray *options; // array of NSDictionary with Keys @"label" and @"value"
	NSArray *values;
}

- (void)setOptions:(NSArray*)_options; // array of NSString*
- (NSArray*)options;
- (void)setStringValues:(NSArray*)_values;
- (NSArray*)stringValues;

@end

@interface AMPurpleJabberFormFieldListSingle : AMPurpleJabberFormField {
	NSArray *options;
	NSString *value;
}

- (void)setOptions:(NSArray*)_options; // array of NSString*
- (NSArray*)options;
- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldTextMulti : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldTextPrivate : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormFieldTextSingle : AMPurpleJabberFormField {
	NSString *value;
}

- (void)setStringValue:(NSString*)_value;
- (NSString*)stringValue;

@end

@interface AMPurpleJabberFormGenerator : NSObject {
	NSString *title;
	NSString *instructions;
	enum AMPurpleJabberFormType type;
	
	NSMutableArray *fields;
}

- (id)initWithType:(enum AMPurpleJabberFormType)_type;
- (id)initWithXML:(xmlnode*)xml;

- (void)setTitle:(NSString*)_title;
- (void)setInstructions:(NSString*)_instructions;

- (NSString*)title;
- (NSString*)instructions;
- (enum AMPurpleJabberFormType)type;

- (void)addField:(AMPurpleJabberFormField*)field;
- (void)removeField:(AMPurpleJabberFormField*)field;

- (NSArray*)fields;

- (xmlnode*)xml;

@end
