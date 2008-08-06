//
//  AIListBookmark.h
//  Adium
//
//  Created by Chloe Haney on 19/07/07.
//

#import <AIListContact.h>
#import <AIAccount.h>
#import <AIListGroup.h>

@interface AIListBookmark : AIListContact <NSCoding> {
	NSDictionary *chatCreationDictionary;

	NSString			*password;
	NSString			*name;
}

- (id)initWithChat:(AIChat *)inChat;

- (NSString*)name;
- (NSDictionary*)chatCreationDictionary;

- (void)openChat;

@end
