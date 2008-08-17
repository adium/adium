//
//  ESIRCLibpurpleServicePlugin.m
//  Adium
//
//  Created by Evan Schoenberg on 3/4/06.
//

#import "ESIRCLibpurpleServicePlugin.h"
#import "ESIRCService.h"

@implementation ESIRCLibpurpleServicePlugin

- (void)installPlugin
{
	[ESIRCService registerService];
}

- (void)installLibpurplePlugin
{
	//No action needed. The IRC prpl is incldued in libpurple.framework and initialized by libpurple automatically.
}

- (void)loadLibpurplePlugin
{
	//No action needed
}

- (void)uninstallPlugin
{

}

- (NSString *)libpurplePluginPath
{
	return [[NSBundle bundleForClass:[self class]] resourcePath];
}

@end
