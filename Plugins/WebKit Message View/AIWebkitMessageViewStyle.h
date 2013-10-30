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


@class AIChat, AIContentObject;

/*!
 *	@brief Key used to retrieve the user's icon
 */
#define KEY_WEBKIT_USER_ICON 				@"webKitUserIconPath"

/*!
 *	@brief Key used to retrieve the default font family
 */
#define KEY_WEBKIT_DEFAULT_FONT_FAMILY		@"DefaultFontFamily"

/*!
 *	@brief Key used to retrieve the default font size
 */
#define KEY_WEBKIT_DEFAULT_FONT_SIZE		@"DefaultFontSize"

/*!
 *	@brief Key used to retrieve the mask for the user's icon
 */
#define KEY_WEBKIT_USER_ICON_MASK			@"ImageMask"

/*!
 *	@brief Different ways of formatting display names
 */
typedef enum {
	AIDefaultName = 0,
	AIDisplayName = 1,
	AIDisplayName_ScreenName = 2,
	AIScreenName_DisplayName = 3,
	AIScreenName = 4
} AINameFormat;

/*!
 *	@brief Different ways of displaying background images
 */
typedef enum {
	BackgroundNormal = 0,
	BackgroundCenter,
	BackgroundTile,
	BackgroundTileCenter,
	BackgroundScale
} AIWebkitBackgroundType;

@class ESFileTransfer;

/*!
 *	@class AIWebkitMessageViewStyle AIWebkitMessageViewStyle.h
 *	@brief Handles all interaction between the webkit message view controller and the message style, including creating the actual html strings to be appended
 *	@see AIWebKitMessageViewController
 */
@interface AIWebkitMessageViewStyle : NSObject {
	NSInteger			styleVersion;
	NSBundle			*__weak styleBundle;
	NSString			*stylePath;
	NSString			*__weak activeVariant;
	
	//Templates
	NSString			*headerHTML;
	NSString			*footerHTML;
	NSString			*baseHTML;
	NSString			*contentHTML;
	NSString			*contentInHTML;
	NSString			*nextContentInHTML;
	NSString			*contextInHTML;
	NSString			*nextContextInHTML;
	NSString			*contentOutHTML;
	NSString			*nextContentOutHTML;
	NSString			*contextOutHTML;
	NSString			*nextContextOutHTML;
	NSString			*statusHTML;
	NSString			*fileTransferHTML;
	NSString			*topicHTML;

	//Style settings
	BOOL				allowsCustomBackground;
	BOOL				transparentDefaultBackground;
	BOOL				allowsUserIcons;
	BOOL				usingCustomTemplateHTML;
	
	BOOL				checkedSenderColors;
	NSArray				*validSenderColors;

	//Behavior
	NSDateFormatter		*timeStampFormatter;
	AINameFormat		nameFormat;
	BOOL				useCustomNameFormat;
	BOOL				showUserIcons;
	BOOL				showHeader;
	BOOL				combineConsecutive;
	BOOL				allowTextBackgrounds;
	BOOL				allowsColors;
	BOOL				showIncomingFonts;
	BOOL				showIncomingColors;
	AIWebkitBackgroundType		customBackgroundType;
	NSString			*customBackgroundPath;
	NSColor			*__weak customBackgroundColor;
	NSImage			*userIconMask;

	NSMutableDictionary *statusIconPathCache;
	NSMutableDictionary	*timeFormatterCache;
}

/*!
 *	@brief Create a message view style instance for the passed style bundle
 */
+ (id)messageViewStyleFromBundle:(NSBundle *)inBundle;

/*!
 *	@brief Create a message view style instance by loading the bundle at the passed path
 *
 * @param path The path, which will be expanded to be bundle-relative via -[NSString(AIStringAdditions) stringByExpandingBundlePath] as needed
 */
+ (id)messageViewStyleFromPath:(NSString *)path;

/*!
 *	@brief The NSBundle for this style
 */
@property (weak, readonly, nonatomic) NSBundle *bundle;

/*!
 *  @brief Reloads the content of the style, useful for style authors and updates
 *
 *  @result YES if the style loaded succesfully; NO if an error (such as an incompatible style version) occurred.
 */
- (BOOL) reloadStyle;

/*!
 *  @brief The name of the active variant.
 *
 * This is only a store; if it is changed, the changing object is responsible for making
 * any appropriate calls to update the display
 */
@property (weak, nonatomic) NSString *activeVariant;

/*!
 *	Returns YES if this style is considered legacy
 *
 *	Legacy/outdated styles may perform sub-optimally because they lack beneficial changes made in modern styles.
 */
- (BOOL)isLegacy;

