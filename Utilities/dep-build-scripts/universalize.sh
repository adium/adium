#!/bin/sh

source common.sh
setupDirStructure
cd "$BUILDDIR"

# create universal libraries for AdiumDeps.
# "top-level" deps
LIBINTL=libintl.8
LIBGLIB=libglib-2.0.0
LIBGOBJECT=libgobject-2.0.0
LIBGTHREAD=libgthread-2.0.0
LIBGMODULE=libgmodule-2.0.0

# "purple" deps
MEANWHILE=libmeanwhile.1
GADU=libgadu.3.7.0
SASL=libsasl2.2
JSONGLIB=libjson-glib-1.0.0

# vv
# I'm not sure what to do to universalize the vv libs, especially the gst-plugins

PURPLE_VERSION=0.6.0

LIBPURPLE=libpurple.$PURPLE_VERSION
PURPLE_FOLDER=libpurple-$PURPLE_VERSION

# Copy the headers to the universal dir so that we can put them in the frameworks 
# once they are built. We stick the required headers for each framework into its own folder
# named after the project to keep the frameworkize script library independent.

mkdir $UNIVERSAL_DIR/include || true
cd $UNIVERSAL_DIR/include

mkdir libintl-8 || true
cp $TARGET_DIR_I386/include/libintl.h $UNIVERSAL_DIR/include/libintl-8/

mkdir libglib-2.0.0 || true
cp -R $TARGET_DIR_I386/include/glib-2.0 $UNIVERSAL_DIR/include/libglib-2.0.0/
cp $TARGET_DIR_I386/lib/glib-2.0/include/glibconfig.h \
    $UNIVERSAL_DIR/include/libglib-2.0.0/glib-2.0/glibconfig-i386.h
cp $TARGET_DIR_PPC/lib/glib-2.0/include/glibconfig.h \
    $UNIVERSAL_DIR/include/libglib-2.0.0/glib-2.0/glibconfig-ppc.h
cp $SCRIPT_DIR/glibconfig.h $UNIVERSAL_DIR/include/libglib-2.0.0/glib-2.0

mkdir libgmodule-2.0.0 || true
cp $TARGET_DIR_I386/include/glib-2.0/gmodule.h $UNIVERSAL_DIR/include/libgmodule-2.0.0/

mkdir libgobject-2.0.0 || true
cp $TARGET_DIR_I386/include/glib-2.0/glib-object.h $UNIVERSAL_DIR/include/libgobject-2.0.0/
cp -R $TARGET_DIR_I386/include/glib-2.0/gobject/ $UNIVERSAL_DIR/include/libgobject-2.0.0/

mkdir libgthread-2.0.0 || true
# no headers to copy, make an empty file so that rtool isn't sad
touch libgthread-2.0.0/no_headers_here.txt

mkdir libjson-glib-1.0.0 || true
cp -R $TARGET_DIR_I386/include/json-glib-1.0/ $UNIVERSAL_DIR/include/libjson-glib-1.0.0/

rm -rf $UNIVERSAL_DIR/include/$PURPLE_FOLDER
cp -R $TARGET_DIR_I386/include/libpurple $UNIVERSAL_DIR/include/$PURPLE_FOLDER
# Another hack: we need libgadu.h
cp $TARGET_DIR_I386/include/libgadu.h $UNIVERSAL_DIR/include/$PURPLE_FOLDER/libgadu-i386.h
cp $TARGET_DIR_PPC/include/libgadu.h $UNIVERSAL_DIR/include/$PURPLE_FOLDER/libgadu-ppc.h
cp $SCRIPT_DIR/libgadu.h $UNIVERSAL_DIR/include/$PURPLE_FOLDER/
cd ..

cd $UNIVERSAL_DIR

for lib in $LIBINTL $LIBGLIB $LIBGOBJECT $LIBGTHREAD $LIBGMODULE $MEANWHILE $JSONGLIB \
           $GADU $LIBPURPLE; do
	echo "Making $lib universal..."
	python $SCRIPT_DIR/framework_maker/universalize.py \
	  i386:$TARGET_DIR_I386/lib/$lib.dylib \
	  ppc:$TARGET_DIR_PPC/lib/$lib.dylib \
	  $UNIVERSAL_DIR/$lib.dylib \
	  $TARGET_DIR_PPC/lib:$UNIVERSAL_DIR \
      $TARGET_DIR_I386/lib:$UNIVERSAL_DIR
done

cd ..

export PATH="$PATH:$SCRIPT_DIR/rtool"
echo "Making a framework for $PURPLE_FOLDER and all dependencies..."
python $SCRIPT_DIR/framework_maker/frameworkize.py $UNIVERSAL_DIR/$LIBPURPLE.dylib $PWD/Frameworks

echo "Adding the Adium framework header."
cp $SCRIPT_DIR/libpurple-full.h $PWD/Frameworks/libpurple.subproj/libpurple.framework/Headers/libpurple.h

cp $SCRIPT_DIR/Libpurple-Info.plist $PWD/Frameworks/libpurple.subproj/libpurple.framework/Resources/Info.plist

echo "Done - now run ./make_po_files.sh (if necessary) then ./copy_frameworks.sh"
