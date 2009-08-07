//
//  AITextAttachmentAdditions.m
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 12/27/05.
//

#import "AITextAttachmentAdditions.h"

@implementation NSTextAttachment (AITextAttachmentAdditions)

- (BOOL)wrapsImage
{
	NSFileWrapper	*fileWrapper = [self fileWrapper];
	NSArray			*imageFileTypes = [NSImage imageFileTypes];
	OSType			HFSTypeCode = [[fileWrapper fileAttributes] fileHFSTypeCode];
	NSString		*pathExtension;
	
	return ([imageFileTypes containsObject:NSFileTypeForHFSTypeCode(HFSTypeCode)] ||
			((pathExtension = [[fileWrapper filename] pathExtension]) && [imageFileTypes containsObject:pathExtension]));	
}

@end
