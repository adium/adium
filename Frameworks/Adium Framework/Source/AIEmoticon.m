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

#import <Adium/AIEmoticon.h>
#import <Adium/AIEmoticonPack.h>
#import <Adium/AITextAttachmentExtension.h>

@interface AIEmoticon ()
- (AIEmoticon *)initWithIconPath:(NSString *)inPath equivalents:(NSArray *)inTextEquivalents name:(NSString *)inName pack:(AIEmoticonPack *)inPack;
@end

@implementation AIEmoticon

/*!
 * @brief Create an autoreleased emoticon object
 *
 * An AIEmoticon has a path to an image, an array of string equivalents, a localized (if possible) name, and a parent
 * <tt>AIEmoticonPack</tt> which contains it.
 *
 * @param inPath A full path to an image to display for this emoticon
 * @param inTextEquivalents An <tt>NSArray</tt> of text equivalents for this emoticon
 * @param inName A human readable name for the emoticon
 * @param inPack The AIEmoticonPack which contains this emoticon
 */
+ (id)emoticonWithIconPath:(NSString *)inPath equivalents:(NSArray *)inTextEquivalents name:(NSString *)inName pack:(AIEmoticonPack *)inPack
{
    return [[[self alloc] initWithIconPath:inPath equivalents:inTextEquivalents name:inName pack:inPack] autorelease];
}

//Init
- (AIEmoticon *)initWithIconPath:(NSString *)inPath equivalents:(NSArray *)inTextEquivalents name:(NSString *)inName pack:(AIEmoticonPack *)inPack
{
    if ((self = [super init])) {
		path = [inPath retain];
		name = [inName retain];
		textEquivalents = [inTextEquivalents retain];
		pack = [inPack retain];
		imageLoaded = NO;
		_cachedAttributedString = nil;	
    }

    return self;
}

//Dealloc
- (void)dealloc
{
    [path release];
	[name release];
    [textEquivalents release];
	[pack release];
    [_cachedAttributedString release];

	[super dealloc];
}

/*!
 * @brief Returns an array of the text equivalents for this emoticon
 *
 * @result An <tt>NSArray</tt> of <tt>NSStrings</tt> which are the equivalents for the emoticon
 */
- (NSArray *)textEquivalents
{
    return textEquivalents;
}

/*!
 * @brief Flush any cached data
 *
 * This releases image attachment strings which were cached by the emoticon. It is primarily used
 * after display previews of emoticon packs which are not enabled, since there is no reason to maintain a cache that
 * will not be used.
 */
- (void)flushEmoticonImageCache
{
	imageLoaded = NO;
    [_cachedAttributedString release]; _cachedAttributedString = nil;
}

/*!
 * @brief Returns the display name of this emoticon
 *
 * @result The display name of the emoticon
 */
- (NSString *)name
{
    return name;
}

/*!
 * @brief Enable/Disable this emoticon
 *
 * Individual emoticons within an emoticon pack may be enabled or disabled.
 *
 * @param inEnabled The new enabled state
 */
- (void)setEnabled:(BOOL)inEnabled
{
    enabled = inEnabled;
}

/*!
 * @brief Return the enabled state
 *
 * @result The enabled state
 */
- (BOOL)isEnabled{
    return enabled;
}

/*!
 * @brief Returns the image for this emoticon
 *
 * @result The image for this emoticon
 */
- (NSImage *)image
{
    return [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
}

/*!
 * @brief Change the path to the image for this emoticon
 */
- (void)setPath:(NSString *)inPath
{
	if (path != inPath) {
		[path release];
		path = [inPath retain];
		
		[_cachedAttributedString release]; _cachedAttributedString = nil;
	}
}

- (NSString *)path
{
	return path;
}

/*!
 * @brief Returns an attributed string containing this emoticon
 *
 * The attributed string contains an <tt>AITextAttachmentExtension</tt> which has both the emoticon image
 * and the passed text equivalent available.  The hard work is cached, although each call results in a new
 * NSMutableAttributedString being returned.
 *
 * @param textEquivalent The text equivalent for this attributed string 
 * @param attach If YES, an image cell is immediately attached. If NO, no attachment cell is made.
 *
 * @result The attributed string with the emoticon
 */
- (NSMutableAttributedString *)attributedStringWithTextEquivalent:(NSString *)textEquivalent attachImages:(BOOL)attach
{
	static dispatch_queue_t cacheQueue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		cacheQueue = dispatch_queue_create("im.adium.AIEmoticon.cachedAttributedStringQueue", 0);
	});
	__block NSMutableAttributedString   *attributedString;
	dispatch_sync(cacheQueue, ^{
		@autoreleasepool {
			AITextAttachmentExtension   *attachment;
			
			//Cache this attachment for ourself if we don't already have a cache, or if our cache needs to have an image attached
			
			if (!_cachedAttributedString || (!imageLoaded && attach)) {
				[_cachedAttributedString release]; //for the second half of the conditional
				AITextAttachmentExtension   *emoticonAttachment = [[[AITextAttachmentExtension alloc] init] autorelease];
				if(!path || attach) {
					NSTextAttachmentCell		*cell = [[NSTextAttachmentCell alloc] initImageCell:[self image]];
					[emoticonAttachment setAttachmentCell:cell];
					[cell release];
					imageLoaded = YES;
				}
				
				[emoticonAttachment setPath:path];
				[emoticonAttachment setHasAlternate:YES];
				[emoticonAttachment setImageClass:@"emoticon"];
				
				//Emoticons should not ever be sent out as images
				[emoticonAttachment setShouldAlwaysSendAsText:YES];
				
				_cachedAttributedString = [[NSAttributedString attributedStringWithAttachment:emoticonAttachment] retain];
			}
			
			
			//Create a copy of our cached string, and update it for the new text equivalent
			attributedString = [_cachedAttributedString mutableCopy];
			attachment = [[attributedString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL] copy];
			[attributedString addAttribute:NSAttachmentAttributeName value:attachment range:NSMakeRange(0, [attributedString length])];
			[attachment setString:textEquivalent];
			[attachment release];
   		}
    }); 
    return [attributedString autorelease];
}


/*!
 * @brief Is this emoticon appropriate for a service class?
 *
 * @result YES if this emoticon is not associated with any service class or is associated with the passed one.
 */
- (BOOL)isAppropriateForServiceClass:(NSString *)inServiceClass
{
	NSString	*ourServiceClass = pack.serviceClass;
	return !ourServiceClass || [ourServiceClass isEqualToString:inServiceClass];
}

/*!
 * @brief A more useful debug description
 */
- (NSString *)description
{
    return [NSString stringWithFormat:@"%@<%x> (Equivalents: %@) [in %@]",name,self,[self textEquivalents],pack];
}

/*!
 * @brief Compare two emoticons
 *
 * @result The result of comparing the display names of the emoticons, case insensitively
 */
- (NSComparisonResult)compare:(AIEmoticon *)otherEmoticon
{
	return [name localizedCaseInsensitiveCompare:[otherEmoticon name]];
}

@end
