//
//  NSFileManager+BundleBit.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-31.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "NSFileManager+BundleBit.h"

#include <Carbon/Carbon.h>

union FinderInfoTransmuter {
	UInt8 *bytes;
	struct FileInfo *finderInfo;
};

@implementation NSFileManager (BundleBit)

- (BOOL) bundleBitOfFile:(NSString *)path {
	BOOL value = NO;

	const char *pathFSR = [path fileSystemRepresentation];
	FSRef ref;
	OSStatus err = FSPathMakeRef((const UInt8 *)pathFSR, &ref, /*isDirectory*/ NULL);
	if (err == noErr) {
		struct FSCatalogInfo catInfo;
		union FinderInfoTransmuter finderInfoPointers = { .bytes = catInfo.finderInfo };

		err = FSGetCatalogInfo(&ref,
							   kFSCatInfoFinderInfo,
							   &catInfo,
							   /*outName*/ NULL,
							   /*FSSpec*/ NULL,
							   /*parentRef*/ NULL);
		if (err == noErr) {
			value = (finderInfoPointers.finderInfo->finderFlags) & kHasBundle;
		}
	}

	return value;
}
- (void) setBundleBitOfFile:(NSString *)path toBool:(BOOL)newValue {
	const char *pathFSR = [path fileSystemRepresentation];
	FSRef ref;
	OSStatus err = FSPathMakeRef((const UInt8 *)pathFSR, &ref, /*isDirectory*/ NULL);
	if (err == noErr) {
		struct FSCatalogInfo catInfo;
		union FinderInfoTransmuter finderInfoPointers = { .bytes = catInfo.finderInfo };

		err = FSGetCatalogInfo(&ref,
							   kFSCatInfoFinderInfo,
							   &catInfo,
							   /*outName*/ NULL,
							   /*FSSpec*/ NULL,
							   /*parentRef*/ NULL);
		if (err == noErr) {
			if (newValue)
				finderInfoPointers.finderInfo->finderFlags |=  kHasBundle;
			else
				finderInfoPointers.finderInfo->finderFlags &= ~kHasBundle;

			FSSetCatalogInfo(&ref,
							 kFSCatInfoFinderInfo,
							 &catInfo);
		}
	}
}

@end
