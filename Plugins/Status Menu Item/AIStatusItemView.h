//
//  AIStatusItemView.h
//  Adium
//
//  Created by Zachary West on 2008-05-22.
//

#import "AIImageTextCellView.h"

@interface AIStatusItemView : AIImageTextCellView {
	NSStatusItem			*statusItem;
	
	BOOL					mouseDown;
	
	NSImage					*regularImage;
	NSImage					*alternateImage;
	
	NSMenu					*menu;
	NSMenu					*alternateMenu;
}

@property(readonly) NSUInteger desiredWidth;

@property(copy) NSImage *regularImage;
@property(copy) NSImage *alternateImage;

//These are by retain in case you want to set a delegate for the menu.
@property(retain) NSMenu *menu;
@property(retain) NSMenu *alternateMenu;

@property(assign) NSStatusItem *statusItem;

@end
