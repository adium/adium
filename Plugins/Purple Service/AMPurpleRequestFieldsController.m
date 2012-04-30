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
#import <AIUtilities/AIStringAdditions.h>

@interface WebView ()
- (void)setDrawsBackground:(BOOL)flag;
- (void)setBackgroundColor:(NSColor *)color;
@end

@interface AMPurpleRequestField : NSObject {
    PurpleRequestField *field;
    CBPurpleAccount *account;
}

- (id)initWithAccount:(CBPurpleAccount*)_account requestField:(PurpleRequestField*)_field;

- (NSXMLElement*)xhtml;
- (NSString*)key;

- (void)applyValue:(NSString*)value;

@end

@interface AMPurpleRequestFieldString : AMPurpleRequestField {
}

@end

@interface AMPurpleRequestFieldInteger : AMPurpleRequestField {
}

@end

@interface AMPurpleRequestFieldBoolean : AMPurpleRequestField {
}

@end

@interface AMPurpleRequestFieldChoice : AMPurpleRequestField {
}

@end

@interface AMPurpleRequestFieldList : AMPurpleRequestField {
}

@end

@interface AMPurpleRequestFieldLabel : AMPurpleRequestField {
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
    }
    return self;
}

- (NSXMLElement*)xhtml {
	NSXMLElement *result = [NSXMLNode elementWithName:@"div"];
	
	[result addAttribute:[NSXMLNode attributeWithName:@"class" stringValue:@"field"]];
	
	const char *labelstr = purple_request_field_get_label(field);
	
	if(labelstr) {
		NSXMLElement *label = [NSXMLNode elementWithName:@"label" stringValue:[NSString stringWithUTF8String:labelstr]];
		[label addAttribute:[NSXMLNode attributeWithName:@"for" stringValue:[self key]]];
		
		[result addChild:[NSXMLNode elementWithName:@"div"
										   children:[NSArray arrayWithObject:label]
										 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"label"]]]];
	}
	return result;
}

- (NSString*)key {
    return [NSString stringWithFormat:@"%p",self];
}

- (void)applyValue:(NSString*)value {
    NSLog(@"Applied the value \"%@\" to an AMPurpleRequestField!", value);
}

@end

@implementation AMPurpleRequestFieldString

- (NSXMLElement*)xhtml {
	NSXMLElement *result = [super xhtml];
	
	const char *defaultvalue = purple_request_field_string_get_default_value(field);
	BOOL isMultiline = (purple_request_field_string_is_multiline(field) == TRUE) ? YES : NO;
	BOOL isEditable = (purple_request_field_string_is_editable(field) == TRUE) ? YES : NO;
	BOOL isMasked = (purple_request_field_string_is_masked(field) == TRUE) ? YES : NO;
	BOOL isVisible = (purple_request_field_is_visible(field) == TRUE) ? YES : NO;
	
	NSXMLElement *textinput;
	
	if(isMultiline) {
		textinput = [NSXMLNode elementWithName:@"textarea"];
		[textinput addAttribute:[NSXMLNode attributeWithName:@"rows" stringValue:@"5"]];
		[textinput addAttribute:[NSXMLNode attributeWithName:@"cols" stringValue:@"40"]];
		if(defaultvalue)
			[textinput setStringValue:[NSString stringWithUTF8String:defaultvalue]];
	} else {
		textinput = [NSXMLNode elementWithName:@"input"];
		if (isVisible)
			[textinput addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:isMasked?@"password":@"text"]];
		else
			[textinput addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"hidden"]];
		[textinput addAttribute:[NSXMLNode attributeWithName:@"size" stringValue:@"50"]];
		if(defaultvalue)
			[textinput addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[NSString stringWithUTF8String:defaultvalue]]];
	}
	[textinput addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[self key]]];
	if(!isEditable)
		[textinput addAttribute:[NSXMLNode attributeWithName:@"readonly" stringValue:@"readonly"]];

	if (isVisible)
		[result addChild:[NSXMLNode elementWithName:@"div"
										   children:[NSArray arrayWithObject:textinput]
										 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"input"]]]];
	else
		return textinput;

    return result;
}

