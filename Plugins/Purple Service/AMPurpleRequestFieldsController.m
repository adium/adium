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

#import "AMPurpleRequestFieldsController.h"
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

@interface WebView ()
- (void)setDrawsBackground:(BOOL)flag;
- (void)setBackgroundColor:(NSColor *)color;
@end

@interface AMPurpleRequestField : NSObject {
    PurpleRequestField *field;
    CBPurpleAccount *account;
    IBOutlet NSView *view;
    IBOutlet NSTextView *label;
    
    NSInteger height;
}

- (id)initWithAccount:(CBPurpleAccount*)_account requestField:(PurpleRequestField*)_field;
- (NSString *)nibName;
- (NSView *)makeView;
- (NSAttributedString *)label;
- (void)submit;

@end

@interface AMPurpleRequestFieldString : AMPurpleRequestField {
    IBOutlet NSTextField *textField;
}
@end

@interface AMPurpleRequestFieldSecureString : AMPurpleRequestField {
    IBOutlet NSSecureTextField *maskedField;
}
@end

@interface AMPurpleRequestFieldMultilineString : AMPurpleRequestField {
    IBOutlet NSTextView *textView;
}
@end

@interface AMPurpleRequestFieldInteger : AMPurpleRequestField {
    IBOutlet NSTextField *textField;
}

@end

@interface AMPurpleRequestFieldBoolean : AMPurpleRequestField {
    IBOutlet NSButton *checkBox;
}

@end

@interface AMPurpleRequestFieldChoice : AMPurpleRequestField {
    IBOutlet NSPopUpButton *popUp;
}

@end

@interface AMPurpleRequestFieldList : AMPurpleRequestField {
    IBOutlet NSPopUpButton *popUp;
}

@end

@interface AMPurpleRequestFieldMultiList : AMPurpleRequestField {
    IBOutlet NSPopUpButton *popDown;
}

- (IBAction)didSelect:(id)sender;

@end


@interface AMPurpleRequestFieldLabel : AMPurpleRequestField {
    IBOutlet NSTextView *labelview;
}

@end

@interface AMPurpleRequestFieldAccount : AMPurpleRequestField {
}

@end

@interface AMPurpleRequestFieldImage : AMPurpleRequestField {
}

@end

@implementation AMPurpleRequestField

- (id)initWithAccount:(CBPurpleAccount*)_account requestField:(PurpleRequestField*)_field {
    if((self = [super init])) {
        account = _account;
        field = _field;
        
        [[NSBundle mainBundle] loadNibNamed:[self nibName] owner:self topLevelObjects:nil];
        
        height = view.frame.size.height;
        
        NSInteger dh = height - label.frame.size.height;
        
        [[label textStorage] setAttributedString:[self label]];
        
        [label setHorizontallyResizable:FALSE];
        [label setTextContainerInset:NSMakeSize(0, 0)];
        [label sizeToFit];
        
        if (height < label.frame.size.height + dh) {
            height = label.frame.size.height + dh;
        }
	}
    return self;
}

- (NSView *)makeView {
	assert(FALSE);
}

- (NSString *)nibName {
    return nil;
}

- (NSAttributedString *)label
{
    const char *labelstr = purple_request_field_get_label(field);
    
    if (labelstr) {
        NSString *labelString = [NSString stringWithUTF8String:labelstr];
        
        char endsWith = [labelString lastCharacter];
        
        if (endsWith == ':' || endsWith == ';' || endsWith == ',' || endsWith == '.' || endsWith == '?') {
            labelString = [labelString substringToIndex:[labelString length] - 1];
        }
        
        labelString = [labelString stringByAppendingString:@":"];
        
        NSMutableParagraphStyle *rightAlign = [[NSMutableParagraphStyle alloc] init];
        [rightAlign setAlignment:NSRightTextAlignment];
        
        NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:labelString
																		attributes:@{
													 NSParagraphStyleAttributeName: rightAlign,
															   NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]]
										 }];
        
        return labelText;
    }
    
    return [[NSAttributedString alloc] initWithString:@""];
}

- (void)submit
{
    
}

@end

@implementation AMPurpleRequestFieldString

- (NSString *)nibName
{
    return @"RequestFieldString";
}

- (NSView *)makeView
{
    AILogWithSignature(@"Appending this to the window");
	NSString *defaultvalue = [NSString stringWithUTF8String:purple_request_field_string_get_default_value(field)];
    BOOL isEditable = purple_request_field_string_is_editable(field);
    BOOL isVisible = purple_request_field_is_visible(field);
    
    if (!isVisible) return nil;
    
	[textField setEditable:isEditable];
	[textField setStringValue:defaultvalue];
	
	return view;
}

