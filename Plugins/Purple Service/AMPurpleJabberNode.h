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
	
	NSString *infoIqId;
	NSString *discoIqId;
	
	NSArray *__weak items;
	NSSet *__weak features;
	NSArray *__weak identities;
	
	AMPurpleJabberNode *commands;
	
	NSMutableArray *delegates;
}

- (id)initWithJID:(NSString*)_jid node:(NSString*)_node name:(NSString*)_name connection:(PurpleConnection*)_gc;

- (void)fetchItems;
- (void)fetchInfo;

@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, copy, nonatomic) NSString *jid;
@property (readonly, copy, nonatomic) NSString *node;
@property (weak, readonly, nonatomic) NSArray *items;
@property (weak, readonly, nonatomic) NSSet *features;
@property (weak, readonly, nonatomic) NSArray *identities;
@property (weak, readonly, nonatomic) NSArray *commands;
@property (copy, nonatomic) NSString *infoIqId;
@property (copy, nonatomic) NSString *discoIqId;

- (void)addDelegate:(id<AMPurpleJabberNodeDelegate>)delegate;
- (void)removeDelegate:(id<AMPurpleJabberNodeDelegate>)delegate;

@end

