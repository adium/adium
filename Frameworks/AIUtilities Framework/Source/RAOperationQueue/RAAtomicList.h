//
//  RAAtomicList.h
//  AudioHijackKit2
//
//  Created by Michael Ash on 11/9/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

// thread safe linked list utilities
// a NULL list is considered empty
typedef struct RAAtomicListNode *RAAtomicListRef;


// thread safe functions: may be called on a shared list from multiple threads with no locking
void RAAtomicListInsert( RAAtomicListRef *listPtr, void *elt );
RAAtomicListRef RAAtomicListSteal( RAAtomicListRef *listPtr );

// thread unsafe functions: must be called only on lists which other threads cannot access
void RAAtomicListReverse( RAAtomicListRef *listPtr );
void *RAAtomicListPop( RAAtomicListRef *listPtr); // returns NULL on empty list

