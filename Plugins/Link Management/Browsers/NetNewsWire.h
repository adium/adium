/*
 * NetNewsWire.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class NetNewsWireItem, NetNewsWireApplication, NetNewsWireColor, NetNewsWireDocument, NetNewsWireWindow, NetNewsWireAttributeRun, NetNewsWireCharacter, NetNewsWireParagraph, NetNewsWireText, NetNewsWireAttachment, NetNewsWireWord, NetNewsWireHeadline, NetNewsWireSubscription, NetNewsWirePrintSettings;

enum NetNewsWireSavo {
	NetNewsWireSavoAsk = 'ask ' /* Ask the user whether or not to save the file. */,
	NetNewsWireSavoNo = 'no  ' /* Do not save the file. */,
	NetNewsWireSavoYes = 'yes ' /* Save the file. */
};
typedef enum NetNewsWireSavo NetNewsWireSavo;

enum NetNewsWireExTF {
	NetNewsWireExTFHTML = 'HTML',
	NetNewsWireExTFOPML = 'OPML',
	NetNewsWireExTFPlainText = 'TEXT'
};
typedef enum NetNewsWireExTF NetNewsWireExTF;

enum NetNewsWireEnum {
	NetNewsWireEnumStandard = 'lwst' /* Standard PostScript error handling */,
	NetNewsWireEnumDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum NetNewsWireEnum NetNewsWireEnum;



/*
 * Standard Suite
 */

// A scriptable object.
@interface NetNewsWireItem : SBObject

@property (copy) NSDictionary *properties;  // All of the object's properties.

- (void) closeSaving:(NetNewsWireSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (id) doJavaScript;  // Applies a string of JavaScript code to a document.
- (void) exportSubscriptionsToFile:(NSString *)toFile includingGroups:(BOOL)includingGroups;  // Export subscriptions as an OPML file to disk, either flat or with groups intact.
- (void) exportTabsAs:(NetNewsWireExTF)as toFile:(NSString *)toFile;  // Export tabs to a file on disk.
- (void) loadUnloadedTabs;  // Load unloaded tabs -- that is, load the web pages for tabs that were remembered from the previous run.
- (void) openInBrowser;  // Open the object in the default Web browser.
- (void) openURLInNewTabWith:(NSString *)with;  // Opens a URL in a new tab. It may open the URL in your default browser instead, if it's of a type NetNewsWire can't or shouldn't handle.
- (void) refresh;  // Refresh a subscription. If a group, its children are refreshed. (It's the equivalent of clicking the Refresh button.)
- (void) refreshAll;  // Refresh all subscriptions -- the equivalent of clicking the Refresh All button. It is treated like a manual refresh-all.
- (BOOL) subscribeTo:(NSString *)to;  // Subscribe with the URL of an RSS feed.
- (void) unsubscribe;  // Unsubscribe from a subscription.

@end

// An application's top level scripting object.
@interface NetNewsWireApplication : SBApplication

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *name;  // The name of the application.
@property (copy, readonly) NSString *version;  // The version of the application.

- (NetNewsWireDocument *) open:(NSURL *)x;  // Open an object.
- (void) print:(NSURL *)x printDialog:(BOOL)printDialog withProperties:(NetNewsWirePrintSettings *)withProperties;  // Print an object.
- (void) quitSaving:(NetNewsWireSavo)saving;  // Quit an application.

@end

// A color.
@interface NetNewsWireColor : NetNewsWireItem


@end

// A document.
@interface NetNewsWireDocument : NetNewsWireItem

@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy) NSString *name;  // The document's name.
@property (copy) NSString *path;  // The document's path.


@end

// A window.
@interface NetNewsWireWindow : NetNewsWireItem

@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (copy, readonly) NetNewsWireDocument *document;  // The document whose contents are being displayed in the window.
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
@interface NetNewsWireAttributeRun : NetNewsWireItem

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
@interface NetNewsWireCharacter : NetNewsWireItem

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
@interface NetNewsWireParagraph : NetNewsWireItem

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
@interface NetNewsWireText : NetNewsWireItem

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
@interface NetNewsWireAttachment : NetNewsWireText

@property (copy) NSString *fileName;  // The path to the file for the attachment


@end

// This subdivides the text into words.
@interface NetNewsWireWord : NetNewsWireItem

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
 * NetNewsWire suite
 */

// NetNewsWire's top level scripting object.
@interface NetNewsWireApplication (NetNewsWireSuite)

- (SBElementArray *) subscriptions;

@property NSInteger indexOfSelectedTab;  // The news items tab is 0, and web page tabs start with 1.
@property (readonly) NSInteger numberOfTabs;  // The number of tabs, including the news items tab.
@property (copy, readonly) NetNewsWireHeadline *selectedHeadline;  // The current selected headline.
@property (copy, readonly) NetNewsWireSubscription *selectedSubscription;  // The current subscription.
@property (copy, readonly) NSArray *titlesOfTabs;  // A list of the titles of tabs, including the news items tab.
@property (readonly) NSInteger totalUnreadCount;  // The total number of unread items for all subscriptions.
@property (copy, readonly) NSArray *URLsOfTabs;  // A list of the URLs of tabs. The first one -- the news items tab -- is always an empty string.

@end

// A single item from a feed.
@interface NetNewsWireHeadline : NetNewsWireItem

@property (copy, readonly) NSString *commentsURL;  // URL of the comments page for this headline.
@property (copy, readonly) NSString *creator;  // The creator of this headline.
@property (copy, readonly) NSDate *dateArrived;  // The date this headline first appeared in NetNewsWire.
@property (copy, readonly) NSDate *datePublished;  // The date this headline was published.
@property (copy, readonly) NSString *objectDescription;  // The description (body) of the headline.
@property (readonly) NSInteger enclosureLength;  // The length in bytes of this item’s enclosure.
@property (copy, readonly) NSString *enclosureType;  // The MIME type of this item‘s enclosure.
@property (copy, readonly) NSString *enclosureURL;  // The URL of the enclosure for this item.
@property (copy, readonly) NSString *guid;  // The guid for this headline (as guid is defined by the various syndication specs).
@property (readonly) BOOL isFake;  // Obsolete. It used to say whether or not this is a fake headline (such as a headline that says "No selection"). But now it always returns false (there are no fake headlines).
@property BOOL isFlagged;  // Has the item been flagged by the user?
@property BOOL isFollowed;  // Has the item been opened in the web browser?
@property BOOL isRead;  // Has the item been read in NetNewsWire?
@property (copy, readonly) NSString *permalink;  // The permalink for this item as it appears in the feed.
@property (readonly) NSInteger sessionID;  // The unique ID of this headline for the current session.
@property (copy, readonly) NSString *subject;  // The subject of a headline, as specified in the RSS source.
@property (copy, readonly) NetNewsWireSubscription *subscription;  // The subscription that contains this headline.
@property (copy, readonly) NSString *summary;  // The summary for this item as it appears in the feed.
@property (copy, readonly) NSString *title;  // The title of the headline.
@property (copy, readonly) NSString *URL;  // The URL included with the headline.


@end

// A feed, group, or other type of subscription.
@interface NetNewsWireSubscription : NetNewsWireItem

- (SBElementArray *) headlines;
- (SBElementArray *) subscriptions;

@property (readonly) NSInteger calculatedAttentionScore;  // The calculated attention score for this subscription, based on clicks and actions (such as posting to weblog, posting to Delicious, etc.). For groups it is the average of the subscription inside the group. For smart lists it only counts current items, not
@property (copy) NSString *displayName;  // The name displayed for this subscription.
@property (copy, readonly) NSString *errorString;  // The string of the last download or parsing error.
@property (copy, readonly) NSString *ETagHeader;  // The ETag header last returned by the server.
@property (copy, readonly) NSString *givenDescription;  // The description of the subscription.
@property (copy, readonly) NSString *givenName;  // The given name of the subscription.
@property (copy, readonly) NetNewsWireSubscription *group;  // The group that contains this subscription.
@property (readonly) NSInteger headlinesCount;  // The number of headlines contained by this subscription.
@property (copy) NSString *homeURL;  // The URL of the home page of this subscription.
@property (copy, readonly) NSString *iconURL;  // The URL of the icon (if there is one).
@property (readonly) BOOL inGroup;  // Is this subscription contained by a group?
@property (readonly) BOOL isGroup;  // Is this subscription a group that contains other subscriptions?
@property (copy, readonly) NSDate *lastCheckTime;  // The last time the subscription was checked for new headlines.
@property (copy, readonly) NSDate *lastUpdateTime;  // The last time the source had new headlines
@property (copy, readonly) NSString *lastModifiedHeader;  // The last last-modified header returned by the server.
@property (readonly) NSInteger numberOfChecks;  // The number of times this subscription has been checked during the current session.
@property (readonly) NSInteger numberOfChildren;  // The number of subscriptions a group contains.
@property (readonly) NSInteger numberOfContentBytes;  // The number of content bytes downloaded during the current session.
@property (readonly) NSInteger numberOfNotModifiedResponses;  // The number of times a 304 Not Modified was returned during the current session.
@property (readonly) NSInteger numberOfOKResponses;  // The number of 200 OK responses returned during the current session.
@property (copy) NSString *RSSURL;  // The URL of the RSS feed for this subscription.
@property NSInteger scriptedAttentionScore;  // To affect the calculated attention score, you can change the scripted attention score. The scripted attention score is a component of the calculated attention score (it's added).
@property (readonly) NSInteger sessionID;  // The ID for this subscription for the current session.
@property (readonly) BOOL synthetic;  // Is this subscription a synthetic subscription? (In other words, a group or other artificial feed?)
@property (readonly) NSInteger unreadCount;  // The number of unread headlines.
@property (copy, readonly) NSString *XMLText;  // The raw XML text downloaded for this subscription.


@end



/*
 * Type Definitions
 */

@interface NetNewsWirePrintSettings : SBObject

@property NSInteger copies;  // the number of copies of a document to be printed
@property BOOL collating;  // Should printed copies be collated?
@property NSInteger startingPage;  // the first page of the document to be printed
@property NSInteger endingPage;  // the last page of the document to be printed
@property NSInteger pagesAcross;  // number of logical pages laid across a physical page
@property NSInteger pagesDown;  // number of logical pages laid out down a physical page
@property (copy) NSDate *requestedPrintTime;  // the time at which the desktop printer should print the document
@property NetNewsWireEnum errorHandling;  // how errors are handled
@property (copy) NSString *faxNumber;  // for fax number
@property (copy) NSString *targetPrinter;  // for target printer

- (void) closeSaving:(NetNewsWireSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveAs:(NSString *)as in:(NSURL *)in_;  // Save an object.
- (id) doJavaScript;  // Applies a string of JavaScript code to a document.
- (void) exportSubscriptionsToFile:(NSString *)toFile includingGroups:(BOOL)includingGroups;  // Export subscriptions as an OPML file to disk, either flat or with groups intact.
- (void) exportTabsAs:(NetNewsWireExTF)as toFile:(NSString *)toFile;  // Export tabs to a file on disk.
- (void) loadUnloadedTabs;  // Load unloaded tabs -- that is, load the web pages for tabs that were remembered from the previous run.
- (void) openInBrowser;  // Open the object in the default Web browser.
- (void) openURLInNewTabWith:(NSString *)with;  // Opens a URL in a new tab. It may open the URL in your default browser instead, if it's of a type NetNewsWire can't or shouldn't handle.
- (void) refresh;  // Refresh a subscription. If a group, its children are refreshed. (It's the equivalent of clicking the Refresh button.)
- (void) refreshAll;  // Refresh all subscriptions -- the equivalent of clicking the Refresh All button. It is treated like a manual refresh-all.
- (BOOL) subscribeTo:(NSString *)to;  // Subscribe with the URL of an RSS feed.
- (void) unsubscribe;  // Unsubscribe from a subscription.

@end

