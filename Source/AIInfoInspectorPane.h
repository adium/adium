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

#import "AIContactInfoContentController.h"
#import <Adium/AIContactObserverManager.h>

@class AIContactInfoImageViewWithImagePicker, AIDelayedTextField;

@interface AIInfoInspectorPane : NSObject <AIContentInspectorPane, AIListObjectObserver> {	
	
	AIListObject											*displayedObject;
	IBOutlet NSView									*inspectorContentView;

	IBOutlet AIContactInfoImageViewWithImagePicker	*userIcon;
	IBOutlet NSImageView							*statusImage;
	
	IBOutlet NSTextField							*aliasLabel;
	IBOutlet AIDelayedTextField						*contactAlias;
	
	IBOutlet NSTextField							*accountName;
	
	IBOutlet NSTextView								*profileView;
	
	IBOutlet NSProgressIndicator					*profileProgress;
}

//Methods from AIContentInspectorPane protocol defined in AIContactInfoInspectorController.h
-(NSString *)nibName;
-(NSView *)inspectorContentView;
-(void)updateForListObject:(AIListObject *)inObject;

- (IBAction)setAlias:(id)sender;

//Method from AIListObjectObserver protocol defined in AIContactControllerProtocol.h
- (NSSet *)updateListObject:(AIListObject *)inObject keys:(NSSet *)inModifiedKeys silent:(BOOL)silent;

@end
