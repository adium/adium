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

#import "AIWebkitMessageViewStyle.h"
#import <AIUtilities/AIColorAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIDateFormatterAdditions.h>
#import <AIUtilities/AIMutableStringAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIGroupChat.h>
#import <Adium/AIContentTopic.h>
#import <Adium/AIContentContext.h>
#import <Adium/AIContentNotification.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusIcons.h>

//
#define LEGACY_VERSION_THRESHOLD		3	//Styles older than this version are considered legacy
#define MAX_KNOWN_WEBKIT_VERSION        4   //Styles newer than this version are unknown entities

//
#define KEY_WEBKIT_VERSION				@"MessageViewVersion"
#define KEY_WEBKIT_VERSION_MIN			@"MessageViewVersion_MinimumCompatible"

//BOM scripts for appending content.
#define APPEND_MESSAGE_WITH_SCROLL		@"checkIfScrollToBottomIsNeeded(); appendMessage(\"%@\"); scrollToBottomIfNeeded();"
#define APPEND_NEXT_MESSAGE_WITH_SCROLL	@"checkIfScrollToBottomIsNeeded(); appendNextMessage(\"%@\"); scrollToBottomIfNeeded();"
#define APPEND_MESSAGE					@"appendMessage(\"%@\");"
#define APPEND_NEXT_MESSAGE				@"appendNextMessage(\"%@\");"
#define APPEND_MESSAGE_NO_SCROLL		@"appendMessageNoScroll(\"%@\");"
#define	APPEND_NEXT_MESSAGE_NO_SCROLL	@"appendNextMessageNoScroll(\"%@\");"
#define REPLACE_LAST_MESSAGE			@"replaceLastMessage(\"%@\");"

#define TOPIC_MAIN_DIV					@"<div id=\"topic\"></div>"
// We set back, when the user finishes editing, the correct topic, which wipes out the existance of the span before. We don't need to undo the dbl click action.
#define TOPIC_INDIVIDUAL_WRAPPER		@"<span id=\"topicEdit\" ondblclick=\"this.setAttribute('contentEditable', true); this.focus();\">%@</span>"

@interface NSString (NewSnowLeopardMethods)
- (NSComparisonResult)localizedStandardCompare:(NSString *)string;
@end

@interface NSMutableString (AIKeywordReplacementAdditions)
- (void) replaceKeyword:(NSString *)word withString:(NSString *)newWord;
- (void) safeReplaceCharactersInRange:(NSRange)range withString:(NSString *)newWord;
@end

@implementation NSMutableString (AIKeywordReplacementAdditions)
- (void) replaceKeyword:(NSString *)keyWord withString:(NSString *)newWord
{
	if(!keyWord) return;
	if(!newWord) newWord = @"";
	[self replaceOccurrencesOfString:keyWord
						  withString:newWord
							 options:NSLiteralSearch
							   range:NSMakeRange(0.0f, [self length])];
}

- (void) safeReplaceCharactersInRange:(NSRange)range withString:(NSString *)newWord
{
	if (range.location == NSNotFound || range.length == 0) return;
	if (!newWord) [self deleteCharactersInRange:range];
	else [self replaceCharactersInRange:range withString:newWord];
}
@end

//The old code built the paths itself, which follows the filesystem's case sensitivity, so some noobs named stuff wrong.
//NSBundle is always case sensitive, so those styles broke (they were already broken on case sensitive hfsx)
//These methods only check for the all-lowercase variant, so are not suitable for general purpose use.
@interface NSBundle (StupidCompatibilityHack)
- (NSString *)semiCaseInsensitivePathForResource:(NSString *)res ofType:(NSString *)type;
- (NSString *)semiCaseInsensitivePathForResource:(NSString *)res ofType:(NSString *)type inDirectory:(NSString *)dirpath;
@end

@implementation NSBundle (StupidCompatibilityHack)
- (NSString *)semiCaseInsensitivePathForResource:(NSString *)res ofType:(NSString *)type
{
	NSString *path = [self pathForResource:res ofType:type];
	if(!path)
		path = [self pathForResource:[res lowercaseString] ofType:type];
	return path;
}

- (NSString *)semiCaseInsensitivePathForResource:(NSString *)res ofType:(NSString *)type inDirectory:(NSString *)dirpath
{
	NSString *path = [self pathForResource:res ofType:type inDirectory:dirpath];
	if(!path)
		path = [self pathForResource:[res lowercaseString] ofType:type inDirectory:dirpath];
	return path;
}

@end

@interface AIWebkitMessageViewStyle ()
- (id)initWithBundle:(NSBundle *)inBundle;
- (void)_loadTemplates;
- (void)releaseResources;
- (NSMutableString *)_escapeStringForPassingToScript:(NSMutableString *)inString;
- (NSString *)noVariantName;
- (NSString *)iconPathForFileTransfer:(ESFileTransfer *)inObject;
- (NSString *)statusIconPathForListObject:(AIListObject *)inObject;
@end

@implementation AIWebkitMessageViewStyle

@synthesize activeVariant;

+ (id)messageViewStyleFromBundle:(NSBundle *)inBundle
{
	return [[self alloc] initWithBundle:inBundle];
}

+ (id)messageViewStyleFromPath:(NSString *)path
{
	NSBundle *styleBundle = [NSBundle bundleWithPath:[path stringByExpandingBundlePath]];
	if(styleBundle)
		return [[self alloc] initWithBundle:styleBundle];
	return nil;
}

/*!
 *	@brief Initialize
 */
- (id)initWithBundle:(NSBundle *)inBundle
{
	if ((self = [super init])) {
		styleBundle = inBundle;
		stylePath = [styleBundle resourcePath];

		if ([self reloadStyle] == FALSE) {
            return nil;
        }
	}

	return self;
}

