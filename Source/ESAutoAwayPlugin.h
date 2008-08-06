//
//  ESAutoAwayPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIPlugin.h>

@interface ESAutoAwayPlugin : AIPlugin {
	BOOL				automaticAwaySet;
	NSMutableDictionary	*previousStatusStateDict;
	NSMutableSet		*accountsToReconnect;
	
	BOOL		autoAway;
	NSNumber	*autoAwayID;
	double		autoAwayInterval;
}

@end
