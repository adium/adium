#!/bin/bash -eu

##
# gpg-error
#
build_libgpgerror(){
	prereq "gpgerror" \
		"ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.7.tar.bz2"

	quiet pushd "${ROOTDIR}/source/gpgerror"
	
	if needsconfigure $@; then
	(
		status "Configuring libgpg-error"
		export CFLAGS="$ARCH_CFLAGS -Os"
		export LDFLAGS="$ARCH_LDFLAGS"
		log ./configure --prefix="$ROOTDIR/build" \
			--disable-shared \
			--enable-static \
			--disable-dependency-tracking
	)
	fi
	
	status "Building and installing gpg-error"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}

##
# gcrypt
#
# disable assembly to help build universal.
#
build_libgcrypt(){
	build_libgpgerror
	prereq "libgcrypt" \
		"ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.4.4.tar.gz"

	quiet pushd "${ROOTDIR}/source/libgcrypt"
	
	if needsconfigure $@; then
	(
		status "Configuring libgcrypt"
		CONFIG_CMD="./configure --prefix=$ROOTDIR/build \
			--disable-shared \
			--enable-static \
			--disable-asm \
			--enable-ciphers=arcfour:blowfish:cast5:des:aes:twofish:serpent:rfc2268 \
			--enable-pubkey-ciphers=dsa:elgamal:rsa \
			--enable-digests=crc:md4:md5:rmd160:sha1:sha256:sha512:tiger \
			--disable-endian-check \
			--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS} -Os" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/libgcrypt/config.h"
	)
	fi


	status "Building and installing libgcrypt"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}

##
# Libotr
#
OTR_VERSION=3.2.0
build_otr(){
	build_libgcrypt
	prereq "otr" \
		"http://www.cypherpunks.ca/otr/libotr-3.2.0.tar.gz"
	
	quiet pushd "${ROOTDIR}/source/otr"
	
	if needsconfigure $@; then
	(
		status "Configuring libotr"
		export CFLAGS="$ARCH_CFLAGS -Os"
		export LDFLAGS="$ARCH_LDFLAGS"
		log ./configure --prefix="$ROOTDIR/build" \
			--disable-dependency-tracking
	)	
	fi
	status "Building and installing libotr"
	log make -j $NUMBER_OF_CORES
	log make install
	
	quiet popd
}