- (BOOL) reloadStyle
{
	[self releaseResources];

	/* Our styles are versioned so we can change how they work without breaking compatibility.
	 *
	 * Version 0: Initial Webkit Version
	 * Version 1: Template.html now handles all scroll-to-bottom functionality.  It is no longer required to call the
	 *            scrollToBottom functions when inserting content.
	 * Version 2: No significant changes
	 * Version 3: main.css is no longer a separate style, it now serves as the base stylesheet and is imported by default.
	 *            The default variant is now a separate file in /variants like all other variants.
	 *			  Template.html now includes appendMessageNoScroll() and appendNextMessageNoScroll() which behave
	 *				the same as appendMessage() and appendNextMessage() in Versions 1 and 2 but without scrolling.
	 * Version 4: Template.html now includes replaceLastMessage()
	 *            Template.html now defines actionMessageUserName and actionMessageBody for display of /me (actions).
	 *				 If the style provides a custom Template.html, these classes must be defined.
	 *				 CSS can be used to customize the appearance of actions.
	 *			  HTML filters in are now supported in Adium's content filter system; filters can assume Version 4 or later.
	 */
	styleVersion = [[styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_VERSION] integerValue];

    /* Refuse to load a version whose minimum compatible version is greater than the latest version we know about; that
     * indicates this is a style FROM THE FUTURE, and we can't risk corrupting our own timeline.
     */
    NSInteger minimumCompatibleVersion = [[styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_VERSION_MIN] integerValue];
    if (minimumCompatibleVersion && (minimumCompatibleVersion > MAX_KNOWN_WEBKIT_VERSION)) {
        return NO;
    }

    //Default behavior
	allowTextBackgrounds = YES;

	//Pre-fetch our templates
	[self _loadTemplates];

	//Style flags
	allowsCustomBackground = ![[styleBundle objectForInfoDictionaryKey:@"DisableCustomBackground"] boolValue];
	transparentDefaultBackground = [[styleBundle objectForInfoDictionaryKey:@"DefaultBackgroundIsTransparent"] boolValue];

	combineConsecutive = ![[styleBundle objectForInfoDictionaryKey:@"DisableCombineConsecutive"] boolValue];

	NSNumber *tmpNum = [styleBundle objectForInfoDictionaryKey:@"ShowsUserIcons"];
	allowsUserIcons = (tmpNum ? [tmpNum boolValue] : YES);

	//User icon masking
	NSString *tmpName = [styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_USER_ICON_MASK];
	if (tmpName) userIconMask = [[NSImage alloc] initWithContentsOfFile:[stylePath stringByAppendingPathComponent:tmpName]];

	NSNumber *allowsColorsNumber = [styleBundle objectForInfoDictionaryKey:@"AllowTextColors"];
	allowsColors = (allowsColorsNumber ? [allowsColorsNumber boolValue] : YES);

    return YES;
}

/*!
 *  @brief release everything we loaded from the style bundle
 */
- (void)releaseResources
{
	//Templates
	headerHTML = nil;
	footerHTML = nil;
	baseHTML = nil;
	contentHTML = nil;
	contentInHTML = nil;
	nextContentInHTML = nil;
	contextInHTML = nil;
	nextContextInHTML = nil;
	contentOutHTML = nil;
	nextContentOutHTML = nil;
	contextOutHTML = nil;
	nextContextOutHTML = nil;
	statusHTML = nil;
	fileTransferHTML = nil;
	topicHTML = nil;

	customBackgroundPath = nil;
	customBackgroundColor = nil;

	userIconMask = nil;
}

/*!
 *	@brief Deallocate
 */
- (void)dealloc
{
	[self releaseResources];

	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
}

@synthesize bundle = styleBundle;

- (BOOL)isLegacy
{
	return styleVersion < LEGACY_VERSION_THRESHOLD;
}

#pragma mark Settings

@synthesize allowsCustomBackground, allowsUserIcons, allowsColors, userIconMask;

- (NSArray *)validSenderColors
{
	if(!checkedSenderColors) {
		NSURL *url = [NSURL fileURLWithPath:[stylePath stringByAppendingPathComponent:@"Incoming/SenderColors.txt"]];
		NSString *senderColorsFile = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
        
		if(senderColorsFile)
			validSenderColors = [senderColorsFile componentsSeparatedByString:@":"];
        
		checkedSenderColors = YES;
	}
    
	return validSenderColors;
}

- (BOOL)isBackgroundTransparent
{
	//Our custom background is only transparent if the user has set a custom color with an alpha component less than 1.0
	return ((!customBackgroundColor && transparentDefaultBackground) ||
		   (customBackgroundColor && [customBackgroundColor alphaComponent] < 0.99));
}

- (NSString *)defaultFontFamily
{
	NSString *defaultFontFamily = [styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_FAMILY];
	if (!defaultFontFamily) defaultFontFamily = [[NSFont systemFontOfSize:0] familyName];

	return defaultFontFamily;
}

- (NSNumber *)defaultFontSize
{
	NSNumber *defaultFontSize = [styleBundle objectForInfoDictionaryKey:KEY_WEBKIT_DEFAULT_FONT_SIZE];

	if (!defaultFontSize) defaultFontSize = [NSNumber numberWithInteger:[[NSFont systemFontOfSize:0] pointSize]];

	return defaultFontSize;
}

- (BOOL)hasHeader
{
	return headerHTML && [headerHTML length];
}

- (BOOL)hasTopic
{
	return topicHTML && [topicHTML length];
}

#pragma mark Behavior

- (void)setDateFormat:(NSString *)format
{
	if (!format || [format length] == 0) {
		format = [NSDateFormatter localizedDateFormatStringShowingSeconds:NO showingAMorPM:NO];
	}

	if ([format rangeOfString:@"%"].location != NSNotFound) {
		/* Support strftime-style format strings, which old message styles may use */
		timeStampFormatter = [[NSDateFormatter alloc] initWithDateFormat:format allowNaturalLanguage:NO];
	} else {
		timeStampFormatter = [[NSDateFormatter alloc] init];
		[timeStampFormatter setDateFormat:format];
	}
}

- (void) flushTimeFormatterCache:(id)dummy {
	[timeFormatterCache removeAllObjects];
}

@synthesize allowTextBackgrounds, customBackgroundType, customBackgroundColor, showIncomingMessageColors=showIncomingColors, showIncomingMessageFonts=showIncomingFonts, customBackgroundPath, nameFormat, useCustomNameFormat, showHeader, showUserIcons;

//Templates ------------------------------------------------------------------------------------------------------------
#pragma mark Templates
- (NSString *)baseTemplateForChat:(AIChat *)chat
{
	NSMutableString	*templateHTML;

	// If this is a group chat, we want to include a topic.
	// Otherwise, if the header is shown, use it.
	NSString *headerContent = @"";
	if (showHeader) {
		if (chat.isGroupChat) {
			headerContent = (((AIGroupChat *)chat).supportsTopic ? TOPIC_MAIN_DIV : @"");
		} else if (headerHTML) {
			headerContent = headerHTML;
		}
	}

	//Old styles may be using an old custom 4 parameter baseHTML.  Styles version 3 and higher should
	//be using the bundled (or a custom) 5 parameter baseHTML.
	if ((styleVersion < 3) && usingCustomTemplateHTML) {
		templateHTML = [NSMutableString stringWithFormat:baseHTML,						//Template
			[[NSURL fileURLWithPath:stylePath] absoluteString],							//Base path
			[self pathForVariant:self.activeVariant],									//Variant path
			headerContent,
			(footerHTML ? footerHTML : @"")];
	} else {
		templateHTML = [NSMutableString stringWithFormat:baseHTML,						//Template
			[[NSURL fileURLWithPath:stylePath] absoluteString],							//Base path
			styleVersion < 3 ? @"" : @"@import url( \"main.css\" );",					//Import main.css for new enough styles
			[self pathForVariant:self.activeVariant],									//Variant path
			headerContent,
			(footerHTML ? footerHTML : @"")];
	}

	return [self fillKeywordsForBaseTemplate:templateHTML chat:chat];
}