- (void)applyValue:(NSString*)value {
	purple_request_field_string_set_value(field, [value UTF8String]);
}

@end


@implementation AMPurpleRequestFieldInteger

- (NSXMLElement*)xhtml {
	NSXMLElement *result = [super xhtml];
	
	NSInteger defaultvalue = purple_request_field_int_get_default_value(field);
	
	NSXMLElement *textinput = [NSXMLNode elementWithName:@"input"];
	[textinput addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"text"]];
	[textinput addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[NSString stringWithFormat:@"%ld",defaultvalue]]];
	[textinput addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[self key]]];
	// XXX add javascript to make sure this is integer-only

	[result addChild:[NSXMLNode elementWithName:@"div"
									   children:[NSArray arrayWithObject:textinput]
									 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"input"]]]];

    return result;
}

- (void)applyValue:(NSString*)value {
	purple_request_field_int_set_value(field, [value intValue]);
}

@end

@implementation AMPurpleRequestFieldBoolean

- (NSXMLElement*)xhtml {
	NSXMLElement *result = [super xhtml];
	
	BOOL defaultvalue = (purple_request_field_bool_get_default_value(field) == TRUE) ? YES : NO;
	
	NSXMLElement *checkbox = [NSXMLNode elementWithName:@"input"];
	[checkbox addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"checkbox"]];
	[checkbox addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[self key]]];
	[checkbox addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[self key]]];

	if(defaultvalue)
		[checkbox addAttribute:[NSXMLNode attributeWithName:@"checked" stringValue:@"checked"]];

	[result addChild:[NSXMLNode elementWithName:@"div"
									   children:[NSArray arrayWithObject:checkbox]
									 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"input"]]]];
	
	purple_request_field_bool_set_value(field, FALSE); // since we won't get an -applyValue: message when the checkbox isn't checked, assume false for now. This might be changed later.
    return result;
}

- (void)applyValue:(NSString*)value {
	purple_request_field_bool_set_value(field, TRUE);
}

@end

@implementation AMPurpleRequestFieldChoice

- (NSXMLElement*)xhtml {
	NSXMLElement *result = [super xhtml];
	
	GList *labels = purple_request_field_choice_get_labels(field);
	
	guint len = g_list_length(labels);
	NSInteger defaultvalue = purple_request_field_choice_get_default_value(field);
	
	// Apple HIG: Don't use checkboxes for lists of more than 5 items, use a popupbutton instead
	if(len > 5) {
		NSXMLElement *popup = [NSXMLNode elementWithName:@"select"];
		[popup addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[self key]]];
		NSInteger i=0;
		GList *label;
		for(label = labels; label; label = g_list_next(label), ++i) {
			const char *labelstr = label->data;
			if(!labelstr)
				continue;
			
			NSXMLElement *option = [NSXMLNode elementWithName:@"option" stringValue:[NSString stringWithUTF8String:labelstr]];
			[option addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[NSString stringWithFormat:@"%lu",i]]];
			if(i == defaultvalue)
				[option addAttribute:[NSXMLNode attributeWithName:@"selected" stringValue:@"selected"]];
			[popup addChild:option];
		}
		[result addChild:[NSXMLNode elementWithName:@"div"
										   children:[NSArray arrayWithObject:popup]
										 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"input"]]]];
	} else {
		NSInteger i=0;
		NSMutableArray *radios = [NSMutableArray array];
		GList *label;
		for(label = labels; label; label = g_list_next(label), ++i) {
			const char *labelstr = label->data;
			if(!labelstr)
				continue;
			
			NSXMLElement *radiobutton = [NSXMLNode elementWithName:@"input"];
			[radiobutton addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"radio"]];
			[radiobutton addAttribute:[NSXMLNode attributeWithName:@"value" stringValue:[NSString stringWithFormat:@"%lu",i]]];
			[radiobutton addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[self key]]];

			if(i == defaultvalue)
				[radiobutton addAttribute:[NSXMLNode attributeWithName:@"checked" stringValue:@"checked"]];
			
			[radios addObject:radiobutton];
			[radios addObject:[NSXMLNode textWithStringValue:[NSString stringWithUTF8String:labelstr]]];
		}
		[result addChild:[NSXMLNode elementWithName:@"div"
										   children:radios
										 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"input"]]]];
	}
	
    return result;
}

