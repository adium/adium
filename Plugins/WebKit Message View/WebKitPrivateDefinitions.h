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

#import <WebKit/WebKit.h>

@interface NSScrollView (NSScrollViewWebKitPrivate)
- (void) setAllowsHorizontalScrolling:(BOOL) allow;
@end

@interface WebCoreScrollView:NSScrollView
{
}

- (void)scrollWheel:fp8;

@end

@protocol WebCoreFrameView
- (void)setScrollBarsSuppressed:(char)fp8 repaintOnUnsuppress:(char)fp12;
- (NSInteger)verticalScrollingMode;
- (NSInteger)horizontalScrollingMode;
- (void)setScrollingMode:(NSInteger)fp8;
- (void)setVerticalScrollingMode:(NSInteger)fp8;
- (void)setHorizontalScrollingMode:(NSInteger)fp8;
@end

@interface WebDynamicScrollBarsView:WebCoreScrollView <WebCoreFrameView>
{
    NSInteger hScroll;
    NSInteger vScroll;
    char suppressLayout;
    char suppressScrollers;
    char inUpdateScrollers;
}

- (void)setSuppressLayout:(char)fp8;
- (void)setScrollBarsSuppressed:(char)fp8 repaintOnUnsuppress:(char)fp12;
- (void)updateScrollers;
- (void)reflectScrolledClipView:fp8;
- (void)setAllowsScrolling:(char)fp8;
- (char)allowsScrolling;
- (void)setAllowsHorizontalScrolling:(char)fp8;
- (void)setAllowsVerticalScrolling:(char)fp8;
- (char)allowsHorizontalScrolling;
- (char)allowsVerticalScrolling;
- (NSInteger)horizontalScrollingMode;
- (NSInteger)verticalScrollingMode;
- (void)setHorizontalScrollingMode:(NSInteger)fp8;
- (void)setVerticalScrollingMode:(NSInteger)fp8;
- (void)setScrollingMode:(NSInteger)fp8;

@end

@interface WebFrameViewPrivate:NSObject
{
    WebView *webView;
    WebDynamicScrollBarsView *frameScrollView;
    NSInteger marginWidth;
    NSInteger marginHeight;
    NSArray *draggingTypes;
    char hasBorder;
}

- init;
- (void)dealloc;

@end


@interface WebHTMLView:NSView <WebDocumentView, WebDocumentSearching, WebDocumentText>
{
    id  _private;
}