- (NSString *)templateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar
{
	NSString	*template;

	//Get the correct template for what we're inserting
	if ([[content type] isEqualToString:CONTENT_MESSAGE_TYPE]) {
		if ([content isOutgoing]) {
			template = (contentIsSimilar ? nextContentOutHTML : contentOutHTML);
		} else {
			template = (contentIsSimilar ? nextContentInHTML : contentInHTML);
		}

	} else if ([[content type] isEqualToString:CONTENT_CONTEXT_TYPE]) {
		if ([content isOutgoing]) {
			template = (contentIsSimilar ? nextContextOutHTML : contextOutHTML);
		} else {
			template = (contentIsSimilar ? nextContextInHTML : contextInHTML);
		}

	} else if([[content type] isEqualToString:CONTENT_FILE_TRANSFER_TYPE]) {
		template = [fileTransferHTML mutableCopy];
	} else if ([[content type] isEqualToString:CONTENT_TOPIC_TYPE]) {
		template = topicHTML;
	}
	else {
		template = statusHTML;
	}

	return template;
}

- (NSString *)completedTemplateForContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar
{
	NSMutableString *mutableTemplate = [[self templateForContent:content similar:contentIsSimilar] mutableCopy];

	if (mutableTemplate)
		[self fillKeywords:mutableTemplate forContent:content similar:contentIsSimilar];

	return mutableTemplate;
}

/*!
 *	@brief Pre-fetch all the style templates
 *
 *	This needs to be called before either baseTemplate or templateForContent is called
 */
- (void)_loadTemplates
{
	//Load the style's templates
	//We can't use NSString's initWithContentsOfFile here.  HTML files are interpreted in the defaultCEncoding
	//(which varies by system) when read that way.  We want to always interpret the files as UTF8.
	headerHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Header" ofType:@"html"]];
	footerHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Footer" ofType:@"html"]];
	topicHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Topic" ofType:@"html"]];
	baseHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Template" ofType:@"html"]];

	//Starting with version 1, styles can choose to not include template.html.  If the template is not included
	//Adium's default will be used.  This is preferred since any future template updates will apply to the style
	if ((!baseHTML || [baseHTML length] == 0) && styleVersion >= 1) {
		baseHTML = [NSString stringWithContentsOfUTF8File:[[NSBundle bundleForClass:[self class]] semiCaseInsensitivePathForResource:@"Template" ofType:@"html"]];
		usingCustomTemplateHTML = NO;
	} else {
		usingCustomTemplateHTML = YES;

		NSAssert(baseHTML != nil, @"The impossible happened!");

		if ([baseHTML rangeOfString:@"function imageCheck()" options:NSLiteralSearch].location != NSNotFound) {
			/* This doesn't quite fix image swapping on styles with broken image swapping due to custom HTML templates,
			 * but it improves it. For some reason, the result of using our normal template.html functions is that
			 * clicking works once, then the text doesn't allow a return click. This is an improvement compared
			 * to fully broken behavior in which the return click shows a missing-image placeholder.
			 */
			NSMutableString *imageSwapFixedBaseHTML = [baseHTML mutableCopy];
			[imageSwapFixedBaseHTML replaceOccurrencesOfString:
			 @"		function imageCheck() {\n"
			 "			node = event.target;\n"
			 "			if(node.tagName == 'IMG' && node.alt) {\n"
			 "				a = document.createElement('a');\n"
			 "				a.setAttribute('onclick', 'imageSwap(this)');\n"
			 "				a.setAttribute('src', node.src);\n"
			 "				text = document.createTextNode(node.alt);\n"
			 "				a.appendChild(text);\n"
			 "				node.parentNode.replaceChild(a, node);\n"
			 "			}\n"
			 "		}"
													withString:
			 @"		function imageCheck() {\n"
			 "			var node = event.target;\n"
			 "			if(node.tagName.toLowerCase() == 'img' && !client.zoomImage(node) && node.alt) {\n"
			 "				var a = document.createElement('a');\n"
			 "				a.setAttribute('onclick', 'imageSwap(this)');\n"
			 "				a.setAttribute('src', node.getAttribute('src'));\n"
			 "				a.className = node.className;\n"
			 "				var text = document.createTextNode(node.alt);\n"
			 "				a.appendChild(text);\n"
			 "				node.parentNode.replaceChild(a, node);\n"
			 "			}\n"
			 "		}"
													   options:NSLiteralSearch];
			[imageSwapFixedBaseHTML replaceOccurrencesOfString:
			 @"		function imageSwap(node) {\n"
			 "			img = document.createElement('img');\n"
			 "			img.setAttribute('src', node.src);\n"
			 "			img.setAttribute('alt', node.firstChild.nodeValue);\n"
			 "			node.parentNode.replaceChild(img, node);\n"
			 "			alignChat();\n"
			 "		}"
													withString:
			 @"		function imageSwap(node) {\n"
			 "			var shouldScroll = nearBottom();\n"
			 "			//Swap the image/text\n"
			 "			var img = document.createElement('img');\n"
			 "			img.setAttribute('src', node.getAttribute('src'));\n"
			 "			img.setAttribute('alt', node.firstChild.nodeValue);\n"
			 "			img.className = node.className;\n"
			 "			node.parentNode.replaceChild(img, node);\n"
			 "			\n"
			 "			alignChat(shouldScroll);\n"
			 "		}"
													   options:NSLiteralSearch];
			/* Now for ones which don't call alignChat() */
			[imageSwapFixedBaseHTML replaceOccurrencesOfString:
			 @"		function imageSwap(node) {\n"
			 "			img = document.createElement('img');\n"
			 "			img.setAttribute('src', node.src);\n"
			 "			img.setAttribute('alt', node.firstChild.nodeValue);\n"
			 "			node.parentNode.replaceChild(img, node);\n"
			 "		}"
													withString:
			 @"		function imageSwap(node) {\n"
			 "			var shouldScroll = nearBottom();\n"
			 "			//Swap the image/text\n"
			 "			var img = document.createElement('img');\n"
			 "			img.setAttribute('src', node.getAttribute('src'));\n"
			 "			img.setAttribute('alt', node.firstChild.nodeValue);\n"
			 "			img.className = node.className;\n"
			 "			node.parentNode.replaceChild(img, node);\n"
			 "		}"
													   options:NSLiteralSearch];
			baseHTML = imageSwapFixedBaseHTML;
		}

	}

	//Content Templates
	contentHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Content" ofType:@"html"]];
	contentInHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Content" ofType:@"html" inDirectory:@"Incoming"]];
	nextContentInHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"NextContent" ofType:@"html" inDirectory:@"Incoming"]];
	contentOutHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Content" ofType:@"html" inDirectory:@"Outgoing"]];
	nextContentOutHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"NextContent" ofType:@"html" inDirectory:@"Outgoing"]];

	//Message history
	contextInHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Context" ofType:@"html" inDirectory:@"Incoming"]];
	nextContextInHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"NextContext" ofType:@"html" inDirectory:@"Incoming"]];
	contextOutHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Context" ofType:@"html" inDirectory:@"Outgoing"]];
	nextContextOutHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"NextContext" ofType:@"html" inDirectory:@"Outgoing"]];

	//Fall back to Resources/Content.html if Incoming isn't present
	if (!contentInHTML) contentInHTML = contentHTML;

	//Fall back to Content if NextContent doesn't need to use different HTML
	if (!nextContentInHTML) nextContentInHTML = contentInHTML;

	//Fall back to Content if Context isn't present
	if (!nextContextInHTML) nextContextInHTML = nextContentInHTML;
	if (!contextInHTML) contextInHTML = contentInHTML;

	//Fall back to Content if Context isn't present
	if (!nextContextOutHTML && nextContentOutHTML) nextContextOutHTML = nextContentOutHTML;
	if (!contextOutHTML && contentOutHTML) contextOutHTML = contentOutHTML;

	//Fall back to Content if Context isn't present
	if (!nextContextOutHTML) nextContextOutHTML = nextContextInHTML;
	if (!contextOutHTML) contextOutHTML = contextInHTML;

	//Fall back to Incoming if Outgoing doesn't need to be different
	if (!contentOutHTML) contentOutHTML = contentInHTML;
	if (!nextContentOutHTML) nextContentOutHTML = nextContentInHTML;

	//Status
	statusHTML = [NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"Status" ofType:@"html"]];

	//Fall back to Resources/Incoming/Content.html if Status isn't present
	if (!statusHTML) statusHTML = contentInHTML;

	//TODO: make a generic Request message, rather than having this ft specific one
	NSMutableString *fileTransferHTMLTemplate;
	fileTransferHTMLTemplate = [[NSString stringWithContentsOfUTF8File:[styleBundle semiCaseInsensitivePathForResource:@"FileTransferRequest" ofType:@"html"]] mutableCopy];
	if(!fileTransferHTMLTemplate) {
		fileTransferHTMLTemplate = [contentInHTML mutableCopy];
		[fileTransferHTMLTemplate replaceKeyword:@"%message%"
									  withString:@"<p><img src=\"%fileIconPath%\" style=\"width:32px; height:32px; vertical-align:middle;\"></img><input type=\"button\" onclick=\"%saveFileAsHandler%\" value=\"Download %fileName%\"></p>"];
	}
	[fileTransferHTMLTemplate replaceKeyword:@"Download %fileName%"
						  withString:[NSString stringWithFormat:AILocalizedString(@"Download %@", "%@ will be a file name"), @"%fileName%"]];
	fileTransferHTML = fileTransferHTMLTemplate;
}

