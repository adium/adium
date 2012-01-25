//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"

//#define SRCommon_PotentiallyUsefulDebugInfo

#ifdef	SRCommon_PotentiallyUsefulDebugInfo
#define PUDNSLog(X,...)	NSLog(X,##__VA_ARGS__)
#else
#define PUDNSLog(X,...)	{ ; }
#endif

#pragma mark -
#pragma mark dummy class 

@implementation SRDummyClass @end

#pragma mark -

//---------------------------------------------------------- 
// SRStringForKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForKeyCode( signed short keyCode )
{
    static SRKeyCodeTransformer *keyCodeTransformer = nil;
    if ( !keyCodeTransformer )
        keyCodeTransformer = [[SRKeyCodeTransformer alloc] init];
    return [keyCodeTransformer transformedValue:[NSNumber numberWithShort:keyCode]];
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlags( NSUInteger flags )
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		( flags & controlKey ? [NSString stringWithFormat:@"%C", KeyboardControlGlyph] : @"" ),
		( flags & optionKey ? [NSString stringWithFormat:@"%C", KeyboardOptionGlyph] : @"" ),
		( flags & shiftKey ? [NSString stringWithFormat:@"%C", KeyboardShiftGlyph] : @"" ),
		( flags & cmdKey ? [NSString stringWithFormat:@"%C", KeyboardCommandGlyph] : @"" )];
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlagsAndKeyCode( NSUInteger flags, signed short keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCarbonModifierFlags( flags ), 
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlags( NSUInteger flags )
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		( flags & NSControlKeyMask ? [NSString stringWithFormat:@"%C", KeyboardControlGlyph] : @"" ),
		( flags & NSAlternateKeyMask ? [NSString stringWithFormat:@"%C", KeyboardOptionGlyph] : @"" ),
		( flags & NSShiftKeyMask ? [NSString stringWithFormat:@"%C", KeyboardShiftGlyph] : @"" ),
		( flags & NSCommandKeyMask ? [NSString stringWithFormat:@"%C", KeyboardCommandGlyph] : @"" )];
	
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlagsAndKeyCode( NSUInteger flags, signed short keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCocoaModifierFlags( flags ),
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRReadableStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCarbonModifierFlagsAndKeyCode( NSUInteger flags, signed short keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		( flags & cmdKey ? SRLoc(@"Command + ") : @""),
		( flags & optionKey ? SRLoc(@"Option + ") : @""),
		( flags & controlKey ? SRLoc(@"Control + ") : @""),
		( flags & shiftKey ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;    
}

//---------------------------------------------------------- 
// SRReadableStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCocoaModifierFlagsAndKeyCode( NSUInteger flags, signed short keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		(flags & NSCommandKeyMask ? SRLoc(@"Command + ") : @""),
		(flags & NSAlternateKeyMask ? SRLoc(@"Option + ") : @""),
		(flags & NSControlKeyMask ? SRLoc(@"Control + ") : @""),
		(flags & NSShiftKeyMask ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;
}

//---------------------------------------------------------- 
// SRCarbonToCocoaFlags()
//---------------------------------------------------------- 
NSUInteger SRCarbonToCocoaFlags( NSUInteger carbonFlags )
{
	NSUInteger cocoaFlags = ShortcutRecorderEmptyFlags;
	
	if (carbonFlags & cmdKey) cocoaFlags |= NSCommandKeyMask;
	if (carbonFlags & optionKey) cocoaFlags |= NSAlternateKeyMask;
	if (carbonFlags & controlKey) cocoaFlags |= NSControlKeyMask;
	if (carbonFlags & shiftKey) cocoaFlags |= NSShiftKeyMask;
	if (carbonFlags & NSFunctionKeyMask) cocoaFlags += NSFunctionKeyMask;
	if (carbonFlags & NSDeviceIndependentModifierFlagsMask) cocoaFlags |= NSDeviceIndependentModifierFlagsMask;
	
	return cocoaFlags;
}

//---------------------------------------------------------- 
// SRCocoaToCarbonFlags()
//---------------------------------------------------------- 
NSUInteger SRCocoaToCarbonFlags( NSUInteger cocoaFlags )
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	
	if (cocoaFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
	if (cocoaFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
	if (cocoaFlags & NSControlKeyMask) carbonFlags |= controlKey;
	if (cocoaFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
	if (cocoaFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}

//---------------------------------------------------------- 
// SRCharacterForKeyCodeAndCarbonFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCarbonFlags(signed short keyCode, NSUInteger carbonFlags) {
	return SRCharacterForKeyCodeAndCocoaFlags(keyCode, SRCarbonToCocoaFlags(carbonFlags));
}

//---------------------------------------------------------- 
// SRCharacterForKeyCodeAndCocoaFlags()
//----------------------------------------------------------
NSString *SRCharacterForKeyCodeAndCocoaFlags(signed short keyCode, NSUInteger cocoaFlags) {
	return SRStringForKeyCode(keyCode);
}

#pragma mark Animation Easing

// From: http://developer.apple.com/samplecode/AnimatedSlider/ as "easeFunction"
CGFloat SRAnimationEaseInOut(CGFloat t) {
	// This function implements a sinusoidal ease-in/ease-out for t = 0 to 1.0.  T is scaled to represent the interval of one full period of the sine function, and transposed to lie above the X axis.
	CGFloat x = ((AIsin((t * (CGFloat)M_PI) - (CGFloat)M_PI_2) + 1.0f ) / 2.0f);
//	NSLog(@"SRAnimationEaseInOut: %f. a: %f, b: %f, c: %f, d: %f, e: %f", t, (t * M_PI), ((t * M_PI) - M_PI_2), sin((t * M_PI) - M_PI_2), (sin((t * M_PI) - M_PI_2) + 1.0), x);
	return x;
} 


#pragma mark -
#pragma mark additions

@implementation NSBezierPath( SRAdditions )

//---------------------------------------------------------- 
// + bezierPathWithSRCRoundRectInRect:radius:
//---------------------------------------------------------- 
+ (NSBezierPath*)bezierPathWithSRCRoundRectInRect:(NSRect)aRect radius:(CGFloat)radius
{
	NSBezierPath* path = [self bezierPath];
	CGFloat widthOrHeight = MIN(NSWidth(aRect), NSHeight(aRect));
	radius = MIN(radius, 0.5f * widthOrHeight);
	NSRect rect = NSInsetRect(aRect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0f endAngle:270.0f];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0f endAngle:360.0f];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0f endAngle: 90.0f];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0f endAngle:180.0f];
	[path closePath];
	return path;
}

@end

@implementation NSError( SRAdditions )

- (NSString *)localizedDescription
{
	return [[self userInfo] objectForKey:@"NSLocalizedDescription"];
}

- (NSString *)localizedFailureReason
{
	return [[self userInfo] objectForKey:@"NSLocalizedFailureReasonErrorKey"];
}

- (NSString *)localizedRecoverySuggestion
{
	return [[self userInfo] objectForKey:@"NSLocalizedRecoverySuggestionErrorKey"];	
}

- (NSArray *)localizedRecoveryOptions
{
	return [[self userInfo] objectForKey:@"NSLocalizedRecoveryOptionsKey"];
}

@end

@implementation NSAlert( SRAdditions )

//---------------------------------------------------------- 
// + alertWithNonRecoverableError:
//---------------------------------------------------------- 
+ (NSAlert *) alertWithNonRecoverableError:(NSError *)error;
{
	NSString *reason = [error localizedRecoverySuggestion];
	return [self alertWithMessageText:[error localizedDescription]
						defaultButton:[[error localizedRecoveryOptions] objectAtIndex:0U]
					  alternateButton:nil
						  otherButton:nil
			informativeTextWithFormat:(reason ? reason : @"")];
}

@end

static NSMutableDictionary *SRSharedImageCache = nil;

@interface SRSharedImageProvider ()
+ (void)_drawSRSnapback:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRSnapback;
+ (void)_drawSRRemoveShortcut:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcut;
+ (void)_drawSRRemoveShortcutRollover:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcutRollover;
+ (void)_drawSRRemoveShortcutPressed:(id)anNSCustomImageRep;
+ (NSValue *)_sizeSRRemoveShortcutPressed;

+ (void)_drawARemoveShortcutBoxUsingRep:(id)anNSCustomImageRep opacity:(CGFloat)opacity;
@end

@implementation SRSharedImageProvider
+ (NSImage *)supportingImageWithName:(NSString *)name {
//	NSLog(@"supportingImageWithName: %@", name);
	if (nil == SRSharedImageCache) {
		SRSharedImageCache = [NSMutableDictionary dictionary];
//		NSLog(@"inited cache");
	}
	NSImage *cachedImage = nil;
	if (nil != (cachedImage = [SRSharedImageCache objectForKey:name])) {
//		NSLog(@"returned cached image: %@", cachedImage);
		return cachedImage;
	}
	
//	NSLog(@"constructing image");
	NSSize size;
	NSValue *sizeValue = [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"_size%@", name])];
	size = [sizeValue sizeValue];
