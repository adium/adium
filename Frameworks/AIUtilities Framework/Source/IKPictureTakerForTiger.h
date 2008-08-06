//
//  IKPictureTakerForTiger.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 10/28/07.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <AIUtilities/AITigerCompatibility.h>

/* Define constants if building without them available */
#ifndef IKPictureTakerAllowsVideoCaptureKey
#define IKPictureTakerAllowsVideoCaptureKey @"IKPictureTakerAllowsVideoCaptureKey"
#define IKPictureTakerAllowsFileChoosingKey @"IKPictureTakerAllowsFileChoosingKey"
#define IKPictureTakerShowRecentPictureKey @"IKPictureTakerShowRecentPictureKey"
#define IKPictureTakerUpdateRecentPictureKey @"IKPictureTakerUpdateRecentPictureKey"
#define IKPictureTakerAllowsEditingKey @"IKPictureTakerAllowsEditingKey"
#define IKPictureTakerShowEffectsKey @"IKPictureTakerShowEffectsKey"
#define IKPictureTakerInformationalTextKey @"IKPictureTakerInformationalTextKey"
#define IKPictureTakerImageTransformsKey @"IKPictureTakerImageTransformsKey"
#define IKPictureTakerOutputImageMaxSizeKey @"IKPictureTakerOutputImageMaxSizeKey"
#define IKPictureTakerCropAreaSizeKey @"IKPictureTakerCropAreaSizeKey"
#define IKPictureTakerShowAddressBookPictureKey @"IKPictureTakerShowAddressBookPictureKey"
#define IKPictureTakerShowEmptyPictureKey @"IKPictureTakerShowEmptyPictureKey"
#endif

@interface IKPictureTakerForTiger : NSObject {
	id		pickerController;
	id		delegate;
	SEL		didEndSelector;
	NSImage	*inputImage;
	NSImage *outputImage;
}

+ (IKPictureTakerForTiger *) pictureTaker;
- (void) setInputImage:(NSImage *) image;
- (NSImage *)inputImage;
- (NSImage*) outputImage;
- (void)close;
- (void)setTitle:(NSString *)title;

/*
 * didEndSelector - (void)pictureTakerDidEnd:(IKPictureTakerForTiger *)pictureTaker returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
 */
- (void) beginPictureTakerSheetForWindow:(NSWindow *)aWindow withDelegate:(id) delegate didEndSelector:(SEL) didEndSelector contextInfo:(void *) contextInfo;

- (void) beginPictureTakerWithDelegate:(id) delegate didEndSelector:(SEL) didEndSelector contextInfo:(void *) contextInfo;

/*
 IKPictureTakerAllowsVideoCaptureKey
 A key for allowing video capture. The associated value is an NSNumber value (BOOL) whose default value is YES.
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerAllowsFileChoosingKey
 A key for allowing the user to choose a file. The associated value is an NSNumber object that contains a BOOL value whose default value is YES.
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerUpdateRecentPictureKey
 A key for allowing a recent picture to be updated. The associated value is an NSNumber object that contains a BOOL value whose default value is YES.
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerAllowsEditingKey
 A key for allowing image editing. The associated value is an NSNumber object that contains a BOOL value whose default value is YES.
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerShowEffectsKey
 A key for showing effects. The associated value is an NSNumber object that contains a BOOL value whose default value is NO.
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerInformationalTextKey
 A key for informational text. The associated value is an NSString or NSAttributedString object whose default value is "Drag Image Here".
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerImageTransformsKey
 A n image transformation key. The associated value is an NSDictionary object that can be serialized.
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerOutputImageMaxSizeKey
 A key for the maximum size of the output image. The associated value is an NSValue object (NSSize).
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerCropAreaSizeKey
 A key for the cropping area size. The associated value is an NSValue object (NSSize).
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerShowAddressBookPictureKey
 A key for showing the address book picture. The associated value is a Boolean value packages as an NSNumber object. The default value is NO. If set to YES, the picture taker automatically adds the address book image for the Me user at the end of the Recent Pictures pop-up menu.
 
 Available in Mac OS X v10.5 and later.
 
 IKPictureTakerShowEmptyPictureKey
 A key for showing an empty picture. The associated value is an NSImage object. The default value is nil. If set to an image, the picture taker automatically shows an image at the end of the Recent Pictures pop-up menu. that means "no picture."
 
 Available in Mac OS X v10.5 and later.
 */
@end

@interface NSObject (IKPictureTakerForTigerDelegate)
- (void)pictureTakerDidEnd:(id)inPictureTaker returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end
