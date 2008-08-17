//
//  AXCDocumentController.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-31.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCDocumentController.h"

#import "AXCStartingPointsController.h"

@implementation AXCDocumentController

//we want to hide the Starting Points window when a document is opened.
- (void) addDocument:(NSDocument *)document
{
	[startingPointsController setStartingPointsVisible:NO];

	[super addDocument:document];
}

//we want to show the Starting Points window again when the last document is closed.
- (void) removeDocument:(NSDocument *)document
{
	[super removeDocument:document];

	if (![[self documents] count])
		[startingPointsController setStartingPointsVisible:YES];
}

@end
