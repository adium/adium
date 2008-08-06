//
//  AMPurpleJabberNode.h
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#include <libpurple/libpurple.h>

@class AMPurpleJabberNode;

@interface NSObject (AMPurpleJabberNodeDelegate)
- (void)jabberNodeGotItems:(AMPurpleJabberNode *)node;
- (void)jabberNodeGotInfo:(AMPurpleJabberNode *)node;
@end

@interface AMPurpleJabberNode : NSObject <NSCopying> {
    PurpleConnection *gc;
	
	NSString *jid;
	NSString *node;
	NSString *name;
	
	NSArray *items;
	NSSet *features;
	NSArray *identities;
	
	AMPurpleJabberNode *commands;
	
	NSMutableArray *delegates;
}

- (id)initWithJID:(NSString*)_jid node:(NSString*)_node name:(NSString*)_name connection:(PurpleConnection*)_gc;

- (void)fetchItems;
- (void)fetchInfo;

- (NSString*)name;
- (NSString*)jid;
- (NSString*)node;
- (NSArray*)items;
- (NSSet*)features;
- (NSArray*)identities;
- (NSArray*)commands;

- (void)addDelegate:(id)delegate;
- (void)removeDelegate:(id)delegate;

@end

