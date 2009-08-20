//
//  Chat.m
//  Logtastic
//
//  Created by Jan Van Tol on Sat Dec 14 2002.
//  Copyright (c) 2002 Spiny Software. All rights reserved.
//

#import "Chat.h"
#import "InstantMessage.h"
#import "FileAttributes.h"
#import "AddressBookUtils.h"

@implementation Chat

- (id)initWithBuddy:(Buddy *)buddy path:(NSString *)path
{
    self = [super init];
    
    myBuddy = [buddy retain];
	creationDate = [[FileAttributes getCreationDateForPath:path] retain];
    myPath = [path retain];
    
    return self;
}

- (void)setCreationDate:(NSDate *)date
{
    creationDate = date;
    [creationDate retain];
}

//Accessor methods.
- (NSDate *)creationDate
{
    return creationDate;
}

- (Buddy *)buddy
{ 
    return myBuddy;
}

- (NSString *)path
{
    return myPath;
}

//Opens in iChat.
- (void)open
{
    [[NSWorkspace sharedWorkspace] openFile:[myPath stringByExpandingTildeInPath] withApplication:@"iChat"];
}

//Returns a description of the Chat - a nicely formatted date string. We strip the leading zero on the hour so it'll look cleaner.
- (NSString *)description
{
    NSCalendarDate *createdDate = [creationDate dateWithCalendarFormat:@"%c" timeZone:nil];
    NSString *hourWithoutLeadingZero;
    if ([[[createdDate descriptionWithCalendarFormat:@"%I"] substringToIndex:1] isEqualToString:@"0"])
	{
        hourWithoutLeadingZero = [[createdDate descriptionWithCalendarFormat:@"%I"] substringFromIndex:1];
    }
	else
	{
        hourWithoutLeadingZero = [createdDate descriptionWithCalendarFormat:@"%I"];
    }
    
    NSString *dateDescription = [createdDate descriptionWithCalendarFormat:@"%a %b %e %Y, "];
    dateDescription = [dateDescription stringByAppendingString: hourWithoutLeadingZero];
    dateDescription = [dateDescription stringByAppendingString: [createdDate descriptionWithCalendarFormat:@":%M %p"]];
    
    return dateDescription;
}

//Comparison method for sorting by date
- (NSComparisonResult)compareByDate:(Chat *)otherChat
{
    return (NSComparisonResult) - [creationDate compare:[otherChat creationDate]];
}

//Comparison method for sorting by buddy name
- (NSComparisonResult)compareByBuddy:(Chat *)otherChat
{
    return [[myBuddy description] compare:[[otherChat buddy] description]];
}

- (void) loadContents
{
	if (chatContents == nil)
	{
		NSData *chatLog = [[NSData alloc] initWithContentsOfMappedFile:myPath];
		if ([myPath hasSuffix:@".ichat"]) // check for tiger-style chat transcript
		{
			NS_DURING
				chatContents = [[NSKeyedUnarchiver unarchiveObjectWithData:chatLog] retain];
			NS_HANDLER
				NSLog(@"Caught exception from NSKeyedUnarchiver - %@", [localException reason]);
				chatContents = nil;
			NS_ENDHANDLER
			[chatLog release];
		}
		else
		{
			NS_DURING
				chatContents = [[NSUnarchiver unarchiveObjectWithData:chatLog] retain];
			NS_HANDLER
				NSLog(@"Caught exception from NSUnarchiver - %@", [localException reason]);
				chatContents = nil;
			NS_ENDHANDLER
			[chatLog release];
		}
		
		if (![chatContents isKindOfClass:[NSArray class]])
		{
			[chatContents release];
			chatContents = nil;
		}
		
		if (chatContents != nil)
		{
			for (unsigned int i=0; i < [chatContents count]; i++)
			{
				id obj = [chatContents objectAtIndex:i];
				if ([obj isKindOfClass:[NSArray class]])
				{
					instantMessages = [obj retain];
					break;
				}
			}
		}
	}
}

