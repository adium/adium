#!/bin/sh
# Common variables and helper functions

# Bails out if any command exits with a non zero exit code
# In all scripts if it doesn't matter what a return code is make sure to use cmd || true
set -e
	
# Package Versions - if a package is changed also update urls.txt
PKGCONFIG=pkg-config-0.22
GETTEXT=gettext-0.16.1
GLIB=glib-2.16.6
MEANWHILE=meanwhile-1.0.2
GADU=libgadu-1.7.1
INTLTOOL=intltool-0.36.2
JSONLIB=json-glib-0.6.2
GPG_ERROR=libgpg-error-1.6
GCRYPT=libgcrypt-1.4.1
LIBXML2=libxml2-2.7.3
GSTREAMER=gstreamer-0.10.22
LIBOIL=liboil-0.3.16
GST_PLUGINS_BASE=gst-plugins-base-0.10.22
GST_PLUGINS_GOOD=gst-plugins-good-0.10.14
GST_PLUGINS_BAD=gst-plugins-bad-0.10.11
GST_PLUGINS_FARSIGHT=gst-plugins-farsight-0.12.11
FARSIGHT=farsight2-0.0.8

# Directories
if [ "x$ADIUM_BUILD_BASEDIR" = "x" ]; then
	BASEDIR="$PWD"
else
	BASEDIR="$ADIUM_BUILD_BASEDIR"
fi

SCRIPT_DIR="$PWD"
PATCHDIR="$SCRIPT_DIR/patches"
SOURCEDIR="$BASEDIR/source"
BUILDDIR="$BASEDIR/build"
UNIVERSAL_DIR="$BUILDDIR/universal"
LOGDIR="$BUILDDIR"

if [ "x$PIDGIN_SOURCE" = "x" ] ; then
	export PIDGIN_SOURCE="$SOURCEDIR/im.pidgin.adium"
fi

# Compiler options
export CC=/usr/bin/gcc-4.2
TARGET_DIR_PPC="$BUILDDIR/root-ppc"
TARGET_DIR_I386="$BUILDDIR/root-i386"
TARGET_DIR_ARMV6="$BUILDDIR/root-armv6"

TARGET_DIR_BASE="$BUILDDIR/root"
export PATH_PPC="$TARGET_DIR_PPC/bin:$PATH"
export PATH_I386="$TARGET_DIR_I386/bin:$PATH"
export PATH_ARMV6="$TARGET_DIR_ARMV6/bin:$PATH"

if [ "$1" = "-iphone" ]; then
    #HOST="arm-apple-darwin"
    echo "iPhone!"
    SDK_ROOT="/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS2.2.sdk"
    BASE_CFLAGS="-miphoneos-version-min=2.2 -isysroot $SDK_ROOT"
    BASE_LDFLAGS="-miphoneos-version-min=2.2 -headerpad_max_install_names -Wl,-syslibroot,$SDK_ROOT"

else
    SDK_ROOT="/Developer/SDKs/MacOSX10.5.sdk"
    BASE_CFLAGS="-mmacosx-version-min=10.5 -isysroot $SDK_ROOT"
    BASE_LDFLAGS="-mmacosx-version-min=10.5 -headerpad_max_install_names -Wl,-syslibroot,$SDK_ROOT"
fi

NUMBER_OF_CORES=`sysctl -n hw.activecpu`

# XXX Not sure if this is even used anymore
IS_ON_10_4=FALSE

function setupDirStructure {
	mkdir "$LOGDIR" > /dev/null 2>&1 || true
	mkdir "$BUILDDIR" >/dev/null 2>&1 || true
	mkdir "$UNIVERSAL_DIR" > /dev/null 2>&1 || true
}

function downloadSources {
	setupDirStructure
	mkdir "$SOURCEDIR" > /dev/null 2>&1 || true
	
	pushd "$SOURCEDIR"
		python "$SCRIPT_DIR/download.py" -f "$SCRIPT_DIR/urls.txt"
	popd
}

if [ "$1" = "-d" ]; then
	downloadSources
	
	echo "Done - now run ./general_dependencies_make.sh"
fi
