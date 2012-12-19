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

#import "ESFileTransferProgressRow.h"
#import "ESFileTransferProgressView.h"
#import <AIUtilities/AIParagraphStyleAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#define	NORMAL_TEXT_COLOR		[NSColor controlTextColor]
#define	SELECTED_TEXT_COLOR		[NSColor whiteColor]
#define TRANSFER_STATUS_COLOR	[NSColor disabledControlTextColor]

@interface ESFileTransferProgressView ()
- (void)updateButtonReveal;
- (void)updateButtonStopResume;
@end

@implementation ESFileTransferProgressView

- (void)awakeFromNib
{
	if ([[self superclass] instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib];
    }

	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator setIndeterminate:YES];
	progressVisible = YES;
		
	showingDetails = NO;

	[button_stopResume setDelegate:self];
	[button_reveal setDelegate:self];

	buttonStopResumeIsHovered = NO;
    buttonStopResumeIsResend = NO;
	buttonRevealIsHovered = NO;
}

#pragma mark Source and destination
- (void)setSourceName:(NSString *)inSourceName
{
	[textField_source setStringValue:(inSourceName ? inSourceName : @"")];
}
- (void)setSourceIcon:(NSImage *)inSourceIcon
{
	[imageView_source setImage:inSourceIcon];
}
- (void)setDestinationName:(NSString *)inDestinationName
{
	[textField_destination setStringValue:(inDestinationName ? inDestinationName : @"")];
}
- (void)setDestinationIcon:(NSImage *)inDestinationIcon
{
	[imageView_destination setImage:inDestinationIcon];
}

#pragma mark File and its icon
- (void)setFileName:(NSString *)inFileName
{
	[textField_fileName setStringValue:(inFileName ? 
									   inFileName : 
									   [AILocalizedString(@"Initializing transfer",nil) stringByAppendingEllipsis])];
}
- (void)setIconImage:(NSImage *)inIconImage
{
	[button_icon setImage:inIconImage];
}

#pragma mark Progress
- (void)setProgressDoubleValue:(double)inPercent
{
	[progressIndicator setDoubleValue:inPercent];
}
- (void)setProgressIndeterminate:(BOOL)flag
{
	[progressIndicator setIndeterminate:flag];	
}
- (void)setProgressAnimation:(BOOL)flag
{
	if (flag) {
		[progressIndicator startAnimation:self];
	} else {
		[progressIndicator stopAnimation:self];	
	}
}
- (void)setProgressVisible:(BOOL)flag
{
	if (flag != progressVisible) {
		progressVisible = flag;
		if (progressVisible) {
			//Redisplay the progress bar.  We never do this at present, so unimplemented for now.
		} else {
			NSRect	progressRect = [progressIndicator frame];
			NSRect	frame;
			CGFloat	distanceToMove = progressRect.size.height / 2;
			
			[progressIndicator setDisplayedWhenStopped:NO];
			[progressIndicator setIndeterminate:YES];
			[progressIndicator stopAnimation:self];
			[progressIndicator setHidden:YES];
			
			//Top objects moving down
			{
				frame = [textField_fileName frame];
				frame.origin.y -= distanceToMove;
				//Don't let it be any further right than the progress bar used to be to avoid our buttons
				frame.size.width = (progressRect.origin.x + progressRect.size.width) - frame.origin.x;
				[textField_fileName setFrame:frame];
			}
			
			//Bottom objects moving up
			{
				frame = [twiddle_details frame];
				frame.origin.y += distanceToMove;
				[twiddle_details setFrame:frame];

				frame = [textField_detailsLabel frame];
				frame.origin.y += distanceToMove;
				[textField_detailsLabel setFrame:frame];
								
				frame = [box_transferStatusFrame frame];
				frame.origin.y += distanceToMove;
				//Don't let it be any further right than the progress bar used to be to avoid our buttons
				frame.size.width = (progressRect.origin.x + progressRect.size.width) - frame.origin.x;
				[box_transferStatusFrame setFrame:frame];
			}
		}
	}
}

