#!/bin/sh
# Common variables and helper functions

# Bails out if any command exits with a non zero exit code
# In all scripts if it doesn't matter what a return code is make sure to use cmd || true
set -e
	
# Package Versions - if a package is changed also update urls.txt
PKGCONFIG=pkg-config-0.22
GETTEXT=gettext-0.16.1
GLIB=glib-2.15.4
MEANWHILE=meanwhile-1.0.2
GADU=libgadu-1.7.1
INTLTOOL=intltool-0.36.2
GPG_ERROR=libgpg-error-1.6
GCRYPT=libgcrypt-1.4.1

# Directories
BASEDIR="$PWD"
PATCHDIR="$PWD/patches"
SOURCEDIR="$PWD/source"
BUILDDIR="$PWD/build"
UNIVERSAL_DIR="$BUILDDIR/universal"
LOGDIR="$PWD/build"
export PIDGIN_SOURCE="$SOURCEDIR/im.pidgin.pidgin"

# Compiler options
export CC=/usr/bin/gcc-4.2
TARGET_DIR_PPC="$BUILDDIR/root-ppc"
TARGET_DIR_I386="$BUILDDIR/root-i386"
TARGET_DIR_BASE="$BUILDDIR/root"
export PATH_PPC="$TARGET_DIR_PPC/bin:$PATH"
export PATH_I386="$TARGET_DIR_I386/bin:$PATH"

SDK_ROOT="/Developer/SDKs/MacOSX10.5.sdk"
BASE_CFLAGS="-mmacosx-version-min=10.5 -isysroot $SDK_ROOT"
BASE_LDFLAGS="-mmacosx-version-min=10.5 -headerpad_max_install_names -Wl,-syslibroot,$SDK_ROOT"
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
		python "$BASEDIR/download.py" -f "$BASEDIR/urls.txt"
	popd
}

if [ "$1" = "-d" ]; then
	downloadSources
	
	echo "Done - now run ./general_dependencies_make.sh"
fi