+ (void)initialize;
- initWithFrame:(struct _NSRect)fp8;
- (void)dealloc;
- (char)hasSelection;
- (void)takeFindStringFromSelection:fp8;
- (void)copy:fp8;
- (char)writeSelectionToPasteboard:fp8 types:fp12;
- (void)selectAll:fp8;
- (void)jumpToSelection:fp8;
- (char)validateUserInterfaceItem:fp8;
- validRequestorForSendType:fp8 returnType:fp12;
- (char)acceptsFirstResponder;
- (void)updateTextBackgroundColor;
- (void)addMouseMovedObserver;
- (void)removeMouseMovedObserver;
- (void)updateFocusRing;
- (void)addSuperviewObservers;
- (void)removeSuperviewObservers;
- (void)addWindowObservers;
- (void)removeWindowObservers;
- (void)viewWillMoveToSuperview:fp8;
- (void)viewDidMoveToSuperview;
- (void)viewWillMoveToWindow:fp8;
- (void)viewDidMoveToWindow;
- (void)viewWillMoveToHostWindow:fp8;
- (void)viewDidMoveToHostWindow;
- (void)addSubview:fp8;
- (void)reapplyStyles;
- (void)layoutToMinimumPageWidth:(CGFloat)fp8 maximumPageWidth:(CGFloat)fp12 adjustingViewSize:(char)fp16;
- (void)layout;
- menuForEvent:fp8;
- (char)searchFor:fp8 direction:(char)fp12 caseSensitive:(char)fp16 wrap:(char)fp20;
- string;
- attributedString;
- selectedString;
- selectedAttributedString;
- (void)selectAll;
- (void)deselectAll;
- (void)deselectText;
- (char)isOpaque;
- (void)setNeedsDisplay:(char)fp8;
- (void)setNeedsLayout:(char)fp8;
- (void)setNeedsToApplyStyles:(char)fp8;
- (void)drawRect:(struct _NSRect)fp8;
- (struct _NSRect)visibleRect;
- (char)isFlipped;
- (void)windowDidBecomeKey:fp8;
- (void)windowDidResignKey:fp8;
- (void)windowWillClose:fp8;
- (char)_isSelectionEvent:fp8;
- (char)acceptsFirstMouse:fp8;
- (char)shouldDelayWindowOrderingForEvent:fp8;
- (void)mouseDown:fp8;
- (void)dragImage:fp8 at:(struct _NSPoint)fp12 offset:(struct _NSSize)fp20 event:fp28 pasteboard:fp32 source:fp36 slideBack:(char)fp40;
- (void)mouseDragged:fp8;
- (NSUInteger)draggingSourceOperationMaskForLocal:(char)fp8;
- (void)draggedImage:fp8 endedAt:(struct _NSPoint)fp12 operation:(NSUInteger)fp20;
- namesOfPromisedFilesDroppedAtDestination:fp8;
- (void)mouseUp:fp8;
- (void)mouseMovedNotification:fp8;
- (char)supportsTextEncoding;
- nextKeyView;
- previousKeyView;
- nextValidKeyView;
- previousValidKeyView;
- (char)becomeFirstResponder;
- (char)resignFirstResponder;
- (void)setDataSource:fp8;
- (void)dataSourceUpdated:fp8;
- (void)_setPrinting:(char)fp8 minimumPageWidth:(CGFloat)fp12 maximumPageWidth:(CGFloat)fp16 adjustViewSize:(char)fp20;
- (void)adjustPageHeightNew:(CGFloat *)fp8 top:(CGFloat)fp12 bottom:(CGFloat)fp16 limit:(CGFloat)fp20;
- (CGFloat)_availablePaperWidthForPrintOperation:fp8;
- (CGFloat)_userScaleFactorForPrintOperation:fp8;
- (CGFloat)_scaleFactorForPrintOperation:fp8;
- (CGFloat)_provideTotalScaleFactorForPrintOperation:fp8;
- (char)knowsPageRange:(struct _NSRange *)fp8;
- (struct _NSRect)rectForPage:(NSInteger)fp8;
- (CGFloat)_calculatePrintHeight;
- (void)endDocument;
- (void)_updateTextSizeMultiplier;
- (void)keyDown:fp8;
- (void)keyUp:fp8;
- accessibilityAttributeValue:fp8;
- accessibilityHitTest:(struct _NSPoint)fp8;

@end

@protocol WebPluginContainer <NSObject>
- (void)showStatus:fp8;
- (void)showURL:fp8 inFrame:fp12;
@end

@interface WebPluginController:NSObject <WebPluginContainer>
{
    id				_HTMLView;
    NSMutableArray *_views;
    char _started;
}

- initWithHTMLView:fp8;
- (void)startAllPlugins;
- (void)stopAllPlugins;
- (void)addPlugin:fp8;
- (void)destroyAllPlugins;
- (void)showURL:fp8 inFrame:fp12;
- (void)showStatus:fp8;

@end

@interface NSPasteboard(NSTypeConversion)
+ _cocoaTypeNameFromIdentifier:(struct __CFString *)fp8;
+ (struct __CFString *)_typeIdentifierFromCocoaName:fp8;
#warning 64BIT: Inspect use of unsigned long
+ (struct __CFString *)_typeIdentifierFromCarbonCode:(unsigned long)fp8;
+ _typesIncludingConversionsFromTypes:fp8;
#warning 64BIT: Inspect use of long
+ (void)_setConversionFromData:fp8 type:fp12 inPasteboard:(struct __CFPasteboard *)fp16 generation:(long)fp20 item:(void *)fp24;
- _dataWithConversionForType:fp8;
- (void)_addConversionsFromTypes:fp8;
@end