- (void)setButtonStopResumeVisible:(BOOL)flag
{
    [button_stopResume setHidden:!flag];
}

- (void)setButtonStopResumeIsResend:(BOOL)flag
{
    buttonStopResumeIsResend = flag;
    [self updateButtonStopResume];
}

- (BOOL)buttonStopResumeIsResend
{
    return buttonStopResumeIsResend;
}

- (void)setTransferBytesStatus:(NSString *)inTransferBytesStatus
			   remainingStatus:(NSString *)inTransferRemainingStatus
				   speedStatus:(NSString *)inTransferSpeedStatus
{
	if (inTransferBytesStatus && inTransferRemainingStatus) {
		transferStatus = [NSString stringWithFormat:@"%@ - %@",
			inTransferBytesStatus,
			inTransferRemainingStatus];
	} else if (inTransferBytesStatus) {
		transferStatus = inTransferBytesStatus;
	} else if (inTransferRemainingStatus) {
		transferStatus = inTransferRemainingStatus;		
	} else {
		transferStatus = @"";
	}
	
//	[textField_transferStatus setStringValue:transferStatus];
	[self setNeedsDisplayInRect:[box_transferStatusFrame frame]];
	[textField_rate setStringValue:(inTransferSpeedStatus ? inTransferSpeedStatus : @"")];
}

#pragma mark Details
//Sent when the details twiddle is clicked
- (IBAction)toggleDetails:(id)sender
{
	NSRect	detailsFrame = [view_details frame];
	NSRect	primaryControlsFrame = [box_primaryControls frame];
	NSRect	oldFrame = [self frame];
	NSRect	newFrame = oldFrame;
	
	showingDetails = !showingDetails;

	if (showingDetails) {
		//Increase our height to make space
		newFrame.size.height += detailsFrame.size.height;
		newFrame.origin.y -= detailsFrame.size.height;
		[self setFrame:newFrame];
		
		//Move the box with our primary controls up
		primaryControlsFrame.origin.y += detailsFrame.size.height;
		[box_primaryControls setFrame:primaryControlsFrame];
			
		//Add the details subview
		[self addSubview:view_details];
		
		//Line up the details frame with the twiddle which revealed it
		detailsFrame.origin.x = [twiddle_details frame].origin.x;
		detailsFrame.origin.y = 0;

		[view_details setFrame:detailsFrame];
	
		//Update the twiddle
		[twiddle_details setState:NSOnState];
	} else {
		newFrame.size.height -= detailsFrame.size.height;
		newFrame.origin.y += detailsFrame.size.height;

		[self setFrame:newFrame];
		
		//Move the box with our primary controls back down
		primaryControlsFrame.origin.y -= detailsFrame.size.height;
		[box_primaryControls setFrame:primaryControlsFrame];
		
		[view_details removeFromSuperview];
		
		//Update the twiddle
		[twiddle_details setState:NSOffState];
	}
	
	//Let the owner know our height changed so other rows can be adjusted accordingly
	[owner fileTransferProgressView:self
				  heightChangedFrom:oldFrame.size.height
								 to:newFrame.size.height];
}

- (void)setShowsDetails:(BOOL)flag
{
	if (showingDetails != flag) {
		[self toggleDetails:nil];	
	}
}

- (void)setAllowsCancel:(BOOL)flag
{
	[button_stopResume setEnabled:flag];
}

- (void)updateColors
{
	NSColor	*newColor;
	
	if (isSelected && [[self window] isKeyWindow]) {
		newColor = SELECTED_TEXT_COLOR;
	} else {
		newColor = NORMAL_TEXT_COLOR;
	}

	[textField_rate setTextColor:newColor];
	[textField_source setTextColor:newColor];
	[textField_destination setTextColor:newColor];		
	[textField_fileName setTextColor:newColor];
	
	[textField_detailsLabel setTextColor:newColor];
	
	
	[self updateButtonStopResume];
	[self updateButtonReveal];
	[self setNeedsDisplay:YES];
}

