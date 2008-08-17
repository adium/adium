//
//  AIMutableStringAdditions.m
//  Adium
//
//  Created by Nelson Elhage on Sun Mar 14 2004.
//

#import "AIMutableStringAdditions.h"

@implementation NSMutableString (AIMutableStringAdditions)

+ (NSMutableString *)stringWithContentsOfASCIIFile:(NSString *)path
{
	return ([[[NSMutableString alloc] initWithData:[NSData dataWithContentsOfFile:path]
										  encoding:NSASCIIStringEncoding] autorelease]);
}

- (NSMutableString*)mutableString
{
	return self;
}

/*
 * @brief Convert new lines to slashes
 *
 * We first consolidate all duplicate line breaks and process \r\n into being just \n.
 * All remaining \r and \n characters are converted to " / " as is done with multiple lines of a poem
 * displayed on a single line
 */
- (void)convertNewlinesToSlashes
{
	NSRange fullRange = NSMakeRange(0, [self length]);
	unsigned int replacements = 0;

	//First, we remove duplicate linebreaks.
	do {
		replacements = [self replaceOccurrencesOfString:@"\r\r"
											 withString:@"\r"
												options:NSLiteralSearch
												  range:fullRange];
		fullRange.length -= replacements;
	} while (replacements > 0);
	
	do {
		replacements = [self replaceOccurrencesOfString:@"\n\n"
											 withString:@"\n"
												options:NSLiteralSearch
												  range:fullRange];
		fullRange.length -= replacements;
	} while (replacements > 0);
	
	do {
		replacements = [self replaceOccurrencesOfString:@"\r\n"
											 withString:@"\n"
												options:NSLiteralSearch
												  range:fullRange];
		fullRange.length -= replacements;
	} while (replacements > 0);
	
	//Now do the slash replacements
	replacements = [self replaceOccurrencesOfString:@"\r"
										 withString:@" / "
											options:NSLiteralSearch
											  range:fullRange];
	fullRange.length += (2 * replacements);
	
	[self replaceOccurrencesOfString:@"\n"
						  withString:@" / "
							 options:NSLiteralSearch
							   range:fullRange];
}

- (unsigned int)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(unsigned)opts
{
	return [self replaceOccurrencesOfString:target withString:replacement options:opts range:NSMakeRange(0, [self length])];
}

@end
