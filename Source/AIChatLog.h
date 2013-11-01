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

#define ChatLog_WillDelete			@"ChatLog_WillDelete"

@class ISO8601DateFormatter;

NSDate *dateFromFileName(NSString *fileName);

@interface AIChatLog : NSObject <NSXMLParserDelegate> {
    NSString	    *relativePath;
    NSString	    *from;
    NSString	    *to;
	NSString		*serviceClass;
    NSDate			*date;
	CGFloat			rankingPercentage;
	CGFloat			rankingValue;
	ISO8601DateFormatter *formatter;
}

- (id)initWithPath:(NSString *)inPath from:(NSString *)inFrom to:(NSString *)inTo serviceClass:(NSString *)inServiceClass;
- (id)initWithPath:(NSString *)inPath;

//Accessors
- (NSString *)relativePath;
- (NSString *)from;
- (NSString *)to;
- (NSString *)serviceClass;
- (NSDate *)date;
- (CGFloat)rankingPercentage;
- (void)setRankingPercentage:(CGFloat)inRankingPercentage;
- (CGFloat)rankingValueOnArbitraryScale;
- (void)setRankingValueOnArbitraryScale:(CGFloat)inRankingValue;

//Comparisons
- (NSComparisonResult)compareTo:(AIChatLog *)inLog;
- (NSComparisonResult)compareToReverse:(AIChatLog *)inLog;
- (NSComparisonResult)compareFrom:(AIChatLog *)inLog;
- (NSComparisonResult)compareFromReverse:(AIChatLog *)inLog;
- (NSComparisonResult)compareDate:(AIChatLog *)inLog;
- (NSComparisonResult)compareDateReverse:(AIChatLog *)inLog;
- (NSComparisonResult)compareService:(AIChatLog *)inLog;
- (NSComparisonResult)compareServiceReverse:(AIChatLog *)inLog;
- (NSComparisonResult)compareRank:(AIChatLog *)inLog;
- (NSComparisonResult)compareRankReverse:(AIChatLog *)inLog;
@end
