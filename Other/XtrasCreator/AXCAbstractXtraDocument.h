//
//  AXCAbstractXtraDocument.h
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//

@protocol ViewController;

@interface AXCAbstractXtraDocument : NSDocument
{
	NSBundle *bundle;
	NSString *name, *author, *version, *bundleID;
	NSAttributedString *readme;
	NSMutableArray * resources;
	NSMutableSet * resourcesSet;
	NSImage * icon;

	NSMutableDictionary *imagePreviews; //keys: paths to image files; values: NSImages
	NSMutableDictionary *displayNames; //keys: paths to files; values: display names (for an image, includes ' (WxH)' suffix)

	IBOutlet NSTabView * tabs;
	IBOutlet NSTableView * fileView;
	IBOutlet NSTextView * readmeView;

	int lastDrag;
	NSDragOperation lastDragOperation;
}

#pragma mark Actions

- (IBAction) runAddFilesPanel:(id)sender;
- (IBAction) runChooseIconPanel:(id)sender;

#pragma mark Resources

//mainly intended for subclasses.
- (void) addResource:(NSString *)path;
- (void) addResources:(NSArray *)paths;
- (void) removeResource:(NSString *)path;
- (void) removeResources:(NSArray *)paths;
- (void) setResources:(NSArray *)newResources;

#pragma mark Accessors

- (void) setName:(NSString *)newName;
- (NSString *) name;

- (void) setAuthor:(NSString *)newAuthor;
- (NSString *) author;

- (void) setVersion:(NSString *)newVersion;
- (NSString *) version;

- (void) setBundleID:(NSString *)newBundleID;
- (NSString *) bundleID;

- (void) setReadme:(NSAttributedString *)newReadme;
- (NSAttributedString *) readme;

- (void) setIcon:(NSImage *)icon;
- (NSImage *) icon;

#pragma mark For subclasses

//all three of these are used for new documents. for an existing document, these will not be called.
- (NSString *) OSType;
- (NSString *) pathExtension;
- (NSString *) uniformTypeIdentifier;

//types of files that can be added as resources via the 'Add Files...' button, or via drag-and-drop.
//if nil, all types are valid.
- (NSArray *) validResourceTypes;

/*override this method if you want to add items to the dictionary that will be written out to Info.plist
 *when the document is saved.
 *
 *you need to call [super infoPlistDictionary], and work from the return value of that.
 */
- (NSDictionary *) infoPlistDictionary;

//added to the tab view.
- (NSArray *) tabViewItems;

@end
