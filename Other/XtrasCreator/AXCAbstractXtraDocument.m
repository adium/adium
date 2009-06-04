//
//  AXCAbstractXtraDocument.m
//  XtrasCreator
//
//  Created by David Smith on 10/27/05.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCAbstractXtraDocument.h"

#import "AXCFileCell.h"
#import "IconFamily.h"
#import "NSFileManager+BundleBit.h"
#import "NSMutableArrayAdditions.h"

#define THUMBNAIL_SIZE 16.0

@implementation AXCAbstractXtraDocument

- (id)init
{
	if ((self = [super init])) {
		resources = [[NSMutableArray alloc] init];
		resourcesSet = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[name release];
	[author release];
	[version release];
	[icon release];
	
	[resources release];
	[resourcesSet release];

	[super dealloc];
}

#pragma mark -

- (NSString *) absolutePathForFile:(NSString *)path
{
	if ([path isAbsolutePath])
		return path;
	else
		return [[bundle resourcePath] stringByAppendingPathComponent:path];
}

- (NSImage *) previewForFile:(NSString *)path
{
	NSImage *image = [imagePreviews objectForKey:path];
	if (!image) {
		image = [[[NSImage alloc] initWithContentsOfFile:[self absolutePathForFile:path]] autorelease];
		NSSize size = [image size]; //note: only used if image != nil
		if (image) {
			if (!imagePreviews)
				imagePreviews = [[NSMutableDictionary alloc] init];
			
			NSSize previewSize = size;
			float maxDimension = MAX(size.width, size.height);
			if (maxDimension > THUMBNAIL_SIZE) {
				//scale proportionally to Wx16 or 16xH.
				float scale = maxDimension / THUMBNAIL_SIZE;
				previewSize.width  /= scale;
				previewSize.height /= scale;
				[image setScalesWhenResized:YES];
				[image setSize:previewSize];
			}
			[image setFlipped:YES];
			[image setName:[@"Preview of " stringByAppendingString:path]];
			
			[imagePreviews setObject:image forKey:path];
		}
	}	
	return image;
}

#pragma mark -

- (void) addResource:(NSString *)path
{
	[self willChangeValueForKey:@"resources"];

	[resources    addObject:path];
	[resourcesSet addObject:path];

	if ([imagePreviews objectForKey:path])
		[imagePreviews removeObjectForKey:path];
	[displayNames setObject:[[NSFileManager defaultManager] displayNameAtPath:[self absolutePathForFile:path]] forKey:path];

	[self didChangeValueForKey:@"resources"];
}
- (void) addResources:(NSArray *)paths
{
	NSIndexSet *newIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange([resources count], [paths count])];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:newIndexes forKey:@"resources"];

	[resources    addObjectsFromArray:paths];
	[resourcesSet addObjectsFromArray:paths];
	
	//add the files to the imagePreviews and displayNames dictionaries.
	NSEnumerator *pathsEnum = [paths objectEnumerator];
	NSString *path;
	while ((path = [pathsEnum nextObject])) {
		//first the image preview
		NSImage *image = [self previewForFile:path];

		/*now store the display name as well*/ {
			if (!displayNames)
				displayNames = [[NSMutableDictionary alloc] init];

			NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:[self absolutePathForFile:path]];
			if (image) {
				enum { MULTIPLICATION_SIGN = 0x00d7 };
				NSSize size = [image size];
				displayName = [NSString stringWithFormat:@"%@ (%u%C%u)", displayName, (unsigned)size.width, MULTIPLICATION_SIGN, (unsigned)size.height];
			}

			[displayNames setObject:displayName forKey:path];
		}
	}
	
	[self didChangeValueForKey:@"resources"];
}

- (void) removeResource:(NSString *)path
{
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[resources indexOfObject:path]];
	[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"resources"];

	[resources    removeObject:path];
	[resourcesSet removeObject:path];

	if ([imagePreviews objectForKey:path])
		[imagePreviews removeObjectForKey:path];
	[displayNames removeObjectForKey:path];

	[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"resources"];
}
- (void) removeResources:(NSArray *)paths
{
	//XXX should look at using NSKeyValueChangeRemoval here
	[self willChangeValueForKey:@"resources"];
	[resources removeObjectsInArray:paths];

	NSSet *temp = [[NSSet alloc] initWithArray:paths];
	[resourcesSet minusSet:temp];
	[temp release];

	[imagePreviews removeObjectsForKeys:paths];
	[displayNames  removeObjectsForKeys:paths];

	[self didChangeValueForKey:@"resources"];
}

