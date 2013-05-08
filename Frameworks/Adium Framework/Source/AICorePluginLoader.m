/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

/*
 Core - Plugin Loader
 
 Loads external plugins (Including plugins stored within our application bundle).  Also responsible for warning the
 user of old or incompatible plugins.

 */

#import <Adium/AICorePluginLoader.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <AIUtilities/AIApplicationAdditions.h>

#define DIRECTORY_INTERNAL_PLUGINS		[@"Contents" stringByAppendingPathComponent:@"PlugIns"]	//Path to the internal plugins
#define EXTERNAL_PLUGIN_FOLDER			@"PlugIns"				//Folder name of external plugins
#define EXTERNAL_DISABLED_PLUGIN_FOLDER	@"PlugIns (Disabled)"	//Folder name for disabled external plugins
#define XTRAS_DISABLED			@" (Disabled)"
#define EXTENSION_ADIUM_PLUGIN			@"AdiumPlugin"			//File extension of a plugin

#define CONFIRMED_PLUGINS				@"Confirmed Plugins"
#define CONFIRMED_PLUGINS_VERSION		@"Confirmed Plugin Version"

//#define PLUGIN_LOAD_TIMING
#ifdef PLUGIN_LOAD_TIMING
NSTimeInterval aggregatePluginLoadingTime = 0.0;
#endif

static	NSMutableDictionary	*pluginDict = nil;
static	NSMutableSet		*pluginBundleIdentifiers = nil;	
static  NSMutableArray		*deferredPluginPaths = nil;

@interface AICorePluginLoader ()
- (void)loadPlugins;
+ (BOOL)confirmPluginAtPath:(NSString *)pluginPath;
+ (BOOL)confirmPluginArchitectureAtPath:(NSString *)pluginPath;
+ (BOOL)confirmMinimumVersionMetForPluginAtPath:(NSString *)pluginPath;
+ (BOOL)pluginIsBlacklisted:(NSBundle *)plugin;
+ (BOOL)allDependenciesMetForPluginAtPath:(NSString *)pluginPath;
@end

@implementation AICorePluginLoader

+ (void)initialize
{
	if (self == [AICorePluginLoader class]) {
		pluginDict = [[NSMutableDictionary alloc] init];
		pluginBundleIdentifiers = [[NSMutableSet alloc] init];
	}
}

- (id)init
{
	if ((self = [super init])) {
		pluginArray = [[NSMutableArray alloc] init];

		[self loadPlugins];
	}

	return self;
}

//init
- (void)loadPlugins
{
	//Init
	[adium createResourcePathForName:EXTERNAL_PLUGIN_FOLDER];

	//If the Adium version has increased since our last run, warn the user that their external plugins may no longer work
	NSString	*lastVersion = [[NSUserDefaults standardUserDefaults] objectForKey:CONFIRMED_PLUGINS_VERSION];
	if (!lastVersion ||
		[adium compareVersion:[NSApp applicationVersion] toVersion:lastVersion] == NSOrderedAscending) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:CONFIRMED_PLUGINS];
		[[NSUserDefaults standardUserDefaults] setObject:[NSApp applicationVersion] forKey:CONFIRMED_PLUGINS_VERSION];
	}
	
	NSString *internalPluginsPath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DIRECTORY_INTERNAL_PLUGINS] stringByExpandingTildeInPath];
	
	//Load the plugins in our bundle
	for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:internalPluginsPath error:NULL]) {
		if ([[path pathExtension] caseInsensitiveCompare:EXTENSION_ADIUM_PLUGIN] == NSOrderedSame)
			[[self class] loadPluginAtPath:[internalPluginsPath stringByAppendingPathComponent:path]
							confirmLoading:NO
							   pluginArray:pluginArray];
	}

	//Load any external plugins the user has installed
	for (NSString *path in [adium allResourcesForName:EXTERNAL_PLUGIN_FOLDER withExtensions:EXTENSION_ADIUM_PLUGIN]) {
		[[self class] loadPluginAtPath:path confirmLoading:YES pluginArray:pluginArray];
	}

	for (NSString *path in deferredPluginPaths) {
		[[self class] loadPluginAtPath:path confirmLoading:YES pluginArray:pluginArray];		
	}
	[deferredPluginPaths release]; deferredPluginPaths = nil;

