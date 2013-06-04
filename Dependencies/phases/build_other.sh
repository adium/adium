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
		"http://dl.sf.net/sourceforge/sipe/pidgin-sipe-1.4.0.tar.gz"
	
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
	
	quiet popd
}

##
# Gfire
#
build_gfire() {
	# I'm not sure how to build this yet... it expects Pidgin to be built, and
	# since no pidgin.pc file is made, we can't satisfy that requirement.
	warning "I don't know how to build Gfire yet."
	return 0
	
	prereq "gfire" \
		"http://dl.sf.net/gfire/gfire-0.8.1.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gfire"
	
	if needsconfigure $@; then
		status "Configuring Gfire"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing Gfire"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}