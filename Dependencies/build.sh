#!/bin/bash -eu

source phases/utility.sh
source phases/build_dependencies.sh
source phases/build_otr.sh
source phases/build_vv_dependencies.sh
source phases/build_purple.sh
source phases/make_frameworks.sh

# Check that we're in the Dependencies directory
ROOTDIR=$(pwd)
if ! expr "$ROOTDIR" : '.*/Dependencies$' &> /dev/null; then
	error "Please run this script from the Dependencies directory."
	exit 1
fi

TARGET_BASE="apple-darwin10"

# Arrays for archs and host systems, sometimes an -arch just isnt enough!
ARCHS=( "x86_64" "i386" "ppc" )
HOSTS=( "x86_64-${TARGET_BASE}" "i686-${TARGET_BASE}" "powerpc-${TARGET_BASE}" )
NUMBER_OF_CORES=`sysctl -n hw.activecpu`
SDK_ROOT="/Developer/SDKs/MacOSX10.5.sdk"
MIN_OS_VERSION="10.5"
BASE_CFLAGS="-fstack-protector -isysroot $SDK_ROOT \
	-mmacosx-version-min=$MIN_OS_VERSION \
	-I$ROOTDIR/build/include \
	-L$ROOTDIR/build/lib \
	-Os"
BASE_LDFLAGS="-mmacosx-version-min=$MIN_OS_VERSION \
	-Wl,-syslibroot,$SDK_ROOT \
	-Wl,-headerpad_max_install_names \
	-I$ROOTDIR/build/include \
	-L$ROOTDIR/build/lib"

remove_arch() {
	local offset=0
	local tempArchs=""
	local tempHosts=""
	for (( i=0; i<${#ARCHS[@]}; i++ )) ; do
		if [[ $1 == ${ARCHS[i]} ]] ; then
			offset=$((offset + 1))
			continue
		fi
		tempArchs[$((i-offset))]=${ARCHS[i]}
		tempHosts[$((i-offset))]=${HOSTS[i]}
	done
	ARCHS=( ${tempArchs[@]} )
	HOSTS=( ${tempHosts[@]} )
}

set_arch_flags() {
	for ARCH in ${ARCHS[@]} ; do
		ARCH_FLAGS="${ARCH_FLAGS:= } -arch ${ARCH}"
	done

	ARCH_CFLAGS="${BASE_CFLAGS} ${ARCH_FLAGS:= }"
	ARCH_LDFLAGS="${BASE_LDFLAGS} ${ARCH_FLAGS:= }"
}

# handle commandline options
FORCE_CONFIGURE=false
NATIVE_BUILD=false
BUILD_OTR=false
STRAIGHT_TO_LIBPURPLE=false
MTN_UPDATE_PARAM=""
for option in ${@:1} ; do
	case $option in
		--configure)
			FORCE_CONFIGURE=true
			warning "Packages will be reconfigured!"
			;;
		--disable-x86_64)
			remove_arch "x86_64" 
			warning "x86_64 target removed! Libpurple will not be universal!"
			;;
		--disable-i386)
			remove_arch "i386"
			warning "i386 target removed! libpurple will not be universal!"
			;;
		--disable-ppc)
			remove_arch "ppc"
			warning "ppc target removed! Libpurple will not be universal!"
			;;
		--build-native) 
			unset ARCHS; ARCHS=""
			unset HOSTS; HOSTS=""
			NATIVE_BUILD=true
			BASE_CFLAGS="-I$ROOTDIR/build/include -L$ROOTDIR/build/lib"
			BASE_LDFLAGS="-Wl,-headerpad_max_install_names \
				-I$ROOTDIR/build/include -L$ROOTDIR/build/lib"
			warning "libpurple will be built for your native arcticture only!"
			;;
		--build-otr)
			BUILD_OTR=true
			status "Building libotr"
			;;
		--enable-llvm)
			asserttools "/Developer/usr/bin/llvm-gcc"
			export CC="/Developer/usr/bin/llvm-gcc"
			export CXX="/Developer/usr/bin/llvm-g++"
			warning "Building with LLVM! This is unsupported and will probably break things!"
			;;
		--libpurple-rev=*)
			MTN_REV=${option##*=}
			MTN_UPDATE_PARAM="${MTN_UPDATE_PARAM} -r ${MTN_REV}"
			;;
		--libpurple-branch=*)
			MTN_BRANCH=${option##*=}
			MTN_UPDATE_PARAM="${MTN_UPDATE_PARAM} -b ${MTN_BRANCH}"
			;;
		--libpurple-only)
			STRAIGHT_TO_LIBPURPLE=true
			;;
		--download-libpurple)
			DOWNLOAD_LIBPURPLE=true
			;;
		-h|-help|--help)
			echo 'The following options are valid:

  --configure                 : Force a configure during the build process
  --disable-[arch]            : Eliminate [arch] from the build process
  --build-native              : Build only for your current architecture
                                (currently breaks liboil on x86_64)
  --build-otr                 : Build libotr and dependancies instead
                                of libpurple.
  --enable-llvm               : Enable building with llvm-gcc.
                                WARNING: This is currently broken!
  --libpurple-rev=[rev]       : Force a specific libpurple revision
  --libpurple-branch=[branch] : Force a secific libpurple branch
  --libpurple-only            : Assume all dependencies are already built
                                and start the build with libpurple itself
  --download-libpurple        : Download the libpurple mtn bootstrap db.
  --help                      : This help text
	
Note that explicitly setting any arch flags implies a forced reconfigure.'
			exit 0
			;;
		*)
			echo "Unknown command.  Run ${0} --help for a list of commands."
			exit 0
			;;
	esac
done

# this file contans the stdio and stderr of the most recent build
LOG_FILE="${ROOTDIR}/build.log"
ERR_FILE="${ROOTDIR}/error.log"

: > ${LOG_FILE}

# set -arch flags now, after the user has had a chance to disable one or more
set_arch_flags

# assert that the developer can, in fact, build libpurple.  Why waste his time if he can't?
asserttools gcc
asserttools mtn

# Ok, so we keep running into issues where MacPorts will volunteer to supply
# dependencies that we want to build ourselves.
# Getting mtn's path before we export our own (safer?) path will ensure it works,
# even if it's being managed by MacPorts, Fink, or similar.
MTN=`which mtn`
export PATH=$ROOTDIR/build/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Developer/usr/bin:/Developer/usr/sbin
export PKG_CONFIG="$ROOTDIR/build/bin/pkg-config"
export PKG_CONFIG_PATH="$ROOTDIR/build/lib/pkgconfig:/usr/lib/pkgconfig"

# Make the source and build directories while we're here
quiet mkdir "source"
quiet mkdir "build"

if $STRAIGHT_TO_LIBPURPLE; then
    build_libpurple $@
else
    # TODO: Make this parameterizable 
    build_pkgconfig $@
    build_gettext $@
    build_glib $@

    if $BUILD_OTR; then
    	build_otr $@
    else
	   build_meanwhile $@

    	build_intltool $@
    	build_jsonglib $@

    	build_gstreamer $@
    	build_farsight $@

    	build_libpurple $@	

    	#build_sipe $@
    	#build_gfire $@
    fi
fi

make_framework $@

#ugly.  gotta be a better way
if [[ !$BUILD_OTR ]] ; then
	make_po_files $@
fi
