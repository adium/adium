//
//  AXCIconPackEntry.h
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

@interface AXCIconPackEntry : NSObject {
	NSString *key, *path;
}

+ (id) entryWithKey:(NSString *)newKey path:(NSString *)newPath;
- (id) initWithKey:(NSString *)newKey path:(NSString *)newPath;

- (NSString *) key;

- (NSString *) path;
- (void) setPath:(NSString *)newPath;

@end
