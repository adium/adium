//
//  AdiumIBPalette.h
//  AdiumIBPalette
//
//  Created by Peter Hosey on 2006-05-11.
//  Copyright 2006 The Adium Project. All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>

#import "AITextColorPreviewView.h"

@interface AdiumIBPalette : IBPalette
{
	IBOutlet AITextColorPreviewView *previewView;
}
@end
