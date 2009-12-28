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

#import <Adium/AIListContact.h>
#import <Adium/AIListGroup.h>
#import <Adium/AISortController.h>
#import <Adium/AIContactControllerProtocol.h>
#import <AIUtilities/AIStringAdditions.h>

#define KEY_RESOLVE_ALPHABETICALLY  @"Status:Resolve Alphabetically"

NSComparisonResult basicGroupSort(id objectA, id objectB, void *context);
NSComparisonResult basicSort(id objectA, id objectB, void *context);

@interface AISortController()
- (NSArray *)sortedListObjects:(NSArray *)inObjects inContainer:(id<AIContainingObject>)container;
- (void)sortListObjects:(NSMutableArray *)inObjects inContainer:(id<AIContainingObject>)container;
@end

@implementation AISortController

static AISortController *activeSortController = nil;
static NSMutableArray *sortControllers = nil;

+ (void) setActiveSortController:(AISortController *)newSortController
{
	[activeSortController autorelease];
	activeSortController = [newSortController retain];
	
	[activeSortController didBecomeActive];
	
	//The newly-active sort controller needs to know whether it should be forced to ignore groups
	[activeSortController forceIgnoringOfGroups:![adium.contactController useContactListGroups]];
	
	//Resort the list
	[adium.contactController sortContactList];
}

+ (AISortController *)activeSortController
{
	return activeSortController;
}

+ (void) registerSortController:(AISortController *)newSortController
{
	if(!sortControllers)
		sortControllers = [[NSMutableArray alloc] init];
	[sortControllers addObject:newSortController];
}

+ (NSArray *)availableSortControllers
{
	NSAssert(sortControllers != nil, @"Someone tried to get the list of sort controllers before any registered");
	return sortControllers;
}

/*!
 * @brief Initialize
 */
- (id)init
{
	if ((self = [super init])) {
		statusKeysRequiringResort = [[self statusKeysRequiringResort] retain];
		attributeKeysRequiringResort = [[self attributeKeysRequiringResort] retain];
		sortFunction = [self sortFunction];
		alwaysSortGroupsToTop = [self alwaysSortGroupsToTopByDefault];
		
		configureView = nil;
		becameActiveFirstTime = NO;
	}
	
	return self;
}

/*!
 * @brief Deallocate
 */
- (void)dealloc
{
	[statusKeysRequiringResort release];
	[attributeKeysRequiringResort release];
	
	[configureView release]; configureView = nil;
	
	[super dealloc];
}

/*!
 * @brief Configure our customization view
 */
- (NSView *)configureView
{
	if (!configureView)
		[NSBundle loadNibNamed:[self configureNibName] owner:self];
	
	[self viewDidLoad];
	
	return configureView;
}

//Sort Logic -------------------------------------------------------------------------------------------------------
#pragma mark Sort Logic
/*!
 * @brief Should we resort for a set of changed properties?
 *
 * @param inModifiedKeys NSSet of NSString keys to test
 * @result YES if we need to resort
 */
- (BOOL)shouldSortForModifiedStatusKeys:(NSSet *)inModifiedKeys
{
	if (statusKeysRequiringResort) {
		return [statusKeysRequiringResort intersectsSet:inModifiedKeys];
	} else {
		return NO;
	}
}

/*!
 * @brief Should we resort for a set of changed attribute keys?
 *
 * @param inModifiedKeys NSSet of NSString keys to test
 * @result YES if we need to resort
 */
- (BOOL)shouldSortForModifiedAttributeKeys:(NSSet *)inModifiedKeys
{
	if (attributeKeysRequiringResort) {
		return [attributeKeysRequiringResort intersectsSet:inModifiedKeys];
	} else {
		return NO;
	}
}

/*!
 * @brief Always sort groups to the top by default?
 *
 * By default, manual sort ignores groups and sorts them alongside all other objects
 * while alphabetical and status sort them to the top of any given array.
 */
- (BOOL)alwaysSortGroupsToTopByDefault
{
	return YES;
}

/*!
 * @brief Force ignoring of groups?
 *
 * @param shouldForce If YES, groups are ignored. If NO, default behavior for this sort is used.
 */
- (void)forceIgnoringOfGroups:(BOOL)shouldForce
{
	alwaysSortGroupsToTop = shouldForce ? NO : [self alwaysSortGroupsToTopByDefault];
}

/*!
 * @brief Can the user manually reorder when this sort controller is active?
 *
 * @result YES if we should allow manual sorting; NO if we should not.
 */
- (BOOL)canSortManually {
	return NO;
}

//Sorting -------------------------------------------------------------------------------------------------------
#pragma mark Sorting
/*!
 * @brief Index for inserting an object into an array
 *
 * @param inObject The AIListObject to be inserted object
 * @param inObjects An NSArray of AIListObject objects
 * @result The index for insertion
 */
- (int)indexForInserting:(AIListObject *)inObject intoObjects:(NSArray *)inObjects inContainer:(id<AIContainingObject>)container
{
	NSEnumerator 	*enumerator = [inObjects objectEnumerator];
	AIListObject	*object;
	int				idx = 0;
	
	SortContext context = {
		sortFunction,
		container
	};
	
	if (alwaysSortGroupsToTop) {
		while ((object = [enumerator nextObject]) && ((object == inObject) || 
			  basicGroupSort(inObject, object, &context) == NSOrderedDescending)) idx++;
	} else {
		while ((object = [enumerator nextObject]) && ((object == inObject) ||
			  basicSort(inObject, object, &context) == NSOrderedDescending)) idx++;
	}
	
	return idx;
}

