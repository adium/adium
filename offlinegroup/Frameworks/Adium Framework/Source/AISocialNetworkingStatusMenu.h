//
//  AISocialNetworkingStatusMenu.h
//  Adium
//
//  Created by Evan Schoenberg on 6/7/08.
//  Copyright 2008 Adium X. All rights reserved.
//


@class AIAccount;

@interface AISocialNetworkingStatusMenu : NSObject {

}

+ (NSMenuItem *)socialNetworkingSubmenuItem;
+ (NSMenu *)socialNetworkingSubmenuForAccount:(AIAccount *)inAccount;

@end
