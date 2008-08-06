//
//  ESIRCLibpurpleServicePlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import <Adium/AIPlugin.h>
#import <AdiumLibpurple/AILibpurplePlugin.h>

@class ESIRCService;

@interface ESIRCLibpurpleServicePlugin : AIPlugin <AILibpurplePlugin> {
	ESIRCService *ircService;
}

@end
