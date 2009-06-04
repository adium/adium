//
//  AIContactInfoWindowPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on 7/27/06.
//


@interface AIContactInfoWindowPlugin : AIPlugin {
	//Contact Info Menu Items
	NSMenuItem				*menuItem_getInfo;
	NSMenuItem				*menuItem_getInfoAlternate;
	NSMenuItem				*menuItem_getInfoContextualContact;
	NSMenuItem				*menuItem_getInfoContextualGroupChat;
	NSMenuItem				*menuItem_getInfoContextualGroup;	
	NSMenuItem				*menuItem_getInfoWithPrompt;
}

@end
