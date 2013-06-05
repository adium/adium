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

#import <AIUtilities/AIRolloverButton.h>

@class ESFileTransferProgressRow, ESFileTransfer, AIRolloverButton;

@interface ESFileTransferProgressView : NSView <AIRolloverButtonDelegate> {
	IBOutlet ESFileTransferProgressRow	*owner;
	
	IBOutlet NSBox					*box_primaryControls;
	IBOutlet NSTextField			*textField_fileName;
	
	IBOutlet NSButton				*button_icon;
	IBOutlet NSProgressIndicator	*progressIndicator;
	
	IBOutlet AIRolloverButton		*button_stopResume;
	BOOL							buttonStopResumeIsHovered;
    BOOL                            buttonStopResumeIsResend;

	IBOutlet AIRolloverButton		*button_reveal;
	BOOL							buttonRevealIsHovered;

	//Details in primary view
	BOOL							showingDetails;
	IBOutlet NSButton				*twiddle_details;
	IBOutlet NSTextField			*textField_detailsLabel;
	IBOutlet NSBox					*box_transferStatusFrame; //Placeholder for drawing the transfer status
	NSString						*transferStatus;
	
	//Details view (revealed by twiddle_details)
	IBOutlet NSView					*view_details;
	IBOutlet NSTextField			*textField_rate;
	IBOutlet NSTextField			*textField_source;
	IBOutlet NSButton				*imageView_source;
	IBOutlet NSTextField			*textField_destination;
	IBOutlet NSButton				*imageView_destination;
	
	BOOL							isSelected;
	BOOL							progressVisible;
}

- (void)setSourceName:(NSString *)inSourceName;
- (void)setSourceIcon:(NSImage *)inSourceIcon;

- (void)setDestinationName:(NSString *)inDestinationName;
- (void)setDestinationIcon:(NSImage *)inDestinationIcon;

- (void)setFileName:(NSString *)inFileName;
- (void)setIconImage:(NSImage *)inIconImage;

- (void)setProgressDoubleValue:(double)inPercent;
- (void)setProgressIndeterminate:(BOOL)flag;
- (void)setProgressAnimation:(BOOL)flag;
- (void)setProgressVisible:(BOOL)flag;

- (void)setButtonStopResumeVisible:(BOOL)flag;
- (void)setButtonStopResumeIsResend:(BOOL)flag;
- (BOOL)buttonStopResumeIsResend;

- (void)setTransferBytesStatus:(NSString *)inTransferBytesStatus
			   remainingStatus:(NSString *)inTransferRemainingStatus
				   speedStatus:(NSString *)inTransferSpeedStatus;

- (IBAction)toggleDetails:(id)sender;
- (void)setShowsDetails:(BOOL)flag;

- (void)setAllowsCancel:(BOOL)flag;

@end