#ifdef PLUGIN_LOAD_TIMING
	AILog(@"Total time spent loading plugins: %f", aggregatePluginLoadingTime);
#endif
}

- (void)controllerDidLoad
{
}

//Give all external plugins a chance to close
- (void)controllerWillClose
{
    for (id<AIPlugin>plugin in pluginArray) {
		[[NSNotificationCenter defaultCenter] removeObserver:plugin];
		[[NSNotificationCenter defaultCenter] removeObserver:plugin];
		[plugin uninstallPlugin];
    }
}

- (void)dealloc
{
	[pluginArray release];
	pluginArray = nil;

	[super dealloc];
}

+ (BOOL)pluginIsBlacklisted:(NSBundle *)plugin
{
	// Only one right now: the Skype plugin that works with 1.4 crashes in 1.5 (see #15590).
	if ([[plugin bundleIdentifier] isEqualToString:@"org.bigbrownchunx.skypeplugin"] &&
		[[[plugin infoDictionary] objectForKey:@"CFBundleVersion"] isEqualToString:@"1.0"]) {
		return YES;
	}
	
	return NO;
}

/*!
 * @brief Load plugins from the specified path
 *
 * @param pluginPath The path to the plugin bundle
 * @param confirmLoading If YES, confirm loading of the plugin if it hasn't been loaded with this Adium version before
 * @param inPluginArray May be nil.  If non-nil, an NSMutableArray to fill with an instance of the principal class (AIPlugin conforming) of each plugin which loads.
 */
+ (void)loadPluginAtPath:(NSString *)pluginPath confirmLoading:(BOOL)confirmLoading pluginArray:(NSMutableArray *)inPluginArray
{
#ifdef PLUGIN_LOAD_TIMING
	NSDate *start = [NSDate date];
#endif	
	// Confirm plugins can load on this arch
	if(![self confirmPluginArchitectureAtPath:pluginPath]) {
		NSRunInformationalAlertPanel([NSString stringWithFormat:AILocalizedString(@"Plugin %@ Will be Disabled", "%@ will be the name of a plugin. This is the title of the dialogue shown when an plugin is loaded on an unsupported architecture."),
									  [[pluginPath lastPathComponent] stringByDeletingPathExtension]],
									 AILocalizedString(@"This plugin does not support your native architecture.", nil),
									 AILocalizedString(@"Disable", nil),
									 nil,
									 nil);
		[self moveXtra:pluginPath toDisabledFolder:YES];
		return;
	}
	
	//Confirm the presence of external plugins with the user
	if (confirmLoading && 
		(![self confirmMinimumVersionMetForPluginAtPath:pluginPath] ||
		 ![self confirmPluginAtPath:pluginPath]))
			return;
	
	if (![self allDependenciesMetForPluginAtPath:pluginPath]) {
		if (!deferredPluginPaths) deferredPluginPaths = [[NSMutableArray alloc] init];
		[deferredPluginPaths addObject:pluginPath];
		return;
	}
		
	
	//Load the plugin
	NSBundle		*pluginBundle;
	id <AIPlugin>	plugin = nil;

	@try
	{
		if ((pluginBundle = [NSBundle bundleWithPath:pluginPath])) {
			
			if ([self pluginIsBlacklisted:pluginBundle]) {
				NSRunInformationalAlertPanel([NSString stringWithFormat:
											  AILocalizedString(@"Plugin %@ Will be Disabled", "%@ will be the name of a plugin. This is the title of the dialogue shown when an plugin is blacklisted."),
											  [[pluginPath lastPathComponent] stringByDeletingPathExtension]],
											 [NSString stringWithFormat:
											  AILocalizedString(@"This plugin is known to be incompatible with Adium %@.", "%@ will be a version number of Adium"),
											  [NSApp applicationVersion]],
											 AILocalizedString(@"Disable", nil),
											 nil,
											 nil);
				[self moveXtra:pluginPath toDisabledFolder:YES];
				return;
			}
			
			Class principalClass = [pluginBundle principalClass];
			if (principalClass) {
				plugin = [[principalClass alloc] init];
			} else {
				NSLog(@"Failed to obtain principal class from plugin \"%@\" (\"%@\")! infoDictionary: %@",
					  [pluginPath lastPathComponent],
					  pluginPath,
					  [pluginBundle infoDictionary]);
			}
			
			if (plugin) {
				[plugin installPlugin];
				[inPluginArray addObject:plugin];
				[pluginDict setObject:plugin forKey:NSStringFromClass(principalClass)];
				[pluginBundleIdentifiers addObject:[pluginBundle bundleIdentifier]];

				[plugin release];
			} else {
				NSLog(@"Failed to initialize Plugin \"%@\" (\"%@\")!",[pluginPath lastPathComponent],pluginPath);
			}
		} else {
				NSLog(@"Failed to open Plugin \"%@\"!",[pluginPath lastPathComponent]);
		}
	}
	@catch(id exc)
	{
		if (confirmLoading) {
			//The plugin encountered an exception while it was loading.  There is no reason to leave this old
			//or poorly coded plugin enabled so that it can cause more problems, so disable it and inform
			//the user that they'll need to restart.
			[self moveXtra:pluginPath toDisabledFolder:YES];
			NSRunCriticalAlertPanel([NSString stringWithFormat:@"Error loading %@",[[pluginPath lastPathComponent] stringByDeletingPathExtension]],
									@"An external plugin failed to load and has been disabled.  Please relaunch Adium",
									@"Quit",
									nil,
									nil);
			[NSApp terminate:nil];					
		}
	}
#ifdef PLUGIN_LOAD_TIMING
	NSTimeInterval t = -[start timeIntervalSinceNow];
	aggregatePluginLoadingTime += t;
	AILog(@"Loaded plugin: %@ in %f seconds", [pluginBundle bundleIdentifier], t);
#endif
}

