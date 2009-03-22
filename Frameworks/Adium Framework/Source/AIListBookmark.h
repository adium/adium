//
//  AIListBookmark.h
//  Adium
//
//  Created by Chloe Haney on 19/07/07.
//

#import "AIListContact.h"

#define KEY_AUTO_JOIN			@"Automatically Join"
#define GROUP_LIST_BOOKMARK		@"List Bookmark Settings"

@class AIChat;

@interface AIListBookmark : AIListContact <NSCoding> {
	NSDictionary		*chatCreationDictionary;

	NSString			*password;
	NSString			*name;
}

- (id)initWithChat:(AIChat *)inChat;

@property (retain, nonatomic)	NSString *password;
@property (readonly, nonatomic)	NSString *name;
@property (readonly, nonatomic)	NSDictionary *chatCreationDictionary;

- (void)openChat;

@end
