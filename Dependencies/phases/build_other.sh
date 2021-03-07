#!/bin/bash -eu

##
# SIPE
#
build_sipe() {
	# I'm not sure how to build this yet... first, it looks like it expects
	# libpurple to already be built, and second it's requiring a FreeBSD package
	# called "com_err" which I can't find the source to.
	warning "I don't know how to build SIPE yet."
	return 0
	
	prereq "sipe" \
		"https://phoenixnap.dl.sourceforge.net/project/sipe/sipe/pidgin-sipe-1.25.0/pidgin-sipe-1.25.0.tar.xz"
	
	quiet pushd "$ROOTDIR/source/sipe"
	
	if needsconfigure $@; then
		status "Configuring SIPE"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build"
				--disable-dependency-tracking
	fi
	
	status "Building and installing SIPE"
	make -j $NUMBER_OF_CORES
	make install
	
	status "Successfully installed sipe"
	quiet popd
}
