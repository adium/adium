//
//  ESPresetManagementController.h
//  Adium
//
//  Created by Evan Schoenberg on 3/14/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>
#import <Adium/AILocalizationButton.h>

@interface ESPresetManagementController : AIWindowController {
	IBOutlet		NSTableView		*tableView_presets;

	IBOutlet		NSTextField		*label_editPresets;
	IBOutlet		AILocalizationButton		*button_duplicate;
	IBOutlet		AILocalizationButton		*button_delete;
	IBOutlet		AILocalizationButton		*button_rename;
	IBOutlet		AILocalizationButton		*button_done;
	
	NSArray			*presets;
	NSString		*nameKey;
	
	id				delegate;
	
	NSDictionary	*tempDragPreset;
}

+ (void)managePresets:(NSArray *)inPresets namedByKey:(NSString *)inNameKey onWindow:(NSWindow *)parentWindow withDelegate:(id)inDelegate;

- (IBAction)duplicatePreset:(id)sender;
- (IBAction)deletePreset:(id)sender;
- (IBAction)renamePreset:(id)sender;

@end

@interface NSObject (ESPresetManagementControllerDelegate)
- (NSArray *)renamePreset:(NSDictionary *)preset toName:(NSString *)newName inPresets:(NSArray *)presets renamedPreset:(id *)renamedPreset;
- (NSArray *)duplicatePreset:(NSDictionary *)preset inPresets:(NSArray *)presets createdDuplicate:(id *)duplicatePreset;
- (NSArray *)deletePreset:(NSDictionary *)preset inPresets:(NSArray *)presets;
@end

@interface NSObject (ESPresetManagementControllerDelegate_Optional)
- (NSArray *)movePreset:(NSDictionary *)preset
				toIndex:(int)index
			  inPresets:(NSArray *)presets
		presetAfterMove:(id *)presetAfterMove;
- (BOOL)allowDeleteOfPreset:(NSDictionary *)preset;
- (BOOL)allowRenameOfPreset:(NSDictionary *)preset;
@end
