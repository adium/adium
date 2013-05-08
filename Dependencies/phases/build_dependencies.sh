#!/bin/bash -eu

##
# pkg-config
#
# We only need a native pkg-config, so no worries about making it a Universal
# Binary.
#
build_pkgconfig() {
	prereq "pkg-config" \
		"http://pkgconfig.freedesktop.org/releases/pkg-config-0.23.tar.gz"
	
	quiet pushd "$ROOTDIR/source/pkg-config"
	
	if needsconfigure $@; then
		status "Configuring pkg-config"
		export CFLAGS="-std=gnu89"
		log ./configure --prefix="$ROOTDIR/build"
	fi
	
	status "Building and installing pkg-config"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}

##
# gettext
#
build_gettext() {
	prereq "gettext" \
		"http://mirrors.kernel.org/gnu/gettext/gettext-0.16.1.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gettext"
	
	# Patch to reduce the number of superfluous things we build
	fwdpatch "$ROOTDIR/patches/gettext-Makefile.in.diff" -p0 || true
	
	if needsconfigure $@; then
	(
		status "Configuring gettext"
		export "gl_cv_absolute_stdint_h=${SDK_ROOT}/usr/include/stdint.h"
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

	# Undo all of our patches... goodbye!
	revpatch "$ROOTDIR/patches/gettext-Makefile.in.diff" -p0

	quiet popd
}

##
# glib
#
GLIB_VERSION=2.0
build_glib() {
	prereq "glib" \
		"ftp://ftp.gnome.org/pub/gnome/sources/glib/2.20/glib-2.20.5.tar.gz"
	
	quiet pushd "$ROOTDIR/source/glib"
	
	# We may have to apply a patch if we're building on PowerPC
	if [ "$(arch)" = "ppc" ]; then
		warning "glib may not build correctly from PowerPC."
	fi
	
	# Patch to fix building with the native libiconv
	fwdpatch "$ROOTDIR/patches/glib-gconvert.c.diff" -p0 || true
	
	# Patch to reduce the number of superfluous things we build
	fwdpatch "$ROOTDIR/patches/glib-Makefile.in.diff" -p0 || true
	
	if needsconfigure $@; then
	(
		status "Configuring glib"
		export MSGFMT="${ROOTDIR}/build/bin/msgfmt"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-static \
				--enable-shared \
				--with-libiconv=native \
				--disable-fam \
				--disable-selinux \
				--with-threads=posix \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS} -lintl" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/glib/config.h" \
			"${ROOTDIR}/source/glib/gmodule/gmoduleconf.h" \
			"${ROOTDIR}/source/glib/glibconfig.h"
	)
	fi
	
	status "Building and installing glib"
	log make -j $NUMBER_OF_CORES
	log make install
	
	# Revert the patches
	revpatch "$ROOTDIR/patches/glib-Makefile.in.diff" -p0
	revpatch "$ROOTDIR/patches/glib-gconvert.c.diff" -p0

	quiet popd
}

##
# Meanwhile
#
MEANWHILE_VERSION=1
build_meanwhile() {
	prereq "meanwhile" \
		"http://downloads.sourceforge.net/project/meanwhile/meanwhile/1.0.2/meanwhile-1.0.2.tar.gz"
	
	quiet pushd "$ROOTDIR/source/meanwhile"
	
	# Mikael Berthe writes, "It seems that the last guint32_get() fails when
	# Meanwhile receives the FT offer. I think we can skip it -- works for me
	# but I can't check it with an older server.
	fwdpatch "$ROOTDIR/patches/Meanwhile-srvc_ft.c.diff" -p0 || true
	
	# Fixes Awareness Snapshots with recent Sametime servers, thanks to Mikael
	# Berthe. "With recent Sametime servers there seem to be 2 bytes after the
	# Snapshot Message Blocks. This patch tries to use the end of block offset
	# provided by th server."
	fwdpatch "$ROOTDIR/patches/Meanwhile-common.c.diff" -p0 || true
	
	# Patch to fix a crash in blist parsing
	fwdpatch "$ROOTDIR/patches/Meanwhile-st_list.c.diff" -p0 || true
	
	# The provided libtool ignores our Universal Binary-makin' flags
	fwdpatch "$ROOTDIR/patches/Meanwhile-ltmain.sh.diff" -p0 || true

	# Fixes accepting group chat invites from the standard Sametime client.
	# Thanks to Jere Krischel and Jonathan Rice.
	fwdpatch "$ROOTDIR/patches/Meanwhile-srvc_place.c.diff" -p0 || true
	fwdpatch "$ROOTDIR/patches/Meanwhile-session.c.diff" -p0 || true
	
	if needsconfigure $@; then
	(
		# Delete 'libtool' if it exists, so that we'll generate a new one 
		rm -f libtool
		
		status "Configuring Meanwhile"
		export CFLAGS="$ARCH_CFLAGS"
		export LDFLAGS="$ARCH_LDFLAGS"
		export GLIB_LIBS="$ROOTDIR/build/lib"
		export GLIB_CFLAGS="-I$ROOTDIR/build/include/glib-2.0 \
			-I$ROOTDIR/build/lib/glib-2.0/include"
		log ./configure \
			--prefix="$ROOTDIR/build" \
			--disable-static \
			--enable-shared \
			--disable-doxygen \
			-disable-mailme \
			--disable-dependency-tracking
	)
	fi
	
	status "Building and installing Meanwhile"
	export CFLAGS="$ARCH_CFLAGS"
	export LDFLAGS="$ARCH_LDFLAGS"
	log make -j $NUMBER_OF_CORES
	log make install
	
	# Undo all the patches
	revpatch "$ROOTDIR/patches/Meanwhile-ltmain.sh.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-st_list.c.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-common.c.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-srvc_ft.c.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-srvc_place.c.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-session.c.diff" -p0
	
	quiet popd
}

##
# intltool
#
INTL_VERSION=8
build_intltool() {
	# We used to use 0.36.2, but I switched to the latest MacPorts is using
	prereq "intltool" \
		"http://ftp.gnome.org/pub/gnome/sources/intltool/0.40/intltool-0.40.6.tar.gz"
	
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
	
	quiet popd
}

##
# json-glib
#
JSON_GLIB_VERSION=1.0
build_jsonglib() {
	prereq "json-glib-0.9.2" \
		"http://ftp.gnome.org/pub/GNOME/sources/json-glib/0.9/json-glib-0.9.2.tar.gz"
	
	quiet pushd "$ROOTDIR/source/json-glib-0.9.2"
	
	if needsconfigure $@; then
	(
		status "Configuring json-glib"
		export CFLAGS="$ARCH_CFLAGS"
		export LDFLAGS="$ARCH_LDFLAGS"
		export GLIB_LIBS="$ROOTDIR/build/lib"
		export GLIB_CFLAGS="-I$ROOTDIR/build/include/glib-2.0 \
			-I$ROOTDIR/build/lib/glib-2.0/include"
		log ./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	)
	fi
	
	status "Building and installing json-glib"
	log make -j $NUMBER_OF_CORES
	log make install
	
	# C'mon, why do you make me do this?
	log ln -fs "$ROOTDIR/build/include/json-glib-1.0/json-glib" \
		"$ROOTDIR/build/include/json-glib"
	
	quiet popd
}