- (void)windowDidChangeKey:(NSNotification *)notification
{
	[self updateColors];
}

- (void)viewDidMoveToWindow
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidBecomeKeyNotification
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidResignKeyNotification
												  object:nil];
	if ([self window]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidChangeKey:)
													 name:NSWindowDidBecomeKeyNotification
												   object:[self window]];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(windowDidChangeKey:)
													 name:NSWindowDidResignKeyNotification
												   object:[self window]];
	}
}

#pragma mark Selection
- (void)setIsHighlighted:(BOOL)flag
{
	if (isSelected != flag) {
		isSelected = flag;
		
		[self updateButtonStopResume];
		[self updateColors];
	}
}

- (void)updateButtonStopResume
{
	if (buttonStopResumeIsResend) {
	    [button_stopResume setKeyEquivalent:@""];
		
		if (isSelected) {
			[button_stopResume setImage:[NSImage imageNamed:(buttonStopResumeIsHovered ? @"FTProgressResendRollover_Selected" : @"FTProgressResend_Selected")
												   forClass:[self class]]];

			[button_stopResume setAlternateImage:[NSImage imageNamed:@"FTProgressResendPressed_Selected" forClass:[self class]]];
				
		} else {
			[button_stopResume setImage:[NSImage imageNamed:(buttonStopResumeIsHovered ? @"FTProgressResendRollover" : @"FTProgressResend")
												   forClass:[self class]]];

			[button_stopResume setAlternateImage:[NSImage imageNamed:@"FTProgressResendPressed" forClass:[self class]]];
		}
	} else {	
		if (isSelected) {
			[button_stopResume setKeyEquivalent:@"."];
			[button_stopResume setKeyEquivalentModifierMask:NSCommandKeyMask];
			
			[button_stopResume setImage:[NSImage imageNamed:(buttonStopResumeIsHovered ? @"FTProgressStopRollover_Selected" : @"FTProgressStop_Selected")
													forClass:[self class]]];

			[button_stopResume setAlternateImage:[NSImage imageNamed:@"FTProgressStopPressed_Selected" forClass:[self class]]];

		} else {
			[button_stopResume setKeyEquivalent:@""];
			
			[button_stopResume setImage:[NSImage imageNamed:(buttonStopResumeIsHovered ? @"FTProgressStopRollover" : @"FTProgressStop")
													forClass:[self class]]];

			[button_stopResume setAlternateImage:[NSImage imageNamed:@"FTProgressStopPressed" forClass:[self class]]];
		}
	}
}

- (void)updateButtonReveal
{
	if (isSelected) {
		[button_reveal setImage:[NSImage imageNamed:(buttonRevealIsHovered ? @"FTProgressRevealRollover_Selected" : @"FTProgressReveal_Selected")
										   forClass:[self class]]];
		
		[button_reveal setAlternateImage:[NSImage imageNamed:@"FTProgressRevealPressed_Selected" forClass:[self class]]];

	} else {
		[button_reveal setImage:[NSImage imageNamed:(buttonRevealIsHovered ? @"FTProgressRevealRollover" : @"FTProgressReveal")
										   forClass:[self class]]];

		[button_reveal setAlternateImage:[NSImage imageNamed:@"FTProgressRevealPressed" forClass:[self class]]];

	}
}
- (void)rolloverButton:(AIRolloverButton *)inButton mouseChangedToInsideButton:(BOOL)isInside
{
	if (inButton == button_stopResume) {
		buttonStopResumeIsHovered = isInside;
		[self updateButtonStopResume];
		
	} else if (inButton == button_reveal) {
		buttonRevealIsHovered = isInside;
		[self updateButtonReveal];

	}
}

