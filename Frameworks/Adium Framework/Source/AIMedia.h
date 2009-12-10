//
//  AIMedia.h
//  Adium
//
//  Created by Zachary West on 2009-12-09.
//  Copyright 2009  . All rights reserved.
//

#import <Adium/AIMediaControllerProtocol.h>

@protocol AIAccount_Media;
@class AIListContact, AIAccount;

@interface AIMedia : NSObject {
	AIAccount <AIAccount_Media>	*account;
	AIListContact				*listContact;
	id							protocolInfo;
	
	CGFloat			sendProgress;
	CGFloat			receiveProgress;

	AIMediaType		mediaType;
	AIMediaState	mediaState;
}

@property (assign, nonatomic) id protocolInfo;

@property (readwrite, nonatomic) AIMediaType mediaType;
@property (readwrite, nonatomic) AIMediaState mediaState;
@property (readwrite, nonatomic) CGFloat sendProgress;
@property (readwrite, nonatomic) CGFloat receiveProgress;

@property (readwrite, retain, nonatomic) AIAccount <AIAccount_Media> *account;
@property (readwrite, retain, nonatomic) AIListContact *listContact;

+ (AIMedia *)mediaWithContact:(AIListContact *)inListContact
					onAccount:(AIAccount *)inAccount;

@end
