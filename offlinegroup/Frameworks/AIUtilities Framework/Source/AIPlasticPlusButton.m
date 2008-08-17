//
//  AIPlasticPlusButton.m
//  Adium
//
//  Created by Adam Iser on 8/9/04.
//

#import "AIPlasticPlusButton.h"
#import "AIImageAdditions.h"

@implementation AIPlasticPlusButton

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self setImage:[NSImage imageNamed:@"plus" forClass:[self class]]];
		[self setTitle:NSLocalizedString(@"Add", /*comment*/ nil)];
		[self setImagePosition:NSImageOnly];
	}
	return self;   
}

@end