//Search method.
- (BOOL)logContainsString:(NSString *)string
{
 
	[self loadContents];
	
	if (instantMessages != nil)
	{
		//Divide into an array of terms, so we don't search for phrases only. TO DO: More advanced searching, allowing quotes around terms to search for a phrase, and more.
		NSArray *searchTerms = [string componentsSeparatedByString:@" "];

		int foundCount = 0;

		int searchTermsCount = [searchTerms count];
		for (int i=0; i < searchTermsCount; i++)
		{
			NSString *searchTerm = [searchTerms objectAtIndex:i];
			
			for (unsigned int j=0; j < [instantMessages count]; j++)
			{
				InstantMessage *im = [instantMessages objectAtIndex:j];
				
				if (im)
				{
					NSString *searchString = [[im text] string];
					//We use a case-insensitive search, but there could be an option to control this.
					if ([searchString rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound)
					{
						foundCount++;
						break;
					}
				}
			}
			
			if (foundCount >= searchTermsCount)
			{
				return YES;
			}
		}
	}
	
    return NO;
}

- (NSAttributedString *) getFormattedContentsWithSearchTermsHilighted:(NSString *) searchTermsStr firstFoundIndex:(NSInteger *) foundIndex
{
	BOOL firstFound = false;
	
	NSAttributedString *ret = [self getFormattedContents];
	if (searchTermsStr && [searchTermsStr length] > 0)
	{
		NSArray *searchTerms = [searchTermsStr componentsSeparatedByString:@" "];

		NSMutableAttributedString *retWithHilite = [[NSMutableAttributedString alloc] initWithAttributedString:ret];
		NSString *retAsString = [retWithHilite string];
		NSDictionary *colorAttrib = [NSDictionary dictionaryWithObject:[NSColor yellowColor] forKey:NSBackgroundColorAttributeName];
		
		for (unsigned int i=0; i < [searchTerms count]; i++)
		{
			unsigned int strLength = [retAsString length];
			NSString *searchTerm = [searchTerms objectAtIndex:i];
		
			NSRange searchRange = NSMakeRange(0, strLength);
			
			while (true && (searchRange.location + searchRange.length) <= strLength)
			{
				NSRange foundRange = [retAsString rangeOfString:searchTerm options:NSCaseInsensitiveSearch range:searchRange];
				if (foundRange.location == NSNotFound)
					break;
				else
				{					
					searchRange.location = foundRange.location + 1;
					searchRange.length = strLength - searchRange.location;
					
					[retWithHilite addAttributes:colorAttrib range:foundRange];

					if (!firstFound)
					{
						*foundIndex = searchRange.location;
						firstFound = true;
					}
				}
			}
		}
		
		return [retWithHilite autorelease];
	}
	else
	{
		return ret;
	}
}

- (NSAttributedString *) getFormattedContents
{
	[self loadContents];
	NSMutableAttributedString *buf = [[NSMutableAttributedString alloc] initWithString:@""];
	NSDictionary *gapAttrib = [NSDictionary dictionaryWithObject:[NSFont userFontOfSize:3.0] forKey:NSFontAttributeName];
	NSAttributedString *gap = [[NSAttributedString alloc] initWithString:@"\n" attributes:gapAttrib];

	[buf appendAttributedString:gap];
	
	for (unsigned int i=0; i < [instantMessages count]; i++)
	{
		InstantMessage *im = [instantMessages objectAtIndex:i];
		Presentity *sender = [im sender];
		NSAttributedString *text = [im text];
		
		NSDictionary *attribsOfText = nil;
		
		if (text && [text length] > 0)
			attribsOfText = [text attributesAtIndex:0 effectiveRange:nil];
		
		if (sender)
		{
			NSString *realName = [AddressBookUtils lookupRealNameForIMNick:[sender senderID]];
			if (!realName)
				realName = [sender senderID];
			
			NSString *formattedName = [realName stringByAppendingString:@": "];
			NSAttributedString *senderName = [[NSAttributedString alloc] initWithString:formattedName attributes:attribsOfText];
			[buf appendAttributedString:senderName];
			[senderName release];
		}
		[buf appendAttributedString:text];
				
		NSAttributedString *lineBreak = [[NSAttributedString alloc] initWithString:@"\n" attributes:attribsOfText];
		[buf appendAttributedString:lineBreak];
		[lineBreak release];
		
		[buf appendAttributedString:gap];
	}

	[gap release];
	
										
	//[buf addAttributes:baselineAttrib range:NSMakeRange(0, [[buf string] length])];
	
	return [buf autorelease];
}

//Get tab delimited text version of chat
- (NSString *) exportableContents
{
    [self loadContents];
    NSMutableString *buf = [[NSMutableString alloc] initWithString:@""];
    
    for (unsigned int i=0; i < [instantMessages count]; i++)
	{
        InstantMessage *im = [instantMessages objectAtIndex:i];
        Presentity *sender = [im sender];
		NSAttributedString *text = [im text];
		NSDate *date = [im date];
        if (sender)
		{
            [buf appendString:[[NSArray arrayWithObjects:
                [self buddy],
                [sender senderID],
                [date descriptionWithCalendarFormat:@"%m/%d/%Y" timeZone:nil locale:nil],
                [date descriptionWithCalendarFormat:@"%H:%M:%S" timeZone:nil locale:nil],
                [text string],nil]
                  componentsJoinedByString:@"\t"]];
            [buf appendString:@"\r"];
        }
    }
    return [buf autorelease];
}

- (NSArray *) participants
{
	NSMutableSet *participantSet = [[[NSMutableSet alloc] init] autorelease];
	
    for (unsigned int i=0; i < [instantMessages count]; i++)
	{
        InstantMessage *im = [instantMessages objectAtIndex:i];
        Presentity *sender = [im sender];
		[participantSet addObject:[sender senderID]];
    }
	
	return [participantSet allObjects];
}

@end
