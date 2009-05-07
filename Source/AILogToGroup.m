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

#import "AILoggerPlugin.h"
#import "AILogToGroup.h"
#import "AIChatLog.h"
#import "AILogViewerWindowController.h"
#import <AIUtilities/AIFileManagerAdditions.h>

@interface AILogToGroup ()
- (NSDictionary *)logDict;
@end

@implementation AILogToGroup

//A group of logs to an specific user
- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass
{
    if ((self = [super init]))
	{
		NSParameterAssert(inPath != nil);
		relativePath = [inPath copy];
		from = [inFrom copy];
		to = [inTo copy];
		serviceClass = [handleSpecialCasesForUIDAndServiceClass(to, inServiceClass) retain];
		logDict = nil;
		partialLogDict = nil;
		
		defaultManager = [[NSFileManager defaultManager] retain];
	}

    return self;
}

//Dealloc
- (void)dealloc
{
    [relativePath release];
    [to release];
    [from release];
    [serviceClass release];
	[logDict release];
	[partialLogDict release];
	
	[defaultManager release];
	
    [super dealloc];
}

- (NSString *)from
{
	return from;
}

- (NSString *)to
{
    return to;
}

- (NSString *)relativePath
{
	return relativePath;
}

- (NSString *)serviceClass
{
	return serviceClass;
}

//Returns an enumerator for all of our logs
- (NSEnumerator *)logEnumerator
{
	return [[self logDict] objectEnumerator];
}
- (NSInteger)logCount
{
	return [[self logDict] count];
}

- (NSDictionary *)logDict
{
	@synchronized(self) {
		if (!logDict) {
			NSString		*logBasePath, *fullPath;
			
			//
			logDict = [[NSMutableDictionary alloc] init];
			
			//Retrieve any logs we've already loaded
			if (partialLogDict) {
				[logDict addEntriesFromDictionary:partialLogDict];
				[partialLogDict release]; partialLogDict = nil;
			}
			
			logBasePath = [AILoggerPlugin logBasePath];
			fullPath = [logBasePath stringByAppendingPathComponent:relativePath];
			for (NSString *fileName in [defaultManager contentsOfDirectoryAtPath:fullPath error:NULL]) {
				if (![fileName hasPrefix:@"."]) {
					NSString	*relativeLogPath = [relativePath stringByAppendingPathComponent:fileName];
					
					if (![logDict objectForKey:relativeLogPath]) {
						AIChatLog	*theLog;
						
						theLog = [[AIChatLog alloc] initWithPath:relativeLogPath
															from:from
															  to:to
													serviceClass:serviceClass];
						if (theLog) {
							[logDict setObject:theLog
										forKey:relativeLogPath];
						} else {
							AILog(@"Class %@: Couldn't make for %@ %@ %@ %@",NSStringFromClass([AIChatLog class]),relativeLogPath,from,to,serviceClass);
						}	
						[theLog release];
					}
				}
			}
		}
	}
	
    return logDict;
}

/*!
 * @brief Get an AIChatLog within this AILogToGroup
 *
 * @param inPath A _relative_ path of the form SERVICE.ACCOUNT_NAME/TO_NAME/LogName.Extension
 *
 * @result The AIChatLog, from the cache if possible
 */
- (AIChatLog *)logAtPath:(NSString *)inPath
{
	AIChatLog	*theLog;

	@synchronized(self) {
		if (logDict) {
			//Use the full dictionary if we have it
			theLog = [logDict objectForKey:inPath];

		} else {
			//Otherwise, use the partialLog dictionary, adding to it if necessary
			if (!partialLogDict) partialLogDict = [[NSMutableDictionary alloc] init];
			
			if (!(theLog = [partialLogDict objectForKey:inPath])) {				
				theLog = [[AIChatLog alloc] initWithPath:inPath
													from:from
													  to:to
											serviceClass:serviceClass];

				[partialLogDict setObject:theLog
								   forKey:inPath];
				[theLog release];
			}

			if (!theLog) AILog(@"%@ couldn't find %@ in its partialLogDict",self,inPath);
		}
	}
	return theLog;
}

/*!
 * @brief Trash an AIChatLog within this AILogToGroup
 *
 * @param aLog The AIChatLog to move to the trash
 *
 * @result YES if the AIChatLog was successfully trashed
 */
- (BOOL)trashLog:(AIChatLog *)aLog
{
	NSString *logPath = [[AILoggerPlugin logBasePath] stringByAppendingPathComponent:[aLog relativePath]];
	BOOL	 success;
	success = [[NSFileManager defaultManager] trashFileAtPath:logPath];

	//Remove from our dictionaries so we don't reference the removed log
	[logDict removeObjectForKey:[aLog relativePath]];
	[partialLogDict removeObjectForKey:[aLog relativePath]];
	
	return success;
}

/*!
 * @brief Partial isEqual implementation
 *
 * 'Partial' in the sense that it doesn't actually test equality.  If two AILogToGroup objects are for the same service/contact pair,
 * they are considered equal by this function.  They may (and probably do) have different source accounts and therefore different
 * contained logs.
 *
 * This is useful because all To groups for a service/contact pair are presented as a single To group in the Contacts source list.
 */
- (BOOL)isEqual:(id)inObject
{
	return ([inObject isMemberOfClass:[self class]] &&
			([[(AILogToGroup *)inObject to] isEqualToString:[self to]] &&
			 [[(AILogToGroup *)inObject serviceClass] isEqualToString:[self serviceClass]]));
}
- (NSUInteger)hash
{
	return [[self to] hash];
}
@end