- (void) setResources:(NSArray *)newResources
{
	NSSet *temp = [[NSSet alloc] initWithArray:newResources];
	
	NSMutableSet *resourcesBeingAdded = [temp mutableCopy];
	[resourcesBeingAdded minusSet:resourcesSet];
	NSMutableSet *resourcesBeingRemoved = [resourcesSet mutableCopy];
	[resourcesBeingRemoved minusSet:temp];
	
	[temp release];
	
	[self removeResources:[resourcesBeingRemoved allObjects]];
	[self    addResources:[resourcesBeingAdded   allObjects]];
}

#pragma mark -

- (NSString *)windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
    [super windowControllerDidLoadNib:controller];

	/*set up cell in table view*/ {
		AXCFileCell *cell = [[AXCFileCell alloc] initTextCell:@""];
		[[[fileView tableColumns] objectAtIndex:0U] setDataCell:cell];
		[cell release];
	}

	/*set up table view the drag types*/ {
		[fileView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	}

	/*fill in tab view*/ {
		NSEnumerator * tabViewItemsEnum = [[self tabViewItems] objectEnumerator];
		NSTabViewItem * item;
		while((item = [tabViewItemsEnum nextObject]))
			[tabs addTabViewItem:item];
	}
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)docType
{
	NSString * bundlePath = fileName;
	NSFileManager * manager = [NSFileManager defaultManager];
	if(![manager fileExistsAtPath:bundlePath])
	{
		[manager createDirectoryAtPath:bundlePath attributes:nil];

		NSString *contentsPath = [bundlePath stringByAppendingPathComponent:@"Contents"];
		[manager createDirectoryAtPath:contentsPath attributes:nil];

		NSDictionary *infoPlist = [self infoPlistDictionary];
		[infoPlist writeToFile:[contentsPath stringByAppendingPathComponent:@"Info.plist"] atomically:YES];

		NSString *resourcesPath = [contentsPath stringByAppendingPathComponent:@"Resources"];
		[manager createDirectoryAtPath:resourcesPath attributes:nil];

		NSEnumerator * resourceEnu = [resources objectEnumerator];
		NSString * resourcePath;
		while ((resourcePath = [resourceEnu nextObject]))
		{
			NSString *resourceSrcPath = nil;
			if ([manager fileExistsAtPath:resourcePath])
				resourceSrcPath = resourcePath;
			else {
				NSString *resourceFilename = [resourcePath lastPathComponent];
				resourceSrcPath = [bundle pathForResource:[resourceFilename stringByDeletingPathExtension] ofType:[resourceFilename pathExtension]];
			}
			resourceSrcPath = [resourceSrcPath stringByStandardizingPath];

			NSString *resourceDestPath = [resourcesPath stringByAppendingPathComponent:[resourcePath lastPathComponent]];

			//if these are not the same file...
			if (![resourceSrcPath isEqualToString:resourceDestPath]) {
				[manager copyPath:resourceSrcPath 
						   toPath:resourceDestPath
						  handler:nil];
			}
		}

		IconFamily* iconFamily = [IconFamily iconFamilyWithThumbnailsOfImage:icon]; //check on error handling for this
		[iconFamily setAsCustomIconForFile:fileName];

		NSRange readmeRange = { 0, [[readmeView textStorage] length] };
		if ([readmeView isRichText])
			[[readmeView RTFFromRange:readmeRange] writeToFile:[resourcesPath stringByAppendingPathComponent:@"ReadMe.rtf"] atomically:YES];
		else
			[[[readmeView string] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:[resourcesPath stringByAppendingPathComponent:@"ReadMe.txt"] atomically:YES];

		//all Xtras are bundles
		[manager setBundleBitOfFile:bundlePath toBool:YES];

		return YES;
	}	
	else
		return NO;
}
- (BOOL)writeToURL:(NSURL *)URL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSString * path = [URL path];
	return [self writeToFile:path ofType:typeName];
}

