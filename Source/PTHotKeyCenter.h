//
//  PTHotKeyCenter.h
//  Protein
//
//  Created by Quentin Carnicelli on Sat Aug 02 2003.
//  Copyright (c) 2003 Quentin D. Carnicelli. All rights reserved.
//
//  Contributers:
//      Quentin D. Carnicelli
//      Finlay Dobbie
//      Vincent Pottier

@class PTHotKey;

@interface PTHotKeyCenter : NSObject
{
	NSMutableDictionary*	mHotKeys; //Keys are NSValue of EventHotKeyRef
	BOOL					mEventHandlerInstalled;
}

+ (PTHotKeyCenter*)sharedCenter;

- (BOOL)registerHotKey: (PTHotKey*)hotKey;
- (void)unregisterHotKey: (PTHotKey*)hotKey;

- (NSArray*)allHotKeys;
- (PTHotKey*)hotKeyWithIdentifier: (id)ident;

@end