- (void)submit
{
    BOOL isVisible = purple_request_field_is_visible(field);
	
    if (!isVisible) {
        purple_request_field_string_set_value(field, purple_request_field_string_get_default_value(field));
    } else {
        purple_request_field_string_set_value(field, [[textField stringValue] UTF8String]);
    }
}

@end

@implementation AMPurpleRequestFieldSecureString

- (NSString *)nibName
{
    return @"RequestFieldSecureString";
}

- (NSView *)makeView
{
    AILogWithSignature(@"Appending this to the window");
	NSString *defaultvalue = [NSString stringWithUTF8String:purple_request_field_string_get_default_value(field)];
    BOOL isEditable = purple_request_field_string_is_editable(field);
    BOOL isVisible = purple_request_field_is_visible(field);
    
    if (!isVisible) return nil;
    
	[maskedField setEditable:isEditable];
	[maskedField setStringValue:defaultvalue];
	
	return view;
}

- (void)submit
{
    BOOL isVisible = purple_request_field_is_visible(field);
	
    if (!isVisible) {
        purple_request_field_string_set_value(field, purple_request_field_string_get_default_value(field));
	} else {
        purple_request_field_string_set_value(field, [[maskedField stringValue] UTF8String]);
	}
}

@end

@implementation AMPurpleRequestFieldMultilineString

- (NSString *)nibName
{
    return @"RequestFieldMultilineString";
}

- (NSView *)makeView
{
    AILogWithSignature(@"Appending this to the window");
	NSString *defaultvalue = [NSString stringWithUTF8String:purple_request_field_string_get_default_value(field)];
    BOOL isEditable = purple_request_field_string_is_editable(field);
    BOOL isVisible = purple_request_field_is_visible(field);
    
    if (!isVisible) return nil;
    
    [[textView enclosingScrollView] setHasVerticalScroller:TRUE];
    
	[textView setEditable:isEditable];
	[[textView textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:defaultvalue]];
	
	if (height < textView.frame.size.height + 15) {
		height = textView.frame.size.height + 15;
	}
    
    [view setFrame:NSMakeRect(0, 0, view.frame.size.width, height)];
	
	return view;
}

- (void)submit
{
    BOOL isVisible = purple_request_field_is_visible(field);
	
    if (!isVisible) {
        purple_request_field_string_set_value(field, purple_request_field_string_get_default_value(field));
    } else {
        purple_request_field_string_set_value(field, [[[textView textStorage] string] UTF8String]);
	}
}

@end


@implementation AMPurpleRequestFieldInteger

- (NSString *)nibName
{
	return @"RequestFieldInteger";
}


- (NSView *)makeView
{
 	NSInteger defaultvalue = purple_request_field_int_get_default_value(field);
	
	[textField setIntegerValue:defaultvalue];
	
	return view;
}

- (void)submit
{
	purple_request_field_int_set_value(field, [textField intValue]);
}

@end

@implementation AMPurpleRequestFieldBoolean

- (NSString *)nibName
{
    return @"RequestFieldBoolean";
}

- (NSView *)makeView
{
	BOOL defaultvalue = purple_request_field_bool_get_default_value(field);
    
    [checkBox setState:defaultvalue];
	
	return view;
}

- (void)submit
{
    purple_request_field_bool_set_value(field, [checkBox state] == NSOnState);
}

- (NSAttributedString *)label
{
    
    const char *labelstr = purple_request_field_get_label(field);
    
    if (labelstr) {
        NSString *labelString = [NSString stringWithUTF8String:labelstr];
        
        char endsWith = [labelString lastCharacter];
        
        if (endsWith == '.' || endsWith == '?') {
            labelString = [labelString substringToIndex:[labelString length] - 1];
        }
        
        NSAttributedString *labelText = [[NSAttributedString alloc] initWithString:labelString
																		attributes:@{ NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]] }];
        return labelText;
    }
    
    return [[NSAttributedString alloc] initWithString:@""];
}

@end

@implementation AMPurpleRequestFieldChoice

- (NSString *)nibName
{
	return @"RequestFieldChoice";
}


- (NSView *)makeView
{
	GList *labels = purple_request_field_choice_get_labels(field);
	
 	NSInteger defaultvalue = purple_request_field_choice_get_default_value(field);
	
	[view setFrame:NSMakeRect(0, 0, view.frame.size.width, height)];
	
	[popUp removeAllItems];
	
	for (; labels; labels = labels->next) {
		[popUp addItemWithTitle:[NSString stringWithUTF8String:(char *)labels->data]];
	}
	
	if (defaultvalue < [popUp numberOfItems]) {
		[popUp selectItemAtIndex:defaultvalue];
	}
	
	return view;
}

- (void)submit
{
	purple_request_field_choice_set_value(field, (int)[popUp indexOfItem:[popUp selectedItem]]);
}