- (BOOL) readFromFile:(NSString *)path ofType:(NSString *)type
{
	NSBundle *bundleAtPath = [NSBundle bundleWithPath:path];
	if (bundleAtPath && ([[bundleAtPath objectForInfoDictionaryKey:@"XtraBundleVersion"] intValue] == 1)) {
		NSString *bundleName = [bundleAtPath objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
		NSString *bundleAuthor = [bundleAtPath objectForInfoDictionaryKey:@"XtraAuthors"];
		if (bundleName && bundleAuthor) {
			[bundle release];
			bundle = [bundleAtPath retain];

			[self setName:bundleName];
			[self setAuthor:bundleAuthor];
			[self setVersion:[bundle objectForInfoDictionaryKey:@"XtraVersion"]];
			[self setBundleID:[bundle objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey]];

			[self setResources:[[NSFileManager defaultManager] directoryContentsAtPath:[bundle resourcePath]]];

			BOOL isRichText = YES;
			NSString *readmePath = [bundle pathForResource:@"ReadMe" ofType:@"rtf"];
			if (!readmePath) {
				readmePath = [bundle pathForResource:@"ReadMe" ofType:@"rtfd"];
				if (!readmePath) {
					readmePath = [bundle pathForResource:@"ReadMe" ofType:@"txt"];
					isRichText = NO;
				}
			}
			if (readmePath) {
				NSAttributedString *readmeTemp;
				if (isRichText) {
					readmeTemp = [[NSAttributedString alloc] initWithPath:readmePath documentAttributes:nil];
				} else {
					NSData *plainTextData = [[NSData alloc] initWithContentsOfFile:readmePath];
					NSString *plainText = [[NSString alloc] initWithData:plainTextData encoding:NSUTF8StringEncoding];
					readmeTemp = [[NSAttributedString alloc] initWithString:plainText];
					[plainText release];
					[plainTextData release];
				}

				[self willChangeValueForKey:@"readme"];
				readme = readmeTemp;
				[self  didChangeValueForKey:@"readme"];

				[self removeResource:[readmePath lastPathComponent]];
			}

			return YES;
		}
	}
	else {
		//XXX This code will be hit if they open an old-format xtra, so it'd be cool if we could offer to upgrade it.
	}
    return NO;
}

- (void) printShowingPrintPanel:(BOOL)flag
{
	//XXX TEMP - should make a new view that grabs all the information from this document, and displays it linearly
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:fileView];
	[op setShowsPrintPanel:flag];
	[op runOperation];
}

- (IBAction) runAddFilesPanel:(id)sender
{
	NSOpenPanel * p = [NSOpenPanel openPanel];
	[p setAllowsMultipleSelection:YES];
	[p beginSheetForDirectory:nil
						 file:nil
						types:[self validResourceTypes]
			   modalForWindow:[self windowForSheet]
				modalDelegate:self
			   didEndSelector:@selector(didEndAddFilesPanel:returnCode:contextInfo:)
				  contextInfo:NULL];
}

- (void) didEndAddFilesPanel:(NSOpenPanel *)p returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton)
		return;

	NSArray *newFiles = [p filenames];
	NSMutableSet *newFilesSet = [NSMutableSet setWithArray:newFiles];
	//remove from newFilesSet all the files that we already have added.
	NSMutableSet *temp = [resourcesSet mutableCopy];
	[temp intersectSet:newFilesSet];
	[newFilesSet minusSet:temp];
	[temp release];

	if ([newFilesSet count]) {
		newFiles = [newFilesSet allObjects];

		[self addResources:newFiles];
	}
}

- (IBAction) runChooseIconPanel:(id)sender
{
	NSOpenPanel * p = [NSOpenPanel openPanel];
	[p setAllowsMultipleSelection:YES];
	[p beginSheetForDirectory:nil
						 file:nil
						types:[NSImage imageFileTypes]
			   modalForWindow:[self windowForSheet]
				modalDelegate:self
			   didEndSelector:@selector(didEndChooseIconPanel:returnCode:contextInfo:)
				  contextInfo:NULL];
}

