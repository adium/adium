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

#import "ESWebView.h"
#import <Adium/AILoginControllerProtocol.h>

@interface WebView ()
- (void)setDrawsBackground:(BOOL)flag;
- (void)setBackgroundColor:(NSColor *)color;
@end

@interface WebPreferences (WebPreferencesPrivate)
- (void)_setLocalStorageDatabasePath:(NSString *)path;
@end

@interface NSWindow ()
- (void) _setContentHasShadow:(BOOL) shadow; 
@end

@interface ESWebView ()
- (void)forwardSelector:(SEL)selector withObject:(id)object;
@end

@implementation ESWebView

- (id)initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName
{
	if ((self = [super initWithFrame:frameRect frameName:frameName groupName:groupName])) {
		draggingDelegate = nil;
		allowsDragAndDrop = YES;
		shouldForwardEvents = YES;
		transparentBackground = NO;
		
		if ([[self preferences] respondsToSelector:@selector(_setLocalStorageDatabasePath:)]) {
			[[self preferences] _setLocalStorageDatabasePath:[[adium.loginController userDirectory] stringByAppendingPathComponent:@"LocalStorage"]];
		}
	}
	
	return self;
}

#pragma mark Transparency
- (void)setTransparent:(BOOL)flag
{
	//Private method: this is new in Tiger
	if( [[self window] respondsToSelector:@selector( _setContentHasShadow: )] )
		[[self window] _setContentHasShadow:NO];
	
	//As of Safari 3.0, we must call setBackgroundColor: to make the webview transparent
	[self setBackgroundColor:(flag ? [NSColor clearColor] : [NSColor whiteColor])];
	
	transparentBackground = flag;
}

- (void)viewDidMoveToWindow
{
	NSWindow *win = [self window];
	if(win) {
		[win setOpaque:!transparentBackground];
		[win _setContentHasShadow:NO];
	}
	[super viewDidMoveToWindow];
}

//Font Family ----------------------------------------------------------------------------------------------------------
#pragma mark Font Family
- (void)setFontFamily:(NSString *)familyName
{
	[[self preferences] setStandardFontFamily:familyName];
	[[self preferences] setFixedFontFamily:familyName];
	[[self preferences] setSerifFontFamily:familyName];
	[[self preferences] setSansSerifFontFamily:familyName];
}

- (NSString *)fontFamily
{
	return [[self preferences] standardFontFamily];
}


#pragma mark Key/Paste Forwarding
- (void)setShouldForwardEvents:(BOOL)flag
{
	shouldForwardEvents = flag;
}

//When the user attempts to type into the table view, we push the keystroke to the next responder,
//and make it key.  This isn't required, but convienent behavior since one will never want to type
//into this view.
- (void)keyDown:(NSEvent *)theEvent
{
	BOOL forwarded = YES;
	
	if (shouldForwardEvents) {
		unichar		 inChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
		
		// Don't forward navigation key events. If we're receiving them, it's because
		// the frame itself didn't support them.
		if (inChar != NSUpArrowFunctionKey && inChar != NSDownArrowFunctionKey &&
			inChar != NSPageUpFunctionKey && inChar != NSPageDownFunctionKey)
		{
			[self forwardSelector:@selector(keyDown:) withObject:theEvent];
			forwarded = YES;
		}
	}
	
	if (!forwarded) {
		[super keyDown:theEvent];
	}
}

- (void)paste:(id)sender
{
	[self forwardSelector:@selector(paste:) withObject:sender];
}
- (void)pasteAsPlainText:(id)sender
{
	[self forwardSelector:@selector(pasteAsPlainText:) withObject:sender];
}
- (void)pasteAsRichText:(id)sender
{
	[self forwardSelector:@selector(pasteAsRichText:) withObject:sender];
}

- (void)forwardSelector:(SEL)selector withObject:(id)object
{
	id	responder = [self nextResponder];
	
	//When walking the responder chain, we want to skip ScrollViews and ClipViews.
	while (responder && ([responder isKindOfClass:[NSClipView class]] || [responder isKindOfClass:[NSScrollView class]])) {
		responder = [responder nextResponder];
	}
	
	if (responder) {
		[[self window] makeFirstResponder:responder]; //Make it first responder
		[responder tryToPerform:selector with:object]; //Pass it this key event
	}
}


//Accepting Drags ------------------------------------------------------------------------------------------------------
#pragma mark Accepting Drags
- (void)setAllowsDragAndDrop:(BOOL)flag
{
	allowsDragAndDrop = flag;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation dragOperation;
	
	if (allowsDragAndDrop) {
		if (draggingDelegate && [draggingDelegate respondsToSelector:@selector(webView:draggingEntered:)]) {
			dragOperation = [draggingDelegate webView:self draggingEntered:sender];
		} else {
			dragOperation = [super draggingEntered:sender];
		}
	} else {
		dragOperation = NSDragOperationNone;
	}
	
	return dragOperation;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSDragOperation dragOperation;
	
	if (allowsDragAndDrop) {
		if (draggingDelegate && [draggingDelegate respondsToSelector:@selector(webView:draggingUpdated:)]) {
			dragOperation = [draggingDelegate webView:self draggingUpdated:sender];
		} else {
			dragOperation = [super draggingUpdated:sender];
		}
	} else {
		dragOperation = NSDragOperationNone;
	}
	
	return dragOperation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	if (draggingDelegate) {
		if ([draggingDelegate respondsToSelector:@selector(webView:draggingExited:)]) {
			[draggingDelegate webView:self draggingExited:sender];
		}
	} else {
		[super draggingExited:sender];
	}
}

//Dragging
- (void)setDraggingDelegate:(id)inDelegate
{
	draggingDelegate = inDelegate;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	if (draggingDelegate && [draggingDelegate respondsToSelector:@selector(webView:prepareForDragOperation:)]) {
		return [draggingDelegate webView:self prepareForDragOperation:sender];
	} else {
		return [super prepareForDragOperation:sender];
	}
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	if (draggingDelegate && [draggingDelegate respondsToSelector:@selector(webView:performDragOperation:)]) {
		return [draggingDelegate webView:self performDragOperation:sender];
	} else {
		return [super performDragOperation:sender];
	}
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	if (draggingDelegate && [draggingDelegate respondsToSelector:@selector(webView:concludeDragOperation:)]) {
		[draggingDelegate webView:self concludeDragOperation:sender];
	} else {
		[super concludeDragOperation:sender];
	}
}

/*
- (id)accessibilityAttributeValue:(NSString *)attribute
{
	NSLog(@"%@: Returning %@ for %@", self, [super accessibilityAttributeValue:attribute], attribute);

	return [super accessibilityAttributeValue:attribute];
}
*/

@end
