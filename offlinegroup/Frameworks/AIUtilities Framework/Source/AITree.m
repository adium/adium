//
//  AITree.m
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-01-13.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "AITree.h"

/*keys are CFTreeRefs. values are AITrees.
 *this is a non-retaining dictionary. trees are added upon initialisation and
 *	removed upon deallocking.
 */
static NSMutableDictionary *knownTrees = nil;

static CFDictionaryKeyCallBacks nonRetainingCFDictionaryCallbacks = {
	.version = 0,
	.retain = NULL,
	.release = NULL,
	.copyDescription = CFCopyDescription,
	.equal = CFEqual,
	.hash = CFHash,
};
static CFDictionaryKeyCallBacks *nonRetainingCFDictionaryKeyCallbacks = &nonRetainingCFDictionaryCallbacks;
static CFDictionaryValueCallBacks *nonRetainingCFDictionaryValueCallbacks = (CFDictionaryValueCallBacks *)&nonRetainingCFDictionaryCallbacks;

@interface AITree (PRIVATE)


@end

static CFTreeContext treeContextForObjCObjects = {
	.version = 0,
	.info = NULL, //holds object
	.retain  = CFRetain,
	.release = CFRelease,
	.copyDescription = CFCopyDescription,
};

@implementation AITree

+ (void)initialize {
	knownTrees = (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, /*capacity*/ 0,
																  nonRetainingCFDictionaryKeyCallbacks,
																  nonRetainingCFDictionaryValueCallbacks);
}

#pragma mark -

+ (id)treeWithContextObject:(id)obj {
	return [[[self alloc] initWithContextObject:obj] autorelease];
}
+ (id)treeWithContextStructure:(CFTreeContext *)context {
	return [[[self alloc] initWithContextStructure:context] autorelease];
}
+ (id)treeWithCFTree:(CFTreeRef)tree {
	return [self treeWithCFTree:tree createIfNecessary:YES];
}
+ (id)treeWithCFTree:(CFTreeRef)CFTree createIfNecessary:(BOOL)flag {
	AITree *tree = [knownTrees objectForKey:(id)CFTree];
	if ((!tree) && flag) {
		//no AITree exists for this CFTree yet - create one.
		tree = [[[self alloc] initWithCFTree:CFTree] autorelease];
	}
	return tree;
}