//	NSLog(@"size: %@", NSStringFromSize(size));
	
	NSCustomImageRep *customImageRep = [[NSCustomImageRep alloc] initWithDrawSelector:NSSelectorFromString([NSString stringWithFormat:@"_draw%@:", name]) delegate:self];
	[customImageRep setSize:size];
//	NSLog(@"created customImageRep: %@", customImageRep);
	NSImage *returnImage = [[NSImage alloc] initWithSize:size];
	[returnImage addRepresentation:customImageRep];
	[returnImage setScalesWhenResized:YES];
	[SRSharedImageCache setObject:returnImage forKey:name];
	
#ifdef SRCommonWriteDebugImagery
	
	NSData *tiff = [returnImage TIFFRepresentation];
	[tiff writeToURL:[NSURL fileURLWithPath:[[NSString stringWithFormat:@"~/Desktop/m_%@.tiff", name] stringByExpandingTildeInPath]] atomically:YES];

	NSSize sizeQDRPL = NSMakeSize(size.width*4.0,size.height*4.0);
	
//	sizeQDRPL = NSMakeSize(70.0,70.0);
	NSCustomImageRep *customImageRepQDRPL = [[NSCustomImageRep alloc] initWithDrawSelector:NSSelectorFromString([NSString stringWithFormat:@"_draw%@:", name]) delegate:self];
	[customImageRepQDRPL setSize:sizeQDRPL];
