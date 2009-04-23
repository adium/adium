//
//  ESAwayStatusWindowPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIContactObserverManager.h>


@interface ESAwayStatusWindowPlugin : AIPlugin<AIListObjectObserver> {
	BOOL			showStatusWindow;
	NSMutableSet	*awayAccounts;
}

@end
