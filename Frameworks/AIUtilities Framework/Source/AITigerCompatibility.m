//
//  AITigerCompatibility.m
//  AIUtilities.framework
//
//  Created by David Smith on 8/1/08.
//  Copyright 2008 The Adium Team. All rights reserved.
//

#import <AIUtilities/AITigerCompatibility.h>
#if MAC_OS_X_VERSION_10_5 > MAC_OS_X_VERSION_MAX_ALLOWED

//64 bit isn't supported on 10.4, so using int is fine
@implementation NSNumber (NSNumber64BitCompat)
- (NSInteger)integerValue
{
    return [self intValue];
}
- (NSUInteger)unsignedIntegerValue
{
    return [self unsignedIntValue];
}
+ (NSNumber *)numberWithInteger:(NSInteger)value
{
    return [self numberWithInt:value];
}
+ (NSNumber *)numberWithUnsignedInteger:(NSUInteger)value
{
    return [self numberWithUnsignedInt:value];
}
@end

@implementation NSControl (NSControl64BitCompat)
- (NSInteger)integerValue
{
    return [self intValue];
}
- (void)setIntegerValue:(NSInteger)anInteger
{
    [self setIntValue:anInteger];
}
- (void)takeIntegerValueFrom:(id)sender
{
    [self takeIntValueFrom:sender];
}
@end

@implementation NSString (NSString64BitCompat)
- (NSInteger)integerValue
{
    return [self intValue];
}
@end
#endif