//	NSLog(@"created customImageRepQDRPL: %@", customImageRepQDRPL);
	NSImage *returnImageQDRPL = [[NSImage alloc] initWithSize:sizeQDRPL];
	[returnImageQDRPL addRepresentation:customImageRepQDRPL];
	[customImageRepQDRPL release];
	[returnImageQDRPL setScalesWhenResized:YES];
	[returnImageQDRPL setFlipped:YES];
	NSData *tiffQDRPL = [returnImageQDRPL TIFFRepresentation];
	[tiffQDRPL writeToURL:[NSURL fileURLWithPath:[[NSString stringWithFormat:@"~/Desktop/m_QDRPL_%@.tiff", name] stringByExpandingTildeInPath]] atomically:YES];
	
#endif
	
//	NSLog(@"returned image: %@", returnImage);
	return returnImage;
}

#define MakeRelativePoint(x,y)	NSMakePoint(x*hScale, y*vScale)

+ (NSValue *)_sizeSRSnapback {
	return [NSValue valueWithSize:NSMakeSize(14.0f,14.0f)];
}
+ (void)_drawSRSnapback:(id)anNSCustomImageRep {
	
//	NSLog(@"drawSRSnapback using: %@", anNSCustomImageRep);
	
	NSCustomImageRep *rep = anNSCustomImageRep;
	NSSize size = [rep size];
	[[NSColor whiteColor] setFill];
	CGFloat hScale = (size.width/1.0f);
	CGFloat vScale = (size.height/1.0f);
	
	NSBezierPath *bp = [[NSBezierPath alloc] init];
	[bp setLineWidth:hScale];
	
	[bp moveToPoint:MakeRelativePoint(0.0489685f, 0.6181513f)];
	[bp lineToPoint:MakeRelativePoint(0.4085750f, 0.9469318f)];
	[bp lineToPoint:MakeRelativePoint(0.4085750f, 0.7226146f)];
	[bp curveToPoint:MakeRelativePoint(0.8508247f, 0.4836237f) controlPoint1:MakeRelativePoint(0.4085750f, 0.7226146f) controlPoint2:MakeRelativePoint(0.8371143f, 0.7491841f)];
	[bp curveToPoint:MakeRelativePoint(0.5507195f, 0.0530682f) controlPoint1:MakeRelativePoint(0.8677834f, 0.1545071f) controlPoint2:MakeRelativePoint(0.5507195f, 0.0530682f)];
	[bp curveToPoint:MakeRelativePoint(0.7421721f, 0.3391942f) controlPoint1:MakeRelativePoint(0.5507195f, 0.0530682f) controlPoint2:MakeRelativePoint(0.7458685f, 0.1913146f)];
	[bp curveToPoint:MakeRelativePoint(0.4085750f, 0.5154130f) controlPoint1:MakeRelativePoint(0.7383412f, 0.4930328f) controlPoint2:MakeRelativePoint(0.4085750f, 0.5154130f)];
	[bp lineToPoint:MakeRelativePoint(0.4085750f, 0.2654000f)];
	
	NSAffineTransform *flip = [[NSAffineTransform alloc] init];
//	[flip translateXBy:0.95 yBy:-1.0];
	[flip scaleXBy:0.9f yBy:1.0f];
	[flip translateXBy:0.5f yBy:-0.5f];
	
	[bp transformUsingAffineTransform:flip];
	
	NSShadow *sh = [[NSShadow alloc] init];
	[sh setShadowColor:[[NSColor blackColor] colorWithAlphaComponent:0.45f]];
	[sh setShadowBlurRadius:1.0f];
	[sh setShadowOffset:NSMakeSize(0.0f,-1.0f)];
	[sh set];
	
	[bp fill];
}