/*!
 * @brief Sort an array of list objects
 *
 * The passed list objects are sorted using sortFunction.
 *
 * We assume that, in general, the array is already close to being properly sorted; we therefore generate and use a hint.
 * This mildly hurts our worst case performance, but it improves both our best and average cases, so it is a worthwhile tradeoff.
 *
 * @param inObjects An NSArray of AIListObject instances to sort
 * @result A sorted NSArray containing the same AIListObjects from inObjects
 */
- (NSArray *)sortedListObjects:(NSArray *)inObjects inContainer:(id<AIContainingObject>)container
{
	SortContext context = {
		sortFunction,
		container
	};
	return [inObjects sortedArrayUsingFunction:(alwaysSortGroupsToTop ? basicGroupSort : basicSort)
									   context:&context
										  hint:[inObjects sortedArrayHint]];
}

- (void) sortListObjects:(NSMutableArray *)inObjects inContainer:(id<AIContainingObject>)container
{
	SortContext context = {
		sortFunction,
		container
	};
	[inObjects sortUsingFunction:(alwaysSortGroupsToTop ? basicGroupSort : basicSort) context:&context];
}

/*!
 * @brief Primary sort when groups are sorted alongside contacts (alwaysSortGroupsToTop == FALSE)
 */
NSComparisonResult basicSort(id objectA, id objectB, void *context)
{
	SortContext ctx = *((SortContext*)context);
	
	return (ctx.function)(objectA, objectB, NO, ctx.container);
}

/*!
 * @brief Primary sort when groups are always sorted to the top
 */
NSComparisonResult basicGroupSort(id objectA, id objectB, void *context)
{
	BOOL	groupA = [objectA isKindOfClass:[AIListGroup class]];
	BOOL	groupB = [objectB isKindOfClass:[AIListGroup class]];
	
	if (groupA && !groupB) {
		return NSOrderedAscending;
	} else if (!groupA && groupB) {
		return NSOrderedDescending;
	} else {
		SortContext ctx = *((SortContext*)context);
		
		return (ctx.function)(objectA, objectB, groupA, ctx.container);
	}
}

/*!
 * @brief The controller became active (in use by Adium)
 */
- (void)didBecomeActive 
{
	if (!becameActiveFirstTime) {
		[self didBecomeActiveFirstTime];
		becameActiveFirstTime = YES;
	}
}

/*!
 * @brief Title for the Configure Sort menu item  when this sort is active
 *
 * Subclasses should provide a title for configuring the sort only if configuration is possible.
 * @result Localized title. If nil, the menu item will be disabled.
 */
- (NSString *)configureSortMenuItemTitle{ 
	NSString *configureSortWindowTitle = [self configureSortWindowTitle];
	if (configureSortWindowTitle) {
		return [[self configureSortWindowTitle] stringByAppendingEllipsis];
	} else {
		return nil;
	}
}

/*!
 * @brief NSSortDescriptor override to perform sorting our way.
 */
- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
	if (alwaysSortGroupsToTop) {
		return basicGroupSort(object1, object2, sortFunction);
	} else {
		return basicSort(object1, object2, sortFunction);
	}	
}

//For subclasses -------------------------------------------------------------------------------------------------------
#pragma mark For Subclasses:

/*!
 * @brief Non-localized identifier
 */
- (NSString *)identifier{ return nil; };

/*!
 * @brief Localized display name
 */
- (NSString *)displayName{ return nil; };

/*!
 * @brief Properties which, when changed, should trigger a resort
 */
- (NSSet *)statusKeysRequiringResort{ return nil; };

/*!
 * @brief Attribute keys which, when changed, should trigger a resort
 */
- (NSSet *)attributeKeysRequiringResort{ return nil; };

/*!
 * @brief Sort function
 */
- (sortfunc)sortFunction{ return NULL; };

/*!
 * @brief Did become active first time
 *
 * Called only once; gives the sort controller an opportunity to set defaults and load preferences lazily.
 */
- (void)didBecomeActiveFirstTime {};

/*!
 * @brief Window title when configuring the sort
 *
 * Subclasses should provide a title for configuring the sort only if configuration is possible.
 * @result Localized title. If nil, the menu item will be disabled.
 */
- (NSString *)configureSortWindowTitle{ return nil; };

/*!
 * @brief Nib name for configuration
 */
- (NSString *)configureNibName{ return nil; };

/*!
 * @brief View did load
 */
- (void)viewDidLoad{ };

/*!
 * @brief Preference changed
 *
 * Sort controllers should live update as preferences change.
 */
- (IBAction)changePreference:(id)sender{ };

@end

@implementation NSArray (AdiumSorting)
- (NSArray *) sortedArrayUsingActiveSortControllerInContainer:(id<AIContainingObject>)container
{
	return [[AISortController activeSortController] sortedListObjects:self inContainer:container];
}
@end

@implementation NSMutableArray (AdiumSorting)
- (void) sortUsingActiveSortControllerInContainer:(id<AIContainingObject>)container
{
	[[AISortController activeSortController] sortListObjects:self inContainer:container];
}
@end
