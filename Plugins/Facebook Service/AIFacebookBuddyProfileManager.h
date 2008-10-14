//
//  AIFacebookBuddyProfileManager.h
//  Adium
//
//  Created by Evan Schoenberg on 10/14/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AIListContact;

@interface AIFacebookBuddyProfileManager : NSObject {

}

+ (void)retrieveProfileForContact:(AIListContact *)contact;

@end