+ (NSValue *)_sizeSRRemoveShortcut {
	return [NSValue valueWithSize:NSMakeSize(14.0f,14.0f)];
}
+ (NSValue *)_sizeSRRemoveShortcutRollover { return [self _sizeSRRemoveShortcut]; }
+ (NSValue *)_sizeSRRemoveShortcutPressed { return [self _sizeSRRemoveShortcut]; }
+ (void)_drawARemoveShortcutBoxUsingRep:(id)anNSCustomImageRep opacity:(CGFloat)opacity {
	
//	NSLog(@"drawARemoveShortcutBoxUsingRep: %@ opacity: %f", anNSCustomImageRep, opacity);
	
	NSCustomImageRep *rep = anNSCustomImageRep;
	NSSize size = [rep size];
	[[NSColor colorWithCalibratedWhite:0.0f alpha:1-opacity] setFill];
	CGFloat hScale = (size.width/14.0f);
	CGFloat vScale = (size.height/14.0f);
	
	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0.0f,0.0f,size.width,size.height)] fill];
	
	[[NSColor whiteColor] setStroke];
	
	NSBezierPath *cross = [[NSBezierPath alloc] init];
	[cross setLineWidth:hScale*1.2f];
	
	[cross moveToPoint:MakeRelativePoint(4,4)];
	[cross lineToPoint:MakeRelativePoint(10,10)];
	[cross moveToPoint:MakeRelativePoint(10,4)];
	[cross lineToPoint:MakeRelativePoint(4,10)];
		
	[cross stroke];
}
+ (void)_drawSRRemoveShortcut:(id)anNSCustomImageRep {
	
//	NSLog(@"drawSRRemoveShortcut using: %@", anNSCustomImageRep);
	
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.75f];
}
+ (void)_drawSRRemoveShortcutRollover:(id)anNSCustomImageRep {
	
//	NSLog(@"drawSRRemoveShortcutRollover using: %@", anNSCustomImageRep);
	
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.65f];	
}
+ (void)_drawSRRemoveShortcutPressed:(id)anNSCustomImageRep {
	
//	NSLog(@"drawSRRemoveShortcutPressed using: %@", anNSCustomImageRep);
	
	[self _drawARemoveShortcutBoxUsingRep:anNSCustomImageRep opacity:0.55f];
}
@end
