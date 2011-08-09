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

#import <Adium/AIContentObject.h>
#import <Adium/AIContentTyping.h>

@interface AIContentTyping ()
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest typingState:(AITypingState)inTyping;
@end

@implementation AIContentTyping

+ (id)typingContentInChat:(AIChat *)inChat withSource:(id)inSource destination:(id)inDest typingState:(AITypingState)inTypingState
{
    return [[[self alloc] initWithChat:inChat source:inSource destination:inDest typingState:inTypingState] autorelease];
}

- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest typingState:(AITypingState)inTypingState
{
	
	if ((self = [super initWithChat:inChat source:inSource destination:inDest date:nil])) {
		//Typing content should NOT be filtered, tracked, or displayed
		filterContent = NO;
		trackContent = NO;
		displayContent = NO;
		
		//Store typing state
		typingState = inTypingState;
	}

	return self;
}

- (void)dealloc
{
    [super dealloc];
}

//Content Identifier
- (NSString *)type
{
    return CONTENT_TYPING_TYPE;
}

@synthesize typingState;

@end
