#!/bin/sh

source common.sh -iphone
setupDirStructure
cd "$BUILDDIR"

LOG_FILE="$LOGDIR/dep_make.log"
echo "Beginning build at" `date` > $LOG_FILE 2>&1

#pkg-config
# We only need a native pkg-config, it's not a runtime dependency,
# but we need a native one in both directories
# Note that this is compiling for the local platform, since this program
# will be running locally. It doesn't need to cross-compile.
#
#unset CFLAGS
#
export CC=/usr/bin/gcc-4.2
for ARCH in armv6 ; do
	echo "Building pkg-config for $ARCH"
	
	case $ARCH in
        ppc) TARGET_DIR=$TARGET_DIR_PPC;;
		i386) TARGET_DIR=$TARGET_DIR_I386;;
        armv6) TARGET_DIR=$TARGET_DIR_ARMV6;;
	esac
	
	mkdir pkg-config-`arch` >/dev/null 2>&1 || true
	cd pkg-config-`arch`
	echo '  Configuring...'
	# "$SOURCEDIR/$PKGCONFIG/configure" --prefix="$TARGET_DIR" >> $LOG_FILE 2>&1
	echo '  make && make install'
	# make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
	cd ..
done

#gettext
# caveat - some of the build files in gettext appear to not respect CFLAGS
# and are compiling to `arch` instead of $ARCH. Lame.
#
# Override the CC/CPP settings for iPhone compilation
export CC=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc-4.0
export CPP=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/g++

for ARCH in armv6 ; do
	echo "Building gettext for $ARCH"
	export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
	
	case $ARCH in
	   ppc) HOST=powerpc-apple-darwin9
			  export PATH=$PATH_PPC;;
       i386) HOST=i686-apple-darwin9
			  export PATH=$PATH_I386;;
	   armv6) HOST=arm-apple-darwin
	          export PATH=$PATH_ARMV6;;
	esac
	
	mkdir gettext-$ARCH >/dev/null 2>&1 || true
	cd gettext-$ARCH
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH
	echo "  Configuring ($HOST)..."
	"$SOURCEDIR/$GETTEXT/configure" \
		--prefix=$TARGET_DIR \
		--enable-static --disable-shared \
     	--host=$HOST
        --target=$HOST
#          >> $LOG_FILE 2>&1
	echo '  make && make install'
	make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
	cd ..
done

#glib


# pushd $SOURCEDIR/$GLIB > /dev/null 2>&1
# GLIB_PATCHES=("")
# 
# for patch in ${GLIB_PATCHES[@]} ; do
#     echo "Applying $patch"
# 	patch --forward -p0 < $patch || true
# done
# popd > /dev/null 2>&1

for ARCH in armv6 ; do
	echo "Building glib for $ARCH"
	LOCAL_BIN_DIR="$TARGET_DIR_BASE-$ARCH/bin"
	LOCAL_LIB_DIR="$TARGET_DIR_BASE-$ARCH/lib"
	LOCAL_INCLUDE_DIR="$TARGET_DIR_BASE-$ARCH/include"
	LOCAL_FLAGS="-L$LOCAL_LIB_DIR -I$LOCAL_INCLUDE_DIR -lintl -liconv"
	
	export PKG_CONFIG="$LOCAL_BIN_DIR/pkg-config"
	export MSGFMT="$LOCAL_BIN_DIR/msgfmt"
	
	export CFLAGS="$LOCAL_FLAGS $BASE_CFLAGS -arch $ARCH"
	export CPPFLAGS="$CFLAGS"
	export LDFLAGS="$LOCAL_FLAGS $BASE_LDFLAGS -arch $ARCH"
	
	case $ARCH in
        armv6) HOST=arm-apple-darwin;;
		ppc) HOST=powerpc-apple-darwin9;;
		i386) HOST=i686-apple-darwin9;;
	esac
	
	mkdir glib-$ARCH >/dev/null 2>&1 || true
	cd glib-$ARCH
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH
	echo '  Configuring...'
	"$SOURCEDIR/$GLIB/configure" \
	   --prefix=$TARGET_DIR \
	   --with-libiconv \
	   --disable-static --enable-shared \
	   --host=$HOST >> $LOG_FILE 2>&1
	echo '  make && make install'
	make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
	cd ..
done

# pushd $SOURCEDIR/$GLIB > /dev/null 2>&1
# 	for patch in ${GLIB_PATCHES[@]} ; do
# 		patch -R -p0 < $patch || true
# 	done
# popd > /dev/null 2>&1

#libogg
#libvorbis
#libspeex
#libtheora
#taglib
#liboil - 3 patches
#gstreamer
#gst-plugins-base
#gst-plugins-good
#gst-plugins-bad

echo "Done - now run ./purple_dependencies_make.sh"