#pragma mark Templates
/*!
 *	@brief Returns the base template for this style
 *
 *	The base template is basically the empty view, and serves as the starting point of all content insertion.
 */
- (NSString *)baseTemplateForChat:(AIChat *)chat;

/*!
 *	@brief Returns the template for inserting content
 * 
 *	Templates may be different for different content types and for content objects similar to the one preceding them.
 */
- (NSString *)templateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar;

/*!
 * @brief Returns the template for the given content filled in with keywords substituted.
 */
- (NSString *)completedTemplateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar;

/*!
 *	@brief Returns the BOM script for appending content
 */
- (NSString *)scriptForAppendingContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects replaceLastContent:(BOOL)replaceLastContent;

/*!
 *	@brief Returns the BOM script for changing the view's variant to the active variant
 */
- (NSString *)scriptForChangingVariant;

/*!
 *	@brief Returns the BOM script for scrolling after adding multiple content objects
 *
 * Only applicable for styles which use the internal template
 */
- (NSString *)scriptForScrollingAfterAddingMultipleContentObjects;

#pragma mark Settings
/*!
 *	@brief Style supports custom backgrounds
 */
@property (readonly) BOOL allowsCustomBackground;

/*!
 *	@brief Style has a transparent background
 */
@property (readonly) BOOL isBackgroundTransparent;


/*!
 *	@brief Style's default font family
 */
- (NSString *)defaultFontFamily;


/*!
 *	@brief Style's default font size
 */
- (NSNumber *)defaultFontSize;

/*!
 *	@brief Style has a header
 */
@property (readonly, nonatomic) BOOL hasHeader;

/*!
 * @brief Style has a topic
 */
@property (readonly, nonatomic) BOOL hasTopic;

/*!
 *	@brief Style's user icon mask
 */
@property (readonly, nonatomic) NSImage *userIconMask;

/*!
 *	@brief Style supports user icons
 */
@property (readonly, nonatomic) BOOL allowsUserIcons;

/*!
 * @brief Style supports display of text colors
 */
@property (readonly, nonatomic) BOOL allowsColors;

/*!
 * @brief The style's sender colors
 */
@property (weak, readonly, nonatomic) NSArray *validSenderColors;

//Behavior
/*!
 *	@brief Set the format of dates/time stamps
 */
- (void ) setDateFormat:(NSString *)inDateFormat;

/*!
 *	@brief The visibility of user icons
 */
@property (readwrite, nonatomic) BOOL showUserIcons;

/*!
 *	@brief The visibility of the chat header
 */
@property (readwrite, nonatomic) BOOL showHeader;

/*!
 *	@brief Toggle use of a custom name format
 */
@property (readwrite, nonatomic) BOOL useCustomNameFormat;

/*!
 *	@brief The custom name format being used
 */
@property (readwrite, nonatomic) AINameFormat nameFormat;

/*!
 *	@brief The visibility of message background colors
 */
@property (readwrite, nonatomic) BOOL allowTextBackgrounds;

/*!
 *	@brief The path to the custom background image
 */
@property (readwrite, copy, nonatomic) NSString *customBackgroundPath;

/*!
 *	@brief Set the custom background image type (How it is displayed - stretched, tiled, centered, etc)
 */
@property (readwrite, nonatomic) AIWebkitBackgroundType customBackgroundType;

/*!
 *	@brief Set the custom background color
 */
@property (weak, readwrite, nonatomic) NSColor *customBackgroundColor;

/*!
 *	@brief Toggle visibility of received coloring
 */
@property (readwrite, nonatomic) BOOL showIncomingMessageColors;

/*!
 *	@brief Toggle visibility of received fonts
 */
@property (readwrite, nonatomic) BOOL showIncomingMessageFonts;

#pragma mark Variants
/*!
 *	@brief Returns an alphabetized array of available variant names for this style
 */
- (NSArray *)availableVariants;

/*!
 *	@brief Returns the file path to the css file defining a variant of this style
 */
- (NSString *)pathForVariant:(NSString *)variant;

/*!
 *	@brief Default variant for all style versions
 */
- (NSString *)defaultVariant;
+ (NSString *)defaultVariantForBundle:(NSBundle *)inBundle;

#pragma mark Keyword Substitution

/*!
 *	@brief Substitute content keywords
 *
 *	Substitute keywords in a template with the appropriate values for the passed content object
 *	We allow the message style to handle this since the behavior of keywords is dependent on the style and may change
 *	for future style versions
 */
- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar;

/*!
 *	@brief Substitute base keywords
 *
 * We allow the message style to handle this since the behavior of keywords is dependent on the style and may change
 * for future style versions
 */
- (NSMutableString *)fillKeywordsForBaseTemplate:(NSMutableString *)inString chat:(AIChat *)chat;
@end