- (id)init {
	NSAssert(0, @"cannot create an empty tree - consider using -initWithContextObject: or -initWithContextStructure: instead");
	return nil;
}
- (id)initWithContextObject:(id)obj {
	CFTreeContext tempContext = treeContextForObjCObjects;
	tempContext.info = obj;
	return [self initWithContextStructure:&tempContext];
}
- (id)initWithContextStructure:(CFTreeContext *)context {
	NSParameterAssert(context != NULL);
	if ((self = [super init])) {
		contextStorage = *context;
		backing = CFTreeCreate(kCFAllocatorDefault, &contextStorage);
		childrenSet = [[NSMutableSet alloc] init];
	}
	return self;
}
- (id)initWithCFTree:(CFTreeRef)cfTree {
	NSParameterAssert(cfTree != NULL);
	if ((self = [super init])) {
		backing = (CFTreeRef)CFRetain(cfTree);
		CFTreeGetContext(backing, &contextStorage);
		[knownTrees setObject:self forKey:(id)backing];
		childrenSet = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc {
	[knownTrees removeObjectForKey:(id)backing];
	[childrenSet release];
	CFRelease(backing);

	[super dealloc];
}

#pragma mark -
#pragma mark Managing context

- (id)contextObject {
	return [self contextStructure]->info;
}
- (CFTreeContext *)contextStructure {
	[self getContextStructure:&contextStorage];
	return &contextStorage;
}
- (void)getContextStructure:(out CFTreeContext *)outContext {
	NSParameterAssert(outContext != NULL);
	CFTreeGetContext(backing, &contextStorage);
	*outContext = contextStorage;
}
- (id)objectValue {
	return [self contextObject];
}

- (void)setContextObject:(id)obj {
	CFTreeContext tempContext = treeContextForObjCObjects;
	tempContext.info = obj;
	[self setContextStructure:&tempContext];
}
- (void)setContextStructure:(CFTreeContext *)context {
	contextStorage = *context;
	CFTreeSetContext(backing, &contextStorage);
}

#pragma mark -
#pragma mark Parents

- (AITree *)root {
	return [self rootCreatingAITreeIfNecessary:YES];
}
- (AITree *)rootCreatingAITreeIfNecessary:(BOOL)flag {
	CFTreeRef rootCFTree = CFTreeFindRoot(backing);
	if (!rootCFTree) return nil;
	else return [[self class] treeWithCFTree:rootCFTree createIfNecessary:flag];
}
- (AITree *)parent {
	return [self parentCreatingAITreeIfNecessary:YES];
}
- (AITree *)parentCreatingAITreeIfNecessary:(BOOL)flag {
	CFTreeRef parentCFTree = CFTreeGetParent(backing);
	if (!parentCFTree) return nil;
	else return [[self class] treeWithCFTree:parentCFTree createIfNecessary:flag];
}

#pragma mark -
#pragma mark Siblings

- (AITree *)nextSibling {
	return [self nextSiblingCreatingAITreeIfNecessary:YES];
}
- (AITree *)nextSiblingCreatingAITreeIfNecessary:(BOOL)flag {
	CFTreeRef nextCFTree = CFTreeGetNextSibling(backing);
	if (!nextCFTree) return nil;
	else return [[self class] treeWithCFTree:nextCFTree createIfNecessary:flag];
}
- (void)insertSibling:(AITree *)other {
	NSParameterAssert(other != nil);
	CFTreeInsertSibling(backing, [other cfTree]);
}

- (void)remove {
	AITree *parent = [self parentCreatingAITreeIfNecessary:NO];
	if (parent) [parent->childrenSet removeObject:self];
	CFTreeRemove(backing);
}

#pragma mark -
#pragma mark Children

- (NSArray *)children {
	CFIndex numChildren = CFTreeGetChildCount(backing);
	AITree **trees = malloc(sizeof(AITree *) * numChildren);
	[self getChildren:trees];
	NSArray *array = [NSArray arrayWithObjects:trees count:numChildren];
	free(trees);
	return array;
}
- (void)getChildren:(out AITree **)outChildren {
	[self getChildren:outChildren createAITreesIfNecessary:YES];
}
- (BOOL)getChildren:(out AITree **)outChildren createAITreesIfNecessary:(BOOL)flag {
	NSParameterAssert(outChildren != NULL);
	CFIndex numChildren = CFTreeGetChildCount(backing);
	CFTreeRef *CFTrees = malloc(sizeof(CFTreeRef) * numChildren);
	CFTreeGetChildren(backing, CFTrees);

	Class myClass = [self class];
	for (CFIndex i = 0; i < numChildren; ++i) {
		AITree *tree = [myClass treeWithCFTree:CFTrees[i] createIfNecessary:flag];
		if (!tree) {
			free(CFTrees);
			return NO;
		}
	}

	free(CFTrees);
	return YES;
}
- (void)getCFChildren:(out CFTreeRef *)outChildren {
	NSParameterAssert(outChildren != NULL);
	CFTreeGetChildren(backing, outChildren);
}
- (AITree *)firstChild {
	return [self firstChildCreatingAITreeIfNecessary:YES];
}
- (AITree *)firstChildCreatingAITreeIfNecessary:(BOOL)flag {
	CFTreeRef parentCFTree = CFTreeGetParent(backing);
	if (!parentCFTree) return nil;
	else return [[self class] treeWithCFTree:parentCFTree createIfNecessary:flag];
}

- (void)applyMethodToChildren:(SEL)selector withObject:(id)obj {
	NSParameterAssert(selector != NULL);
	
	CFIndex numChildren = CFTreeGetChildCount(backing);
	AITree **trees = malloc(sizeof(AITree *) * numChildren);
	[self getChildren:trees];

	while (numChildren > 0) {
		[*(trees++) performSelector:selector withObject:obj];
	}
}
- (NSArray *)applyMethodToChildrenReturningObjects:(SEL)selector withObject:(id)obj {
	NSParameterAssert(selector != NULL);

	CFIndex numChildren = CFTreeGetChildCount(backing);
	AITree **trees = malloc(sizeof(AITree *) * numChildren);
	[self getChildren:trees];
	id *returnValues = malloc(sizeof(id) * numChildren);

	for (CFIndex i = 0; i < numChildren; ++i) {
		returnValues[i] = [trees[i] performSelector:selector withObject:obj];
	}

	free(trees);

	NSArray *array = [NSArray arrayWithObjects:returnValues count:numChildren];
	free(returnValues);
	return array;
}

- (unsigned)countChildren {
	return CFTreeGetChildCount(backing);
}
- (AITree *)childAtIndex:(unsigned)index {
	return [self childAtIndex:index createAITreeIfNecessary:YES];
}
- (AITree *)childAtIndex:(unsigned)index createAITreeIfNecessary:(BOOL)flag {
	CFTreeRef child = CFTreeGetChildAtIndex(backing, index);
	NSAssert3(child != NULL, @"CFTreeGetChildAtIndex(%p, %li) returned NULL (tree description: %@)", backing, (long)index, backing);
	return [AITree treeWithCFTree:child createIfNecessary:flag];
}

- (void)prependChild:(AITree *)other {
	NSParameterAssert(other != nil);
	CFTreePrependChild(backing, [other cfTree]);
}
- (void)removeAllChildren {
	CFTreeRemoveAllChildren(backing);
}

- (void)sortChildrenUsingCFComparator:(CFComparatorFunction)func context:(void *)context {
	CFTreeSortChildren(backing, func, context);
}

#pragma mark -
#pragma mark CFTree backing

- (CFTreeRef)cfTree {
	return backing;
}

@end
