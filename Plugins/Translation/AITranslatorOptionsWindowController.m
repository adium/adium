//
//  AITranslatorOptionsWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 3/13/06.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "AITranslatorOptionsWindowController.h"
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringUtilities.h> 
#import <Adium/AILocalizationAssistance.h>
#import <AIUtilities/AIPopUpButtonAdditions.h>
#import "AIPreferenceController.h"

@interface AITranslatorOptionsWindowController (PRIVATE)
- (void)configureForListObject:(AIListObject *)listObject;
@end

@implementation AITranslatorOptionsWindowController

static AITranslatorOptionsWindowController *sharedWindowController = nil;

+ (void)showOptionsForListObject:(AIListObject *)listObject
{
	//Create the window
	if (!sharedWindowController) {
		sharedWindowController = [[self alloc] initWithWindowNibName:@"TranslatorOptions"];
	}

	//Configure and show window
	if ([listObject isKindOfClass:[AIListContact class]]) {
		AIListContact *parentContact = [(AIListContact *)listObject parentContact];
		
		/* Use the parent contact if it is a valid meta contact which contains contacts
		 * If this contact is within a metacontact but not currently listed on any buddy list, we don't want to 
		 * display the effectively-invisible metacontact's info but rather the info of this contact itself.
		 */
		if (![parentContact isKindOfClass:[AIMetaContact class]] ||
			[[(AIMetaContact *)parentContact listContacts] count]) {
			listObject = parentContact;
		}
	}
	
	//Load the window
	[sharedWindowController window];
	[sharedWindowController configureForListObject:listObject];
	[[sharedWindowController window] makeKeyAndOrderFront:nil];
}

- (NSMenu *)languageMenu
{
	NSMenu *languageMenu = [[NSMenu alloc] init];
	
	NSDictionary *translationDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"English",	@"en",
			@"Spanish",	@"es",
			@"French",	@"fr",
			@"German",	@"de",
			@"Portuguese (Brazilian)",	@"pt",
			@"Italian",	@"it",
			@"Dutch",	@"nl",
			@"Greek",@"el",
			@"Russian",	@"ru",
			@"Japanese",	@"ja",
			@"Chinese (Simplified)",	@"zh_cn",
			@"Chinese (Traditional)",		@"zh_tw",
			@"Korean",	@"ko",
			nil];
	NSEnumerator *enumerator;
	NSString	 *langCode;
	
	enumerator = [translationDict keyEnumerator];
	while ((langCode = [enumerator nextObject])) {
		NSMenuItem *menuItem;
		menuItem = [[NSMenuItem alloc] initWithTitle:[translationDict objectForKey:langCode]
											  target:nil
											  action:nil
									   keyEquivalent:@""];
		[menuItem setRepresentedObject:langCode];
		[languageMenu addItem:menuItem];
		[menuItem release];
	}
	[translationDict release];

	return [languageMenu autorelease];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	NSMenu	*languageMenu = [self languageMenu];
	[popUp_sourceLanguage setMenu:languageMenu];
	[popUp_destinationLanguage setMenu:[[languageMenu copy] autorelease]];
}

- (void)configureForListObject:(AIListObject *)listObject
{
	if (listObject != currentListObject) {
		[currentListObject release];
		currentListObject = [listObject retain];
		
		[popUp_sourceLanguage selectItemWithRepresentedObject:[currentListObject preferenceForKey:@"LanguageToContact"
																							group:@"Translator"]];
		[popUp_destinationLanguage selectItemWithRepresentedObject:[currentListObject preferenceForKey:@"LanguageFromContact"
																							group:@"Translator"]];
		
		[textField_header setLocalizedString:[NSString stringWithFormat:AILocalizedString(@"When talking to %@", nil), [currentListObject displayName]]];
//		[textField_sourceLanguage setLocalizedString:AILocalizedString(@"I speak:", nil)];
//		[textField_destinationLanguage setLocalizedString:[NSString stringWithFormat:AILocalizedString(@"%@ speaks:", nil), [currentListObject displayName]]];
	}
}

- (void)dealloc
{
	[currentListObject release];
	
	[super dealloc];
}

- (IBAction)selectLanguage:(id)sender
{
	NSString	*key;
	if (sender == popUp_sourceLanguage) {
		key = @"LanguageToContact";
	} else {
		key = @"LanguageFromContact";		
	}

	[currentListObject setPreference:[[sender selectedItem] representedObject]
							  forKey:key
							   group:@"Translator"];
}

@end
