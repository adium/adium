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

#import "AIDelayedTextField.h"

//  A text field that groups changes, sending its action to its target when 0.5 seconds elapses without a change

@interface AIDelayedTextField ()
- (id)_init;
@end

@implementation AIDelayedTextField

//Init the field
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		self = [self _init];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self _init];
	}
	return self;
}

- (id)_init
{
	delayInterval = 0.5f;
	
	return self;
}

- (void)setDelayInterval:(float)inInterval
{
	delayInterval = inInterval;
}
- (float)delayInterval
{
	return delayInterval;
}

- (void)fireImmediately
{
	[NSObject cancelPreviousPerformRequestsWithTarget:[self target]
											 selector:[self action]
											   object:self];
	
	[[self target] performSelector:[self action] 
						withObject:self];
}

- (void)textDidChange:(NSNotification *)notification
{
	[super textDidChange:notification];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:[self target]
											 selector:[self action]
											   object:self];
	
	[[self target] performSelector:[self action] 
						withObject:self
						afterDelay:delayInterval];
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	//Don't trigger our delayed changes timer after the field ends editing.
	[NSObject cancelPreviousPerformRequestsWithTarget:[self target]
											 selector:[self action]
											   object:self];
	
	[super textDidEndEditing:notification];
}

@end
