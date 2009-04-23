//
//  AIPasteboardAdditions.h
//  AIUtilities.framework
//
//  Created by Evan Schoenberg on 5/26/08.
//

#define AIiTunesTrackPboardType @"CorePasteboardFlavorType 0x6974756E" /* CorePasteboardFlavorType 'itun' */

@interface NSPasteboard (AIPasteboardAdditions)
- (NSArray *)filesFromITunesDragPasteboard;
@end