- (void)applyValue:(NSString*)value {
	purple_request_field_choice_set_value(field, [value intValue]);
}

@end

@implementation AMPurpleRequestFieldList

- (NSXMLElement*)xhtml {
	NSXMLElement *result = [super xhtml];
	
	BOOL isMultiSelect = (purple_request_field_list_get_multi_select(field) == TRUE) ? YES : NO;

	NSXMLElement *list = [NSXMLNode elementWithName:@"select"];
	[list addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[self key]]];
	
	if(isMultiSelect)
		[list addAttribute:[NSXMLNode attributeWithName:@"multiple" stringValue:@"multiple"]];

	const GList *items = purple_request_field_list_get_items(field);
	guint len = g_list_length((GList*)items);
	
	// show all items up to 10
	[list addAttribute:[NSXMLNode attributeWithName:@"size" stringValue:[NSString stringWithFormat:@"%u",(len>10)?10:len]]];
	
	const GList *item;
	for(item = items; item; item = g_list_next(item)) {
		const char *labelstr = item->data;
		if(!labelstr)
			continue;
		
		NSXMLElement *option = [NSXMLNode elementWithName:@"option" stringValue:[NSString stringWithUTF8String:labelstr]];
		if(purple_request_field_list_is_selected(field, labelstr))
			[option addAttribute:[NSXMLNode attributeWithName:@"selected" stringValue:@"selected"]];
		[list addChild:option];
	}
	[result addChild:[NSXMLNode elementWithName:@"div"
									   children:[NSArray arrayWithObject:list]
									 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"input"]]]];
	
	purple_request_field_list_clear_selected(field);
	
	return result;
}

- (void)applyValue:(NSString*)value {
	purple_request_field_list_add_selected(field, [value UTF8String]);
}

@end

@implementation AMPurpleRequestFieldLabel

#if 0
- (NSXMLNode*)xhtml {
    return [super xhtml];
}
#endif

@end

@implementation AMPurpleRequestFieldAccount
// this is not used by libpurple, so should I care about it?
@end

@implementation AMPurpleRequestFieldImage

- (NSXMLElement*)xhtml {
	NSXMLElement *result = [super xhtml];
	
	//unsigned int scale_x = purple_request_field_image_get_scale_x(field);
	//unsigned int scale_y = purple_request_field_image_get_scale_y(field);
		
	//This could be base 64 encoded and embedded directly, but it seems like a heavy fix...
	NSData *data = [NSData dataWithBytes:purple_request_field_image_get_buffer(field)
								  length:purple_request_field_image_get_size(field)];
				
	NSString *extension = [NSImage extensionForBitmapImageFileType:[NSImage fileTypeOfData:data]];
	if (!extension) {
		//We don't know what it is; try to make a png out of it
		NSImage				*image = [[NSImage alloc] initWithData:data];
		NSData				*imageTIFFData = [image TIFFRepresentation];
		NSBitmapImageRep	*bitmapRep = [NSBitmapImageRep imageRepWithData:imageTIFFData];
		
		data = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
		extension = @"png";
		[image release];
	}

	NSString *filename = [[[NSString stringWithFormat:@"TEMP-Image_%@",[self key]] stringByAppendingPathExtension:extension] safeFilenameString];
	NSString *imagePath = [[adium cachesPath] stringByAppendingPathComponent:filename];

	NSXMLElement *imageElement = [NSXMLNode elementWithName:@"image"];

	if ([data writeToFile:imagePath atomically:YES]) {
		[imageElement addAttribute:[NSXMLNode attributeWithName:@"src" stringValue:[[NSURL fileURLWithPath:imagePath] absoluteString]]];
		[imageElement addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[self key]]];

		[result addChild:[NSXMLNode elementWithName:@"div"
										   children:[NSArray arrayWithObject:imageElement]
										 attributes:[NSArray arrayWithObject:[NSXMLNode attributeWithName:@"class" stringValue:@"image"]]]];		
	} else {
		AILogWithSignature(@"Failed to write image to %@",imagePath);
	}

    return result;
}


