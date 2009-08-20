//
//  AISMEntryTextView.m
//  Adium
//
//  Created by Adam Iser on Wed Nov 20 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AISMEntryTextView.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@interface AISMEntryTextView (PRIVATE)
- (id)initForHandle:(AIContactHandle *)inHandle owner:(id)inOwner;
- (void)postSendNotification:(NSNotification *)notification;
- (void)didSendEnteredMessage:(NSNotification *)notification;
@end

@implementation AISMEntryTextView

+ (id)messageEntryTextViewForHandle:(AIContactHandle *)inHandle owner:(id)inOwner
{
    return [[[self alloc] initForHandle:inHandle owner:inOwner] autorelease];
}

// Required protocol methods ---
- (NSAttributedString *)attributedString
{
    return [self textStorage];
}

- (void)setAttributedString:(NSAttributedString *)inAttributedString
{
    [[self textStorage] setAttributedString:inAttributedString];
}

//Handled automatically by our superclasses:
- (void)setSelectedRange:(NSRange)inRange{
    [super setSelectedRange:inRange];
}
- (NSRange)selectedRange{
    return [super selectedRange];
}
- (void)setSelectedTextAttributes:(NSDictionary *)attributeDictionary{
    [super setSelectedTextAttributes:attributeDictionary];
}
- (NSDictionary *)selectedTextAttributes{
    return [super selectedTextAttributes];
}



// Private ------------------------------------------------------------------
- (id)initForHandle:(AIContactHandle *)inHandle owner:(id)inOwner
{
    [super init];

    owner = [inOwner retain];
    handle = [inHandle retain];

    //Configure our view
    [self setAutoresizingMask:(NSViewWidthSizable)];
    [self setTarget:self action:@selector(postSendNotification:)];
    [self setSendOnEnter:[[[owner preferenceController] preferenceForKey:@"message_send_onEnter" group:PREF_GROUP_GENERAL handle:handle] boolValue]];
    [self setSendOnReturn:[[[owner preferenceController] preferenceForKey:@"message_send_onReturn" group:PREF_GROUP_GENERAL handle:handle] boolValue]];

    //Register for notifications
    [[[owner interfaceController] interfaceNotificationCenter] addObserver:self selector:@selector(didSendEnteredMessage:) name:Interface_DidSendEnteredMessage object:handle];

    return self;
}

//Send the entered message
- (void)postSendNotification:(NSNotification *)notification
{
    [[[owner interfaceController] interfaceNotificationCenter] postNotificationName:Interface_SendEnteredMessage object:handle userInfo:nil];
}

//Called after a message is sent, removes the message from this text view
- (void)didSendEnteredMessage:(NSNotification *)notification
{
    //Clear the text view
    [self setString:@""];
}

@end
