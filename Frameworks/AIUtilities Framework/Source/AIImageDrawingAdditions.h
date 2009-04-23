//
//  AIImageDrawingAdditions.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 2/11/08.
//

typedef enum {
	IMAGE_POSITION_LEFT = 0,
	IMAGE_POSITION_RIGHT,
	IMAGE_POSITION_LOWER_LEFT,
	IMAGE_POSITION_LOWER_RIGHT
} IMAGE_POSITION;


@interface NSImage (AIImageDrawingAdditions)

- (void)tileInRect:(NSRect)rect;
- (NSImage *)imageByScalingToSize:(NSSize)size;
- (NSImage *)imageByFadingToFraction:(float)delta;
- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta;
- (NSImage *)imageByScalingForMenuItem;
- (NSImage *)imageByScalingToSize:(NSSize)size fraction:(float)delta flipImage:(BOOL)flipImage proportionally:(BOOL)proportionally allowAnimation:(BOOL)allowAnimation;
//+ (NSImage *)imageFromGWorld:(GWorldPtr)gWorldPtr;
- (NSRect)drawRoundedInRect:(NSRect)rect radius:(float)radius;
- (NSRect)drawRoundedInRect:(NSRect)rect fraction:(float)fraction radius:(float)radius;
- (NSRect)drawRoundedInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction radius:(float)radius;
- (NSRect)drawInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position fraction:(float)fraction;
- (NSRect)rectForDrawingInRect:(NSRect)rect atSize:(NSSize)size position:(IMAGE_POSITION)position;

@end
