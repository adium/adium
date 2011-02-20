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

#import "AIImageUploaderPlugin.h"
#import "AIImageShackImageUploader.h"
#import "AIImgurImageUploader.h"
#import "AIImageUploaderWindowController.h"

#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIMenuControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIChat.h>

#import <AIUtilities/AIWindowAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIImageAdditions.h>

@interface AIImageUploaderPlugin()
- (NSImage *)currentImage;
- (void)uploadImage;

- (void)insertImageAddress:(NSString *)inAddress intoTextView:(NSTextView *)textView;
- (void)setImageUploader:(NSMenuItem *)menuItem;
@end

@implementation AIImageUploaderPlugin
- (void)installPlugin
{
	uploaders = [[NSMutableArray alloc] init];
	windowControllers = [[NSMutableDictionary alloc] init];
	uploadInstances = [[NSMutableDictionary alloc] init];
	
	[uploaders addObject:[AIImageShackImageUploader class]];
	[uploaders addObject:[AIImgurImageUploader class]];
	
	NSMenuItem *menuItem;
	
	NSMenu *subMenu = [[NSMenu alloc] init];
	[subMenu setDelegate:self];
	
	// Edit menu
	menuItem = [[[NSMenuItem alloc] initWithTitle:IMAGE_UPLOAD_MENU_TITLE
										   target:self
										   action:@selector(uploadImage)
									keyEquivalent:@"k"
										  keyMask:NSCommandKeyMask | NSAlternateKeyMask] autorelease];
	
	[menuItem setSubmenu:subMenu];
	
	[adium.menuController addMenuItem:menuItem toLocation:LOC_Edit_Links];

	// Context menu
	menuItem = [[[NSMenuItem alloc] initWithTitle:IMAGE_UPLOAD_MENU_TITLE
										   target:self
										   action:@selector(uploadImage)
									keyEquivalent:@""] autorelease];
	
	[menuItem setSubmenu:[[subMenu copy] autorelease]];
	
	[adium.menuController addContextualMenuItem:menuItem toLocation:Context_TextView_Edit];
	
	[adium.preferenceController registerPreferenceObserver:self forGroup:PREF_GROUP_FORMATTING];
}

- (void)uninstallPlugin
{
	[adium.preferenceController unregisterPreferenceObserver:self];
}

- (void)dealloc
{
	[defaultService release];
	[windowControllers release];
	[uploadInstances release];
	[uploaders release];
	
	[super dealloc];
}

#pragma mark Preferences
@synthesize defaultService;

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	if (object)
		return;
	
	if (!key || [key isEqualToString:PREF_KEY_DEFAULT_IMAGE_UPLOADER]) {
		self.defaultService = [prefDict objectForKey:PREF_KEY_DEFAULT_IMAGE_UPLOADER];
	}
}

#pragma mark Services
/*!
 * @brief Set the submenu as a menu of all possible services
 */
- (void)menuNeedsUpdate:(NSMenu *)menu
{
	[menu removeAllItems];

	for (Class service in uploaders) {
		NSMenuItem *newItem = [menu addItemWithTitle:[service serviceName]
											  target:self 
											  action:@selector(setImageUploader:)
									   keyEquivalent:@""];
		
		[newItem setRepresentedObject:[service serviceName]];
		
		[newItem setState:[[service serviceName] isEqualToString:defaultService]];
	}
}

/*!
 * @brief Set the default upload service, then upload.
 */
- (void)setImageUploader:(NSMenuItem *)menuItem
{
	NSString *serviceName = [menuItem representedObject];
	
	[adium.preferenceController setPreference:serviceName
									   forKey:PREF_KEY_DEFAULT_IMAGE_UPLOADER
										group:PREF_GROUP_FORMATTING];
	
	[self uploadImage];
}

/*!
 * @brief If we have a selected image, we can do something.
 */
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	return [self currentImage] != nil;
}

#pragma mark Image uploading
/*!
 * @brief The current selected image in the text view.
 *
 * @return the NSImage in the text view which is selected
 */
- (NSImage *)currentImage
{
	NSTextView	*textView = (NSTextView *)[[NSApp keyWindow] earliestResponderOfClass:[NSTextView class]];
	if (textView) {
		NSAttributedString *text = textView.textStorage;
		NSRange selectedRange = textView.selectedRange;
		
		//If we have some text and the start of the selection is not at the end of the string...
		if (text.length && selectedRange.length) {
			NSTextAttachment *attachment = [text attribute:NSAttachmentAttributeName atIndex:selectedRange.location effectiveRange:NULL];

			if (attachment) {
				NSImage *image = nil;
				
				if ([attachment respondsToSelector:@selector(image)])
					image = [attachment performSelector:@selector(image)];
				else if ([[attachment attachmentCell] respondsToSelector:@selector(image)])
					image = [[attachment attachmentCell] performSelector:@selector(image)];
				
				return image;
			}
		}
	}
	
	return nil;
}

