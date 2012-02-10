//
//  AXCServiceIconPackDocument.m
//  XtrasCreator
//
//  Created by Mac-arena the Bored Zo on 2005-10-30.
//  Copyright 2005 Adium Team. All rights reserved.
//

#import "AXCServiceIconPackDocument.h"
#import "AXCIconPackEntry.h"

@implementation AXCServiceIconPackDocument

- (NSString *) OSType {
	return @"AISr";
}
- (NSString *) pathExtension {
	return @"AdiumServiceIcons";
}
- (NSString *) uniformTypeIdentifier {
	return @"com.adiumx.serviceicons";
}

- (NSArray *) categoryNames {
	return [NSArray arrayWithObjects:
		@"Interface-Large", @"Interface-Small", @"List",
		nil];
}

- (NSArray *) entriesForNewDocumentInCategory:(NSString *)categoryName {
	return [NSArray arrayWithObjects:
		[AXCIconPackEntry entryWithKey:@"AIM"          path:nil],
		[AXCIconPackEntry entryWithKey:@"Bonjour"      path:nil],
		[AXCIconPackEntry entryWithKey:@"Gadu-Gadu"    path:nil],
		[AXCIconPackEntry entryWithKey:@"GroupWise"    path:nil],
		[AXCIconPackEntry entryWithKey:@"GTalk"        path:nil],
		[AXCIconPackEntry entryWithKey:@"ICQ"          path:nil],
		[AXCIconPackEntry entryWithKey:@"Jabber"       path:nil],
		[AXCIconPackEntry entryWithKey:@"Mac"          path:nil],
		[AXCIconPackEntry entryWithKey:@"MSN"          path:nil],
		[AXCIconPackEntry entryWithKey:@"Napster"      path:nil],
		[AXCIconPackEntry entryWithKey:@"Sametime"     path:nil],
		[AXCIconPackEntry entryWithKey:@"Stress Test"  path:nil],
		[AXCIconPackEntry entryWithKey:@"Trepia"       path:nil],
		[AXCIconPackEntry entryWithKey:@"Yahoo!"       path:nil],
		[AXCIconPackEntry entryWithKey:@"Yahoo! Japan" path:nil],
		[AXCIconPackEntry entryWithKey:@"Zephyr"       path:nil],
		nil];
}

@end
