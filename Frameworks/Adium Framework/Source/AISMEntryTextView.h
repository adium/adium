//
//  AISMEntryTextView.h
//  Adium
//
//  Created by Adam Iser on Wed Nov 20 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AIUtilities/AIUtilities.h>

@class AIContactHandle, AISendingTextView, AIAdium;
@protocol AITextEntryView;

@interface AISMEntryTextView : AISendingTextView <AITextEntryView> {
    AIAdium		*owner;
    AIContactHandle	*handle;
}

+ (id)messageEntryTextViewForHandle:(AIContactHandle *)inHandle owner:(id)inOwner;

@end