- (void) didEndChooseIconPanel:(NSOpenPanel *)p returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode != NSOKButton)
		return;

	[self setIcon:[[[NSImage alloc] initByReferencingFile:[[p filenames] objectAtIndex:0]]autorelease]];
}

#pragma mark -

- (void) setName:(NSString *)newName
{
	[name release];
	name = [newName copy];
}
- (NSString *) name
{
	return name;
}

- (void) setAuthor:(NSString *)newAuthor
{
	[author release];
	author = [newAuthor copy];
}
- (NSString *) author
{
	return author;
}

- (void) setVersion:(NSString *)newVersion
{
	[version release];
	version = [newVersion copy];
}
- (NSString *) version
{
	return version;
}

- (void) setBundleID:(NSString *)newBundleID
{
	[bundleID release];
	bundleID = [newBundleID copy];
}
- (NSString *) bundleID
{
	return bundleID;
}

- (void) setReadme:(NSAttributedString *)newReadme
{
	[readme release];
	readme = [newReadme copy];
}
- (NSAttributedString *) readme
{
	return readme;
}

- (void) setIcon:(NSImage *)inImage
{
	[icon autorelease];
	icon = [inImage retain];
}

- (NSImage *) icon
{
	return icon;
}

#pragma mark -

- (NSString *) OSType
{
	return @"AdIM";
}
- (NSString *) pathExtension
{
	return nil;
}
- (NSString *) uniformTypeIdentifier
{
	return @"com.adiumx.xtra";
}

- (NSArray *) validResourceTypes
{
	return nil;
}

- (NSDictionary *) infoPlistDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"English", kCFBundleDevelopmentRegionKey,
		name, kCFBundleNameKey,
		[self OSType], @"CFBundlePackageType",
		bundleID, kCFBundleIdentifierKey,
		[NSNumber numberWithInt:1], @"XtraBundleVersion",
		@"1.0", kCFBundleInfoDictionaryVersionKey,
		version, @"XtraVersion",
		author, @"XtraAuthors",
		nil];
}

//added to the tab view.
- (NSArray *) tabViewItems
{
	return [NSArray array];
}

#pragma mark -
#pragma mark Table-view drag validation (for resources)

- (NSDragOperation) validateDragWithInfo:(id <NSDraggingInfo>)info operation:(NSTableViewDropOperation)operation
{
	NSArray *filenames = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if (filenames) {
		NSSet *validTypes = [NSSet setWithArray:[self validResourceTypes]];
		if (validTypes) {
			//iterate on the array until we find an invalid type. if we do, this drag fails.
			NSEnumerator *filenamesEnum = [filenames objectEnumerator];
			NSString *path;
			while ((path = [filenamesEnum nextObject])) {
				if (![validTypes containsObject:[path pathExtension]])
					goto fail;
				//XXX OSTypes
			}

			//no failure: all the files are valid to be dropped.
			return NSDragOperationCopy;
		}
	}

fail:
	return NSDragOperationNone;
}

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	int thisDrag = [info draggingSequenceNumber];
	if (lastDrag != thisDrag) {
		//this is a new drag. validate it.
		lastDragOperation = [self validateDragWithInfo:info operation:operation];
		lastDrag = thisDrag;
	}

	if ((lastDragOperation != NSDragOperationNone) && (operation == NSTableViewDropOn)) {
		NSArray *filenames = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		if ([filenames count] == 1)
			row = [resources indexForInsortingObject:[filenames objectAtIndex:0U] usingSelector:@selector(caseInsensitiveCompare:)];
		else {
			//retarget to either above or below.
			NSPoint location = [info draggingLocation];
			NSRect rowRect = [tableView rectOfRow:row];
			
			//make this relative to the row rect. (we don't care about x.)
			location.y -= rowRect.origin.y;
			//compare the y-coord to the height of the row. if below the middle, drop below the row; else, drop above it.
			if (location.y > (rowRect.size.height / 2.0))
				++row;
		}	
		
		[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
	return lastDragOperation;
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSArray *filenames = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];

	//XXX insort
	[self addResources:filenames];

	return YES;
}

@end
