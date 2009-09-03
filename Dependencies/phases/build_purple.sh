#!/bin/bash -eu

##
# fetch_libpurple
#
fetch_libpurple() {
	quiet pushd "$ROOTDIR/source"
	
	if [ -d "im.pidgin.adium" ]; then
		
		status "Pulling latest changes to libpurple"
		cd "im.pidgin.adium"
		$MTN pull
		$MTN update "${MTN_UPDATE_PARAM}"
		
	else
		
		quiet mkdir "im.pidgin.adium"
		cd "im.pidgin.adium"
	
		status "Downloading bootstrap database for libpurple"
		curl -LOf "http://developer.pidgin.im/static/pidgin.mtn.bz2"
	
		status "Extracting bootstrap database"
		bzip2 -d "pidgin.mtn.bz2"
	
		status "Migrating database to new schema"
		$MTN db -d "pidgin.mtn" migrate
	
		status "Pulling updates to monotone database"
		$MTN -d "pidgin.mtn" pull --set-default "mtn.pidgin.im" "im.pidgin.*"
	
		status "Checking out im.pidgin.adium.1-4 branch"
		$MTN -d "pidgin.mtn" co -b "im.pidgin.adium.1-4" .
	
	fi
	
	quiet popd
}

##
# libpurple
#
build_libpurple() {
	fetch_libpurple
	prereq "cyrus-sasl" \
		"ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/OLD-VERSIONS/sasl/cyrus-sasl-2.1.18.tar.gz"
	
	# Copy the headers from Cyrus-SASL
	status "Copying headers from Cyrus-SASL"
	quiet mkdir -p "$ROOTDIR/build/include/sasl"
	cp -f "$ROOTDIR/source/cyrus-sasl/include/"*.h "$ROOTDIR/build/include/sasl"
	
	quiet pushd "$ROOTDIR/source/im.pidgin.adium"
	
	PROTOCOLS="bonjour,facebook,gg,irc,jabber,msn,myspace,novell,oscar,qq,"
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
		status "Configuring libpurple"
		export ACLOCAL_FLAGS="-I $ROOTDIR/build/share/aclocal"
		export LIBXML_CFLAGS="-I/usr/include/libxml2"
		export LIBXML_LIBS="-lxml2"
		export GADU_CFLAGS="-I$ROOTDIR/build/include"
		export GADU_LIBS="-lgadu"
		export MEANWHILE_CFLAGS="-I$ROOTDIR/build/include/meanwhile \
			-I$ROOTDIR/build/include/glib-2.0 \
			-I$ROOTDIR/build/lib/glib-2.0/include"
		export MEANWHILE_LIBS="-lmeanwhile -lglib-2.0 -liconv"
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
				--enable-vv=yes \
				--disable-idn \
				$KERBEROS"
		xconfigure "$BASE_CFLAGS -I/usr/include/kerberosIV -DHAVE_SSL \
			        -DHAVE_OPENSSL -fno-common" \
			"$BASE_LDFLAGS -lsasl2 -ljson-glib-1.0" \
			"${CONFIG_CMD}" \
			"${ROOTDIR}/source/im.pidgin.adium/libpurple/purple.h" \
			"${ROOTDIR}/source/im.pidgin.adium/config.h"
	fi
	
	status "Building and installing libpurple"
	make -j $NUMBER_OF_CORES
	make install
	
	status "Copying internal libpurple headers"
	cp -f "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/oscar/oscar.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/oscar/snactypes.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/oscar/peer.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/cmds.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/internal.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/msn/"*.h \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/yahoo/"*.h \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/gg/buddylist.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/gg/gg.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/gg/search.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/bosh.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/buddy.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/caps.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/jutil.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/presence.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/si.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/jabber.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/iq.h" \
		  "$ROOTDIR/build/include/libpurple"
	
	quiet popd
}
