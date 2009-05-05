//
//  AMPurpleJabberNode.h
//  Adium
//
//  Created by Evan Schoenberg on 9/5/07.
//

#import <libpurple/libpurple.h>

@class AMPurpleJabberNode;

@protocol AMPurpleJabberNodeDelegate <NSObject>
@optional
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

@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, copy, nonatomic) NSString *jid;
@property (readonly, copy, nonatomic) NSString *node;
@property (readonly, nonatomic) NSArray *items;
@property (readonly, retain, nonatomic) NSSet *features;
@property (readonly, retain, nonatomic) NSArray *identities;
@property (readonly, nonatomic) NSArray *commands;

- (void)addDelegate:(id<AMPurpleJabberNodeDelegate>)delegate;
- (void)removeDelegate:(id<AMPurpleJabberNodeDelegate>)delegate;

@end

