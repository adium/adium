//
//  AIPreviewChat.h
//  Adium
//
//  Created by Evan Schoenberg on 9/21/06.
//

#import <Adium/AIChat.h>

@interface AIPreviewChat : AIChat {

}

+ (AIPreviewChat *)previewChat;
- (void)setDateOpened:(NSDate *)inDate;

@end
