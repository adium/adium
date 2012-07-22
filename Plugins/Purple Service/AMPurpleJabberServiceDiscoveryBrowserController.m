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

#import "AMPurpleJabberServiceDiscoveryBrowserController.h"
#import "AMPurpleJabberNode.h"
#import <libpurple/jabber.h>
#import <Adium/DCJoinChatWindowController.h>
#import "DCPurpleJabberJoinChatViewController.h"

@implementation AMPurpleJabberServiceDiscoveryBrowserController

extern void jabber_adhoc_execute(JabberStream *js, JabberAdHocCommands *cmd);

static NSImage *downloadprogress = nil;
static NSImage *det_triangle_opened = nil;
static NSImage *det_triangle_closed = nil;

- (id)initWithAccount:(AIAccount*)_account purpleConnection:(PurpleConnection *)_gc node:(AMPurpleJabberNode *)_node
{
    if ((self = [super initWithWindowNibName:@"AMPurpleJabberDiscoveryBrowser"])) {
		account = _account;
        gc = _gc;

		//Load the window immediately
		[self window];

		node = [_node retain];
		[node addDelegate:self];
		if (![node items])
			[node fetchItems];
		if (![node identities])
			[node fetchInfo];
        
        [[self window] makeKeyAndOrderFront:nil];
		
        [self retain];
        [outlineview setTarget:self];
        [outlineview setDoubleAction:@selector(openService:)];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[node release];
    [super dealloc];
}

- (NSString *)adiumFrameAutosaveName
{
	return @"Jabber Service Discovery Browser";
}

- (void)windowDidLoad
{
	[[self window] setTitle:AILocalizedString(@"Service Discovery Browser", "Window title for the service discovery browser")];
	[label_service setLocalizedString:AILocalizedString(@"Service:", nil)];
	[label_node setLocalizedString:AILocalizedString(@"Node:", nil)];
	
	[[[outlineview tableColumnWithIdentifier:@"name"] headerCell] setStringValue:AILocalizedString(@"Name", "Name table column header for the service discovery browser")];
	[[[outlineview tableColumnWithIdentifier:@"jid"] headerCell] setStringValue:AILocalizedString(@"JID", "JID (Jabber ID) table column header for the service discovery browser. This may not need to be localized.")];
	[[[outlineview tableColumnWithIdentifier:@"category"] headerCell] setStringValue:AILocalizedString(@"Category", "Category table column header for the service discovery browser")];
	
	[super windowDidLoad];

}

- (IBAction)openService:(id)sender
{
    NSInteger row = [outlineview clickedRow];
    if (row != -1) {
		AMPurpleJabberNode *item = [outlineview itemAtRow:row];
		NSArray *identities = [item identities];
		if (!identities)
			return;
		NSDictionary *identity;
		
		for (identity in identities) {
			if ([[identity objectForKey:@"category"] isEqualToString:@"gateway"])
			/* XXX Using 'extern' declared function from jabber prpl */
				jabber_register_gateway((JabberStream*)gc->proto_data, [[item jid] UTF8String]);
			else if ([[identity objectForKey:@"category"] isEqualToString:@"conference"]) {
                DCJoinChatWindowController *jcwc = [DCJoinChatWindowController showJoinChatWindow];
                [jcwc configureForAccount:account];
                
				NSRange atsign = [[item jid] rangeOfString:@"@"];
				if (atsign.location == NSNotFound)
					[(DCPurpleJabberJoinChatViewController*)[jcwc joinChatViewController] setServer:[item jid]];
				else {
					[(DCPurpleJabberJoinChatViewController*)[jcwc joinChatViewController] setServer:[[item jid] substringFromIndex:atsign.location+1]];
					[(DCPurpleJabberJoinChatViewController*)[jcwc joinChatViewController] setRoomName:[[item jid] substringToIndex:atsign.location]];
				}
			} else if ([[identity objectForKey:@"category"] isEqualToString:@"directory"]) {
				/* XXX Using 'extern' declared function from jabber prpl */
				jabber_user_search((JabberStream*)gc->proto_data, [[item jid] UTF8String]);
			} else if ([[identity objectForKey:@"category"] isEqualToString:@"automation"] &&
					   [[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
				JabberAdHocCommands cmd;
				
				cmd.jid = (char*)[[item jid] UTF8String];
				cmd.node = (char*)[[item node] UTF8String];
				cmd.name = (char*)[[item name] UTF8String];
				
				/* XXX Using 'extern' declared function from jabber prpl */
				jabber_adhoc_execute(gc->proto_data, &cmd);
			}
		}
    }
}

- (IBAction)performCommand:(id)sender {
	AMPurpleJabberNode *commandnode = [sender representedObject];
	
	JabberAdHocCommands cmd;
	
	cmd.jid = (char*)[[commandnode jid] UTF8String];
	cmd.node = (char*)[[commandnode node] UTF8String];
	cmd.name = (char*)[[commandnode name] UTF8String];
	
	/* XXX Using 'extern' declared function from jabber prpl */
	jabber_adhoc_execute(gc->proto_data, &cmd);
}

- (NSMenu *)outlineView:(NSOutlineView *)outlineView menuForEvent:(NSEvent *)theEvent
{
	NSMenu	*menu = nil;
	NSInteger		row = [outlineView rowAtPoint:[outlineView convertPoint:[theEvent locationInWindow]
														fromView:nil]];
	
	if (row != -1) {
		id item = [outlineView itemAtRow:row];
		NSArray *commands = [(AMPurpleJabberNode*)item commands];
		
		if (commands) {
			menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
			AMPurpleJabberNode *command;
			
			for (command in commands) {
				NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:[command name]
															   action:@selector(performCommand:)
														keyEquivalent:@""];
				[mitem setTarget:self];
				[mitem setRepresentedObject:command];
				[menu addItem:mitem];
				[mitem release];
			}
		}
	}
	
	return menu;
}

- (IBAction)changeServiceName:(id)sender {
	[node release];
	node = [[AMPurpleJabberNode alloc] initWithJID:[servicename stringValue] node:([[nodename stringValue] length]>0)?[nodename stringValue]:nil name:nil connection:gc];
	[node addDelegate:self];
	[node fetchInfo];
	[outlineview reloadData];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self release];
	
	[super windowWillClose:notification];
}

- (void)jabberNodeGotItems:(AMPurpleJabberNode*)node {
    [outlineview reloadData];
}

- (void)jabberNodeGotInfo:(AMPurpleJabberNode*)node {
    [outlineview reloadData];
}

#pragma mark Outline View

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)idx ofItem:(id)item
{
	if (!item)
		return node;
	return [[item items] objectAtIndex:idx];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (![item items]) {
		// unknown
		return YES;
	}
	return [[item items] count] > 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return [item identities] != NULL;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	if ([outlineview selectedRow] != -1) {
		AMPurpleJabberNode *selection = [outlineview itemAtRow:[outlineview selectedRow]];
		if (![selection features])
			[selection fetchInfo];
		[servicename setStringValue:[selection jid]];
		[nodename setStringValue:[selection node]?[selection node]:@""];
	}
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item)
		return 1;
	return [[item items] count];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
    AMPurpleJabberNode *item = [[notification userInfo] objectForKey:@"NSObject"];
	if (![item items])
		[item fetchItems];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSDictionary *style = [NSDictionary dictionaryWithObject:[item identities]?[NSColor blackColor]:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
	
    NSString *identifier = [tableColumn identifier];
    
	if ([identifier isEqualToString:@"jid"])
		return [[[NSAttributedString alloc] initWithString:[item jid] attributes:style] autorelease];
	else if ([identifier isEqualToString:@"name"]) {
		if ([item node]) {
			if ([item name])
				return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)",[item name],[item node]] attributes:style] autorelease];
			return [[[NSAttributedString alloc] initWithString:[item node] attributes:style] autorelease];
		}
		if ([item node])
			return [[[NSAttributedString alloc] initWithString:[item name] attributes:style] autorelease];
		// try to guess a name when there's none supplied
		NSRange slashsign = [[item jid] rangeOfString:@"/"];
		if (slashsign.location != NSNotFound)
			return [[[NSAttributedString alloc] initWithString:[[item jid] substringFromIndex:slashsign.location+1] attributes:style] autorelease];
		NSRange atsign = [[item jid] rangeOfString:@"@"];
		if (atsign.location != NSNotFound)
			return [[[NSAttributedString alloc] initWithString:[[item jid] substringToIndex:atsign.location] attributes:style] autorelease];
		if ([[item identities] count] > 0) {
			NSDictionary *identity = [[item identities] objectAtIndex:0];
			id name = [identity objectForKey:@"name"];
			if (name != [NSNull null] && [name length] > 0)
				return [[[NSAttributedString alloc] initWithString:[identity objectForKey:@"name"] attributes:style] autorelease];
		}
		return [[[NSAttributedString alloc] initWithString:AILocalizedString(@"(unknown)",nil) attributes:style] autorelease];
	} else if ([identifier isEqualToString:@"category"]) {
		if (![item identities])
			[[[NSAttributedString alloc] initWithString:AILocalizedString(@"Fetching...",nil) attributes:style] autorelease];
		
		NSMutableArray *identities = [[NSMutableArray alloc] init];
		
		NSEnumerator *e = [[item identities] objectEnumerator];
		NSDictionary *identity;
		while ((identity = [e nextObject]))
			[identities addObject:[NSString stringWithFormat:@"%@ (%@)",[identity objectForKey:@"category"],[identity objectForKey:@"type"]]];
		
		NSString *result = [identities componentsJoinedByString:@", "];
		
		[identities release];
		return [[[NSAttributedString alloc] initWithString:result attributes:style] autorelease];
	} else
        return @"???";
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
	NSArray *identities = [item identities];
	if (!identities)
		return nil;
	NSMutableArray *result = [NSMutableArray array];
	NSDictionary *identity;
	
	for (identity in identities) {
		if ([[identity objectForKey:@"category"] isEqualToString:@"gateway"])
			[result addObject:[NSString stringWithFormat:AILocalizedString(@"%@; double-click to register.","XMPP service discovery browser gateway tooltip"),[identity objectForKey:@"name"]]];
		else if ([[identity objectForKey:@"category"] isEqualToString:@"conference"])
			[result addObject:AILocalizedString(@"Conference service; double-click to join",nil)];
		else if ([[identity objectForKey:@"category"] isEqualToString:@"directory"])
			[result addObject:AILocalizedString(@"Directory service; double-click to search",nil)];
		else if ([[identity objectForKey:@"category"] isEqualToString:@"automation"] &&
				 [[identity objectForKey:@"type"] isEqualToString:@"command-node"])
			[result addObject:AILocalizedString(@"Ad-Hoc command; double-click to execute",nil)];
	}
	if ([[item commands] count] > 0)
		[result addObject:AILocalizedString(@"This node provides ad-hoc commands. Open the context menu to access them.",nil)];
	if ([result count] == 0)
		[result addObject:AILocalizedString(@"This node does not provide any services accessible to this program.",nil)];
	return [result componentsJoinedByString:@"\n"];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	BOOL expanded = [outlineView isItemExpanded:item];
	if (expanded && [item items] == nil) {
		if (!downloadprogress)
			downloadprogress = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"downloadprogress" ofType:@"png"]];
		NSSize imgsize = [downloadprogress size];
		NSImage *img = [[NSImage alloc] initWithSize:imgsize];
		NSAffineTransform *transform = [NSAffineTransform transform];
		
		[transform translateXBy:imgsize.width/2.0f yBy:imgsize.height/2.0f];
		NSTimeInterval intv = [NSDate timeIntervalSinceReferenceDate];
		intv -= floor(intv); // only get the fractional part
		[transform rotateByRadians:(CGFloat)(2.0*M_PI * (1.0-intv))];
		[transform translateXBy:-imgsize.width/2.0f yBy:-imgsize.height/2.0f];
		
		[img lockFocus];
		[transform set];
		[downloadprogress drawInRect:NSMakeRect(0.0f,0.0f,imgsize.width,imgsize.height) fromRect:NSMakeRect(0.0f,0.0f,imgsize.width,imgsize.height)
						   operation:NSCompositeSourceOver fraction:1.0f];
		[[NSAffineTransform transform] set];
		[img unlockFocus];
		[cell setImage:img];
		[img release];
		NSInvocation *inv = [[NSInvocation invocationWithMethodSignature:[outlineView methodSignatureForSelector:@selector(setNeedsDisplayInRect:)]] retain];
		[inv setSelector:@selector(setNeedsDisplayInRect:)];
		NSRect rect = [outlineView rectOfRow:[outlineView rowForItem:item]];
		[inv setArgument:&rect atIndex:2];
		
		[inv performSelector:@selector(invokeWithTarget:) withObject:outlineView afterDelay:0.1];
	} else {
		if (expanded) {
			if (!det_triangle_opened) {
				det_triangle_opened = [[NSImage alloc] initWithSize:NSMakeSize(13.0f,13.0f)];
				NSButtonCell *triangleCell = [[NSButtonCell alloc] initImageCell:nil];
				[triangleCell setButtonType:NSOnOffButton];
				[triangleCell setBezelStyle:NSDisclosureBezelStyle];
				[triangleCell setState:NSOnState];
				
				[det_triangle_opened lockFocus];
				[triangleCell drawWithFrame:NSMakeRect(0.0f,0.0f,13.0f,13.0f) inView:outlineView];
				[det_triangle_opened unlockFocus];
				
				[triangleCell release];
			}

			[cell setImage:det_triangle_opened];
		} else {
			if (!det_triangle_closed) {
				det_triangle_closed = [[NSImage alloc] initWithSize:NSMakeSize(13.0f,13.0f)];
				NSButtonCell *triangleCell = [[NSButtonCell alloc] initImageCell:nil];
				[triangleCell setButtonType:NSOnOffButton];
				[triangleCell setBezelStyle:NSDisclosureBezelStyle];
				[triangleCell setIntegerValue:NSOffState];
				
				[det_triangle_closed lockFocus];
				[triangleCell drawWithFrame:NSMakeRect(0.0f,0.0f,13.0f,13.0f) inView:outlineView];
				[det_triangle_closed unlockFocus];
				
				[triangleCell release];
			}
			
			[cell setImage:det_triangle_closed];
		}
	}
}

@end
