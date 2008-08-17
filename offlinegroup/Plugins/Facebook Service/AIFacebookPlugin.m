//
//  AIFacebookPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 5/8/08.
//

#import "AIFacebookPlugin.h"
#import "AIFacebookService.h"

@implementation AIFacebookPlugin

- (void)installPlugin
{
	[AIFacebookService registerService];
}

@end
