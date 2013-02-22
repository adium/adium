/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIContactInfoWindowController.h"
#import "AIContactInfoImageViewWithImagePicker.h"
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIModularPaneCategoryView.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListOutlineView.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIImageViewWithImagePicker.h>
#import <AIUtilities/AIOutlineViewAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AITabViewAdditions.h>
#import <QuartzCore/QuartzCore.h>

#define	CONTACT_INFO_NIB				@"ContactInfoInspector"			//Filename of the contact info nib
#define KEY_INFO_WINDOW_FRAME			@"Contact Info Inspector Frame"	//
#define KEY_INFO_SELECTED_CATEGORY		@"Selected Info Category"		//

#define	CONTACT_INFO_THEME				@"Contact Info List Theme"
#define	CONTACT_INFO_LAYOUT				@"Contact Info List Layout"

//Defines for the image files used by the toolbar segments
#define INFO_SEGMENT_IMAGE (@"get-info-profile.tiff")
#define ADDRESS_BOOK_SEGMENT_IMAGE (@"get-info-address-book.tiff")
#define EVENTS_SEGMENT_IMAGE (@"get-info-events.tiff")
#define ADVANCED_SEGMENT_IMAGE (@"get-info-advanced.tiff")

enum segments {
	CONTACT_INFO_SEGMENT = 0,
	CONTACT_ADDRESSBOOK_SEGMENT = 1,
	CONTACT_EVENTS_SEGMENT = 2,
	CONTACT_ADVANCED_SEGMENT = 3,
	CONTACT_PLUGINS_SEGMENT = 4
};

@interface AIContactInfoWindowController (PRIVATE)
- (void)configureForDisplayedObject;

-(void)segmentSelected:(id)sender animate:(BOOL)shouldAnimate;
- (void)selectionChanged:(NSNotification *)notification;
- (void)setupToolbarSegments;
- (void)configureToolbarForListObject:(AIListObject *)inObject;
- (void)contactInfoListControllerSelectionDidChangeToListObject:(AIListObject *)listObject;

//View Animation
-(void)addInspectorPanel:(NSInteger)newSegment animate:(BOOL)doAnimate;
-(void)animateViewIn:(NSView *)aView;
-(void)animateViewOut:(NSView *)aView;
@end

@interface NSWindow (FakeLeopardAdditions)
- (void)setAutorecalculatesContentBorderThickness:(BOOL)autorecalculateContentBorderThickness forEdge:(NSRectEdge)edge;
- (float)contentBorderThicknessForEdge:(NSRectEdge)edge;
- (void)setContentBorderThickness:(float)borderThickness forEdge:(NSRectEdge)edge;
@end

@implementation AIContactInfoWindowController

static AIContactInfoWindowController *sharedContactInfoInstance = nil;

- (IBAction)segmentSelected:(id)sender
{
	[self segmentSelected:sender animate:YES];
}

- (void)segmentSelected:(id)sender animate:(BOOL)shouldAnimate
{
	//Action method for the Segmented Control, which is actually the toolbar.
	NSInteger currentSegment = [sender selectedColumn];
	
	//Take focus away from any textual controls to ensure that they register changes and save
	if ([[[self window] firstResponder] isKindOfClass:[NSText class]]) {
		[[self window] makeFirstResponder:nil];
	}
	
	if(currentSegment != lastSegment) {
		[inspectorToolbar deselectAllCells];
	}
	
	[inspectorToolbar selectCellAtRow:0 column:currentSegment];
	[self addInspectorPanel:currentSegment animate:shouldAnimate];
}

//Return the shared contact info window
+ (AIContactInfoWindowController *)showInfoWindowForListObject:(AIListObject *)listObject
{
	//Create the window
	if (!sharedContactInfoInstance) {
		sharedContactInfoInstance = [[self alloc] initWithWindowNibName:CONTACT_INFO_NIB];
	}

	[sharedContactInfoInstance setDisplayedListObject:listObject];
	
	[[sharedContactInfoInstance window] makeKeyAndOrderFront:nil];

	return sharedContactInfoInstance;
}

