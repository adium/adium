//
//  IKPictureTakerForTiger.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/28/07.
//

#import "IKPictureTakerForTiger.h"
#import "AIImageDrawingAdditions.h"
#import "NSImagePicker.h"
#import "AIStringUtilities.h"

@implementation IKPictureTakerForTiger

+ (IKPictureTakerForTiger *)pictureTaker
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	[inputImage release];
	[outputImage release];
	
	[super dealloc];
}

- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate;
}

- (id)delegate
{
	return delegate;
}

- (NSImage *)inputImage
{
	return inputImage;
}

- (void)setInputImage:(NSImage *)inImage
{
	if (inputImage != inImage) {
		[inputImage release];
		inputImage = [inImage retain];

		[pickerController selectionChanged];
	}
}

- (NSImage *)outputImage
{
	return outputImage;
}

/*
 * @brief This gets called when the user selects OK on a new image
 *
 * @param sender The Image Picker
 * @param image The image which was selected
 */
- (void)imagePicker:(id)sender selectedImage:(NSImage *)image
{
	NSSize imageSize = [image size];
	NSSize maxSize = [[self delegate] maxSize];

	if ((maxSize.width > 0 && imageSize.width > maxSize.width) ||
		(maxSize.height > 0 && imageSize.height > maxSize.height)) {
		image = [image imageByScalingToSize:maxSize];
	}
	
	if (image != outputImage) {
		[outputImage release];
		outputImage = [image retain];
	}

	[[self delegate] pictureTakerDidEnd:self returnCode:NSOKButton contextInfo:NULL];
	
	//Add the image to the list of recent images
	//10.2 and 10.5 don't have NSIPRecentPicture, so find the class dynamically to avoid link errors if we want 10.2/10.5 compatibility
	Class ipRecentPictureClass = NSClassFromString(@"NSIPRecentPicture");
	id recentPicture = [[[ipRecentPictureClass alloc] initWithOriginalImage:image] autorelease];
	[recentPicture setCurrent];
	[ipRecentPictureClass _saveChanges]; //Saves to ~/Library/Images/iChat Recent Pictures
	
	//Picker controller is closing
	[pickerController release]; pickerController = nil;
}

- (void)close
{
	[[pickerController window] close];
	[pickerController release]; pickerController = nil;
}

- (void)setTitle:(NSString *)title
{
	[[pickerController window] setTitle:title];
}

/*
 * @brief This is called if the user cancels an image selection
 */
- (void)imagePickerCanceled: (id) sender
{
	[[pickerController window] close];
	
	//Picker controller is closing
	[pickerController release]; pickerController = nil;
}

/*
 * @brief Provide the image to be shown in the image picker
 *
 * This is called to provide an image when the delegate is first set and following selectionChanged messages to the controller.
 * The junk on the end seems to be the selector name for the method itself.
 */
- (NSImage *)displayImageInPicker: junk
{
	return [self inputImage];
}

/*
 * @brief Provide the title for the picker
 *
 * Note that you must not return nil or the window gets upset
 */
- (NSString *)displayTitleInPicker: junk
{
	return ([[self delegate] title] ? [[self delegate] title] : AILocalizedStringFromTableInBundle(@"Image Picker", nil, [NSBundle bundleWithIdentifier:AIUTILITIES_BUNDLE_ID], nil));
}


- (void)openImagePicker
{
	Class	imagePickerClass = NSClassFromString(@"NSImagePickerController");
	NSPoint pickerPoint;

	pickerController = [[imagePickerClass sharedImagePickerControllerCreate:YES] retain];
	[pickerController setDelegate:self];
	
	pickerPoint = [NSEvent mouseLocation];
	//Determine the screen of this mouse location
	NSScreen		*currentScreen;
	NSEnumerator	*enumerator = [[NSScreen screens] objectEnumerator];
	while ((currentScreen = [enumerator nextObject])) {
		if (NSPointInRect(pickerPoint, [currentScreen frame])) {
			break;
		}
	}
	NSRect pickerControllerFrame = [[pickerController window] frame];
	pickerPoint.y -= NSHeight(pickerControllerFrame);
	
	//Constrain the picker to the screen if possible
	if (currentScreen) {
		NSRect targetRect = [currentScreen visibleFrame];
		if (pickerPoint.y < NSMinY(targetRect)) pickerPoint.y = NSMinY(targetRect);
		if ((pickerPoint.y + NSHeight(pickerControllerFrame)) > NSMaxY(targetRect))
			pickerPoint.y = NSMaxY(targetRect) - NSHeight(pickerControllerFrame);
		
		if (pickerPoint.x < NSMinX(targetRect)) pickerPoint.x = NSMinX(targetRect);
		if (pickerPoint.x + NSWidth(pickerControllerFrame) > NSMaxX(targetRect))
			pickerPoint.x = NSMaxX(targetRect) - NSWidth(pickerControllerFrame);
	}
	
	[pickerController initAtPoint:pickerPoint inWindow:nil];
	[pickerController setHasChanged:NO];
	
	[pickerController selectionChanged];
	[[pickerController window] makeKeyAndOrderFront: nil];
}

- (void) beginPictureTakerSheetForWindow:(NSWindow *)aWindow withDelegate:(id)inDelegate didEndSelector:(SEL)inDidEndSelector contextInfo:(void *) contextInfo
{
	[self setDelegate:inDelegate];
	didEndSelector = inDidEndSelector;
	
	[self openImagePicker];
}

- (void) beginPictureTakerWithDelegate:(id)inDelegate didEndSelector:(SEL)inDidEndSelector contextInfo:(void *)contextInfo
{
	[self beginPictureTakerSheetForWindow:nil withDelegate:inDelegate didEndSelector:didEndSelector contextInfo:contextInfo];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	if ([key isEqualToString:IKPictureTakerAllowsVideoCaptureKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerAllowsFileChoosingKey]) {
		//No-op
	} else if ([key isEqualToString:IKPictureTakerShowRecentPictureKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerUpdateRecentPictureKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerAllowsEditingKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerShowEffectsKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerInformationalTextKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerImageTransformsKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerOutputImageMaxSizeKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerCropAreaSizeKey]) {
		//No-op						
	} else if ([key isEqualToString:IKPictureTakerShowAddressBookPictureKey]) { 
		//No-op
	} else if ([key isEqualToString:IKPictureTakerShowEmptyPictureKey]) { 
		//No-op
	} else
		[super setValue:value forKey:key];
}

@end
