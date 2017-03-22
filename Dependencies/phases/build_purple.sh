#!/bin/bash -eu

##
# sniff_libpurple_version
#
# We pull libpurple from monotone, so we may not know the version number
# ahead of time
#
sniff_libpurple_version() {
	LIBPURPLE_VERSION=''
	while read LINE ; do
		local version=`expr "'${LINE}'" : '.* PURPLE_.*_VERSION (\([0-9]*\)).*'`
		if [[ '' != ${version} ]] ; then
			LIBPURPLE_VERSION="${LIBPURPLE_VERSION}.${version}"
		fi
	done < "${ROOTDIR}/source/libpurple/libpurple/version.h"
	LIBPURPLE_VERSION="0.${LIBPURPLE_VERSION:3}"
}

##
# fetch_libpurple
#
fetch_libpurple() {
	quiet pushd "$ROOTDIR/source"
	
	if [ -d "libpurple" ]; then
		status "Pulling latest changes to libpurple"
		cd "libpurple"
		$HG pull

		status "Updating libpurple with ${HG_UPDATE_PARAM}"
		$HG update ${HG_UPDATE_PARAM}
	else
		$HG clone -b adium "http://hg.adium.im/libpurple/" libpurple
	fi
	
	quiet popd
}

##
# libpurple
#
build_libpurple() {
	if $DOWNLOAD_LIBPURPLE; then
	  fetch_libpurple
	fi
	if [ ! -d "$ROOTDIR/source/libpurple" ]; then
	  error "libpurple checkout not found; use --download-libpurple"
	  exit 1;
	fi
	
	prereq "cyrus-sasl" \
		"ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/OLD-VERSIONS/sasl/cyrus-sasl-2.1.18.tar.gz"
	
	# Copy the headers from Cyrus-SASL
	status "Copying headers from Cyrus-SASL"
	quiet mkdir -p "$ROOTDIR/build/include/sasl"
	log cp -f "$ROOTDIR/source/cyrus-sasl/include/"*.h "$ROOTDIR/build/include/sasl"
	
	quiet pushd "$ROOTDIR/source/libpurple"
	
	PROTOCOLS="bonjour,gg,irc,jabber,msn,novell,oscar,"
	PROTOCOLS+="sametime,simple,yahoo,zephyr"
	
	# Leopard's 64-bit Kerberos library is missing symbols, as evidenced by
	#    $ nm -arch x86_64 /usr/lib/libkrb4.dylib | grep krb_rd_req
	# So, only enable it on Snow Leopard
	if [ "$(sysctl -b kern.osrelease | awk -F '.' '{ print $1}')" -ge 10 ]; then
		#KERBEROS="--with-krb4"
		KERBEROS=""
	else
		warning "Kerberos support is disabled."
		KERBEROS=""
	fi
	
	if needsconfigure $@; then
	(
		status "Configuring libpurple"
		export ACLOCAL_FLAGS="-I $ROOTDIR/build/share/aclocal"
		export LIBXML_CFLAGS="-I/usr/include/libxml2"
		export LIBXML_LIBS="-lxml2"
		export MEANWHILE_CFLAGS="-I$ROOTDIR/build/include/meanwhile \
			-I$ROOTDIR/build/include/glib-2.0 \
			-I$ROOTDIR/build/lib/glib-2.0/include"
		export MEANWHILE_LIBS="-lmeanwhile -lglib-2.0 -liconv"
		export MSGFMT="$ROOTDIR/build/bin/msgfmt"
		CONFIG_CMD="./autogen.sh \
				--disable-dependency-tracking \
				--disable-gtkui \
				--disable-consoleui \
				--disable-perl \
				--enable-debug \
				--disable-static \
				--enable-shared \
				--enable-cyrus-sasl \
				--prefix=$ROOTDIR/build \
				--with-static-prpls=$PROTOCOLS \
				--disable-plugins \
				--disable-avahi \
				--disable-dbus \
				--enable-gnutls=no \
				--enable-nss=no \
				--enable-vv=no \
				--disable-gstreamer \
				--disable-idn \
				$KERBEROS"
		xconfigure "$BASE_CFLAGS -I/usr/include/kerberosIV -DHAVE_SSL \
			        -DHAVE_OPENSSL -fno-common -DHAVE_ZLIB" \
			"$BASE_LDFLAGS -lsasl2 -ljson-glib-1.0 -lz" \
			"${CONFIG_CMD}" \
			"${ROOTDIR}/source/libpurple/libpurple/purple.h" \
			"${ROOTDIR}/source/libpurple/config.h"
	)
	fi
	
	status "Building and installing libpurple"
	log make -j $NUMBER_OF_CORES
	log make install
	
	status "Copying internal libpurple headers"
	log cp -f "$ROOTDIR/source/libpurple/libpurple/protocols/oscar/oscar.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/oscar/snactypes.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/oscar/peer.h" \
		  "$ROOTDIR/source/libpurple/libpurple/cmds.h" \
		  "$ROOTDIR/source/libpurple/libpurple/internal.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/msn/"*.h \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/yahoo/"*.h \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/gg/buddylist.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/gg/gg.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/gg/search.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/auth.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/bosh.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/buddy.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/caps.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/jutil.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/presence.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/si.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/jabber.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/iq.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/jabber/namespaces.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/irc/irc.h" \
		  "$ROOTDIR/source/libpurple/libpurple/protocols/gg/lib/libgadu.h" \
		  "$ROOTDIR/build/include/libpurple"
	
	quiet popd
	sniff_libpurple_version
}
