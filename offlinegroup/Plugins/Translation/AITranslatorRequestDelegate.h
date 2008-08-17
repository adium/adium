//
//  AITranslatorRequestDelegate.h
//  Adium
//
//  Created by Evan Schoenberg on 3/12/06.
//


// States of search state machine
typedef enum {
	Translator_SearchForTextArea = 0,
	Translator_SearchForEndOfTag,
	Translator_SearchForTextAreaClose,
	Translator_SearchCompleted
} Translator_Step;

@interface AITranslatorRequestDelegate : NSObject {
	NSDictionary	*messageDict;
	id				target;
	NSMutableString	*response;
	NSRange			targetRange;

	Translator_Step	state;
}

+ (id)translatorRequestDelegateForDict:(NSDictionary *)inDict notifyingTarget:(id)inTarget;

@end
