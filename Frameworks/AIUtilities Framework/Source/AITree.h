//
//  AITree.h
//  AIUtilities.framework
//
//  Created by Mac-arena the Bored Zo on 2005-01-13.
//  Copyright 2004 The Adium Team. All rights reserved.
//

@interface AITree: NSObject
{
	CFTreeRef backing;
	CFTreeContext contextStorage; //used for -context
	NSMutableSet *childrenSet;
}

+ (id)treeWithContextObject:(id)obj;
+ (id)treeWithContextStructure:(CFTreeContext *)context;
+ (id)treeWithCFTree:(CFTreeRef)tree;
+ (id)treeWithCFTree:(CFTreeRef)CFTree createIfNecessary:(BOOL)flag;

- (id)init;
- (id)initWithContextObject:(id)obj;
- (id)initWithContextStructure:(CFTreeContext *)context;
- (id)initWithCFTree:(CFTreeRef)tree;

#pragma mark -
#pragma mark Managing context

- (id)contextObject;
- (CFTreeContext *)contextStructure;
- (void)getContextStructure:(out CFTreeContext *)outContext;
//this is the same as contextObject. it is included so that an AITree can be passed to, for example, -takeObjectValueFrom:.
- (id)objectValue;

- (void)setContextObject:(id)obj;
- (void)setContextStructure:(CFTreeContext *)context;

#pragma mark -
#pragma mark Parents

- (AITree *)root;
- (AITree *)rootCreatingAITreeIfNecessary:(BOOL)flag;
- (AITree *)parent;
- (AITree *)parentCreatingAITreeIfNecessary:(BOOL)flag;

#pragma mark -
#pragma mark Siblings

- (AITree *)nextSibling;
- (AITree *)nextSiblingCreatingAITreeIfNecessary:(BOOL)flag;
- (void)insertSibling:(AITree *)other;

- (void)remove;

#pragma mark -
#pragma mark Children

- (NSArray *)children;
//equivalent to [tree getChildren:children createAITreesIfNecessary:YES];
- (void)getChildren:(out AITree **)outChildren;
//if flag is NO, returns NO if not all of the CFTree's children have corresponding AITrees.
- (BOOL)getChildren:(out AITree **)outChildren createAITreesIfNecessary:(BOOL)flag;
- (void)getCFChildren:(out CFTreeRef *)outChildren;
- (AITree *)firstChild;
- (AITree *)firstChildCreatingAITreeIfNecessary:(BOOL)flag;

- (void)applyMethodToChildren:(SEL)selector withObject:(id)obj;
- (NSArray *)applyMethodToChildrenReturningObjects:(SEL)selector withObject:(id)obj;

- (unsigned)countChildren;
//equivalent to [tree childAtIndex:index createAITreeIfNecessary:YES];
- (AITree *)childAtIndex:(unsigned)index;
//if flag is NO, returns NO if that child of the CFTree does not have a corresponding AITree.
- (AITree *)childAtIndex:(unsigned)index createAITreeIfNecessary:(BOOL)flag;

- (void)prependChild:(AITree *)other;
- (void)removeAllChildren;

- (void)sortChildrenUsingCFComparator:(CFComparatorFunction)func context:(void *)context;

#pragma mark -
#pragma mark CFTree backing

- (CFTreeRef)cfTree;

@end
