/*
 * OmniWeb.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class OmniWebItem, OmniWebApplication, OmniWebColor, OmniWebDocument, OmniWebWindow, OmniWebAttributeRun, OmniWebCharacter, OmniWebParagraph, OmniWebText, OmniWebAttachment, OmniWebWord, OmniWebBookmark, OmniWebBookmarksDocument, OmniWebBrowser, OmniWebTab, OmniWebWorkspace, OmniWebPrintSettings;

enum OmniWebSavo {
	OmniWebSavoAsk = 'ask ' /* Ask the user whether or not to save the file. */,
	OmniWebSavoNo = 'no  ' /* Do not save the file. */,
	OmniWebSavoYes = 'yes ' /* Save the file. */
};
typedef enum OmniWebSavo OmniWebSavo;

enum OmniWebEnum {
	OmniWebEnumStandard = 'lwst' /* Standard PostScript error handling */,
	OmniWebEnumDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum OmniWebEnum OmniWebEnum;



/*
 * Standard Suite
 */

// A scriptable object.
@interface OmniWebItem : SBObject

@property (copy) NSDictionary *properties;  // All of the object's properties.

- (void) closeSaving:(OmniWebSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (NSArray *) GetWindowInfo;  // Given a window's numeric ID, returns a list containing its current URL and title string.
- (NSArray *) ListWindows;  // Returns a list of the numeric IDs of all open browser windows.
- (NSInteger) OpenURLFormData:(NSString *)FormData MIMEType:(NSString *)MIMEType to:(NSString *)to toWindow:(NSInteger)toWindow;  // Causes the web browser to display a specified URL.
- (NSString *) ParseAnchorWithURL:(NSString *)withURL;  // Parses a URL (possibly relative to a base URL) and returns the resulting URL as a string.
- (void) checkIncludingChildren:(BOOL)includingChildren;  // Tells a bookmark to check for updates of its resource.
- (void) doScriptLanguage:(NSString *)language window:(OmniWebBrowser *)window;  // Execute the text as a script.
- (void) flushCache;  // Flush all cached content.
- (void) GetURLTo:(NSString *)to;  // The Netscape way of displaying a URL in a window.
- (void) reload;  // Reload the contents of this browser from the server.
- (void) stop;  // Stop a browser.

@end

// An application's top level scripting object.
@interface OmniWebApplication : SBApplication

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *name;  // The name of the application.
@property (copy, readonly) NSString *version;  // The version of the application.

- (OmniWebDocument *) open:(NSURL *)x;  // Open an object.
- (void) print:(NSURL *)x printDialog:(BOOL)printDialog withProperties:(OmniWebPrintSettings *)withProperties;  // Print an object.
- (void) quitSaving:(OmniWebSavo)saving;  // Quit an application.

@end

// A color.
@interface OmniWebColor : OmniWebItem


@end

// A document.
@interface OmniWebDocument : OmniWebItem

@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy) NSString *name;  // The document's name.
@property (copy) NSString *path;  // The document's path.


@end

// A window.
@interface OmniWebWindow : OmniWebItem

@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (copy, readonly) OmniWebDocument *document;  // The document whose contents are being displayed in the window.
@property (readonly) BOOL floating;  // Whether the window floats.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property (readonly) BOOL miniaturizable;  // Whether the window can be miniaturized.
@property BOOL miniaturized;  // Whether the window is currently miniaturized.
@property (readonly) BOOL modal;  // Whether the window is the application's current modal window.
@property (copy) NSString *name;  // The full title of the window.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property (readonly) BOOL titled;  // Whether the window has a title bar.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.


@end



/*
 * Text Suite
 */

// This subdivides the text into chunks that all have the same attributes.
@interface OmniWebAttributeRun : OmniWebItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into characters.
@interface OmniWebCharacter : OmniWebItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// This subdivides the text into paragraphs.
@interface OmniWebParagraph : OmniWebItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// Rich (styled) text
@interface OmniWebText : OmniWebItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end

// Represents an inline text attachment.  This class is used mainly for make commands.
@interface OmniWebAttachment : OmniWebText

@property (copy) NSString *fileName;  // The path to the file for the attachment


@end

// This subdivides the text into words.
@interface OmniWebWord : OmniWebItem

- (SBElementArray *) attachments;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.


@end



/*
 * OmniWeb suite
 */

// OmniWeb's top-level object.
@interface OmniWebApplication (OmniWebSuite)

- (SBElementArray *) bookmarksDocuments;
- (SBElementArray *) browsers;
- (SBElementArray *) workspaces;

@property (copy) OmniWebWorkspace *activeWorkspace;  // the currently active workspace.
@property (copy, readonly) OmniWebBookmark *favorites;  // The bookmark item whose contents are displayed in the Favorites bar.
@property (copy, readonly) NSString *fullVersion;  // The complete version string for this instance of OmniWeb.
@property (copy, readonly) OmniWebBookmarksDocument *personalBookmarks;  // The default bookmarks document.

@end

// A bookmark or shortcut item.
@interface OmniWebBookmark : OmniWebItem

- (SBElementArray *) bookmarks;

@property (copy) NSString *address;  // the location to which this bookmark refers (a URL).
@property NSInteger checkInterval;  // how often this bookmark is automatically checked for changes, in seconds.
@property BOOL isNew;  // whether this page has been updated since it was last viewed.
@property BOOL isReachable;  // whether this page could be retrieved last time it was checked.
@property (copy, readonly) NSDate *lastCheckedDate;  // the date on which this bookmark was last retrieved.
@property (copy) NSString *name;  // the label text of this bookmark item.
@property (copy) NSString *note;  // the annotation text of this bookmark item.


@end

// A document containing a set of bookmarks.
@interface OmniWebBookmarksDocument : OmniWebDocument

- (SBElementArray *) bookmarks;

@property (copy, readonly) NSString *address;  // the URL at which these bookmarks are stored.
@property (readonly) BOOL isReadOnly;  // can the bookmarks in this document be modified?


@end

// A web browser window.
@interface OmniWebBrowser : OmniWebWindow

- (SBElementArray *) tabs;

@property (copy) OmniWebTab *activeTab;  // the tab currently being displayed in this browser.
@property (copy) NSString *address;  // the URL currently being displayed in this browser.
@property BOOL hasFavorites;  // whether the browser window displays the favorites shelf
@property BOOL hasTabs;  // whether the browser window displays the tabs drawer
@property BOOL hasToolbar;  // whether the browser window has a toolbar
@property (readonly) BOOL isBusy;  // whether the browser is currently working on its display.
@property BOOL showsAddress;  // whether the browser window always displays the address (URL) field


@end

// A tab within a browser window.
@interface OmniWebTab : OmniWebItem

@property (copy) NSString *address;  // the URL currently being displayed in this tab.
@property (readonly) BOOL isBusy;  // whether the tab is currently working on its display.
@property (copy, readonly) NSString *source;  // the source code for the current web page.
@property (copy, readonly) NSString *title;  // the title for the page currently being displayed in this tab.


@end

// A workspace.
@interface OmniWebWorkspace : OmniWebItem

- (SBElementArray *) browsers;

@property BOOL autosaves;  // whether the workspace saves its browser windows automatically
@property (copy) NSString *name;  // the workspace's name


@end



/*
 * Type Definitions
 */

@interface OmniWebPrintSettings : SBObject

@property NSInteger copies;  // the number of copies of a document to be printed
@property BOOL collating;  // Should printed copies be collated?
@property NSInteger startingPage;  // the first page of the document to be printed
@property NSInteger endingPage;  // the last page of the document to be printed
@property NSInteger pagesAcross;  // number of logical pages laid across a physical page
@property NSInteger pagesDown;  // number of logical pages laid out down a physical page
@property (copy) NSDate *requestedPrintTime;  // the time at which the desktop printer should print the document
@property OmniWebEnum errorHandling;  // how errors are handled
@property (copy) NSString *faxNumber;  // for fax number
@property (copy) NSString *targetPrinter;  // for target printer

- (void) closeSaving:(OmniWebSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (NSArray *) GetWindowInfo;  // Given a window's numeric ID, returns a list containing its current URL and title string.
- (NSArray *) ListWindows;  // Returns a list of the numeric IDs of all open browser windows.
- (NSInteger) OpenURLFormData:(NSString *)FormData MIMEType:(NSString *)MIMEType to:(NSString *)to toWindow:(NSInteger)toWindow;  // Causes the web browser to display a specified URL.
- (NSString *) ParseAnchorWithURL:(NSString *)withURL;  // Parses a URL (possibly relative to a base URL) and returns the resulting URL as a string.
- (void) checkIncludingChildren:(BOOL)includingChildren;  // Tells a bookmark to check for updates of its resource.
- (void) doScriptLanguage:(NSString *)language window:(OmniWebBrowser *)window;  // Execute the text as a script.
- (void) flushCache;  // Flush all cached content.
- (void) GetURLTo:(NSString *)to;  // The Netscape way of displaying a URL in a window.
- (void) reload;  // Reload the contents of this browser from the server.
- (void) stop;  // Stop a browser.

@end

