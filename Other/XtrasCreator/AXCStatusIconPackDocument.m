//
//  AXCStatusIconPackDocument.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCStatusIconPackDocument.h"
#import "AXCIconPackEntry.h"

@implementation AXCStatusIconPackDocument

- (NSString *) OSType {
	return @"AISt";
}
- (NSString *) pathExtension {
	return @"AdiumStatusIcons";
}
- (NSString *) uniformTypeIdentifier {
	return @"com.adiumx.statusicons";
}

- (NSArray *) categoryNames {
	return [NSArray arrayWithObjects:
		@"List", @"Tabs",
		nil];
}

- (NSArray *) entriesForNewDocumentInCategory:(NSString *)categoryName {
	return [NSArray arrayWithObjects:
		[AXCIconPackEntry entryWithKey:@"Generic Available" path:nil],
		[AXCIconPackEntry entryWithKey:@"Generic Away"      path:nil],
		[AXCIconPackEntry entryWithKey:@"Idle"              path:nil],
		[AXCIconPackEntry entryWithKey:@"Invisible"         path:nil],
		[AXCIconPackEntry entryWithKey:@"Mobile"            path:nil],
		[AXCIconPackEntry entryWithKey:@"Offline"           path:nil],
		[AXCIconPackEntry entryWithKey:@"Unknown"           path:nil],
		[AXCIconPackEntry entryWithKey:@"content"           path:nil],
		[AXCIconPackEntry entryWithKey:@"enteredtext"       path:nil],
		[AXCIconPackEntry entryWithKey:@"typing"            path:nil],
		nil];
}

@end