static NSDictionary	*transferStatusAttributes = nil;
static NSDictionary	*transferStatusSelectedAttributes = nil;

//Draw the transfer status after other views draw.  This lets us use custom drawing behavior including the
//NSLineBreakByTruncatingTail paragraph style.  We draw into a frame reserved for us by box_transferStatusFrame;
//this lets us not worry about autosizing and positioning since the view takes care of that for us.
- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	NSDictionary	*attributes;
	NSRect			primaryControlsRect = [box_primaryControls frame];
	NSRect			targetRect = [box_transferStatusFrame frame];

	targetRect.origin.x += primaryControlsRect.origin.x;
	targetRect.origin.y += primaryControlsRect.origin.y;

	if (isSelected && [[self window] isKeyWindow]) {
		if (!transferStatusSelectedAttributes) {
			NSMutableParagraphStyle	*paragraphStyle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																					lineBreakMode:NSLineBreakByTruncatingTail];
			[paragraphStyle setMaximumLineHeight:[box_transferStatusFrame frame].size.height];
			
			transferStatusSelectedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:9], NSFontAttributeName, 
				SELECTED_TEXT_COLOR, NSForegroundColorAttributeName, nil];
		}
		
		attributes = transferStatusSelectedAttributes;
	} else {
		if (!transferStatusAttributes) {
			NSMutableParagraphStyle	*paragraphStyle = [NSMutableParagraphStyle styleWithAlignment:NSLeftTextAlignment
																					lineBreakMode:NSLineBreakByTruncatingTail];
			[paragraphStyle setMaximumLineHeight:[box_transferStatusFrame frame].size.height];
			
			transferStatusAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				paragraphStyle, NSParagraphStyleAttributeName,
				[NSFont systemFontOfSize:9], NSFontAttributeName, 
				TRANSFER_STATUS_COLOR, NSForegroundColorAttributeName, nil];
		}
		
		attributes = transferStatusAttributes;
	}
	
	[transferStatus drawInRect:targetRect
				withAttributes:attributes];
}

#pragma mark Menu
- (NSMenu *)menuForEvent:(NSEvent *)inEvent
{
	return [owner menuForEvent:inEvent];
}

#pragma mark Accessibility

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	id value;
	
	if ([attribute isEqualToString:NSAccessibilityRoleAttribute]) {
		value = NSAccessibilityRowRole;

	} else if ([attribute isEqualToString:NSAccessibilityRoleDescriptionAttribute]) {
		if (![progressIndicator isIndeterminate]) {
			//We are in the concrete phase of an active transfer
			value = [NSString stringWithFormat:
					 AILocalizedString(@"Transferring %@ from %@ to %@ at %@ : %@", "e.g: Transferring file.zip from Evan to Joel at 45 kb/sec : 5 minutes remaining. Keep the spaces around the colon."),
					 [textField_fileName stringValue],
					 [textField_source stringValue],
					 [textField_destination stringValue], 
					 [textField_rate stringValue],
					 (transferStatus ? transferStatus : @"")];
			
		} else {
			value = [NSString stringWithFormat:
					 AILocalizedString(@"Transfer of %@ from %@ to %@ : %@", "e.g: Transfer of file.zip from Evan to Joel : Upload complete. Keep the spaces around the colon"),
					 [textField_fileName stringValue],
					 [textField_source stringValue],
					 [textField_destination stringValue], 
					 (transferStatus ? transferStatus : @"")];
		}

	} else if ([attribute isEqualToString:NSAccessibilityTitleAttribute]) {
		value = AILocalizedString(@"File transfer", nil);
		
	} else if ([attribute isEqualToString:NSAccessibilityEnabledAttribute]) {
		//Never report as disabled, so we don't say 'dimmed' all the time
		value = [NSNumber numberWithBool:YES];

	} else {
		value = [super accessibilityAttributeValue:attribute];
	}
	
	return value;
}

@end
