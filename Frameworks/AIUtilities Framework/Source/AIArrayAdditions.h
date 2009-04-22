//
//  AIArrayAdditions.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 2/15/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

@interface NSArray (AIArrayAdditions)
- (BOOL)containsObjectIdenticalTo:(id)obj;
+ (NSArray *)arrayNamed:(NSString *)name forClass:(Class)inClass;
- (NSComparisonResult)compare:(NSArray *)other;
- (BOOL)validateAsPropertyList;
@end

@interface NSMutableArray (ESArrayAdditions)
- (void)addObjectsFromArrayIgnoringDuplicates:(NSArray *)inArray;
- (void)moveObject:(id)object toIndex:(unsigned)newIndex;
- (void)setObject:(id)object atIndex:(unsigned)index;
@end
