//
//  AITextViewWithPlaceholder.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Dec 26 2003.
//

#import "AITextViewWithPlaceholder.h"

#define PLACEHOLDER_SPACING		2

@implementation AITextViewWithPlaceholder

//Current implementation suggested by Philippe Mougin on the cocoadev mailing list

- (void)setPlaceholderString:(NSString *)inPlaceholderString
{
  //  NSDictionary *attributes;
	
//	attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor], NSForegroundColorAttributeName, nil];
	[self setPlaceholder:[[[NSAttributedString alloc] initWithString:inPlaceholderString
														  attributes:nil] autorelease]];
}

- (void)setPlaceholder:(NSAttributedString *)inPlaceholder
{
	if (inPlaceholder != placeholder) {
		[placeholder release];
		
		NSMutableAttributedString	*tempPlaceholder = [inPlaceholder mutableCopy];
		[tempPlaceholder addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, [tempPlaceholder length])];

		placeholder = tempPlaceholder;
	
		[self setNeedsDisplay:YES];
	}
}

- (NSAttributedString *)placeholder
{
    return placeholder;
}

- (void)dealloc
{
	[placeholder release];
	
	[super dealloc];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	if (placeholder &&
		([[self string] isEqualToString:@""]) && 
		([[self window] firstResponder] != self)) {
		NSSize	size = [self frame].size;
		NSSize	textContainerInset = [self textContainerInset];
		textContainerInset.width += 4;
		textContainerInset.height += 2;

		[placeholder drawInRect:NSMakeRect(textContainerInset.width, 
										   textContainerInset.height, 
										   size.width - (textContainerInset.width * 2),
										   size.height - (textContainerInset.height * 2))];
	}
}

- (BOOL)becomeFirstResponder
{
	if (placeholder) [self setNeedsDisplay:YES];

	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	if (placeholder) [self setNeedsDisplay:YES];
	
	return [super resignFirstResponder];
}
@end
