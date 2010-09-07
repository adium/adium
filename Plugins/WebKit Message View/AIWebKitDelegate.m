//
//  AIWebKitDelegate.m
//  Adium
//
//  Created by David Smith on 5/9/07.
//

#import "AIWebKitDelegate.h"
#import "AIWebKitMessageViewController.h"
#import "ESWebView.h"
#import "AIURLHandlerPlugin.h"
#import "AIEventAdditions.h"

static AIWebKitDelegate *AISharedWebKitDelegate;

@interface AIWebKitMessageViewController (DelegateCallbacks)
- (void)webViewIsReady;
@end

@implementation AIWebKitDelegate

- (id)init 
{
	if ((self = [super init]))  {
		mapping = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[mapping release];

	[super dealloc];
}

+ (AIWebKitDelegate *)sharedWebKitDelegate
{
	if(!AISharedWebKitDelegate)
		AISharedWebKitDelegate = [[self alloc] init];
	return AISharedWebKitDelegate;
}

- (void) addDelegate:(AIWebKitMessageViewController *)controller forView:(ESWebView *)webView
{
	[mapping setObject:controller forKey:[NSValue valueWithPointer:webView]];
	
	[webView setFrameLoadDelegate:self];
	[webView setPolicyDelegate:self];
	[webView setUIDelegate:self];
	[webView setDraggingDelegate:self];
	[webView setEditingDelegate:self];
	[webView setResourceLoadDelegate:self];
	
//	[[webView windowScriptObject] setValue:self forKey:@"client"];
}
- (void) removeDelegate:(AIWebKitMessageViewController *)controller
{
	ESWebView *webView = (ESWebView *)[controller messageView];
	
	[webView setFrameLoadDelegate:nil];
	[webView setPolicyDelegate:nil];
	[webView setUIDelegate:nil];
	[webView setDraggingDelegate:nil];
	[webView setEditingDelegate:nil];
	[webView setResourceLoadDelegate:nil];
	
	[mapping removeObjectForKey:[NSValue valueWithPointer:webView]];
}

//WebView Delegates ----------------------------------------------------------------------------------------------------
#pragma mark Webview delegates
/*!
* @brief Invoked once the webview has loaded and is ready to accept content
 */
- (void)webView:(ESWebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	if(controller) {
		//Flag the view as ready (as soon as the current methods exit) so we know it's now safe to add content
		[controller performSelector:@selector(webViewIsReady) withObject:nil afterDelay:0];
	}
	
	//We don't care about any further didFinishLoad notifications
	[sender setFrameLoadDelegate:nil];
}

/*!
* @brief Prevent the webview from following external links.  We direct these to the user's web browser.
 */
- (void)webView:(ESWebView *)sender
    decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request
		  frame:(WebFrame *)frame
    decisionListener:(id<WebPolicyDecisionListener>)listener
{
    NSInteger actionKey = [[actionInformation objectForKey: WebActionNavigationTypeKey] integerValue];
    if (actionKey == WebNavigationTypeOther) {
		[listener use];
	} else if ([((NSString *)LSCopyDefaultHandlerForURLScheme((CFStringRef)request.URL.scheme)).lowercaseString isEqualToString:@"com.adiumx.adiumx"]) {
		// We're the default for this URL, let's open it ourself.
		[[NSNotificationCenter defaultCenter] postNotificationName:@"AIURLHandleNotification" object:request.URL.absoluteString];
		
		[listener ignore];
    } else {
		NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
		
		//Ignore file URLs, but open anything else
		if (![url isFileURL]) {
			if ([NSEvent cmdKey]) {
				NSArray *urls = [NSArray arrayWithObject:url]; 
				
				[[NSWorkspace sharedWorkspace] openURLs:urls
								withAppBundleIdentifier:nil
												options:NSWorkspaceLaunchWithoutActivation
						 additionalEventParamDescriptor:nil 
									  launchIdentifiers:nil];
			} else {
				[[NSWorkspace sharedWorkspace] openURL:url]; 
			}
		}
		
		[listener ignore];
    }
}

/*!
* @brief Append our own menu items to the webview's contextual menus
 */
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	if(controller)
		return [controller webView:sender contextMenuItemsForElement:element defaultMenuItems:defaultMenuItems];
	return defaultMenuItems;
}

/*!
* @brief Announce when the window script object is available for modification
 */
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
    AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	if(controller)
        [controller webView:sender didClearWindowObject:windowObject forFrame:frame];
}

/*!
* @brief Dragging entered
 */
- (NSDragOperation)webView:(ESWebView *)sender draggingEntered:(id <NSDraggingInfo>)info
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];

	return controller ? [controller draggingEntered:info] : NSDragOperationNone;
}

/*!
* @brief Dragging updated
 */
- (NSDragOperation)webView:(ESWebView *)sender draggingUpdated:(id <NSDraggingInfo>)info
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	return controller ? [controller draggingUpdated:info] : NSDragOperationNone;
}

/*!
* @brief Handle a drag onto the webview
 * 
 * If we're getting a non-image file, we can handle it immediately.  Otherwise, the drag is the textView's problem.
 */
- (BOOL)webView:(ESWebView *)sender performDragOperation:(id <NSDraggingInfo>)info
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	return controller ? [controller performDragOperation:info] : NO;
}

/*!
* @brief Pass on the prepareForDragOperation if it's not one we're handling in this class
 */
- (BOOL)webView:(ESWebView *)sender prepareForDragOperation:(id <NSDraggingInfo>)info
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	return controller ? [controller prepareForDragOperation:info] : NO;
}

/*!
* @brief Pass on the concludeDragOperation if it's not one we're handling in this class
 */
- (void)webView:(ESWebView *)sender concludeDragOperation:(id <NSDraggingInfo>)info
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	if(controller)
		[controller concludeDragOperation:info];
}

- (BOOL)webView:(ESWebView *)sender shouldHandleDragWithPasteboard:(NSPasteboard *)pasteboard
{
	//AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	//return controller ? [controller shouldHandleDragWithPasteboard:pasteboard] : NO;
	return NO;
}

- (BOOL)webView:(ESWebView *)sender shouldInsertText:(NSString *)text replacingDOMRange:(DOMRange *)range givenAction:(WebViewInsertAction)action
{
	if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
		AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
		if(controller)
			[controller editingDidComplete:range];
		
		// The user pressed return; don't let it be entered into the text.
		return NO;
	} else {
		return YES;
	}
}

- (BOOL)webView:(ESWebView *)sender shouldEndEditingInDOMRange:(DOMRange *)range
{
	AIWebKitMessageViewController *controller = [mapping objectForKey:[NSValue valueWithPointer:sender]];
	if(controller)
		[controller editingDidComplete:range];
	
	return YES;
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
	NSMutableURLRequest *newRequest = [request mutableCopy];
	[newRequest setHTTPShouldHandleCookies:NO];
	return [newRequest autorelease];
}
@end