#pragma mark Scripts
- (NSString *)scriptForAppendingContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar willAddMoreContentObjects:(BOOL)willAddMoreContentObjects replaceLastContent:(BOOL)replaceLastContent
{
	NSMutableString	*newHTML;
	NSString		*script;

	//If combining of consecutive messages has been disabled, we treat all content as non-similar
	if (!combineConsecutive) contentIsSimilar = NO;

	//Fetch the correct template and substitute keywords for the passed content
	newHTML = [[self completedTemplateForContent:content similar:contentIsSimilar] mutableCopy];

	//BOM scripts vary by style version
	if (!usingCustomTemplateHTML && styleVersion >= 4) {
		/* If we're using the built-in template HTML, we know that it supports our most modern scripts */
		if (replaceLastContent)
			script = REPLACE_LAST_MESSAGE;
		else if (willAddMoreContentObjects) {
			script = (contentIsSimilar ? APPEND_NEXT_MESSAGE_NO_SCROLL : APPEND_MESSAGE_NO_SCROLL);
		} else {
			script = (contentIsSimilar ? APPEND_NEXT_MESSAGE : APPEND_MESSAGE);
		}

	} else  if (styleVersion >= 3) {
		if (willAddMoreContentObjects) {
			script = (contentIsSimilar ? APPEND_NEXT_MESSAGE_NO_SCROLL : APPEND_MESSAGE_NO_SCROLL);
		} else {
			script = (contentIsSimilar ? APPEND_NEXT_MESSAGE : APPEND_MESSAGE);
		}
	} else if (styleVersion >= 1) {
		script = (contentIsSimilar ? APPEND_NEXT_MESSAGE : APPEND_MESSAGE);

	} else {
		if (usingCustomTemplateHTML && [content isKindOfClass:[AIContentStatus class]]) {
			/* Old styles with a custom template.html had Status.html files without 'insert' divs coupled
			 * with a APPEND_NEXT_MESSAGE_WITH_SCROLL script which assumes one exists.
			 */
			script = APPEND_MESSAGE_WITH_SCROLL;
		} else {
			script = (contentIsSimilar ? APPEND_NEXT_MESSAGE_WITH_SCROLL : APPEND_MESSAGE_WITH_SCROLL);
		}
	}

	return [NSString stringWithFormat:script, [self _escapeStringForPassingToScript:newHTML]];
}

- (NSString *)scriptForChangingVariant
{
	return [NSString stringWithFormat:@"setStylesheet(\"mainStyle\",\"%@\");",[self pathForVariant:self.activeVariant]];
}

- (NSString *)scriptForScrollingAfterAddingMultipleContentObjects
{
	if ((styleVersion >= 3) || !usingCustomTemplateHTML) {
		return @"if (this.AI_viewScrolledOnLoad != undefined) {alignChat(nearBottom());} else {this.AI_viewScrolledOnLoad = true; alignChat(true);}";
	}

	return nil;
}

/*!
 *	@brief Escape a string for passing to our BOM scripts
 */
- (NSMutableString *)_escapeStringForPassingToScript:(NSMutableString *)inString
{
	// We need to escape a few things to get our string to the javascript without trouble
	[inString replaceOccurrencesOfString:@"\\"
							  withString:@"\\\\"
								 options:NSLiteralSearch];

	[inString replaceOccurrencesOfString:@"\""
							  withString:@"\\\""
								 options:NSLiteralSearch];

	[inString replaceOccurrencesOfString:@"\n"
							  withString:@""
								 options:NSLiteralSearch];

	[inString replaceOccurrencesOfString:@"\r"
							  withString:@"<br>"
								 options:NSLiteralSearch];

	return inString;
}

#pragma mark Variants

