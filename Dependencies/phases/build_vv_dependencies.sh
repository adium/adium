#!/bin/bash -eu

##
# xml2
#
XML_VERSION=2.2
build_libxml2() {
	prereq "xml2" \
		"ftp://xmlsoft.org:21//libxml2/libxml2-sources-2.7.3.tar.gz"
	
	quiet pushd "$ROOTDIR/source/xml2"
	
	if needsconfigure $@; then
		status "Configuring xml2"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--with-python=no \
				--disable-dependency-tracking
	fi
	
	status "Building and installing xml2"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}


##
# liboil
# liboil needs special threatment.  Rather than placing platform specific code
# in a ifdef, it sequesters it by directory and invokes a makefile.  woowoo.
build_liboil() {
	prereq "oil" \
		"http://liboil.freedesktop.org/download/liboil-0.3.16.tar.gz"
	
	quiet pushd "$ROOTDIR/source/oil"
	
	status "Cross-comiling oil..."
	CONFIG_CMD="./configure \
				--disable-dependency-tracking"
	xcompile "${BASE_CFLAGS}  -DHAVE_SYMBOL_UNDERSCORE" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
		"lib/liboil-0.3.0.dylib" \
		"lib/liboil-0.3.a"

	status "...done cross-compiling oil"
	
	quiet popd
}

##
# gst-plugins-base
#
build_gst_plugins_base() {
	prereq "gst-plugins-base" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-0.10.23.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-base"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-base"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-base/config.h" \
			"${ROOTDIR}/source/gst-plugins-base/_stdint.h"
	fi
	
	status "Building and installing gst-plugins-base"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gst-plugins-good
#
build_gst_plugins_good() {
	prereq "gst-plugins-good" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-0.10.15.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-good"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-good"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-aalib \
				--disable-examples \
				--disable-goom \
				--disable-goom2k1 \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-good/config.h" \
			"${ROOTDIR}/source/gst-plugins-good/_stdint.h"
	fi
	
	status "Building and installing gst-plugins-good"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gst-plugins-bad
#
build_gst_plugins_bad() {
	prereq "gst-plugins-bad" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-0.10.13.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-bad"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-bad"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-real \
				--disable-osx_video \
				--disable-quicktime \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-bad/config.h" \
			"${ROOTDIR}/source/gst-plugins-bad/_stdint.h"
	fi
	
	status "Building and installing gst-plugins-bad"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gst-plugins-farsight
#
build_gst_plugins_farsight() {
	prereq "gst-plugins-farsight" \
		"http://farsight.freedesktop.org/releases/gst-plugins-farsight/gst-plugins-farsight-0.12.11.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-farsight"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-farsight"
		export NM="nm -arch all"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing gst-plugins-farsight"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gstreamer plugins
#
build_gst_plugins() {
	build_liboil $@
	build_gst_plugins_base $@
	build_gst_plugins_good $@
	build_gst_plugins_bad $@
	build_gst_plugins_farsight $@
}

##
# gstreamer
#
GSTREAMER_VERSION=0.10
build_gstreamer() {
    build_libxml2 $@

	prereq "gstreamer" \
		"http://gstreamer.freedesktop.org/src/gstreamer/gstreamer-0.10.24.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gstreamer"
	
	if needsconfigure $@; then
		status "Configuring gstreamer"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"$ROOTDIR/source/gstreamer/gst/gstconfig.h" \
			"$ROOTDIR/source/gstreamer/config.h"
	fi
	
	status "Building and installing gstreamer"
	warning "Building too much! Patch the Makefile"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
	
	build_gst_plugins $@
}

##
# libNICE
#
build_nice() {
	prereq "nice" \
		"http://nice.freedesktop.org/releases/libnice-0.0.9.tar.gz"
	
	quiet pushd "$ROOTDIR/source/nice"
	
	if needsconfigure $@; then
		status "Configuring NICE"
		export NM="nm -arch all"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing NICE"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# farsight
#
build_farsight() {
	build_nice $@
	
	prereq "farsight" \
		"http://farsight.freedesktop.org/releases/farsight2/farsight2-0.0.15.tar.gz"
	
	quiet pushd "$ROOTDIR/source/farsight"
	
	if needsconfigure $@; then
		status "Configuring farsight"
		export NM="nm -arch all"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-python \
				--disable-dependency-tracking
	fi
	
	status "Building and installing farsight"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}