//Confirm the presence of an external plugin with the user.  Returns YES if the plugin should be loaded.
+ (BOOL)confirmPluginAtPath:(NSString *)pluginPath
{
	BOOL	loadPlugin = YES;
	NSArray	*confirmed = [[NSUserDefaults standardUserDefaults] objectForKey:CONFIRMED_PLUGINS];

	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"AIAutoConfirmExternalPlugins"]  &&
		(!confirmed || ![confirmed containsObject:[pluginPath lastPathComponent]])) {
		if (NSRunInformationalAlertPanel([NSString stringWithFormat:AILocalizedString(@"Disable %@?", "%@ will be the name of a plugin. This is the title of the dialogue shown when an unknown plugin is loaded"),[[pluginPath lastPathComponent] stringByDeletingPathExtension]],
										AILocalizedString(@"External plugins may cause crashes and odd behavior after updating Adium.  Disable this plugin if you experience any issues.", nil),
										AILocalizedString(@"Disable", nil),
										AILocalizedString(@"Continue", nil),
										nil) == NSAlertDefaultReturn) {
			//Disable this plugin
			[self moveXtra:pluginPath toDisabledFolder:YES];
			loadPlugin = NO;
			
		} else {
			//Add this plugin to our confirmed list
			confirmed = (confirmed ? [confirmed arrayByAddingObject:[pluginPath lastPathComponent]] : [NSArray arrayWithObject:[pluginPath lastPathComponent]]);
			[[NSUserDefaults standardUserDefaults] setObject:confirmed forKey:CONFIRMED_PLUGINS];
		}
	}
	
	return loadPlugin;
}

+ (BOOL)confirmPluginArchitectureAtPath:(NSString *)pluginPath
{
#ifndef CURRENT_BUNDLE_ARCH_IS_DEFINED
	#if defined(__x86_64__)
		#define CURRENT_BUNDLE_ARCH NSBundleExecutableArchitectureX86_64
	#elif defined(__i386__)
		#define CURRENT_BUNDLE_ARCH NSBundleExecutableArchitectureI386
	#else
		#error Unsupported Architecture!
	#endif
	#define CURRENT_BUNDLE_ARCH_IS_DEFINED 1
#endif
	NSBundle *pluginBundle = [NSBundle bundleWithPath:pluginPath];
	NSArray *pluginArchs = [pluginBundle executableArchitectures];
	
	return [pluginArchs containsObject:[NSNumber numberWithInteger:CURRENT_BUNDLE_ARCH]];
}