- (NSArray *)availableVariants
{
	NSMutableArray	*availableVariants = [NSMutableArray array];

	//Build an array of all variant names
	for (NSString *path in [styleBundle pathsForResourcesOfType:@"css" inDirectory:@"Variants"]) {
		[availableVariants addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
	}

	//Style versions before 3 stored the default variant in a separate location.  They also allowed for this
	//varient name to not be specified, and would substitute a localized string in its place.
	if (styleVersion < 3) {
		[availableVariants addObject:[self noVariantName]];
	}

	//Alphabetize the variants
	[availableVariants sortUsingSelector:@selector(localizedStandardCompare:)];

	return availableVariants;
}

- (NSString *)pathForVariant:(NSString *)variant
{
	if (styleVersion > 2) {
        //mvv > 2 and (variant exists and not nil)
        if (![variant isEqualToString:[self noVariantName]] && variant != nil ) {
            return [NSString stringWithFormat:@"Variants/%@.css",variant];
        }
        // mvv > 2 and variant does not exist
    	else if (([variant isEqualToString:[self noVariantName]] || variant == nil )) {
            return @"";
        }
	}
    //Styles before version 3 stored the default variant in main.css, and not in the variants folder.
	else if (styleVersion < 3 && [variant isEqualToString:[self noVariantName]]) {
		return @"main.css";
	}
    //Old styles still support varients, so we need to make sure we return them if they exist.
    else if (variant != nil) {
        return [NSString stringWithFormat:@"Variants/%@.css",variant];
    }
    
	// Secure Return
	return @"";
}

/*!
 *	@brief Base variant name for styles before version 2
 */
- (NSString *)noVariantName
{
	NSString	*noVariantName = [styleBundle objectForInfoDictionaryKey:@"DisplayNameForNoVariant"];
	return noVariantName ? noVariantName : AILocalizedString(@"Normal","Normal style variant menu item");
}

+ (NSString *)noVariantNameForBundle:(NSBundle *)inBundle
{
	NSString	*noVariantName = [inBundle objectForInfoDictionaryKey:@"DisplayNameForNoVariant"];
	return noVariantName ? noVariantName : AILocalizedString(@"Normal","Normal style variant menu item");
}

- (NSString *)defaultVariant
{
	return styleVersion < 3 ? [self noVariantName] : [styleBundle objectForInfoDictionaryKey:@"DefaultVariant"];
}

+ (NSString *)defaultVariantForBundle:(NSBundle *)inBundle
{
	return [[inBundle objectForInfoDictionaryKey:KEY_WEBKIT_VERSION] integerValue] < 3 ?
		   [self noVariantNameForBundle:inBundle] :
		   [inBundle objectForInfoDictionaryKey:@"DefaultVariant"];
}

#pragma mark Keyword replacement

- (NSMutableString *)fillKeywords:(NSMutableString *)inString forContent:(AIContentObject *)content similar:(BOOL)contentIsSimilar
{
	NSDate			*date = nil;
	NSRange			range;
	AIListObject	*contentSource = [content source];
	AIListObject	*theSource = ([contentSource isKindOfClass:[AIListContact class]] ?
								  [(AIListContact *)contentSource parentContact] :
								  contentSource);

	/*
		htmlEncodedMessage is only encoded correctly for AIContentMessages
		but we do it up here so that we can check for RTL/LTR text below without
		having to encode the message twice. This is less than ideal
	 */
	NSString		*htmlEncodedMessage = [AIHTMLDecoder encodeHTML:[content message]
															headers:NO
														   fontTags:showIncomingFonts
												 includingColorTags:(allowsColors && showIncomingColors)
													  closeFontTags:YES
														  styleTags:YES
										 closeStyleTagsOnFontChange:YES
													 encodeNonASCII:YES
													   encodeSpaces:YES
														 imagesPath:NSTemporaryDirectory()
												  attachmentsAsText:NO
										  onlyIncludeOutgoingImages:NO
													 simpleTagsOnly:NO
													 bodyBackground:NO
										        allowJavascriptURLs:NO];

	if (styleVersion >= 4)
		htmlEncodedMessage = [adium.contentController filterHTMLString:htmlEncodedMessage
															   direction:[content isOutgoing] ? AIFilterOutgoing : AIFilterIncoming
																 content:content];

	//date
	if ([content respondsToSelector:@selector(date)])
		date = [(AIContentMessage *)content date];

	//Replacements applicable to any AIContentObject
	[inString replaceKeyword:@"%time%"
				  withString:(date ? [timeStampFormatter stringFromDate:date] : @"")];

	__block NSString *shortTimeString;
	[NSDateFormatter withLocalizedDateFormatterShowingSeconds:NO showingAMorPM:NO perform:^(NSDateFormatter *dateFormatter){
		shortTimeString = (date ? [dateFormatter stringFromDate:date] : @"");
	}];

	[inString replaceKeyword:@"%shortTime%"
				  withString:shortTimeString];

	if ([inString rangeOfString:@"%senderStatusIcon%"].location != NSNotFound) {
		//Only cache the status icon to disk if the message style will actually use it
		[inString replaceKeyword:@"%senderStatusIcon%"
					  withString:[self statusIconPathForListObject:theSource]];
	}

	//Replaces %localized{x}% with a a localized version of x, searching the style's localizations, and then Adium's localizations
	do{
		range = [inString rangeOfString:@"%localized{"];
		if (range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), [inString length] - NSMaxRange(range))];
			if (endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
				NSString *untranslated = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];

				NSString *translated = [styleBundle localizedStringForKey:untranslated
																	value:untranslated
																	table:nil];
				if (!translated || [translated length] == 0) {
					translated = [[NSBundle bundleForClass:[self class]] localizedStringForKey:untranslated
																						 value:untranslated
																						 table:nil];
					if (!translated || [translated length] == 0) {
						translated = [[NSBundle mainBundle] localizedStringForKey:untranslated
																			value:untranslated
																			table:nil];
					}
				}


				[inString safeReplaceCharactersInRange:NSUnionRange(range, endRange)
											withString:translated];
			}
		}
	} while (range.location != NSNotFound);

	[inString replaceKeyword:@"%userIcons%"
				  withString:(showUserIcons ? @"showIcons" : @"hideIcons")];

	[inString replaceKeyword:@"%messageClasses%"
				  withString:[(contentIsSimilar ? @"consecutive " : @"") stringByAppendingString:[[content displayClasses] componentsJoinedByString:@" "]]];

	[inString replaceKeyword:@"%senderColor%"
				  withString:[NSColor representedColorForObject:contentSource.UID withValidColors:self.validSenderColors]];

	//HAX. The odd conditional here detects the rtl html that our html parser spits out.
	BOOL isRTL = ([htmlEncodedMessage rangeOfString:@"<div dir=\"rtl\">"
                                            options:(NSCaseInsensitiveSearch | NSLiteralSearch)].location != NSNotFound);
	[inString replaceKeyword:@"%messageDirection%"
				  withString:(isRTL ? @"rtl" : @"ltr")];

	//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
	do{
		range = [inString rangeOfString:@"%time{"];
		if (range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), [inString length] - NSMaxRange(range))];
			if (endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
				if (date) {
					if (!timeFormatterCache) {
						timeFormatterCache = [[NSMutableDictionary alloc] init];
						[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(flushTimeFormatterCache:) name:@"AppleDatePreferencesChangedNotification" object:nil];
						[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(flushTimeFormatterCache:) name:@"AppleTimePreferencesChangedNotification" object:nil];
					}
					NSString *timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];

					NSDateFormatter *dateFormatter = [timeFormatterCache objectForKey:timeFormat];
					if (!dateFormatter) {
						if ([timeFormat rangeOfString:@"%"].location != NSNotFound) {
							/* Support strftime-style format strings, which old message styles may use */
							dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeFormat allowNaturalLanguage:NO];
						} else {
							dateFormatter = [[NSDateFormatter alloc] init];
							[dateFormatter setDateFormat:timeFormat];
						}
						[timeFormatterCache setObject:dateFormatter forKey:timeFormat];
					}

					[inString safeReplaceCharactersInRange:NSUnionRange(range, endRange)
												withString:[dateFormatter stringFromDate:date]];

				} else
					[inString deleteCharactersInRange:NSUnionRange(range, endRange)];

			}
		}
	} while (range.location != NSNotFound);

	do{
		range = [inString rangeOfString:@"%userIconPath%"];
		if (range.location != NSNotFound) {
			NSString    *userIconPath;
			NSString	*replacementString;

			userIconPath = [theSource valueForProperty:KEY_WEBKIT_USER_ICON];
			if (!userIconPath) {
				userIconPath = [theSource valueForProperty:@"UserIconPath"];
			}

			if (showUserIcons && userIconPath) {
				replacementString = [NSString stringWithFormat:@"file://%@", userIconPath];

			} else {
				replacementString = ([content isOutgoing]
									 ? @"Outgoing/buddy_icon.png"
									 : @"Incoming/buddy_icon.png");
			}

			[inString safeReplaceCharactersInRange:range withString:replacementString];
		}
	} while (range.location != NSNotFound);

	[inString replaceKeyword:@"%service%"
				  withString:[content.chat.account.service shortDescription]];

	[inString replaceKeyword:@"%serviceIconPath%"
				  withString:[AIServiceIcons pathForServiceIconForServiceID:content.chat.account.service.serviceID
																	   type:AIServiceIconLarge]];

	if ([inString rangeOfString:@"%variant%"].location != NSNotFound) {
		/* Per #12702, don't allow spaces in the variant name, as otherwise it becomes multiple css classes */
		[inString replaceKeyword:@"%variant%"
					  withString:[self.activeVariant stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
	}

	//message stuff
	if ([content isKindOfClass:[AIContentMessage class]]) {

		//Use [content source] directly rather than the potentially-metaContact theSource
		NSString *formattedUID = nil;
        if (content.chat.isGroupChat && [(AIGroupChat *)content.chat aliasForContact:contentSource]) {
			formattedUID = [(AIGroupChat *)content.chat aliasForContact:contentSource];
		} else {
			formattedUID = contentSource.formattedUID;
		}

		NSString *displayName;

        if (content.chat.isGroupChat)
            displayName = [(AIGroupChat *)content.chat displayNameForContact:contentSource];
        else
            displayName = content.source.displayName;

		[inString replaceKeyword:@"%status%"
					  withString:@""];

		[inString replaceKeyword:@"%senderScreenName%"
					  withString:[(formattedUID ?
								   formattedUID :
								   displayName) stringByEscapingForXMLWithEntities:nil]];


		[inString replaceKeyword:@"%senderPrefix%"
					  withString:((AIContentMessage *)content).senderPrefix];

		do{
			range = [inString rangeOfString:@"%sender%"];
			if (range.location != NSNotFound) {
				NSString		*senderDisplay = nil;
				if (useCustomNameFormat) {
			 		if (formattedUID && ![displayName isEqualToString:formattedUID]) {
						switch (nameFormat) {
							case AIDefaultName:
								break;

							case AIDisplayName:
								senderDisplay = displayName;
								break;

							case AIDisplayName_ScreenName:
								senderDisplay = [NSString stringWithFormat:@"%@ (%@)",displayName,formattedUID];
								break;

							case AIScreenName_DisplayName:
								senderDisplay = [NSString stringWithFormat:@"%@ (%@)",formattedUID,displayName];
								break;

							case AIScreenName:
								senderDisplay = formattedUID;
								break;
						}
					}

					//Test both displayName and formattedUID for nil-ness. If they're both nil, the assertion will trip.
					if (!senderDisplay) {
						senderDisplay = displayName;
						if (!senderDisplay) {
							senderDisplay = formattedUID;
							if (!senderDisplay) {
								AILog(@"XXX we don't have a sender for %@ (%@)", content, [content message]);
								NSLog(@"Enormous error: we don't have a sender for %@ (%@)", content, [content message]);

								// This shouldn't happen.
								senderDisplay = @"(unknown)";
							}
						}
					}
				} else {
					senderDisplay = displayName;
				}

				if ([(AIContentMessage *)content isAutoreply]) {
					senderDisplay = [NSString stringWithFormat:@"%@ %@",senderDisplay,AILocalizedString(@"(Autoreply)","Short word inserted after the sender's name when displaying a message which was an autoresponse")];
				}

				[inString safeReplaceCharactersInRange:range withString:[senderDisplay stringByEscapingForXMLWithEntities:nil]];
			}
		} while (range.location != NSNotFound);

		do {
			range = [inString rangeOfString:@"%senderDisplayName%"];
			if (range.location != NSNotFound) {
				NSString *serversideDisplayName = ([theSource isKindOfClass:[AIListContact class]] ?
												   [(AIListContact *)theSource serversideDisplayName] :
												   nil);
				if (!serversideDisplayName) {
					serversideDisplayName = theSource.displayName;
				}

				[inString safeReplaceCharactersInRange:range
											withString:[serversideDisplayName stringByEscapingForXMLWithEntities:nil]];
			}
		} while (range.location != NSNotFound);

		//Blatantly stealing the date code for the background color script.
		do{
			range = [inString rangeOfString:@"%textbackgroundcolor{"];
			if (range.location != NSNotFound) {
				NSRange endRange;
				endRange = [inString rangeOfString:@"}%" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), [inString length] - NSMaxRange(range))];
				if (endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
					NSString *transparency = [inString substringWithRange:NSMakeRange(NSMaxRange(range),
																					  (endRange.location - NSMaxRange(range)))];

					if (allowTextBackgrounds && showIncomingColors) {
						NSString *thisIsATemporaryString;
						unsigned rgb = 0, red, green, blue;
						NSScanner *hexcode;
						thisIsATemporaryString = [AIHTMLDecoder encodeHTML:[content message] headers:NO
																  fontTags:NO
														includingColorTags:NO
															 closeFontTags:NO
																 styleTags:NO
												closeStyleTagsOnFontChange:NO
															encodeNonASCII:NO
															  encodeSpaces:NO
																imagesPath:NSTemporaryDirectory()
														 attachmentsAsText:NO
												 onlyIncludeOutgoingImages:NO
															simpleTagsOnly:NO
															bodyBackground:YES
													   allowJavascriptURLs:NO];
						hexcode = [NSScanner scannerWithString:thisIsATemporaryString];
						[hexcode scanHexInt:&rgb];
						if (![thisIsATemporaryString length] && rgb == 0) {
							[inString deleteCharactersInRange:NSUnionRange(range, endRange)];
						} else {
							red = (rgb & 0xff0000) >> 16;
							green = (rgb & 0x00ff00) >> 8;
							blue = rgb & 0x0000ff;
							[inString safeReplaceCharactersInRange:NSUnionRange(range, endRange)
														withString:[NSString stringWithFormat:@"rgba(%d, %d, %d, %@)", red, green, blue, transparency]];
						}
					} else {
						[inString deleteCharactersInRange:NSUnionRange(range, endRange)];
					}
				} else if (endRange.location == NSMaxRange(range)) {
					if (allowTextBackgrounds && showIncomingColors) {
						NSString *thisIsATemporaryString;

						thisIsATemporaryString = [AIHTMLDecoder encodeHTML:[content message] headers:NO
																  fontTags:NO
														includingColorTags:NO
															 closeFontTags:NO
																 styleTags:NO
												closeStyleTagsOnFontChange:NO
															encodeNonASCII:NO
															  encodeSpaces:NO
																imagesPath:NSTemporaryDirectory()
														 attachmentsAsText:NO
												 onlyIncludeOutgoingImages:NO
															simpleTagsOnly:NO
															bodyBackground:YES
													   allowJavascriptURLs:NO];
						[inString safeReplaceCharactersInRange:NSUnionRange(range, endRange)
													withString:[NSString stringWithFormat:@"#%@", thisIsATemporaryString]];
					} else {
						[inString deleteCharactersInRange:NSUnionRange(range, endRange)];
					}
				}
			}
		} while (range.location != NSNotFound);

		if ([content isKindOfClass:[ESFileTransfer class]]) { //file transfers are an AIContentMessage subclass

			ESFileTransfer *transfer = (ESFileTransfer *)content;
			NSString *fileName = [[transfer remoteFilename] stringByEscapingForXMLWithEntities:nil];
			NSString *fileTransferID = [[transfer uniqueID] stringByEscapingForXMLWithEntities:nil];

			range = [inString rangeOfString:@"%fileIconPath%"];
			if (range.location != NSNotFound) {
				NSString *iconPath = [self iconPathForFileTransfer:transfer];
				NSImage *icon = [transfer iconImage];
				do{
					[[icon TIFFRepresentation] writeToFile:iconPath atomically:YES];
					[inString safeReplaceCharactersInRange:range withString:iconPath];
					range = [inString rangeOfString:@"%fileIconPath%"];
				} while (range.location != NSNotFound);
			}

			[inString replaceKeyword:@"%fileName%"
						  withString:fileName];

			[inString replaceKeyword:@"%saveFileHandler%"
						  withString:[NSString stringWithFormat:@"client.handleFileTransfer('Save', '%@')", fileTransferID]];

			[inString replaceKeyword:@"%saveFileAsHandler%"
						  withString:[NSString stringWithFormat:@"client.handleFileTransfer('SaveAs', '%@')", fileTransferID]];

			[inString replaceKeyword:@"%cancelRequestHandler%"
						  withString:[NSString stringWithFormat:@"client.handleFileTransfer('Cancel', '%@')", fileTransferID]];
		}

		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		while(range.location != NSNotFound) {
			[inString safeReplaceCharactersInRange:range withString:htmlEncodedMessage];
			range = [inString rangeOfString:@"%message%"
									options:NSLiteralSearch
									  range:NSMakeRange(range.location + htmlEncodedMessage.length,
														inString.length - range.location - htmlEncodedMessage.length)];
		}

		// Topic replacement (if applicable)
		if ([content isKindOfClass:[AIContentTopic class]]) {
			range = [inString rangeOfString:@"%topic%"];

			if (range.location != NSNotFound) {
				[inString safeReplaceCharactersInRange:range withString:[NSString stringWithFormat:TOPIC_INDIVIDUAL_WRAPPER, htmlEncodedMessage]];
			}
		}
	} else if ([content isKindOfClass:[AIContentStatus class]]) {
		NSString	*statusPhrase;
		BOOL		replacedStatusPhrase = NO;

		[inString replaceKeyword:@"%status%"
				  withString:[[(AIContentStatus *)content status] stringByEscapingForXMLWithEntities:nil]];

		[inString replaceKeyword:@"%statusSender%"
				  withString:[theSource.displayName stringByEscapingForXMLWithEntities:nil]];

		[inString replaceKeyword:@"%senderScreenName%"
				  withString:@""];

		[inString replaceKeyword:@"%senderPrefix%"
				  withString:@""];

		[inString replaceKeyword:@"%sender%"
				  withString:@""];

		if ((statusPhrase = [[content userInfo] objectForKey:@"Status Phrase"])) {
			do{
				range = [inString rangeOfString:@"%statusPhrase%"];
				if (range.location != NSNotFound) {
					[inString safeReplaceCharactersInRange:range
												withString:[statusPhrase stringByEscapingForXMLWithEntities:nil]];
					replacedStatusPhrase = YES;
				}
			} while (range.location != NSNotFound);
		}

		//Message (must do last)
		range = [inString rangeOfString:@"%message%"];
		if (range.location != NSNotFound) {
			NSString	*messageString;

			if (replacedStatusPhrase) {
				//If the status phrase was used, clear the message tag
				messageString = @"";
			} else {
				messageString = [AIHTMLDecoder encodeHTML:[content message]
												  headers:NO
												 fontTags:NO
									   includingColorTags:NO
											closeFontTags:YES
												styleTags:NO
							   closeStyleTagsOnFontChange:YES
										   encodeNonASCII:YES
											 encodeSpaces:YES
											   imagesPath:NSTemporaryDirectory()
										attachmentsAsText:NO
								onlyIncludeOutgoingImages:NO
										   simpleTagsOnly:NO
										   bodyBackground:NO
									  allowJavascriptURLs:NO];
			}

			[inString safeReplaceCharactersInRange:range withString:messageString];
		}
	}

	return inString;
}

