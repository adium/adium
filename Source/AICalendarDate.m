//
//  AICalendarDate.m
//  Adium
//
//  Created by Evan Schoenberg on 7/31/06.
//

#import "AICalendarDate.h"


@implementation AICalendarDate
/*!
 * @brief Initialize with coder
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
		if ([decoder allowsKeyedCoding]) {
			granularity = [[decoder decodeObjectForKey:@"Granularity"] intValue];
		} else {
			granularity = [[decoder decodeObject] intValue];			
		}
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];

	if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:[NSNumber numberWithInteger:granularity] forKey:@"Granularity"];
		
    } else {
        [encoder encodeObject:[NSNumber numberWithInteger:granularity]];
    }
}

- (id)copyWithZone:(NSZone *)inZone
{
	AICalendarDate *newDate = [super copyWithZone:inZone];
	newDate->granularity = granularity;

	return newDate;
}

- (void)setGranularity:(AICalendarDateGranularity)inGranularity
{
	granularity = inGranularity;
}
- (AICalendarDateGranularity)granularity
{
	return granularity;
}
@end
