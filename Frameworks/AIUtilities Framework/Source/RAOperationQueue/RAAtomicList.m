//
//  RAAtomicList.m
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/9/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "RAAtomicList.h"

#import <libkern/OSAtomic.h>


struct RAAtomicListNode
{
	struct RAAtomicListNode *next;
	void *elt;
};

void RAAtomicListInsert( RAAtomicListRef *listPtr, void *elt )
{
	struct RAAtomicListNode *node = malloc( sizeof( *node ) );
	node->elt = elt;
	
	do {
		node->next = *listPtr;
	} while( !OSAtomicCompareAndSwapPtrBarrier( node->next, node, (void **)listPtr ) );
}

RAAtomicListRef RAAtomicListSteal( RAAtomicListRef *listPtr )
{
	RAAtomicListRef ret;
	do {
		ret = *listPtr;
	} while( !OSAtomicCompareAndSwapPtrBarrier( ret, NULL, (void **)listPtr ) );
	return ret;
}

void RAAtomicListReverse( RAAtomicListRef *listPtr )
{
	struct RAAtomicListNode *cur = *listPtr;
	struct RAAtomicListNode *prev = NULL;
	struct RAAtomicListNode *next = NULL;
	
	if( !cur )
		return;
	
	do {
		next = cur->next;
		cur->next = prev;
		
		if( next )
		{
			prev = cur;
			cur = next;
		}
	} while( next );
	
	*listPtr = cur;
}

void *RAAtomicListPop( RAAtomicListRef *listPtr)
{
	struct RAAtomicListNode *node = *listPtr;
	if( !node )
		return NULL;
	
	*listPtr = node->next;
	
	void *elt = node->elt;
	free( node );
	return elt;
}