/*!
 * @brief Upload the image.
 *
 * Tells the current default service to perform an upload, creates the progress window, and waits.
 */
- (void)uploadImage
{
	Class uploader = nil;
	
	for (Class service in uploaders) {
		uploader = service;
		
		if ([[service serviceName] isEqualToString:defaultService]) {
			break;
		}
	}
	
	AIChat *chat = adium.interfaceController.activeChat;
	NSImage *currentImage = [self currentImage];

	AILogWithSignature(@"Beginning upload for %@ to %@", currentImage, [uploader serviceName]);
	
	AIImageUploaderWindowController *controller = [AIImageUploaderWindowController displayProgressInWindow:[NSApp keyWindow]
																								  delegate:self
																									  chat:chat];
	
	controller.indeterminate = YES;

	id <AIImageUploader> uploadInstance = [uploader uploadImage:currentImage forUploader:self inChat:chat];
	
	[windowControllers setValue:controller forKey:chat.internalObjectID];
	[uploadInstances setValue:uploadInstance forKey:chat.internalObjectID];
}

/*!
 * @brief Request a URL, insert into text view
 *
 * @param inAddress The NSString to insert
 * @param textView the NSTextView to insert the address itno
 *
 * Replaces the selected image in textView with the given address.
 */
- (void)insertImageAddress:(NSString *)inAddress intoTextView:(NSTextView *)textView
{	
	NSParameterAssert(inAddress.length);
	
	NSRange selectedRange = textView.selectedRange;
	
	AILogWithSignature(@"Inserting %@ into text view", inAddress);
	
	// Replace the current selection with the new URL
	NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[textView.attributedString attributesAtIndex:selectedRange.location effectiveRange:nil]];
	[attrs setObject:inAddress forKey:NSLinkAttributeName];
	
	[textView.textStorage replaceCharactersInRange:selectedRange
							  withAttributedString:[[[NSAttributedString alloc] initWithString:inAddress attributes:attrs] autorelease]];
	
	// Select the inserted URL
	textView.selectedRange = NSMakeRange(selectedRange.location, inAddress.length);
	
	// Post a notification that we've changed the text
	[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification
														object:textView];
}

- (void)errorWithMessage:(NSString *)message forChat:(AIChat *)chat
{
	[adium.interfaceController handleErrorMessage:AILocalizedString(@"Error during image upload", nil)
								  withDescription:message];
	
	[self uploadedURL:nil forChat:chat];
}

/*!
 * @brief The upload has finished
 *
 * @param url The URL or nil if failed
 * @param chat The AIChat for this upload
*/
- (void)uploadedURL:(NSString *)url forChat:(AIChat *)chat
{
	AIImageUploaderWindowController *windowController = [windowControllers objectForKey:chat.internalObjectID];
	NSObject <AIImageUploader> *imageUploader = [uploadInstances objectForKey:chat.internalObjectID];
	
	[windowController closeWindow:nil];
	
	[[windowController retain] autorelease];
	[[imageUploader retain] autorelease];
	
	[windowControllers setValue:nil forKey:chat.internalObjectID];
	[uploadInstances setValue:nil forKey:chat.internalObjectID];
	
	AILogWithSignature(@"Received %@ for %@", url, chat);
	
	if (url) {
		NSWindow *window = ((AIWindowController *)chat.chatContainer.windowController).window;
		NSTextView *textView = (NSTextView *)[window earliestResponderOfClass:[NSTextView class]];
		
		[self insertImageAddress:url intoTextView:textView];
	}
}

/*!
 * @brief Update the progress's percent
 *
 * @param uploaded The uploaded amount in bytes
 * @param total The total amount in bytes
 * @param chat The AIChat for the upload
 */
- (void)updateProgress:(NSUInteger)uploaded total:(NSUInteger)total forChat:(AIChat *)chat;
{
	[[windowControllers objectForKey:chat.internalObjectID] setIndeterminate:NO];
	[[windowControllers objectForKey:chat.internalObjectID] updateProgress:uploaded total:total];
}

/*!
 * @brief Cancel an update
 *
 * @param chat The AIChat to cancel for
 */
- (void)cancelForChat:(AIChat *)chat
{
	AIImageUploaderWindowController *windowController = [windowControllers objectForKey:chat.internalObjectID];
	NSObject <AIImageUploader> *imageUploader = [uploadInstances objectForKey:chat.internalObjectID];
	
	[imageUploader cancel];

	[[windowController retain] autorelease];
	[[imageUploader retain] autorelease];
	
	[windowControllers setValue:nil forKey:chat.internalObjectID];
	[uploadInstances setValue:nil forKey:chat.internalObjectID];

	AILogWithSignature(@"Cancelled image upload for %@", chat);
}

@end