//Close the info window
+ (void)closeInfoWindow
{
	if (sharedContactInfoInstance) {
		[sharedContactInfoInstance closeWindow:nil];
		[sharedContactInfoInstance release]; sharedContactInfoInstance = nil;
	}
}

- (void)dealloc
{
	AILogWithSignature(@"");
	deallocating = YES;

	[self setDisplayedListObject:nil];

	[displayedObject release]; displayedObject = nil;
	[loadedContent release]; loadedContent = nil;
	[contentController release]; contentController = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}


- (NSString *)adiumFrameAutosaveName
{
	return KEY_INFO_WINDOW_FRAME;
}

-(void)windowWillLoad
{
	[super windowWillLoad];
	
	//If we are on Leopard, we want our panel to have a finder-esque look.

	contentController = [[AIContactInfoContentController defaultInfoContentController] retain];

	if(!loadedContent) {
		//Load the content array from the content controller.
		loadedContent = [[contentController loadedPanes] retain];
	}
	
	//Monitor the selected contact
	[[NSNotificationCenter defaultCenter] addObserver:self
								   selector:@selector(selectionChanged:)
									   name:Interface_ContactSelectionChanged
									 object:nil];
}
	

//Setup the window before it is displayed
- (void)windowDidLoad
{
	[super windowDidLoad];

	//Localization
	[self setupToolbarSegments];
	
	currentPane = nil;
	lastSegment = 0;
	
	int	selectedSegment;
	
	//Select the previously selected category
	selectedSegment = [[[adium preferenceController] preferenceForKey:KEY_INFO_SELECTED_CATEGORY
																group:PREF_GROUP_WINDOW_POSITIONS] intValue];
	
	if (selectedSegment < 0 || selectedSegment > [inspectorToolbar numberOfColumns])
		selectedSegment = 0;

	[inspectorToolbar selectCellAtRow:0 column:selectedSegment];
	[self segmentSelected:inspectorToolbar];
}

- (void)windowWillClose:(NSNotification *)inNotification
{
	AILogWithSignature(@"");
		
	[[adium preferenceController] setPreference:[NSNumber numberWithInteger:[inspectorToolbar selectedColumn]]
										  forKey:KEY_INFO_SELECTED_CATEGORY
										   group:PREF_GROUP_WINDOW_POSITIONS];
	
	[sharedContactInfoInstance autorelease]; sharedContactInfoInstance = nil;

	[super windowWillClose:inNotification];
}

/*
    @method     setupToolbarSegments
    @abstract   setupToolbarSegments loads the localized tooltips and images for each toolbar segment
    @discussion Since we don't want to enumerate over all of the segments twice, we've combined the
	localization and image loading steps into this method.
*/
- (void)setupToolbarSegments
{	
	int i;
	for(i = 0; i < [inspectorToolbar numberOfColumns]; i++) {
		NSString	*segmentLabel = nil;
		NSImage		*segmentImage = nil;

		switch (i) {
			case CONTACT_INFO_SEGMENT:
				segmentLabel = AILocalizedString(@"Status and Profile","This segment displays the status and profile information for the selected contact.");
				segmentImage = [NSImage imageNamed:INFO_SEGMENT_IMAGE];
				break;
			case CONTACT_ADDRESSBOOK_SEGMENT:
				segmentLabel = AILocalizedString(@"Contact Information", "This segment displays contact and alias information for the selected contact.");
				segmentImage = [NSImage imageNamed:ADDRESS_BOOK_SEGMENT_IMAGE];
				break;
			case CONTACT_EVENTS_SEGMENT:
				segmentLabel = AILocalizedString(@"Events", "This segment displays controls for a user to set up events for this contact.");
				segmentImage = [NSImage imageNamed:EVENTS_SEGMENT_IMAGE];
				break;
			case CONTACT_ADVANCED_SEGMENT:
				segmentLabel = AILocalizedString(@"Advanced Settings","This segment displays the advanced settings for a contact, including encryption details and account information.");
				segmentImage = [NSImage imageNamed:ADVANCED_SEGMENT_IMAGE];
				break;
		}		
		
		[inspectorToolbar setToolTip:segmentLabel forCell:[inspectorToolbar cellAtRow:0 column:i]];
		
		[segmentImage setDataRetained:YES];
		[[inspectorToolbar cellAtRow:0 column:i] setImage:segmentImage];
	}	
}

