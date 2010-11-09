//
//  AIImageUploaderPlugin.h
//  Adium
//
//  Created by Zachary West on 2009-05-26.
//  Copyright 2009 Adium. All rights reserved.
//

#define PREF_KEY_DEFAULT_IMAGE_UPLOADER	@"Default Image Uploader"

#define IMAGE_UPLOAD_MENU_TITLE		AILocalizedString(@"Replace with Uploaded Image", nil)

typedef enum {
	AISuccessfulUpload = 1,
	AIErrorUpload
} AIImageUploaderCode;

@class AIImageUploaderWindowController, AIChat;

@interface AIImageUploaderPlugin : AIPlugin <NSMenuDelegate> {
	NSMutableArray		*uploaders;
	NSString			*defaultService;
	
	NSDictionary		*windowControllers;
	NSDictionary		*uploadInstances;
}

@property (copy, nonatomic) NSString *defaultService;

- (void)errorWithMessage:(NSString *)message forChat:(AIChat *)chat;
- (void)uploadedURL:(NSString *)url forChat:(AIChat *)chat;
- (void)updateProgress:(NSUInteger)uploaded total:(NSUInteger)total forChat:(AIChat *)chat;
- (void)cancelForChat:(AIChat *)chat;

@end

@protocol AIImageUploader
// Service name should be unique across all image uploaders.
+ (NSString *)serviceName;
+ (id)uploadImage:(NSImage *)image forUploader:(AIImageUploaderPlugin *)uploader inChat:(AIChat *)chat;
- (void)cancel;
@end