+ (BOOL)confirmMinimumVersionMetForPluginAtPath:(NSString *)pluginPath
{
	NSString *minimumVersionOfPlugin = [[[NSBundle bundleWithPath:pluginPath] infoDictionary] objectForKey:@"AIMinimumAdiumVersionRequirement"];
	if (!minimumVersionOfPlugin) {
		NSString *pluginName = [[pluginPath lastPathComponent] stringByDeletingPathExtension];

		NSLog(@"The %@ plugin is not compatible with Adium %@. Please check xtras.adium.im to see if an update is available.",
			  pluginName, [NSApp applicationVersion]);

		NSRunAlertPanel([NSString stringWithFormat:@"Could not load %@", pluginName],
						@"The %@ plugin is not compatible with Adium %@. Please check xtras.adium.im to see if an update is available.",
						AILocalizedString(@"Disable", nil), nil, nil, pluginName, [NSApp applicationVersion]);
		[self moveXtra:pluginPath toDisabledFolder:YES];
		return NO;
	}

	NSString *appVersion = [NSApp applicationVersion];
	if ([appVersion rangeOfString:@"svn"].location != NSNotFound)
		appVersion = [appVersion substringToIndex:[appVersion rangeOfString:@"svn"].location];
	
	if ([appVersion rangeOfString:@"hg"].location != NSNotFound)
		appVersion = [appVersion substringToIndex:[appVersion rangeOfString:@"hg"].location];

	NSComparisonResult versionComparison = [adium compareVersion:appVersion
													   toVersion:minimumVersionOfPlugin];

	if (versionComparison == NSOrderedAscending) {
		NSString *pluginName = [[pluginPath lastPathComponent] stringByDeletingPathExtension];

		NSRunAlertPanel([NSString stringWithFormat:@"Could not load %@", pluginName],
						@"%@ requires Adium %@ or later, but you have Adium %@. Please upgrade Adium to use %@",
						AILocalizedString(@"Disable", nil), nil, nil, 
						pluginName, minimumVersionOfPlugin, appVersion, pluginName);
		[self moveXtra:pluginName toDisabledFolder:YES];
		return NO;
	}

	return YES;
}

+ (BOOL)allDependenciesMetForPluginAtPath:(NSString *)pluginPath
{
	NSArray *dependencies = [[[NSBundle bundleWithPath:pluginPath] infoDictionary] objectForKey:@"AIPluginDependencies"];
	
	return ((dependencies && [dependencies count]) ?
			[[NSSet setWithArray:dependencies] isSubsetOfSet:pluginBundleIdentifiers] : 
			YES);
}

+ (void)moveXtra:(NSString *)pluginPath toDisabledFolder:(BOOL)disable
{
	NSString	*pluginName = [pluginPath lastPathComponent];
	NSString	*basePath = [pluginPath stringByDeletingLastPathComponent];
	NSString	*typeName = [basePath lastPathComponent];
	
	if (disable) {
		if ([typeName rangeOfString:XTRAS_DISABLED].location == NSNotFound)
			typeName = [typeName stringByAppendingString:XTRAS_DISABLED];
	} else {
		typeName = [typeName stringByReplacingOccurrencesOfString:XTRAS_DISABLED withString:@""];
	}
	
	NSString	*newPath = [[basePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:typeName];
	[[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:NULL];
	[[NSFileManager defaultManager] moveItemAtPath:pluginPath
											toPath:[newPath stringByAppendingPathComponent:pluginName]
											 error:NULL];
}

/*!
 * @brief Retrieve a plugin by its class name
 */
- (id <AIPlugin>)pluginWithClassName:(NSString *)className {
	return [pluginDict objectForKey:className];
}

@end
