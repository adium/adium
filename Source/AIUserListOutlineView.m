//
//  AIUserListOutlineView.m
//  Adium
//
//  Created by Evan Schoenberg on 11/22/07.
//

#import "AIUserListOutlineView.h"

@implementation AIUserListOutlineView

/*!
 * @brief Should we perform type select next/previous on find?
 *
 * @return YES to switch between type-select results. NO to to switch within the responder chain.
 */
- (BOOL)tabPerformsTypeSelectFind
{
	return NO;
}

- (void)dealloc
{
	AILogWithSignature(@"");
	[super dealloc];
}

@end
