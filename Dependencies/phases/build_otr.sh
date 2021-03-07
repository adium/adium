#!/bin/bash -eu

##
# gpg-error
#
build_libgpgerror(){
	prereq "gpgerror" \
		"https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.41.tar.bz2"

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
	
	status "Successfully installed gpgerror"
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
		"https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.9.2.tar.bz2"

	quiet pushd "${ROOTDIR}/source/libgcrypt"
	
	if needsconfigure $@; then
	(
		status "Configuring libgcrypt"
		log ./configure --prefix=$ROOTDIR/build \
			--enable-ciphers=arcfour:blowfish:cast5:des:aes:twofish:serpent:rfc2268 \
			--enable-pubkey-ciphers=dsa:elgamal:rsa \
			--enable-digests=crc:md4:md5:rmd160:sha1:sha256:sha512:tiger \
			--disable-endian-check \
			--disable-dependency-tracking
	)
	fi


	status "Building and installing libgcrypt"
	log make -j $NUMBER_OF_CORES
	log make install
	
	status "Successfully installed libgcrypt"
	quiet popd
}

##
# Libotr
#
OTR_VERSION=3.2.0
build_otr(){
	build_libgcrypt
	prereq "otr" \
		"https://github.com/off-the-record/libotr/archive/4.1.0.tar.gz"

	quiet pushd "${ROOTDIR}/source/otr"

	if needsconfigure $@; then
	(
    status "Bootstrapping libotr"
    ./bootstrap
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

	status "Successfully installed libotr"
	quiet popd
}
