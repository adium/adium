/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2006, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

@interface AITextAttachmentExtension : NSTextAttachment <NSCopying> {
    NSString	*stringRepresentation;
    BOOL        shouldSaveImageForLogging;
	BOOL		hasAlternate;
	NSString	*path;
	NSImage		*image;
	NSString	*imageClass; //set as class attribute in html, used to tell images apart for CSS
	BOOL		shouldAlwaysSendAsText;
}

- (void)setString:(NSString *)inString;
- (NSString *)string;
- (void)setImageClass:(NSString *)inString;
- (NSString *)imageClass;
- (BOOL)shouldSaveImageForLogging;
- (void)setShouldSaveImageForLogging:(BOOL)flag;
- (BOOL)hasAlternate;
- (void)setHasAlternate:(BOOL)flag;

- (void)setPath:(NSString *)inPath;
- (NSString *)path;

- (void)setImage:(NSImage *)inImage;
- (NSImage *)image;

- (NSImage *)iconImage;

- (BOOL)attachesAnImage;

- (BOOL)shouldAlwaysSendAsText;
- (void)setShouldAlwaysSendAsText:(BOOL)flag;

@end
