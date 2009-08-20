//IconFamily depends heavily upon Carbon calls and thus will only work in Mac OS X
#ifdef MAC_OS_X_VERSION_10_0

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@interface NSString (CarbonFSSpecCreation)

// Fills in the given FSRef struct so it specifies the file whose path is in this string.
// If the file doesn't exist, and "createFile" is YES, this method will attempt to create
// an empty file with the specified path.  (The caller should insure that the directory
// the file is to be placed in already exists.)

- (BOOL) getFSRef:(FSRef*)fsRef createFileIfNecessary:(BOOL)createFile;

// Fills in the given FSSpec struct so it specifies the file whose path is in this string.
// If the file doesn't exist, and "createFile" is YES, this method will attempt to create
// an empty file with the specified path.  (The caller should insure that the directory
// the file is to be placed in already exists.)

- (BOOL) getFSSpec:(FSSpec*)fsSpec createFileIfNecessary:(BOOL)createFile;

//given a Carbon FSRef, get a POSIX-style pathname in an NSString.
+ (NSString *)pathForFSRef:(FSRef *)object;
@end

#endif