- (NSMutableString *)fillKeywordsForBaseTemplate:(NSMutableString *)inString chat:(AIChat *)chat
{
	NSRange	range;

	[inString replaceKeyword:@"%chatName%"
				  withString:[chat.displayName stringByEscapingForXMLWithEntities:nil]];

	NSString * sourceName = [chat.account.displayName stringByEscapingForXMLWithEntities:nil];
	if(!sourceName) sourceName = @" ";
	[inString replaceKeyword:@"%sourceName%"
				  withString:sourceName];

	NSString *destinationName = chat.listObject.displayName;
	if (!destinationName) destinationName = chat.displayName;
	[inString replaceKeyword:@"%destinationName%"
				  withString:destinationName];

	NSString *serversideDisplayName = chat.listObject.serversideDisplayName;
	if (!serversideDisplayName) serversideDisplayName = chat.displayName;
	[inString replaceKeyword:@"%destinationDisplayName%"
				  withString:[serversideDisplayName stringByEscapingForXMLWithEntities:nil]];

	AIListContact	*listObject = chat.listObject;
	NSString		*iconPath = nil;

	[inString replaceKeyword:@"%incomingColor%"
				  withString:[NSColor representedColorForObject:listObject.UID withValidColors:self.validSenderColors]];

	[inString replaceKeyword:@"%outgoingColor%"
				  withString:[NSColor representedColorForObject:chat.account.UID withValidColors:self.validSenderColors]];

	if (listObject) {
		iconPath = [listObject valueForProperty:KEY_WEBKIT_USER_ICON];
		if (!iconPath)
			iconPath = [listObject valueForProperty:@"UserIconPath"];

		/* We couldn't get an icon... but perhaps we can for a parent contact */
		if (!iconPath &&
			[listObject isKindOfClass:[AIListContact class]] &&
			([(AIListContact *)listObject parentContact] != listObject)) {
			iconPath = [[(AIListContact *)listObject parentContact] valueForProperty:KEY_WEBKIT_USER_ICON];
			if (!iconPath)
				iconPath = [[(AIListContact *)listObject parentContact] valueForProperty:@"UserIconPath"];
		}
	}
	[inString replaceKeyword:@"%incomingIconPath%"
				  withString:(iconPath ? iconPath : @"incoming_icon.png")];

	AIListObject	*account = chat.account;
	iconPath = nil;

	if (account) {
		iconPath = [account valueForProperty:KEY_WEBKIT_USER_ICON];
		if (!iconPath)
			iconPath = [account valueForProperty:@"UserIconPath"];
	}
	[inString replaceKeyword:@"%outgoingIconPath%"
				  withString:(iconPath ? iconPath : @"outgoing_icon.png")];

	NSString *serviceIconPath = [AIServiceIcons pathForServiceIconForServiceID:account.service.serviceID
																		  type:AIServiceIconLarge];

	NSString *serviceIconTag = [NSString stringWithFormat:@"<img class=\"serviceIcon\" src=\"%@\" alt=\"%@\" title=\"%@\">", serviceIconPath ? serviceIconPath : @"outgoing_icon.png", [account.service shortDescription], [account.service shortDescription]];

	[inString replaceKeyword:@"%service%"
				  withString:[account.service shortDescription]];

	[inString replaceKeyword:@"%serviceIconImg%"
				  withString:serviceIconTag];

	[inString replaceKeyword:@"%serviceIconPath%"
				  withString:serviceIconPath];

	[inString replaceKeyword:@"%timeOpened%"
				  withString:[timeStampFormatter stringFromDate:[chat dateOpened]]];

	//Replaces %time{x}% with a timestamp formatted like x (using NSDateFormatter)
	do{
		range = [inString rangeOfString:@"%timeOpened{"];
		if (range.location != NSNotFound) {
			NSRange endRange;
			endRange = [inString rangeOfString:@"}%" options:NSLiteralSearch range:NSMakeRange(NSMaxRange(range), [inString length] - NSMaxRange(range))];

			if (endRange.location != NSNotFound && endRange.location > NSMaxRange(range)) {
				NSString		*timeFormat = [inString substringWithRange:NSMakeRange(NSMaxRange(range), (endRange.location - NSMaxRange(range)))];

				NSDateFormatter *dateFormatter;
				if ([timeFormat rangeOfString:@"%"].location != NSNotFound) {
					/* Support strftime-style format strings, which old message styles may use */
					dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:timeFormat allowNaturalLanguage:NO];
				} else {
					dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setDateFormat:timeFormat];
				}

				[inString safeReplaceCharactersInRange:NSUnionRange(range, endRange)
												withString:[dateFormatter stringFromDate:[chat dateOpened]]];
			}
		}
	} while (range.location != NSNotFound);

	[NSDateFormatter withLocalizedDateFormatterPerform:^(NSDateFormatter *dateFormatter){
		[inString replaceKeyword:@"%dateOpened%"
					  withString:[dateFormatter stringFromDate:[chat dateOpened]]];
	}];

	//Background
	{
		range = [inString rangeOfString:@"==bodyBackground=="];

		if (range.location != NSNotFound) { //a backgroundImage tag is not required
			NSMutableString *bodyTag = nil;

			if (allowsCustomBackground && (customBackgroundPath || customBackgroundColor)) {
				bodyTag = [[NSMutableString alloc] init];

				if (customBackgroundPath) {
					if ([customBackgroundPath length]) {
						switch (customBackgroundType) {
							case BackgroundNormal:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); background-repeat: no-repeat; background-attachment:fixed;", customBackgroundPath]];
							break;
							case BackgroundCenter:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); background-position: center; background-repeat: no-repeat; background-attachment:fixed;", customBackgroundPath]];
							break;
							case BackgroundTile:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); background-repeat: repeat;", customBackgroundPath]];
							break;
							case BackgroundTileCenter:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); background-repeat: repeat; background-position: center;", customBackgroundPath]];
							break;
							case BackgroundScale:
								[bodyTag appendString:[NSString stringWithFormat:@"background-image: url('%@'); -webkit-background-size: 100%% 100%%; background-size: 100%% 100%%; background-attachment: fixed;", customBackgroundPath]];
							break;
						}
					} else {
						[bodyTag appendString:@"background-image: none; "];
					}
				}
				if (customBackgroundColor) {
					CGFloat red, green, blue, alpha;
					[customBackgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
					[bodyTag appendString:[NSString stringWithFormat:@"background-color: rgba(%ld, %ld, %ld, %f); ", (NSInteger)(red * 255.0), (NSInteger)(green * 255.0), (NSInteger)(blue * 255.0), alpha]];
				}
 			}

			//Replace the body background tag
 			[inString safeReplaceCharactersInRange:range withString:(bodyTag ? (NSString *)bodyTag : @"")];
 		}
 	}

	if ([inString rangeOfString:@"%variant%"].location != NSNotFound) {
		/* Per #12702, don't allow spaces in the variant name, as otherwise it becomes multiple css classes */
		[inString replaceKeyword:@"%variant%"
					  withString:[self.activeVariant stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
	}

	return inString;
}

#pragma mark Icons

- (NSString *)iconPathForFileTransfer:(ESFileTransfer *)inObject
{
	NSString	*filename = [NSString stringWithFormat:@"TEMP-%@%@.tiff", [inObject uniqueID], [NSString randomStringOfLength:5]];
	return [[adium cachesPath] stringByAppendingPathComponent:filename];
}

- (NSString *)statusIconPathForListObject:(AIListObject *)inObject
{
	if(!statusIconPathCache) statusIconPathCache = [[NSMutableDictionary alloc] init];
	NSImage *icon = [AIStatusIcons statusIconForListObject:inObject
													  type:AIStatusIconTab
												 direction:AIIconNormal];
	NSString *statusName = [AIStatusIcons statusNameForListObject:inObject];
	if(!statusName)
		statusName = @"UnknownStatus";
	NSString *path = [statusIconPathCache objectForKey:statusName];
	if(!path)
	{
		path = [[adium cachesPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"TEMP-%@%@.tiff", statusName, [NSString randomStringOfLength:5]]];
		[[icon TIFFRepresentation] writeToFile:path atomically:YES];
		[statusIconPathCache setObject:path forKey:statusName];
	}

	return path;
}

@end
