//
//  AIImageAdditions.h
//  Adium
//
//  Created by Evan Schoenberg on Tue Dec 02 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

typedef enum {
    AIButtonActive = 0,
    AIButtonPressed,
    AIButtonUnknown,
    AIButtonDisabled,
    AIButtonHovered
} AICloseButtonState;

typedef enum {
	AIUnknownFileType = -9999,
	AITIFFFileType = NSTIFFFileType,
    AIBMPFileType = NSBMPFileType,
    AIGIFFileType = NSGIFFileType,
    AIJPEGFileType = NSJPEGFileType,
    AIPNGFileType = NSPNGFileType,
    AIJPEG2000FileType = NSJPEG2000FileType
} AIBitmapImageFileType;

@interface NSImage (AIImageAdditions)

+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass;
+ (NSImage *)imageNamed:(NSString *)name forClass:(Class)inClass loadLazily:(BOOL)flag;

+ (NSImage *)imageForSSL;

+ (AIBitmapImageFileType)fileTypeOfData:(NSData *)inData;
+ (NSString *)extensionForBitmapImageFileType:(AIBitmapImageFileType)inFileType;

- (NSData *)JPEGRepresentation;
- (NSData *)JPEGRepresentationWithCompressionFactor:(float)compressionFactor;
- (NSData *)PNGRepresentation;
- (NSData *)GIFRepresentation;
- (NSData *)BMPRepresentation;
- (NSBitmapImageRep *)largestBitmapImageRep;

@end

//Defined in AppKit.framework
@interface NSImageCell(NSPrivateAnimationSupport)
- (BOOL)_animates;
- (void)_setAnimates:(BOOL)fp8;
- (void)_startAnimation;
- (void)_stopAnimation;
- (void)_animationTimerCallback:fp8;
@end
