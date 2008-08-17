//
//  AdiumIBPalette.m
//  AdiumIBPalette
//
//  Created by Peter Hosey on 2006-05-11.
//  Copyright 2006 The Adium Project. All rights reserved.
//

#import "AdiumIBPalette.h"

@implementation AdiumIBPalette

- (void)finishInstantiate
{
	[previewView setPreviewText:NSLocalizedString(@"Text color preview", /*comment*/ nil)];

	[super finishInstantiate];
}

@end
