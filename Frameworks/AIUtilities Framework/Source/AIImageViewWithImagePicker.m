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


#import "AIImageViewWithImagePicker.h"
#import <Quartz/Quartz.h>

#import "AIImageDrawingAdditions.h"
#import "AIImageAdditions.h"
#import "AIFileManagerAdditions.h"
#import "AIStringUtilities.h"

#import "IKRecentPicture.h" //10.5+, private

#define DRAGGING_THRESHOLD 16.0

@class IKPictureTakerRecentPicture;

@interface AIImageViewWithImagePicker ()

- (void)_initImageViewWithImagePicker;
- (void)showPictureTaker;
- (void)copy:(id)sender;
- (void)paste:(id)sender;
- (void)delete;

@end

@interface NSObject (IKPictureTaker_SecretsAdiumKnows)

- (void)setRecentPictureAsImageInput:(IKPictureTakerRecentPicture *)picture;

@end

/*
 * @class AIImageViewWithImagePicker
 *
 * @brief Image view which displays and uses the Image Picker used by Apple Address Book and iChat when activated and also allows other image-setting behaviors.
 *
 * The following is supported
 *		- Address book-style image picker on double-click or enter, with delegate notification
 *		- Or, alternately, an Open Panel on double-click or enter, with delegate notification
 *		- Copying and pasting, with delegate notification
 *		- Drag and drop into and out of the image well, with delegate notification, 
 *			with support for animated GIFs and transparency
 *		- Notifcation to the delegate of user's attempt to delete the image
 *		- Adding image to Recent Picture Repository, for dragged images only
 */
@implementation AIImageViewWithImagePicker


@synthesize delegate, activeRecentPicture, usePictureTaker, presentPictureTakerAsSheet, shouldUpdateRecentRepository, maxSize; 

#pragma mark Init

/*
 * @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
		[self _initImageViewWithImagePicker];
	}
    return self;
}

/*
 * @brief Initialize with frame
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self _initImageViewWithImagePicker];
	}
	return self;
}

/*
 * @brief Private initialization method
 */
- (void)_initImageViewWithImagePicker
{
	pictureTaker = nil;
	title = nil;
	delegate = nil;
	activeRecentPicture = nil;
	
	shouldUpdateRecentRepository = NO;
	
	lastResp = nil;
	shouldDrawFocusRing = NO;

	mouseDownPos = NSZeroPoint;
	maxSize = NSZeroSize;

	usePictureTaker = YES;
}

/*
 * @brief Deallocate
 */
- (void)dealloc
{
	if (pictureTaker) {
		[pictureTaker close];
		pictureTaker = nil;
	}
}

#pragma mark Getters and Setters

/*!
 * @brief Set the image
 *
 * We may get here progrmatically, from a user drag-and-drop or paste, etc.
 */
- (void)setImage:(NSImage *)inImage
{
	[super setImage:inImage];
	
	// Inform the picker controller of a changed selection if it is open, for live updating
	if (pictureTaker) {
		[pictureTaker setInputImage:inImage];
	}
	
	activeRecentPicture = nil;
}

/*!
 * @brief Set the title of the Image Picker
 *
 * Set the title of the Image Picker window which will be displayed if the user activates it (see class discussion).
 * @param inTitle An <tt>NSString</tt> of the title
 */ 
- (void)setTitle:(NSString *)inTitle
{
	if (title != inTitle) {
		title = inTitle;
		
		if (pictureTaker) {
			[pictureTaker setTitle:title];
		}
	}
}

/*
 * @brief The title of the image picker
 */
- (NSString *)title
{
	return (title ? title : AILocalizedStringFromTableInBundle(@"Image Picker", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil));
}

#pragma mark Monitoring user interaction

