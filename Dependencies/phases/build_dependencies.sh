#!/bin/bash -eu

##
# pkg-config
#
# We only need a native pkg-config, so no worries about making it a Universal
# Binary.
#
build_pkgconfig() {
	prereq "pkg-config" \
		"http://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"
	
	quiet pushd "$ROOTDIR/source/pkg-config"
	
	if needsconfigure $@; then
		status "Configuring pkg-config"
		log ./configure --prefix="$ROOTDIR/build"
	fi
	
	status "Building and installing pkg-config"
	log make -j $NUMBER_OF_CORES
	log make install
	
	status "Successfully installed pkg-config"
	quiet popd
}

##
# gettext
#
build_gettext() {
	prereq "gettext" \
		"http://mirrors.kernel.org/gnu/gettext/gettext-0.21.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gettext"
	
	if needsconfigure $@; then
	(
		status "Configuring gettext"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-java \
				--disable-static \
				--enable-shared \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gettext/gettext-runtime/config.h" \
			"${ROOTDIR}/source/gettext/gettext-runtime/libasprintf/config.h" \
			"${ROOTDIR}/source/gettext/gettext-tools/config.h"
	)
	fi
	
	status "Building and installing gettext"
	log make -j $NUMBER_OF_CORES
	log make install

	status "Successfully installed gettext"
	quiet popd
}

##
# glib
#
GLIB_VERSION=2.0
build_glib() {
	prereq "glib" \
		"https://download.gnome.org/sources/glib/2.66/glib-2.66.7.tar.xz"
	
	quiet pushd "$ROOTDIR/source/glib"
	
	if needsconfigure $@; then
	(
		status "Configuring glib"
    meson \
        -Dprefix=$ROOTDIR/build \
        -Dman=false \
        -Diconv=auto \
        -Dinstalled_tests=false \
        _build
    status "Configured."


#				--disable-static \
#				--enable-shared \
#				--with-libiconv=native \
#				--disable-fam \
#				--disable-selinux \
#				--with-threads=posix \
#				--disable-dependency-tracking"
#		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS} -lintl" "${CONFIG_CMD}" \
#			"${ROOTDIR}/source/glib/config.h" \
#			"${ROOTDIR}/source/glib/gmodule/gmoduleconf.h" \
#			"${ROOTDIR}/source/glib/glibconfig.h"
	)
	fi
	
	status "Building and installing glib"
  ninja -C _build
  status "Finished Building glib."
  status "Installing glib."
  ninja -C _build install
	
	status "Successfully installed glib"
	quiet popd
}

