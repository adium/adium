//
//  AIStatusItemView.h
//  Adium
//
//  Created by Zachary West on 2008-05-22.
//

#import <Adium/AIAdiumProtocol.h>
#import "AIImageTextCellView.h"

@interface AIStatusItemView : AIImageTextCellView {
	NSStatusItem			*statusItem;
	
	BOOL					mouseDown;
	
	NSImage					*regularImage;
	NSImage					*alternateImage;
	
	NSMenu					*mainMenu;
	NSMenu					*alternateMenu;
}

- (unsigned)desiredWidth;

- (void)setRegularImage:(NSImage *)image;
- (NSImage *)regularImage;
- (void)setAlternateImage:(NSImage *)image;
- (NSImage *)alternateImage;

- (void)setMenu:(NSMenu *)menu;
- (NSMenu *)menu;
- (void)setAlternateMenu:(NSMenu *)menu;
- (NSMenu *)alternateMenu;

- (void)setStatusItem:(NSStatusItem *)statusItem;
- (NSStatusItem *)statusItem;

@end