/*
 * @brief Mouse down
 *
 * Intercept mouse down events so we can begin a drag out of the image view if appropriate
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	if ([self isEnabled]) {
		NSEvent *nextEvent;
		
		//Wait for the next event
		nextEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask)
											   untilDate:[NSDate distantFuture]
												  inMode:NSEventTrackingRunLoopMode
												 dequeue:NO];
		
		mouseDownPos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		/* If the user starts dragging, don't call mouse down as we won't receive mouse dragged events, as it seems that
			* NSImageView does some sort of event loop modification in response to a click. We didn't dequeue the event, so
			* we don't have to handle it ourselves -- instead, the event loop will handle it after this invocation is complete. 
			*/
		if ([nextEvent type] != NSLeftMouseDragged) {
			[super mouseDown:theEvent];   
		}
		
		if ([theEvent clickCount] == 2) {
			[self showPictureTaker];
		}

	} else {
		[super mouseDown:theEvent];   
	}
}

/*
 * @brief Key down
 *
 * Intercept key down events to delete the image on delete/backspace or to show the image picker on enter/return
 */
- (void)keyDown:(NSEvent *)theEvent
{
	NSString *characters = [theEvent charactersIgnoringModifiers];
	unichar key = ([characters length] ? [characters characterAtIndex:0] : 0);
	
	if ((key == NSBackspaceCharacter) || (key == NSDeleteCharacter) || (key == NSDeleteFunctionKey) || (key == NSDeleteCharFunctionKey)) {
		[self delete];
	} else if (key == NSEnterCharacter || key == NSCarriageReturnCharacter) {
		[self showPictureTaker];
	} else {
		[super keyDown:theEvent];
	}
}

/*
 * @brief Mouse dragged
 *
 * Begin an image drag as appropriate
 */
- (void)mouseDragged:(NSEvent *)theEvent
{
	if (![self image]) return;

	// Work out if the mouse has been dragged far enough - it stops accidental drags
	NSPoint mousePos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	CGFloat dx = mousePos.x-mouseDownPos.x;
	CGFloat dy = mousePos.y-mouseDownPos.y;	
	
	if ((dx*dx) + (dy*dy) < DRAGGING_THRESHOLD) {
		return;
	}
	
	//Start the drag
	[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"png"]
						  fromRect:NSZeroRect
							source:self
						 slideBack:YES
							 event:theEvent];
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack
{
	[pboard addTypes:[NSArray arrayWithObjects:NSTIFFPboardType,NSPDFPboardType,nil] owner:self];
	
	NSImage *dragImage = [[NSImage alloc] initWithSize:[[self image] size]];
	
	//Draw our original image as 50% transparent
	[dragImage lockFocus];
	[[self image] drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0, 0, self.image.size.width, self.image.size.height) operation:NSCompositeCopy fraction:0.5f];
	[dragImage unlockFocus];
	
	//We want the image to resize
	[dragImage setScalesWhenResized:YES];
	//Change to the size we are displaying
	[dragImage setSize:[self bounds].size];
	
	[super dragImage:dragImage
				  at:imageLoc
			  offset:mouseOffset
			   event:theEvent
		  pasteboard:pboard
			  source:sourceObject
		   slideBack:slideBack];
}

/*
 * @brief Declare what operations we can participate in as a drag and drop source
 */
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	return NSDragOperationCopy;
}

/*
 * @brief Method called to support drag types we said we could offer
 */
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type
{
    //sender has accepted the drag and now we need to send the data for the type we promised
    if ([type isEqualToString:NSTIFFPboardType]) {
		//set data for TIFF type on the pasteboard as requested
		[sender setData:[[self image] TIFFRepresentation] 
				forType:NSTIFFPboardType];
		
    } else if ([type isEqualToString:NSPDFPboardType]) {
		[sender setData:[self dataWithPDFInsideRect:[self bounds]] 
				forType:NSPDFPboardType];
    }
}

/*
 * @brief Dragging entered
 */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ([sender draggingSource] == self) {
		return NSDragOperationNone;
	} else {
		return [super draggingEntered:sender];
	}
}

