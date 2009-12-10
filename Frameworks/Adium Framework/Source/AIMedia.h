//
//  AIMedia.h
//  Adium
//
//  Created by Zachary West on 2009-12-09.
//  Copyright 2009  . All rights reserved.
//

#import <Adium/AIMediaControllerProtocol.h>

@class AIListContact, AIAccount;

@interface AIMedia : NSObject {
	AIAccount		*account;
	AIListContact	*listContact;
	id				protocolInfo;
	
	AIMediaState	mediaState;
}

@property (assign, nonatomic) id protocolInfo;

@property (readwrite, nonatomic) AIMediaState mediaState;
@property (readwrite, retain, nonatomic) AIAccount *account;
@property (readwrite, retain, nonatomic) AIListContact *listContact;

+ (AIMedia *)mediaWithContact:(AIListContact *)inListContact
					onAccount:(AIAccount *)inAccount;

@end
