/*
 * From AddressBook.framework, 10.3 and later
 */
@interface NSIPRecentPicture:NSObject
{
    NSString *_originalImageName;
    NSImage *_originalImage;
    struct _NSRect _crop;
    NSData *_smallIconData;
}

+ _infoFilePath;
+ (void)_saveChanges;
+ currentPicture;
+ (int)maxRecents;
+ (void)noCurrentPicture;
+ pictureDirPath;
+ (char)purgeExtras;
+ recentPictures;
+ recentSmallIcons;
+ (void)removeAllButCurrent;
- _infoToSave;
- (void)_removePermanently;
- (struct _NSRect)crop;
- croppedImage;
- (void)dealloc;
- initWithInfo:fp8;
- initWithOriginalImage:fp8;
- initWithOriginalImage:fp8 crop:(struct _NSRect)fp12 smallIcon:fp28;
- originalImage;
- originalImagePath;
- (void)setCrop:(struct _NSRect)fp8 smallIcon:fp24;
- (void)setCurrent;
- smallIcon;

@end
