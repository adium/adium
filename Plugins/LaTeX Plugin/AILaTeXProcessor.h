//
//  AILaTeXProcessor.h
//  Adium
//
//  Created by Evan Schoenberg on 10/21/08.
//  Copyright 2008 Adium X. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AILaTeXProcessor : NSObject {
	NSMutableAttributedString *newMessage;
	NSAttributedString *originalAttributedString;
	id context;
	unsigned long long uniqueID;
	NSScanner *scanner;
	
	NSString *currentLaTeX;
	NSString *currentFileRoot;
	NSImage *currentImage;
	float currentScaleFactor;
}

+ (void)processString:(NSAttributedString *)inAttributedString context:(id)inContext uniqueID:(unsigned long long)inUniqueID;

@end