##
# Meanwhile
#
MEANWHILE_VERSION=1
build_meanwhile() {
	prereq "meanwhile" \
		"http://downloads.sourceforge.net/project/meanwhile/meanwhile/1.0.2/meanwhile-1.0.2.tar.gz"
	
	quiet pushd "${ROOTDIR}/source/meanwhile"
	
	# Mikael Berthe writes, "It seems that the last guint32_get() fails when
	# Meanwhile receives the FT offer. I think we can skip it -- works for me
	# but I can't check it with an older server.
	fwdpatch "${ROOTDIR}/patches/Meanwhile-srvc_ft.c.diff" -p0 || true

	# Fixes Awareness Snapshots with recent Sametime servers, thanks to Mikael
	# Berthe. "With recent Sametime servers there seem to be 2 bytes after the
	# Snapshot Message Blocks. This patch tries to use the end of block offset
	# provided by th server."
	fwdpatch "${ROOTDIR}/patches/Meanwhile-common.c.diff" -p0 || true

	# Patch to fix a crash in blist parsing
	fwdpatch "${ROOTDIR}/patches/Meanwhile-st_list.c.diff" -p0 || true

	# The provided libtool ignores our Universal Binary-makin' flags
	fwdpatch "${ROOTDIR}/patches/Meanwhile-ltmain.sh.diff" -p0 || true

	# Fixes accepting group chat invites from the standard Sametime client.
	# Thanks to Jere Krischel and Jonathan Rice.
	fwdpatch "${ROOTDIR}/patches/Meanwhile-srvc_place.c.diff" -p0 || true
	fwdpatch "${ROOTDIR}/patches/Meanwhile-session.c.diff" -p0 || true
 
  # For some reason, Meanwhile includes specific glib/*.h files,
  # which causes an error that they should not be included directly.
  # This changes all #include <glib/*.h> statements to #include <glib.h>.
  fwdpatch "${ROOTDIR}/patches/Meanwhile-glib_headers.diff" -p0 || true
	
	if needsconfigure $@; then
	(
		# Delete 'libtool' if it exists, so that we'll generate a new one
		rm -f libtool
		
    install_dir=${ROOTDIR}/build
		status "Configuring Meanwhile to install at ${install_dir}"
		export CFLAGS=( ${ARCH_LDFLAGS} -L${install_dir}/lib )
		export LDFLAGS=( $ARCH_CFLAGS -I${install_dir}/include/glib-2.0 -I${install_dir}/lib/glib-2.0/include )
    log ./configure \
			--prefix="${install_dir}" \
			--disable-static \
			--enable-shared \
			--disable-doxygen \
			--disable-mailme \
			--disable-dependency-tracking
	)
	fi
	
	status "Building and installing Meanwhile"
	export CFLAGS="$ARCH_CFLAGS"
	export LDFLAGS="$ARCH_LDFLAGS"
	log make -j $NUMBER_OF_CORES
	log make install
	
	# Undo all the patches
	revpatch "${ROOTDIR}/patches/Meanwhile-glib_headers.diff" -p0
	revpatch "${ROOTDIR}/patches/Meanwhile-session.c.diff" -p0
	revpatch "${ROOTDIR}/patches/Meanwhile-srvc_place.c.diff" -p0
	revpatch "${ROOTDIR}/patches/Meanwhile-ltmain.sh.diff" -p0
	revpatch "${ROOTDIR}/patches/Meanwhile-st_list.c.diff" -p0
	revpatch "${ROOTDIR}/patches/Meanwhile-common.c.diff" -p0
	revpatch "${ROOTDIR}/patches/Meanwhile-srvc_ft.c.diff" -p0
	
	status "Successfully installed meanwhile"
  quiet popd
}

##
# intltool
#
INTL_VERSION=8
build_intltool() {
	# We used to use 0.36.2, but I switched to the latest MacPorts is using
	prereq "intltool" \
		"https://download.gnome.org/sources/intltool/0.40/intltool-0.40.6.tar.bz2"
	
	quiet pushd "$ROOTDIR/source/intltool"
	
	if needsconfigure $@; then
	(
		status "Configuring intltool"
		export CFLAGS="$ARCH_CFLAGS"
		export LDFLAGS="$ARCH_LDFLAGS"
		log ./configure --prefix="$ROOTDIR/build" --disable-dependency-tracking
	)
	fi
	
	status "Building and installing intltool"
	log make -j $NUMBER_OF_CORES
	log make install
	
	status "Successfully installed intltool"
	quiet popd
}

##
# json-glib
#
JSON_GLIB_VERSION=1.0
build_jsonglib() {
	prereq "json-glib-0.9.2" \
		"https://download.gnome.org/sources/json-glib/1.6/json-glib-1.6.2.tar.xz"
	
	quiet pushd "$ROOTDIR/source/json-glib-1.6.2"
	
	if needsconfigure $@; then
	(
		status "Configuring json-glib"
		export CFLAGS="$ARCH_CFLAGS"
		export LDFLAGS="$ARCH_LDFLAGS"
		export GLIB_LIBS="$ROOTDIR/build/lib"
		export GLIB_CFLAGS="-I$ROOTDIR/build/include/glib-2.0 -I$ROOTDIR/build/lib/glib-2.0/include"
    meson \
        -Dprefix=$ROOTDIR/build \
        -Dman=false \
        _build
    status "Configured."

		log ./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	)
	fi
	
	status "Building and installing json-glib"
  ninja -C _build
  status "Finished Building json-glib."
  status "Installing json-glib."
  ninja -C _build install
	
	# C'mon, why do you make me do this?
#	log ln -fs "$ROOTDIR/build/include/json-glib-1.0/json-glib" \
#		"$ROOTDIR/build/include/json-glib"
	
	status "Successfully installed json-glib"
	quiet popd
}
