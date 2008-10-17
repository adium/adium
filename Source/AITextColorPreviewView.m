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

#import "AITextColorPreviewView.h"
#import <AIUtilities/AIStringUtilities.h>
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>

@interface AITextColorPreviewView ()
- (void)_initTextColorPreviewView;
@end

@implementation AITextColorPreviewView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [super initWithCoder:aDecoder];
    [self _initTextColorPreviewView];
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    [self _initTextColorPreviewView];
    return self;
}

- (void)_initTextColorPreviewView
{
	backColorOverride = nil;
}

- (void)drawRect:(NSRect)rect
{
	NSMutableDictionary	*attributes;
	NSAttributedString	*sample;
	NSShadow			*shadow = nil;
	NSSize				sampleSize;
	
	//Background
	if (([backgroundEnabled state] != NSOffState) && backgroundGradientColor) {
		[[[[NSGradient alloc] initWithStartingColor:[backgroundGradientColor color] endingColor:[backgroundColor color]] autorelease] drawInRect:rect angle:90.0];
	} else {
		NSColor *backColor = (backColorOverride ? backColorOverride : [backgroundColor color]);
		if (backColor) {
			[backColor set];
			[NSBezierPath fillRect:rect];
		}
	}

	//Shadow
	if (([textShadowColorEnabled state] != NSOffState) && [textShadowColor color]) {
		shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:[textShadowColor color]];
	}

	//Text
	NSColor *colorForText = [textColor color];
	if (colorForText) {
		//If we have a checkbox and it's unchecked, change to black.
		if (textColorEnabled && ([textColorEnabled state] == NSOffState)) {
			colorForText = [NSColor blackColor];
		}
	}
	attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:12], NSFontAttributeName,
		[NSParagraphStyle styleWithAlignment:NSCenterTextAlignment], NSParagraphStyleAttributeName,
		colorForText, NSForegroundColorAttributeName,
		shadow, NSShadowAttributeName,
		nil];
	
	sample = [[[NSAttributedString alloc] initWithString:AILocalizedString(@"Sample",nil)
											  attributes:attributes] autorelease];
	sampleSize = [sample size];

	[sample drawInRect:NSIntegralRect(NSMakeRect(rect.origin.x + ((rect.size.width - sampleSize.width) / 2.0),
												 rect.origin.y + ((rect.size.height - sampleSize.height) / 2.0),
												 sampleSize.width,
												 sampleSize.height))];
}

- (void)dealloc
{
	[backColorOverride release];
	[super dealloc];
}

//Overrides.  pass nil to disable
- (void)setBackColorOverride:(NSColor *)inColor
{
	if (backColorOverride != inColor) {
		[backColorOverride release];
		backColorOverride = [inColor retain];
	}
}

@end