@end


@interface AMPurpleRequestFieldsController ()
- (void)loadForm:(NSXMLDocument*)doc;
- (void)webviewWindowWillClose:(NSNotification *)notification;
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
        
        // generate XHTML
        NSXMLElement *root = [NSXMLNode elementWithName:@"html"];
        [root addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://www.w3.org/1999/xhtml"]];
        NSXMLElement *head = [NSXMLNode elementWithName:@"head"];
        [root addChild:head];
        
        [head addChild:[NSXMLNode elementWithName:@"style" children:[NSArray arrayWithObject:
            [NSXMLNode textWithStringValue:
                @"body {"
				@"	font-family:'Lucida Grande';"
				@"	font-size: 13pt;"
				@"}"
				@"h1 {"
				@"	display: none;"
				@"}"
				@"h2 {"
				@"	font-size: 13pt;"
				@"	font-weight: normal;"
				@"}"
				@"h3 {"
				@"	font-size: 11pt;"
				@"	font-weight: normal;"
				@"}"
				@"#formwrapper"
				@"{"
				@"	position: fixed;"
				@"	top: 0px;"
				@"	left: 0;"
				@"	bottom: 50px;"
				@"	right: 0;"
				@"	overflow: auto;"
				@"}"
				@"#form2"
				@"{"
				@"	margin: 20px;"
				@"	overflow: none;"
				@"}"
				@"#formtable"
				@"{"
				@"	display: table;"
				@"	margin: 0 auto;"
				@"}"
				@".field {"
				@"	position: relative;"
				@"	display: table-row;"
				@"	font-size: 13pt;"
				@"}"
				@".label {"
				@"	text-align: right;"
				@"	display: table-cell;"
				@"	width: 50%;"
				@"	padding-right: .2em;"
				@"	vertical-align: top;"
				@"	font-size: 13pt;"
				@"}"
				@".label:after {"
				@"	content: \":\";"
				@"}"
				@".input {"
				@"	display: table-cell;"
				@"	width: 50%;"
				@"	padding-left: .2em;"
				@"	vertical-align: top;"
				@"}"
				@"#cancel {"
				@"	font-size: 13pt;"
				@"	margin-right: 10px;"
				@"}"
				@"#submit {"
				@"	font-size: 13pt;"
				@"	margin-right: 20px;"
				@"	margin-left: 10px;"
				@"}"
				@"#submitbuttons {"
				@"	text-align: right;"
				@"	position: absolute;"
				@"	bottom: 0;"
				@"	right: 0;"
				@"	overflow: auto;"
				@"	height: 45px;"
				@"	width: 100%;"
				@"	border-color: #000;"
				@"	border-width: 1px 0 0 0;"
				@"	border-style: solid;"
				@"}"
                ]] attributes:[NSArray arrayWithObject:
                    [NSXMLNode attributeWithName:@"type" stringValue:@"text/css"]]]];

        NSXMLElement *titleelem = [NSXMLNode elementWithName:@"title" stringValue:title];
        [head addChild:titleelem];

        NSXMLElement *body = [NSXMLNode elementWithName:@"body"];
        [root addChild:body];

        
        NSXMLElement *formnode = [NSXMLNode elementWithName:@"form" children:nil attributes:[NSArray arrayWithObjects:
            [NSXMLNode attributeWithName:@"action" stringValue:@"http://www.adium.im/XMPP/form"],
            [NSXMLNode attributeWithName:@"method" stringValue:@"POST"],nil]];
        [body addChild:formnode];
		
		NSXMLElement *formwrapper = [NSXMLNode elementWithName:@"div"];
		[formwrapper addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"formwrapper"]];
		[formnode addChild:formwrapper];
		NSXMLElement *form2 = [NSXMLNode elementWithName:@"div"];
		[form2 addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"form2"]];
		[formwrapper addChild:form2];
		
		formwrapper = form2;

		NSXMLElement *heading = [NSXMLNode elementWithName:@"h1" stringValue:title];
        [formwrapper addChild:heading];
		
        NSXMLElement *heading2 = [NSXMLNode elementWithName:@"h2" stringValue:primary];
        [formwrapper addChild:heading2];
		
        NSXMLElement *heading3 = [NSXMLNode elementWithName:@"h3" stringValue:secondary];
        [formwrapper addChild:heading3];
		
		NSXMLElement *formdiv = [NSXMLNode elementWithName:@"div"];
		[formdiv addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:@"formtable"]];
		[formwrapper addChild:formdiv];
		
        // load field objects
        
        fieldobjects = [[NSMutableDictionary alloc] init];
        
        GList *gl = purple_request_fields_get_groups(fields);
		GList *fl, *field_list;
		PurpleRequestFieldGroup	*group;
        
        NSXMLElement *fieldset;
		guint len = g_list_length(gl);
        
		//Look through each group, processing each field and transforming it into an Objective C object
		for (; gl != NULL; gl = gl->next) {
			group = gl->data;
			// only display groups when there's more than one
			if(len > 1) {
				fieldset = [NSXMLNode elementWithName:@"fieldset"];
				[formdiv addChild:fieldset];

				const char *fieldtitle = purple_request_field_group_get_title(group);
				if(fieldtitle)
					[fieldset addChild:[NSXMLNode elementWithName:@"legend" stringValue:[NSString stringWithUTF8String:fieldtitle]]];
			} else
				fieldset = formdiv;
			
			field_list = purple_request_field_group_get_fields(group);
			
			for (fl = field_list; fl != NULL; fl = fl->next) {
                PurpleRequestField		*field;
                
                AMPurpleRequestField *fieldobject = nil;

				field = (PurpleRequestField *)fl->data;
				switch(purple_request_field_get_type(field)) {
                    case PURPLE_REQUEST_FIELD_STRING:
                        fieldobject = [[AMPurpleRequestFieldString alloc] initWithAccount:account requestField:field];
                        break;
                    case PURPLE_REQUEST_FIELD_INTEGER:
                        fieldobject = [[AMPurpleRequestFieldInteger alloc] initWithAccount:account requestField:field];
                        break;
                    case PURPLE_REQUEST_FIELD_BOOLEAN:
                        fieldobject = [[AMPurpleRequestFieldBoolean alloc] initWithAccount:account requestField:field];
                        break;
                    case PURPLE_REQUEST_FIELD_CHOICE:
                        fieldobject = [[AMPurpleRequestFieldChoice alloc] initWithAccount:account requestField:field];
                        break;
                    case PURPLE_REQUEST_FIELD_LIST:
                        fieldobject = [[AMPurpleRequestFieldList alloc] initWithAccount:account requestField:field];
                        break;
                    case PURPLE_REQUEST_FIELD_LABEL:
                        fieldobject = [[AMPurpleRequestFieldLabel alloc] initWithAccount:account requestField:field];
                        break;
					case PURPLE_REQUEST_FIELD_IMAGE:
						fieldobject = [[AMPurpleRequestFieldImage alloc] initWithAccount:account requestField:field];
						break;
						/*
                    case PURPLE_REQUEST_FIELD_ACCOUNT:
                        fieldobject = [[AMPurpleRequestFieldAccount alloc] initWithAccount:account requestField:field];
                        break;
						 */
                    default:
                        fieldobject = nil;
                }
                if(fieldobject) {
                    //Keep objects for later processing of the form
                    [fieldobjects setObject:fieldobject forKey:[fieldobject key]];

                    //Insert the field into the XHTML document
                    [fieldset addChild:[fieldobject xhtml]];
                    [fieldobject release];
                }
            }
        }
        
        [formnode addChild:[NSXMLNode elementWithName:@"div" children:[NSArray arrayWithObjects:
#if 0
            [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"type" stringValue:@"submit"],
                [NSXMLNode attributeWithName:@"id" stringValue:@"cancel"],
                [NSXMLNode attributeWithName:@"value" stringValue:cancelText],nil]],
#endif
            [NSXMLNode elementWithName:@"input" children:nil attributes:[NSArray arrayWithObjects:
                [NSXMLNode attributeWithName:@"type" stringValue:@"submit"],
                [NSXMLNode attributeWithName:@"id" stringValue:@"submit"],
                [NSXMLNode attributeWithName:@"value" stringValue:okText],nil]],
			nil] attributes:[NSArray arrayWithObject:[NSXMLElement attributeWithName:@"id" stringValue:@"submitbuttons"]]]];
        
        NSXMLDocument *doc = [NSXMLNode documentWithRootElement:root];
        [doc setCharacterEncoding:@"UTF-8"];
        [doc setDocumentContentKind:NSXMLDocumentXHTMLKind];
        
		if(title)
			[[self window] setTitle:title];
		else
			[[self window] setTitle:AILocalizedString(@"Form","Generic fields request window title")];
		
		/*
		 //Code here originally made the webview transparent; the result is an all-black window. I don't think this is desired.
		if ([webview respondsToSelector:@selector(setBackgroundColor:)]) {
			//As of Safari 3.0, we must call setBackgroundColor: to make the webview transparent
			[webview setBackgroundColor:[NSColor clearColor]];

		} else {
			[webview setDrawsBackground:NO];
		}
		 */
		 
        [self performSelector:@selector(loadForm:) withObject:doc afterDelay:0.0];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(webviewWindowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:[self window]];
    }

    return [self retain]; // keep us as long as the form is open
}