@end

@implementation AMPurpleRequestFieldList

- (NSString *)nibName
{
    return @"RequestFieldList";
}

- (NSView *)makeView
{
    GList *items = purple_request_field_list_get_items(field);
    
	[popUp removeAllItems];
	
	NSInteger i;
	
    for (i = 0; items; items = items->next, i++) {
		NSString *item = [NSString stringWithUTF8String:items->data];
		[popUp addItemWithTitle:item];
		if (purple_request_field_list_is_selected(field, items->data)) {
			[popUp selectItemAtIndex:i];
		}
    }
    
	return view;
}
- (void)submit
{
	purple_request_field_list_clear_selected(field);
	
	GList *items = NULL;
	const char *text;
	
	text = [[[popUp selectedItem] title] UTF8String];
	items = g_list_prepend(items, (gpointer)text);
	
	purple_request_field_list_set_selected(field, items);
	
	g_list_free(items);
}

@end

@implementation AMPurpleRequestFieldMultiList

- (NSString *)nibName
{
    return @"RequestFieldMultiList";
}

- (NSView *)makeView
{
	GList *items = purple_request_field_list_get_items(field);
    NSInteger i = 0;
	
	[popDown removeAllItems];
	[popDown addItemWithTitle:AILocalizedString(@"Select...", "Used in the request UI for popdown buttons")];
	
    for (i = 0; items; items = items->next, i++) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:items->data]
														  target:self
														  action:@selector(didSelect:)
												   keyEquivalent:@""];
		if(purple_request_field_list_is_selected(field, items->data)) {
			[menuItem setState:NSOnState];
		}
		
		[[popDown menu] addItem:menuItem];
    }
    
	return view;
}

- (IBAction)didSelect:(id)sender
{
	NSInteger state = [sender state];
	
	if (state == NSOnState)
		state = NSOffState;
	else
		state = NSOnState;
	
	[sender setState:state];
}

- (void)submit
{
	purple_request_field_list_clear_selected(field);
	
	BOOL skipped = FALSE;
	
	GList *items = NULL;
	const char *text;
	
	for (NSMenuItem *item in [[popDown menu] itemArray]) {
		if (!skipped) {
			skipped = TRUE;
			continue;
		}
		
		if ([item state] == NSOnState) {
			text = [[item title] UTF8String];
			items = g_list_prepend(items, (gpointer)text);
		}
	}
	
	purple_request_field_list_set_selected(field, items);
	
	g_list_free(items);
}

@end

@implementation AMPurpleRequestFieldLabel

- (NSString *)nibName
{
    return @"RequestFieldLabel";
}

