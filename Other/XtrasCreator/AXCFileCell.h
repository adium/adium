//
//  AXCFileCell.h
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

/*the string/object values to an AXCFileCell are paths. they will be drawn as
 *	an icon and filename.
 */

enum AXCFileCellIconSourceMask {
	AXCFileCellIconSourcePreviewByFullPathMask = 0x01,
	AXCFileCellIconSourcePreviewByFilenameMask = 0x02,
	AXCFileCellIconSourceLookupByFileIconMask  = 0x04,
	AXCFileCellIconSourceAll = 0xffffFFFF,
};

@interface AXCFileCell : NSCell {
	union {
		enum AXCFileCellIconSourceMask iconSourceMask;
		struct {
			//note: these variables need to be in the reverse order of the order of the enumeration above.
			unsigned reserved: 29;
			unsigned getPreviewsFromFileIcons: 1;
			unsigned getPreviewsByFilename: 1;
			unsigned getPreviewsByFullPath: 1;
		} iconSourceBitfield;
	} iconSource;
}

- (enum AXCFileCellIconSourceMask)iconSourceMask;
- (void)setIconSourceMask:(enum AXCFileCellIconSourceMask)mask;

//These are the methods that the cell uses to determine the icon and filename that it should draw. You can override them in subclasses. The cell calls them with its current object value, which (in AXCFileCell) is a path.
- (NSImage *) iconForObjectValue:(id)objValue;
- (NSString *) filenameForObjectValue:(id)objectValue;

@end
