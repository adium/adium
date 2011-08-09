#!/bin/bash -eu

##
# liboil
# liboil needs special threatment.  Rather than placing platform specific code
# in a ifdef, it sequesters it by directory and invokes a makefile.  woowoo.
GSTREAMER_VERSION=0.10
GST_DEPS=( "liboil-0.3.0.dylib" )
build_liboil() {
	prereq "oil" \
		"http://liboil.freedesktop.org/download/liboil-0.3.16.tar.gz"
	
	quiet pushd "$ROOTDIR/source/oil"
	
	status "Cross-compiling oil..."
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
GST_DEPS=( ${GST_DEPS[@]} "libgstaudio-${GSTREAMER_VERSION}.0.dylib" "libgstvideo-${GSTREAMER_VERSION}.0.dylib" )
build_gst_plugins_base() {
	prereq "gst-plugins-base" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-0.10.26.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-base"
	
	if needsconfigure $@; then
	(
		status "Configuring gst-plugins-base"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-examples \
				--disable-gdp \
				--disable-audioconvert \
				--disable-playback \
				--disable-subparse \
				--disable-audiotestsrc \
				--disable-videotestsrc \
				--disable-cdparanoia \
				--disable-subparse \
				--disable-videotestsrc \
				--disable-x \
				--disable-xvideo \
				--disable-xshm \
				--disable-gst_v4l \
				--disable-alsa \
				--disable-gnome_vfs \
				--disable-gio \
				--disable-libvisual \
				--disable-ogg \
				--disable-pango \
				--disable-theora \
				--disable-vorbis \
				--disable-freetypetest \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS} -lintl" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-base/config.h" \
			"${ROOTDIR}/source/gst-plugins-base/_stdint.h"
	)
	fi
	
	status "Building and installing gst-plugins-base"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}

##
# gst-plugins-good
#
GST_DEPS=( ${GST_DEPS[@]} "libgstapp-${GSTREAMER_VERSION}.0.dylib" "libgstnet-${GSTREAMER_VERSION}.0.dylib" "libgstnetbuffer-${GSTREAMER_VERSION}.0.dylib" "libgstdataprotocol-${GSTREAMER_VERSION}.0.dylib" "libgstcontroller-${GSTREAMER_VERSION}.0.dylib" "libgsttag-${GSTREAMER_VERSION}.0.dylib" )
build_gst_plugins_good() {
	prereq "gst-plugins-good" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-0.10.18.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-good"
	
	if needsconfigure $@; then
	(
		status "Configuring gst-plugins-good"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-aalib \
				--disable-videofilter \
				--disable-apetag \
				--disable-alpha \
				--disable-audiofx \
				--disable-auparse \
				--disable-avi \
				--disable-cutter \
				--disable-debugutils \
				--disable-deinterlace \
				--disable-effectv \
				--disable-equalizer \
				--disable-flv \
				--disable-flx \
				--disable-id3demux \
				--disable-icydemux \
				--disable-examples \
				--disable-interleave \
				--disable-goom \
				--disable-goom2k1 \
				--disable-matroska \
				--disable-monoscope \
				--disable-multifile \
				--disable-multipart \
				--disable-qtdemux \
				--disable-replaygain \
				--disable-smpte \
				--disable-spectrum \
				--disable-directsound \
				--disable-wavenc \
				--disable-wavparse \
				--disable-y4m \
				--disable-oss \
				--disable-sunaudio \
				--disable-gst_v4l2 \
				--disable-x \
				--disable-xshm \
				--disable-xvideo \
				--disable-annodex \
				--disable-cairo \
				--disable-esd \
				--disable-flac \
				--disable-libcaca \
				--disable-libdv \
				--disable-libpng \
				--disable-pulse \
				--disable-taglib  \
				--disable-wavpack \
				--disable-zlib \
				--disable-bz2 \
				--disable-shout2 \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS} -lintl" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-good/config.h" \
			"${ROOTDIR}/source/gst-plugins-good/_stdint.h"
	)
	fi
	
	status "Building and installing gst-plugins-good"
	log make -j $NUMBER_OF_CORES
	log make install
	
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
	(
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
	)
	fi
	
	status "Building and installing gst-plugins-bad"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}

##
# gst-plugins-farsight
#
GST_DEPS=( ${GST_DEPS[@]} "libgstrtp-${GSTREAMER_VERSION}.0.dylib" "libgstsdp-${GSTREAMER_VERSION}.0.dylib" "libgstrtsp-${GSTREAMER_VERSION}.0.dylib" )
build_gst_plugins_farsight() {
	prereq "gst-plugins-farsight" \
		"http://farsight.freedesktop.org/releases/obsolete/gst-plugins-farsight/gst-plugins-farsight-0.12.11.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-farsight"
	
	if needsconfigure $@; then
	(
		status "Configuring gst-plugins-farsight"
		export NM="nm -arch all"
		export CFLAGS="$ARCH_CFLAGS"
		export LDFLAGS="$ARCH_LDFLAGS"
		log ./configure --prefix="$ROOTDIR/build" \
			--disable-jrtplib \
			--disable-gconf \
			--disable-dependency-tracking
	)
	fi
	
	status "Building and installing gst-plugins-farsight"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}

##
# gstreamer plugins
#
build_gst_plugins() {
	build_liboil $@
	build_gst_plugins_base $@
	build_gst_plugins_good $@
#	build_gst_plugins_bad $@
	build_gst_plugins_farsight $@
}

##
# gstreamer
#
build_gstreamer() {
	prereq "gstreamer" \
		"http://gstreamer.freedesktop.org/src/gstreamer/gstreamer-0.10.26.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gstreamer"
	
	if needsconfigure $@; then
	(
		status "Configuring gstreamer"
		export XML_CFLAGS=" -I$SDK_ROOT/usr/include/libxml2"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-examples \
				--disable-tests \
				--disable-option-parsing \
				--disable-check \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"$ROOTDIR/source/gstreamer/gst/gstconfig.h" \
			"$ROOTDIR/source/gstreamer/config.h"
	)
	fi
	
	status "Building and installing gstreamer"
	warning "Building too much! Patch the Makefile"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
	
	build_gst_plugins $@
}

##
# libNICE
#
GST_DEPS=( ${GST_DEPS[@]} "libnice.0.dylib" )
build_nice() {
	prereq "nice" \
		"http://nice.freedesktop.org/releases/libnice-0.0.10.tar.gz"
	
	quiet pushd "$ROOTDIR/source/nice"
	
	if needsconfigure $@; then
	(
		status "Configuring NICE"
		export NM="nm -arch all"
		export CFLAGS="$ARCH_CFLAGS"
		export LDFLAGS="$ARCH_LDFLAGS"
		log ./configure \
			--prefix="$ROOTDIR/build" \
			--disable-dependency-tracking
	)
	fi
	
	status "Building and installing NICE"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}

##
# farsight
#
build_farsight() {
	build_nice $@
	
	prereq "farsight" \
		"http://farsight.freedesktop.org/releases/farsight2/farsight2-0.0.17.tar.gz"
	
	quiet pushd "$ROOTDIR/source/farsight"
	
	if needsconfigure $@; then
	(
		status "Configuring farsight"
		export NM="nm -arch all"
		export CFLAGS="$ARCH_CFLAGS"
		export LDFLAGS="$ARCH_LDFLAGS"
		log ./configure \
			--prefix="$ROOTDIR/build" \
			--disable-python \
			--disable-dependency-tracking
	)
	fi
	
	status "Building and installing farsight"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}