- (NSView *)makeView
{
    [[labelview textStorage] setAttributedString:self.label];
    [labelview setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [labelview setHorizontallyResizable:FALSE];
    [labelview setTextContainerInset:NSMakeSize(0, 0)];
    [labelview sizeToFit];
    
    [view setFrame:NSMakeRect(0, 0, view.frame.size.width, height)];
    
	return view;
}

// Do not append a :
- (NSString *)label
{
    
    const char *labelstr = purple_request_field_get_label(field);
    
    if (labelstr) {
        NSString *labelString = [NSString stringWithUTF8String:labelstr];
        
        return labelString;
    }
    
    return @"";
}

@end

@implementation AMPurpleRequestFieldAccount
// this is not used by libpurple, so should I care about it?
@end

@implementation AMPurpleRequestFieldImage

@end

@implementation AMPurpleRequestFieldsController

- (id)initWithTitle:(NSString*)title
        primaryText:(NSString*)primary
      secondaryText:(NSString*)secondary
      requestFields:(PurpleRequestFields*)_fields
             okText:(NSString*)okText
           callback:(GCallback)_okcb
         cancelText:(NSString*)cancelText
           callback:(GCallback)_cancelcb
            account:(CBPurpleAccount*)account
                who:(NSString*)who
       conversation:(PurpleConversation*)conv
           userData:(void*)_userData {
    if ((self = [super initWithWindowNibName:@"AMPurpleRequestFieldsWindow"])) {
        // we only need to store these fields
        fields = _fields;
        okcb = _okcb;
        cancelcb = _cancelcb;
        userData = _userData;
        
		[self showWindow:nil];
		
		[primaryTextField setStringValue:primary ?: @""];
		
		if (secondary && ![secondary isEqualToString:primary]) {
			[secondaryTextField setStringValue:secondary];
		} else {
			[secondaryTextField setStringValue:@""];
		}
		
        // load field objects
        
        fieldobjects = [[NSMutableArray alloc] init];
        
        GList *gl = purple_request_fields_get_groups(fields);
		GList *fl, *field_list;
		PurpleRequestFieldGroup	*group;
		CGFloat availableHeight = contentView.frame.size.height;
        
		//Look through each group, processing each field and transforming it into an Objective C object
		for (; gl != NULL; gl = gl->next) {
			group = gl->data;
			
			field_list = purple_request_field_group_get_fields(group);
			
			for (fl = field_list; fl != NULL; fl = fl->next) {
                PurpleRequestField		*field;
                
                AMPurpleRequestField *fieldobject = nil;
				
				field = (PurpleRequestField *)fl->data;
				
				Class fieldobjectClass = NULL;
				
				switch(purple_request_field_get_type(field)) {
                    case PURPLE_REQUEST_FIELD_STRING: {
						BOOL isMultiline = purple_request_field_string_is_multiline(field);
						BOOL isMasked = purple_request_field_string_is_masked(field);
						
                        if (isMasked)
							fieldobjectClass = [AMPurpleRequestFieldSecureString class];
						else if (isMultiline)
							fieldobjectClass = [AMPurpleRequestFieldMultilineString class];
						else
							fieldobjectClass = [AMPurpleRequestFieldString class];
						
                        break;
					}
                    case PURPLE_REQUEST_FIELD_INTEGER:
                        fieldobjectClass = [AMPurpleRequestFieldInteger class];
                        break;
                    case PURPLE_REQUEST_FIELD_BOOLEAN:
                        fieldobjectClass = [AMPurpleRequestFieldBoolean class];
                        break;
                    case PURPLE_REQUEST_FIELD_CHOICE:
                        fieldobjectClass = [AMPurpleRequestFieldChoice class];
                        break;
                    case PURPLE_REQUEST_FIELD_LIST: {
						BOOL isMultiSelect = purple_request_field_list_get_multi_select(field);
						
						if (isMultiSelect)
							fieldobjectClass = [AMPurpleRequestFieldMultiList class];
						else
							fieldobjectClass = [AMPurpleRequestFieldList class];
						
                        break;
					}
                    case PURPLE_REQUEST_FIELD_LABEL:
                        fieldobjectClass = [AMPurpleRequestFieldLabel class];
                        break;
					case PURPLE_REQUEST_FIELD_IMAGE:
						fieldobjectClass = [AMPurpleRequestFieldImage class];
						break;
					default:
						break;
                }
                if(fieldobjectClass) {
					fieldobject = [[fieldobjectClass alloc] initWithAccount:account requestField:field];
                    //Keep objects for later processing of the form
					
                    [fieldobjects addObject:fieldobject];
                    NSView *view = [fieldobject makeView];
					
					if (view) {
						CGFloat height = view.frame.size.height;
						AILogWithSignature(@"Resizing by %f", height);
						
						[contentView addSubview:view];
						
						availableHeight -= height;
						
						if (availableHeight < 0) {
							[contentView setFrame:NSMakeRect(contentView.frame.origin.x,
															 contentView.frame.origin.y + availableHeight,
															 contentView.frame.size.width,
															 contentView.frame.size.height - availableHeight)];
							availableHeight = 0.0;
						}
						
						[view setFrameOrigin:NSMakePoint(0.0, availableHeight)];
						[view setFrameSize:NSMakeSize(contentView.frame.size.width, view.frame.size.height)];
					}
					
                    fieldobject = nil;
                }
            }
        }
		
		if(title)
			[[self window] setTitle:title];
		else
			[[self window] setTitle:AILocalizedString(@"Form","Generic fields request window title")];
    	
		if (_okcb) [okButton setTitle:okText];
		else [okButton setHidden:TRUE];
    
		if (_cancelcb) [cancelButton setTitle:cancelText];
		else [cancelButton setHidden:TRUE];
    
		[[self window] makeKeyAndOrderFront:nil];
	}
    
    return self; // keep us as long as the form is open
}

- (IBAction)submit:(id)sender
{
    for (AMPurpleRequestField *fieldobject in fieldobjects) {
        [fieldobject submit];
    }
    
    if (okcb) {
        ((PurpleRequestFieldsCb)okcb)(userData, fields);
		okcb = NULL;
		cancelcb = NULL;
    }
    [self close];
}

- (IBAction)cancel:(id)sender
{
    if (cancelcb) {
        ((PurpleRequestFieldsCb)cancelcb)(userData, fields);
		okcb = NULL;
		cancelcb = NULL;
    }
    [self close];
}

/*!
 * @brief libpurple has been made aware we closed or has informed us we should close
 *
 * If we haven't trigerred a callback yet, we shouldn't now; the data in question is likely invalid
 * and will crash if used since purple is closing our request at the source
 */
- (void)purpleRequestClose
{
	okcb = NULL;
	cancelcb = NULL;

	[super purpleRequestClose];
}

@end
