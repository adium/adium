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

#import "AIPreferenceCVPrototypeView.h"
#import "AIPreferenceCollectionView.h"
#import "AIPreferencePane.h"

@implementation AIPreferenceCVPrototypeView
@synthesize item;

- (id)accessibilityAttributeValue:(NSString *)attribute
{
	//Don't expose the children (image and text field) as accessibility elements since we want them to appear as one item
	if ([attribute isEqualToString:NSAccessibilityChildrenAttribute])
		return [NSArray arrayWithObject:self];
	else if ([attribute isEqualToString:NSAccessibilityParentAttribute])
		return NSAccessibilityUnignoredAncestor([self superview]);

	else if ([attribute isEqualToString:NSAccessibilityTitleAttribute])
		return [(AIPreferencePane *)item.representedObject paneName];
	else if ([attribute isEqualToString:NSAccessibilityDescriptionAttribute])
		return [(AIPreferencePane *)item.representedObject paneName];

	else if ([attribute isEqualToString:NSAccessibilityRoleAttribute])
		return NSAccessibilityButtonRole;
	else if ([attribute isEqualToString:NSAccessibilitySubroleAttribute])
		return NSAccessibilityTableRowSubrole;

	else
		return [super accessibilityAttributeValue:attribute];
}

- (void)accessibilityPerformAction:(NSString *)action
{
	//Pass the action up the chain
	if ([action isEqualToString:NSAccessibilityPressAction])
		[(AIPreferenceCollectionView *)[self superview] didSelectItem:item];
}

@end