/*
 * @brief Dragging updated
 */
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	if ([sender draggingSource] == self) {
		return NSDragOperationNone;
	} else {
		return [super draggingUpdated:sender];
	}
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)inDropDestination
{
	NSString *name = nil;
	if ([[self delegate] respondsToSelector:@selector(fileNameForImageInImagePicker:)]) {
		name = [[self delegate] fileNameForImageInImagePicker:self];
		if (![name length]) name = nil;
	}
	
	if (!name)
		name = NSLocalizedString(@"Picture", nil);
	
	name = [name stringByAppendingPathExtension:@"png"];
	
	NSString *fullPath = [[inDropDestination path] stringByAppendingPathComponent:name];
	fullPath = [[NSFileManager defaultManager] uniquePathForPath:fullPath];
	
	[[[self image] bestRepresentationByType] writeToFile:fullPath
									   atomically:YES];
	
	return [NSArray arrayWithObject:[fullPath lastPathComponent]];
}

/*
 * @brief Conclude a drag operation
 *
 * A new image was dragged into our view.
 * We want to edit a dropped image if it doesn't correspond to our needs (too large or not of desired shape).
 * We then want to update our pictureTaker's selection if it is open.
 * Also we want the image to be added to the recent repository.
 */
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	NSImage *droppedImage = [[NSImage alloc] initWithPasteboard:[sender draggingPasteboard]];
    
    if (!droppedImage) {
        return;
    }
    
    NSSize droppedImageSize = [droppedImage size];
	NSSize mSize = [self maxSize];
	
	IKPictureTakerRecentPicture *recentPicture = [IKPictureTakerRecentPicture defaultRecentPictureWithOriginalImage:droppedImage cropSize:CGSizeZero];
	
    // We want to edit a dropped image if it is:
    // - larger then desired max size
    // - width/height proportions are ~20% off the squre shape
	if ((mSize.width > 0.0f && droppedImageSize.width > mSize.width) ||
		(mSize.height > 0.0f && droppedImageSize.height > mSize.height) ||
        (droppedImageSize.width / droppedImageSize.height > 1.2f ||
         droppedImageSize.width / droppedImageSize.height < 0.8f)) {

        // Set recent picture and open Image Picker
        [self setRecentPictureAsImageInput:recentPicture];
        [self showPictureTaker];
            
        return;
    } else if ([self pictureTaker]) {
        // Update an open Image Picker
        [self setRecentPictureAsImageInput:recentPicture];
    }
	
	// Inform the delegate
	if ([[self delegate] respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]) {
        [[self delegate] imageViewWithImagePicker:self didChangeToImageData:[droppedImage bestRepresentationByType]];
    } else if ([[self delegate] respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]) {
		[[self delegate] imageViewWithImagePicker:self didChangeToImage:droppedImage];
	}

	// Update Recent Pictures Repository
	if (shouldUpdateRecentRepository) {
		// Recent picture needs a small icon, of square shape
		// We need a valid maxSize, >= (32.0f, 32.0f)
		NSAssert(mSize.width >= 32.0f || mSize.height >= 32.0f, @"Valid maxSize required!");

		if ((mSize.width > 0.0f && droppedImageSize.width > mSize.width) ||
			(mSize.height > 0.0f && droppedImageSize.height > mSize.height)) {
			mSize = NSMakeSize(64.0f, 64.0f);
		} else {
			// We don't want to get weird results when the image is smaller
			CGFloat tmpSize = MAX(droppedImageSize.width, droppedImageSize.height);
			mSize = NSMakeSize(tmpSize, tmpSize);
		}
		
		// Update recent picture
		[recentPicture setCropInfo:nil smallIcon:[droppedImage imageByFittingInSize:mSize]];
		
		// Add to recent repository
		[[IKPictureTakerRecentPictureRepository recentRepository] addRecent:recentPicture];
	}
}

#pragma mark Copy / Paste

/*
 * @brief Copy
 */
- (void)copy:(id)sender
{
	NSImage *image = [self image];
	if (image) {
		[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSTIFFPboardType] owner:nil];
		[[NSPasteboard generalPasteboard] setData:[image TIFFRepresentation] forType:NSTIFFPboardType];
	}
}

/*
 * @brief Paste
 */