//When the contact list selection changes, then configure the window for the new contact
- (void)selectionChanged:(NSNotification *)notification
{
	AIListObject	*object = [[adium interfaceController] selectedListObject];
	if (object) {
		[self setDisplayedListObject:object];
	}
}

- (void)setDisplayedListObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[AIListContact class]]) {
		inObject = [(AIListContact *)inObject parentContact];
	}
	
	if (inObject != displayedObject) {
		NSMutableDictionary *notificationUserInfo = [NSMutableDictionary dictionary];;
		if (displayedObject)
			[notificationUserInfo setObject:displayedObject
									 forKey:KEY_PREVIOUS_INSPECTED_OBJECT];
		if (inObject)
			[notificationUserInfo setObject:inObject
									 forKey:KEY_NEW_INSPECTED_OBJECT];
		[displayedObject release];

		displayedObject = [inObject retain];

		if (!deallocating) {
			//Ensure our window is loaded
			[self window];
			
			//Configure for the new object
			[self configureForDisplayedObject];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:AIContactInfoInspectorDidChangeInspectedObject
												  object:nil
												userInfo:notificationUserInfo];
	}
}

//Change the list object
- (void)configureForDisplayedObject
{	
	//Set the title of the window.
	if (displayedObject) {
		[[self window] setTitle:[NSString stringWithFormat:AILocalizedString(@"%@'s Info",nil), displayedObject.displayName]];
	} else {
		[[self window] setTitle:AILocalizedString(@"Contact Info",nil)];
	}
	
	//Configure each pane for this contact.
	for (id<AIContentInspectorPane> pane in loadedContent) {
		[pane updateForListObject:displayedObject];
	}
}

#pragma mark View Management and Animation
-(void)addInspectorPanel:(NSInteger)newSegment animate:(BOOL)doAnimate
{	
	NSView *newPane = [[loadedContent objectAtIndex:newSegment] inspectorContentView];
	
	if (currentPane == newPane) {
		return;
	}
	
	if (currentPane) {		
		// Remove the old pane		
		[self animateViewOut:currentPane];
		[currentPane removeFromSuperview];
	}
	
	lastSegment = newSegment;

	NSRect paneFrame = [newPane frame], contentBounds = [inspectorContent bounds];
    
    paneFrame.size.width = contentBounds.size.width;
    paneFrame.size.height = contentBounds.size.height;
        
    [newPane setFrame:paneFrame];
    
	[inspectorContent addSubview:newPane];
	
	currentPane = newPane;
	[self animateViewIn:currentPane];
}

-(void)animateViewIn:(NSView *)aView;
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	//Set View for animation
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
		
	//Set View to fade in.
	[animationDict setObject:NSViewAnimationFadeInEffect forKey:NSViewAnimationEffectKey];
	
	//Create the animation
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}

-(void)animateViewOut:(NSView *)aView;
{
	NSMutableDictionary *animationDict = [NSMutableDictionary dictionaryWithCapacity:3];
	
	//Set View for animation
	[animationDict setObject:aView forKey:NSViewAnimationTargetKey];
		
	//Set View to fade out.
	[animationDict setObject:NSViewAnimationFadeOutEffect forKey:NSViewAnimationEffectKey];
	
	//Create the animation
	NSViewAnimation *viewAnim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationDict, nil]];
	
	//Setup the animation
	[viewAnim setDuration:0.1];
	[viewAnim setAnimationCurve:NSAnimationEaseInOut];
	[viewAnim setAnimationBlockingMode:NSAnimationBlocking];
	
	//Start it
	[viewAnim startAnimation];
	
	[viewAnim release];
}



@end
