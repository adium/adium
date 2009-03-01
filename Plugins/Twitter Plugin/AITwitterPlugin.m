//
//  AITwitterPlugin.m
//  Adium
//
//  Created by Zachary West on 2009-02-27.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AITwitterPlugin.h"
#import "AITwitterService.h"

@implementation AITwitterPlugin
- (void)installPlugin
{
	[AITwitterService registerService];
}
@end
