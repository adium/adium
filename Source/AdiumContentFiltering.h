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

#import <Adium/AIContentControllerProtocol.h>

@interface AdiumContentFiltering : NSObject {
	NSMutableArray			*contentFilter[FILTER_TYPE_COUNT][FILTER_DIRECTION_COUNT];

	NSMutableArray			*delayedContentFilters[FILTER_TYPE_COUNT][FILTER_DIRECTION_COUNT];
	
	NSMutableArray			*htmlContentFilters[FILTER_DIRECTION_COUNT];
	
	NSMutableSet			*stringsRequiringPolling;
	
	NSMutableDictionary		*delayedFilteringDict;
}

- (void)registerContentFilter:(id <AIContentFilter>)inFilter
					   ofType:(AIFilterType)type
					direction:(AIFilterDirection)direction;

- (void)registerDelayedContentFilter:(id<AIDelayedContentFilter>)inFilter
							  ofType:(AIFilterType)type
						   direction:(AIFilterDirection)direction;

- (void)registerHTMLContentFilter:(id <AIHTMLContentFilter>)inFilter
						direction:(AIFilterDirection)direction;

- (void)unregisterContentFilter:(id <AIContentFilter>)inFilter;
- (void)unregisterDelayedContentFilter:(id <AIDelayedContentFilter>)inFilter;
- (void)unregisterHTMLContentFilter:(id <AIHTMLContentFilter>)inFilter;

- (void)registerFilterStringWhichRequiresPolling:(NSString *)inPollString;
- (BOOL)shouldPollToUpdateString:(NSString *)inString;

- (NSAttributedString *)filterAttributedString:(NSAttributedString *)attributedString
							   usingFilterType:(AIFilterType)type
									 direction:(AIFilterDirection)direction
									   context:(id)context;
- (void)filterAttributedString:(NSAttributedString *)attributedString
			   usingFilterType:(AIFilterType)type
					 direction:(AIFilterDirection)direction
				 filterContext:(id)filterContext
			   notifyingTarget:(id)target
					  selector:(SEL)selector
					   context:(id)context;

- (NSString *)filterHTMLString:(NSString *)htmlString
					 direction:(AIFilterDirection)direction
					   content:(AIContentObject *)content;

- (void)delayedFilterDidFinish:(NSAttributedString *)attributedString uniqueID:(unsigned long long)uniqueID;

@end
