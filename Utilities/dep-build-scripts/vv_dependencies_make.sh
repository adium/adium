#!/bin/sh

source common.sh
setupDirStructure
cd "$BUILDDIR"

LOG_FILE=$PWD/dep_make.log
echo "Continuing vv build at" `date` >> $LOG_FILE 2>&1

for ARCH in ppc i386 ; do
    #libxml2
	echo "Building libxml2 for $ARCH"
	
	export CFLAGS="$LOCAL_FLAGS $BASE_CFLAGS -arch $ARCH"
	export CPPFLAGS="$CFLAGS"
	export LDFLAGS="$LOCAL_FLAGS $BASE_LDFLAGS -arch $ARCH"
	
	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig";;
	esac
	
	mkdir libxml2-$ARCH >/dev/null 2>&1 || true
	pushd libxml2-$ARCH
    	echo "  Configuring..."
    	"$SOURCEDIR/$LIBXML2/configure" \
	       --prefix=$TARGET_DIR \
	       --with-python=no
        echo "  Making and installing..."
    	make -j $NUMBER_OF_CORES && make install
	popd
done

for ARCH in ppc i386 ; do
    #gstreamer
	echo "Building gstreamer for $ARCH"
	
	export CFLAGS="$LOCAL_FLAGS $BASE_CFLAGS -arch $ARCH"
	export CPPFLAGS="$CFLAGS"
	export LDFLAGS="$LOCAL_FLAGS $BASE_LDFLAGS -arch $ARCH"
	
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH

	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig";;
	esac
	
	mkdir gstreamer-$ARCH >/dev/null 2>&1 || true
	pushd gstreamer-$ARCH
    	echo "  Configuring gstreamer..."
    	"$SOURCEDIR/$GSTREAMER/configure" \
	       --prefix=$TARGET_DIR
        echo "  Making and installing gstreamer..."
    	make -j $NUMBER_OF_CORES && make install
	popd
done


# gst-plugins-base req:
#   * gstreamer
#   * liboil
#
for ARCH in ppc i386 ; do
    #gst-plugins-base (gstreamer plugins, base)
	echo "Building gst-plugins-base and immediate deps for $ARCH"
	
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH

	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig"
             export HOST="powerpc-apple-darwin"
             export NM="nm -arch ppc "
          	# We add -DHAVE_SYMBOL_UNDERSCORE because otherwise the
          	# Altivec functions for PPC are defined as __vec_memcpy rather
          	# than _vec_memcpy, which fails (liboil)
             export LOCAL_CFLAGS="-DHAVE_SYMBOL_UNDERSCORE";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig"
              export HOST="i386-apple-darwin9.6.0"
              export NM="nm -arch i386 "
              export LOCAL_CFLAGS="";;
	esac

	export CFLAGS="$LOCAL_CFLAGS $BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"	
	export CPPFLAGS="$CFLAGS"

	mkdir liboil-$ARCH >/dev/null 2>&1 || true
    pushd liboil-$ARCH
    	echo "  Configuring liboil for $ARCH..."
        "$SOURCEDIR/$LIBOIL/configure" \
	        --prefix=$TARGET_DIR \
	       --host=$HOST
        echo "  Making and installing liboil for $ARCH..."
    	make -j $NUMBER_OF_CORES && make install
	popd

	mkdir gst-plugins-base-$ARCH >/dev/null 2>&1 || true
	pushd gst-plugins-base-$ARCH
    	echo "  Configuring gst-plugins-base for $ARCH..."
    	"$SOURCEDIR/$GST_PLUGINS_BASE/configure" \
	       --prefix=$TARGET_DIR
        echo "  Making and installing gst-plugins-base for $ARCH..."
    	make -j $NUMBER_OF_CORES && make install
	popd

	mkdir gst-plugins-good-$ARCH >/dev/null 2>&1 || true
	pushd gst-plugins-good-$ARCH
	   # aalib is the ascii art library; on my system, it kept linking in
	   # from macports. -evands
    	echo "  Configuring gst-plugins-good for $ARCH..."
    	"$SOURCEDIR/$GST_PLUGINS_GOOD/configure" \
	       --prefix=$TARGET_DIR \
	       --host=$HOST \
	       --disable-aalib 
        echo "  Making and installing gst-plugins-good for $ARCH..."
    	make -j $NUMBER_OF_CORES && make install
	popd

	mkdir gst-plugins-bad-$ARCH >/dev/null 2>&1 || true
	pushd gst-plugins-bad-$ARCH
    	echo "  Configuring gst-plugins-bad for $ARCH..."
    	"$SOURCEDIR/$GST_PLUGINS_BAD/configure" \
	       --prefix=$TARGET_DIR \
	       --host=$HOST
        echo "  Making and installing gst-plugins-bad for $ARCH..."
    	make -j $NUMBER_OF_CORES && make install
	popd


	mkdir gst-plugins-farsight-$ARCH >/dev/null 2>&1 || true
	pushd gst-plugins-farsight-$ARCH
    	echo "  Configuring gst-plugins-farsight for $ARCH..."
    	"$SOURCEDIR/$GST_PLUGINS_FARSIGHT/configure" \
	       --prefix=$TARGET_DIR \
	       --host=$HOST
        echo "  Making and installing gst-plugins-farsight for $ARCH..."
    	make -j $NUMBER_OF_CORES && make install
	popd
done


for ARCH in ppc i386 ; do
    #libNICE
	echo "Building nice for $ARCH"
	
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH

	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig"
             export HOST="powerpc-apple-darwin"
             export NM="nm -arch ppc "
             export LOCAL_CFLAGS="";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig"
              export HOST="i386-apple-darwin9.6.0"
              export NM="nm -arch i386 "
              export LOCAL_CFLAGS="";;
	esac

	export CFLAGS="$LOCAL_CFLAGS $BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"	
	export CPPFLAGS="$CFLAGS"

	mkdir nice-$ARCH >/dev/null 2>&1 || true
    pushd nice-$ARCH
    	echo "  Configuring nice for $ARCH..."
        "$SOURCEDIR/$NICE/configure" \
	       --prefix=$TARGET_DIR \
	       --host=$HOST
        echo "  Making and installing farsight for $ARCH..."
    	make -j $NUMBER_OF_CORES && make install
	popd
done

for ARCH in ppc i386 ; do
    #farsight
	echo "Building farsight for $ARCH"
	
	TARGET_DIR=$TARGET_DIR_BASE-$ARCH

	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig"
             export HOST="powerpc-apple-darwin"
             export NM="nm -arch ppc "
             export LOCAL_CFLAGS="";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig"
              export HOST="i386-apple-darwin9.6.0"
              export NM="nm -arch i386 "
              export LOCAL_CFLAGS="";;
	esac

	export CFLAGS="$LOCAL_CFLAGS $BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"	
	export CPPFLAGS="$CFLAGS"

	mkdir farsight-$ARCH >/dev/null 2>&1 || true
    pushd farsight-$ARCH
    	echo "  Configuring farsight for $ARCH..."
        "$SOURCEDIR/$FARSIGHT/configure" \
	       --prefix=$TARGET_DIR \
	       --disable-python \
	       --host=$HOST
        echo "  Making and installing farsight for $ARCH..."
    	make -j $NUMBER_OF_CORES && make install
	popd
done


#Do we need any of these?
#libpng
#libjpeg
#libogg
#libvorbis
#libspeex
#libtheora
#taglib

echo "Done - now run ./purple_make.sh"