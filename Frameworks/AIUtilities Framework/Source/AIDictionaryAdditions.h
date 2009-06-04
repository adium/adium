/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2005, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@interface NSDictionary (AIDictionaryAdditions)

+ (NSDictionary *)dictionaryNamed:(NSString *)name forClass:(Class)inClass;
+ (NSDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create;
- (BOOL)writeToPath:(NSString *)path withName:(NSString *)name;
- (void)asyncWriteToPath:(NSString *)path withName:(NSString *)name;

- (NSDictionary *)dictionaryByTranslating:(NSDictionary *)translation adding:(NSDictionary *)addition removing:(NSSet *)removal;

- (NSSet *)allKeysSet;
- (NSMutableSet *)allKeysMutableSet;

//If flag is non-NO, keys that are in both dicts but whose values are different will be included in both sets.
- (void)compareWithPriorDictionary:(NSDictionary *)other
                      getAddedKeys:(out NSSet **)outAddedKeys
                    getRemovedKeys:(out NSSet **)outRemovedKeys
                includeChangedKeys:(BOOL)flag;

- (NSDictionary *)dictionaryWithIntersectionWithSetOfKeys:(NSSet *)keys;
- (NSDictionary *)dictionaryWithDifferenceWithSetOfKeys:(NSSet *)keys;

//Assumes that its key-value pairs (both key and value being NSStrings) are CSS properties. Generates CSS source code like this:
//	font-family: Helvetica; font-size: 12pt; font-weight: bold; font-style: italic;
- (NSString *)CSSString;

- (BOOL)validateAsPropertyList;

@end

@interface NSMutableDictionary (AIDictionaryAdditions)

+ (NSMutableDictionary *)dictionaryAtPath:(NSString *)path withName:(NSString *)name create:(BOOL)create;

- (void)translate:(NSDictionary *)translation add:(NSDictionary *)addition remove:(NSSet *)removal;

- (void)intersectSetOfKeys:(NSSet *)keys;
- (void)minusSetOfKeys:(NSSet *)keys;

@end