- (void)paste:(id)sender
{
	NSPasteboard	*pb = [NSPasteboard generalPasteboard];
	NSString		*type = [pb availableTypeFromArray:
		[NSArray arrayWithObjects:NSTIFFPboardType, NSPDFPboardType,nil]];
	BOOL			success = NO;

    NSData			*imageData = (type ? [pb dataForType:type] : nil);
	if (imageData) {
		NSImage *image = [[NSImage alloc] initWithData:imageData];
		if (image) {
			NSSize	imageSize = [image size];

			if ((maxSize.width > 0 && imageSize.width > maxSize.width) ||
				(maxSize.height > 0 && imageSize.height > maxSize.height)) {
				image = [image imageByScalingToSize:maxSize];
				imageData = [image bestRepresentationByType];
			}
			
			[self setImage:image];
							
			if (pictureTaker) {
				[pictureTaker setInputImage:image];
			}
			
			//Inform the delegate
			if (delegate) {
				if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]) {
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)
								   withObject:self
								   withObject:imageData];
				} else if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]) {
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
								   withObject:self
								   withObject:image];
				}
			}
			
			success = YES;
		}
	}
	
	if (!success) NSBeep();
}

/*
 * @brief Cut
 *
 * Cut = copy + delete
 */
- (void)cut:(id)sender
{
	[self copy:sender];
	[self delete];
}

/*
 * @brief Delete
 */
- (void)delete
{
	if (delegate && [delegate respondsToSelector:@selector(deleteInImageViewWithImagePicker:)]) {
		[delegate performSelector:@selector(deleteInImageViewWithImagePicker:)
					   withObject:self];
	}	
}

#pragma mark NSImagePicker Access and Delegate

/*!
 * @brief Action to call -[self showPictureTaker]
 */ 
- (IBAction)showImagePicker:(id)sender
{
	[self showPictureTaker];
}

- (void)pictureTakerDidEnd:(id)inPictureTaker returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{	
	if (returnCode == NSOKButton) {
		NSImage *image = [inPictureTaker outputImage];
		
		//Update the NSImageView
		NSSize imageSize = [image size];
		if ((maxSize.width > 0 && imageSize.width > maxSize.width) ||
			(maxSize.height > 0 && imageSize.height > maxSize.height)) {
			image = [image imageByScalingToSize:maxSize];
		}
		[self setImage:image];
		
		//Inform the delegate, but only if NOT using NSOpenPanel
		if (delegate && usePictureTaker) {
			if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]) {
				[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)
							   withObject:self
							   withObject:[image bestRepresentationByType]];
				
			} else if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]) {
				[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
							   withObject:self
							   withObject:image];
			}
		}
	}
}

/*
 * @brief Show the image picker controller
 */
