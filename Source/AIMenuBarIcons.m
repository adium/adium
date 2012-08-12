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
 
#import "AIMenuBarIcons.h"
#import <AIUtilities/AIBundleAdditions.h>
#import <Adium/AIXtraInfo.h>
#import <AIUtilities/AIImageAdditions.h>
#import <QuartzCore/CoreImage.h>

#define KEY_ICONS_DICT	@"Icons"

@interface AIMenuBarIcons ()
- (NSImage *)imageForKey:(NSString *)keyName;
- (BOOL)keyOfTypeExists:(NSString *)keyName;
@end

@implementation AIMenuBarIcons

- (id)initWithURL:(NSURL *)url
{
	if ((self = [super initWithURL:url])) {
		imageStates = [[NSMutableDictionary alloc] init];
		alternateImageStates = [[NSMutableDictionary alloc] init];
		iconInfo = [xtraBundle objectForInfoDictionaryKey:KEY_ICONS_DICT];
	}
	return self;
}

- (NSImage *)imageOfType:(NSString *)imageType alternate:(BOOL)alternate
{
	NSImage *image;

	// Default to Online if key not found.
	if (![self keyOfTypeExists:imageType]) {
		imageType = @"Online";
	}

	image = [(alternate ? alternateImageStates : imageStates) objectForKey:imageType];
	if (!image) { // Image not already stored.
		if (alternate) {
			NSImage *normalImage = [self imageOfType:imageType alternate:NO];
			image = [self alternateImageForImage:normalImage];
			[alternateImageStates setObject:image forKey:imageType];
		} else {
			image = [self imageForKey:imageType];
			if (image) { // Make sure the image exists.
				[imageStates setObject:image forKey:imageType];
			}
		}
	}
	
	[image setFlipped:YES];
	
	return image;
}

- (NSImage *)imageForKey:(NSString *)keyName
{
	// This set doesn't contain an Icons dictionary entry. It's invalid.
	if (!iconInfo) {
		return nil;
	}
	
	return [xtraBundle imageForResource:[iconInfo objectForKey:keyName]];
}

- (BOOL)keyOfTypeExists:(NSString *)keyName
{
	if (!iconInfo || ![iconInfo objectForKey:keyName]) {
		return NO;
	}
	return YES;
}

- (void)dealloc
{
	[imageStates release];
	[alternateImageStates release];
	[super dealloc];
}

#define	PREVIEW_MENU_IMAGE_SIZE		18
#define	PREVIEW_MENU_IMAGE_MARGIN	2

+ (NSImage *)previewMenuImageForIconPackAtPath:(NSString *)inPath
{
	NSImage			*image;
	NSBundle		*menuIconsBundle = [[[NSBundle alloc] initWithPath:inPath] autorelease];
	NSDictionary	*imageInfo;
	
	if (!menuIconsBundle) {
		return nil;
	}
	
	imageInfo = [menuIconsBundle objectForInfoDictionaryKey:KEY_ICONS_DICT];
	
	if (!imageInfo) {
		return nil;
	}

	image = [[[NSImage alloc] initWithSize:NSMakeSize((PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN) * 2,
													  PREVIEW_MENU_IMAGE_SIZE)] autorelease];
													 

	if ([[menuIconsBundle objectForInfoDictionaryKey:@"XtraBundleVersion"] integerValue] == 1) {
		NSInteger				xOrigin = 0;

		[image lockFocus];
		for (NSString *iconID in [NSArray arrayWithObjects:@"Online",@"Offline",nil]) {
			NSImage		*anIcon;

			if ((anIcon = [menuIconsBundle imageForResource:[imageInfo objectForKey:iconID]])) {
				NSSize	anIconSize = [anIcon size];
				NSRect	targetRect = NSMakeRect(xOrigin, 0, PREVIEW_MENU_IMAGE_SIZE, PREVIEW_MENU_IMAGE_SIZE);

				if (anIconSize.width < targetRect.size.width) {
					CGFloat difference = (targetRect.size.width - anIconSize.width)/2;

					targetRect.size.width -= difference;
					targetRect.origin.x += difference;
				}

				if (anIconSize.height < targetRect.size.height) {
					CGFloat difference = (targetRect.size.height - anIconSize.height)/2;

					targetRect.size.height -= difference;
					targetRect.origin.y += difference;
				}

				[anIcon drawInRect:targetRect
							fromRect:NSMakeRect(0,0,anIconSize.width,anIconSize.height)
						   operation:NSCompositeCopy
							fraction:1.0f];

				//Shift right in preparation for next image
				xOrigin += PREVIEW_MENU_IMAGE_SIZE + PREVIEW_MENU_IMAGE_MARGIN;
			}
		}
		[image unlockFocus];
	}

	return image;
}

// Returns an inverted image.
- (NSImage *)alternateImageForImage:(NSImage *)inImage
{
	NSImage				*altImage = [[NSImage alloc] initWithSize:[inImage size]];
	NSBitmapImageRep	*srcImageRep = [inImage largestBitmapImageRep];
	
	[altImage setFlipped:[inImage isFlipped]];

	id monochromeFilter, invertFilter, alphaFilter;
	
	monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
	[monochromeFilter setValue:[[[CIImage alloc] initWithBitmapImageRep:srcImageRep] autorelease]
						forKey:@"inputImage"]; 
	[monochromeFilter setValue:[NSNumber numberWithDouble:1.0]
						forKey:@"inputIntensity"];
	[monochromeFilter setValue:[[[CIColor alloc] initWithColor:[NSColor whiteColor]] autorelease]
						forKey:@"inputColor"];
	
	//Now invert our greyscale image
	invertFilter = [CIFilter filterWithName:@"CIColorInvert"];
	[invertFilter setValue:[monochromeFilter valueForKey:@"outputImage"]
					forKey:@"inputImage"]; 
	
	//And turn the parts that were previously white (are now black) into transparent
	alphaFilter = [CIFilter filterWithName:@"CIMaskToAlpha"];
	[alphaFilter setValue:[invertFilter valueForKey:@"outputImage"]
				   forKey:@"inputImage"]; 

	[altImage addRepresentation:[NSCIImageRep imageRepWithCIImage:[alphaFilter valueForKey:@"outputImage"]]];

	return [altImage autorelease];
}

@end
