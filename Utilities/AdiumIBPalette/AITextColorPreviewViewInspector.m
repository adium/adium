//
//  AITextColorPreviewViewInspector.m
//  AdiumIBPalette
//
//  Created by Peter Hosey on 2006-05-11.
//  Copyright 2006 The Adium Project. All rights reserved.
//

#import "AITextColorPreviewViewInspector.h"

@implementation AITextColorPreviewViewInspector

- (id) init
{
	if((self = [super init])) {
		[NSBundle loadNibNamed:@"AITextColorPreviewViewInspector" owner:self];
	}
	return self;
}

/* We're supposed to override this, but with Bindings, we don't need to.
   Bindings in IB inspectors are kind of flaky, though, so I'm leaving this here for now, in case we need to use it.
   -- boredzo

- (void)ok:(id)sender
{
	[super ok:sender];
}
*/

- (void)revert:(id)sender
{
	[self willChangeValueForKey:@"previewText"];
	[self  didChangeValueForKey:@"previewText"];
	[self willChangeValueForKey:@"textColor"];
	[self  didChangeValueForKey:@"textColor"];
	[self willChangeValueForKey:@"textShadowColor"];
	[self  didChangeValueForKey:@"textShadowColor"];
	[self willChangeValueForKey:@"backgroundColor"];
	[self  didChangeValueForKey:@"backgroundColor"];
	[self willChangeValueForKey:@"backgroundGradientColor"];
	[self  didChangeValueForKey:@"backgroundGradientColor"];
	[self willChangeValueForKey:@"textShadowEnabled"];
	[self  didChangeValueForKey:@"textShadowEnabled"];
	[self willChangeValueForKey:@"backgroundEnabled"];
	[self  didChangeValueForKey:@"backgroundEnabled"];

	[super revert:sender];
}

#pragma Bindings accessors

//All of these forward data to/from the preview view.

- (NSString *) previewText {
	return [[self object] previewText];
}
- (void) setPreviewText:(NSString *)newPreviewText {
	[[self object] setPreviewText:newPreviewText];

	//Bug in IB's Bindings support (if it has any): We can't call -ok: from here because this is a text field.
	//Instead, we call it after a delay.
//	[super ok:nil];
	[self performSelector:@selector(ok:)
			   withObject:nil
			   afterDelay:0.1];
}

- (NSColor *) textColor {
	return [[self object] textColor];
}
- (void) setTextColor:(NSColor *)newTextColor {
	[[self object] setTextColor:newTextColor];
	[super ok:nil];
}

- (NSColor *) textShadowColor {
	return [[self object] textShadowColor];
}
- (void) setTextShadowColor:(NSColor *)newTextShadowColor {
	[[self object] setTextShadowColor:newTextShadowColor];
	[super ok:nil];
}

- (NSColor *) backgroundColor {
	return [[self object] backgroundColor];
}
- (void) setBackgroundColor:(NSColor *)newBackgroundColor {
	[[self object] setBackgroundColor:newBackgroundColor];
	[super ok:nil];
}

- (NSColor *) backgroundGradientColor {
	return [[self object] backgroundGradientColor];
}
- (void) setBackgroundGradientColor:(NSColor *)newBackgroundGradientColor {
	[[self object] setBackgroundGradientColor:newBackgroundGradientColor];
	[super ok:nil];
}

- (BOOL) textShadowEnabled {
	return [[self object] textShadowEnabled];
}
- (void) setTextShadowEnabled:(BOOL)flag {
	[[self object] setTextShadowEnabled:flag];
	[super ok:nil];
}

- (BOOL) backgroundEnabled {
	return [[self object] backgroundEnabled];
}
- (void) setBackgroundEnabled:(BOOL)flag {
	[[self object] setBackgroundEnabled:flag];
	[super ok:nil];
}

@end

@implementation AITextColorPreviewView (AdiumIBPaletteInspector)

- (NSString *)inspectorClassName {
	return @"AITextColorPreviewViewInspector";
}

@end
