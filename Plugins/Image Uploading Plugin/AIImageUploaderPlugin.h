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

#define PREF_KEY_DEFAULT_IMAGE_UPLOADER	@"Default Image Uploader"

#define IMAGE_UPLOAD_MENU_TITLE		AILocalizedString(@"Replace with Uploaded Image", nil)

@class AIImageUploaderWindowController, AIChat;

@interface AIImageUploaderPlugin : AIPlugin <NSMenuDelegate> {
	NSMutableArray		*uploaders;
	NSString			*defaultService;
	
	NSDictionary		*windowControllers;
	NSDictionary		*uploadInstances;
	
	NSMenuItem* contextMenuItem;
	NSMenuItem* editMenuItem;
}

@property (copy, nonatomic) NSString *defaultService;

- (void)addUploader:(Class)uploader;
- (void)removeUploader:(Class)uploader;
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
