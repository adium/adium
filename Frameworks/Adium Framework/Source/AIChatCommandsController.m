//
//  AIChatCommandsController.m
//  Adium
//
//  Created by Erik Beerepoot on 11/07/07.
//  Copyright 2007 Adium. All rights reserved.
//

#import "AIChatCommandsController.h"
@interface AIChatCommandsController (PRIVATE)
- (void)verifyCommand:(NSString*)command forChat:(AIChat*)chat;
@end

@implementation AIChatCommandsController

+ (void)showCommand:(NSString *)command forChat:(AIChat *)chat
{
	AIChatCommandsController *controller = [[self alloc] init];
	[controller verifyCommand:command forChat:chat];
	[controller release];
}

- (void)dealloc
{
	[parameters release];
	
	[super dealloc];
}

/* @name	verifyCommand
 * @param	command: command picked by the user
 *			AIChat: the chat the command was issued from
 * @brief	the method shows the user a sheet to input the 
 *			appropriate information. 
 */
 
-(void)verifyCommand:(NSString*)command forChat:(AIChat*)chat;
{
	parameters = [[NSMutableDictionary alloc] init];
	[parameters setObject:chat forKey:@"chat"];
	[parameters setObject:[chat account] forKey:@"account"];
	[parameters setObject:[command stringByAppendingString:@" "] forKey:@"command"];

	//check what command was given & set proper label
	if([command isEqualTo:@"kick"]) {
		[NSBundle loadNibNamed:@"ChatPrompt" owner:self];
		[textField_comment setStringValue:@"(optional)"];
	} else if ([command isEqualTo:@"Ban User:"]) {
		[NSBundle loadNibNamed:@"ChatPrompt" owner:self];
		[label_target setStringValue:@"Ban:"];
		[textField_comment setStringValue:@"(optional)"];
	} else if([command isEqualTo:@"topic"]) {
		[NSBundle loadNibNamed:@"BanPrompt" owner:self];
		[label_target setStringValue:@"Set topic:"];
	} else if([command isEqualTo:@"invite"]) {
		[NSBundle loadNibNamed:@"ChatPrompt" owner:self];
		[label_target setStringValue:@"Invite User:"];
		[textField_comment setStringValue:@"(optional)"];
	} else if([command isEqualTo:@"msg"]) {
		[NSBundle loadNibNamed:@"ChatPrompt" owner:self];
		[label_target setStringValue:@"Message User:"];
		[label_comment setStringValue:@"Message:"];
	} else if([command isEqualTo:@"part"]) {
		[NSBundle loadNibNamed:@"BanPrompt" owner:self];
		[label_target setStringValue:@"Leave room with comment:"];
	} else if([command isEqualTo:@"nick"]) {
		[NSBundle loadNibNamed:@"BanPrompt" owner:self];
		[label_target setStringValue:@"Enter new handle:"];
	} else if([command isEqualTo:@"msg"]) {
		[NSBundle loadNibNamed:@"ChatPrompt" owner:self];
		[label_target setStringValue:@"Join room:"];
		[label_comment setStringValue:@"Password:"];
		[textField_comment setStringValue:@"(optional)"];
	} else if([command isEqualTo:@"role"]) {
		[NSBundle loadNibNamed:@"ChatPrompt" owner:self];
		[label_target setStringValue:@"Set role for user:"];
		[label_comment setStringValue:@"Role:"];
	} else if([command isEqualTo:@"affiliate"]) {
		[NSBundle loadNibNamed:@"ChatPrompt" owner:self];
		[label_target setStringValue:@"Set affiliation for user:"];
		[label_comment setStringValue:@"Affiliation:"];
	} else if([command isEqualTo:@"join"]) {
		[NSBundle loadNibNamed:@"BanPrompt" owner:self];
		[label_target setStringValue:@"Join room:"];
	} else {
		NSRunAlertPanel(@"Command not supported", @"This command is not supported at this time",@"Cancel",@"OK",nil);
	}
	
	//show sheet
	[self showWindow:[self window]];
	[[self window] center];
	
	//Will release when the window closes;
	[self retain];
}

/* @name	ok
 * @brief	method  called when the user presses ok
 *			on the input sheet. This method calls
 *			"doCommand" on the delegate. 
 */
- (IBAction)ok:(id)sender
{
	/* the proper command string is in the form:
	* "/ command target"
	* make sure this is the form "totalCommandString has"
	*/
	
	NSMutableString *totalCommandString = [NSMutableString stringWithFormat:@"/%@", [parameters objectForKey:@"command"]];

	if ([[textField_target stringValue] length]) {
		[totalCommandString appendFormat:@" %@", [textField_target stringValue]];
	}

	if ([[textField_comment stringValue] length]) {
		[totalCommandString appendFormat:@" %@", [textField_comment stringValue]];
	}

	[parameters setObject:totalCommandString forKey:@"totalCommandString"];	
	[[[parameters objectForKey:@"chat"] account] executeCommandWithParameters:parameters];
	
	[sheet orderOut:nil];
	[NSApp endSheet:sheet];
	
	[self autorelease];
}

/* @name	cancel
 * @brief	method called when user presses cancel on the sheet
 *			dismisses the sheet
 */
-(IBAction)cancel:(id)sender
{
	[sheet orderOut:nil];
	[NSApp endSheet:sheet];
	
	[self autorelease];
}

@end