- (void)dealloc {
    [fieldobjects release];

    [super dealloc];
}

- (void)loadForm:(NSXMLDocument*)doc {
    NSData *formdata = [doc XMLDataWithOptions:NSXMLDocumentTidyHTML | NSXMLDocumentIncludeContentTypeDeclaration];
    [[webview mainFrame] loadData:formdata MIMEType:@"application/xhtml+xml" textEncodingName:@"UTF-8" baseURL:nil];

    [self showWindow:nil];
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

#pragma mark WebView Delegate Methods

- (void)webviewWindowWillClose:(NSNotification *)notification {
    [webview setPolicyDelegate:nil];
   
    if (wasSubmitted) {
        if (okcb)
            ((PurpleRequestFieldsCb)okcb)(userData, fields);
    } else {
        if (cancelcb)
            ((PurpleRequestFieldsCb)cancelcb)(userData, fields);
    }
    
    [self autorelease]; // no we don't need us no longer, commit suicide
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
		  frame:(WebFrame *)frame
	decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if ([[[request URL] scheme] isEqualToString:@"applewebdata"] || [[[request URL] scheme] isEqualToString:@"about"])
        [listener use];

    else {
        if ([[[request URL] absoluteString] isEqualToString:@"http://www.adium.im/XMPP/form"]) {
            NSString *info = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
            NSArray *formfields = [info componentsSeparatedByString:@"&"];
            [info release];
            
            NSString *field;
            for (field in formfields) {
                NSArray *keyvalue = [field componentsSeparatedByString:@"="];
                if ([keyvalue count] != 2)
                    continue;
				
                NSString *key = [[[keyvalue objectAtIndex:0] mutableCopy] autorelease];
                [(NSMutableString *)key replaceOccurrencesOfString:@"+"
														withString:@" " 
														   options:NSLiteralSearch 
															 range:NSMakeRange(0,[key length])];
                
                key = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                          (CFStringRef)key,
                                                                                          (CFStringRef)@"", kCFStringEncodingUTF8);
                
                NSString *value = [[[keyvalue objectAtIndex:1] mutableCopy] autorelease];
                [(NSMutableString *)value replaceOccurrencesOfString:@"+" 
														  withString:@" " 
															 options:NSLiteralSearch 
															   range:NSMakeRange(0,[value length])];
                
                value = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                            (CFStringRef)value,
                                                                                            (CFStringRef)@"", kCFStringEncodingUTF8);
                
				[[fieldobjects objectForKey:key] applyValue:value];
                
                [key release];
                [value release];
            }
            
			wasSubmitted = YES;
            [self close];
        }

        [listener ignore];
    }
}

@end