- (void)showPictureTaker
{
	if (usePictureTaker) {
		if (!pictureTaker) {	
			pictureTaker = [IKPictureTaker pictureTaker];
			[pictureTaker setDelegate:self];
		}
		
		NSImage	*theImage = nil;
			 
		//Give the delegate an opportunity to supply an image which differs from the NSImageView's image
		if (delegate && [delegate respondsToSelector:@selector(imageForImageViewWithImagePicker:)]) {
			theImage = [delegate imageForImageViewWithImagePicker:self];
		}
		
		if (activeRecentPicture && [pictureTaker respondsToSelector:@selector(setRecentPictureAsImageInput:)])
			[pictureTaker setRecentPictureAsImageInput:activeRecentPicture];
		else
			[pictureTaker setInputImage:(theImage ? theImage : [self image])];

		[pictureTaker setTitle:([self title] ? [self title] : AILocalizedStringFromTableInBundle(@"Image Picker", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil))];
		[pictureTaker setValue:(([self maxSize].width != 0 && [self maxSize].height != 0) ?
								[NSValue valueWithSize:[self maxSize]] :
								nil)
						forKey:IKPictureTakerOutputImageMaxSizeKey];
		[pictureTaker setValue:[NSNumber numberWithBool:YES]
						forKey:IKPictureTakerShowEffectsKey];
		[pictureTaker setValue:[NSNumber numberWithBool:YES]
						forKey:IKPictureTakerShowAddressBookPictureKey];
		if (delegate && [delegate respondsToSelector:@selector(emptyPictureImageForImageViewWithImagePicker:)]) {
			[pictureTaker setValue:[delegate emptyPictureImageForImageViewWithImagePicker:self]
							forKey:IKPictureTakerShowEmptyPictureKey];
		}

		if ([self presentPictureTakerAsSheet]) {
			[pictureTaker beginPictureTakerSheetForWindow:[self window] 
											 withDelegate:self
										   didEndSelector:@selector(pictureTakerDidEnd:returnCode:contextInfo:)
											  contextInfo:nil];
		} else {
			[pictureTaker beginPictureTakerWithDelegate:self
										 didEndSelector:@selector(pictureTakerDidEnd:returnCode:contextInfo:)
											contextInfo:nil];
		}
			 
	} else {
		/* If we aren't using or can't use the image picker, use an open panel  */
		NSOpenPanel *openPanel;
		
		openPanel = [NSOpenPanel openPanel];
		[openPanel setTitle:AILocalizedStringFromTableInBundle(@"Select Image", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil)];
        [openPanel setAllowedFileTypes:[NSImage imageFileTypes]];
		
		if ([openPanel runModal] == NSOKButton) {
			NSData	*imageData;
			NSImage *image;
			NSSize	imageSize;

			imageData = [NSData dataWithContentsOfURL:[[openPanel URLs] objectAtIndex:0]];
			image = (imageData ? [[NSImage alloc] initWithData:imageData] : nil);
			imageSize = (image ? [image size] : NSZeroSize);

			if ((maxSize.width > 0 && imageSize.width > maxSize.width) ||
				(maxSize.height > 0 && imageSize.height > maxSize.height)) {
				image = [image imageByScalingToSize:maxSize];
				imageData = [image bestRepresentationByType];
			}
			
			//Update the image view
			[self setImage:image];
			
			//Inform the delegate
			if (delegate) {
				if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)]) {
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImageData:)
								   withObject:self
								   withObject:imageData];
					
				} else if ([delegate respondsToSelector:@selector(imageViewWithImagePicker:didChangeToImage:)]) {
					[delegate performSelector:@selector(imageViewWithImagePicker:didChangeToImage:)
								   withObject:self
								   withObject:image];
				}
			}
		}
	}
}

- (id)pictureTaker
{
	return pictureTaker;
}

- (void)setRecentPictureAsImageInput:(IKPictureTakerRecentPicture *)recentPicture
{
	if (activeRecentPicture != recentPicture) {
		activeRecentPicture = recentPicture;
	}
	
	//Update any open picture taker immediately.
	if (pictureTaker && activeRecentPicture && [pictureTaker respondsToSelector:@selector(setRecentPictureAsImageInput:)]) {
		[pictureTaker setRecentPictureAsImageInput:activeRecentPicture];
	}
}

#pragma mark Drawing

/*
 * @brief Note when the focus ring needs to be displayed
 *
 * Focus ring drawing code by Nicholas Riley, posted unlicensed as public domain on cocoadev and available at:
 * http://cocoa.mamasam.com/COCOADEV/2002/03/2/29535.php
 */
- (BOOL)needsDisplay
{
	NSResponder *resp = nil;
	NSWindow	*window = [self window];
	
	if ([window isKeyWindow]) {
		resp = [window firstResponder];
		
		if (resp == lastResp) {
			return [super needsDisplay];
		}
	} else if (lastResp == nil) {
		return [super needsDisplay];
	}
	
	shouldDrawFocusRing = ([self focusRingType] != NSFocusRingTypeNone &&
						   resp != nil &&
						   [resp isKindOfClass:[NSView class]] &&
						   [(NSView *)resp isDescendantOf:self]); // [sic]

	lastResp = resp;
	
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	return YES;
}

/*
 * @brief Draw the focus ring around our view if necessary
 */
- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	
	if (shouldDrawFocusRing) {
		NSSetFocusRingStyle(NSFocusRingOnly);
		NSRectFill(rect);
	}
} 

@end
